# Security review — READ BEFORE DEPLOYING

This file describes changes to `firestore.rules`, `storage.rules`, and the
Cloud Functions that **have not been deployed**. They touch production data and
production money. Review them, then deploy deliberately.

Nothing in this repo has been deployed automatically.

---

## Do this first: rotate the exposed Paystack key

`sk_test_8a005c6bea1bf16bc47ffae780c8e76a8a5ce347` was committed in
`lib/core/constants/app_constants.dart` and is present in the git history of a
**public** repository (commits `01cab95` and `9546a7e`). It has been removed
from the working tree, but removing it from `HEAD` does not remove it from
history — anyone who cloned the repo still has it.

1. Revoke and regenerate the key in the Paystack dashboard.
2. Store the new one as a Cloud Functions secret (never in the repo):
   ```bash
   firebase functions:secrets:set PAYSTACK_SECRET_KEY
   firebase functions:secrets:set PAYSTACK_WEBHOOK_SECRET
   firebase functions:secrets:set ANTHROPIC_API_KEY
   ```
3. Consider purging the history (`git filter-repo`) or making the repo private.
   Treat the old key as compromised regardless.

Do the same for any Anthropic key or SMTP password that was ever in a `.env`
committed or shared.

---

## What changed in `firestore.rules`

| Area | Before | After |
|---|---|---|
| `users` create | Any authenticated user could create their own doc **with any role**, including `admin` | Role must be `customer`; wallet must start empty; server-owned fields rejected |
| `users` update | Blocked `role` only | Also blocks `walletBalance`, rating counters, `isVerifiedDriver`; going online requires an approved driver |
| `orders` update | Owner or driver could write **any field**, including `price` and `driverId` | Field-level allowlists per party (see below) |
| `orders` create | Any shape | Must start `pending`, unassigned, unpaid |
| `orders/messages` | Any participant could write any sender id | Sender must be themselves; messages immutable |
| `referrals` | **Absent** — the catch-all denied all writes, so referrals silently never worked | Referee may create their own pending record; `referrerId` resolved server-side |
| `sos_alerts` | **Absent** — same silent breakage | Creatable by the alerting user; closable only by an admin |
| `driver_applications` | Applicant could create with any status | Must be `pending`; applicant cannot change `status` |

### Order write permissions, precisely

- **Customer** — `rating`, `ratingComment`, `updatedAt`. Nothing else.
  Cancellation deliberately is *not* here: it goes through the `cancelOrder`
  callable so the refund is actually paid.
- **Assigned driver** (approved only) — `status`, `updatedAt`, `pickedUpAt`,
  `deliveredAt`, `proofOfDeliveryUrl`, `driverLocation`,
  `driverLocationUpdatedAt`.
- **Driver claiming a job** — may set `driverId` to *their own uid* only, only
  on a `pending` order with no driver, and only together with
  `status: accepted`.
- **Admin** — unrestricted.

The fare is not in any client allowlist. `onOrderCreated` recomputes
`totalFare`, `driverEarnings`, and `platformCommission` from zone config and
the pickup/dropoff coordinates and overwrites whatever the client sent.

### Behaviour changes to expect

- **A driver cannot go online until approved.** `isVerifiedDriver` is set by
  `onDriverApplicationReviewed` when an admin approves the application. Any
  driver account that predates this change has no `isVerifiedDriver` field and
  will be unable to go online until backfilled:
  ```js
  // one-off Admin SDK script, run against existing approved drivers
  await db.collection('users').where('role','==','driver')
    .get().then(s => Promise.all(s.docs.map(d =>
      d.ref.update({ isVerifiedDriver: true }))));
  ```
- **Existing users cannot edit their profile if the write includes a blocked
  field.** The app only sends partial updates, so this is fine in practice.

---

## What's new in `storage.rules`

There was no `storage.rules` file at all. Profile photos, driver identity
documents, and delivery proof images were governed by the bucket default.

- `profile_photos/{uid}.jpg` — you write your own; any signed-in user can read
  (a customer needs to see their driver).
- `driver_applications/{uid}/*` — **identity documents.** Readable only by the
  applicant and admins. Never public.
- `proof_of_delivery/{orderId}/*` — writable by signed-in users, readable by
  signed-in users.

Uploads are capped (5 MB profile, 10 MB documents) and must be images.

> **Known limitation:** Storage rules cannot cheaply join against the order
> document, so proof-of-delivery reads are scoped to "any signed-in user with
> the order id" rather than "participants in this order". The path is
> unguessable, but this is weaker than the Firestore equivalent. If that
> matters, serve these through a Cloud Function instead.

---

## New Cloud Functions

| Function | Purpose |
|---|---|
| `paystackWebhook` | HTTPS endpoint. Verifies the `x-paystack-signature` HMAC against the raw body, then credits the wallet server-side. Makes top-ups survive an app crash after payment. |
| `cancelOrder` | Callable. Cancels and refunds per policy — full before pickup, 50% after. Cancellation used to be a status flag with no money movement. |
| `onDriverApplicationReviewed` | Grants `role: driver` + `isVerifiedDriver` on approval; revokes and forces offline on rejection/suspension. The only path to the driver role. |
| `onReferralCreated` | Resolves a referral code to its owner. Clients cannot set `referrerId`. |
| `mayaChat` | Proxies support chat to Claude so the Anthropic key stays server-side. |

`verifyPaystackPayment` and `initializePaystackPayment` were rewritten: they
were v2-style handlers registered on the v1 API and threw on every call.

### Webhook setup

After deploying, register the URL in the Paystack dashboard
(Settings → API Keys & Webhooks):

```
https://<region>-<project-id>.cloudfunctions.net/paystackWebhook
```

`PAYSTACK_WEBHOOK_SECRET` must be the same value Paystack signs with (your
Paystack secret key). Without it every delivery is rejected as unsigned.

---

## Suggested deploy order

Rules first (they only tighten access), then functions:

```bash
# 1. Review the diff
git diff HEAD~1 -- firestore.rules storage.rules

# 2. Dry-run against the emulator if you have test data
firebase emulators:start --only firestore,storage

# 3. Deploy
firebase deploy --only firestore:rules,storage:rules
firebase deploy --only functions
```

Deploying functions **before** rules would leave a window where the driver
approval function exists but the rules still allow self-assigned roles.

---

## Still open

- **Admin role assignment.** There is deliberately no self-service path. Grant
  it with a one-off Admin SDK script or Firebase custom claims.
- **Payout idempotency.** `processDriverPayout` and `weeklyDriverReport` are
  scheduled Pub/Sub functions; a redelivery on the same day would pay twice.
  Tracked separately.
- **Play Store background location.** The manifest now declares
  `ACCESS_BACKGROUND_LOCATION`. Google Play requires a prominent in-app
  disclosure *and* a declaration form describing the driver-tracking use case,
  or the listing is rejected.
