// Firestore security-rules tests.
//
// These exist because the rules were previously only reasoned about, never
// executed. Each block below pins down one privilege boundary; the negative
// cases are the ones that matter, since a rule that is accidentally permissive
// still looks fine in code review.

import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import {
  ADMIN,
  CUSTOMER,
  OTHER_CUSTOMER,
  UNVERIFIED_DRIVER,
  VERIFIED_DRIVER,
  makeTestEnv,
  pendingOrder,
  seedDoc,
  seedUsers,
} from './helpers.mjs';

let testEnv;

const db = (uid) =>
  uid === null
    ? testEnv.unauthenticatedContext().firestore()
    : testEnv.authenticatedContext(uid).firestore();

before(async () => {
  testEnv = await makeTestEnv();
});

after(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seedUsers(testEnv);
});

// ==================== SEC-3: ROLE ESCALATION ON CREATE ====================

describe('users — sign-up cannot mint privilege (SEC-3)', () => {
  const newUid = 'brand_new_uid';

  it('allows creating a customer account', async () => {
    await assertSucceeds(
      setDoc(doc(db(newUid), `users/${newUid}`), {
        role: 'customer',
        fullName: 'New Person',
      }),
    );
  });

  it('rejects self-assigning the admin role', async () => {
    await assertFails(
      setDoc(doc(db(newUid), `users/${newUid}`), {
        role: 'admin',
        fullName: 'Attacker',
      }),
    );
  });

  it('rejects self-assigning the driver role', async () => {
    await assertFails(
      setDoc(doc(db(newUid), `users/${newUid}`), {
        role: 'driver',
        fullName: 'Attacker',
      }),
    );
  });

  it('rejects a sign-up that pre-funds its own wallet', async () => {
    await assertFails(
      setDoc(doc(db(newUid), `users/${newUid}`), {
        role: 'customer',
        fullName: 'Attacker',
        walletBalance: 1000000,
      }),
    );
  });

  it('rejects a sign-up that pre-sets isVerifiedDriver', async () => {
    await assertFails(
      setDoc(doc(db(newUid), `users/${newUid}`), {
        role: 'customer',
        fullName: 'Attacker',
        isVerifiedDriver: true,
      }),
    );
  });

  it('rejects creating an account for somebody else', async () => {
    await assertFails(
      setDoc(doc(db(newUid), `users/${OTHER_CUSTOMER}_new`), {
        role: 'customer',
        fullName: 'Impostor',
      }),
    );
  });
});

describe('users — profile edits cannot escalate', () => {
  it('allows editing an ordinary profile field', async () => {
    await assertSucceeds(
      updateDoc(doc(db(CUSTOMER), `users/${CUSTOMER}`), {
        fullName: 'Ada Renamed',
      }),
    );
  });

  it('rejects promoting yourself to admin', async () => {
    await assertFails(
      updateDoc(doc(db(CUSTOMER), `users/${CUSTOMER}`), { role: 'admin' }),
    );
  });

  it('rejects topping up your own wallet', async () => {
    await assertFails(
      updateDoc(doc(db(CUSTOMER), `users/${CUSTOMER}`), {
        walletBalance: 9999999,
      }),
    );
  });

  it('rejects marking yourself a verified driver', async () => {
    await assertFails(
      updateDoc(doc(db(UNVERIFIED_DRIVER), `users/${UNVERIFIED_DRIVER}`), {
        isVerifiedDriver: true,
      }),
    );
  });

  it('rejects inflating your own rating', async () => {
    await assertFails(
      updateDoc(doc(db(VERIFIED_DRIVER), `users/${VERIFIED_DRIVER}`), {
        averageRating: 5,
      }),
    );
  });

  it('rejects reading another user profile', async () => {
    await assertFails(getDoc(doc(db(CUSTOMER), `users/${OTHER_CUSTOMER}`)));
  });

  it('allows an admin to read any profile', async () => {
    await assertSucceeds(getDoc(doc(db(ADMIN), `users/${CUSTOMER}`)));
  });
});

// ==================== DRIVER VERIFICATION GATE ====================

describe('users — only an approved driver may go on duty', () => {
  it('allows a verified driver to go online', async () => {
    await assertSucceeds(
      updateDoc(doc(db(VERIFIED_DRIVER), `users/${VERIFIED_DRIVER}`), {
        isOnline: true,
      }),
    );
  });

  it('rejects an unverified driver going online', async () => {
    await assertFails(
      updateDoc(doc(db(UNVERIFIED_DRIVER), `users/${UNVERIFIED_DRIVER}`), {
        isOnline: true,
      }),
    );
  });
});

// ==================== SEC-6: ORDER FIELD RESTRICTIONS ====================

describe('orders — booking', () => {
  it('allows a customer to book a pending, unassigned order', async () => {
    await assertSucceeds(
      setDoc(doc(db(CUSTOMER), 'orders/o_new'), pendingOrder()),
    );
  });

  it('rejects booking an order that arrives pre-assigned to a driver', async () => {
    await assertFails(
      setDoc(
        doc(db(CUSTOMER), 'orders/o_new'),
        pendingOrder({ driverId: VERIFIED_DRIVER }),
      ),
    );
  });

  it('rejects booking an order that starts already accepted', async () => {
    await assertFails(
      setDoc(
        doc(db(CUSTOMER), 'orders/o_new'),
        pendingOrder({ status: 'accepted' }),
      ),
    );
  });

  it('rejects booking an order that declares itself already paid', async () => {
    await assertFails(
      setDoc(
        doc(db(CUSTOMER), 'orders/o_new'),
        pendingOrder({ paymentStatus: 'paid' }),
      ),
    );
  });

  it('rejects booking in somebody else name', async () => {
    await assertFails(
      setDoc(
        doc(db(CUSTOMER), 'orders/o_new'),
        pendingOrder({ userId: OTHER_CUSTOMER }),
      ),
    );
  });
});

describe('orders — the customer cannot rewrite their own delivery', () => {
  beforeEach(async () => {
    await seedDoc(testEnv, 'orders/o1', pendingOrder());
  });

  it('rejects the customer lowering the fare', async () => {
    await assertFails(
      updateDoc(doc(db(CUSTOMER), 'orders/o1'), { totalFare: 1 }),
    );
  });

  it('rejects the customer assigning a driver', async () => {
    await assertFails(
      updateDoc(doc(db(CUSTOMER), 'orders/o1'), { driverId: VERIFIED_DRIVER }),
    );
  });

  it('rejects the customer marking the order paid', async () => {
    await assertFails(
      updateDoc(doc(db(CUSTOMER), 'orders/o1'), { paymentStatus: 'paid' }),
    );
  });

  it('rejects a direct cancel — it must go through cancelOrder so the refund is paid', async () => {
    await assertFails(
      updateDoc(doc(db(CUSTOMER), 'orders/o1'), { status: 'cancelled' }),
    );
  });

  it('allows the customer to rate the delivery', async () => {
    await assertSucceeds(
      updateDoc(doc(db(CUSTOMER), 'orders/o1'), {
        rating: 5,
        ratingComment: 'Fast',
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('rejects an unrelated customer reading the order', async () => {
    await assertFails(getDoc(doc(db(OTHER_CUSTOMER), 'orders/o1')));
  });

  it('rejects an anonymous read', async () => {
    await assertFails(getDoc(doc(db(null), 'orders/o1')));
  });
});

describe('orders — claiming', () => {
  beforeEach(async () => {
    await seedDoc(testEnv, 'orders/o1', pendingOrder());
  });

  it('allows a verified driver to claim a pending order', async () => {
    await assertSucceeds(
      updateDoc(doc(db(VERIFIED_DRIVER), 'orders/o1'), {
        driverId: VERIFIED_DRIVER,
        status: 'accepted',
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('rejects an unverified driver claiming an order', async () => {
    await assertFails(
      updateDoc(doc(db(UNVERIFIED_DRIVER), 'orders/o1'), {
        driverId: UNVERIFIED_DRIVER,
        status: 'accepted',
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('rejects a driver assigning the order to someone else', async () => {
    await assertFails(
      updateDoc(doc(db(VERIFIED_DRIVER), 'orders/o1'), {
        driverId: UNVERIFIED_DRIVER,
        status: 'accepted',
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('rejects a driver smuggling a fare change into the claim', async () => {
    await assertFails(
      updateDoc(doc(db(VERIFIED_DRIVER), 'orders/o1'), {
        driverId: VERIFIED_DRIVER,
        status: 'accepted',
        totalFare: 999999,
        updatedAt: new Date().toISOString(),
      }),
    );
  });

  it('rejects stealing an order already assigned to another driver', async () => {
    await seedDoc(
      testEnv,
      'orders/o2',
      pendingOrder({ driverId: UNVERIFIED_DRIVER, status: 'accepted' }),
    );
    await assertFails(
      updateDoc(doc(db(VERIFIED_DRIVER), 'orders/o2'), {
        driverId: VERIFIED_DRIVER,
        status: 'accepted',
        updatedAt: new Date().toISOString(),
      }),
    );
  });
});

describe('orders — the assigned driver progressing a delivery', () => {
  beforeEach(async () => {
    await seedDoc(
      testEnv,
      'orders/o1',
      pendingOrder({ driverId: VERIFIED_DRIVER, status: 'accepted' }),
    );
  });

  it('allows pushing a live location', async () => {
    await assertSucceeds(
      updateDoc(doc(db(VERIFIED_DRIVER), 'orders/o1'), {
        driverLocation: { latitude: 6.45, longitude: 3.4 },
        driverLocationUpdatedAt: new Date().toISOString(),
      }),
    );
  });

  it('allows advancing the status', async () => {
    await assertSucceeds(
      updateDoc(doc(db(VERIFIED_DRIVER), 'orders/o1'), {
        status: 'picked_up',
        pickedUpAt: new Date().toISOString(),
      }),
    );
  });

  it('rejects the driver raising their own earnings', async () => {
    await assertFails(
      updateDoc(doc(db(VERIFIED_DRIVER), 'orders/o1'), {
        driverEarnings: 999999,
      }),
    );
  });

  it('rejects the driver marking the order paid', async () => {
    await assertFails(
      updateDoc(doc(db(VERIFIED_DRIVER), 'orders/o1'), {
        paymentStatus: 'paid',
      }),
    );
  });

  it('rejects an uninvolved driver touching the order', async () => {
    await assertFails(
      updateDoc(doc(db(UNVERIFIED_DRIVER), 'orders/o1'), { status: 'delivered' }),
    );
  });
});

// ==================== SUPPORT THREADS ====================

describe('orders — support threads are private to their owner', () => {
  beforeEach(async () => {
    await seedDoc(testEnv, `orders/support_${CUSTOMER}`, {
      userId: CUSTOMER,
      status: 'support',
    });
  });

  it('allows the owner to read their support thread', async () => {
    await assertSucceeds(
      getDoc(doc(db(CUSTOMER), `orders/support_${CUSTOMER}`)),
    );
  });

  it('rejects reading somebody else support thread', async () => {
    await assertFails(
      getDoc(doc(db(OTHER_CUSTOMER), `orders/support_${CUSTOMER}`)),
    );
  });
});

// ==================== ORDER MESSAGES ====================

describe('orders/{id}/messages', () => {
  beforeEach(async () => {
    await seedDoc(
      testEnv,
      'orders/o1',
      pendingOrder({ driverId: VERIFIED_DRIVER, status: 'accepted' }),
    );
  });

  it('allows a participant to send a message as themselves', async () => {
    await assertSucceeds(
      setDoc(doc(db(CUSTOMER), 'orders/o1/messages/m1'), {
        senderId: CUSTOMER,
        text: 'On my way?',
      }),
    );
  });

  it('rejects sending a message under a forged sender id', async () => {
    await assertFails(
      setDoc(doc(db(CUSTOMER), 'orders/o1/messages/m1'), {
        senderId: VERIFIED_DRIVER,
        text: 'Forged',
      }),
    );
  });

  it('rejects a non-participant reading the thread', async () => {
    await seedDoc(testEnv, 'orders/o1/messages/m1', {
      senderId: CUSTOMER,
      text: 'Private',
    });
    await assertFails(getDoc(doc(db(OTHER_CUSTOMER), 'orders/o1/messages/m1')));
  });

  it('rejects editing a sent message', async () => {
    await seedDoc(testEnv, 'orders/o1/messages/m1', {
      senderId: CUSTOMER,
      text: 'Original',
    });
    await assertFails(
      updateDoc(doc(db(CUSTOMER), 'orders/o1/messages/m1'), { text: 'Edited' }),
    );
  });
});

// ==================== MONEY ====================

describe('transactions — server-written only', () => {
  beforeEach(async () => {
    await seedDoc(testEnv, 'transactions/t1', {
      userId: CUSTOMER,
      amount: 5000,
      type: 'credit',
    });
  });

  it('allows the owner to read their transaction', async () => {
    await assertSucceeds(getDoc(doc(db(CUSTOMER), 'transactions/t1')));
  });

  it('rejects another user reading it', async () => {
    await assertFails(getDoc(doc(db(OTHER_CUSTOMER), 'transactions/t1')));
  });

  it('rejects a client minting a transaction', async () => {
    await assertFails(
      setDoc(doc(db(CUSTOMER), 'transactions/t2'), {
        userId: CUSTOMER,
        amount: 500000,
        type: 'credit',
      }),
    );
  });
});

describe('driver_payouts — untouchable by clients', () => {
  beforeEach(async () => {
    await seedDoc(testEnv, 'driver_payouts/p1', {
      driverId: VERIFIED_DRIVER,
      amount: 15000,
    });
  });

  it('rejects a driver reading the payout ledger', async () => {
    await assertFails(getDoc(doc(db(VERIFIED_DRIVER), 'driver_payouts/p1')));
  });

  it('rejects a driver writing a payout record', async () => {
    await assertFails(
      setDoc(doc(db(VERIFIED_DRIVER), 'driver_payouts/p2'), {
        driverId: VERIFIED_DRIVER,
        amount: 999999,
      }),
    );
  });

  it('allows an admin to read it', async () => {
    await assertSucceeds(getDoc(doc(db(ADMIN), 'driver_payouts/p1')));
  });
});

// ==================== DRIVER APPLICATIONS ====================

describe('driver_applications — approval is an admin act', () => {
  it('allows submitting an application for yourself', async () => {
    await assertSucceeds(
      setDoc(doc(db(UNVERIFIED_DRIVER), 'driver_applications/a1'), {
        userId: UNVERIFIED_DRIVER,
        status: 'submitted',
        ninNumber: '12345678901',
      }),
    );
  });

  it('rejects submitting an already-approved application', async () => {
    await assertFails(
      setDoc(doc(db(UNVERIFIED_DRIVER), 'driver_applications/a1'), {
        userId: UNVERIFIED_DRIVER,
        status: 'approved',
      }),
    );
  });

  it('rejects applying on behalf of another user', async () => {
    await assertFails(
      setDoc(doc(db(UNVERIFIED_DRIVER), 'driver_applications/a1'), {
        userId: CUSTOMER,
        status: 'submitted',
      }),
    );
  });

  describe('once submitted', () => {
    beforeEach(async () => {
      await seedDoc(testEnv, 'driver_applications/a1', {
        userId: UNVERIFIED_DRIVER,
        status: 'submitted',
        ninNumber: '12345678901',
      });
    });

    it('allows the applicant to amend their documents', async () => {
      await assertSucceeds(
        updateDoc(doc(db(UNVERIFIED_DRIVER), 'driver_applications/a1'), {
          ninNumber: '10987654321',
        }),
      );
    });

    it('rejects the applicant approving themselves', async () => {
      await assertFails(
        updateDoc(doc(db(UNVERIFIED_DRIVER), 'driver_applications/a1'), {
          status: 'approved',
        }),
      );
    });

    it('allows an admin to approve', async () => {
      await assertSucceeds(
        updateDoc(doc(db(ADMIN), 'driver_applications/a1'), {
          status: 'approved',
        }),
      );
    });

    it('rejects an unrelated user reading the application', async () => {
      await assertFails(
        getDoc(doc(db(CUSTOMER), 'driver_applications/a1')),
      );
    });
  });
});

// ==================== REFERRALS ====================

describe('referrals — a client cannot mint a bonus', () => {
  it('allows recording that you were referred', async () => {
    await assertSucceeds(
      setDoc(doc(db(CUSTOMER), 'referrals/r1'), {
        refereeId: CUSTOMER,
        status: 'pending',
        code: 'ADA123',
      }),
    );
  });

  it('rejects naming the referrer yourself — the server resolves it from the code', async () => {
    await assertFails(
      setDoc(doc(db(CUSTOMER), 'referrals/r1'), {
        refereeId: CUSTOMER,
        referrerId: OTHER_CUSTOMER,
        status: 'pending',
        code: 'ADA123',
      }),
    );
  });

  it('rejects self-completing a referral', async () => {
    await assertFails(
      setDoc(doc(db(CUSTOMER), 'referrals/r1'), {
        refereeId: CUSTOMER,
        status: 'completed',
        code: 'ADA123',
      }),
    );
  });

  it('rejects updating a referral after the fact', async () => {
    await seedDoc(testEnv, 'referrals/r1', {
      refereeId: CUSTOMER,
      referrerId: OTHER_CUSTOMER,
      status: 'pending',
    });
    await assertFails(
      updateDoc(doc(db(CUSTOMER), 'referrals/r1'), { status: 'completed' }),
    );
  });
});

// ==================== SOS ====================

describe('sos_alerts', () => {
  it('allows raising an alert for yourself', async () => {
    await assertSucceeds(
      setDoc(doc(db(CUSTOMER), 'sos_alerts/s1'), {
        userId: CUSTOMER,
        status: 'active',
        orderId: 'o1',
      }),
    );
  });

  it('rejects raising an alert in another user name', async () => {
    await assertFails(
      setDoc(doc(db(CUSTOMER), 'sos_alerts/s1'), {
        userId: OTHER_CUSTOMER,
        status: 'active',
      }),
    );
  });

  it('rejects a user closing their own alert', async () => {
    await seedDoc(testEnv, 'sos_alerts/s1', {
      userId: CUSTOMER,
      status: 'active',
    });
    await assertFails(
      updateDoc(doc(db(CUSTOMER), 'sos_alerts/s1'), { status: 'resolved' }),
    );
  });

  it('allows an admin to resolve it', async () => {
    await seedDoc(testEnv, 'sos_alerts/s1', {
      userId: CUSTOMER,
      status: 'active',
    });
    await assertSucceeds(
      updateDoc(doc(db(ADMIN), 'sos_alerts/s1'), { status: 'resolved' }),
    );
  });
});

// ==================== RATINGS ====================

describe('ratings — immutable once written', () => {
  it('allows rating as yourself', async () => {
    await assertSucceeds(
      setDoc(doc(db(CUSTOMER), 'ratings/r1'), {
        userId: CUSTOMER,
        driverId: VERIFIED_DRIVER,
        stars: 5,
      }),
    );
  });

  it('rejects rating under another user id', async () => {
    await assertFails(
      setDoc(doc(db(CUSTOMER), 'ratings/r1'), {
        userId: OTHER_CUSTOMER,
        driverId: VERIFIED_DRIVER,
        stars: 1,
      }),
    );
  });

  it('rejects editing a rating, since driver averages derive from it', async () => {
    await seedDoc(testEnv, 'ratings/r1', {
      userId: CUSTOMER,
      driverId: VERIFIED_DRIVER,
      stars: 5,
    });
    await assertFails(
      updateDoc(doc(db(CUSTOMER), 'ratings/r1'), { stars: 1 }),
    );
  });

  it('rejects deleting a rating', async () => {
    await seedDoc(testEnv, 'ratings/r1', {
      userId: CUSTOMER,
      driverId: VERIFIED_DRIVER,
      stars: 1,
    });
    await assertFails(deleteDoc(doc(db(CUSTOMER), 'ratings/r1')));
  });
});

// ==================== ADMIN-ONLY COLLECTIONS ====================

describe('zones and promos are read-only to ordinary users', () => {
  beforeEach(async () => {
    await seedDoc(testEnv, 'zones/z1', { name: 'Lagos Island', baseFare: 1000 });
  });

  it('allows any signed-in user to read a zone', async () => {
    await assertSucceeds(getDoc(doc(db(CUSTOMER), 'zones/z1')));
  });

  it('rejects a customer rewriting the fare table', async () => {
    await assertFails(
      updateDoc(doc(db(CUSTOMER), 'zones/z1'), { baseFare: 1 }),
    );
  });

  it('allows an admin to rewrite it', async () => {
    await assertSucceeds(
      updateDoc(doc(db(ADMIN), 'zones/z1'), { baseFare: 1200 }),
    );
  });
});

// ==================== CATCH-ALL ====================

describe('catch-all denies unknown collections', () => {
  it('rejects writing to a collection the rules never mention', async () => {
    await assertFails(
      setDoc(doc(db(CUSTOMER), 'arbitrary_collection/x1'), { anything: true }),
    );
  });

  it('rejects reading one, even as admin', async () => {
    await seedDoc(testEnv, 'arbitrary_collection/x1', { anything: true });
    await assertFails(getDoc(doc(db(ADMIN), 'arbitrary_collection/x1')));
  });
});
