# Dilivvafast

Nigerian on-demand logistics and delivery platform.

- **App**: Flutter (Riverpod, GoRouter, Freezed)
- **Backend**: Firebase — Auth, Firestore, Cloud Functions, Storage, FCM
- **Maps**: Mapbox
- **Payments**: Paystack (server-verified)

See [SECURITY.md](SECURITY.md) for the trust model and [PLAY_STORE.md](PLAY_STORE.md)
for release steps.

---

## Development setup

### 1. Firebase

Place the config files:

- **Android** — `google-services.json` in `android/app/`
- **iOS** — `GoogleService-Info.plist` in `ios/Runner/`

If `lib/firebase_options.dart` is missing or stale, regenerate it:

```bash
flutterfire configure
```

### 2. Environment variables

```bash
cp .env.example .env
```

Fill in the two public values. **`.env` is bundled into the shipped binary**,
so only publishable keys go there:

| Variable | Notes |
|---|---|
| `MAPBOX_ACCESS_TOKEN` | Public token (`pk.*`). Needs `downloads:read` for the mobile SDK. |
| `PAYSTACK_PUBLIC_KEY` | Public key (`pk_test_*` / `pk_live_*`) only. |

The Paystack **secret** key and the Anthropic key are never configured here —
they live in Cloud Secret Manager and are read only by Cloud Functions.

### 3. Run

```bash
flutter pub get
flutter run
```

Mapbox, geolocation, FCM and Paystack checkout need a **physical device**;
they do not work on web or Windows desktop targets.

### 4. Code generation

Freezed / json_serializable models are generated. After editing any model:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Backend setup

### Secrets

```bash
firebase functions:secrets:set PAYSTACK_SECRET_KEY
firebase functions:secrets:set ANTHROPIC_API_KEY
```

### Deploy

```bash
cd functions && npm install && cd ..

firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

`firebase.json` declares firestore rules, indexes, storage rules and functions.
It previously declared **only** firestore rules, which meant the Cloud
Functions and storage rules had never been deployed.

### Paystack webhook

Register in the Paystack dashboard:

```
https://<region>-<project-id>.cloudfunctions.net/paystackWebhook
```

The handler verifies the HMAC-SHA512 signature, so an unregistered or forged
POST is rejected.

### First administrator

`setUserRole` requires an existing admin, so the first one is bootstrapped
out-of-band. See SECURITY.md → *Bootstrapping the first admin*.

---

## Roles

| Role | Granted by | Notes |
|---|---|---|
| `customer` | Default on registration | |
| `driver` | Admin, via `reviewDriverApplication` | User requests by setting `driverStatus: pending` |
| `investor` | Admin | Same request/approve pattern |
| `admin` | Existing admin, via `setUserRole` | Custom claim + mirrored `role` field |

No role can be self-assigned. `firestore.rules` freezes `role` against
client updates, and privileged authorisation reads the custom claim.

---

## Delivery lifecycle

```
pending → accepted → picked_up → in_transit → delivered
   ↓          ↓                        ↓
cancelled  cancelled                failed
```

Enforced in three places, deliberately: `CourierOrderModel.canTransitionTo`
(client UX), `firestore.rules` (authoritative), and the status trigger
(notifications).

Status values are serialised as the snake_case `@JsonValue` forms
(`picked_up`, `in_transit`) via `OrderStatus.wireValue` — **never** `.name`.

---

## Testing

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test                              # 111 unit/widget tests

cd functions && npx tsc --noEmit          # Cloud Functions type-check
```

Both emulator suites need a JVM. Android Studio bundles one:

```bash
export JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
export FUNCTIONS_DISCOVERY_TIMEOUT=120

cd test/firestore-rules && npm install && npm test   # 49 rules assertions
npm --prefix functions run test:integration          # 13 backend assertions
```

The Firestore emulator runs on port **8085**, not the default 8080. If every
rules test reports `cancelledByParent`, something else has taken the port.

All of the above run in CI.

## Deploying

See [DEPLOYMENT.md](DEPLOYMENT.md). Staging (`dilivvafast-staging`) already has
Firestore rules and indexes deployed; functions and storage are blocked on a
Blaze upgrade and one console click.

---

## Project layout

```
lib/
  core/           config, constants, providers, routing, theme, shared services
  features/       one folder per feature, each domain / data / presentation
functions/src/    Cloud Functions (TypeScript, firebase-functions v2)
test/
  unit/           pure Dart tests
  firestore-rules/ emulator-based security rules tests
firestore.rules   Firestore authorisation
storage.rules     Cloud Storage authorisation
```
