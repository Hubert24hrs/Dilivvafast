/// Non-secret application constants.
///
/// Credentials do NOT belong in this file. Anything checked in here ships
/// inside the APK/IPA and can be recovered by unzipping the bundle, so every
/// key is read at runtime from `.env` via [AppConfig] instead — and secret-tier
/// credentials (Paystack secret key, Anthropic key, SMTP password) never reach
/// the client at all; they live in Cloud Secret Manager and are used only by
/// Cloud Functions.
///
/// This file previously held a live Paystack **secret** key and a hardcoded
/// Mapbox token. Both have been removed. See SECURITY.md, "Secret management".
class AppConstants {
  static const String appName = 'Dilivvafast';

  // Asset Paths
  static const String logoPath = 'assets/images/logo.png';
}
