# Dilivvafast Store Readiness Checklist & Manual Action Items

This document outlines all required manual actions, console configurations, and account setups that must be completed before shipping Dilivvafast to the Apple App Store and Google Play Store.

---

## 1. Firebase Console Actions (Required for iOS & Auth)

### A. iOS App Re-Registration & Configuration
1. Go to [Firebase Console](https://console.firebase.google.com/) → Project Settings → **General**.
2. Under "Your apps", select the iOS app or click **Add app** (iOS).
3. Set Bundle ID to **`com.dilivvafast.app`** (must match `ios/Runner/Info.plist` and Xcode project).
4. Download the newly generated **`GoogleService-Info.plist`**.
5. Replace `ios/Runner/GoogleService-Info.plist` in the repository with this downloaded file.
6. Run `flutterfire configure` from the terminal to update `lib/firebase_options.dart` automatically.

### B. SHA Fingerprints for Android (Google Sign-In & Phone Auth)
1. Generate your release keystore SHA-1 and SHA-256 fingerprints:
   ```bash
   keytool -list -v -keystore ~/dilivvafast-release.jks -alias dilivvafast
   ```
2. Go to Firebase Console → Project Settings → **General** → Android app (`com.dilivvafast.app`).
3. Add both **SHA-1** and **SHA-256** fingerprints for:
   - Debug keystore (`~/.android/debug.keystore`)
   - Release keystore (`dilivvafast-release.jks`)
   - Google Play App Signing key (copied from Google Play Console → Setup → App Integrity).

---

## 2. Android Release Signing Setup

1. Generate release keystore if not already created:
   ```bash
   keytool -genkey -v -keystore ~/dilivvafast-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dilivvafast
   ```
2. Create `android/key.properties` (never commit this file; it is gitignored):
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=dilivvafast
   storeFile=/path/to/dilivvafast-release.jks
   ```

---

## 3. Apple Developer Account & App Store Connect Setup

1. **Apple Team ID**:
   - Open `ios/ExportOptions.plist` and update `<key>teamID</key>` with your 10-character Apple Team ID (found at `developer.apple.com/account`).
2. **App Store Connect Privacy Nutrition Label**:
   - Declare precise location data collection (app functionality).
   - Declare contact info (name, email, phone).
   - Declare financial info (Paystack card processing).
   - Declare identifiers (UID, FCM token).
   - Declare analytics & crash data (Firebase Analytics & Crashlytics).
3. **App Privacy Manifest**:
   - `ios/Runner/PrivacyInfo.xcprivacy` has been created with all required reason API declarations (NSUserDefaults, file timestamps, disk space, boot time).

---

## 4. Google Play Console Setup

1. **Target API Level**:
   - `android/app/build.gradle.kts` has been updated to `compileSdk = 36` and `targetSdk = 36` as mandated by Google Play policies.
2. **Data Safety Form**:
   - Declare location data (collected & shared for delivery dispatch).
   - Declare personal info (name, email, phone).
   - Declare financial info (Paystack payments).
   - Declare app performance data (Crashlytics logs).
3. **In-App Account Deletion**:
   - Implemented in-app under **Settings → Delete Account** (`lib/features/auth/presentation/screens/delete_account_screen.dart`). Submit the web deletion URL if required.

---

## 5. Paystack & Mapbox Keys

1. Ensure production keys are populated in your environment or Cloud Functions config:
   - Paystack Secret & Public Keys
   - Mapbox Public Access Token (for maps UI) & Secret Token (for downloading Mapbox SDK on iOS/Android).
