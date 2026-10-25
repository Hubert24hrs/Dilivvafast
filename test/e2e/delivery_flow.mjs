/**
 * End-to-end delivery lifecycle against the DEPLOYED staging backend.
 *
 *   booking → courier offer → raise → accept → pickup → in transit
 *     → delivered → rating → driver paid (and not paid twice)
 *
 * plus the paths around it: a referral paid on the customer's first
 * delivery, a support message reaching the inbox, saved notification
 * preferences, and both accounts deleting themselves (a Play requirement).
 *
 * Runs with the Firebase *client* SDK, signed in as a real customer and a
 * real driver, so every firestore.rules check and every Cloud Function runs
 * exactly as it does for the app. Each run creates fresh accounts.
 *
 * Two steps need project-owner access, which the app gets from an admin:
 *   - approving the driver (admin action in the app), and
 *   - backdating deliveredAt to yesterday, because processDriverPayout pays
 *     yesterday's deliveries and we cannot wait until tomorrow.
 * Both go through the Firestore REST API with a gcloud access token, and the
 * payout job is triggered through Cloud Scheduler — the same path it takes
 * every night at 01:00 Lagos time.
 *
 * Usage (from this directory):
 *   GCLOUD_TOKEN=$(gcloud auth print-access-token) GCLOUD_BIN=gcloud npm run staging
 */

import { execSync } from "node:child_process";
import { initializeApp } from "firebase/app";
import {
  getAuth,
  createUserWithEmailAndPassword,
  deleteUser,
} from "firebase/auth";
import {
  getFirestore,
  doc,
  setDoc,
  addDoc,
  getDoc,
  getDocs,
  updateDoc,
  collection,
  query,
  where,
  orderBy,
  writeBatch,
  serverTimestamp,
  GeoPoint,
  Timestamp,
} from "firebase/firestore";
import { getFunctions, httpsCallable } from "firebase/functions";

const PROJECT = "dilivvafast-staging";
const CONFIG = {
  apiKey: "AIzaSyAkoOb0gul_5MskaYdYcLjcWTbbRuq0trE",
  authDomain: `${PROJECT}.firebaseapp.com`,
  projectId: PROJECT,
  storageBucket: `${PROJECT}.firebasestorage.app`,
  appId: "1:54402955686:android:eb8098262392b19875b767",
};
const GCLOUD_TOKEN = process.env.GCLOUD_TOKEN;
const GCLOUD_BIN = process.env.GCLOUD_BIN || "gcloud";
if (!GCLOUD_TOKEN) {
  console.error("GCLOUD_TOKEN is required (gcloud auth print-access-token).");
  process.exit(2);
}

// ── tiny test harness ──────────────────────────────────────────────────────

const results = [];
async function step(name, fn) {
  const t = Date.now();
  try {
    const detail = await fn();
    results.push({ name, ok: true });
    console.log(`  ✔ ${name}${detail ? ` — ${detail}` : ""} (${Date.now() - t} ms)`);
  } catch (e) {
    results.push({ name, ok: false, error: e.message });
    console.log(`  ✘ ${name}\n      ${e.message}`);
    throw e;
  }
}
function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}
async function poll(fn, { timeoutMs = 60000, everyMs = 1000, what = "condition" } = {}) {
  const deadline = Date.now() + timeoutMs;
  let last;
  while (Date.now() < deadline) {
    last = await fn();
    if (last) return last;
    await new Promise((r) => setTimeout(r, everyMs));
  }
  throw new Error(`timed out after ${timeoutMs / 1000}s waiting for ${what}`);
}

// ── admin helpers (owner access, used only where the app uses an admin) ────

const REST = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
function toValue(v) {
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === "string") return { stringValue: v };
  if (typeof v === "boolean") return { booleanValue: v };
  if (Number.isInteger(v)) return { integerValue: String(v) };
  return { doubleValue: v };
}
async function adminExists(path) {
  const res = await fetch(`${REST}/${path}`, {
    headers: { Authorization: `Bearer ${GCLOUD_TOKEN}` },
  });
  if (res.status === 404) return false;
  if (!res.ok) throw new Error(`admin GET ${path}: ${res.status} ${await res.text()}`);
  return true;
}
async function adminPatch(path, fields) {
  const mask = Object.keys(fields).map((k) => `updateMask.fieldPaths=${k}`).join("&");
  const body = { fields: Object.fromEntries(Object.entries(fields).map(([k, v]) => [k, toValue(v)])) };
  const res = await fetch(`${REST}/${path}?${mask}`, {
    method: "PATCH",
    headers: { Authorization: `Bearer ${GCLOUD_TOKEN}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`admin PATCH ${path}: ${res.status} ${await res.text()}`);
}

// ── two independent signed-in clients ──────────────────────────────────────

function client(name) {
  const app = initializeApp(CONFIG, name);
  return { auth: getAuth(app), db: getFirestore(app), fns: getFunctions(app, "us-central1") };
}
const customer = client("customer");
const driver = client("driver");

const run = Date.now();
const password = `E2e-${Math.random().toString(36).slice(2)}-${run}`;

let customerUid, driverUid, orderId;

async function main() {
  console.log(`\nDilivvafast staging E2E — run ${run}\n`);

  // ── accounts ─────────────────────────────────────────────────────────────
  await step("customer signs up", async () => {
    const cred = await createUserWithEmailAndPassword(
      customer.auth, `e2e.customer.${run}@dilivvafast.test`, password);
    customerUid = cred.user.uid;
    // The same shape UserModel.toFirestore writes on registration.
    await setDoc(doc(customer.db, "users", customerUid), {
      uid: customerUid, fullName: "E2E Customer", email: cred.user.email,
      phone: "+2348000000001", role: "customer", isVerified: false,
      isOnline: false, walletBalance: 0, referralCode: `E2EC${run % 100000}`,
      rating: 0, totalDeliveries: 0, driverStatus: "none", investorStatus: "none",
      createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    });
    return customerUid;
  });

  await step("driver signs up and is approved (admin action)", async () => {
    const cred = await createUserWithEmailAndPassword(
      driver.auth, `e2e.driver.${run}@dilivvafast.test`, password);
    driverUid = cred.user.uid;
    await setDoc(doc(driver.db, "users", driverUid), {
      uid: driverUid, fullName: "Emeka Driver", email: cred.user.email,
      phone: "+2348000000002", role: "customer", isVerified: false,
      isOnline: false, walletBalance: 0, referralCode: `E2ED${run % 100000}`,
      rating: 0, totalDeliveries: 0, driverStatus: "none", investorStatus: "none",
      createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    });
    await adminPatch(`users/${driverUid}`, {
      driverStatus: "approved", vehicleType: "motorcycle", vehiclePlate: "LAG-E2E-01",
    });
    return driverUid;
  });

  await step("customer's sign-up referral code resolves to the driver", async () => {
    // What FirebaseAuthRepository._saveReferral writes when someone registers
    // with a friend's code: one document, keyed by the new user's uid.
    await setDoc(doc(customer.db, "referrals", customerUid), {
      refereeId: customerUid, referralCode: `E2ED${run % 100000}`,
      status: "pending", bonusPaid: false, createdAt: serverTimestamp(),
    });
    const r = await poll(async () => {
      const d = (await getDoc(doc(customer.db, "referrals", customerUid))).data();
      return d?.referrerId ? d : null;
    }, { what: "onReferralCreated to resolve the referrer" });
    assert(r.referrerId === driverUid, `referrerId ${r.referrerId}, expected the driver`);
    return "referrer resolved server-side";
  });

  await step("customer saves notification preferences", async () => {
    // The Settings switches; sendToUser honours them server-side.
    await updateDoc(doc(customer.db, "users", customerUid), {
      "notificationPrefs.promotions": true,
    });
    const prefs = (await getDoc(doc(customer.db, "users", customerUid))).data().notificationPrefs;
    assert(prefs?.promotions === true, `prefs ${JSON.stringify(prefs)}`);
  });

  await step("driver goes online and publishes a position", async () => {
    await setDoc(doc(driver.db, "driver_locations", driverUid), {
      driverId: driverUid, isOnline: true, isAvailable: true, vehicleType: "motorcycle",
      location: new GeoPoint(6.452, 3.396), lastSeen: serverTimestamp(),
    }, { merge: true });
    await updateDoc(doc(driver.db, "users", driverUid), { isOnline: true });
  });

  // ── booking ──────────────────────────────────────────────────────────────
  await step("customer books a bike delivery offering ₦1200", async () => {
    // The exact field set CourierOrderModel.toFirestore writes.
    const ref = await addDoc(collection(customer.db, "couriers"), {
      userId: customerUid, driverId: null, status: "pending",
      pickupAddress: "1 Marina, Lagos Island", pickupGeoPoint: new GeoPoint(6.4541, 3.3947),
      dropoffAddress: "12 Awolowo Rd, Ikoyi", dropoffGeoPoint: new GeoPoint(6.4478, 3.4342),
      packageDescription: "Documents", packageWeight: 2, packageCategory: "documents",
      recipientName: "Ada Recipient", recipientPhone: "+2348000000003",
      estimatedDistanceKm: 8, estimatedDurationMin: 32, baseFare: 500, surgeMultiplier: 1,
      totalFare: 1200, vehicleType: "bike", offeredFare: 1200, recommendedFare: 0,
      paymentMethod: "cash", paymentStatus: "pending", paystackReference: null,
      promoCode: null, discountAmount: 0, trackingCode: `DLVE2E${run % 1000000}`,
      notes: null, proofOfDeliveryUrl: null, rating: null, ratingComment: null,
      driverEarnings: 0, platformCommission: 0,
      createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      pickedUpAt: null, deliveredAt: null, estimatedDeliveryTime: null, polylinePoints: [],
    });
    orderId = ref.id;
    return orderId;
  });

  await step("server prices the route and keeps the in-band offer", async () => {
    const o = await poll(async () => {
      const d = (await getDoc(doc(customer.db, "couriers", orderId))).data();
      return d?.fareAuthoritative ? d : null;
    }, { what: "onCourierCreated to price the order" });
    // No zones on staging: ₦500 base + 8 km × ₦100.
    assert(o.recommendedFare === 1300, `recommendedFare ${o.recommendedFare}, expected 1300`);
    assert(o.offeredFare === 1200, `offeredFare ${o.offeredFare}, expected 1200`);
    return `recommended ₦${o.recommendedFare}, offer ₦${o.offeredFare}`;
  });

  // ── negotiation ──────────────────────────────────────────────────────────
  await step("driver sees the request in the pending queue", async () => {
    const snap = await getDocs(query(collection(driver.db, "couriers"),
      where("status", "==", "pending"), orderBy("createdAt")));
    assert(snap.docs.some((d) => d.id === orderId), "order missing from driver's pending list");
    return `${snap.size} pending`;
  });

  await step("driver counter-offers ₦1400", async () => {
    await setDoc(doc(driver.db, "couriers", orderId, "bids", driverUid), {
      driverId: driverUid, amount: 1400, status: "open", etaMinutes: 7,
      createdAt: serverTimestamp(),
    });
  });

  await step("customer sees the offer with the driver's verified details", async () => {
    const bid = await poll(async () => {
      const s = await getDocs(query(collection(customer.db, "couriers", orderId, "bids"),
        where("status", "==", "open")));
      const b = s.docs.find((d) => d.id === driverUid)?.data();
      return b?.driverName ? b : null;
    }, { what: "onBidWritten to enrich the offer" });
    assert(bid.driverName === "Emeka", `driverName ${bid.driverName}`);
    assert(bid.vehiclePlate === "LAG-E2E-01", `plate ${bid.vehiclePlate}`);
    return `${bid.driverName}, ${bid.vehiclePlate}, ₦${bid.amount}`;
  });

  await step("customer raises their own offer to ₦1300", async () => {
    const r = await httpsCallable(customer.fns, "raiseOffer")({ orderId, amount: 1300 });
    assert(r.data.offeredFare === 1300, `offeredFare ${r.data.offeredFare}`);
  });

  await step("customer accepts the driver's ₦1400 offer", async () => {
    const r = await httpsCallable(customer.fns, "acceptBid")({ orderId, driverId: driverUid });
    assert(r.data.agreedFare === 1400, `agreedFare ${r.data.agreedFare}`);
    const o = (await getDoc(doc(customer.db, "couriers", orderId))).data();
    assert(o.status === "accepted" && o.driverId === driverUid, `status ${o.status}, driver ${o.driverId}`);
    assert(o.platformCommission === 280 && o.driverEarnings === 1120,
      `split ${o.platformCommission}/${o.driverEarnings}, expected 280/1120`);
    return "assigned, ₦280 commission / ₦1120 driver";
  });

  await step("a second accept is refused", async () => {
    try {
      await httpsCallable(customer.fns, "acceptBid")({ orderId, driverId: driverUid });
    } catch (e) {
      return `refused: ${e.code}`;
    }
    throw new Error("second accept unexpectedly succeeded");
  });

  await step("customer can see the courier's live position", async () => {
    const p = (await getDoc(doc(customer.db, "driver_locations", driverUid))).data();
    assert(p?.location, "no position");
    return `${p.location.latitude}, ${p.location.longitude}`;
  });

  // ── delivery ─────────────────────────────────────────────────────────────
  for (const [status, extra] of [
    ["picked_up", { pickedUpAt: serverTimestamp() }],
    ["in_transit", {}],
    ["delivered", { deliveredAt: serverTimestamp() }],
  ]) {
    await step(`driver marks the job ${status}`, async () => {
      // What FirebaseCourierRepository.updateOrderStatus writes.
      await updateDoc(doc(driver.db, "couriers", orderId), {
        status, updatedAt: serverTimestamp(), ...extra,
      });
    });
  }

  await step("customer rates the courier 5★ and it reaches their profile", async () => {
    const batch = writeBatch(customer.db);
    batch.update(doc(customer.db, "couriers", orderId), {
      rating: 5, ratingComment: "Fast and careful", updatedAt: serverTimestamp(),
    });
    batch.set(doc(customer.db, "ratings", orderId), {
      orderId, userId: customerUid, driverId: driverUid, rating: 5,
      comment: "Fast and careful", createdAt: serverTimestamp(),
    });
    await batch.commit();
    const me = await poll(async () => {
      const d = (await getDoc(doc(driver.db, "users", driverUid))).data();
      return d?.rating === 5 ? d : null;
    }, { what: "onRatingCreated to update the driver's rating" });
    return `driver rating ${me.rating}`;
  });

  await step("the first delivery pays both referral bonuses (₦500 each)", async () => {
    const r = await poll(async () => {
      const d = (await getDoc(doc(customer.db, "referrals", customerUid))).data();
      return d?.bonusPaid ? d : null;
    }, { what: "the referral to complete and pay" });
    assert(r.status === "completed", `referral status ${r.status}`);
    const mine = (await getDoc(doc(customer.db, "users", customerUid))).data().walletBalance;
    const theirs = (await getDoc(doc(driver.db, "users", driverUid))).data().walletBalance;
    assert(mine === 500, `customer wallet ${mine}, expected 500`);
    assert(theirs === 500, `referrer wallet ${theirs}, expected 500`);
    return "customer ₦500, referrer ₦500";
  });

  await step("a support message reaches the admin inbox", async () => {
    const thread = doc(customer.db, "orders", `support_${customerUid}`);
    await addDoc(collection(thread, "messages"), {
      senderId: customerUid, senderName: "Customer",
      text: "Thanks — my parcel arrived", createdAt: serverTimestamp(),
    });
    const t = await poll(async () => {
      const d = (await getDoc(thread)).data();
      return d?.needsReply ? d : null;
    }, { what: "onSupportMessageCreated to flag the thread" });
    assert(t.userName === "E2E Customer", `userName ${t.userName}`);
    return "thread flagged for a reply";
  });

  // ── payout ───────────────────────────────────────────────────────────────
  const yesterday = new Date();
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  yesterday.setUTCHours(12, 0, 0, 0);
  const periodKey = yesterday.toISOString().slice(0, 10);
  const payoutId = `${driverUid}_${periodKey}`;

  await step("delivery backdated into yesterday's payout window (admin)", async () => {
    await adminPatch(`couriers/${orderId}`, { deliveredAt: yesterday });
    return periodKey;
  });

  const runPayout = () =>
    execSync(
      `"${GCLOUD_BIN}" scheduler jobs run firebase-schedule-processDriverPayout-us-central1 --location us-central1 --project ${PROJECT}`,
      { stdio: "pipe" },
    );

  // The driver's wallet already holds the ₦500 referral bonus.
  let walletBefore = 0;

  await step("nightly payout pays the driver ₦1120", async () => {
    walletBefore = (await getDoc(doc(driver.db, "users", driverUid))).data().walletBalance;
    runPayout();
    // The rules deny reading a payout that does not exist yet (there is no
    // driverId to check), so "permission-denied" here means "not written yet".
    const payout = await poll(async () => {
      try {
        const d = await getDoc(doc(driver.db, "payouts", payoutId));
        return d.exists() ? d.data() : null;
      } catch (e) {
        if (e.code === "permission-denied") return null;
        throw e;
      }
    }, { timeoutMs: 120000, everyMs: 3000, what: `payouts/${payoutId}` });
    assert(payout.amount === 1120, `payout amount ${payout.amount}`);
    const wallet = (await getDoc(doc(driver.db, "users", driverUid))).data().walletBalance;
    assert(wallet === walletBefore + 1120, `driver wallet ${wallet}, expected ${walletBefore + 1120}`);
    return `payout ₦${payout.amount}, wallet ₦${walletBefore} → ₦${wallet}`;
  });

  await step("running the payout again does NOT pay twice", async () => {
    runPayout();
    await new Promise((r) => setTimeout(r, 45000));
    const wallet = (await getDoc(doc(driver.db, "users", driverUid))).data().walletBalance;
    assert(wallet === walletBefore + 1120, `driver wallet ${wallet} after second run — DOUBLE PAID`);
    const tx = await getDocs(query(collection(driver.db, "transactions"),
      where("userId", "==", driverUid)));
    const earnings = tx.docs.filter((d) => d.data().type === "delivery_earning");
    assert(earnings.length === 1, `${earnings.length} earning transactions, expected 1`);
    return `wallet still ₦${wallet}, 1 earning record`;
  });

  // ── account deletion (Google Play requirement) ───────────────────────────
  for (const [who, c, uid] of [["customer", customer, customerUid], ["driver", driver, driverUid]]) {
    await step(`${who} deletes their account`, async () => {
      const r = await httpsCallable(c.fns, "deleteMyAccount")({});
      assert(r.data.success === true, JSON.stringify(r.data));
      assert(!(await adminExists(`users/${uid}`)), "profile still exists");
      if (who === "customer") {
        assert(!(await adminExists(`orders/support_${uid}`)), "support thread still exists");
        assert(!(await adminExists(`referrals/${uid}`)), "referral still exists");
      }
      assert(await adminExists(`couriers/${orderId}`), "the delivery record must be kept");
      // The sign-in is gone too: refreshing the session fails.
      const refreshed = await c.auth.currentUser.getIdToken(true).then(() => true, () => false);
      assert(!refreshed, "sign-in still valid after deletion");
      return "profile and sign-in removed, delivery record kept";
    });
  }
}

try {
  await main();
} catch {
  // reported by step()
} finally {
  // A failed run can stop before the deletion steps; remove any sign-in it
  // left behind. The order and payout documents stay on staging as a record.
  for (const c of [customer, driver]) {
    if (c.auth.currentUser) await deleteUser(c.auth.currentUser).catch(() => undefined);
  }
  const failed = results.filter((r) => !r.ok);
  console.log(`\n${results.length - failed.length}/${results.length} steps passed` +
    (orderId ? ` · order ${orderId}` : ""));
  process.exit(failed.length ? 1 : 0);
}
