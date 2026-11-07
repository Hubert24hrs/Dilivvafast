import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to the environment variables the **client** is allowed to know.
///
/// Anything in `.env` is compiled into the shipped bundle as an asset, so this
/// class deliberately exposes only publishable values:
///
///  * `APP_ENV`, `API_BASE_URL` — non-secret build settings.
///
/// The Google Maps key is not read here: Android takes it from the manifest
/// at build time (MAPS_API_KEY, see android/app/build.gradle.kts).
///
/// Secret-tier credentials — the Anthropic API key, SMTP passwords — are NOT
/// here and must never be added. They live in Cloud Secret Manager and are
/// read only by Cloud Functions (`firebase functions:secrets:set <NAME>`).
/// `anthropicApiKey` used to exist on this class and was actually being sent
/// from the handset, which put the key in every installed APK.
///
/// See SECURITY.md, "Secret management".
class AppConfig {
  AppConfig._();
  static final AppConfig instance = AppConfig._();

  // ==================== APP CONFIG ====================
  String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.dilivvafast.ng';

  bool get isDevelopment => appEnv == 'development';
  bool get isProduction => appEnv == 'production';
}
