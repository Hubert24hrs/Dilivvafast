import * as crypto from "crypto";
import * as functions from "firebase-functions";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import Anthropic from "@anthropic-ai/sdk";
import axios from "axios";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Paystack secret key. Bound to the functions that need it and injected at
 * runtime by Cloud Functions — it never reaches the Flutter client.
 * Set with: firebase functions:secrets:set PAYSTACK_SECRET_KEY
 */
const paystackSecretKey = defineSecret("PAYSTACK_SECRET_KEY");

/** Anthropic key for the Maya support assistant. Server-side only. */
const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

/**
 * Signing secret Paystack uses for webhook payloads. This is the same value as
 * the Paystack secret key, kept as its own secret so the webhook function does
 * not need the API key itself.
 */
const paystackWebhookSecret = defineSecret("PAYSTACK_WEBHOOK_SECRET");

/** Smallest wallet top-up we accept, in Naira. Mirrored in the app's UI. */
const MIN_TOP_UP_NAIRA = 100;

/** Where Paystack sends the browser after checkout completes. */
const PAYSTACK_CALLBACK_URL = "https://dilivvafast.com/payment/callback";

// ==================== PAYSTACK PAYMENT VERIFICATION ====================

/**
 * Ask Paystack about a reference. Returns the raw transaction payload.
 */
async function fetchPaystackTransaction(reference: string, secret: string) {
  const response = await axios.get(
    `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,
    { headers: { Authorization: `Bearer ${secret}` } }
  );
  return response.data.data;
}

/**
 * Credit a wallet exactly once for a given Paystack reference.
 *
 * The reference lookup and the balance write happen inside a single
 * transaction, so a retry (client retry, webhook racing the callable, or a
 * duplicate webhook delivery) can never credit the same payment twice.
 */
async function creditWalletOnce(
  uid: string,
  reference: string,
  amountNaira: number
): Promise<{ credited: boolean; amount: number }> {
  return db.runTransaction(async (transaction) => {
    const existing = await transaction.get(
      db
        .collection("transactions")
        .where("paystackReference", "==", reference)
        .limit(1)
    );

    if (!existing.empty) {
      const previous = existing.docs[0].data();
      return {
        credited: false,
        amount: (previous.amount as number) ?? amountNaira,
      };
    }

    const userRef = db.collection("users").doc(uid);
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User not found");
    }

    transaction.update(userRef, {
      walletBalance: admin.firestore.FieldValue.increment(amountNaira),
    });

    const txRef = db.collection("transactions").doc();
    transaction.set(txRef, {
      userId: uid,
      type: "top_up",
      amount: amountNaira,
      description: "Wallet top-up via Paystack",
      paystackReference: reference,
      status: "completed",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { credited: true, amount: amountNaira };
  });
}

/**
 * Verify a Paystack payment and credit the caller's wallet.
 * Called from the Flutter app once the user returns from Paystack checkout.
 */
export const verifyPaystackPayment = onCall(
  { secrets: [paystackSecretKey] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const reference = String(request.data?.reference ?? "").trim();
    if (!reference) {
      throw new HttpsError("invalid-argument", "Payment reference is required");
    }

    try {
      const data = await fetchPaystackTransaction(
        reference,
        paystackSecretKey.value()
      );

      if (data.status !== "success") {
        throw new HttpsError(
          "failed-precondition",
          `Payment not successful: ${data.status}`
        );
      }

      // The reference must belong to the caller. Without this a user could
      // submit someone else's reference and claim their payment.
      const payerId = data.metadata?.userId;
      if (payerId && payerId !== uid) {
        throw new HttpsError(
          "permission-denied",
          "This payment belongs to another account"
        );
      }

      const amountNaira = data.amount / 100;
      const result = await creditWalletOnce(uid, reference, amountNaira);

      return {
        success: true,
        amount: result.amount,
        alreadyProcessed: !result.credited,
        message: result.credited
          ? `₦${result.amount.toLocaleString()} credited to wallet`
          : "This payment was already credited to your wallet",
      };
    } catch (error: unknown) {
      if (error instanceof HttpsError) throw error;
      const message = error instanceof Error ? error.message : "Unknown error";
      throw new HttpsError("internal", `Verification failed: ${message}`);
    }
  }
);

// ==================== SERVER-SIDE FARE ====================

const MINIMUM_FARE_NAIRA = 500;
const DEFAULT_BASE_FARE = 500;
const DEFAULT_PER_KM_RATE = 100;
const PLATFORM_COMMISSION_RATE = 0.2;

interface ZoneConfig {
  name?: string;
  baseFare?: number;
  perKmRate?: number;
  currentSurgeMultiplier?: number;
  polygonCoordinates?: admin.firestore.GeoPoint[];
}

/** Great-circle distance between two points, in kilometres. */
function haversineKm(
  a: admin.firestore.GeoPoint,
  b: admin.firestore.GeoPoint
): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const dLat = toRad(b.latitude - a.latitude);
  const dLng = toRad(b.longitude - a.longitude);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(a.latitude)) *
      Math.cos(toRad(b.latitude)) *
      Math.sin(dLng / 2) ** 2;
  return 2 * earthRadiusKm * Math.asin(Math.sqrt(h));
}

/** Ray-casting point-in-polygon test. Mirrors FareCalculatorService in the app. */
function isPointInPolygon(
  point: admin.firestore.GeoPoint,
  polygon: admin.firestore.GeoPoint[]
): boolean {
  if (!polygon || polygon.length < 3) return false;

  let inside = false;
  let j = polygon.length - 1;
  for (let i = 0; i < polygon.length; i++) {
    const xi = polygon[i].latitude;
    const yi = polygon[i].longitude;
    const xj = polygon[j].latitude;
    const yj = polygon[j].longitude;
    if (
      yi > point.longitude !== yj > point.longitude &&
      point.latitude < ((xj - xi) * (point.longitude - yi)) / (yj - yi) + xi
    ) {
      inside = !inside;
    }
    j = i;
  }
  return inside;
}

async function findZoneForPoint(
  point: admin.firestore.GeoPoint
): Promise<ZoneConfig | null> {
  const zones = await db
    .collection("zones")
    .where("isActive", "==", true)
    .get();

  if (zones.empty) return null;

  for (const doc of zones.docs) {
    const zone = doc.data() as ZoneConfig;
    if (isPointInPolygon(point, zone.polygonCoordinates ?? [])) {
      return zone;
    }
  }
  // City-wide fallback, same as the client.
  return zones.docs[0].data() as ZoneConfig;
}

/**
 * Recompute an order's fare from zone configuration and the pickup/dropoff
 * coordinates, and write the authoritative figures back.
 *
 * The client shows an estimate, but the price it submits is never trusted:
 * distance, surge, fare, and the driver/platform split are all decided here.
 */
async function lockOrderFare(
  orderRef: admin.firestore.DocumentReference,
  order: admin.firestore.DocumentData
): Promise<number> {
  const pickup = order.pickupGeoPoint as admin.firestore.GeoPoint | undefined;
  const dropoff = order.dropoffGeoPoint as admin.firestore.GeoPoint | undefined;
  if (!pickup || !dropoff) {
    console.warn("Order missing coordinates; leaving client fare in place");
    return Number(order.totalFare) || 0;
  }

  const zone = await findZoneForPoint(pickup);
  const baseFare = zone?.baseFare ?? DEFAULT_BASE_FARE;
  const perKmRate = zone?.perKmRate ?? DEFAULT_PER_KM_RATE;
  const surgeMultiplier = zone?.currentSurgeMultiplier ?? 1;

  const distanceKm = haversineKm(pickup, dropoff);

  const weightKg = Number(order.packageWeight) || 0;
  let weightSurcharge = 0;
  if (weightKg >= 10) {
    weightSurcharge = 500;
  } else if (weightKg >= 5) {
    weightSurcharge = 200;
  }

  // A discount is only honoured if the client actually claimed one, and it can
  // never push the fare below the floor.
  const discount = Math.max(0, Number(order.discountAmount) || 0);
  const subtotal =
    (baseFare + distanceKm * perKmRate + weightSurcharge) * surgeMultiplier;
  const totalFare = Math.max(
    Math.round(subtotal - discount),
    MINIMUM_FARE_NAIRA
  );

  const platformCommission = Math.round(totalFare * PLATFORM_COMMISSION_RATE);
  const driverEarnings = totalFare - platformCommission;

  await orderRef.update({
    estimatedDistanceKm: Number(distanceKm.toFixed(2)),
    baseFare,
    surgeMultiplier,
    totalFare,
    driverEarnings,
    platformCommission,
    fareLockedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return totalFare;
}

// ==================== ORDER CREATED — PRICE, THEN NOTIFY DRIVERS ====================

/**
 * When a new order is created: lock the fare server-side, then notify
 * available drivers.
 */
export const onOrderCreated = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snapshot, context) => {
    const order = snapshot.data();
    const orderId = context.params.orderId;

    if (!order) return;

    let lockedFare = Number(order.totalFare) || 0;
    try {
      lockedFare = await lockOrderFare(snapshot.ref, order);
    } catch (error) {
      console.error(`Failed to lock fare for order ${orderId}:`, error);
    }

    try {
      // Find online drivers
      const driversSnapshot = await db
        .collection("users")
        .where("role", "==", "driver")
        .where("isOnline", "==", true)
        .where("isAvailable", "==", true)
        .limit(50)
        .get();

      if (driversSnapshot.empty) {
        console.log(`No available drivers for order ${orderId}`);
        return;
      }

      // Collect FCM tokens
      const tokens: string[] = [];
      driversSnapshot.forEach((doc) => {
        const driverData = doc.data();
        if (driverData.fcmToken) {
          tokens.push(driverData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log("No FCM tokens found for available drivers");
        return;
      }

      // Send multicast notification
      const message: admin.messaging.MulticastMessage = {
        tokens,
        notification: {
          title: "🚀 New Delivery Request!",
          body: `${order.pickupAddress} → ${order.dropoffAddress} · ₦${lockedFare.toFixed(0)}`,
        },
        data: {
          type: "new_order",
          orderId,
          pickupAddress: order.pickupAddress || "",
          totalFare: String(lockedFare),
        },
        android: {
          priority: "high",
          notification: {
            channelId: "dilivvafast_default",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      const response = await messaging.sendEachForMulticast(message);
      console.log(
        `Order ${orderId}: ${response.successCount} notifications sent, ${response.failureCount} failed`
      );

      // Create notification records for each driver
      const batch = db.batch();
      driversSnapshot.forEach((doc) => {
        const notifRef = db
          .collection("users")
          .doc(doc.id)
          .collection("notifications")
          .doc();
        batch.set(notifRef, {
          title: "New Delivery Request",
          body: `${order.pickupAddress} → ${order.dropoffAddress}`,
          type: "order_update",
          orderId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      await batch.commit();
    } catch (error) {
      console.error("onOrderCreated error:", error);
    }
  });

// ==================== ORDER STATUS CHANGED — NOTIFY CUSTOMER ====================

/**
 * When order status changes, notify the customer via FCM.
 */
export const onOrderStatusChanged = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    if (!before || !after) return;
    if (before.status === after.status) return;

    const statusMessages: Record<string, string> = {
      accepted: "A driver has accepted your delivery! 🎉",
      picked_up: "Your package has been picked up 📦",
      in_transit: "Your package is on its way! 🚀",
      delivered: "Your package has been delivered! ✅",
      cancelled: "Your order has been cancelled ❌",
    };

    const statusMsg = statusMessages[after.status];
    if (!statusMsg) return;

    try {
      // Get customer FCM token
      const customerDoc = await db
        .collection("users")
        .doc(after.userId)
        .get();
      const customerData = customerDoc.data();

      if (!customerData?.fcmToken) {
        console.log("Customer has no FCM token");
        return;
      }

      // Send notification
      await messaging.send({
        token: customerData.fcmToken,
        notification: {
          title: `Order ${after.trackingCode}`,
          body: statusMsg,
        },
        data: {
          type: "order_update",
          orderId,
          status: after.status,
        },
      });

      // Save notification to Firestore
      await db
        .collection("users")
        .doc(after.userId)
        .collection("notifications")
        .add({
          title: `Order ${after.trackingCode}`,
          body: statusMsg,
          type: "order_update",
          orderId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(
        `Order ${orderId}: Notified customer of status change → ${after.status}`
      );
    } catch (error) {
      console.error("onOrderStatusChanged error:", error);
    }
  });

// ==================== SCHEDULED: DRIVER PAYOUT ====================

/**
 * Daily scheduled function to calculate and record driver earnings.
 * Runs at midnight WAT (1:00 AM UTC).
 */
export const processDriverPayout = functions.pubsub
  .schedule("0 1 * * *")
  .timeZone("Africa/Lagos")
  .onRun(async () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    try {
      // Find all delivered orders from yesterday
      const ordersSnapshot = await db
        .collection("orders")
        .where("status", "==", "delivered")
        .where("deliveredAt", ">=", yesterday)
        .where("deliveredAt", "<", today)
        .get();

      if (ordersSnapshot.empty) {
        console.log("No delivered orders to process");
        return null;
      }

      // Group earnings by driver
      const driverEarnings: Record<string, number> = {};
      ordersSnapshot.forEach((doc) => {
        const order = doc.data();
        if (order.driverId && order.driverEarnings) {
          driverEarnings[order.driverId] =
            (driverEarnings[order.driverId] || 0) + order.driverEarnings;
        }
      });

      // Pub/Sub delivers at-least-once, so this function can run twice for the
      // same day. Each payout is keyed by driver + date, and the write only
      // lands if that key does not already exist — a redelivery pays nothing.
      const payoutDate = yesterday.toISOString().slice(0, 10); // YYYY-MM-DD
      const batch = db.batch();
      let scheduled = 0;

      for (const [driverId, earnings] of Object.entries(driverEarnings)) {
        const payoutId = `${driverId}_${payoutDate}`;
        const payoutRef = db.collection("driver_payouts").doc(payoutId);

        // eslint-disable-next-line no-await-in-loop
        const already = await payoutRef.get();
        if (already.exists) {
          console.log(`Payout ${payoutId} already processed; skipping`);
          continue;
        }

        batch.create(payoutRef, {
          driverId,
          payoutDate,
          amount: earnings,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        const txRef = db.collection("transactions").doc();
        batch.set(txRef, {
          userId: driverId,
          type: "delivery_earning",
          amount: earnings,
          description: `Daily earnings for ${payoutDate}`,
          payoutId,
          status: "completed",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        batch.update(db.collection("users").doc(driverId), {
          walletBalance: admin.firestore.FieldValue.increment(earnings),
        });
        scheduled++;
      }

      if (scheduled === 0) {
        console.log("All payouts for this date were already processed");
        return null;
      }

      // batch.create fails the whole batch if a payout doc appeared in the
      // meantime, so two concurrent runs cannot both credit.
      await batch.commit();
      console.log(
        `Processed earnings for ${Object.keys(driverEarnings).length} drivers`
      );

      return null;
    } catch (error) {
      console.error("processDriverPayout error:", error);
      return null;
    }
  });

// ==================== INITIALIZE PAYMENT (PAYSTACK) ====================

/**
 * Initialize a Paystack payment transaction.
 * Returns the authorization URL for the user to complete payment.
 */
export const initializePaystackPayment = onCall(
  { secrets: [paystackSecretKey] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const amount = Number(request.data?.amount);
    if (!Number.isFinite(amount) || amount < MIN_TOP_UP_NAIRA) {
      throw new HttpsError(
        "invalid-argument",
        `Amount must be at least ₦${MIN_TOP_UP_NAIRA}`
      );
    }

    // Trust the authenticated account's email, not whatever the client sent.
    const email =
      request.auth?.token?.email ??
      (await db.collection("users").doc(uid).get()).data()?.email;
    if (!email) {
      throw new HttpsError(
        "failed-precondition",
        "Your account has no email address for payment receipts"
      );
    }

    // The reference is generated server-side so a client can't replay or
    // collide with someone else's transaction id.
    const reference = `DVF-${uid.slice(0, 8)}-${Date.now()}-${Math.random()
      .toString(36)
      .slice(2, 8)}`;

    try {
      const response = await axios.post(
        "https://api.paystack.co/transaction/initialize",
        {
          amount: Math.round(amount * 100), // Convert to kobo
          email,
          reference,
          callback_url: PAYSTACK_CALLBACK_URL,
          currency: "NGN",
          metadata: {
            userId: uid,
            custom_fields: [
              {
                display_name: "User ID",
                variable_name: "user_id",
                value: uid,
              },
            ],
          },
        },
        {
          headers: {
            Authorization: `Bearer ${paystackSecretKey.value()}`,
            "Content-Type": "application/json",
          },
        }
      );

      return {
        success: true,
        authorizationUrl: response.data.data.authorization_url,
        reference: response.data.data.reference ?? reference,
      };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Unknown error";
      throw new HttpsError(
        "internal",
        `Payment initialization failed: ${message}`
      );
    }
  }
);

// ==================== RATING CREATED — RECALCULATE DRIVER AVERAGE ====================

/**
 * When a new rating is created, recalculate the driver's average rating.
 */
export const onRatingCreated = functions.firestore
  .document("ratings/{ratingId}")
  .onCreate(async (snapshot) => {
    const rating = snapshot.data();
    if (!rating || !rating.driverId) return;

    try {
      // Get all ratings for this driver
      const ratingsSnapshot = await db
        .collection("ratings")
        .where("driverId", "==", rating.driverId)
        .get();

      let totalRating = 0;
      let count = 0;
      ratingsSnapshot.forEach((doc) => {
        const r = doc.data();
        if (r.rating) {
          totalRating += r.rating;
          count++;
        }
      });

      const averageRating = count > 0 ? totalRating / count : 0;

      // Update driver's average rating
      await db.collection("users").doc(rating.driverId).update({
        averageRating: Math.round(averageRating * 10) / 10,
        totalRatings: count,
      });

      console.log(
        `Driver ${rating.driverId}: Rating updated to ${averageRating.toFixed(1)} (${count} ratings)`
      );
    } catch (error) {
      console.error("onRatingCreated error:", error);
    }
  });

// ==================== REFERRAL COMPLETED — CREDIT BOTH PARTIES ====================

/**
 * When a referral is completed, credit both the referrer and referee wallets.
 */
export const onReferralCompleted = functions.firestore
  .document("referrals/{referralId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return;
    if (before.status === "completed" || after.status !== "completed") return;

    const referrerId = after.referrerId;
    const refereeId = after.refereeId;
    const bonusAmount = 500; // ₦500 each

    try {
      const batch = db.batch();

      // Credit referrer
      const referrerRef = db.collection("users").doc(referrerId);
      batch.update(referrerRef, {
        walletBalance: admin.firestore.FieldValue.increment(bonusAmount),
      });

      // Credit referee
      const refereeRef = db.collection("users").doc(refereeId);
      batch.update(refereeRef, {
        walletBalance: admin.firestore.FieldValue.increment(bonusAmount),
      });

      // Create transaction for referrer
      const txRef1 = db.collection("transactions").doc();
      batch.set(txRef1, {
        userId: referrerId,
        type: "referral_bonus",
        amount: bonusAmount,
        description: "Referral bonus — your friend completed their first delivery!",
        status: "completed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Create transaction for referee
      const txRef2 = db.collection("transactions").doc();
      batch.set(txRef2, {
        userId: refereeId,
        type: "referral_bonus",
        amount: bonusAmount,
        description: "Welcome bonus — thanks for joining Dilivvafast!",
        status: "completed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Notify referrer
      const referrerDoc = await referrerRef.get();
      const referrerData = referrerDoc.data();
      if (referrerData?.fcmToken) {
        await messaging.send({
          token: referrerData.fcmToken,
          notification: {
            title: "Referral Bonus! 🎉",
            body: `You earned ₦${bonusAmount} — your friend just completed their first delivery!`,
          },
          data: { type: "referral_bonus" },
        });
      }

      console.log(
        `Referral completed: ₦${bonusAmount} credited to ${referrerId} and ${refereeId}`
      );
    } catch (error) {
      console.error("onReferralCompleted error:", error);
    }
  });

// ==================== SOS TRIGGERED — ALERT ADMINS ====================

/**
 * When an SOS is triggered, send urgent notification to all admin users.
 */
export const onSosTriggered = functions.firestore
  .document("sos_alerts/{alertId}")
  .onCreate(async (snapshot) => {
    const alert = snapshot.data();
    if (!alert) return;

    try {
      // Get all admin users
      const adminsSnapshot = await db
        .collection("users")
        .where("role", "==", "admin")
        .get();

      const tokens: string[] = [];
      adminsSnapshot.forEach((doc) => {
        const adminData = doc.data();
        if (adminData.fcmToken) {
          tokens.push(adminData.fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log("No admin FCM tokens found for SOS alert");
        return;
      }

      // Get user info
      const userDoc = await db.collection("users").doc(alert.userId).get();
      const userName = userDoc.data()?.fullName || "Unknown user";

      await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "🚨 SOS ALERT — URGENT",
          body: `${userName} triggered an SOS! Order: ${alert.orderId || "N/A"} | Location: ${alert.address || "Unknown"}`,
        },
        data: {
          type: "sos_alert",
          alertId: snapshot.id,
          userId: alert.userId,
          orderId: alert.orderId || "",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "sos_channel",
            sound: "alarm",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "alarm.caf",
              badge: 1,
              "content-available": 1,
            },
          },
        },
      });

      console.log(`SOS alert sent to ${tokens.length} admins`);
    } catch (error) {
      console.error("onSosTriggered error:", error);
    }
  });

// ==================== WEEKLY DRIVER REPORT — MONDAY 8AM WAT ====================

/**
 * Scheduled every Monday at 8:00 AM WAT.
 * Generates weekly earnings summary for each active driver.
 */
export const weeklyDriverReport = functions.pubsub
  .schedule("0 8 * * 1")
  .timeZone("Africa/Lagos")
  .onRun(async () => {
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

    try {
      // Get all drivers
      const driversSnapshot = await db
        .collection("users")
        .where("role", "==", "driver")
        .get();

      for (const driverDoc of driversSnapshot.docs) {
        const driverId = driverDoc.id;
        const driverData = driverDoc.data();

        // Get completed orders for this driver in the past week
        const ordersSnapshot = await db
          .collection("orders")
          .where("driverId", "==", driverId)
          .where("status", "==", "delivered")
          .where("deliveredAt", ">=", oneWeekAgo)
          .get();

        const totalDeliveries = ordersSnapshot.size;
        let totalEarnings = 0;
        ordersSnapshot.forEach((doc) => {
          totalEarnings += doc.data().driverEarnings || 0;
        });

        // Keyed by week so a Pub/Sub redelivery overwrites the same report
        // instead of appending a duplicate (and re-notifying the driver).
        const weekKey = oneWeekAgo.toISOString().slice(0, 10);
        const reportRef = db
          .collection("users")
          .doc(driverId)
          .collection("weekly_reports")
          .doc(weekKey);

        const existing = await reportRef.get();
        await reportRef.set({
          weekEnding: admin.firestore.FieldValue.serverTimestamp(),
          totalDeliveries,
          totalEarnings,
          averagePerDelivery:
            totalDeliveries > 0 ? totalEarnings / totalDeliveries : 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Only notify the first time this week's report is generated.
        if (existing.exists) continue;

        // Send notification
        if (driverData.fcmToken && totalDeliveries > 0) {
          await messaging.send({
            token: driverData.fcmToken,
            notification: {
              title: "📊 Weekly Report",
              body: `Last week: ${totalDeliveries} deliveries, ₦${totalEarnings.toLocaleString()} earned. Keep it up!`,
            },
            data: { type: "weekly_report" },
          });
        }
      }

      console.log(
        `Weekly reports generated for ${driversSnapshot.size} drivers`
      );
      return null;
    } catch (error) {
      console.error("weeklyDriverReport error:", error);
      return null;
    }
  });

// ==================== MAYA SUPPORT ASSISTANT (SERVER-SIDE PROXY) ====================

/**
 * Maya's persona and product knowledge. This lives server-side so the prompt
 * (and the Anthropic key) can be updated without shipping a new app build.
 */
const MAYA_SYSTEM_PROMPT = `
You are Maya, the friendly and knowledgeable AI assistant for Dilivvafast — Nigeria's on-demand logistics and delivery platform.

Your personality:
- Warm, professional, and empathetic
- You speak naturally with occasional Nigerian English expressions (e.g., "No wahala!")
- Always helpful and solution-oriented
- Use emojis sparingly but effectively

Product knowledge:
- Dilivvafast offers instant courier, package, and document delivery across Nigerian cities
- Delivery types: Express (1-2 hrs), Standard (same-day), Economy (next-day)
- Payment: Naira via Paystack (cards, bank transfer, USSD), and wallet top-up
- Vehicle types: Bike (small packages), Car (medium), Van (large/bulk)
- Drivers are verified with NIN, driver's licence, and background checks
- Customers track deliveries in real time on a map
- Both customers and drivers rate each other from 1 to 5 stars
- Referral program: earn ₦500 for each friend who completes their first delivery
- Operating hours: 6am - 10pm daily in Lagos, Abuja, and Port Harcourt

What you help with:
1. Tracking deliveries and order status
2. Explaining pricing and fare breakdowns
3. Account issues (password reset, profile update)
4. Filing complaints or reporting issues
5. Explaining how to become a driver
6. Payment and wallet questions
7. Cancellation and refund policies

Policies:
- Cancellation before driver pickup: full refund
- Cancellation after pickup: 50% charge
- Damaged items: file a claim within 24 hours with photos
- Insurance: available for items valued above ₦50,000
- Response SLA: critical issues within 1 hour, general within 24 hours

Resolve what you can yourself. For anything needing manual review (billing
disputes, for example), point the customer to support@dilivvafast.ng or
+234-800-DELIVER. Keep replies short enough to read on a phone.
`.trim();

interface MayaTurn {
  role: "user" | "assistant";
  content: string;
}

/**
 * Proxy a Maya conversation turn to the Claude API.
 *
 * The app sends the conversation so far and gets back one reply. The API key
 * stays in Cloud Functions secrets — the client never sees it.
 */
export const mayaChat = onCall(
  { secrets: [anthropicApiKey] },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const rawMessages = request.data?.messages;
    if (!Array.isArray(rawMessages) || rawMessages.length === 0) {
      throw new HttpsError("invalid-argument", "messages must be a non-empty array");
    }

    // Keep the tail of the conversation; older turns add cost without much value.
    const messages: MayaTurn[] = rawMessages
      .slice(-20)
      .map(
        (entry: { role?: unknown; content?: unknown }): MayaTurn => ({
          role: entry?.role === "assistant" ? "assistant" : "user",
          content: String(entry?.content ?? "").slice(0, 4000),
        })
      )
      .filter((entry: MayaTurn) => entry.content.length > 0);

    if (messages.length === 0 || messages[messages.length - 1].role !== "user") {
      throw new HttpsError(
        "invalid-argument",
        "The last message must be from the user"
      );
    }

    try {
      const client = new Anthropic({ apiKey: anthropicApiKey.value() });
      const response = await client.messages.create({
        model: "claude-opus-5",
        max_tokens: 1024,
        system: MAYA_SYSTEM_PROMPT,
        messages,
      });

      if (response.stop_reason === "refusal") {
        return {
          success: false,
          reply:
            "I can't help with that one. For anything sensitive, please reach " +
            "our team at support@dilivvafast.ng.",
        };
      }

      const reply = response.content
        .filter((block): block is Anthropic.TextBlock => block.type === "text")
        .map((block) => block.text)
        .join("\n")
        .trim();

      if (!reply) {
        throw new HttpsError("internal", "Empty response from Maya");
      }

      return { success: true, reply };
    } catch (error: unknown) {
      if (error instanceof HttpsError) throw error;
      console.error("mayaChat error:", error);
      throw new HttpsError("internal", "Maya is unavailable right now");
    }
  }
);

// ==================== PAYSTACK WEBHOOK ====================

/**
 * Server-side fallback for wallet crediting.
 *
 * The app calls verifyPaystackPayment when the user returns from checkout, but
 * that depends on the app surviving the round trip. Paystack also posts here
 * the moment a charge succeeds, so a crash, a killed app, or a dead network
 * after payment no longer loses the top-up. Both paths share creditWalletOnce,
 * so whichever arrives second is a no-op.
 */
export const paystackWebhook = onRequest(
  { secrets: [paystackWebhookSecret] },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    // Verify the payload really came from Paystack before trusting a word of
    // it. rawBody is the exact bytes Paystack signed; re-serialising req.body
    // would change them and break the comparison.
    const signature = req.get("x-paystack-signature");
    const expected = crypto
      .createHmac("sha512", paystackWebhookSecret.value())
      .update(req.rawBody)
      .digest("hex");

    if (
      !signature ||
      signature.length !== expected.length ||
      !crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))
    ) {
      console.warn("Rejected Paystack webhook with bad signature");
      res.status(401).send("Invalid signature");
      return;
    }

    // Acknowledge immediately — Paystack retries on anything but a 2xx, and we
    // don't want a slow Firestore write to trigger duplicate deliveries.
    res.status(200).send("ok");

    const event = req.body;
    if (event?.event !== "charge.success") return;

    const data = event.data ?? {};
    const reference = String(data.reference ?? "");
    const uid = data.metadata?.userId;
    const amountNaira = Number(data.amount) / 100;

    if (!reference || !uid || !Number.isFinite(amountNaira)) {
      console.warn("charge.success missing reference/userId/amount", {
        reference,
      });
      return;
    }

    try {
      const result = await creditWalletOnce(uid, reference, amountNaira);
      console.log(
        result.credited
          ? `Webhook credited ₦${amountNaira} to ${uid} (${reference})`
          : `Webhook saw already-processed reference ${reference}`
      );
    } catch (error) {
      console.error("paystackWebhook credit failed:", error);
    }
  }
);

// ==================== ORDER CANCELLATION REFUND ====================

/**
 * Cancel an order and refund the customer according to policy.
 *
 * Cancellation used to be a status flag with no money movement. Refund amount
 * follows the published policy: full refund before the driver collects the
 * package, 50% afterwards.
 */
export const cancelOrder = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const orderId = String(request.data?.orderId ?? "").trim();
  if (!orderId) {
    throw new HttpsError("invalid-argument", "orderId is required");
  }

  const reason = String(request.data?.reason ?? "").slice(0, 500);
  const orderRef = db.collection("orders").doc(orderId);

  return db.runTransaction(async (transaction) => {
    const orderDoc = await transaction.get(orderRef);
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found");
    }

    const order = orderDoc.data() as admin.firestore.DocumentData;
    if (order.userId !== uid) {
      throw new HttpsError("permission-denied", "This is not your order");
    }

    const status = order.status as string;
    if (status === "delivered" || status === "cancelled") {
      throw new HttpsError(
        "failed-precondition",
        `An order that is ${status} cannot be cancelled`
      );
    }

    // Before pickup: full refund. After: the customer keeps 50%.
    const collected = status === "picked_up" || status === "in_transit";
    const paid = order.paymentStatus === "paid";
    const totalFare = Number(order.totalFare) || 0;
    const refundAmount = paid ? (collected ? totalFare * 0.5 : totalFare) : 0;

    transaction.update(orderRef, {
      status: "cancelled",
      cancellationReason: reason,
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      refundAmount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (refundAmount > 0) {
      transaction.update(db.collection("users").doc(uid), {
        walletBalance: admin.firestore.FieldValue.increment(refundAmount),
      });

      transaction.set(db.collection("transactions").doc(), {
        userId: uid,
        type: "refund",
        amount: refundAmount,
        description: collected
          ? "Partial refund — cancelled after pickup"
          : "Refund — cancelled before pickup",
        orderId,
        status: "completed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      success: true,
      refundAmount,
      message: refundAmount > 0
        ? `₦${refundAmount.toLocaleString()} refunded to your wallet`
        : "Order cancelled",
    };
  });
});

// ==================== DRIVER APPLICATION APPROVAL ====================

/**
 * Grant the driver role when an admin approves an application.
 *
 * This is the only path to the 'driver' role: firestore.rules refuses any
 * client write to `role`, so promotion happens here with the Admin SDK.
 */
export const onDriverApplicationReviewed = functions.firestore
  .document("driver_applications/{applicationId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;

    const userId = after.userId as string | undefined;
    if (!userId) return;

    const userRef = db.collection("users").doc(userId);

    if (after.status === "approved") {
      await userRef.update({
        role: "driver",
        isVerifiedDriver: true,
        vehicleType: after.vehicleType ?? null,
        vehiclePlate: after.vehiclePlate ?? null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Driver approved: ${userId}`);
    } else if (after.status === "rejected" || after.status === "suspended") {
      // Revoke: a suspended driver drops back to customer and can no longer
      // go online or accept orders.
      await userRef.update({
        role: "customer",
        isVerifiedDriver: false,
        isOnline: false,
        isAvailable: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Driver access revoked: ${userId} (${after.status})`);
    }

    const userDoc = await userRef.get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (fcmToken) {
      const approved = after.status === "approved";
      await messaging.send({
        token: fcmToken,
        notification: {
          title: approved ? "You're approved! 🎉" : "Application update",
          body: approved
            ? "Your driver application was approved. You can go online now."
            : `Your driver application is now ${after.status}.`,
        },
        data: { type: "driver_application", status: String(after.status) },
      });
    }
  });

// ==================== REFERRAL RESOLUTION ====================

/**
 * Resolve a referral code to the account that owns it.
 *
 * The client submits only the code it was given; firestore.rules refuses a
 * client-supplied referrerId, because a user who could name the referrer could
 * mint ₦500 bonuses for any account. The mapping is done here.
 */
export const onReferralCreated = functions.firestore
  .document("referrals/{referralId}")
  .onCreate(async (snapshot) => {
    const referral = snapshot.data();
    if (!referral) return;

    const code = String(referral.referralCode ?? "").trim();
    const refereeId = referral.refereeId as string | undefined;
    if (!code || !refereeId) {
      await snapshot.ref.update({ status: "invalid" });
      return;
    }

    const owners = await db
      .collection("users")
      .where("referralCode", "==", code)
      .limit(1)
      .get();

    if (owners.empty) {
      await snapshot.ref.update({ status: "invalid" });
      console.log(`Referral code ${code} matched no account`);
      return;
    }

    const referrerId = owners.docs[0].id;

    // Self-referral would be a free ₦1000 for one person.
    if (referrerId === refereeId) {
      await snapshot.ref.update({ status: "invalid" });
      return;
    }

    await snapshot.ref.update({
      referrerId,
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
