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

  // Social links shown at the foot of the side menu. Left empty on purpose:
  // the icons stay hidden until these point at Dilivvafast's real pages, so
  // a guessed handle can never send customers to someone else's account.
  static const String facebookUrl = '';
  static const String instagramUrl = '';

  // Contact details and hosted legal pages, kept in one place. They used to
  // name addresses at dilivvafast.ng / .app / .com, none of which exist, so
  // every message bounced. Google Play shows the support address on the
  // store listing. Keep docs/*.html in step when changing these.
  static const String supportEmail = 'dilivvafastsupport@gmail.com';
  static const String privacyEmail = supportEmail;
  static const String legalEmail = supportEmail;
  static const String legalPagesBaseUrl =
      'https://hubert24hrs.github.io/Dilivvafast';
  static const String privacyPolicyUrl = '$legalPagesBaseUrl/privacy.html';
  static const String termsUrl = '$legalPagesBaseUrl/terms.html';
  static const String accountDeletionUrl =
      '$legalPagesBaseUrl/delete-account.html';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.dilivvafast.app';
}
