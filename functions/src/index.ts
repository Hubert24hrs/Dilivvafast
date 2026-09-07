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
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import axios from "axios";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

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
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
      .update({ fcmToken: admin.firestore.FieldValue.delete() })
      .catch(() => undefined);
  }
}

async function sendToUser(
  uid: string,
  notification: { title: string; body: string },
  data: Record<string, string>
): Promise<void> {
  const snap = await db.collection("users").doc(uid).get();
  const token = snap.data()?.fcmToken;
  if (!token) return;

  try {
    await messaging.send({ token, notification, data });
  } catch (error) {
    logger.warn("FCM send failed", { uid, error });
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
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        authorizationUrl: response.data.data.authorization_url,
        reference: response.data.data.reference,
      };
    } catch (error) {
      // Never surface the provider's raw error to the client.
      logger.error("initializePaystackPayment failed", { uid, error });
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
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(userRef, {
      walletBalance: admin.firestore.FieldValue.increment(amountNaira),
    });

    tx.set(db.collection("transactions").doc(), {
      userId: paidUid,
      type: "top_up",
      amount: amountNaira,
      description: "Wallet top-up via Paystack",
      paystackReference: reference,
      status: "completed",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
      logger.error("verifyPaystackPayment failed", { uid, reference, error });
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
      logger.error("Webhook processing failed", { reference, error });
      // 200 so Paystack does not hot-loop retries on a permanent failure;
      // the error is captured above for investigation.
      res.status(200).send("error logged");
    }
  }
);

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
      const pickup = order.pickupGeoPoint as admin.firestore.GeoPoint | undefined;

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
          const centre = zone.center as admin.firestore.GeoPoint | undefined;
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

      const subtotal = (baseFare + distanceKm * perKmRate + weightSurcharge) * surgeMultiplier;
      // Discounts are only honoured once promo redemption is validated
      // server-side; an unvalidated client discount is ignored.
      const totalFare = toKoboPrecision(Math.max(subtotal, MINIMUM_FARE));
      const platformCommission = toKoboPrecision(totalFare * PLATFORM_COMMISSION_RATE);
      const driverEarnings = toKoboPrecision(totalFare - platformCommission);

      await snapshot.ref.update({
        baseFare: toKoboPrecision(baseFare),
        surgeMultiplier,
        totalFare,
        platformCommission,
        driverEarnings,
        fareAuthoritative: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ---- dispatch ----
      const driversSnapshot = await db
        .collection("driver_locations")
        .where("isOnline", "==", true)
        .where("isAvailable", "==", true)
        .limit(50)
        .get();

      if (driversSnapshot.empty) {
        logger.info("No available drivers", { orderId });
        return;
      }

      const driverIds = driversSnapshot.docs.map((d) => d.id);
      const driverDocs = await db.getAll(
        ...driverIds.map((id) => db.collection("users").doc(id))
      );

      const tokens: string[] = [];
      const notifyBatch = db.batch();

      for (const driverDoc of driverDocs) {
        const token = driverDoc.data()?.fcmToken;
        if (token) tokens.push(token);

        notifyBatch.set(
          db.collection("users").doc(driverDoc.id).collection("notifications").doc(),
          {
            title: "New Delivery Request",
            body: `${order.pickupAddress} → ${order.dropoffAddress}`,
            type: "order_update",
            orderId,
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          }
        );
      }
      await notifyBatch.commit();

      if (tokens.length === 0) return;

      const response = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "🚀 New Delivery Request!",
          body: `${order.pickupAddress} → ${order.dropoffAddress} · ₦${totalFare.toFixed(0)}`,
        },
        data: {
          type: "new_order",
          orderId,
          pickupAddress: order.pickupAddress ?? "",
          totalFare: String(totalFare),
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
      logger.error("onCourierCreated error", { orderId, error });
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
        { type: "order_update", orderId, status: String(after.status) }
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
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      // Free the driver up again once the job leaves an active state.
      if (["delivered", "cancelled", "failed"].includes(after.status) && after.driverId) {
        await db
          .collection("driver_locations")
          .doc(after.driverId)
          .set({ isAvailable: true }, { merge: true })
          .catch(() => undefined);
      }
    } catch (error) {
      logger.error("onCourierStatusChanged error", { orderId, error });
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
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            tx.update(db.collection("users").doc(driverId), {
              walletBalance: admin.firestore.FieldValue.increment(amount),
            });

            tx.set(db.collection("transactions").doc(), {
              userId: driverId,
              type: "delivery_earning",
              amount,
              description: `Daily earnings for ${periodKey}`,
              payoutId: payoutRef.id,
              status: "completed",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          });
          paid++;
        } catch (error) {
          if ((error as Error).message === "ALREADY_PAID") {
            skipped++;
            continue;
          }
          logger.error("Payout failed for driver", { driverId, periodKey, error });
        }
      }

      logger.info("Payout run complete", { periodKey, paid, skipped });
    } catch (error) {
      logger.error("processDriverPayout error", { periodKey, error });
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
      logger.error("onRatingCreated error", { error });
    }
  }
);

// ==================== REFERRAL COMPLETED ====================

/**
 * Credit both parties once a referral completes. Guarded by a `bonusPaidAt`
 * marker written in the same transaction, so flipping the status back and
 * forth cannot mint repeated bonuses.
 */
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
          bonusPaidAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        for (const uid of [referrerId, refereeId]) {
          tx.update(db.collection("users").doc(uid), {
            walletBalance: admin.firestore.FieldValue.increment(REFERRAL_BONUS),
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
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
      logger.error("onReferralCompleted error", { error });
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
      logger.error("onSosTriggered error", { error });
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
            weekEnding: admin.firestore.FieldValue.serverTimestamp(),
            totalDeliveries,
            totalEarnings,
            averagePerDelivery: toKoboPrecision(totalEarnings / totalDeliveries),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
      logger.error("weeklyDriverReport error", { error });
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

  await admin.auth().setCustomUserClaims(targetUid, {
    admin: role === "admin",
    role,
  });

  await db.collection("users").doc(targetUid).update({
    role,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid,
    action: "set_user_role",
    targetUid,
    details: { role },
  });

  return { success: true, uid: targetUid, role };
});

/** Approve or reject a driver application, with an audit trail. */
export const reviewDriverApplication = onCall(async (request) => {
  const actorUid = await requireAdmin(request);

  const targetUid = String(request.data?.uid ?? "").trim();
  const decision = String(request.data?.decision ?? "").trim();
  const reason = String(request.data?.reason ?? "").slice(0, 500);

  if (!targetUid) throw new HttpsError("invalid-argument", "A target uid is required.");
  if (!["approved", "rejected", "suspended"].includes(decision)) {
    throw new HttpsError("invalid-argument", "Decision must be approved, rejected or suspended.");
  }

  await db.collection("users").doc(targetUid).update({
    driverStatus: decision,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await writeAuditLog({
    actorUid,
    action: "review_driver_application",
    targetUid,
    details: { decision, reason },
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
      logger.error("askMaya failed", { uid, error });
      throw new HttpsError("unavailable", "The assistant is unavailable right now.");
    }
  }
);
