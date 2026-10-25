/**
 * Dilivvafast Cloud Functions.
 *
 * Migrated to the firebase-functions v2 API. The previous revision imported the
 * v1 namespace (`import * as functions from "firebase-functions"`, which is v1
 * in firebase-functions v5) while using the v2 callable signature
 * (`request.data` / `request.auth`). Under v1 the handler receives
 * `(data, context)`, so `request.data` was always undefined and every callable
 * threw `unauthenticated` before doing any work. Both payment callables were
 * dead on arrival.
 *
 * Trust model: everything in here runs with Admin SDK privileges and therefore
 * bypasses firestore.rules. Every callable must establish caller identity and
 * authorisation for itself, and must never trust a client-supplied amount,
 * price, role or user id.
 */

import { onCall, onRequest, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { onDocumentCreated, onDocumentUpdated, onDocumentWritten } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import { logger } from "firebase-functions";
import { initializeApp } from "firebase-admin/app";
import {
  getFirestore,
  FieldValue,
  GeoPoint,
} from "firebase-admin/firestore";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";
import * as crypto from "crypto";
import axios from "axios";

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

setGlobalOptions({ region: "us-central1", maxInstances: 20 });

// Secrets are supplied by Cloud Secret Manager, never by build-time config and
// never by the mobile client. Set with:
//   firebase functions:secrets:set PAYSTACK_SECRET_KEY
const PAYSTACK_SECRET_KEY = defineSecret("PAYSTACK_SECRET_KEY");
const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");

const PLATFORM_COMMISSION_RATE = 0.2;
const MINIMUM_FARE = 500;
const REFERRAL_BONUS = 500;

// ==================== SHARED HELPERS ====================

/** Naira is stored as a float for backwards compatibility with existing
 *  documents. Rounding every write to kobo precision keeps repeated
 *  increments from accumulating binary-floating-point drift. */
function toKoboPrecision(naira: number): number {
  return Math.round(naira * 100) / 100;
}

/**
 * Serialise an error for structured logging.
 *
 * Passing the raw error as a log field looks right but is useless: an Error
 * has no enumerable own properties, so it JSON-serialises to `{}` and the log
 * records that something failed without saying what. Every catch block in this
 * file goes through here instead.
 */
function errorInfo(error: unknown): Record<string, unknown> {
  if (error instanceof Error) {
    return { message: error.message, stack: error.stack, name: error.name };
  }
  return { message: String(error) };
}

function requireAuth(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in to continue.");
  }
  return uid;
}

/** Admin is asserted by custom claim first. The legacy `role` field is still
 *  honoured so existing admin accounts keep working, but claims are the
 *  supported path — see SECURITY.md. */
async function requireAdmin(request: CallableRequest): Promise<string> {
  const uid = requireAuth(request);
  if (request.auth?.token?.admin === true) return uid;

  const snap = await db.collection("users").doc(uid).get();
  if (snap.data()?.role === "admin") return uid;

  throw new HttpsError("permission-denied", "Administrator access required.");
}

/** Fixed-window limiter for endpoints that cost money to serve. Backed by a
 *  Firestore transaction so concurrent calls cannot both slip through. */
async function enforceRateLimit(
  uid: string,
  bucket: string,
  maxCalls: number,
  windowSeconds: number
): Promise<void> {
  const ref = db.collection("rate_limits").doc(`${bucket}_${uid}`);
  const now = Date.now();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    const windowStart: number = data?.windowStart ?? 0;
    const count: number = data?.count ?? 0;

    if (now - windowStart > windowSeconds * 1000) {
      tx.set(ref, { windowStart: now, count: 1, uid });
      return;
    }
    if (count >= maxCalls) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many requests. Please wait a moment and try again."
      );
    }
    tx.update(ref, { count: count + 1 });
  });
}

/** Append-only record of privileged actions. Readable by admins, writable by
 *  nobody except the Admin SDK (see firestore.rules). */
async function writeAuditLog(entry: {
  actorUid: string;
  action: string;
  targetUid?: string;
  details?: Record<string, unknown>;
}): Promise<void> {
  await db.collection("admin_audit_log").add({
    ...entry,
    createdAt: FieldValue.serverTimestamp(),
  });
}

/** Drops an FCM token that the messaging service has told us is dead. */
async function pruneTokenIfStale(uid: string, error: unknown): Promise<void> {
  const code = (error as { errorInfo?: { code?: string } })?.errorInfo?.code;
  if (
    code === "messaging/registration-token-not-registered" ||
    code === "messaging/invalid-registration-token"
  ) {
    await db
      .collection("users")
      .doc(uid)
      .update({ fcmToken: FieldValue.delete() })
      .catch(() => undefined);
  }
}

/** What a push is about, for the switches in Settings → Notifications. */
type PushCategory = "order" | "account";

/**
 * Whether the user's saved preferences allow this push.
 *
 * The Settings switches were local widget state that nothing read, so turning
 * notifications off changed nothing. They are now stored on the profile as
 * `notificationPrefs` and honoured here. Absent preferences mean "on".
 */
function pushAllowed(
  user: { notificationPrefs?: { push?: boolean; orderUpdates?: boolean } } | undefined,
  category: PushCategory
): boolean {
  const prefs = user?.notificationPrefs;
  if (prefs?.push === false) return false;
  if (category === "order" && prefs?.orderUpdates === false) return false;
  return true;
}

async function sendToUser(
  uid: string,
  notification: { title: string; body: string },
  data: Record<string, string>,
  category: PushCategory = "account"
): Promise<void> {
  const snap = await db.collection("users").doc(uid).get();
  const token = snap.data()?.fcmToken;
  if (!token || !pushAllowed(snap.data(), category)) return;

  try {
    await messaging.send({ token, notification, data });
  } catch (error) {
    logger.warn("FCM send failed", { uid, ...errorInfo(error) });
    await pruneTokenIfStale(uid, error);
  }
}

// ==================== PAYMENT: INITIALIZE ====================

/**
 * Create a Paystack transaction and hand the client an authorization URL.
 * The amount is echoed to Paystack but never trusted as proof of payment —
 * only `verifyPaystackPayment` (or the webhook) can credit a wallet.
 */
export const initializePaystackPayment = onCall(
  { secrets: [PAYSTACK_SECRET_KEY] },
  async (request) => {
    const uid = requireAuth(request);
    await enforceRateLimit(uid, "payment_init", 10, 60 * 10);

    const amount = Number(request.data?.amount);
    const email = String(request.data?.email ?? "").trim();

    if (!Number.isFinite(amount) || amount < 100) {
      throw new HttpsError("invalid-argument", "Minimum top-up is ₦100.");
    }
    if (amount > 1_000_000) {
      throw new HttpsError("invalid-argument", "Amount exceeds the per-transaction limit.");
    }
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      throw new HttpsError("invalid-argument", "A valid email is required.");
    }

    // The reference is minted server-side. A client-supplied reference would
    // let a caller pin a reference it had already had verified elsewhere.
    const reference = `DF-${uid.slice(0, 8)}-${Date.now()}-${crypto
      .randomBytes(4)
      .toString("hex")}`;

    try {
      const response = await axios.post(
        "https://api.paystack.co/transaction/initialize",
        {
          amount: Math.round(amount * 100), // kobo
          email,
          reference,
          callback_url: "https://dilivvafast.com/payment/callback",
          currency: "NGN",
          metadata: {
            userId: uid,
            custom_fields: [
              { display_name: "User ID", variable_name: "user_id", value: uid },
            ],
          },
        },
        {
          headers: {
            Authorization: `Bearer ${PAYSTACK_SECRET_KEY.value()}`,
            "Content-Type": "application/json",
          },
          timeout: 15000,
        }
      );

      // Record the intent so the webhook can attribute the payment even if the
      // client never comes back to call verify.
      await db.collection("payment_intents").doc(reference).set({
        uid,
        amount,
        status: "initialized",
        createdAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        authorizationUrl: response.data.data.authorization_url,
        reference: response.data.data.reference,
      };
    } catch (error) {
      // Never surface the provider's raw error to the client.
      logger.error("initializePaystackPayment failed", { uid, ...errorInfo(error) });
      throw new HttpsError("internal", "Could not start the payment. Please try again.");
    }
  }
);

// ==================== PAYMENT: CREDIT (shared core) ====================

/**
 * Verify a reference with Paystack and credit the wallet exactly once.
 *
 * Idempotency: `processed_payments/{reference}` is created inside the same
 * transaction that moves the money. A second call — a retried client, a
 * duplicate webhook, a malicious replay — finds the marker and returns without
 * crediting again. This was the most serious defect in the previous revision:
 * the same reference could be verified unlimited times for unlimited credit.
 *
 * Ownership: the wallet credited is the one named in Paystack's own metadata,
 * not one supplied by the caller, so a reference belonging to another user
 * cannot be redirected.
 */
async function creditVerifiedPayment(
  reference: string,
  expectedUid: string | null
): Promise<{ credited: boolean; amount: number; uid: string }> {
  const response = await axios.get(
    `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,
    {
      headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY.value()}` },
      timeout: 15000,
    }
  );

  const data = response.data?.data;
  if (!data || data.status !== "success") {
    throw new HttpsError("failed-precondition", "Payment was not completed.");
  }

  const paidUid: string | undefined = data.metadata?.userId;
  if (!paidUid) {
    logger.error("Paystack reference carries no userId metadata", { reference });
    throw new HttpsError("failed-precondition", "Payment could not be attributed.");
  }
  if (expectedUid && paidUid !== expectedUid) {
    logger.warn("Caller tried to claim another user's payment", {
      reference,
      expectedUid,
      paidUid,
    });
    throw new HttpsError("permission-denied", "This payment belongs to another account.");
  }

  const amountNaira = toKoboPrecision(data.amount / 100);
  const markerRef = db.collection("processed_payments").doc(reference);

  const credited = await db.runTransaction(async (tx) => {
    const marker = await tx.get(markerRef);
    if (marker.exists) return false; // already credited — replay

    const userRef = db.collection("users").doc(paidUid);
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new HttpsError("not-found", "Account not found.");
    }

    tx.set(markerRef, {
      reference,
      uid: paidUid,
      amount: amountNaira,
      channel: data.channel ?? "unknown",
      processedAt: FieldValue.serverTimestamp(),
    });

    tx.update(userRef, {
      walletBalance: FieldValue.increment(amountNaira),
    });

    tx.set(db.collection("transactions").doc(), {
      userId: paidUid,
      type: "top_up",
      amount: amountNaira,
      description: "Wallet top-up via Paystack",
      paystackReference: reference,
      status: "completed",
      createdAt: FieldValue.serverTimestamp(),
    });

    return true;
  });

  return { credited, amount: amountNaira, uid: paidUid };
}

export const verifyPaystackPayment = onCall(
  { secrets: [PAYSTACK_SECRET_KEY] },
  async (request) => {
    const uid = requireAuth(request);
    await enforceRateLimit(uid, "payment_verify", 20, 60 * 10);

    const reference = String(request.data?.reference ?? "").trim();
    if (!reference || reference.length > 128) {
      throw new HttpsError("invalid-argument", "A payment reference is required.");
    }

    try {
      const result = await creditVerifiedPayment(reference, uid);
      return {
        success: true,
        alreadyProcessed: !result.credited,
        amount: result.amount,
        message: result.credited
          ? `₦${result.amount.toLocaleString()} credited to your wallet.`
          : "This payment has already been credited.",
      };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("verifyPaystackPayment failed", { uid, reference, ...errorInfo(error) });
      throw new HttpsError("internal", "Could not verify the payment.");
    }
  }
);

/**
 * Paystack webhook. Signature-verified, so a forged POST cannot mint credit.
 * Shares the same idempotent credit path as the callable, which means a
 * customer who closes the app mid-payment still gets their wallet funded.
 */
export const paystackWebhook = onRequest(
  { secrets: [PAYSTACK_SECRET_KEY] },
  async (req, res) => {
    const signature = req.headers["x-paystack-signature"];
    const expected = crypto
      .createHmac("sha512", PAYSTACK_SECRET_KEY.value())
      .update(JSON.stringify(req.body))
      .digest("hex");

    if (typeof signature !== "string" || signature !== expected) {
      logger.warn("Rejected webhook with bad signature");
      res.status(401).send("invalid signature");
      return;
    }

    const event = req.body?.event;
    const reference = req.body?.data?.reference;

    if (event !== "charge.success" || !reference) {
      res.status(200).send("ignored");
      return;
    }

    try {
      // expectedUid is null: the webhook is trusted to act for whoever the
      // verified metadata names.
      const result = await creditVerifiedPayment(String(reference), null);
      logger.info("Webhook processed", { reference, credited: result.credited });
      res.status(200).send("ok");
    } catch (error) {
      logger.error("Webhook processing failed", { reference, ...errorInfo(error) });
      // 200 so Paystack does not hot-loop retries on a permanent failure;
      // the error is captured above for investigation.
      res.status(200).send("error logged");
    }
  }
);

// ==================== PROMOTIONS ====================

/**
 * Validate and atomically redeem a promo code.
 *
 * Returns the discount in Naira, or 0 if the code is missing, invalid,
 * expired, exhausted, or already used by this customer.
 *
 * Redemption is recorded at `promo_redemptions/{promoId}_{uid}` and created
 * with `tx.create` in the same transaction that increments `usedCount`, so
 * two orders racing the same code cannot both claim it. The client-supplied
 * `discountAmount` on the order is never trusted — this figure replaces it.
 *
 * A promo is single-use per customer. `maxUses` of 0 means unlimited.
 */
async function redeemPromo(
  code: string,
  uid: string,
  subtotal: number
): Promise<number> {
  // Queries cannot run inside a transaction, so resolve the document first
  // and re-read it by reference under the transaction below.
  const matches = await db
    .collection("promos")
    .where("code", "==", code.trim().toUpperCase())
    .limit(1)
    .get();

  if (matches.empty) return 0;
  const promoRef = matches.docs[0].ref;

  try {
    return await db.runTransaction(async (tx) => {
      const snap = await tx.get(promoRef);
      const promo = snap.data();
      if (!promo) return 0;

      if (promo.isActive === false) return 0;

      const expiresAt = promo.expiresAt?.toDate?.();
      if (expiresAt && expiresAt.getTime() < Date.now()) return 0;

      const minOrder = Number(promo.minOrderAmount) || 0;
      if (subtotal < minOrder) return 0;

      const maxUses = Number(promo.maxUses) || 0;
      const usedCount = Number(promo.usedCount) || 0;
      if (maxUses > 0 && usedCount >= maxUses) return 0;

      const redemptionRef = db
        .collection("promo_redemptions")
        .doc(`${promoRef.id}_${uid}`);
      const existing = await tx.get(redemptionRef);
      if (existing.exists) return 0; // this customer has already used it

      const amount = Number(promo.amount) || 0;
      const discount =
        promo.discountType === "percent"
          ? toKoboPrecision((subtotal * amount) / 100)
          : toKoboPrecision(amount);

      // Never discount below zero, and never below the minimum fare.
      const capped = Math.max(0, Math.min(discount, subtotal - MINIMUM_FARE));
      if (capped <= 0) return 0;

      tx.create(redemptionRef, {
        promoId: promoRef.id,
        code: promo.code,
        userId: uid,
        discount: capped,
        redeemedAt: FieldValue.serverTimestamp(),
      });
      tx.update(promoRef, {
        usedCount: FieldValue.increment(1),
      });

      return capped;
    });
  } catch (error) {
    // A losing race on tx.create means someone else redeemed it first.
    logger.warn("Promo redemption failed", { code, uid, ...errorInfo(error) });
    return 0;
  }
}

// ==================== ORDER CREATED ====================

/**
 * Recompute the fare server-side and notify eligible drivers.
 *
 * The client calculates a fare to show the customer an estimate, and writes it
 * with the order. That value is not trusted: firestore.rules only checks it is
 * a non-negative number, and this trigger immediately overwrites it with a
 * figure derived from the zone configuration. Driver earnings and platform
 * commission are only ever set here.
 */
export const onCourierCreated = onDocumentCreated(
  "couriers/{orderId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const order = snapshot.data();
    const orderId = event.params.orderId;

    try {
      // ---- server-authoritative pricing ----
      const distanceKm = Number(order.estimatedDistanceKm) || 0;
      const weightKg = Number(order.packageWeight) || 0;
      const pickup = order.pickupGeoPoint as GeoPoint | undefined;

      let baseFare = 500;
      let perKmRate = 100;
      let surgeMultiplier = 1.0;

      if (pickup) {
        const zones = await db
          .collection("zones")
          .where("isActive", "==", true)
          .get();
        for (const zoneDoc of zones.docs) {
          const zone = zoneDoc.data();
          const centre = zone.center as GeoPoint | undefined;
          const radiusKm = Number(zone.radiusKm) || 0;
          if (!centre || radiusKm <= 0) continue;
          if (haversineKm(pickup.latitude, pickup.longitude, centre.latitude, centre.longitude) <= radiusKm) {
            baseFare = Number(zone.baseFare) || baseFare;
            perKmRate = Number(zone.perKmRate) || perKmRate;
            surgeMultiplier = Number(zone.currentSurgeMultiplier) || 1.0;
            break;
          }
        }
      }

      let weightSurcharge = 0;
      if (weightKg >= 10) weightSurcharge = 500;
      else if (weightKg >= 5) weightSurcharge = 200;

      const subtotal =
        (baseFare + distanceKm * perKmRate + weightSurcharge) * surgeMultiplier;

      // inDrive-style pricing: the computed fare is a *recommendation*. The
      // customer names their own price, and drivers answer with offers. The
      // customer's figure is honoured only inside the negotiation band, so a
      // patched client cannot book a delivery for ₦1 — anything outside the
      // band is clamped to its edge.
      const recommendedFare = toKoboPrecision(Math.max(subtotal, MINIMUM_FARE));
      const bounds = negotiationBounds(recommendedFare);
      const requested = Number(order.offeredFare) || Number(order.totalFare) || 0;
      const offeredFare = clampToBounds(requested || recommendedFare, bounds);

      // The client writes a promo code and its own idea of the discount. The
      // code is honoured; the amount is recomputed and redeemed atomically
      // here, so a code cannot be applied twice or inflated. The discount is
      // taken off whatever price is finally agreed, in acceptBid.
      const promoCode = typeof order.promoCode === "string" ? order.promoCode : "";
      const discountAmount = promoCode
        ? await redeemPromo(promoCode, order.userId, offeredFare)
        : 0;

      // Provisional figures, recomputed from the accepted offer in acceptBid.
      const split = fareSplit(offeredFare, discountAmount);
      const vehicleType = order.vehicleType === "car" ? "car" : "bike";

      await snapshot.ref.update({
        baseFare: toKoboPrecision(baseFare),
        surgeMultiplier,
        discountAmount,
        recommendedFare,
        offeredFare,
        offerAdjusted: requested > 0 && offeredFare !== toKoboPrecision(requested),
        vehicleType,
        totalFare: split.totalFare,
        platformCommission: split.platformCommission,
        driverEarnings: split.driverEarnings,
        fareAuthoritative: true,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // ---- dispatch: only drivers whose vehicle can serve this booking ----
      const driversSnapshot = await db
        .collection("driver_locations")
        .where("isOnline", "==", true)
        .where("isAvailable", "==", true)
        .limit(100)
        .get();

      const eligible = driversSnapshot.docs.filter((d) =>
        driverCanServe(d.data().vehicleType, vehicleType)
      );

      if (eligible.length === 0) {
        logger.info("No available drivers for vehicle type", { orderId, vehicleType });
        return;
      }

      const driverIds = eligible.slice(0, 50).map((d) => d.id);
      const driverDocs = await db.getAll(
        ...driverIds.map((id) => db.collection("users").doc(id))
      );

      const tokens: string[] = [];
      const notifyBatch = db.batch();

      for (const driverDoc of driverDocs) {
        const token = driverDoc.data()?.fcmToken;
        if (token && pushAllowed(driverDoc.data(), "order")) tokens.push(token);

        notifyBatch.set(
          db.collection("users").doc(driverDoc.id).collection("notifications").doc(),
          {
            title: "New Delivery Request",
            body: `${order.pickupAddress} → ${order.dropoffAddress}`,
            type: "order_update",
            orderId,
            isRead: false,
            createdAt: FieldValue.serverTimestamp(),
          }
        );
      }
      await notifyBatch.commit();

      if (tokens.length === 0) return;

      const response = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: `🚀 New ${vehicleType} delivery · offer ₦${offeredFare.toFixed(0)}`,
          body: `${order.pickupAddress} → ${order.dropoffAddress}`,
        },
        data: {
          type: "new_order",
          orderId,
          pickupAddress: order.pickupAddress ?? "",
          offeredFare: String(offeredFare),
          vehicleType,
        },
        android: {
          priority: "high",
          notification: { channelId: "dilivvafast_default", sound: "default" },
        },
        apns: { payload: { aps: { sound: "default", badge: 1 } } },
      });

      logger.info("Dispatch notifications sent", {
        orderId,
        sent: response.successCount,
        failed: response.failureCount,
      });
    } catch (error) {
      logger.error("onCourierCreated error", { orderId, ...errorInfo(error) });
    }
  }
);

function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ==================== PRICE NEGOTIATION ====================
//
// inDrive-style bargaining. The customer names a price; drivers answer with
// offers at or above it; the customer picks one. Three invariants hold
// throughout, and every path below exists to protect one of them:
//
//   1. No price outside the negotiation band ever reaches an order.
//   2. A driver is assigned only by the customer accepting their offer, and
//      only once — two concurrent accepts cannot both win.
//   3. The agreed price is the stored offer, never a figure the client sends.
//
// Mirrored on the client in NegotiationBounds (lib/.../courier_bid.dart).

const FLOOR_RATIO = 0.7;
const CEILING_RATIO = 3.0;

interface Bounds {
  floor: number;
  ceiling: number;
}

function negotiationBounds(recommendedFare: number): Bounds {
  const ratioFloor = Math.ceil((recommendedFare * FLOOR_RATIO) / 50) * 50;
  const floor = Math.max(MINIMUM_FARE, ratioFloor);
  const ceiling = Math.max(floor, toKoboPrecision(recommendedFare * CEILING_RATIO));
  return { floor, ceiling };
}

function clampToBounds(value: number, bounds: Bounds): number {
  if (!Number.isFinite(value)) return bounds.floor;
  return toKoboPrecision(Math.min(Math.max(value, bounds.floor), bounds.ceiling));
}

/** What the customer pays, and how it divides, for an agreed price. */
function fareSplit(agreedFare: number, discountAmount: number) {
  const totalFare = toKoboPrecision(Math.max(agreedFare - discountAmount, MINIMUM_FARE));
  // Commission is taken on the agreed price, not the discounted one: the
  // platform funds the promo, the driver is not charged for it.
  const platformCommission = toKoboPrecision(agreedFare * PLATFORM_COMMISSION_RATE);
  const driverEarnings = toKoboPrecision(agreedFare - platformCommission);
  return { totalFare, platformCommission, driverEarnings };
}

/** Driver vehicle types (from the application) that can serve a booking. */
function driverCanServe(driverVehicleType: unknown, bookingVehicle: string): boolean {
  const v = String(driverVehicleType ?? "");
  // Drivers approved before presence carried a vehicle type are offered every
  // job rather than none; the bid rule still checks their real vehicle.
  if (!v) return true;
  return bookingVehicle === "car"
    ? v === "car" || v === "van"
    : v === "motorcycle" || v === "bicycle";
}

/**
 * Fill in who placed an offer, and tell the customer.
 *
 * The driver's device writes only `amount`, `etaMinutes` and `status` —
 * firestore.rules rejects anything else. The identity a customer chooses on
 * (name, photo, rating, vehicle, plate) is copied here from the driver's own
 * record, so it cannot be forged by the bidder.
 */
export const onBidWritten = onDocumentWritten(
  "couriers/{orderId}/bids/{driverId}",
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return; // withdrawn

    const bid = after.data()!;
    const before = event.data?.before?.data();
    const { orderId, driverId } = event.params;

    // Only react to the driver's own writes. A driver's set() replaces the
    // whole document and so wipes the fields filled in below, which makes a
    // missing driverName the reliable signal: it covers a fresh offer, a new
    // amount, and re-offering the same amount after a decline. The update
    // below sets driverName, so it does not loop back through here, and
    // status changes made by acceptBid leave it in place.
    if (bid.status !== "open") return;
    const amountChanged = !!before && before.amount !== bid.amount;
    if (bid.driverName && !amountChanged) return;

    try {
      const [driverSnap, orderSnap] = await Promise.all([
        db.collection("users").doc(driverId).get(),
        db.collection("couriers").doc(orderId).get(),
      ]);
      const driver = driverSnap.data();
      const order = orderSnap.data();

      // Defence in depth: the rules already require these, but an offer on
      // a closed request or from a non-driver is removed rather than shown.
      const isDriver =
        driver?.driverStatus === "approved" || driver?.role === "driver";
      if (!order || !driver || !isDriver || order.status !== "pending" || order.driverId) {
        await after.ref.delete();
        return;
      }

      const bounds = negotiationBounds(Number(order.recommendedFare) || MINIMUM_FARE);
      const amount = Number(bid.amount);
      if (!Number.isFinite(amount) || amount < Number(order.offeredFare) || amount > bounds.ceiling) {
        await after.ref.delete();
        return;
      }

      await after.ref.update({
        driverName: String(driver.fullName ?? "Courier").split(" ")[0],
        driverPhotoUrl: driver.photoUrl ?? null,
        driverRating: Number(driver.rating) || 0,
        driverTrips: Number(driver.totalDeliveries) || 0,
        vehicleLabel: driver.vehicleType ?? null,
        vehiclePlate: driver.vehiclePlate ?? null,
        updatedAt: FieldValue.serverTimestamp(),
      });

      await sendToUser(
        order.userId,
        {
          title: `New offer: ₦${amount.toFixed(0)}`,
          body: `A courier is ready to take your delivery. Tap to review offers.`,
        },
        { type: "new_bid", orderId, driverId, amount: String(amount) },
        "order"
      );
    } catch (error) {
      logger.error("onBidWritten failed", { orderId, driverId, ...errorInfo(error) });
    }
  }
);

/**
 * Customer accepts one driver's offer.
 *
 * Runs as a single transaction: it re-reads the order and the offer, checks
 * the order is still the caller's, still pending and still unassigned, then
 * assigns the driver and fixes the price from the stored offer. A second
 * accept — a double tap, or a race between two offers — finds the order
 * already assigned and fails cleanly. Every other open offer is closed.
 */
export const acceptBid = onCall(async (request) => {
  const uid = requireAuth(request);
  await enforceRateLimit(uid, "accept_bid", 20, 60 * 10);

  const orderId = String(request.data?.orderId ?? "").trim();
  const driverId = String(request.data?.driverId ?? "").trim();
  if (!orderId || !driverId) {
    throw new HttpsError("invalid-argument", "An order and an offer are required.");
  }

  const orderRef = db.collection("couriers").doc(orderId);
  const bidRef = orderRef.collection("bids").doc(driverId);

  // Two accepts racing for one request — or an accept racing the trigger
  // that fills in the driver's details on the offer — contend on the same
  // documents. Firestore retries a contended transaction; the default five
  // attempts is not always enough when both sides keep retrying, and then
  // *both* fail. Ten attempts makes that vanishingly rare, and if it still
  // happens the caller gets a retryable error rather than a generic one.
  let agreed: number;
  try {
    agreed = await db.runTransaction(async (tx) => {
    const [orderSnap, bidSnap] = await Promise.all([tx.get(orderRef), tx.get(bidRef)]);
    const order = orderSnap.data();
    const bid = bidSnap.data();

    if (!order) throw new HttpsError("not-found", "That request no longer exists.");
    if (order.userId !== uid) {
      throw new HttpsError("permission-denied", "That is not your request.");
    }
    if (order.status !== "pending" || order.driverId) {
      throw new HttpsError("failed-precondition", "This request already has a courier.");
    }
    if (!bid || bid.status !== "open") {
      throw new HttpsError("failed-precondition", "That offer is no longer available.");
    }

    const bounds = negotiationBounds(Number(order.recommendedFare) || MINIMUM_FARE);
    const agreedFare = clampToBounds(Number(bid.amount), bounds);
    const split = fareSplit(agreedFare, Number(order.discountAmount) || 0);

    tx.update(orderRef, {
      driverId,
      status: "accepted",
      agreedFare,
      totalFare: split.totalFare,
      platformCommission: split.platformCommission,
      driverEarnings: split.driverEarnings,
      acceptedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(bidRef, { status: "accepted", decidedAt: FieldValue.serverTimestamp() });

    return agreedFare;
  }, { maxAttempts: 10 });
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    const code = (error as { code?: unknown })?.code;
    if (code === 10 || code === "aborted" || code === "ABORTED") {
      throw new HttpsError("aborted", "Busy right now — please try again.");
    }
    logger.error("acceptBid failed", { orderId, driverId, ...errorInfo(error) });
    throw new HttpsError("internal", "Could not accept that offer.");
  }

  // Close the losing offers outside the transaction — best effort, and the
  // order is already assigned so no stale offer can be accepted regardless.
  const others = await orderRef.collection("bids").where("status", "==", "open").get();
  if (!others.empty) {
    const batch = db.batch();
    others.docs.forEach((d) =>
      batch.update(d.ref, { status: "declined", decidedAt: FieldValue.serverTimestamp() })
    );
    await batch.commit();
  }

  // The winning driver is no longer free for other jobs.
  await db
    .collection("driver_locations")
    .doc(driverId)
    .set({ isAvailable: false }, { merge: true })
    .catch(() => undefined);

  await sendToUser(
    driverId,
    {
      title: "Your offer was accepted 🎉",
      body: `₦${agreed.toFixed(0)} — head to the pickup point.`,
    },
    { type: "bid_accepted", orderId },
    "order"
  );

  return { success: true, agreedFare: agreed };
});

/**
 * Customer raises their offer while waiting, as inDrive allows.
 *
 * Only upwards, only while the request is still open, and never past the
 * ceiling. Lowering is not offered: drivers who already answered at the old
 * price would otherwise be holding offers below the customer's own.
 */
export const raiseOffer = onCall(async (request) => {
  const uid = requireAuth(request);
  await enforceRateLimit(uid, "raise_offer", 15, 60 * 10);

  const orderId = String(request.data?.orderId ?? "").trim();
  const amount = Number(request.data?.amount);
  if (!orderId || !Number.isFinite(amount)) {
    throw new HttpsError("invalid-argument", "An order and an amount are required.");
  }

  const orderRef = db.collection("couriers").doc(orderId);

  const offeredFare = await db.runTransaction(async (tx) => {
    const snap = await tx.get(orderRef);
    const order = snap.data();
    if (!order) throw new HttpsError("not-found", "That request no longer exists.");
    if (order.userId !== uid) {
      throw new HttpsError("permission-denied", "That is not your request.");
    }
    if (order.status !== "pending" || order.driverId) {
      throw new HttpsError("failed-precondition", "This request already has a courier.");
    }

    const current = Number(order.offeredFare) || 0;
    if (amount <= current) {
      throw new HttpsError("invalid-argument", "A new offer must be higher than your current one.");
    }

    const bounds = negotiationBounds(Number(order.recommendedFare) || MINIMUM_FARE);
    const next = clampToBounds(amount, bounds);
    const split = fareSplit(next, Number(order.discountAmount) || 0);

    tx.update(orderRef, {
      offeredFare: next,
      totalFare: split.totalFare,
      platformCommission: split.platformCommission,
      driverEarnings: split.driverEarnings,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return next;
  });

  return { success: true, offeredFare };
});

// ==================== ORDER STATUS CHANGED ====================

/**
 * Notify the customer as their delivery progresses.
 *
 * Status keys are the camelCase names OrderStatus.name produces (`pickedUp`,
 * `inTransit`). The previous revision keyed on snake_case, so even once the
 * collection name was right those two transitions produced no notification.
 */
export const onCourierStatusChanged = onDocumentUpdated(
  "couriers/{orderId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const orderId = event.params.orderId;

    if (!before || !after) return;
    if (before.status === after.status) return;

    // Keys are the snake_case @JsonValue forms CourierOrderModel serialises
    // to. The camelCase aliases cover documents written by older builds,
    // which used the Dart enum `.name` instead.
    const statusMessages: Record<string, string> = {
      accepted: "A driver has accepted your delivery! 🎉",
      picked_up: "Your package has been picked up 📦",
      pickedUp: "Your package has been picked up 📦",
      in_transit: "Your package is on its way! 🚀",
      inTransit: "Your package is on its way! 🚀",
      delivered: "Your package has been delivered! ✅",
      cancelled: "Your order has been cancelled ❌",
      failed: "Your delivery could not be completed.",
    };

    const statusMsg = statusMessages[after.status];
    if (!statusMsg) return;

    try {
      await sendToUser(
        after.userId,
        { title: `Order ${after.trackingCode ?? ""}`.trim(), body: statusMsg },
        { type: "order_update", orderId, status: String(after.status) },
        "order"
      );

      await db
        .collection("users")
        .doc(after.userId)
        .collection("notifications")
        .add({
          title: `Order ${after.trackingCode ?? ""}`.trim(),
          body: statusMsg,
          type: "order_update",
          orderId,
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
        });

      if (after.status === "delivered") {
        await completeReferralOnFirstDelivery(after.userId);
      }

      // Free the driver up again once the job leaves an active state.
      if (["delivered", "cancelled", "failed"].includes(after.status) && after.driverId) {
        await db
          .collection("driver_locations")
          .doc(after.driverId)
          .set({ isAvailable: true }, { merge: true })
          .catch(() => undefined);
      }
    } catch (error) {
      logger.error("onCourierStatusChanged error", { orderId, ...errorInfo(error) });
    }
  }
);

// ==================== SCHEDULED: DRIVER PAYOUT ====================

/**
 * Daily driver payout.
 *
 * Idempotency: each driver-day is keyed `payouts/{driverId}_{YYYY-MM-DD}` and
 * created with `tx.create`, which fails if the document already exists. Pub/Sub
 * delivers at-least-once, so without this a redelivery — or a manual re-run —
 * paid every driver twice. The wallet increment and the ledger entry share the
 * transaction, so a retry after a partial failure cannot double-credit either.
 */
export const processDriverPayout = onSchedule(
  { schedule: "0 1 * * *", timeZone: "Africa/Lagos" },
  async () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const periodKey = yesterday.toISOString().slice(0, 10); // YYYY-MM-DD

    try {
      const ordersSnapshot = await db
        .collection("couriers")
        .where("status", "==", "delivered")
        .where("deliveredAt", ">=", yesterday)
        .where("deliveredAt", "<", today)
        .get();

      if (ordersSnapshot.empty) {
        logger.info("No delivered orders to pay out", { periodKey });
        return;
      }

      const earningsByDriver: Record<string, { total: number; orderIds: string[] }> = {};
      for (const doc of ordersSnapshot.docs) {
        const order = doc.data();
        if (!order.driverId || !order.driverEarnings) continue;
        const entry = earningsByDriver[order.driverId] ?? { total: 0, orderIds: [] };
        entry.total += Number(order.driverEarnings) || 0;
        entry.orderIds.push(doc.id);
        earningsByDriver[order.driverId] = entry;
      }

      let paid = 0;
      let skipped = 0;

      for (const [driverId, entry] of Object.entries(earningsByDriver)) {
        const amount = toKoboPrecision(entry.total);
        if (amount <= 0) continue;

        const payoutRef = db.collection("payouts").doc(`${driverId}_${periodKey}`);

        try {
          await db.runTransaction(async (tx) => {
            const existing = await tx.get(payoutRef);
            if (existing.exists) {
              throw new Error("ALREADY_PAID");
            }

            // create() rather than set(): if a concurrent run wrote this doc
            // between the read and the commit, the transaction aborts.
            tx.create(payoutRef, {
              driverId,
              periodKey,
              amount,
              orderCount: entry.orderIds.length,
              orderIds: entry.orderIds,
              status: "completed",
              createdAt: FieldValue.serverTimestamp(),
            });

            tx.update(db.collection("users").doc(driverId), {
              walletBalance: FieldValue.increment(amount),
            });

            tx.set(db.collection("transactions").doc(), {
              userId: driverId,
              type: "delivery_earning",
              amount,
              description: `Daily earnings for ${periodKey}`,
              payoutId: payoutRef.id,
              status: "completed",
              createdAt: FieldValue.serverTimestamp(),
            });
          });
          paid++;
        } catch (error) {
          if ((error as Error).message === "ALREADY_PAID") {
            skipped++;
            continue;
          }
          logger.error("Payout failed for driver", { driverId, periodKey, ...errorInfo(error) });
        }
      }

      logger.info("Payout run complete", { periodKey, paid, skipped });
    } catch (error) {
      // Rethrow so Cloud Scheduler records the run as FAILED. Swallowing this
      // made a missing index look like a quiet night: the query failed, the
      // run "succeeded", and no driver was paid. A retry is safe — each
      // driver-day payout is created at most once (see above).
      logger.error("processDriverPayout error", { periodKey, ...errorInfo(error) });
      throw error;
    }
  }
);

// ==================== RATING CREATED ====================

/**
 * Recalculate a driver's average rating.
 *
 * Writes `rating` / `totalRatings`. The previous revision wrote
 * `averageRating`, a field UserModel does not read, so ratings never surfaced
 * anywhere in the app.
 */
export const onRatingCreated = onDocumentCreated(
  "ratings/{ratingId}",
  async (event) => {
    const rating = event.data?.data();
    if (!rating?.driverId) return;

    try {
      const ratingsSnapshot = await db
        .collection("ratings")
        .where("driverId", "==", rating.driverId)
        .get();

      let total = 0;
      let count = 0;
      ratingsSnapshot.forEach((doc) => {
        const value = Number(doc.data().rating);
        if (Number.isFinite(value) && value > 0) {
          total += value;
          count++;
        }
      });

      const average = count > 0 ? total / count : 0;

      await db.collection("users").doc(rating.driverId).update({
        rating: Math.round(average * 10) / 10,
        totalRatings: count,
      });
    } catch (error) {
      logger.error("onRatingCreated error", errorInfo(error));
    }
  }
);

// ==================== REFERRAL COMPLETED ====================

/**
 * Credit both parties once a referral completes. Guarded by a `bonusPaidAt`
 * marker written in the same transaction, so flipping the status back and
 * forth cannot mint repeated bonuses.
 */
/**
 * Attach the referrer to a new referral.
 *
 * Referral documents are keyed by the referee's uid (one per account) and
 * carry only the code they typed. Nothing used to resolve that code, so
 * `referrerId` was never set, `onReferralCompleted` returned early, and no
 * referral bonus was ever paid. Resolving it here also lets the referrer see
 * the referral in Refer & Earn while it is pending.
 */
export const onReferralCreated = onDocumentCreated(
  "referrals/{referralId}",
  async (event) => {
    const referral = event.data?.data();
    if (!referral || !event.data) return;

    const refereeId = event.params.referralId;
    const code = String(referral.referralCode ?? "").trim().toUpperCase();

    try {
      const snap = code
        ? await db.collection("users").where("referralCode", "==", code).limit(1).get()
        : null;
      const referrerId = snap && !snap.empty ? snap.docs[0].id : null;

      if (!referrerId || referrerId === refereeId) {
        await event.data.ref.update({ status: "invalid" });
        return;
      }
      await event.data.ref.update({ referrerId, refereeId });
    } catch (error) {
      logger.error("onReferralCreated error", { refereeId, ...errorInfo(error) });
    }
  }
);

/**
 * Mark a customer's referral complete once their first delivery lands, which
 * releases both bonuses through `onReferralCompleted`.
 *
 * "First" is checked against delivered orders, so a referral recorded after
 * an account already has deliveries never qualifies.
 */
async function completeReferralOnFirstDelivery(customerId: unknown): Promise<void> {
  if (typeof customerId !== "string" || !customerId) return;

  const referralRef = db.collection("referrals").doc(customerId);
  const referral = (await referralRef.get()).data();
  if (!referral || referral.status !== "pending" || !referral.referrerId) return;

  const delivered = await db
    .collection("couriers")
    .where("userId", "==", customerId)
    .where("status", "==", "delivered")
    .limit(2)
    .get();
  if (delivered.size !== 1) return;

  await referralRef.update({
    status: "completed",
    completedAt: FieldValue.serverTimestamp(),
  });
}

export const onReferralCompleted = onDocumentUpdated(
  "referrals/{referralId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === "completed" || after.status !== "completed") return;

    const referralRef = event.data!.after.ref;
    const { referrerId, refereeId } = after;
    if (!referrerId || !refereeId) return;

    try {
      const credited = await db.runTransaction(async (tx) => {
        const current = await tx.get(referralRef);
        if (current.data()?.bonusPaidAt) return false;

        tx.update(referralRef, {
          bonusPaid: true,
          bonusPaidAt: FieldValue.serverTimestamp(),
        });

        for (const uid of [referrerId, refereeId]) {
          tx.update(db.collection("users").doc(uid), {
            walletBalance: FieldValue.increment(REFERRAL_BONUS),
          });
          tx.set(db.collection("transactions").doc(), {
            userId: uid,
            type: "referral_bonus",
            amount: REFERRAL_BONUS,
            description:
              uid === referrerId
                ? "Referral bonus — your friend completed their first delivery!"
                : "Welcome bonus — thanks for joining Dilivvafast!",
            status: "completed",
            createdAt: FieldValue.serverTimestamp(),
          });
        }
        return true;
      });

      if (!credited) return;

      await sendToUser(
        referrerId,
        {
          title: "Referral Bonus! 🎉",
          body: `You earned ₦${REFERRAL_BONUS} — your friend just completed their first delivery!`,
        },
        { type: "referral_bonus" }
      );
    } catch (error) {
      logger.error("onReferralCompleted error", errorInfo(error));
    }
  }
);

// ==================== SOS ====================

export const onSosTriggered = onDocumentCreated(
  "sos_alerts/{alertId}",
  async (event) => {
    const alert = event.data?.data();
    if (!alert) return;

    try {
      const adminsSnapshot = await db
        .collection("users")
        .where("role", "==", "admin")
        .get();

      const tokens: string[] = [];
      adminsSnapshot.forEach((doc) => {
        const token = doc.data().fcmToken;
        if (token) tokens.push(token);
      });

      if (tokens.length === 0) {
        logger.warn("SOS raised but no admin FCM tokens registered");
        return;
      }

      const userDoc = await db.collection("users").doc(alert.userId).get();
      const userName = userDoc.data()?.fullName ?? "Unknown user";

      await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "🚨 SOS ALERT — URGENT",
          body: `${userName} triggered an SOS. Open the admin console for location and order details.`,
        },
        data: {
          type: "sos_alert",
          alertId: event.params.alertId,
          userId: String(alert.userId ?? ""),
          orderId: String(alert.orderId ?? ""),
        },
        android: {
          priority: "high",
          notification: { channelId: "sos_channel", sound: "alarm" },
        },
        apns: {
          payload: { aps: { sound: "alarm.caf", badge: 1, "content-available": 1 } },
        },
      });
    } catch (error) {
      logger.error("onSosTriggered error", errorInfo(error));
    }
  }
);

// ==================== WEEKLY DRIVER REPORT ====================

export const weeklyDriverReport = onSchedule(
  { schedule: "0 8 * * 1", timeZone: "Africa/Lagos" },
  async () => {
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

    try {
      const driversSnapshot = await db
        .collection("users")
        .where("role", "==", "driver")
        .get();

      for (const driverDoc of driversSnapshot.docs) {
        const driverId = driverDoc.id;

        const ordersSnapshot = await db
          .collection("couriers")
          .where("driverId", "==", driverId)
          .where("status", "==", "delivered")
          .where("deliveredAt", ">=", oneWeekAgo)
          .get();

        const totalDeliveries = ordersSnapshot.size;
        if (totalDeliveries === 0) continue;

        let totalEarnings = 0;
        ordersSnapshot.forEach((doc) => {
          totalEarnings += Number(doc.data().driverEarnings) || 0;
        });
        totalEarnings = toKoboPrecision(totalEarnings);

        await db
          .collection("users")
          .doc(driverId)
          .collection("weekly_reports")
          .add({
            weekEnding: FieldValue.serverTimestamp(),
            totalDeliveries,
            totalEarnings,
            averagePerDelivery: toKoboPrecision(totalEarnings / totalDeliveries),
            createdAt: FieldValue.serverTimestamp(),
          });

        await sendToUser(
          driverId,
          {
            title: "📊 Weekly Report",
            body: `Last week: ${totalDeliveries} deliveries, ₦${totalEarnings.toLocaleString()} earned. Keep it up!`,
          },
          { type: "weekly_report" }
        );
      }
    } catch (error) {
      logger.error("weeklyDriverReport error", errorInfo(error));
    }
  }
);

// ==================== ROLE ADMINISTRATION ====================

/**
 * Grant or revoke privileged roles.
 *
 * Roles live in a custom claim, which no client can write. The mirrored `role`
 * field on the user document is kept in step for the existing UI, but it is no
 * longer the source of truth for anything security-sensitive.
 *
 * Bootstrapping the very first administrator cannot be done from the app — see
 * SECURITY.md, "Bootstrapping the first admin".
 */
export const setUserRole = onCall(async (request) => {
  const actorUid = await requireAdmin(request);

  const targetUid = String(request.data?.uid ?? "").trim();
  const role = String(request.data?.role ?? "").trim();
  const allowedRoles = ["customer", "driver", "support", "dispatcher", "admin"];

  if (!targetUid) throw new HttpsError("invalid-argument", "A target uid is required.");
  if (!allowedRoles.includes(role)) {
    throw new HttpsError("invalid-argument", `Role must be one of: ${allowedRoles.join(", ")}`);
  }
  if (targetUid === actorUid && role !== "admin") {
    throw new HttpsError(
      "failed-precondition",
      "You cannot remove your own administrator access."
    );
  }

  await getAuth().setCustomUserClaims(targetUid, {
    admin: role === "admin",
    role,
  });

  await db.collection("users").doc(targetUid).update({
    role,
    updatedAt: FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid,
    action: "set_user_role",
    targetUid,
    details: { role },
  });

  return { success: true, uid: targetUid, role };
});

/**
 * Approve or reject a driver application, with an audit trail.
 *
 * The admin UI used to write the application record and the user entitlement
 * straight to Firestore. That worked — admins may write both — but it left no
 * audit trail for a decision that grants someone the ability to earn money on
 * the platform. Routing it through here records who decided what, and when.
 */
export const reviewDriverApplication = onCall(async (request) => {
  const actorUid = await requireAdmin(request);

  const targetUid = String(request.data?.uid ?? "").trim();
  const decision = String(request.data?.decision ?? "").trim();
  const reason = String(request.data?.reason ?? "").slice(0, 500);
  const applicationId = String(request.data?.applicationId ?? "").trim();
  const vehicleType = String(request.data?.vehicleType ?? "").slice(0, 80);
  const vehiclePlate = String(request.data?.vehiclePlate ?? "").slice(0, 40);

  if (!targetUid) throw new HttpsError("invalid-argument", "A target uid is required.");
  if (!["approved", "rejected", "suspended"].includes(decision)) {
    throw new HttpsError("invalid-argument", "Decision must be approved, rejected or suspended.");
  }

  // The application record and the entitlement must agree, so they move
  // together.
  const batch = db.batch();

  batch.update(db.collection("users").doc(targetUid), {
    driverStatus: decision,
    ...(decision === "approved" && vehicleType ? { vehicleType } : {}),
    ...(decision === "approved" && vehiclePlate ? { vehiclePlate } : {}),
    updatedAt: FieldValue.serverTimestamp(),
  });

  if (applicationId) {
    batch.update(db.collection("driver_applications").doc(applicationId), {
      status: decision,
      reviewedAt: FieldValue.serverTimestamp(),
      reviewedBy: actorUid,
    });
  }

  await batch.commit();

  await writeAuditLog({
    actorUid,
    action: "review_driver_application",
    targetUid,
    details: { decision, reason, applicationId },
  });

  await sendToUser(
    targetUid,
    {
      title: decision === "approved" ? "Driver application approved 🎉" : "Driver application update",
      body:
        decision === "approved"
          ? "You can now go online and accept deliveries."
          : "Your application status has changed. Open the app for details.",
    },
    { type: "driver_application", decision }
  );

  return { success: true };
});

// ==================== DRIVER DOCUMENT ACCESS ====================

/** Upload keys used by driver_application_screen. */
const DRIVER_DOC_KEYS = [
  "drivers_license",
  "vehicle_photo",
  "government_id",
] as const;

/**
 * Mint a short-lived signed URL for one driver identity document.
 *
 * Why this exists: `getDownloadURL()` mints a token that lives forever and
 * bypasses storage.rules entirely — anyone who obtains the link can read a
 * driver's licence or government ID, with no way to revoke it short of
 * deleting the object. Storing those URLs on the user document meant a leak of
 * that document was a leak of the identity papers behind it.
 *
 * A signed URL expires in 15 minutes and is minted only for a caller we have
 * just authorised. Every access is written to admin_audit_log, because reading
 * somebody's identity documents is exactly the kind of privileged act that
 * should leave a trace.
 *
 * DEPLOYMENT NOTE: signing requires the runtime service account to hold the
 * "Service Account Token Creator" role on itself. Without it this throws
 * "Permission iam.serviceAccounts.signBlob is required". See DEPLOYMENT.md.
 */
export const getDriverDocumentUrl = onCall(async (request) => {
  const uid = requireAuth(request);

  const targetUid = String(request.data?.uid ?? "").trim();
  const docKey = String(request.data?.docKey ?? "").trim();

  if (!targetUid) {
    throw new HttpsError("invalid-argument", "A driver uid is required.");
  }
  if (!(DRIVER_DOC_KEYS as readonly string[]).includes(docKey)) {
    // Rejecting anything off the list stops a caller walking the bucket by
    // feeding arbitrary path fragments in here.
    throw new HttpsError("invalid-argument", "Unknown document type.");
  }

  // A driver may fetch their own documents; anyone else must be an admin.
  let isAdminCaller = false;
  if (targetUid !== uid) {
    await requireAdmin(request);
    isAdminCaller = true;
  }

  await enforceRateLimit(uid, "driver_doc_url", 60, 60 * 10);

  const path = `driver_applications/${targetUid}/${docKey}.jpg`;

  try {
    const file = getStorage().bucket().file(path);

    const [exists] = await file.exists();
    if (!exists) {
      throw new HttpsError("not-found", "That document has not been uploaded.");
    }

    const [url] = await file.getSignedUrl({
      action: "read",
      expires: Date.now() + 15 * 60 * 1000,
    });

    if (isAdminCaller) {
      await writeAuditLog({
        actorUid: uid,
        action: "view_driver_document",
        targetUid,
        details: { docKey },
      });
    }

    return { url, expiresInSeconds: 900 };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error("getDriverDocumentUrl failed", {
      uid,
      targetUid,
      docKey,
      ...errorInfo(error),
    });
    throw new HttpsError("internal", "Could not open that document.");
  }
});

// ==================== REFERRAL CODE LOOKUP ====================

/**
 * Resolve a referral code to a user id.
 *
 * The client used to query `users` by `referralCode` directly, which the
 * tightened rules correctly deny — reading arbitrary user documents is exactly
 * what we are trying to prevent. Only the referrer's uid is returned.
 */
export const lookupReferralCode = onCall(async (request) => {
  const uid = requireAuth(request);
  await enforceRateLimit(uid, "referral_lookup", 20, 60 * 10);

  const code = String(request.data?.code ?? "").trim().toUpperCase();
  if (!code || code.length > 32) {
    throw new HttpsError("invalid-argument", "A referral code is required.");
  }

  const snap = await db
    .collection("users")
    .where("referralCode", "==", code)
    .limit(1)
    .get();

  if (snap.empty) return { found: false };
  if (snap.docs[0].id === uid) {
    throw new HttpsError("failed-precondition", "You cannot refer yourself.");
  }

  return { found: true, referrerId: snap.docs[0].id };
});

// ==================== SUPPORT CHAT ====================

/**
 * Route support messages to whoever has to read them next.
 *
 * Threads live at `orders/support_{uid}` (see firestore.rules). Until this
 * existed nothing told anyone a customer had written in, and there was no
 * inbox to read it from, so every message went unanswered. A customer's
 * message now updates the thread summary the admin inbox lists and alerts the
 * admins; an admin's reply notifies the customer.
 */
export const onSupportMessageCreated = onDocumentCreated(
  "orders/{threadId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    const threadId = event.params.threadId;
    if (!message || !threadId.startsWith("support_")) return;

    const ownerId = threadId.slice("support_".length);
    const fromCustomer = message.senderId === ownerId;
    const preview = String(message.text ?? "").slice(0, 140);

    try {
      const owner = (await db.collection("users").doc(ownerId).get()).data();
      await db.collection("orders").doc(threadId).set(
        {
          userId: ownerId,
          userName: owner?.fullName ?? "Customer",
          lastMessage: preview,
          lastSenderId: String(message.senderId ?? ""),
          needsReply: fromCustomer,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      if (!fromCustomer) {
        await sendToUser(
          ownerId,
          { title: "Dilivvafast Support replied", body: preview },
          { type: "support_reply" }
        );
        return;
      }

      const admins = await db.collection("users").where("role", "==", "admin").get();
      const tokens = admins.docs
        .map((d) => d.data().fcmToken)
        .filter((t): t is string => typeof t === "string" && t.length > 0);
      if (tokens.length === 0) {
        logger.warn("Support message received but no admin FCM tokens registered", {
          threadId,
        });
        return;
      }
      await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: `Support: ${owner?.fullName ?? "Customer"}`,
          body: preview,
        },
        data: { type: "support_message", userId: ownerId },
      });
    } catch (error) {
      logger.error("onSupportMessageCreated error", { threadId, ...errorInfo(error) });
    }
  }
);

// ==================== ACCOUNT DELETION ====================

/** Order states in which someone is still relying on this account. */
const ACTIVE_ORDER_STATES = [
  "pending",
  "accepted",
  "picked_up",
  "in_transit",
  "pickedUp",
  "inTransit",
];

/**
 * Delete the caller's account and personal data (required by Google Play).
 *
 * The client used to delete the profile document and then the Auth user.
 * Firebase routinely refuses the second step with `requires-recent-login`,
 * which left a signed-in account with no profile: the router waits for a
 * profile that will never arrive. The Admin SDK has no such requirement, so
 * both steps now happen here, with the Auth user removed last.
 *
 * Kept: delivery records, ratings and the wallet/payout ledgers, which the
 * other party and the accounts rely on. They reference only the uid, which no
 * longer resolves to a person once the profile is gone. See PLAY_STORE.md.
 */
export const deleteMyAccount = onCall(async (request) => {
  const uid = requireAuth(request);
  await enforceRateLimit(uid, "delete_account", 5, 60 * 10);

  const [asCustomer, asDriver, investorSnap] = await Promise.all([
    db
      .collection("couriers")
      .where("userId", "==", uid)
      .where("status", "in", ACTIVE_ORDER_STATES)
      .limit(1)
      .get(),
    db
      .collection("couriers")
      .where("driverId", "==", uid)
      .where("status", "in", ACTIVE_ORDER_STATES)
      .limit(1)
      .get(),
    db.collection("investors").doc(uid).get(),
  ]);

  if (!asCustomer.empty || !asDriver.empty) {
    throw new HttpsError(
      "failed-precondition",
      "You have a delivery in progress. Finish or cancel it, then try again."
    );
  }
  const investor = investorSnap.data();
  if ((investor?.activeBikes ?? 0) > 0 || (investor?.pendingWithdrawal ?? 0) > 0) {
    throw new HttpsError(
      "failed-precondition",
      "Your investor account has active bikes or a pending withdrawal. " +
        "Contact support to close it."
    );
  }

  const byUser = async (collection: string, field: string) => {
    const snap = await db.collection(collection).where(field, "==", uid).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  };

  // Profile plus its sub-collections (notifications, saved addresses, cards),
  // which are not removed with their parent document.
  await db.recursiveDelete(db.collection("users").doc(uid));
  await db.recursiveDelete(db.collection("orders").doc(`support_${uid}`));
  await Promise.all([
    byUser("notifications", "userId"),
    byUser("driver_applications", "userId"),
    byUser("referrals", "refereeId"),
    db.collection("driver_locations").doc(uid).delete(),
    db.collection("investors").doc(uid).delete(),
  ]);

  // Identity documents and the profile photo. Best effort: a storage outage
  // must not leave the account half-deleted, so failures are logged for
  // follow-up instead of aborting.
  try {
    const bucket = getStorage().bucket();
    await Promise.all([
      bucket.deleteFiles({ prefix: `drivers/${uid}/` }),
      bucket.deleteFiles({ prefix: `driver_applications/${uid}/` }),
      bucket.deleteFiles({ prefix: `profile_photos/${uid}.` }),
    ]);
  } catch (error) {
    logger.error("deleteMyAccount: storage cleanup failed", { uid, ...errorInfo(error) });
  }

  await getAuth().deleteUser(uid);
  await writeAuditLog({ actorUid: uid, action: "delete_account", targetUid: uid });
  return { success: true };
});

// ==================== AI SUPPORT PROXY ====================

/**
 * Server-side proxy for the Maya support assistant.
 *
 * The API key previously shipped inside the Flutter binary and was sent
 * straight from the handset, so anyone who unpacked the APK could spend
 * against the account. The key now lives in Secret Manager and never leaves
 * the backend; the client sends only conversation text.
 */
export const askMaya = onCall(
  { secrets: [ANTHROPIC_API_KEY] },
  async (request) => {
    const uid = requireAuth(request);
    await enforceRateLimit(uid, "maya_chat", 30, 60 * 10);

    const messages = request.data?.messages;
    if (!Array.isArray(messages) || messages.length === 0 || messages.length > 20) {
      throw new HttpsError("invalid-argument", "A conversation of 1-20 messages is required.");
    }

    const sanitised = messages.map((m: unknown) => {
      const msg = m as { role?: unknown; content?: unknown };
      const role = msg.role === "assistant" ? "assistant" : "user";
      const content = String(msg.content ?? "").slice(0, 4000);
      return { role, content };
    });

    const systemPrompt = String(request.data?.system ?? "").slice(0, 8000);

    try {
      const response = await axios.post(
        "https://api.anthropic.com/v1/messages",
        {
          model: "claude-sonnet-4-5",
          max_tokens: 1024,
          system: systemPrompt || undefined,
          messages: sanitised,
        },
        {
          headers: {
            "x-api-key": ANTHROPIC_API_KEY.value(),
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
          },
          timeout: 30000,
        }
      );

      const text = response.data?.content?.[0]?.text;
      if (typeof text !== "string") {
        throw new HttpsError("internal", "Unexpected response from the assistant.");
      }
      return { reply: text };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("askMaya failed", { uid, ...errorInfo(error) });
      throw new HttpsError("unavailable", "The assistant is unavailable right now.");
    }
  }
);
