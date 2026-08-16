# Handoff — current state

Last updated: 2026-08-16.

## Where things stand

The audit-and-fix pass is complete: all nine known findings (SEC-1 … SEC-9)
were re-verified against HEAD, fixed, and the work is committed and pushed.

| Check | Status |
|---|---|
| `flutter analyze` | clean |
| `flutter test` | 119 / 119 |
| `rules_test` (emulators) | 88 / 88 |
| Debug APK | built, secrets verified absent |

Nothing is deployed. Rules, storage rules, and Cloud Functions are all written
and tested but still sitting in the repo awaiting review — that is deliberate,
see [SECURITY.md](SECURITY.md).

## The APK

```
build/app/outputs/flutter-apk/app-debug.apk    (~235 MB, debug)
```

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

235 MB is normal for a debug build: unstripped symbols, all ABIs, Mapbox and
Firebase native libraries. A release build is far smaller.

The build was checked for the leaked keys after the fact — no `.env` entry, and
no match for `sk_test_`, `sk_live_`, `sk-ant-`, or the specific exposed
Paystack key. The check used a positive control (the Mapbox public token, which
*should* be present) to prove the scan could actually see strings in the binary
before trusting the zero results.

## What to pick up next

### 1. Rotate the exposed Paystack key — do this first

`sk_test_8a005c6bea1bf16bc47ffae780c8e76a8a5ce347` was committed in
`lib/core/constants/app_constants.dart` and is in public git history. It has
been removed from the code, but **removal is not revocation** — the key stays
live until it is rotated in the Paystack dashboard. Independent of everything
else here.

### 2. Deploy, in this order

```bash
firebase functions:secrets:set PAYSTACK_SECRET_KEY
firebase functions:secrets:set PAYSTACK_WEBHOOK_SECRET
firebase functions:secrets:set ANTHROPIC_API_KEY

cd rules_test && npm test && cd ..          # gate: prove the rules still hold

firebase deploy --only firestore:rules,storage:rules
firebase deploy --only functions
```

Rules before functions. The reverse order leaves a window where the driver
approval function exists while the rules still permit self-assigned roles.

### 3. Register the Paystack webhook

Point it at the deployed `paystackWebhook` URL. Without it, a wallet top-up
that loses connection after payment never credits.

### 4. Backfill `isVerifiedDriver`

The driver gate keys off `users.isVerifiedDriver`, which is new. **Every
existing driver is locked out of going online until this runs** — the script is
in [SECURITY.md](SECURITY.md).

### 5. Smoke test

[TESTING.md](TESTING.md) walks the three critical journeys. Failures are marked
🔒 (a real bug) or ⚙️ (just not deployed yet), so a red step tells you which.

## Known gaps

- **Cloud Functions have no automated tests.** The rules are now covered; the
  functions are not. `creditWalletOnce` idempotency and the webhook signature
  check are the two worth testing first — both handle money.
- **`processDriverPayout` / `weeklyDriverReport` idempotency** against Pub/Sub
  redelivery is reasoned about but not proven under a real redelivery.
- **iOS is untested.** No macOS host was available; only Android was built.
- **Release signing** needs a real `android/key.properties` and keystore, which
  were never provided. Debug builds only so far.
- **Play Store background location** requires a prominent in-app disclosure and
  a declaration form describing the driver-tracking use case, or the listing is
  rejected. The manifest permission is declared; the paperwork is not done.

## Local environment quirks

These cost real time once already and are not obvious:

- **No `java` on `PATH`.** The Firestore emulator needs one. Use Android
  Studio's: `export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"`.
- **NDK is pinned to `27.1.12297006`** in `android/app/build.gradle.kts`. The
  previous pin (`27.0.12077973`) was a hollow install — one file, no
  `source.properties` — and failed configuration with `CXX1101`.
- **A full disk corrupts the Gradle cache.** If a build fails with "Could not
  read workspace metadata from …`metadata.bin`", delete
  `~/.gradle/caches/8.12/transforms` and run `./gradlew --stop` — a stale
  daemon replays the corruption from memory even after the files are gone.
- **Generated desktop plugin registrants churn.** `linux/`, `macos/`, and
  `windows/` registrant files show as modified after any `flutter` command,
  with an empty content diff — it is CRLF only. Discard rather than commit:
  `git checkout -- linux macos windows`.
