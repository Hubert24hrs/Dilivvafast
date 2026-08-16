# Building Dilivvafast

## Configuration model

The app takes its configuration at **build time** through `--dart-define`. There
is no `.env` file bundled into the APK — a bundled `.env` is readable by anyone
who unzips the app, so it can never hold anything sensitive.

Two categories, and the split matters:

| Category | Where it lives | Examples |
|---|---|---|
| **Client-safe** — publishable values | `--dart-define` at build time | `MAPBOX_ACCESS_TOKEN`, `PAYSTACK_PUBLIC_KEY` |
| **Secret** — grants spending or account access | Firebase Cloud Functions secrets | `PAYSTACK_SECRET_KEY`, `ANTHROPIC_API_KEY`, SMTP credentials |

Nothing in the second row has an accessor anywhere in `lib/`. If you find
yourself adding one, the feature belongs in a Cloud Function instead.

### Client-safe keys

| Key | Required | Default | Used for |
|---|---|---|---|
| `MAPBOX_ACCESS_TOKEN` | for maps | _(empty — maps stay blank)_ | Mapbox tiles and geocoding |
| `PAYSTACK_PUBLIC_KEY` | no | _(empty)_ | Reserved; checkout is initialised server-side |
| `APP_ENV` | no | `development` | `development` / `production` |
| `API_BASE_URL` | no | `https://api.dilivvafast.ng` | Backend base URL |

A missing `MAPBOX_ACCESS_TOKEN` degrades gracefully: the app builds and runs,
maps just don't render tiles. Nothing crashes.

### Local development

For local work you may keep a `.env` file at the repo root (it is gitignored and
**not** an asset — it is loaded at runtime only if present). Copy `.env.example`
and fill in the client-safe values. CI never uses it.

## Building a debug APK

```bash
flutter build apk --debug --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here --dart-define=APP_ENV=development
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

Install on a connected phone:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

If debug builds feel too slow to evaluate real performance, build a profile APK
instead — same flags, `--profile` in place of `--debug`.

### Using a dart-define file

Rather than repeating flags, put them in a JSON file (gitignored) and pass it:

```bash
flutter build apk --debug --dart-define-from-file=dart_defines.json
```

```json
{
  "MAPBOX_ACCESS_TOKEN": "pk.your_token_here",
  "PAYSTACK_PUBLIC_KEY": "pk_test_your_key_here",
  "APP_ENV": "development"
}
```

## Release builds

A release build additionally needs `android/key.properties` pointing at a real
keystore. Without it the Gradle release config has nothing to sign with. CI
supplies the keystore from the `KEYSTORE_JKS_BASE64` secret; the workflows in
`.github/workflows/` pass the same `--dart-define` flags from repository
secrets.

## Server-side configuration (Cloud Functions)

Secrets are stored with Firebase's secret manager, not in `.env` and not in
source:

```bash
firebase functions:secrets:set PAYSTACK_SECRET_KEY
firebase functions:secrets:set ANTHROPIC_API_KEY
firebase functions:secrets:set PAYSTACK_WEBHOOK_SECRET
```

Each function declares the secrets it needs (`defineSecret` in
`functions/src/index.ts`), so a secret is only injected into the functions that
actually use it.

Build and typecheck the functions before deploying:

```bash
cd functions && npm install && npm run build
```

---

## Prerequisites
- **Flutter SDK**: 3.24.x or higher
- **Dart SDK**: 3.5.x or higher
- **Java Development Kit (JDK)**: 17
- **Xcode CLI & CocoaPods** (for iOS builds, macOS runner required)

---

## Release artifacts

### Android App Bundle (Play Store)

`android/key.properties` must exist and point at a real keystore:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=dilivvafast
storeFile=/path/to/dilivvafast-release.jks
```

Then, with the same `--dart-define` flags as above:

```bash
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (macOS host with Xcode required)

```bash
cd ios && pod install --repo-update && cd ..
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

Set your 10-character Apple Team ID in `ios/ExportOptions.plist` first. The
`.ipa` lands in `build/ios/ipa/`, ready for Transporter or Xcode Organizer.
