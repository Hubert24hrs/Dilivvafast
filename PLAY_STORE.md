# Google Play release checklist

Steps that must be completed in the **Google Play Console** and cannot be done
from source, plus the source-side facts a reviewer will ask about.

---

## Location permissions — current position

The app declares **foreground location only**:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

`ACCESS_BACKGROUND_LOCATION` is **not declared and not requested**.

This matters for the review:

- The **background location declaration form does not apply.** Do not fill it
  in, and do not submit a demo video for background location — there is no
  background location feature to demonstrate.
- No prominent-disclosure screen is required, and none exists. Google's
  prominent-disclosure obligation attaches to background access; foreground
  access is covered by the runtime permission dialog.
- Location is requested **in context** — the first time tracking actually
  starts — not at launch.

### If background tracking is ever added

Do all of this *before* writing the code:

1. Add `ACCESS_BACKGROUND_LOCATION` and a `foregroundServiceType="location"`
   service.
2. Build a prominent-disclosure screen that appears **before** the permission
   request, names the app, says data is collected in the background, and states
   why. The user must be able to decline.
3. Complete the Play Console background-location declaration form.
4. Record a demo video showing the disclosure, the permission prompt, and the
   feature in use.
5. Update the Data Safety form and SECURITY.md.

Skipping any of these is a rejection, and repeat offences risk suspension.

---

## Data Safety form

Declare, based on what the code actually does:

| Data type | Collected | Shared | Why |
|---|---|---|---|
| Name, email, phone | Yes | No | Account, delivery contact |
| Approximate + precise location | Yes | No | Live courier tracking, fare by distance |
| Photos | Yes | No | Driver documents, proof of delivery |
| Payment info | No¹ | — | Handled entirely by Paystack |
| Crash logs, diagnostics | Yes | Yes (Firebase) | Crashlytics, Performance |

¹ The app never sees or stores card data — Paystack checkout runs in an
external browser. Do **not** declare payment-info collection.

Also declare: data is encrypted in transit, and users can request deletion
(account deletion exists in `firebase_auth_repository`).

---

## Pre-launch checklist

**Signing**

- [ ] `android/key.properties` exists locally and is **not** committed
      (`.gitignore` covers `key.properties`, `*.jks`, `*.keystore`).
- [ ] Upload key backed up somewhere you will still have in two years.
- [ ] Play App Signing enrolled.

**Version**

- [ ] `pubspec.yaml` version bumped (currently `1.0.1+2`).

**Build**

```bash
flutter build appbundle --release
```

- [ ] Bundle builds clean.
- [ ] Test on a physical device — Mapbox, geolocation, FCM and Paystack
      checkout cannot be exercised on an emulator or on Windows/web.

**Backend — must be done before the app is usable**

- [ ] `firebase deploy --only firestore:rules,storage,functions`
      (`firebase.json` previously declared **only** firestore rules, so
      functions and storage rules were never deployed).
- [ ] `firebase functions:secrets:set PAYSTACK_SECRET_KEY`
- [ ] `firebase functions:secrets:set ANTHROPIC_API_KEY`
- [ ] Register the webhook in the Paystack dashboard →
      `https://<region>-<project>.cloudfunctions.net/paystackWebhook`
- [ ] Composite indexes built (`firebase deploy --only firestore:indexes`).
- [ ] Bootstrap the first admin (see SECURITY.md).
- [ ] **Rotate the Paystack key that was committed to git history.**

**Store listing**

- [ ] Privacy policy URL live — `docs/privacy.html` needs hosting.
- [ ] Terms URL live — `docs/terms.html`.
- [ ] Screenshots: phone, 7" and 10" tablet.
- [ ] Feature graphic 1024×500.
- [ ] Content rating questionnaire.
- [ ] Target audience (not directed at children).

---

## App Check

Not configured. Without it the backend accepts calls from anything holding a
valid token, not only genuine installs of your app.

1. Play Console → enable Play Integrity.
2. Firebase Console → App Check → register the Android app with Play Integrity.
3. Add `firebase_app_check` to `pubspec.yaml` and activate it in `main()` after
   `Firebase.initializeApp()`.
4. Run in **monitoring mode** first and watch the metrics — enforcing
   immediately will lock out every already-installed client.
5. Only then enforce, per-service.
