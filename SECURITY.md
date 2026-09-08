# Security

This document describes what the Dilivvafast codebase **actually does today**,
not what it aspires to. Where something is unfinished or depends on manual
console configuration, it says so explicitly. Keep it that way — a security
document that describes intentions rather than implementation is worse than
none, because it stops people looking.

Last reviewed: 2026-09-07.

---

## Reporting a vulnerability

Email **security@dilivvafast.ng**. Please do not open a public GitHub issue.

---

## Trust model

The mobile app is **untrusted**. It runs on hardware the user controls, and
anyone can unpack the APK, read every string in it, and issue arbitrary
Firestore and Cloud Functions calls with a valid auth token. Therefore:

- No security decision may depend on client-side UI state or on a value the
  client supplies about itself.
- Money is moved only by Cloud Functions, never by client writes.
- Prices, earnings and commissions are computed server-side.
- Role and entitlement are read from custom claims / server-controlled fields,
  never from something the client can write.

Cloud Functions run with Admin SDK privileges and **bypass firestore.rules
entirely**. Every callable therefore re-establishes identity and authorisation
for itself.

---

## Authentication and roles

Firebase Authentication provides identity. Authorisation comes from two places:

1. **Custom claims** (`admin: true`, `role: "..."`) — set only by the
   `setUserRole` callable, which itself requires an existing admin. No client
   can write a claim.
2. **The `role` / `driverStatus` / `investorStatus` fields** on the user
   document — legacy, still honoured so pre-existing accounts keep working,
   and writable only by an admin (firestore.rules freezes `role` against
   self-service updates).

A user may move their own `driverStatus` / `investorStatus` to `pending` to
request access. Approval is an admin action. A status already `approved` or
`suspended` is frozen to the client, so access cannot be re-requested to escape
a suspension.

### Bootstrapping the first admin

`setUserRole` requires an admin, so the first one cannot be created from the
app. This is deliberate. Do it once, from a trusted machine:

```bash
# Requires service-account credentials; never run this from CI or a laptop
# that is not yours.
node -e "
const admin = require('firebase-admin');
admin.initializeApp({credential: admin.credential.applicationDefault()});
admin.auth().setCustomUserClaims('<UID>', {admin: true, role: 'admin'})
  .then(() => console.log('done'));
"
```

Then set `role: "admin"` on that user's Firestore document so the legacy check
agrees. Claims only refresh when the client's ID token is renewed — sign out
and back in, or force a token refresh.

Registration always creates a `customer`, regardless of the `role` argument
passed to `AuthRepository.register` — elevated roles come only from
`setUserRole`. `firestore.rules` rejects a create with any other role, so this
is defence in depth.

### Email verification — partially implemented

A confirmation email **is** now sent on registration, and the state is
observable via `emailVerifiedProvider` / `refreshEmailVerified()`. This is
Firebase Auth's `emailVerified`, which the client cannot forge — distinct from
the `isVerified` field on the user document, which is an admin-controlled
identity flag that the rules freeze against client writes.

**It is not yet enforced.** Nothing currently refuses service to an unverified
account. Gating specific flows (wallet top-up, first order) is the follow-up;
it was left out here because switching it on retroactively would lock out
every existing account until they re-confirm.

### Not yet implemented

- **Re-authentication is not required** before high-risk account operations
  (changing email, deleting the account).
- Biometric unlock (`biometric_setup_screen.dart`) is a **local convenience
  only**. It gates access to the UI on this device and confers no server-side
  authority whatsoever. Nothing in the backend trusts it.

---

## Secret management

**No secret-tier credential is present in the client.**

| Credential | Where it lives | Reaches the app? |
|---|---|---|
| Mapbox public token | `.env` → `AppConfig` | Yes (public by design) |
| Paystack **public** key | `.env` → `AppConfig` | Yes (public by design) |
| Paystack **secret** key | Cloud Secret Manager | No |
| Anthropic API key | Cloud Secret Manager | No |

Everything in `.env` is bundled into the shipped binary as an asset and can be
read by anyone who unzips it. Only publishable values belong there;
`.env.example` documents this.

Set server secrets with:

```bash
firebase functions:secrets:set PAYSTACK_SECRET_KEY
firebase functions:secrets:set ANTHROPIC_API_KEY
```

### Fixed during the 2026-09 audit

- A Paystack **secret** key (`sk_test_8a005c…`) was hardcoded in
  `lib/core/constants/app_constants.dart` and shipped in every build. Removed.
- The Anthropic API key was read from `.env` and sent directly from the handset
  in an `x-api-key` header. Requests now go through the `askMaya` Cloud
  Function; the key never leaves the backend.
- `AppConfig` exposed getters for the Paystack secret key and SMTP password.
  Removed.

### ⚠ Outstanding — key rotation

The leaked Paystack test key is in git history. Removing it from `HEAD` does
not remove it from the repository. **Rotate it in the Paystack dashboard.** If
a live key was ever committed, rotate that too and audit the account for
unrecognised transactions. This cannot be done from source and has not been
done.

---

## Payments

Payment success is established **only** by the backend verifying the
transaction directly with Paystack. The client is never believed.

Flow:

1. `initializePaystackPayment` (callable) validates the amount and email,
   mints a server-side reference, opens a Paystack transaction and records the
   intent. The client cannot choose the reference.
2. The customer completes payment in the browser.
3. Credit happens through either path, whichever arrives first:
   - `paystackWebhook` — HMAC-SHA512 signature verified against the Paystack
     secret; a forged POST cannot mint credit.
   - `verifyPaystackPayment` (callable) — for immediate confirmation while the
     customer is still in the app.

### Idempotency

Both paths share `creditVerifiedPayment`, which creates
`processed_payments/{reference}` **inside the same transaction** that
increments the wallet. A replayed reference finds the marker and returns
without crediting again.

### Ownership

The wallet credited is the one named in Paystack's own `metadata.userId`, not
one supplied by the caller. A caller presenting someone else's reference is
rejected with `permission-denied`.

### Fixed during the audit

- `verifyPaystackPayment` had **no replay protection** — the same reference
  could be verified repeatedly for unlimited wallet credit — and **no ownership
  check**, so one user could credit their wallet from another user's payment.
- Both payment callables were **completely non-functional**: they used the v2
  callable signature (`request.data`) while importing the v1 namespace, so
  `request.data` was always undefined and every call threw `unauthenticated`.
  The functions are now on the v2 API throughout.
- The client's `initializePayment` never called the backend at all; it returned
  its own reference string, which `canLaunchUrl` then rejected. Wallet top-up
  had never worked.
- Two mock services (`PaymentService`, `PaystackService`) returned
  unconditional success — one displaying a fake "Payment Successful" dialog.
  Both deleted.

### Money representation — known weakness

Balances are stored as floating-point Naira, not integer kobo. Every server
write is rounded to kobo precision (`toKoboPrecision`) to stop drift
accumulating across repeated increments, but the underlying representation is
still lossy. Migrating to integer minor units is recommended and would require
a data migration; it has **not** been done.

---

## Driver payouts

`processDriverPayout` runs daily at 01:00 Africa/Lagos.

Idempotency key: `payouts/{driverId}_{YYYY-MM-DD}`, created with `tx.create`
inside a transaction that also increments the wallet and writes the ledger
entry. `create` fails if the document exists, so:

- Pub/Sub at-least-once redelivery cannot double-pay.
- A manual re-run for the same date is a no-op.
- A concurrent second run aborts on the transaction.

Previously the function used an unguarded batch write, so any redelivery paid
every driver a second time.

`payouts/` is client-read-only (a driver sees their own) and client-write-never.

---

## Firestore rules

`firestore.rules` is deny-by-default: an explicit `match /{document=**} { allow
read, write: if false; }` terminates the file, and every collection is
enumerated above it.

Enforced invariants:

- **Ownership** on every user-scoped collection.
- **Immutability** of financial and audit fields (`totalFare`, `baseFare`,
  `driverEarnings`, `platformCommission`, `paymentStatus`, `userId`,
  `createdAt`, `trackingCode`, `paystackReference`).
- **Creation invariants** — a new user starts with a zero wallet, zero rating
  and no entitlements; a new order starts unassigned, unpaid and unearned; a
  new investor profile starts with zero totals.
- **The delivery state machine**, mirroring
  `CourierOrderModel.canTransitionTo`. A customer may cancel only from
  `pending` / `accepted`, and may never mark a delivery `delivered`. A driver
  may claim only an unassigned `pending` job, and may only progress along legal
  transitions.
- **Role manipulation is impossible** from the client.

### Holes closed during the audit

| Was | Impact |
|---|---|
| `users` create constrained `role` but not `walletBalance` | Register with any opening balance |
| `investors` create did not constrain totals | Fabricate investment history |
| `notifications` had `allow list: if isAuthenticated()` | Read every user's notifications |
| `orders/{id}` matched `support_.*` for any caller | Read and write every user's support thread |
| `users` second match block exposed online drivers | Every driver's email, phone, wallet and FCM token readable by any customer |
| `couriers` update allowed arbitrary status jumps | Mark a delivery complete without a driver |
| `bikes` update was unconstrained on fields | Alter bike price while claiming it |
| `referrals` was readable by everyone | Enumerate the referral graph |

### Driver location privacy

Driver position used to be written onto the `users` document, which forced a
rule exposing the entire driver record to customers. Presence now lives in
`driver_locations/{driverId}`, containing only `driverId`, `isOnline`,
`isAvailable`, `location`, `heading`, `speed`, `vehicleType`, timestamps. The
rules reject any write to it carrying `email`, `phone`, `walletBalance`,
`fcmToken` or `role`.

Remaining weakness: presence is readable by **any** authenticated user, not
only by a customer with an active delivery assigned to that driver. Narrowing
this needs a per-order lookup that Firestore rules cannot express efficiently
for `list` queries; the pragmatic mitigation is that the projection carries no
identifying data.

---

## Promotions

A promo code is validated and redeemed **server-side**, inside
`onCourierCreated`:

- The code the client writes on the order is honoured; the **discount amount it
  writes is ignored** and recomputed from the promo document.
- Redemption is recorded at `promo_redemptions/{promoId}_{uid}`, created with
  `tx.create` in the same transaction that increments `usedCount`. Two orders
  racing the same code cannot both claim it, and a code is single-use per
  customer.
- `isActive`, `expiresAt`, `minOrderAmount` and `maxUses` are all checked
  server-side.
- The discount is capped so it can never take a fare below `MINIMUM_FARE`, and
  never below zero.

`promo_redemptions` is client-read-only (your own) and client-write-never.

The client-side check in `promotions_screen` is a convenience that gives the
customer a clear message; it is not a commitment, and nothing trusts it.

## Cloud Storage

`storage.rules` — **the project previously shipped none at all**, for a bucket
holding driver licences and ID documents.

- `profile_photos/{userId}` — readable by any signed-in user, writable by the
  owner.
- `drivers/{userId}/**` and `driver_applications/{userId}/**` — readable only
  by the owner and admins. Never by customers, never listable.
- `proof_of_delivery/{orderId}/**` — readable by that order's customer, its
  driver, and admins; writable by the assigned driver.
- Uploads are constrained to `image/(jpeg|jpg|png|webp)` and 8 MB.

### ⚠ Known weakness — download URLs

`getDownloadURL()` mints a long-lived bearer token that **bypasses these rules**
for anyone holding the link. Driver document URLs are currently stored on the
user document, so a leak of that document leaks the documents.

The correct fix is to store the storage *path* and serve admins short-lived
signed URLs from the Admin SDK. This has **not** been implemented.

---

## Cloud Functions input validation

Every callable:

- Requires authentication (`requireAuth`), and admin endpoints additionally
  require a verified admin (`requireAdmin`).
- Validates and coerces every input; unexpected values are rejected rather than
  passed through.
- Returns user-safe messages. Provider and stack detail goes to `logger`, never
  to the client.

### Rate limiting

`enforceRateLimit` is a Firestore-transaction-backed fixed-window limiter
applied to endpoints that cost money to serve:

| Endpoint | Limit |
|---|---|
| `initializePaystackPayment` | 10 / 10 min |
| `verifyPaystackPayment` | 20 / 10 min |
| `askMaya` | 30 / 10 min |
| `lookupReferralCode` | 20 / 10 min |

---

## App Check

`FirebaseAppCheck.activate()` runs in `main()` immediately after
`Firebase.initializeApp()`. Debug builds use the debug providers; release
builds attest with Play Integrity (Android) and DeviceCheck (Apple).

Activation failure is deliberately **non-fatal** — it is logged and the app
continues. Until enforcement is switched on, an unattested call is served
anyway, so aborting startup because attestation was unreachable would be a
strictly worse outcome.

**Enforcement is off.** Attaching tokens does nothing on its own. Turn it on
per-service in the Firebase console, and only after the App Check metrics show
real traffic being attested — enabling it cold locks out every client that has
not yet shipped with this build. See PLAY_STORE.md.

## Admin actions and audit trail

`admin_audit_log` is append-only from the Admin SDK, readable by admins,
writable by no client. `setUserRole` and `reviewDriverApplication` both write
to it.

Not every privileged path is audited yet — admin edits made directly through
Firestore client writes (the admin screens) are **not** logged. Routing those
through callables is outstanding.

---

## Location and privacy

The app requests **foreground location only**
(`ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`).

`ACCESS_BACKGROUND_LOCATION` is **not declared and not requested**. There is
therefore no Google Play prominent-disclosure obligation for background
location, and no disclosure screen exists because none is required. If
background tracking is ever added, see PLAY_STORE.md before writing any code.

Position writes are throttled to a 20 m distance filter **and** a 10-second
minimum interval, and obviously invalid fixes (out-of-range, null-island) are
discarded. Tracking stops on `stopTracking`, which also clears the last known
position so a stale pin does not linger on the customer map.

---

## Verification status

| Check | Status |
|---|---|
| `flutter analyze` | ✅ clean |
| `flutter test` | ✅ 111 passing |
| `tsc --noEmit` (functions) | ✅ clean |
| Firestore rules tests | ⚠️ **written but never executed** — the emulator needs a JVM and none was installed on the audit machine. Run `npm test` in `test/firestore-rules/` before deploying rules. |
| Release build | ⚠️ not produced during the audit |

---

## Known outstanding risks

1. **Rotate the leaked Paystack key** — in git history, cannot be fixed from
   source.
2. **Firestore rules tests have never been run.** They encode the intended
   behaviour but are unverified.
3. **Storage download URLs bypass storage rules** (above).
4. **Money is floating-point**, not integer minor units.
5. **Email verification is sent but not enforced** (see above).
6. **App Check is integrated but not enforced** (see below).
7. **Admin screen writes are not audited.** The admin UI writes to Firestore
   directly; only `setUserRole` and `reviewDriverApplication` reach
   `admin_audit_log`.
8. **Re-authentication is not required** for high-risk account operations.
