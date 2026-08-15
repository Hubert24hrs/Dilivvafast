import * as functions from "firebase-functions";
import { onCall, HttpsError } from "firebase-functions/v2/https";
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

// ==================== ORDER CREATED — NOTIFY DRIVERS ====================

/**
 * When a new order is created, send FCM notification to available drivers
 * in the same zone/city.
 */
export const onOrderCreated = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snapshot, context) => {
    const order = snapshot.data();
    const orderId = context.params.orderId;

    if (!order) return;

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
          body: `${order.pickupAddress} → ${order.dropoffAddress} · ₦${order.totalFare?.toFixed(0) || "0"}`,
        },
        data: {
          type: "new_order",
          orderId,
          pickupAddress: order.pickupAddress || "",
          totalFare: String(order.totalFare || 0),
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

      // Update each driver's wallet
      const batch = db.batch();
      for (const [driverId, earnings] of Object.entries(driverEarnings)) {
        const driverRef = db.collection("users").doc(driverId);

        // Create earnings transaction
        const txRef = db.collection("transactions").doc();
        batch.set(txRef, {
          userId: driverId,
          type: "delivery_earning",
          amount: earnings,
          description: `Daily earnings for ${yesterday.toLocaleDateString()}`,
          status: "completed",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Credit wallet
        batch.update(driverRef, {
          walletBalance: admin.firestore.FieldValue.increment(earnings),
        });
      }

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

        // Save weekly report
        await db
          .collection("users")
          .doc(driverId)
          .collection("weekly_reports")
          .add({
            weekEnding: admin.firestore.FieldValue.serverTimestamp(),
            totalDeliveries,
            totalEarnings,
            averagePerDelivery:
              totalDeliveries > 0 ? totalEarnings / totalDeliveries : 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

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
