#!/usr/bin/env node
/**
 * Post-deploy smoke test.
 *
 * Proves that a REAL deployed backend works — not the emulator. Run it
 * immediately after deploying to staging, and again after any production
 * deploy. It writes to the project it is pointed at, so it refuses to run
 * against production unless you force it.
 *
 * What it proves:
 *   1. Firestore is reachable with admin credentials.
 *   2. onCourierCreated is deployed and firing.
 *   3. Server-authoritative pricing works against real zone config.
 *   4. Promo redemption applies once and only once.
 *   5. The callable functions are deployed and reject unauthenticated calls.
 *
 * What it does NOT prove: anything touching Paystack (needs a real checkout),
 * FCM delivery, or the scheduled payout. Those still need a manual pass.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
 *   node scripts/smoke-test.js --project dilivvafast-staging
 *
 * Cleans up everything it creates.
 */

const admin = require("firebase-admin");

const args = process.argv.slice(2);
const projectId = args[args.indexOf("--project") + 1];
const force = args.includes("--force");

if (!projectId || projectId.startsWith("--")) {
  console.error("Usage: node scripts/smoke-test.js --project <projectId> [--force]");
  process.exit(2);
}

const PROD_PROJECT = "fast-delivery-d8d5c";
if (projectId === PROD_PROJECT && !force) {
  console.error(
    `Refusing to write test data to production (${PROD_PROJECT}).\n` +
      "Run against staging, or pass --force if you genuinely mean it."
  );
  process.exit(2);
}

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error(
    "GOOGLE_APPLICATION_CREDENTIALS is not set. Download a service account key\n" +
      "from Firebase Console > Project settings > Service accounts."
  );
  process.exit(2);
}

admin.initializeApp({ projectId });
const db = admin.firestore();
const { FieldValue, GeoPoint, Timestamp } = admin.firestore;

const SUFFIX = Date.now();
const TEST_USER = `smoketest_${SUFFIX}`;
const ZONE_ID = `smoketest_zone_${SUFFIX}`;
const PROMO_ID = `smoketest_promo_${SUFFIX}`;
const created = [];

let passed = 0;
let failed = 0;

function check(name, condition, detail = "") {
  if (condition) {
    console.log(`  PASS  ${name}`);
    passed++;
  } else {
    console.log(`  FAIL  ${name}${detail ? ` — ${detail}` : ""}`);
    failed++;
  }
}

async function waitFor(ref, predicate, timeoutMs = 60000) {
  const deadline = Date.now() + timeoutMs;
  let last;
  while (Date.now() < deadline) {
    const snap = await ref.get();
    last = snap.exists ? snap.data() : undefined;
    if (last && predicate(last)) return last;
    await new Promise((r) => setTimeout(r, 1000));
  }
  return last;
}

function order(overrides = {}) {
  return {
    userId: TEST_USER,
    status: "pending",
    driverId: null,
    paymentStatus: "pending",
    driverEarnings: 0,
    platformCommission: 0,
    totalFare: 1, // deliberately wrong; the backend must overwrite it
    baseFare: 1,
    discountAmount: 0,
    estimatedDistanceKm: 10,
    packageWeight: 0,
    pickupAddress: "Smoke test pickup",
    pickupGeoPoint: new GeoPoint(6.4541, 3.3947),
    dropoffAddress: "Smoke test dropoff",
    dropoffGeoPoint: new GeoPoint(6.4478, 3.4342),
    packageDescription: "Smoke test",
    recipientName: "Smoke Test",
    recipientPhone: "+2348000000000",
    trackingCode: `SMOKE-${SUFFIX}`,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    ...overrides,
  };
}

async function main() {
  console.log(`\nSmoke testing project: ${projectId}\n`);

  // ---- 1. connectivity -----------------------------------------------
  console.log("Firestore connectivity");
  await db.collection("_smoketest").doc(TEST_USER).set({ ok: true });
  created.push(db.collection("_smoketest").doc(TEST_USER));
  const ping = await db.collection("_smoketest").doc(TEST_USER).get();
  check("admin SDK can read and write", ping.exists);

  // ---- 2. seed pricing config ----------------------------------------
  console.log("\nSeeding test zone and promo");
  const zoneRef = db.collection("zones").doc(ZONE_ID);
  await zoneRef.set({
    name: "Smoke Test Zone",
    isActive: true,
    center: new GeoPoint(6.45, 3.4),
    radiusKm: 25,
    baseFare: 500,
    perKmRate: 100,
    currentSurgeMultiplier: 1.0,
  });
  created.push(zoneRef);

  const promoRef = db.collection("promos").doc(PROMO_ID);
  await promoRef.set({
    code: `SMOKE${SUFFIX}`,
    discountType: "flat",
    amount: 200,
    minOrderAmount: 0,
    maxUses: 0,
    usedCount: 0,
    isActive: true,
    expiresAt: Timestamp.fromDate(new Date(Date.now() + 864e5)),
  });
  created.push(promoRef);
  console.log("  seeded");

  // ---- 3. trigger + pricing ------------------------------------------
  console.log("\nonCourierCreated (deployed trigger)");
  const o1 = db.collection("couriers").doc();
  created.push(o1);
  await o1.set(order());

  const priced = await waitFor(o1, (d) => d.fareAuthoritative === true);
  check(
    "trigger fired within 60s",
    priced && priced.fareAuthoritative === true,
    priced ? `last state totalFare=${priced.totalFare}` : "document vanished"
  );
  check(
    "fare recomputed server-side (expected 1500)",
    priced && priced.totalFare === 1500,
    priced && `got ${priced.totalFare}`
  );
  check(
    "commission split correct (300 / 1200)",
    priced && priced.platformCommission === 300 && priced.driverEarnings === 1200,
    priced && `got ${priced.platformCommission} / ${priced.driverEarnings}`
  );

  // ---- 4. promo redemption -------------------------------------------
  console.log("\nPromo redemption");
  const o2 = db.collection("couriers").doc();
  created.push(o2);
  await o2.set(order({ promoCode: `SMOKE${SUFFIX}` }));
  const discounted = await waitFor(o2, (d) => d.fareAuthoritative === true);
  check(
    "discount applied (expected 200)",
    discounted && discounted.discountAmount === 200,
    discounted && `got ${discounted.discountAmount}`
  );

  const o3 = db.collection("couriers").doc();
  created.push(o3);
  await o3.set(order({ promoCode: `SMOKE${SUFFIX}` }));
  const reused = await waitFor(o3, (d) => d.fareAuthoritative === true);
  check(
    "same customer cannot reuse the code",
    reused && reused.discountAmount === 0,
    reused && `got ${reused.discountAmount}`
  );

  const redemption = await db
    .collection("promo_redemptions")
    .doc(`${PROMO_ID}_${TEST_USER}`)
    .get();
  check("redemption ledger entry written", redemption.exists);
  if (redemption.exists) created.push(redemption.ref);

  const promoAfter = await promoRef.get();
  check(
    "usedCount incremented exactly once",
    promoAfter.data().usedCount === 1,
    `got ${promoAfter.data().usedCount}`
  );

  // ---- 5. callables deployed -----------------------------------------
  console.log("\nCallable functions reachable");
  const region = "us-central1";
  for (const fn of [
    "initializePaystackPayment",
    "verifyPaystackPayment",
    "askMaya",
    "lookupReferralCode",
    "setUserRole",
    "reviewDriverApplication",
  ]) {
    const url = `https://${region}-${projectId}.cloudfunctions.net/${fn}`;
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data: {} }),
      });
      // Deployed and correctly refusing an unauthenticated caller.
      check(
        `${fn} deployed and rejects unauthenticated`,
        res.status === 401 || res.status === 403 || res.status === 400,
        `HTTP ${res.status}`
      );
    } catch (e) {
      check(`${fn} reachable`, false, e.message);
    }
  }
}

async function cleanup() {
  console.log("\nCleaning up");
  for (const ref of created) {
    await ref.delete().catch(() => undefined);
  }
  console.log(`  removed ${created.length} test documents`);
}

main()
  .catch((e) => {
    console.error("\nSmoke test crashed:", e.message);
    failed++;
  })
  .then(cleanup)
  .then(() => {
    console.log(`\n${passed} passed, ${failed} failed\n`);
    process.exit(failed === 0 ? 0 : 1);
  });
