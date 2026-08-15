import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Client-side configuration.
///
/// Every value here is safe to ship inside the APK. Values arrive by
/// `--dart-define` at build time; a local `.env` file is consulted as a
/// convenience for development only and is never bundled as an asset.
///
/// Secrets — the Paystack secret key, the Anthropic API key, SMTP
/// credentials — deliberately have no accessor on this class. They live in
/// Firebase Cloud Functions secrets and are used only by server code. See
/// BUILD.md.
class AppConfig {
  AppConfig._();
  static final AppConfig instance = AppConfig._();

  static const _mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
  );
  static const _paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
  );
  static const _appEnv = String.fromEnvironment('APP_ENV');
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  // ==================== MAPBOX ====================
  String get mapboxAccessToken =>
      _value(_mapboxAccessToken, 'MAPBOX_ACCESS_TOKEN');

  // ==================== PAYSTACK ====================
  /// Publishable key only. Checkout is initialised server-side by the
  /// `initializePaystackPayment` Cloud Function, so the app never needs a
  /// secret key.
  String get paystackPublicKey =>
      _value(_paystackPublicKey, 'PAYSTACK_PUBLIC_KEY');

  // ==================== APP ====================
  String get appEnv => _value(_appEnv, 'APP_ENV', fallback: 'development');

  String get apiBaseUrl => _value(
    _apiBaseUrl,
    'API_BASE_URL',
    fallback: 'https://api.dilivvafast.ng',
  );

  bool get isDevelopment => appEnv == 'development';
  bool get isProduction => appEnv == 'production';

  bool get isMapboxConfigured => mapboxAccessToken.isNotEmpty;
  bool get isPaystackConfigured => paystackPublicKey.isNotEmpty;

  String _value(String dartDefineValue, String envKey, {String fallback = ''}) {
    if (_isConfiguredValue(dartDefineValue)) {
      return dartDefineValue.trim();
    }

    if (dotenv.isInitialized) {
      final envValue = dotenv.env[envKey];
      if (_isConfiguredValue(envValue)) {
        return envValue!.trim();
      }
    }

    return fallback;
  }

  /// Treats the placeholders shipped in `.env.example` as "not configured", so
  /// a half-filled env file behaves the same as a missing one.
  bool _isConfiguredValue(String? value) {
    if (value == null || value.trim().isEmpty) return false;

    final normalized = value.trim().toLowerCase();
    return !normalized.contains('placeholder') &&
        !normalized.contains('your_') &&
        !normalized.contains('_your') &&
        !normalized.startsWith('sk_') &&
        !normalized.startsWith('server_only');
  }
}
