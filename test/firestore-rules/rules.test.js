/**
 * Firestore security rules tests.
 *
 * Every case here corresponds to a hole that was open before the audit, or to
 * an access path the app genuinely needs and must keep.
 *
 * Requires the Firestore emulator, which needs a JVM:
 *
 *   npm install                       (in this directory)
 *   npm test
 *
 * The emulator could not be run on the audit machine (no Java installed), so
 * these assertions are written but UNVERIFIED. Run them before deploying rules.
 */

import { test, describe, before, after, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import {
  doc,
  getDoc,
  setDoc,
  deleteDoc,
  updateDoc,
  collection,
  getDocs,
  query,
  where,
} from "firebase/firestore";

let testEnv;

const CUSTOMER = "customer_1";
const OTHER_CUSTOMER = "customer_2";
const DRIVER = "driver_1";
const CAR_DRIVER = "driver_car";
const ADMIN = "admin_1";

/** Seed documents bypassing rules. */
async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "dilivvafast-rules-test",
    firestore: {
      rules: readFileSync("../../firestore.rules", "utf8"),
      host: "127.0.0.1",
      // 8085, not the emulator default of 8080 — that port is contended by
      // too many dev tools. Pointing the suite at an occupied port fails in a
      // thoroughly confusing way: loadFirestoreRules PUTs the rules to
      // whatever is listening and every test dies with `cancelledByParent`.
      // Keep this in step with `emulators.firestore.port` in firebase.json.
      port: 8085,
    },
  });
});

after(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seed(async (db) => {
    await setDoc(doc(db, "users", CUSTOMER), {
      role: "customer",
      walletBalance: 5000,
      email: "c1@example.com",
      phone: "+2348000000001",
    });
    await setDoc(doc(db, "users", OTHER_CUSTOMER), {
      role: "customer",
      walletBalance: 0,
      email: "c2@example.com",
    });
    await setDoc(doc(db, "users", DRIVER), {
      role: "driver",
      driverStatus: "approved",
      isOnline: true,
      isAvailable: true,
      walletBalance: 1200,
      email: "d1@example.com",
      fcmToken: "tok",
    });
    await setDoc(doc(db, "users", CAR_DRIVER), {
      role: "driver",
      driverStatus: "approved",
      vehicleType: "car",
    });
    await setDoc(doc(db, "users", ADMIN), { role: "admin" });
  });
});

const asCustomer = () => testEnv.authenticatedContext(CUSTOMER).firestore();
const asOther = () => testEnv.authenticatedContext(OTHER_CUSTOMER).firestore();
const asDriver = () => testEnv.authenticatedContext(DRIVER).firestore();
const asCarDriver = () => testEnv.authenticatedContext(CAR_DRIVER).firestore();
const asAdmin = () => testEnv.authenticatedContext(ADMIN).firestore();
const asAnon = () => testEnv.unauthenticatedContext().firestore();

describe("users", () => {
  test("a user reads only their own document", async () => {
    await assertSucceeds(getDoc(doc(asCustomer(), "users", CUSTOMER)));
    await assertFails(getDoc(doc(asCustomer(), "users", OTHER_CUSTOMER)));
  });

  test("a customer cannot read a driver's record", async () => {
    // Regression: the old rules let any signed-in user read every online
    // driver's full document, exposing email, phone, wallet and FCM token.
    await assertFails(getDoc(doc(asCustomer(), "users", DRIVER)));
  });

  test("registration cannot mint a wallet balance", async () => {
    const db = testEnv.authenticatedContext("new_user").firestore();
    await assertFails(
      setDoc(doc(db, "users", "new_user"), {
        role: "customer",
        walletBalance: 1000000,
      })
    );
    await assertSucceeds(
      setDoc(doc(db, "users", "new_user"), {
        role: "customer",
        walletBalance: 0,
      })
    );
  });

  test("a user cannot promote themselves to admin", async () => {
    await assertFails(updateDoc(doc(asCustomer(), "users", CUSTOMER), { role: "admin" }));
  });

  test("a user cannot top up their own wallet", async () => {
    await assertFails(
      updateDoc(doc(asCustomer(), "users", CUSTOMER), { walletBalance: 999999 })
    );
  });

  test("a user cannot approve their own driver application", async () => {
    await assertFails(
      updateDoc(doc(asCustomer(), "users", CUSTOMER), { driverStatus: "approved" })
    );
    await assertSucceeds(
      updateDoc(doc(asCustomer(), "users", CUSTOMER), { driverStatus: "pending" })
    );
  });

  test("an admin may update any user", async () => {
    await assertSucceeds(
      updateDoc(doc(asAdmin(), "users", CUSTOMER), { walletBalance: 10 })
    );
  });
});

describe("driver presence", () => {
  test("any signed-in user may read presence", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "driver_locations", DRIVER), {
        driverId: DRIVER,
        isOnline: true,
        isAvailable: true,
      });
    });
    await assertSucceeds(getDoc(doc(asCustomer(), "driver_locations", DRIVER)));
  });

  test("a driver publishes only their own presence", async () => {
    await assertSucceeds(
      setDoc(doc(asDriver(), "driver_locations", DRIVER), {
        driverId: DRIVER,
        isOnline: true,
      })
    );
    await assertFails(
      setDoc(doc(asDriver(), "driver_locations", "someone_else"), {
        driverId: "someone_else",
        isOnline: true,
      })
    );
  });

  test("identifying fields are rejected in the public projection", async () => {
    await assertFails(
      setDoc(doc(asDriver(), "driver_locations", DRIVER), {
        driverId: DRIVER,
        email: "d1@example.com",
      })
    );
    await assertFails(
      setDoc(doc(asDriver(), "driver_locations", DRIVER), {
        driverId: DRIVER,
        walletBalance: 1200,
      })
    );
  });

  test("anonymous users get nothing", async () => {
    await assertFails(getDoc(doc(asAnon(), "driver_locations", DRIVER)));
  });
});

describe("orders (couriers)", () => {
  const baseOrder = {
    userId: CUSTOMER,
    status: "pending",
    driverId: null,
    paymentStatus: "pending",
    driverEarnings: 0,
    platformCommission: 0,
    totalFare: 1500,
    baseFare: 500,
    discountAmount: 0,
    rating: null,
    proofOfDeliveryUrl: null,
    pickedUpAt: null,
    deliveredAt: null,
  };

  async function seedOrder(overrides = {}) {
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "order_1"), { ...baseOrder, ...overrides });
    });
  }

  test("an order is created unassigned, unpaid and unearned", async () => {
    await assertSucceeds(
      setDoc(doc(asCustomer(), "couriers", "order_new"), baseOrder)
    );
  });

  test("an order cannot be created already assigned or already delivered", async () => {
    await assertFails(
      setDoc(doc(asCustomer(), "couriers", "o2"), { ...baseOrder, driverId: DRIVER })
    );
    await assertFails(
      setDoc(doc(asCustomer(), "couriers", "o3"), { ...baseOrder, status: "delivered" })
    );
  });

  test("an order cannot be created pre-credited with driver earnings", async () => {
    await assertFails(
      setDoc(doc(asCustomer(), "couriers", "o4"), {
        ...baseOrder,
        driverEarnings: 50000,
      })
    );
  });

  test("negative fares are rejected", async () => {
    await assertFails(
      setDoc(doc(asCustomer(), "couriers", "o5"), { ...baseOrder, totalFare: -100 })
    );
  });

  test("an order cannot be created on someone else's behalf", async () => {
    await assertFails(
      setDoc(doc(asOther(), "couriers", "o6"), baseOrder)
    );
  });

  test("the customer cannot reprice their own order", async () => {
    await seedOrder();
    await assertFails(
      updateDoc(doc(asCustomer(), "couriers", "order_1"), { totalFare: 1 })
    );
  });

  test("the customer cannot mark their own delivery complete", async () => {
    await seedOrder({ status: "in_transit", driverId: DRIVER });
    await assertFails(
      updateDoc(doc(asCustomer(), "couriers", "order_1"), { status: "delivered" })
    );
  });

  test("the customer may cancel while pending or accepted", async () => {
    await seedOrder();
    await assertSucceeds(
      updateDoc(doc(asCustomer(), "couriers", "order_1"), { status: "cancelled" })
    );
  });

  test("the customer cannot cancel a delivered order", async () => {
    await seedOrder({ status: "delivered", driverId: DRIVER });
    await assertFails(
      updateDoc(doc(asCustomer(), "couriers", "order_1"), { status: "cancelled" })
    );
  });

  test("a driver cannot claim a job directly — only via an accepted offer", async () => {
    // Regression for the pre-negotiation rule, which let any approved driver
    // assign themselves to any pending job at whatever price was on it.
    await seedOrder();
    await assertFails(
      updateDoc(doc(asDriver(), "couriers", "order_1"), {
        driverId: DRIVER,
        status: "accepted",
      })
    );
  });

  test("a driver cannot steal a job already assigned to someone else", async () => {
    await seedOrder({ driverId: "driver_2", status: "accepted" });
    await assertFails(
      updateDoc(doc(asDriver(), "couriers", "order_1"), { driverId: DRIVER })
    );
  });

  test("a driver cannot skip states", async () => {
    await seedOrder({ driverId: DRIVER, status: "accepted" });
    // accepted -> delivered is not a legal transition.
    await assertFails(
      updateDoc(doc(asDriver(), "couriers", "order_1"), { status: "delivered" })
    );
    await assertSucceeds(
      updateDoc(doc(asDriver(), "couriers", "order_1"), { status: "picked_up" })
    );
  });

  test("a driver cannot raise their own earnings", async () => {
    await seedOrder({ driverId: DRIVER, status: "in_transit" });
    await assertFails(
      updateDoc(doc(asDriver(), "couriers", "order_1"), { driverEarnings: 99999 })
    );
  });

  test("an unrelated customer cannot read another customer's order", async () => {
    await seedOrder();
    await assertFails(getDoc(doc(asOther(), "couriers", "order_1")));
  });
});

describe("price negotiation (inDrive-style offers)", () => {
  // A request the server has priced: recommended ₦2000, customer offering
  // ₦1600. The ceiling is 3 × recommended = ₦6000.
  const pricedOrder = {
    userId: CUSTOMER,
    status: "pending",
    driverId: null,
    vehicleType: "bike",
    recommendedFare: 2000,
    offeredFare: 1600,
    totalFare: 1600,
  };

  async function seedPriced(overrides = {}) {
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "neg_1"), { ...pricedOrder, ...overrides });
    });
  }

  const bid = (db, driverId, data) =>
    setDoc(doc(db, "couriers", "neg_1", "bids", driverId), {
      driverId,
      status: "open",
      createdAt: new Date(),
      ...data,
    });

  test("a driver can accept the customer's price", async () => {
    await seedPriced();
    await assertSucceeds(bid(asDriver(), DRIVER, { amount: 1600 }));
  });

  test("a driver can counter-offer above it", async () => {
    await seedPriced();
    await assertSucceeds(bid(asDriver(), DRIVER, { amount: 2100, etaMinutes: 6 }));
  });

  test("an offer below the customer's own price is rejected", async () => {
    await seedPriced();
    await assertFails(bid(asDriver(), DRIVER, { amount: 1599 }));
  });

  test("an offer past the ceiling is rejected", async () => {
    await seedPriced();
    await assertFails(bid(asDriver(), DRIVER, { amount: 6001 }));
  });

  test("no offer before the server has priced the request", async () => {
    await seedPriced({ recommendedFare: 0 });
    await assertFails(bid(asDriver(), DRIVER, { amount: 1600 }));
  });

  test("a driver cannot forge their name, rating or plate", async () => {
    await seedPriced();
    await assertFails(
      bid(asDriver(), DRIVER, { amount: 1600, driverName: "Top Rated", driverRating: 5 })
    );
  });

  test("a driver cannot bid as someone else", async () => {
    await seedPriced();
    await assertFails(bid(asDriver(), "driver_2", { amount: 1600 }));
  });

  test("a customer cannot place an offer", async () => {
    await seedPriced();
    await assertFails(bid(asOther(), OTHER_CUSTOMER, { amount: 1600 }));
  });

  test("a car driver cannot bid on a bike request", async () => {
    await seedPriced();
    await assertFails(bid(asCarDriver(), CAR_DRIVER, { amount: 1600 }));
  });

  test("a car driver can bid on a car request", async () => {
    await seedPriced({ vehicleType: "car" });
    await assertSucceeds(bid(asCarDriver(), CAR_DRIVER, { amount: 1600 }));
  });

  test("no offers once a courier is assigned", async () => {
    await seedPriced({ status: "accepted", driverId: "driver_2" });
    await assertFails(bid(asDriver(), DRIVER, { amount: 1600 }));
  });

  test("the customer sees offers on their own request — nobody else does", async () => {
    await seedPriced();
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "neg_1", "bids", DRIVER), {
        driverId: DRIVER,
        amount: 1600,
        status: "open",
      });
    });
    await assertSucceeds(getDoc(doc(asCustomer(), "couriers", "neg_1", "bids", DRIVER)));
    await assertFails(getDoc(doc(asOther(), "couriers", "neg_1", "bids", DRIVER)));
  });

  test("the customer can decline an offer but not accept it directly", async () => {
    await seedPriced();
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "neg_1", "bids", DRIVER), {
        driverId: DRIVER,
        amount: 1600,
        status: "open",
      });
    });
    const ref = doc(asCustomer(), "couriers", "neg_1", "bids", DRIVER);
    // Accepting must go through the acceptBid function so it is atomic.
    await assertFails(updateDoc(ref, { status: "accepted" }));
    await assertSucceeds(updateDoc(ref, { status: "declined" }));
  });

  test("a driver can withdraw their open offer", async () => {
    await seedPriced();
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "neg_1", "bids", DRIVER), {
        driverId: DRIVER,
        amount: 1600,
        status: "open",
      });
    });
    await assertSucceeds(deleteDoc(doc(asDriver(), "couriers", "neg_1", "bids", DRIVER)));
  });

  test("the customer cannot change their offer directly", async () => {
    // Raising goes through the raiseOffer function, which bounds it.
    await seedPriced();
    await assertFails(
      updateDoc(doc(asCustomer(), "couriers", "neg_1"), { offeredFare: 1 })
    );
  });

  test("a client cannot set the recommended or agreed fare", async () => {
    await assertFails(
      setDoc(doc(asCustomer(), "couriers", "fake"), {
        ...pricedOrder,
        offeredFare: 100,
        recommendedFare: 100,
        totalFare: 100,
      })
    );
    await assertFails(
      setDoc(doc(asCustomer(), "couriers", "fake2"), {
        ...pricedOrder,
        recommendedFare: 0,
        agreedFare: 50,
      })
    );
  });

  test("a vehicle type outside bike/car is rejected", async () => {
    await assertFails(
      setDoc(doc(asCustomer(), "couriers", "fake3"), {
        ...pricedOrder,
        recommendedFare: 0,
        vehicleType: "helicopter",
      })
    );
  });
});

describe("support threads", () => {
  test("a user reads only their own support thread", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "orders", `support_${CUSTOMER}`), { userId: CUSTOMER });
    });
    await assertSucceeds(
      getDoc(doc(asCustomer(), "orders", `support_${CUSTOMER}`))
    );
    // Regression: `orderId.matches('support_.*')` let anyone read every thread.
    await assertFails(
      getDoc(doc(asOther(), "orders", `support_${CUSTOMER}`))
    );
  });
});

describe("notifications", () => {
  test("a user cannot enumerate everyone's notifications", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "notifications", "n1"), { userId: OTHER_CUSTOMER });
    });
    // Regression: `allow list: if isAuthenticated()` exposed the whole
    // collection regardless of owner.
    await assertFails(getDocs(collection(asCustomer(), "notifications")));
    await assertFails(getDoc(doc(asCustomer(), "notifications", "n1")));
  });

  test("a user may query their own notifications", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "notifications", "n2"), { userId: CUSTOMER });
    });
    await assertSucceeds(
      getDocs(
        query(collection(asCustomer(), "notifications"), where("userId", "==", CUSTOMER))
      )
    );
  });

  test("clients cannot author notifications", async () => {
    await assertFails(
      setDoc(doc(asCustomer(), "notifications", "n3"), { userId: CUSTOMER })
    );
  });
});

describe("financial ledgers", () => {
  test("clients cannot write transactions", async () => {
    await assertFails(
      setDoc(doc(asCustomer(), "transactions", "t1"), {
        userId: CUSTOMER,
        amount: 100000,
      })
    );
  });

  test("the payment idempotency ledger is invisible to clients", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "processed_payments", "ref_1"), { uid: CUSTOMER });
    });
    await assertFails(getDoc(doc(asCustomer(), "processed_payments", "ref_1")));
    await assertFails(getDoc(doc(asAdmin(), "processed_payments", "ref_1")));
  });

  test("payout records are read-only, and only by their driver", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "payouts", `${DRIVER}_2026-01-01`), {
        driverId: DRIVER,
        amount: 5000,
      });
    });
    await assertSucceeds(
      getDoc(doc(asDriver(), "payouts", `${DRIVER}_2026-01-01`))
    );
    await assertFails(
      getDoc(doc(asCustomer(), "payouts", `${DRIVER}_2026-01-01`))
    );
    await assertFails(
      setDoc(doc(asDriver(), "payouts", `${DRIVER}_2026-01-02`), {
        driverId: DRIVER,
        amount: 999999,
      })
    );
  });

  test("an investor profile cannot be created with fabricated totals", async () => {
    const db = testEnv.authenticatedContext("inv_1").firestore();
    await assertFails(
      setDoc(doc(db, "investors", "inv_1"), {
        userId: "inv_1",
        totalEarned: 5000000,
      })
    );
  });
});

/**
 * The tests above prove the holes are closed. These prove the app still works.
 *
 * A rules change has two failure modes, and denial tests only catch one of
 * them. Everything here is an access path the running app depends on; if any
 * of it regresses, real users are locked out of a working feature.
 */
describe("legitimate access still works", () => {
  test("a user updates their own profile", async () => {
    await assertSucceeds(
      updateDoc(doc(asCustomer(), "users", CUSTOMER), {
        fullName: "Updated Name",
        phone: "+2348000000009",
      })
    );
  });

  test("an investor updates a non-financial field on their own profile", async () => {
    // Exercises the `affects()` helper against an existing document — the
    // path that speculative evaluation on a missing doc does not cover.
    await seed(async (db) => {
      await setDoc(doc(db, "investors", CUSTOMER), {
        userId: CUSTOMER,
        totalInvested: 0,
        totalEarned: 0,
        bankName: "Old Bank",
      });
    });
    await assertSucceeds(
      updateDoc(doc(asCustomer(), "investors", CUSTOMER), { bankName: "New Bank" })
    );
  });

  test("a customer reads their own order and transactions", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "mine"), { userId: CUSTOMER, status: "pending" });
      await setDoc(doc(db, "transactions", "t_mine"), { userId: CUSTOMER, amount: 100 });
    });
    await assertSucceeds(getDoc(doc(asCustomer(), "couriers", "mine")));
    await assertSucceeds(getDoc(doc(asCustomer(), "transactions", "t_mine")));
  });

  test("a customer lists their own orders", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "mine"), { userId: CUSTOMER, status: "pending" });
    });
    await assertSucceeds(
      getDocs(
        query(collection(asCustomer(), "couriers"), where("userId", "==", CUSTOMER))
      )
    );
  });

  test("a driver browses the unassigned queue", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "open"), { userId: OTHER_CUSTOMER, status: "pending" });
    });
    await assertSucceeds(getDocs(collection(asDriver(), "couriers")));
  });

  test("a driver reads and progresses a job assigned to them", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "job"), {
        userId: OTHER_CUSTOMER,
        driverId: DRIVER,
        status: "picked_up",
      });
    });
    await assertSucceeds(getDoc(doc(asDriver(), "couriers", "job")));
    await assertSucceeds(
      updateDoc(doc(asDriver(), "couriers", "job"), { status: "in_transit" })
    );
  });

  test("a driver completes a delivery from in_transit", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "job"), {
        userId: OTHER_CUSTOMER,
        driverId: DRIVER,
        status: "in_transit",
      });
    });
    await assertSucceeds(
      updateDoc(doc(asDriver(), "couriers", "job"), {
        status: "delivered",
        deliveredAt: new Date(),
      })
    );
  });

  test("a customer rates a delivered order", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "done"), {
        userId: CUSTOMER,
        driverId: DRIVER,
        status: "delivered",
      });
    });
    await assertSucceeds(
      updateDoc(doc(asCustomer(), "couriers", "done"), {
        rating: 5,
        ratingComment: "Great service",
      })
    );
  });

  test("order chat works for both parties", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "couriers", "chat"), {
        userId: CUSTOMER,
        driverId: DRIVER,
        status: "in_transit",
      });
    });
    await assertSucceeds(
      setDoc(doc(asCustomer(), "couriers", "chat", "messages", "m1"), {
        senderId: CUSTOMER,
        text: "I am at the gate",
      })
    );
    await assertSucceeds(
      getDocs(collection(asDriver(), "couriers", "chat", "messages"))
    );
  });

  test("a user writes in their own support thread", async () => {
    await assertSucceeds(
      setDoc(doc(asCustomer(), "orders", `support_${CUSTOMER}`), {
        userId: CUSTOMER,
        subject: "Where is my parcel",
      })
    );
    await assertSucceeds(
      setDoc(
        doc(asCustomer(), "orders", `support_${CUSTOMER}`, "messages", "m1"),
        { senderId: CUSTOMER, text: "Hello" }
      )
    );
  });

  test("reference data is readable by any signed-in user", async () => {
    await seed(async (db) => {
      await setDoc(doc(db, "zones", "lagos"), { name: "Lagos", isActive: true });
      await setDoc(doc(db, "promos", "p1"), { code: "WELCOME", isActive: true });
      await setDoc(doc(db, "app_config", "pricing"), { commission: 0.2 });
    });
    await assertSucceeds(getDoc(doc(asCustomer(), "zones", "lagos")));
    await assertSucceeds(getDoc(doc(asCustomer(), "promos", "p1")));
    await assertSucceeds(getDoc(doc(asCustomer(), "app_config", "pricing")));
  });

  test("a user raises an SOS and files a support ticket", async () => {
    await assertSucceeds(
      setDoc(doc(asCustomer(), "sos_alerts", "s1"), {
        userId: CUSTOMER,
        orderId: "mine",
      })
    );
    await assertSucceeds(
      setDoc(doc(asCustomer(), "support_tickets", "st1"), {
        userId: CUSTOMER,
        subject: "Damaged item",
      })
    );
  });

  test("a user requests driver access by moving their own status to pending", async () => {
    await assertSucceeds(
      updateDoc(doc(asCustomer(), "users", CUSTOMER), { driverStatus: "pending" })
    );
  });

  test("a user manages their own saved addresses and payment methods", async () => {
    await assertSucceeds(
      setDoc(doc(asCustomer(), "users", CUSTOMER, "saved_addresses", "a1"), {
        label: "Home",
        address: "1 Marina",
      })
    );
    await assertSucceeds(
      setDoc(doc(asCustomer(), "users", CUSTOMER, "payment_methods", "pm1"), {
        last4: "4242",
      })
    );
  });

  test("a user submits a driver application and a withdrawal request", async () => {
    await assertSucceeds(
      setDoc(doc(asCustomer(), "driver_applications", "app1"), {
        userId: CUSTOMER,
        status: "submitted",
      })
    );
    await assertSucceeds(
      setDoc(doc(asCustomer(), "withdrawal_requests", "w1"), {
        userId: CUSTOMER,
        status: "pending",
        amount: 5000,
      })
    );
  });
});

describe("catch-all", () => {
  test("an undeclared collection is denied", async () => {
    await assertFails(getDoc(doc(asCustomer(), "some_random_collection", "x")));
    await assertFails(
      setDoc(doc(asAdmin(), "some_random_collection", "x"), { a: 1 })
    );
  });
});
