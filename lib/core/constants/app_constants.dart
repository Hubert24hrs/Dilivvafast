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

  // Contact details and hosted legal pages, kept in one place: they were
  // spelled three ways (.app, .ng, .com) across the app and the hosted
  // policy. Google Play shows the support address on the store listing and
  // requires the privacy and account-deletion pages to be live — see
  // PLAY_STORE.md before release.
  static const String supportEmail = 'support@dilivvafast.ng';
  static const String privacyEmail = 'privacy@dilivvafast.ng';
  static const String legalEmail = 'legal@dilivvafast.ng';
  static const String legalPagesBaseUrl =
      'https://hubert24hrs.github.io/Dilivvafast';
  static const String privacyPolicyUrl = '$legalPagesBaseUrl/privacy.html';
  static const String termsUrl = '$legalPagesBaseUrl/terms.html';
  static const String accountDeletionUrl =
      '$legalPagesBaseUrl/delete-account.html';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.dilivvafast.app';
}
