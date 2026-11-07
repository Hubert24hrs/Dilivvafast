# Deployment

Staging (`dilivvafast-staging`) runs the current backend and has passed the
full end-to-end delivery test below. Production (`fast-delivery-d8d5c`) was
deployed from the same commit on 26 October 2026: Firestore rules and
indexes, Storage rules (bucket `fast-delivery-d8d5c.firebasestorage.app`,
us-east1) and all 21 functions on Node.js 22, on the Blaze plan with a
$10/month budget alert. Anthropic key is a placeholder.

**1.3.0 (8 November 2026): no wallet, no Paystack.** Customers pay couriers
directly — cash, or a bank transfer to the courier's account, which the server
copies onto the order when their offer is accepted. The Paystack functions and
the nightly wallet payout were deleted (18 functions remain). Staging runs
1.3.0. **Production still runs 1.2.x** and its billing account is currently
unlinked (Cloud Billing → *Link a billing account* on `fast-delivery-d8d5c`),
which blocks the 1.3.0 deploy:

```bash
GOOGLE_CLOUD_QUOTA_PROJECT=fast-delivery-d8d5c FUNCTIONS_DISCOVERY_TIMEOUT=120 \
  firebase deploy --only firestore:rules,functions --project fast-delivery-d8d5c --non-interactive --force
```

Maps: Google Maps SDK for Android. The key ("Dilivvafast Android Maps", in
`dilivvafast-staging`, restricted to both package names, the upload and debug
SHA-1s and the Maps SDK for Android) goes in `android/local.properties` as
`MAPS_API_KEY`. After the first Play upload, add Play's **app signing** SHA-1
(Play Console → Test and release → App integrity) to that key, or the map is
blank in the Play-installed app.

---

## Current staging status

`dilivvafast-staging` is fully deployed.

| Step | State |
|---|---|
| Project created | ✅ `dilivvafast-staging` |
| Blaze plan | ✅ billed to *Suskii Errands*, $10/month budget alert |
| Firestore `(default)` database (nam5) | ✅ |
| Firestore rules + indexes | ✅ including the negotiation (`bids`) rules |
| Storage bucket (us-east1) + storage rules | ✅ |
| Auth — Email/Password + Google | ✅ |
| Cloud Functions | ✅ all 21 live on **Node.js 22**, callables answer (unauthenticated calls are refused) |
| `ANTHROPIC_API_KEY` | ⚠️ **random placeholder** — Maya falls back to built-in answers until a real value is set (`PAYSTACK_SECRET_KEY` is no longer used) |
| `serviceAccountTokenCreator` for document signing | ❌ not granted — admins cannot open driver documents yet |
| Staging Android app `com.dilivvafast.app.staging` | ✅ registered, debug SHA-1 added; build with `--flavor staging` |

### Node.js runtime

Functions run on `nodejs22` (`firebase.json`). Google decommissioned the
Node.js 20 runtime on 30 October 2026; after that date a project still on 20
cannot deploy functions at all. Production must be deployed with this
`firebase.json`.

### Gotcha seen on the first functions deploy

Right after enabling Eventarc, the six Firestore-triggered functions failed with
"Permission denied while using the Eventarc Service Agent". Google grants that
agent its role asynchronously; re-running the deploy for just those functions
a few minutes later succeeded. If it recurs on a fresh project, wait and retry
before granting anything by hand.

### Replacing the placeholder secrets

```bash
firebase functions:secrets:set PAYSTACK_SECRET_KEY --project dilivvafast-staging
firebase functions:secrets:set ANTHROPIC_API_KEY --project dilivvafast-staging
firebase deploy --only functions --project dilivvafast-staging
```

Functions read the secret version they were deployed with, so the redeploy is
required for a new value to take effect.

## Part 1 — What you need to do (I cannot)

### 1. Upgrade staging to Blaze

**Cloud Functions v2 requires the Blaze (pay-as-you-go) plan.** The deploy
fails at `artifactregistry.googleapis.com` on Spark:

> Your project dilivvafast-staging must be on the Blaze (pay-as-you-go) plan
> to complete this command.

https://console.firebase.google.com/project/dilivvafast-staging/usage/details

This needs a payment method, which is yours to add. Staging costs
approximately nothing at test volumes — set a $10/month budget alert while you
are in there.

### 2. Initialise Storage

https://console.firebase.google.com/project/dilivvafast-staging/storage →
**Get started**. One click; the CLI cannot do this first-time setup.

### 3. Enable Email/Password auth

https://console.firebase.google.com/project/dilivvafast-staging/authentication/providers

### 4. Set the two secrets

```bash
firebase use staging
firebase functions:secrets:set PAYSTACK_SECRET_KEY   # Paystack TEST key (sk_test_...)
firebase functions:secrets:set ANTHROPIC_API_KEY
```

Use the **test** Paystack key for staging, never the live one. I have
deliberately not handled either key.

### 5. Grant the signing role

`getDriverDocumentUrl` signs URLs, which needs the runtime service account to
hold **Service Account Token Creator** on itself. Without it, opening a driver
document throws `Permission iam.serviceAccounts.signBlob is required`.

```bash
gcloud projects add-iam-policy-binding dilivvafast-staging \
  --member="serviceAccount:dilivvafast-staging@appspot.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"
```

### 6. Rotate the leaked Paystack key

Separate from all of the above, and still outstanding: `sk_test_8a005c…` is in
this repository's git history. Removing it from `HEAD` does not remove it from
history. Rotate it in the Paystack dashboard.

### 7. Tell me when 1–5 are done

Then I finish Part 2.

---

## Part 2 — Finish the staging deploy (I can run this)

```bash
firebase use staging
firebase deploy --only storage,functions
```

Rules and indexes are already live, so only storage and functions remain.

Indexes build asynchronously; the deploy returns before they are ready. Watch
Firestore → Indexes until they all read "Enabled".

### Verify the deploy

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/staging-service-account.json
node functions/scripts/smoke-test.js --project dilivvafast-staging
```

Download the service account key from Project settings → Service accounts.
**Do not commit it** — `.gitignore` covers `*.json` under no blanket rule, so
keep it outside the repository entirely.

The smoke test proves the deployed backend actually works: Firestore
reachable, `onCourierCreated` firing, fares recomputed server-side, commission
split correct, promo applied once and only once, and all six callables
deployed and rejecting unauthenticated calls. It cleans up after itself and
refuses to run against production without `--force`.

### Point the app at staging

Replace `android/app/google-services.json` with the staging project's file,
and rebuild. Keep the production one somewhere safe — you will swap it back.

---

## Part 3 — The end-to-end pass

This is the acceptance gate. The emulator suites cannot cover any of it.

On a **physical Android device** against staging:

- [ ] Register; confirm the verification email arrives.
- [ ] The home screen shows a Google map with your position.
- [ ] As a courier, add a bank account (menu → Bank account).
- [ ] Book a delivery. Confirm the fare charged matches the estimate, and that
      it comes from the backend, not the client.
- [ ] Apply a promo code; confirm the discount. Try it again on a second
      order; confirm it is refused.
- [ ] On a second device or account, go online as an approved driver. Confirm
      the new-job notification arrives.
- [ ] Accept the job. The customer's matching screen must move to tracking.
- [ ] Progress pickup → in transit → delivered. Confirm the customer gets a
      push at each step.
- [ ] Confirm the driver's live position appears on the customer map, and that
      no personal data leaks with it.
- [ ] After pickup the customer sees "Pay your courier" with the courier's
      bank details; switch to bank transfer, tap "I've sent". The courier
      gets a push, taps "I've received" and the customer sees "Paid".
- [ ] Rate the delivery; confirm the driver's average updates.
- [ ] Raise an SOS; confirm admins are alerted.
- [ ] Approve a driver application from the admin screen; confirm an
      `admin_audit_log` entry is written.

The automated staging run (`test/e2e/delivery_flow.mjs`, see
"Automated staging end-to-end test" below) already proves the payment rules
(only the customer marks a transfer sent, only the courier marks it paid);
this manual pass is for what only a phone can show — pushes and maps.

---

### Automated staging end-to-end test

`test/e2e/delivery_flow.mjs` drives the deployed staging backend with the
Firebase client SDK, as a real customer and a real driver, so every rule and
every Cloud Function runs as it does for the app. Each run creates throwaway
accounts and ends by deleting them through `deleteMyAccount`.

```bash
cd test/e2e
npm install
GCLOUD_TOKEN=$(gcloud auth print-access-token) node delivery_flow.mjs
```

It covers: sign-up with a referral code → the courier saves a bank account
(a malformed one is refused) → booking at the customer's price, to be paid by
transfer → server pricing → driver counter-offer → customer raises → accept
(the courier's bank details are copied onto the order; a second accept is
refused) → live position → courier arrives → picked up → in transit →
delivered → the customer cannot mark it paid → the customer marks the
transfer sent → the courier confirms it → 5★ rating with compliments → the
referral completes with no wallet credit → support message reaches the inbox
→ a second request auto-accepted at the customer's price → that courier drops
it before pickup (back to pending, no re-offer) → the customer cancels it
with a reason → both accounts delete themselves, keeping the delivery record
and stripping the courier's bank details from it.

Last run: **30/30 passed**, 8 November 2026 (1.3.0), functions on Node.js 22.

---

## Part 4 — Production

Only after Part 3 passes cleanly.

```bash
firebase use prod
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
firebase functions:secrets:set ANTHROPIC_API_KEY
```

Then, in order:

1. Bootstrap the first admin — see SECURITY.md.
2. Restore the production `google-services.json` and rebuild.
3. Watch App Check metrics in **monitoring mode**. Do not enforce until
   essentially all traffic shows as verified; enforcing early locks out every
   client that has not yet shipped with the App Check build.

### Rolling back rules

Rules deploys are versioned. Firebase Console → Firestore → Rules → history,
and publish the previous revision. Do this first if users report sudden
permission errors; it is faster than diagnosing live.

---

## Deploy-time gotchas found during the audit

- **`cloudbilling.googleapis.com` 429 "Quota exceeded … for consumer
  project_number:563584335869".** That project is the Firebase CLI's own,
  shared by every CLI user, and its per-minute quota can stay exhausted for
  a long time. Bill the CLI's calls to your project instead:
  `GOOGLE_CLOUD_QUOTA_PROJECT=fast-delivery-d8d5c firebase deploy …`
  (the Cloud Billing API must be enabled on that project).
- **First 2nd-gen deploy on a project:** the Firestore-triggered functions
  fail with "Permission denied while using the Eventarc Service Agent".
  Wait about five minutes and deploy functions again; seen on both projects.

- **Functions discovery timeout.** The default is 10s and is not always enough
  on a cold machine. The failure reads "Cannot determine backend
  specification", which sounds like a code fault and is not. Export
  `FUNCTIONS_DISCOVERY_TIMEOUT=120`.
- **Emulator port.** Firestore runs on **8085** here, not the default 8080,
  which was occupied. If the rules suite reports every test as
  `cancelledByParent`, something else has taken the port and the rules were
  PUT at whatever was listening.
- **A JVM is required** for the emulators. Android Studio bundles one at
  `C:\Program Files\Android\Android Studio\jbr`.
