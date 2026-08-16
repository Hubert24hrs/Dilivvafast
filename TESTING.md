# Manual smoke test

Automated tests cover logic, not Firebase. Everything below needs a real
project, so it has to be walked by hand on a device.

**Prerequisite:** the rules and Cloud Functions in this branch are **not
deployed**. Until they are, every item marked 🔒 will fail with a permission
error, and every item marked ⚙️ will fail because the function does not exist
yet. Deploy per SECURITY.md first.

Set up before you start:

- [ ] Rules deployed (`firebase deploy --only firestore:rules,storage:rules`)
- [ ] Functions deployed (`firebase deploy --only functions`)
- [ ] Secrets set: `PAYSTACK_SECRET_KEY`, `PAYSTACK_WEBHOOK_SECRET`, `ANTHROPIC_API_KEY`
- [ ] Webhook URL registered in the Paystack dashboard
- [ ] At least one document in `zones` — without it fares fall back to
      ₦500 base / ₦100 per km
- [ ] Existing driver accounts backfilled with `isVerifiedDriver` (script in
      SECURITY.md) — otherwise no existing driver can go online

Three accounts on three devices (or one device, signing out between roles):
a customer, a driver, and an admin. The admin has to be promoted with an Admin
SDK script — there is deliberately no self-service path.

---

## Journey 1 — Customer books and tracks a delivery

- [ ] Register a new account. Pick **Driver** in the role selector on purpose.
- [ ] 🔒 Sign-up succeeds and lands on the **customer** home, not a driver
      home. In Firestore the document reads `role: customer` with
      `requestedRole: driver`. *(This is the escalation fix — a failure here
      means the client is still self-assigning roles.)*
- [ ] Fund the wallet: Wallet → Fund Wallet → ₦1,000 → Pay Now.
- [ ] ⚙️ Paystack checkout opens in the browser. Complete it with a
      [test card](https://paystack.com/docs/payments/test-payments/).
- [ ] Return to the app. The balance updates without tapping anything —
      verification runs on resume.
- [ ] Tap **I've completed payment** again. The message says the payment was
      *already* credited and the balance does **not** move. *(Idempotency.)*
- [ ] Book a delivery: pickup, dropoff, package details, confirm.
- [ ] ⚙️ The fare on the order in Firestore matches the zone configuration,
      not whatever the client displayed. `fareLockedAt` is set.
- [ ] Open the order from Orders. The map shows pickup and dropoff pins, and
      no driver pin yet.

## Journey 2 — Driver accepts and completes

- [ ] Sign in as the driver. Try the online toggle **before** approval.
- [ ] 🔒 It refuses with "Your driver application has not been approved yet"
      and offers an **Apply** action.
- [ ] Submit a driver application with documents.
- [ ] 🔒 The upload lands in `driver_applications/<uid>/` in Storage, and is
      **not** readable while signed in as the customer.
- [ ] After approval (Journey 3), toggle online. Grant location, then grant
      **Allow all the time** when asked the second time.
- [ ] ⚙️ A push notification arrives for the pending order. *(Needs the driver
      marked online in Firestore and an `fcmToken` on their user document —
      check both if nothing arrives.)*
- [ ] Accept the order. The customer's screen shows "Accepted".
- [ ] Open the active delivery. Move around (or use the emulator's location
      controls).
- [ ] 🔒 The customer's tracking map shows the driver pin **moving**. This is
      the whole point of writing location to the order rather than the user
      document.
- [ ] Send a message from the driver's chat; it arrives on the customer side,
      and vice versa.
- [ ] Background the driver app and keep moving. The customer's pin keeps
      updating. *(Background location. If it freezes, the "Allow all the time"
      grant did not stick.)*
- [ ] Progress the delivery: picked up → in transit → delivered.
- [ ] The customer gets a push at each step.
- [ ] Driver earnings reflect the completed delivery.

## Journey 3 — Admin approves a driver

- [ ] Sign in as the admin. Go to **Applications**.
- [ ] 🔒 The pending application is listed with name, phone, vehicle, and which
      documents were uploaded. *(A placeholder screen here means the build
      predates the approval queue.)*
- [ ] Tap **Approve**.
- [ ] ⚙️ Within a few seconds the driver's user document flips to
      `role: driver`, `isVerifiedDriver: true`. The driver gets a push saying
      they are approved.
- [ ] The driver can now go online (back to Journey 2).
- [ ] Reject a second application with a reason. That account is forced offline
      and drops back to `customer`.

## Cross-cutting

- [ ] **Cancellation refund** — book, then cancel before pickup. ⚙️ The full
      fare returns to the wallet and a `refund` transaction appears. Cancel
      another after pickup: half returns.
- [ ] **SOS** — long-press SOS on the customer tracking screen and on the
      driver's active delivery. ⚙️ Admins receive an urgent push; the alert is
      in `sos_alerts`.
- [ ] **Support chat** — open support chat as two different customers. 🔒
      Neither can see the other's conversation.
- [ ] **Maya** — ask a question in support chat. ⚙️ A real answer comes back.
      Without `ANTHROPIC_API_KEY` set it falls back to canned replies, which is
      the intended degradation, not a failure.
- [ ] **Offline** — turn off data mid-session. The connectivity banner appears
      and nothing crashes.
- [ ] **Firebase failure** — launch with a deliberately broken
      `google-services.json`. The error screen appears; **Retry** shows a
      spinner and does not stack duplicate notification handlers.

---

## What automated tests already cover

Don't re-check these by hand:

| Area | File |
|---|---|
| Order status transitions | `test/unit/order_status_transition_test.dart` |
| Payment init + verification, idempotency reporting | `test/unit/payment_repository_test.dart` |
| Signup never grants a privileged role | `test/unit/signup_role_test.dart` |
| Validators, role guard, rate limiter, input validation | `test/unit/`, `test/services/` |

## Known gaps

- **No security-rules tests.** The rules are reasoned about, not executed.
  `@firebase/rules-unit-testing` against the emulator would catch a
  field-name mismatch before it reaches a device; two such mismatches were
  found by reading during this audit and there may be more.
- **No integration test** driving a full booking against the emulator suite.
- Cloud Functions have no unit tests; they are typechecked only.
