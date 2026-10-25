# Google Play release checklist

Everything needed to get Dilivvafast from this repository onto Google Play,
in order. Items marked **(you)** need your accounts, passwords or money and
cannot be done from source. Everything else is already done in the code.

Last reviewed: 25 October 2026, against version `1.1.0+3`.

---

## 0. Where things stand

Done and verified in code:

- Android target/compile SDK 36 (Play's requirement for new apps from
  31 August 2026), R8 shrinking on, release builds refuse to fall back to the
  debug key when built with `-PrequireReleaseSigning=true`.
- Two flavors: `production` (`com.dilivvafast.app`) and `staging`
  (`com.dilivvafast.app.staging`). Only `production` goes to Play.
- In-app account deletion (Settings → Delete Account), run server-side by the
  `deleteMyAccount` Cloud Function, plus a public deletion page
  (`docs/delete-account.html`). Both are Play requirements.
- Privacy policy in the app and at `docs/privacy.html`, matching the Data
  safety answers below.
- No advertising ID: the `AD_ID` permission Firebase Analytics adds is
  stripped in `AndroidManifest.xml`.
- No foreground service type and no background location. The unused
  `flutter_background_service` dependency, which injected a location
  foreground service, has been removed, and geolocator's service has its
  `foregroundServiceType` stripped in `AndroidManifest.xml` (the plugin binds
  to that service for every position stream, so the service itself stays,
  but it is never started in the foreground).
- The whole delivery flow is tested end to end against the staging backend
  (`test/e2e/delivery_flow.mjs`, see DEPLOYMENT.md).

---

## 1. Publish the legal pages (you, 2 minutes)

Play needs a working privacy-policy URL and an account-deletion URL. The
pages are in `docs/`, but GitHub Pages is **not enabled**, so the links in the
app return 404 today.

After the `security/audit-hardening` branch is merged into `main`:

GitHub → Hubert24hrs/Dilivvafast → Settings → Pages → Source: *Deploy from a
branch* → Branch `main`, folder `/docs` → Save. Or:

```bash
gh api -X POST repos/Hubert24hrs/Dilivvafast/pages -f "source[branch]=main" -f "source[path]=/docs"
```

Then check these open in a browser:

- https://hubert24hrs.github.io/Dilivvafast/privacy.html
- https://hubert24hrs.github.io/Dilivvafast/delete-account.html
- https://hubert24hrs.github.io/Dilivvafast/terms.html

If you later host them on your own domain, change `legalPagesBaseUrl` in
`lib/core/constants/app_constants.dart`.

**Contact address.** The app and the pages use `dilivvafastsupport@gmail.com` for
support, privacy and legal (set in `AppConstants` and the three HTML pages).
Play shows it publicly on the store listing; check that inbox regularly.

---

## 2. Create the upload key (you, once — keep it forever)

Run this from the repository root. It asks for passwords — choose strong
ones and store them in a password manager:

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

(`keytool` is in `C:\Program Files\Android\Android Studio\jbr\bin`.)

Then create `android/key.properties` (already git-ignored):

```properties
storePassword=<the store password you chose>
keyPassword=<the key password you chose>
keyAlias=upload
storeFile=upload-keystore.jks
```

Back up `upload-keystore.jks` and both passwords somewhere off this computer.
With Play App Signing (step 5) a lost upload key can be reset, but it takes
days and a support request.

---

## 3. Production backend (you approve; commands below)

Production (`fast-delivery-d8d5c`) is still on the old backend. Staging has
everything. Production needs the **Blaze** plan before functions can deploy.

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage,functions --project fast-delivery-d8d5c
firebase functions:secrets:set PAYSTACK_SECRET_KEY --project fast-delivery-d8d5c   # LIVE key
firebase functions:secrets:set ANTHROPIC_API_KEY --project fast-delivery-d8d5c
```

Then:

1. Paystack dashboard → Settings → API Keys & Webhooks → webhook URL
   `https://us-central1-fast-delivery-d8d5c.cloudfunctions.net/paystackWebhook`.
2. Make the first admin (see SECURITY.md, "Bootstrapping the first admin").
3. **Rotate the Paystack key that was once committed to git history**, if not
   done yet.

---

## 4. Build the release bundle

Bump the version for every upload (`version:` in `pubspec.yaml`; the number
after `+` must always increase). Then:

```bash
flutter build appbundle --release --flavor production -PrequireReleaseSigning=true
```

The bundle is written to
`build/app/outputs/bundle/productionRelease/app-production-release.aab`.

Test the same build on a real phone first:

```bash
flutter build apk --release --flavor production -PrequireReleaseSigning=true
```

---

## 5. Play Console setup (you)

1. Create the app: name *Dilivvafast*, default language English (UK or US),
   App, Free.
2. **Play App Signing**: accept the default (Google manages the app signing
   key). Upload the `.aab` from step 4.
3. **Register both SHA-1 fingerprints with Firebase**, or Google sign-in will
   fail on Play-installed copies. In Play Console → Test and release → App
   integrity → App signing, copy the SHA-1 of the *app signing key*. Get the
   upload key's with:

   ```bash
   keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
   ```

   Firebase console → Project settings → `com.dilivvafast.app` → Add
   fingerprint, for each. Download the new `google-services.json` into
   `android/app/` and rebuild.
4. **Testing track.** New *personal* developer accounts must run a closed test
   with at least 12 testers opted in for 14 days in a row before production
   access is granted. Organisation accounts are exempt. Create the closed
   track, add testers by email or a Google Group, and share the opt-in link.

---

## 6. App content forms (you; answers below)

### Privacy policy
`https://hubert24hrs.github.io/Dilivvafast/privacy.html`

### App access
Sign-in is required. Give reviewers a working customer account on
**production** (create one in the app, top up a little wallet credit) and
write: "Sign in with the email and password below. To see the courier side,
open the menu and tap Driver mode." Do not reuse a personal account.

### Ads
No, the app contains no ads.

### Advertising ID
No. (The permission is removed in the manifest.)

### Content rating
Questionnaire category: *Utility, Productivity, Communication or Other*.
Answer "no" to violence, sexuality, drugs, gambling. It has user-to-user
chat between customer and courier (answer yes to "users can interact"), and
shares location with the other party during a delivery.

### Target audience
18 and over. Couriers must be 18+, and the app is not designed for children.

### Data safety

Data is **encrypted in transit**: yes. Users can **request deletion**: yes,
in the app and at
`https://hubert24hrs.github.io/Dilivvafast/delete-account.html`.

"Shared" in Play's sense means passed to a third party for its own use.
Service providers acting for us (Firebase, Paystack, Mapbox, Anthropic) and
data the user knowingly sends to the other side of a delivery do not count,
so nothing is declared as shared.

| Play category | Data type | Collected | Optional? | Purpose |
|---|---|---|---|---|
| Location | Precise location | Yes | Required | App functionality |
| Personal info | Name | Yes | Required | App functionality, Account management |
| Personal info | Email address | Yes | Required | Account management |
| Personal info | Phone number | Yes | Required | App functionality |
| Personal info | Address (pickup / drop-off) | Yes | Required | App functionality |
| Personal info | User IDs | Yes | Required | Account management |
| Personal info | Other info (driver's licence, government ID) | Yes | Optional (couriers only) | Fraud prevention, security |
| Financial info | Purchase history (fares, wallet) | Yes | Required | App functionality |
| Financial info | Other financial info (courier bank details) | Yes | Optional (couriers only) | App functionality |
| Financial info | User payment info (cards) | **No** — Paystack only | — | — |
| Messages | Other in-app messages (chat, support, Maya) | Yes | Optional | App functionality, Customer support |
| Photos and videos | Photos (profile, documents, vehicle) | Yes | Optional | App functionality |
| App activity | App interactions | Yes | Required | Analytics |
| App activity | Other user-generated content (ratings) | Yes | Optional | App functionality |
| App info and performance | Crash logs, Diagnostics | Yes | Required | Analytics |
| Device or other IDs | Device or other IDs (push token) | Yes | Required | App functionality |

### Financial features
The app holds a wallet balance used only to pay for deliveries on Dilivvafast,
and pays couriers their earnings. It is not a bank, loan, money-transfer or
crypto app. Answer the declaration accordingly.

### Government / health / news
Not applicable.

---

## 7. Store listing (you)

- App name: *Dilivvafast* (30 characters max).
- Short description (80 max), e.g. "Send packages across Lagos — name your
  price, pick your courier."
- Full description (4000 max).
- App icon 512×512 PNG (the launcher icon source is `assets/images/logo.png`).
- Feature graphic 1024×500.
- At least 2 phone screenshots (16:9 or 9:16, 320–3840 px). Take them from
  the production build on a real phone: home map, offer screen, live
  tracking, driver requests.
- Category: *Maps & Navigation* or *Business*. Contact email: the support
  address from step 1.

---

## Location permissions — reviewer notes

The app declares **foreground location only** (`ACCESS_FINE_LOCATION`,
`ACCESS_COARSE_LOCATION`). `ACCESS_BACKGROUND_LOCATION` is not declared,
and no foreground service type or `FOREGROUND_SERVICE` permission is
declared, so the background-location declaration and the foreground-service
declaration **do not apply** — do not fill them in. If the Console still asks
about foreground services, answer that the app uses none.
Location is requested in context, the first time it is needed.

### If background tracking is ever added

Do all of this *before* writing the code:

1. Add `ACCESS_BACKGROUND_LOCATION` and a `foregroundServiceType="location"`
   service with `FOREGROUND_SERVICE_LOCATION`.
2. Build a prominent-disclosure screen that appears **before** the permission
   request, names the app, says data is collected in the background, and
   states why. The user must be able to decline.
3. Complete the Play Console background-location and foreground-service
   declarations, each with a demo video.
4. Update the Data safety form, the privacy policy and SECURITY.md.

---

## App Check

The client side is **done**: `firebase_app_check` is a dependency and
`FirebaseAppCheck.activate()` runs in `main()` (Play Integrity in release,
debug providers in debug builds).

What remains is console-side, in this order:

1. Play Console → enable Play Integrity for the app.
2. Firebase Console → App Check → register the Android app with Play Integrity.
3. For local development, run the app once and copy the debug token it logs
   into Firebase Console → App Check → Manage debug tokens.
4. Leave enforcement **off** and watch the metrics until essentially all
   traffic shows as verified. Enforcing before your users have the build that
   attests will lock every one of them out.
5. Only then enable enforcement, one service at a time (Firestore, Functions,
   Storage), watching for a drop in legitimate traffic after each.
