// Shared setup for the security-rules tests.
//
// Every test runs against the Firestore and Storage emulators started by
// `firebase emulators:exec`, with the real firestore.rules / storage.rules
// loaded from the repo root — so these tests fail if the shipped rules change
// behaviour, which is the whole point.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), '..');

export const PROJECT_ID = 'demo-dilivvafast';

// Fixed uids so intent is readable at the call site.
export const CUSTOMER = 'customer_uid';
export const OTHER_CUSTOMER = 'other_customer_uid';
export const VERIFIED_DRIVER = 'verified_driver_uid';
export const UNVERIFIED_DRIVER = 'unverified_driver_uid';
export const ADMIN = 'admin_uid';

export async function makeTestEnv() {
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(join(repoRoot, 'firestore.rules'), 'utf8'),
    },
    storage: {
      rules: readFileSync(join(repoRoot, 'storage.rules'), 'utf8'),
    },
  });
}

/// The four account shapes the rules branch on. `isVerifiedDriver` is the flag
/// an admin approval sets; a driver without it must behave like a nobody.
export async function seedUsers(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(`users/${CUSTOMER}`).set({
      role: 'customer',
      fullName: 'Ada Customer',
      walletBalance: 5000,
    });
    await db.doc(`users/${OTHER_CUSTOMER}`).set({
      role: 'customer',
      fullName: 'Bola Customer',
      walletBalance: 0,
    });
    await db.doc(`users/${VERIFIED_DRIVER}`).set({
      role: 'driver',
      fullName: 'Chidi Driver',
      isVerifiedDriver: true,
      isOnline: false,
      walletBalance: 0,
    });
    await db.doc(`users/${UNVERIFIED_DRIVER}`).set({
      role: 'driver',
      fullName: 'Dele Applicant',
      isVerifiedDriver: false,
      isOnline: false,
      walletBalance: 0,
    });
    await db.doc(`users/${ADMIN}`).set({
      role: 'admin',
      fullName: 'Eze Admin',
    });
  });
}

/// Writes a document bypassing rules, for arrange steps.
export async function seedDoc(testEnv, path, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc(path).set(data);
  });
}

/// A booked-but-unassigned order, as the customer app writes it.
export function pendingOrder(overrides = {}) {
  return {
    userId: CUSTOMER,
    driverId: null,
    status: 'pending',
    paymentStatus: 'pending',
    totalFare: 2500,
    driverEarnings: 2000,
    pickupAddress: '12 Awolowo Rd, Ikoyi',
    dropoffAddress: '4 Adeola Odeku, VI',
    createdAt: new Date().toISOString(),
    ...overrides,
  };
}

/// A 1x1 PNG — small, and genuinely image/png so contentType checks pass.
export const TINY_PNG = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  'base64',
);
