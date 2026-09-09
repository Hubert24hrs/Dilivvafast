# Deployment

Nothing in this repository has ever been deployed. `firebase.json` previously
declared only Firestore rules, so the Cloud Functions and Storage rules have
never reached any project.

Staging first. Production only once staging has passed a real end-to-end
delivery.

---

## Part 1 — What you need to do (I cannot)

### 1. Create the staging project

Firebase Console → Add project → name it **`dilivvafast-staging`**.

If you pick a different id, update the `staging` alias in `.firebaserc`.

### 2. Enable billing on it

**Cloud Functions v2 requires the Blaze (pay-as-you-go) plan.** A Spark-plan
project will fail the functions deploy with a quota error.

Staging costs approximately nothing at test volumes, but the card has to be on
file. Set a budget alert (say $10/month) while you are in there.

### 3. Enable the services staging needs

In the staging project: **Authentication** (Email/Password), **Firestore**
(production mode — the rules in this repo are the access control), **Storage**.

### 4. Set the two secrets

```bash
firebase use staging
firebase functions:secrets:set PAYSTACK_SECRET_KEY   # your Paystack TEST key (sk_test_...)
firebase functions:secrets:set ANTHROPIC_API_KEY
```

Use the **test** Paystack key for staging. Never the live one.

### 5. Rotate the leaked Paystack key

Separate from all of the above, and still outstanding: the key
`sk_test_8a005c…` is in this repository's git history. Removing it from `HEAD`
does not remove it from history. Rotate it in the Paystack dashboard.

### 6. Tell me when 1–4 are done

Then I run Part 2.

---

## Part 2 — Deploy to staging (I can run this)

```bash
firebase use staging
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

Indexes build asynchronously; the deploy returns before they are ready.
Watch Firestore → Indexes until they all read "Enabled".

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
- [ ] Fund the wallet. Paystack checkout opens in the browser, payment
      completes with a test card, wallet is credited **exactly once**.
- [ ] Tap "I have paid" a second time — the balance must not move again
      (idempotency; this is the single most important check here).
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
- [ ] Rate the delivery; confirm the driver's average updates.
- [ ] Raise an SOS; confirm admins are alerted.
- [ ] Approve a driver application from the admin screen; confirm an
      `admin_audit_log` entry is written.

Then wait for the 01:00 Africa/Lagos payout, or invoke `processDriverPayout`
manually from the console, and confirm:

- [ ] The driver's wallet is credited once.
- [ ] A `payouts/{driverId}_{YYYY-MM-DD}` document exists.
- [ ] Running it a second time credits **nothing further**.

Payout idempotency is currently unproven by any automated test — the emulator
skips scheduled functions. This manual check is the only evidence there is.

---

## Part 4 — Production

Only after Part 3 passes cleanly.

```bash
firebase use prod
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
firebase functions:secrets:set PAYSTACK_SECRET_KEY   # LIVE key this time
firebase functions:secrets:set ANTHROPIC_API_KEY
```

Then, in order:

1. Register the webhook in the Paystack dashboard:
   `https://us-central1-fast-delivery-d8d5c.cloudfunctions.net/paystackWebhook`
2. Bootstrap the first admin — see SECURITY.md.
3. Restore the production `google-services.json` and rebuild.
4. Watch App Check metrics in **monitoring mode**. Do not enforce until
   essentially all traffic shows as verified; enforcing early locks out every
   client that has not yet shipped with the App Check build.

### Rolling back rules

Rules deploys are versioned. Firebase Console → Firestore → Rules → history,
and publish the previous revision. Do this first if users report sudden
permission errors; it is faster than diagnosing live.

---

## Deploy-time gotchas found during the audit

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
