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

admin.initializeApp({ projectId: "fast-delivery-d8d5c" });
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
    // A deliberately bogus fare, as a tampered client would send.
    totalFare: 1,
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
  test("overwrites a tampered client fare", async () => {
    const ref = db.collection("couriers").doc();
    await ref.set(baseOrder());

    const order = await waitFor(ref, (d) => d.fareAuthoritative === true);

    // 500 base + (10km * 100) = 1500, surge 1.0, no discount.
    assert.equal(order.totalFare, 1500, "fare must be recomputed, not trusted");
    assert.equal(order.baseFare, 500);
    assert.equal(order.surgeMultiplier, 1);
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
    assert.equal(order.totalFare, 2000);
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
