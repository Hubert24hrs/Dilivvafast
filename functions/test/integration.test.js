/**
 * Cloud Functions integration tests, run against the Firebase emulators.
 *
 * These exercise the logic that firestore.rules deliberately cannot enforce:
 * server-authoritative pricing, and promo redemption that has to be atomic.
 * The rules suite proves a client cannot write a fare; this proves the backend
 * writes the right one.
 *
 * Run from the repository root:
 *   npm --prefix functions run test:integration
 *
 * Requires a JVM for the Firestore emulator. Android Studio bundles one at
 * "C:\Program Files\Android\Android Studio\jbr" on this project's Windows
 * setup; on CI the setup-java action provides it.
 */

const { test, describe, before, beforeEach } = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8085";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";

const PROJECT = "fast-delivery-d8d5c";
const FUNCTIONS = `http://127.0.0.1:5001/${PROJECT}/us-central1`;

admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

const CUSTOMER = "itest_customer";

/** Triggers are asynchronous; poll until the field appears or we give up. */
async function waitFor(ref, predicate, { timeoutMs = 20000, everyMs = 250 } = {}) {
  const deadline = Date.now() + timeoutMs;
  let last;
  while (Date.now() < deadline) {
    const snap = await ref.get();
    last = snap.exists ? snap.data() : undefined;
    if (last && predicate(last)) return last;
    await new Promise((r) => setTimeout(r, everyMs));
  }
  throw new Error(
    `Timed out waiting for trigger. Last document state: ${JSON.stringify(last)}`
  );
}

async function deleteCollection(name) {
  const snap = await db.collection(name).get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

function baseOrder(overrides = {}) {
  return {
    userId: CUSTOMER,
    status: "pending",
    driverId: null,
    paymentStatus: "pending",
    driverEarnings: 0,
    platformCommission: 0,
    // A deliberately bogus fare, as a tampered client would send. The offer
    // itself defaults to the route's recommended fare (N1500 for 10 km).
    totalFare: 1,
    offeredFare: 1500,
    vehicleType: "bike",
    baseFare: 1,
    discountAmount: 0,
    estimatedDistanceKm: 10,
    packageWeight: 0,
    pickupAddress: "1 Marina, Lagos",
    pickupGeoPoint: new admin.firestore.GeoPoint(6.4541, 3.3947),
    dropoffAddress: "12 Awolowo Rd, Ikoyi",
    dropoffGeoPoint: new admin.firestore.GeoPoint(6.4478, 3.4342),
    packageDescription: "Documents",
    recipientName: "Ada",
    recipientPhone: "+2348000000000",
    trackingCode: "DF-ITEST",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    ...overrides,
  };
}

before(async () => {
  // A zone covering the Lagos pickup point: ₦500 base + ₦100/km, no surge.
  await db.collection("zones").doc("lagos").set({
    name: "Lagos Island",
    isActive: true,
    center: new admin.firestore.GeoPoint(6.45, 3.4),
    radiusKm: 25,
    baseFare: 500,
    perKmRate: 100,
    currentSurgeMultiplier: 1.0,
  });
});

beforeEach(async () => {
  await deleteCollection("couriers");
  await deleteCollection("promos");
  await deleteCollection("promo_redemptions");
});

describe("onCourierCreated — server-authoritative pricing", () => {
  test("computes the recommended fare server-side", async () => {
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder());

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);

    // 500 base + (10km * 100) = 1500, surge 1.0, no discount.
    assert.equal(order.recommendedFare, 1500);
    assert.equal(order.baseFare, 500, "client baseFare must be overwritten");
    assert.equal(order.surgeMultiplier, 1);
  });

  test("clamps a N1 offer up to the floor (70% of recommended)", async () => {
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ offeredFare: 1 }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    // ceil(1500 * 0.7 / 50) * 50 = 1050.
    assert.equal(order.offeredFare, 1050, "a N1 booking must not be possible");
    assert.equal(order.totalFare, 1050);
    assert.equal(order.offerAdjusted, true);
  });

  test("clamps an absurd offer down to the ceiling (3x recommended)", async () => {
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ offeredFare: 1e9 }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    assert.equal(order.offeredFare, 4500);
  });

  test("honours an in-band offer exactly", async () => {
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ offeredFare: 1300 }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    assert.equal(order.offeredFare, 1300);
    assert.equal(order.offerAdjusted, false);
  });

  test("splits commission and driver earnings server-side", async () => {
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder());

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);

    // 20% platform commission.
    assert.equal(order.platformCommission, 300);
    assert.equal(order.driverEarnings, 1200);
    assert.equal(
      order.platformCommission + order.driverEarnings,
      order.totalFare,
      "the split must account for the whole fare"
    );
  });

  test("never prices below the minimum fare", async () => {
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ estimatedDistanceKm: 0 }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    assert.ok(order.totalFare >= 500, `expected >= 500, got ${order.totalFare}`);
  });

  test("applies a weight surcharge", async () => {
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ packageWeight: 12 }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    // 500 + 1000 + 500 surcharge.
    assert.equal(order.recommendedFare, 2000);
  });
});

describe("promo redemption", () => {
  async function seedPromo(fields = {}) {
    await db.collection("promos").doc("p1").set({
      code: "SAVE200",
      discountType: "flat",
      amount: 200,
      minOrderAmount: 0,
      maxUses: 0,
      usedCount: 0,
      isActive: true,
      expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 864e5)),
      ...fields,
    });
  }

  test("applies a valid flat discount and records the redemption", async () => {
    await seedPromo();
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ promoCode: "SAVE200" }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    assert.equal(order.discountAmount, 200);
    assert.equal(order.totalFare, 1300); // 1500 - 200

    const redemptions = await db.collection("promo_redemptions").get();
    assert.equal(redemptions.size, 1, "redemption must be recorded");
    assert.equal(redemptions.docs[0].id, `p1_${CUSTOMER}`);

    const promo = await db.collection("promos").doc("p1").get();
    assert.equal(promo.data().usedCount, 1);
  });

  test("applies a percentage discount", async () => {
    await seedPromo({ discountType: "percent", amount: 10 });
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ promoCode: "SAVE200" }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    assert.equal(order.discountAmount, 150); // 10% of 1500
    assert.equal(order.totalFare, 1350);
  });

  test("the same customer cannot reuse a code", async () => {
    await seedPromo();

    const first = db.collection("couriers").doc();
    await first.set(baseOrder({ promoCode: "SAVE200" }));
    const a = await waitFor(first, (d) => d.fareAuthoritative === true);
    assert.equal(a.discountAmount, 200);

    const second = db.collection("couriers").doc();
    await second.set(baseOrder({ promoCode: "SAVE200" }));
    const b = await waitFor(second, (d) => d.fareAuthoritative === true);

    assert.equal(b.discountAmount, 0, "a second order must not be discounted");
    assert.equal(b.totalFare, 1500);

    const promo = await db.collection("promos").doc("p1").get();
    assert.equal(promo.data().usedCount, 1, "usedCount must not double-count");
  });

  test("ignores an expired code", async () => {
    await seedPromo({
      expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 864e5)),
    });
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ promoCode: "SAVE200" }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    assert.equal(order.discountAmount, 0);
  });

  test("ignores an inactive code", async () => {
    await seedPromo({ isActive: false });
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ promoCode: "SAVE200" }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    assert.equal(order.discountAmount, 0);
  });

  test("ignores a code that has hit its usage cap", async () => {
    await seedPromo({ maxUses: 5, usedCount: 5 });
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ promoCode: "SAVE200" }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    assert.equal(order.discountAmount, 0);
  });

  test("ignores a code below its minimum order value", async () => {
    await seedPromo({ minOrderAmount: 10000 });
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ promoCode: "SAVE200" }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    assert.equal(order.discountAmount, 0);
  });

  test("ignores an unknown code without failing the order", async () => {
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ promoCode: "NOSUCHCODE" }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    assert.equal(order.discountAmount, 0);
    assert.equal(order.totalFare, 1500, "the order must still price normally");
  });

  test("a discount can never drive the fare below the minimum", async () => {
    await seedPromo({ amount: 99999 });
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder({ promoCode: "SAVE200" }));

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);
    assert.ok(order.totalFare >= 500, `expected >= 500, got ${order.totalFare}`);
    assert.ok(order.discountAmount >= 0, "discount must never be negative");
  });
});

// ── Price negotiation ────────────────────────────────────────────────────────

const DRIVER_A = "itest_driver_a";
const DRIVER_B = "itest_driver_b";
const STRANGER = "itest_stranger";
const tokens = {};

/** Create an emulator account and return an ID token for it. */
async function signIn(uid) {
  if (tokens[uid]) return tokens[uid];
  const email = `${uid}@example.test`;
  await admin.auth().deleteUser(uid).catch(() => undefined);
  await admin.auth().createUser({ uid, email, password: "password123" });
  const res = await fetch(
    `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password: "password123", returnSecureToken: true }),
    }
  );
  const body = await res.json();
  tokens[uid] = body.idToken;
  return body.idToken;
}

/** Call an onCall function as `uid`. Resolves to { result } or { error }. */
async function call(name, uid, data) {
  const res = await fetch(`${FUNCTIONS}/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${await signIn(uid)}`,
    },
    body: JSON.stringify({ data }),
  });
  return res.json();
}

describe("price negotiation", () => {
  before(async () => {
    for (const [uid, name] of [
      [DRIVER_A, "Tunde Bakare"],
      [DRIVER_B, "Chidi Okafor"],
    ]) {
      await db.collection("users").doc(uid).set({
        role: "driver",
        driverStatus: "approved",
        fullName: name,
        rating: 4.8,
        totalDeliveries: 120,
        vehicleType: "motorcycle",
        vehiclePlate: "LAG-123AB",
      });
    }
    await db.collection("users").doc(CUSTOMER).set({ role: "customer" });
  });

  beforeEach(async () => {
    // Every test calls the callables several times; a shared rate-limit
    // window would make later tests fail for reasons unrelated to them.
    await deleteCollection("rate_limits");
  });

  /** A priced, open request with the customer offering 1500. */
  async function pricedRequest() {
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder());
    await waitFor(ref, (d) => d.fareAuthoritative === true);
    return ref;
  }

  async function placeBid(orderRef, driverId, amount) {
    const bidRef = orderRef.collection("bids").doc(driverId);
    await bidRef.set({ driverId, amount, status: "open", createdAt: new Date() });
    return bidRef;
  }

  test("an offer is filled in with the driver's verified details", async () => {
    const order = await pricedRequest();
    const bid = await placeBid(order, DRIVER_A, 1700);

    const enriched = await waitFor(bid, (d) => !!d.driverName);
    assert.equal(enriched.driverName, "Tunde", "first name only");
    assert.equal(enriched.driverRating, 4.8);
    assert.equal(enriched.vehiclePlate, "LAG-123AB");
  });

  test("an offer below the customer's price is removed", async () => {
    const order = await pricedRequest();
    const bid = await placeBid(order, DRIVER_A, 900);

    const deadline = Date.now() + 15000;
    while (Date.now() < deadline && (await bid.get()).exists) {
      await new Promise((r) => setTimeout(r, 250));
    }
    assert.equal((await bid.get()).exists, false);
  });

  test("accepting assigns the driver at the offered price and closes the rest", async () => {
    const order = await pricedRequest();
    await placeBid(order, DRIVER_A, 1800);
    await placeBid(order, DRIVER_B, 1600);
    await waitFor(order.collection("bids").doc(DRIVER_B), (d) => !!d.driverName);

    const res = await call("acceptBid", CUSTOMER, {
      orderId: order.id,
      driverId: DRIVER_B,
    });
    assert.ok(res.result, `expected success, got ${JSON.stringify(res)}`);
    assert.equal(res.result.agreedFare, 1600);

    const o = (await order.get()).data();
    assert.equal(o.driverId, DRIVER_B);
    assert.equal(o.status, "accepted");
    assert.equal(o.agreedFare, 1600);
    assert.equal(o.totalFare, 1600);
    assert.equal(o.platformCommission, 320);
    assert.equal(o.driverEarnings, 1280);

    const losing = (await order.collection("bids").doc(DRIVER_A).get()).data();
    assert.equal(losing.status, "declined");
  });

  test("a second accept loses: one request, one courier", async () => {
    const order = await pricedRequest();
    await placeBid(order, DRIVER_A, 1500);
    await placeBid(order, DRIVER_B, 1500);

    const [a, b] = await Promise.all([
      call("acceptBid", CUSTOMER, { orderId: order.id, driverId: DRIVER_A }),
      call("acceptBid", CUSTOMER, { orderId: order.id, driverId: DRIVER_B }),
    ]);
    const wins = [a, b].filter((r) => r.result).length;
    assert.equal(wins, 1, `exactly one accept must win: ${JSON.stringify([a, b])}`);
  });

  test("only the customer who made the request can accept", async () => {
    const order = await pricedRequest();
    await placeBid(order, DRIVER_A, 1500);

    const res = await call("acceptBid", STRANGER, {
      orderId: order.id,
      driverId: DRIVER_A,
    });
    assert.equal(res.error?.status, "PERMISSION_DENIED");
    assert.equal((await order.get()).data().driverId, null);
  });

  test("raising the offer moves it up, never past the ceiling", async () => {
    const order = await pricedRequest();

    const up = await call("raiseOffer", CUSTOMER, { orderId: order.id, amount: 1700 });
    assert.equal(up.result?.offeredFare, 1700, JSON.stringify(up));

    const capped = await call("raiseOffer", CUSTOMER, { orderId: order.id, amount: 1e9 });
    assert.equal(capped.result?.offeredFare, 4500, "clamped to 3x recommended");
  });

  test("an offer cannot be lowered through raiseOffer", async () => {
    const order = await pricedRequest();
    const res = await call("raiseOffer", CUSTOMER, { orderId: order.id, amount: 1000 });
    assert.equal(res.error?.status, "INVALID_ARGUMENT");
  });
});
