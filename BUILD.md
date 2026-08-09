# Dilivvafast Build Instructions

This guide provides instructions for compiling and building release artifacts for Dilivvafast on Android and iOS.

---

## Prerequisites

- **Flutter SDK**: 3.24.x or higher
- **Dart SDK**: 3.5.x or higher
- **Java Development Kit (JDK)**: 17
- **Xcode CLI & CocoaPods** (for iOS builds, macOS runner required)

---

## 1. Environment Preparation

Clean the build cache and fetch all dependencies:

```bash
flutter clean
flutter pub get
```

Run static analysis and tests:

```bash
flutter analyze
flutter test
```

---

## 2. Android Release Build (AAB / APK)

### Step 1: Ensure `android/key.properties` Exists
Create `android/key.properties` with your signing configuration:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=dilivvafast
storeFile=/path/to/dilivvafast-release.jks
```

### Step 2: Build App Bundle for Google Play Store
```bash
flutter build appbundle --release
```
The output file will be located at:
`build/app/outputs/bundle/release/app-release.aab`

### Step 3: Build APK for Direct Testing (Optional)
```bash
flutter build apk --release
```
The output APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 3. iOS Release Build (IPA / App Store Connect)

*Note: iOS builds require a macOS host with Xcode installed.*

### Step 1: Install CocoaPods Dependencies
```bash
cd ios
pod install --repo-update
cd ..
```

### Step 2: Update ExportOptions.plist
Ensure your Apple 10-character Team ID is set in `ios/ExportOptions.plist`.

### Step 3: Build IPA Package
```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```
The generated `.ipa` file will be created in `build/ios/ipa/` ready for upload to App Store Connect via Transporter or Xcode Organizer.
