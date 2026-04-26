import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ==================== PAYSTACK PAYMENT VERIFICATION ====================

/**
 * Verify a Paystack payment and credit the user's wallet.
 * Called from the Flutter app after user completes payment in browser.
 */
export const verifyPaystackPayment = functions.https.onCall(
  async (request) => {
    const { reference } = request.data;
    const uid = request.auth?.uid;

    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    if (!reference) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Payment reference is required"
      );
    }

    // Get Paystack secret key from environment
    const paystackSecret = process.env.PAYSTACK_SECRET_KEY;
    if (!paystackSecret) {
      throw new functions.https.HttpsError(
        "internal",
        "Paystack secret key not configured"
      );
    }

    try {
      // Verify with Paystack API
      const response = await axios.get(
        `https://api.paystack.co/transaction/verify/${reference}`,
        {
          headers: {
            Authorization: `Bearer ${paystackSecret}`,
          },
        }
      );

      const { data } = response.data;

      if (data.status !== "success") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `Payment not successful: ${data.status}`
        );
      }

      // Amount is in kobo (1/100 of Naira)
      const amountNaira = data.amount / 100;

      // Credit wallet using a transaction
      await db.runTransaction(async (transaction) => {
        const userRef = db.collection("users").doc(uid);
        const userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw new functions.https.HttpsError("not-found", "User not found");
        }

        const currentBalance = userDoc.data()?.walletBalance || 0;

        // Update wallet balance
        transaction.update(userRef, {
          walletBalance: currentBalance + amountNaira,
        });

        // Create transaction record
        const txRef = db.collection("transactions").doc();
        transaction.set(txRef, {
          userId: uid,
          type: "top_up",
          amount: amountNaira,
          description: `Wallet top-up via Paystack`,
          paystackReference: reference,
          status: "completed",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      return {
        success: true,
        amount: data.amount / 100,
        message: `₦${(data.amount / 100).toLocaleString()} credited to wallet`,
      };
    } catch (error: unknown) {
      if (error instanceof functions.https.HttpsError) throw error;
      const message =
        error instanceof Error ? error.message : "Unknown error";
      throw new functions.https.HttpsError(
        "internal",
        `Verification failed: ${message}`
      );
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
export const initializePaystackPayment = functions.https.onCall(
  async (request) => {
    const { amount, email, reference } = request.data;
    const uid = request.auth?.uid;

    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const paystackSecret = process.env.PAYSTACK_SECRET_KEY;
    if (!paystackSecret) {
      throw new functions.https.HttpsError(
        "internal",
        "Paystack secret key not configured"
      );
    }

    try {
      const response = await axios.post(
        "https://api.paystack.co/transaction/initialize",
        {
          amount: Math.round(amount * 100), // Convert to kobo
          email,
          reference,
          callback_url: "https://dilivvafast.com/payment/callback",
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
            Authorization: `Bearer ${paystackSecret}`,
            "Content-Type": "application/json",
          },
        }
      );

      return {
        success: true,
        authorizationUrl: response.data.data.authorization_url,
        reference: response.data.data.reference,
      };
    } catch (error: unknown) {
      const message =
        error instanceof Error ? error.message : "Unknown error";
      throw new functions.https.HttpsError(
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
