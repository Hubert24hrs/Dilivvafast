# Publishing Dilivvafast to Google Play

Everything the Play Console asks for, with the answers worked out from what this
codebase actually does. Written 2026-08-16.

The Data Safety and content-rating answers below are **drafts for you to review
and submit yourself**. They are legal attestations tied to your developer
account — read each one and confirm it matches reality before ticking it. Where
an answer depends on a business decision only you can make, it is marked ⚠️.

---

## Two blockers before you can upload anything

### Blocker 1 — there is no release keystore

`android/key.properties` and the `.jks` do not exist. `android/app/build.gradle.kts`
falls back to **debug signing** when they are absent, so `flutter build appbundle
--release` produces a debug-signed AAB. Play rejects those at upload.

Generate an upload key — you choose and keep the passwords, and they are never
committed:

```bash
keytool -genkey -v -keystore ~/dilivvafast-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dilivvafast
```

Then create `android/key.properties` (already gitignored):

```properties
storePassword=<what you just typed>
keyPassword=<what you just typed>
keyAlias=dilivvafast
storeFile=C:/Users/HP/dilivvafast-upload.jks
```

**Back the `.jks` up somewhere you will still have in five years.** With Play App
Signing a lost upload key is recoverable; without it, losing the key means you
can never update the app under the same listing.

### Blocker 2 — background location has no prominent disclosure

The manifest declares `ACCESS_BACKGROUND_LOCATION`, and drivers are tracked while
the app is backgrounded. Google requires a **prominent in-app disclosure shown
before the permission prompt**, separate from the privacy policy. Right now
`Geolocator.requestPermission()` is called directly
(`lib/core/services/location_tracking_service.dart:162`), and background location
is described only inside the privacy policy screen — which does not satisfy the
policy.

This is the most common rejection reason for delivery apps. You need a dialog,
shown before the OS prompt, that:

- names the app,
- says location is collected **in the background**, even when the app is closed,
- states the purpose in plain words ("so customers can watch your bike move on
  the map while a delivery is active"),
- offers a real choice — a decline path that does not break the app.

The Play declaration also asks for a **video link** showing the disclosure and
the permission flow in the running app.

⚠️ If you would rather not deal with this for v1, the alternative is to drop
`ACCESS_BACKGROUND_LOCATION` and track only while the driver has the app open.
That is a genuine product decision: foreground-only tracking means the
customer's map goes stale the moment the driver switches apps.

---

## 1. Play App Signing

Opt in when you create the app. Google holds the real signing key; you sign
uploads with the upload key from Blocker 1. This is the default and what you
want — it makes a lost upload key recoverable.

## 2. App identity

| Field | Value |
|---|---|
| Package name | `com.dilivvafast.app` — permanent, cannot change after first upload |
| Version | `1.0.1+2` → versionName `1.0.1`, versionCode `2` |
| Target API | 36 ✅ meets the 31 Aug 2026 mandate |
| Category | Maps & Navigation, or Business |

Every subsequent upload needs a **higher versionCode** — bump the `+N` in
`pubspec.yaml`.

## 3. Data Safety form

Derived from `UserModel`, `DriverApplicationModel`, `CourierOrderModel`, and the
Firebase services actually initialised in `main.dart`.

**Encrypted in transit:** Yes — all traffic is Firebase/HTTPS.
**Users can request deletion:** Yes — Settings → Delete Account
(`/settings/delete-account`). Cite this in the form.

| Data type | Collected | Shared | Purpose |
|---|---|---|---|
| Name | Yes | No | Account management, app functionality |
| Email address | Yes | No | Account management |
| Phone number | Yes | No | App functionality — driver and customer contact |
| Address | Yes | No | App functionality — pickup and dropoff |
| User IDs | Yes | No | Account management (`uid`, `referralCode`) |
| Photos | Yes | No | App functionality — profile, ID documents, proof of delivery |
| Precise location | Yes | ⚠️ see below | App functionality — dispatch and live tracking |
| Purchase history | Yes | No | App functionality — order and wallet history |
| User payment info | Yes | Yes → Paystack | App functionality — payouts (`accountNumber`, `bankName`) |
| Other financial info | Yes | No | App functionality — wallet balance |
| In-app messages | Yes | No | App functionality — order chat |
| Crash logs | Yes | No | Analytics — Crashlytics |
| Diagnostics | Yes | No | Analytics — Performance Monitoring |
| Other app performance data | Yes | No | Analytics — Firebase Analytics |
| Device or other IDs | Yes | No | App functionality — FCM push token |

⚠️ **Is precise location "shared"?** A customer sees their assigned driver's live
position and vice versa. Google counts user-to-user visibility inside your own
app as *collection*, not *sharing* — sharing means transfer to a third party.
Declare it collected, not shared, unless you also send location somewhere
external.

⚠️ **BVN.** `UserModel` carries a `bvn` field. A Nigerian Bank Verification
Number is sensitive identity data. Confirm whether it is actually populated — if
it is, declare it under Personal info → Other info and make sure you have a
lawful basis and NDPR-compliant handling. If it is a leftover field nothing ever
writes, **delete it from the model** rather than declaring it.

Mark location, financial info, and photos **required, not optional**, unless the
app genuinely works without them.

## 4. App access — test credentials (do not skip)

Everything here is behind a login and the three roles are gated. A reviewer who
cannot get in will reject the submission. Under **App access → All functionality
is restricted**, provide email/password logins for:

1. **A customer account** — with the wallet already funded, so checkout can be
   exercised without a real card.
2. **A pre-approved driver account** — `users.isVerifiedDriver` must already be
   `true`. A reviewer cannot approve themselves, and an unapproved driver cannot
   go online, so without this the entire driver half of the app looks broken.
3. **An admin account** — only if you want the dashboard reviewed. ⚠️ Consider
   whether you want a live admin login sitting in a review queue at all; you may
   prefer to omit it and describe admin as internal-only.

Add a note explaining the roles and that driver approval is server-side.

## 5. Declarations

| Declaration | Answer |
|---|---|
| Background location | Yes — needs the justification and video from Blocker 2 |
| Foreground service (location) | Yes — driver tracking during an active delivery |
| Financial features | ⚠️ Yes — the app holds a wallet balance and processes payments; Nigeria-based financial declarations may require supporting documents |
| Ads | No — no ad SDK in `pubspec.yaml` |
| News app | No |
| COVID-19 / contact tracing | No |
| Government app | No |
| Target audience | 18+ — avoids Families policy, appropriate for a payments app |
| Data deletion | In-app, plus a web URL if you have one |

## 6. Content rating (IARC questionnaire)

Category: **Utility / Productivity / Communication**. Expected outcome Everyone
or PEGI 3. Answer honestly:

- Violence, sexual content, profanity, gambling, drugs → **No** to all
- **Users can interact / communicate** → **Yes**, order chat exists
- **Users can share location** → **Yes**, drivers and customers see each other
- **Digital purchases** → **Yes**, wallet top-up

Those last three are what stop this being a trivial rating. Declaring them
wrongly is a suspension risk and admitting them costs nothing.

## 7. Store listing assets

| Asset | Requirement |
|---|---|
| App icon | 512×512 PNG, 32-bit, no alpha |
| Feature graphic | 1024×500 PNG or JPG, no alpha |
| Phone screenshots | 2–8, min 320 px, max 3840 px, 16:9 or 9:16 |
| 7" and 10" tablet | Only if you declare tablet support |
| Short description | ≤ 80 characters |
| Full description | ≤ 4000 characters |

Screenshots must show the real app — take them from the debug build across the
three journeys in `TESTING.md`.

⚠️ Avoid "fastest", "cheapest", or "#1" in the listing without evidence;
unsubstantiated superlatives get listings pulled.

## 8. Privacy policy

Required — a payments app collecting location cannot ship without one at a public
URL. `docs/privacy.html` and `docs/terms.html` exist in the repo but are not
hosted. Publish them (GitHub Pages works) and put the URL in both the Play
listing and the app.

Confirm the policy actually describes background location, the Paystack
relationship, and how deletion works. A policy that contradicts your Data Safety
form is itself a violation.

## 9. Build and upload

Once Blocker 1 is resolved:

```bash
flutter build appbundle --release --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_public_token --dart-define=APP_ENV=production
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Verify it is signed with your key rather than the debug key:

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

The owner must match what you entered at keystore creation. If it says
`CN=Android Debug`, `key.properties` was not picked up.

**Roll out through internal testing first**, then closed, then production. An
internal-testing release reaches your own test accounts in minutes without full
review — the cheapest way to catch a signing or crash-on-launch problem.

## 10. Before you submit

- [ ] Release keystore created and backed up
- [ ] Background location disclosure implemented, or the permission dropped
- [ ] Paystack key rotated — the old one is in public git history, see `HANDOFF.md`
- [ ] Firestore rules, storage rules, and Cloud Functions **deployed**
- [ ] `isVerifiedDriver` backfilled, or every existing driver is locked out
- [ ] Paystack webhook registered against the deployed function
- [ ] SHA-1 and SHA-256 of the upload key added to Firebase
- [ ] Privacy policy hosted at a public URL
- [ ] Test accounts created and working, driver pre-approved
- [ ] `flutter analyze` clean, `flutter test` green, `rules_test` green
- [ ] Smoke-tested on a real device per `TESTING.md`

The Firebase SHA fingerprint step is easy to forget and breaks Google Sign-In
only in the *released* build, where it is hardest to debug.
