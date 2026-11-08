/**
 * End-to-end delivery lifecycle against the DEPLOYED staging backend.
 *
 *   booking → courier offer → raise → accept (courier's bank details reach
 *     the customer) → arrived → pickup → in transit → delivered
 *     → customer transfers and marks it sent → courier confirms → rating
 *
 * There is no wallet: customers pay couriers directly, in cash or by bank
 * transfer to the courier's own account.
 *
 * Plus the paths around it: a referral completed on the customer's first
 * delivery (no cash bonus), a support message reaching the inbox, saved notification
 * preferences, inDrive's auto-accept, a courier dropping a job (it goes back
 * to other couriers), the customer cancelling with a reason, and both
 * accounts deleting themselves (a Play requirement).
 *
 * Runs with the Firebase *client* SDK, signed in as a real customer and a
 * real driver, so every firestore.rules check and every Cloud Function runs
 * exactly as it does for the app. Each run creates fresh accounts.
 *
 * Approving the driver needs project-owner access, which the app gets from an
 * admin; it goes through the Firestore REST API with a gcloud access token,
 * as do the checks that deleted data is really gone.
 *
 * Usage (from this directory):
 *   GCLOUD_TOKEN=$(gcloud auth print-access-token) npm run staging
 */

import { initializeApp } from "firebase/app";
import {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
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
async function adminGet(path) {
  const res = await fetch(`${REST}/${path}`, {
    headers: { Authorization: `Bearer ${GCLOUD_TOKEN}` },
  });
  if (!res.ok) throw new Error(`admin GET ${path}: ${res.status} ${await res.text()}`);
  return (await res.json()).fields ?? {};
}
async function adminReplaceFields(path, set, remove) {
  const keys = [...Object.keys(set), ...remove];
  const mask = keys.map((k) => `updateMask.fieldPaths=${k}`).join("&");
  const body = { fields: Object.fromEntries(Object.entries(set).map(([k, v]) => [k, toValue(v)])) };
  const res = await fetch(`${REST}/${path}?${mask}`, {
    method: "PATCH",
    headers: { Authorization: `Bearer ${GCLOUD_TOKEN}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`admin PATCH ${path}: ${res.status} ${await res.text()}`);
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

// The rest of what CourierOrderModel.toFirestore writes on a new request.
const ORDER_DEFAULTS = {
  autoAccept: false, paymentMethod: "cash", paymentStatus: "pending",
  promoCode: null, discountAmount: 0, notes: null,
  cancelReason: null, cancelledBy: null, proofOfDeliveryUrl: null,
  rating: null, ratingComment: null, ratingTags: [], driverEarnings: 0,
  platformCommission: 0, arrivedAt: null, pickedUpAt: null, deliveredAt: null,
  estimatedDeliveryTime: null, polylinePoints: [],
};

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
      isOnline: false, referralCode: `E2EC${run % 100000}`,
      rating: 0, totalDeliveries: 0, driverStatus: "none", investorStatus: "none",
      createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    });
    return customerUid;
  });

  await step("customer signs out and signs back in with their password", async () => {
    const email = customer.auth.currentUser.email;
    await signOut(customer.auth);
    assert(!customer.auth.currentUser, "still signed in after sign-out");
    const cred = await signInWithEmailAndPassword(customer.auth, email, password);
    assert(cred.user.uid === customerUid, "signed in as someone else");
    const me = (await getDoc(doc(customer.db, "users", customerUid))).data();
    assert(me?.fullName === "E2E Customer", `profile ${JSON.stringify(me?.fullName)}`);
    return "signed in again, profile readable";
  });

  await step("driver signs up and is approved (admin action)", async () => {
    const cred = await createUserWithEmailAndPassword(
      driver.auth, `e2e.driver.${run}@dilivvafast.test`, password);
    driverUid = cred.user.uid;
    await setDoc(doc(driver.db, "users", driverUid), {
      uid: driverUid, fullName: "Emeka Driver", email: cred.user.email,
      phone: "+2348000000002", role: "customer", isVerified: false,
      isOnline: false, referralCode: `E2ED${run % 100000}`,
      rating: 0, totalDeliveries: 0, driverStatus: "none", investorStatus: "none",
      createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    });
    await adminPatch(`users/${driverUid}`, {
      driverStatus: "approved", vehicleType: "motorcycle", vehiclePlate: "LAG-E2E-01",
    });
    return driverUid;
  });

  await step("the courier's profile is in the old app's format (like the live accounts)", async () => {
    // Production profiles written by the first app version have displayName /
    // phoneNumber / a string createdAt / role "driver", and no fullName.
    await adminReplaceFields(`users/${driverUid}`, {
      displayName: "Emeka Driver",
      phoneNumber: "+2348000000002",
      createdAt: "2025-12-03T10:15:30.000Z",
      role: "driver",
    }, ["fullName", "phone"]);
    const me = (await getDoc(doc(driver.db, "users", driverUid))).data();
    assert(!me.fullName && me.displayName === "Emeka Driver", "profile not converted");
    return "old-format courier";
  });

  const BANK = { bankName: "GTBank", accountNumber: "0123456789", accountName: "Emeka Driver" };

  await step("driver saves the bank account customers pay them into", async () => {
    // What DriverBankAccountScreen writes.
    await updateDoc(doc(driver.db, "users", driverUid), {
      payoutAccount: BANK, updatedAt: serverTimestamp(),
    });
    // A malformed account (not a 10-digit NUBAN) is refused by the rules.
    const bad = await updateDoc(doc(driver.db, "users", driverUid), {
      payoutAccount: { ...BANK, accountNumber: "123" },
    }).then(() => "accepted", (e) => e.code);
    assert(bad === "permission-denied", `malformed account was ${bad}`);
    return `${BANK.bankName} ${BANK.accountNumber}`;
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
      ...ORDER_DEFAULTS,
      trackingCode: `DLVE2E${run % 1000000}`,
      createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
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
    // The customer will pay this courier by transfer: their account is on
    // the order, copied server-side from the courier's own profile.
    // Map field order is not guaranteed, so compare field by field.
    assert(["bankName", "accountNumber", "accountName"].every((k) => o.courierBank?.[k] === BANK[k]),
      `courierBank ${JSON.stringify(o.courierBank)}`);
    return `assigned; pay ${o.courierBank.bankName} ${o.courierBank.accountNumber}`;
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
    ["arrived", { arrivedAt: serverTimestamp() }],
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

  // ── paying the courier directly ──────────────────────────────────────────
  await step("the customer cannot mark the order paid themselves", async () => {
    const r = await updateDoc(doc(customer.db, "couriers", orderId), {
      paymentStatus: "paid",
    }).then(() => "accepted", (e) => e.code);
    assert(r === "permission-denied", `customer marking paid was ${r}`);
  });

  await step("customer transfers ₦1400 and marks it sent", async () => {
    // What FirebaseCourierRepository.markPaymentSent writes.
    await updateDoc(doc(customer.db, "couriers", orderId), {
      paymentMethod: "transfer", paymentStatus: "sent", updatedAt: serverTimestamp(),
    });
    const o = (await getDoc(doc(driver.db, "couriers", orderId))).data();
    assert(o.paymentStatus === "sent", `paymentStatus ${o.paymentStatus}`);
    return `₦${o.totalFare} to ${o.courierBank.bankName}`;
  });

  await step("courier confirms the money arrived", async () => {
    // What FirebaseCourierRepository.confirmPaymentReceived writes.
    await updateDoc(doc(driver.db, "couriers", orderId), {
      paymentStatus: "paid", paidAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    const o = (await getDoc(doc(customer.db, "couriers", orderId))).data();
    assert(o.paymentStatus === "paid" && o.paidAt, `paymentStatus ${o.paymentStatus}`);
    return "paid";
  });

  await step("courier rates the customer 5★ and it reaches their profile", async () => {
    // What FirebaseCourierRepository.rateCustomer writes.
    await updateDoc(doc(driver.db, "couriers", orderId), {
      customerRatingByCourier: 5, updatedAt: serverTimestamp(),
    });
    const me = await poll(async () => {
      const d = (await getDoc(doc(customer.db, "users", customerUid))).data();
      return d?.customerRatingCount === 1 ? d : null;
    }, { what: "the customer's rating to update" });
    assert(me.customerRating === 5, `customerRating ${me.customerRating}`);
    // Only once.
    const again = await updateDoc(doc(driver.db, "couriers", orderId), {
      customerRatingByCourier: 1,
    }).then(() => "accepted", (e) => e.code);
    assert(again === "permission-denied", `second rating was ${again}`);
    return "customer ★5 (1)";
  });

  await step("customer rates the courier 5★ with compliments", async () => {
    // What FirebaseCourierRepository.rateOrder writes.
    const tags = ["fast_delivery", "careful_with_package"];
    const batch = writeBatch(customer.db);
    batch.update(doc(customer.db, "couriers", orderId), {
      rating: 5, ratingComment: "Fast and careful", ratingTags: tags,
      updatedAt: serverTimestamp(),
    });
    batch.set(doc(customer.db, "ratings", orderId), {
      orderId, userId: customerUid, driverId: driverUid, rating: 5,
      comment: "Fast and careful", tags, createdAt: serverTimestamp(),
    });
    await batch.commit();
    const me = await poll(async () => {
      const d = (await getDoc(doc(driver.db, "users", driverUid))).data();
      return d?.rating === 5 && d?.ratingTagCounts?.fast_delivery === 1 ? d : null;
    }, { what: "onRatingCreated to update the driver's rating" });
    return `driver rating ${me.rating}`;
  });

  await step("the first delivery completes the referral — no wallet credit", async () => {
    const r = await poll(async () => {
      const d = (await getDoc(doc(customer.db, "referrals", customerUid))).data();
      return d?.status === "completed" ? d : null;
    }, { what: "the referral to complete" });
    assert(r.bonusPaid !== true, "a bonus was marked paid");
    const mine = (await getDoc(doc(customer.db, "users", customerUid))).data().walletBalance;
    const theirs = (await getDoc(doc(driver.db, "users", driverUid))).data().walletBalance;
    assert(mine === undefined && theirs === undefined,
      `wallet balances appeared: ${mine} / ${theirs}`);
    return "completed, nobody credited";
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

  // ── inDrive extras: auto-accept, courier drops the job, customer cancels ─
  let order2;

  await step("a second request with auto-accept is assigned to the first courier at the price", async () => {
    const ref = await addDoc(collection(customer.db, "couriers"), {
      userId: customerUid, driverId: null, status: "pending",
      pickupAddress: "3 Broad St, Lagos Island", pickupGeoPoint: new GeoPoint(6.4531, 3.3958),
      dropoffAddress: "5 Admiralty Way, Lekki", dropoffGeoPoint: new GeoPoint(6.4474, 3.4740),
      packageDescription: "Keys", packageWeight: 0, packageCategory: "other",
      recipientName: "Tobi Recipient", recipientPhone: "+2348000000004",
      estimatedDistanceKm: 9, estimatedDurationMin: 36, baseFare: 500, surgeMultiplier: 1,
      totalFare: 1400, vehicleType: "bike", offeredFare: 1400, recommendedFare: 0,
      ...ORDER_DEFAULTS, autoAccept: true,
      trackingCode: `DLVE2F${run % 1000000}`,
      createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    });
    order2 = ref.id;
    const priced = await poll(async () => {
      const d = (await getDoc(doc(customer.db, "couriers", order2))).data();
      return d?.fareAuthoritative ? d : null;
    }, { what: "pricing of the second request" });
    // Couriers see the customer's rating on the new request.
    assert(priced.customerRatingAvg === 5 && priced.customerRatingCount === 1,
      `customer rating on request ${priced.customerRatingAvg} (${priced.customerRatingCount})`);

    // The courier takes the customer's price: no Accept tap needed.
    await setDoc(doc(driver.db, "couriers", order2, "bids", driverUid), {
      driverId: driverUid, amount: priced.offeredFare, status: "open",
      etaMinutes: 5, createdAt: serverTimestamp(),
    });
    const o = await poll(async () => {
      const d = (await getDoc(doc(customer.db, "couriers", order2))).data();
      return d?.status === "accepted" ? d : null;
    }, { what: "auto-accept to assign the courier" });
    assert(o.driverId === driverUid, `driverId ${o.driverId}`);
    return `assigned at ₦${o.agreedFare}`;
  });

  await step("the courier drops the job before pickup — it goes back to other couriers", async () => {
    const r = await httpsCallable(driver.fns, "courierCancelJob")({
      orderId: order2, reason: "Problem with my vehicle",
    });
    assert(r.data.success === true, JSON.stringify(r.data));
    const o = (await getDoc(doc(customer.db, "couriers", order2))).data();
    assert(o.status === "pending" && o.driverId === null,
      `status ${o.status}, driver ${o.driverId}`);
    // …and that courier cannot offer on it again.
    await setDoc(doc(driver.db, "couriers", order2, "bids", driverUid), {
      driverId: driverUid, amount: o.offeredFare, status: "open",
      createdAt: serverTimestamp(),
    }).catch(() => undefined);
    await poll(async () => {
      const b = await getDoc(doc(driver.db, "couriers", order2, "bids", driverUid));
      return !b.exists() || b.data().status === "cancelled";
    }, { what: "the re-offer to be refused" });
    const back = (await getDoc(doc(customer.db, "couriers", order2))).data();
    assert(back.status === "pending", `re-offer reassigned it: ${back.status}`);
    return "back to pending, re-offer refused";
  });

  await step("the customer cancels the request with a reason", async () => {
    // What FirebaseCourierRepository.cancelOrder writes.
    await updateDoc(doc(customer.db, "couriers", order2), {
      status: "cancelled", cancelReason: "I changed my mind",
      cancelledBy: "customer", cancelledAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    const o = (await getDoc(doc(customer.db, "couriers", order2))).data();
    assert(o.status === "cancelled" && o.cancelReason === "I changed my mind",
      `status ${o.status}`);
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
      if (who === "driver") {
        // A deleted courier's bank details do not stay on their deliveries.
        const kept = await adminGet(`couriers/${orderId}`);
        assert(!("courierBank" in kept), "courierBank still on the order");
      }
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
  // left behind. The order documents stay on staging as a record.
  for (const c of [customer, driver]) {
    if (c.auth.currentUser) await deleteUser(c.auth.currentUser).catch(() => undefined);
  }
  const failed = results.filter((r) => !r.ok);
  console.log(`\n${results.length - failed.length}/${results.length} steps passed` +
    (orderId ? ` · order ${orderId}` : ""));
  process.exit(failed.length ? 1 : 0);
}
