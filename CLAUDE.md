# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

Dilivvafast is a Nigerian courier delivery platform: one Flutter codebase
serving **three roles** — customer (book + track), driver (accept, deliver,
earn), and admin (approve drivers, oversee orders and finance) — plus an
investor role for bike financing. The backend is Firebase, with Cloud Functions
in TypeScript.

Roles are separated by routing, not by separate apps. `app_router.dart` picks a
shell per role; `role_guard.dart` holds the rules.

## Commands

```bash
flutter pub get
flutter analyze                                    # must be clean before committing
flutter test                                       # must be green before committing
dart run build_runner build --delete-conflicting-outputs   # after touching a @freezed model or @GenerateMocks
dart format lib test

cd functions && npm install && npx tsc --noEmit     # typecheck Cloud Functions
```

Build an installable debug APK (see BUILD.md for the full story):

```bash
flutter build apk --debug --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token
```

## Architecture

Feature-first. Each feature under `lib/features/<name>/` follows:

```
domain/          entities (freezed) + repository interfaces
data/            Firebase repository implementations
infrastructure/  services that are not repositories
presentation/    screens, widgets, controllers
```

`lib/core/` holds cross-feature concerns: providers, routing, theme, services,
security.

**Extend this layout rather than introducing a new one.** A new screen goes in
its feature's `presentation/screens/`; a new Firestore query goes through that
feature's repository, not directly in a widget.

State is Riverpod. Every provider is declared in `lib/core/providers/providers.dart`
— add there rather than scattering providers through feature folders.

## The rule that matters most: the client is not trusted

Anything representing **money, trust, or privilege** is written by server code
and read by the client. Concretely:

| Never write from the app | Where it comes from |
|---|---|
| `users.role`, `isVerifiedDriver` | `onDriverApplicationReviewed` Cloud Function |
| `users.walletBalance` | Paystack verification, payouts, refunds, referral bonuses |
| `orders.totalFare`, `driverEarnings`, `platformCommission` | `onOrderCreated` recomputes from zone config |
| `transactions/*` | Cloud Functions only — the collection denies client creates |
| `referrals.referrerId` | `onReferralCreated` resolves it from the code |

Secrets follow the same split. `AppConfig` deliberately has **no accessor** for
the Paystack secret key, the Anthropic key, or SMTP credentials — those live in
Cloud Functions secrets (`defineSecret`). If a feature seems to need one in the
app, the feature belongs in a Cloud Function. Client-safe values arrive by
`--dart-define`; there is no bundled `.env`.

When you change `firestore.rules` or `storage.rules`, update `SECURITY.md` and
**do not deploy** — those files are reviewed before they ship.

### Two traps that have bitten this codebase

1. **Explicit nulls count as keys.** `CourierOrderModel.toFirestore()`
   serialises every field, so `driverId` is present-but-null on create. A rule
   written as `!data.keys().hasAny(['driverId'])` rejects every booking. Use
   `data.get('driverId', null) == null`.
2. **Enum values must match the rules.** Driver applications are created with
   status `submitted` (not `pending`), and roles serialise via `.name`. A rule
   that guesses the string silently blocks the feature.

## Payments

Checkout is initialised **server-side**: the app calls
`initializePaystackPayment`, opens the returned Paystack URL, and then calls
`verifyPaystackPayment` with the reference. The app holds no Paystack key.

`flutter_paystack_plus` is deliberately **not** used — on Android and iOS it
requires the Paystack *secret* key in the client.

Crediting is idempotent: the webhook and the verify call share
`creditWalletOnce`, which checks the reference inside the same transaction that
writes the balance. Whichever arrives second does nothing.

## Testing

`flutter test` must be green before any commit. Widget tests that assert on
copy should match case-insensitively — the login screen renders `DILIVVAFAST`,
and a redesign has already broken those assertions once.

When adding a mocked test, add the class to `@GenerateMocks` and re-run
build_runner. `HttpsCallableResult` has no public constructor, so mock it
rather than constructing one.

### Security rules

`firestore.rules` and `storage.rules` have their own suite in `rules_test/` —
88 tests run against the Firebase emulators. **Run it after touching either
rules file**, before deploying:

```bash
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"   # no java on PATH
export PATH="$JAVA_HOME/bin:$PATH"
cd rules_test && npm test
```

Keep `--test-concurrency=1` in the npm script: both test files share one
emulator, and parallel runs let one file's `clearFirestore()` wipe the other's
fixtures mid-test, which surfaces as phantom rule failures.

## Local environment

Quirks of this machine that will otherwise cost you a build cycle:

- **No `java` on `PATH`.** The Firestore emulator is a Java process. Use the
  JDK Android Studio ships: `/c/Program Files/Android/Android Studio/jbr`.
- **NDK is pinned to `27.1.12297006`.** Do not "fix" it back to
  `27.0.12077973` — that version exists on disk as a hollow install (one file,
  no `source.properties`) and fails configuration with `CXX1101`.
- **A full disk corrupts the Gradle cache.** `Could not read workspace metadata
  from …metadata.bin` means truncated cache files: delete
  `~/.gradle/caches/8.12/transforms`, then `./gradlew --stop`. The daemon
  replays the corruption from memory even after the files are deleted, so
  stopping it is not optional.
- **Generated desktop registrants churn.** Files under `linux/`, `macos/`, and
  `windows/` show as modified after most `flutter` commands with an *empty*
  content diff — it is CRLF only. `git checkout -- linux macos windows` before
  committing; never stage them.

## Conventions

- Comments explain *why*, and are worth writing where a reader would otherwise
  wonder. Skip comments that restate the line below them.
- Errors surface to the user as a message, not a silent no-op. Several bugs in
  this repo's history were failures swallowed by an empty `catch`.
- Prefer fixing a broken feature over deleting it, but delete genuinely dead
  code — three unused stub services were removed for pretending to work.
