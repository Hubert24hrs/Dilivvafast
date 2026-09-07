import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to the environment variables the **client** is allowed to know.
///
/// Anything in `.env` is compiled into the shipped bundle as an asset, so this
/// class deliberately exposes only publishable values:
///
///  * `MAPBOX_ACCESS_TOKEN` — a public token, scoped and restricted in the
///    Mapbox dashboard.
///  * `PAYSTACK_PUBLIC_KEY` — public by design; it can start a transaction but
///    cannot move or read money.
///
/// Secret-tier credentials — the Paystack **secret** key, the Anthropic API
/// key, SMTP passwords — are NOT here and must never be added. They live in
/// Cloud Secret Manager and are read only by Cloud Functions
/// (`firebase functions:secrets:set <NAME>`). Getters for all three used to
/// exist on this class; `anthropicApiKey` was actually being sent from the
/// handset, which put the key in every installed APK.
///
/// See SECURITY.md, "Secret management".
class AppConfig {
  AppConfig._();
  static final AppConfig instance = AppConfig._();

  // ==================== MAPBOX ====================
  String get mapboxAccessToken => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  // ==================== PAYSTACK (public key only) ====================
  String get paystackPublicKey => dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';

  // ==================== APP CONFIG ====================
  String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.dilivvafast.ng';

  bool get isDevelopment => appEnv == 'development';
  bool get isProduction => appEnv == 'production';

  /// Check if client-side keys are configured.
  bool get isMapboxConfigured => mapboxAccessToken.isNotEmpty;
  bool get isPaystackConfigured => paystackPublicKey.isNotEmpty;
}
