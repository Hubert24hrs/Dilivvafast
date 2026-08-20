# Dilivvafast

A Nigerian courier delivery platform. One Flutter codebase serves three roles —
**customer** (book and track a delivery), **driver** (accept jobs, navigate,
earn), and **admin** (approve drivers, oversee orders and finance) — plus an
investor role for bike financing. The backend is Firebase with Cloud Functions
in TypeScript.

Roles are separated by routing rather than by separate apps: `app_router.dart`
picks a shell per role and `role_guard.dart` holds the rules.

## Quick start

```bash
flutter pub get
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_public_token
```

You also need Firebase config files, which are **not** in the repo:

- Android — `android/app/google-services.json`
- iOS — `ios/Runner/GoogleService-Info.plist`

Download both from the Firebase console, or run `flutterfire configure` to
generate them along with `lib/firebase_options.dart`. See
[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).

## Configuration: no secrets in the app

Client-safe values are injected at build time with `--dart-define` and read via
`String.fromEnvironment`. **There is no bundled `.env`** — an earlier version
shipped one inside the APK, where anyone could unzip it and read the keys.

| Value | How it reaches the app |
|---|---|
| `MAPBOX_ACCESS_TOKEN` (public `pk.`) | `--dart-define` at build time |
| Paystack **secret** key, Anthropic key, SMTP password | Cloud Functions secrets only — never the client |

`AppConfig` deliberately exposes no accessor for a secret. If a feature seems to
need one in the app, that feature belongs in a Cloud Function.

Full detail in [BUILD.md](BUILD.md).

## Building an installable APK

```bash
flutter build apk --debug --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_public_token
```

Output lands at `build/app/outputs/flutter-apk/app-debug.apk`. Install with
`adb install -r <path>`, or copy it to a phone with "install from unknown
sources" enabled.

## Tests

```bash
flutter analyze          # must be clean
flutter test             # 119 tests

# Security rules — 88 tests against the Firebase emulators.
# Needs a JDK; this project's docs assume Android Studio's bundled one.
export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
cd rules_test && npm install && npm test
```

The rules suite executes the real `firestore.rules` and `storage.rules`, so a
change that loosens a privilege boundary fails a test rather than reaching
production. Run it before any rules deploy.

## Documentation

| File | What it covers |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Architecture, conventions, and the traps this codebase has already fallen into |
| [BUILD.md](BUILD.md) | Configuration model, debug and release builds, CI |
| [SECURITY.md](SECURITY.md) | The security model, what changed and why, deploy order |
| [TESTING.md](TESTING.md) | Manual smoke-test script for the three critical journeys |
| [STORE_READINESS.md](STORE_READINESS.md) | Console setup and manual steps before store submission |
| [PLAY_STORE.md](PLAY_STORE.md) | Google Play submission: blockers, Data Safety answers, declarations |
| [rules_test/README.md](rules_test/README.md) | What the rules tests cover and how to run them |
| [HANDOFF.md](HANDOFF.md) | Current state and what to pick up next |

## Stack

Flutter 3.x · Riverpod · go_router · Firebase (Auth, Firestore, Storage,
Functions, Messaging, Crashlytics, Analytics) · Cloud Functions in TypeScript ·
Paystack · Mapbox
