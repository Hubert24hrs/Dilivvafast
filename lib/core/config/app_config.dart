import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Singleton configuration class wrapping flutter_dotenv.
/// Provides typed access to all environment variables.
class AppConfig {
  AppConfig._();
  static final AppConfig instance = AppConfig._();

  // ==================== MAPBOX ====================
  String get mapboxAccessToken =>
      dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  // ==================== PAYSTACK ====================
  String get paystackPublicKey =>
      dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';

  String get paystackSecretKey =>
      dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';

  // ==================== ANTHROPIC (AI Chat - Maya) ====================
  String get anthropicApiKey =>
      dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  // ==================== SMTP ====================
  String get smtpHost =>
      dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';

  int get smtpPort =>
      int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;

  String get smtpUsername =>
      dotenv.env['SMTP_USERNAME'] ?? '';

  String get smtpPassword =>
      dotenv.env['SMTP_PASSWORD'] ?? '';

  String get senderName =>
      dotenv.env['SENDER_NAME'] ?? 'Dilivvafast';

  String get senderEmail =>
      dotenv.env['SENDER_EMAIL'] ?? 'noreply@dilivvafast.ng';

  // ==================== APP CONFIG ====================
  String get appEnv =>
      dotenv.env['APP_ENV'] ?? 'development';

  String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.dilivvafast.ng';

  bool get isDevelopment => appEnv == 'development';
  bool get isProduction => appEnv == 'production';

  /// Check if critical keys are configured
  bool get isMapboxConfigured => mapboxAccessToken.isNotEmpty;
  bool get isPaystackConfigured => paystackPublicKey.isNotEmpty;
  bool get isAnthropicConfigured => anthropicApiKey.isNotEmpty;
  bool get isSmtpConfigured =>
      smtpUsername.isNotEmpty && smtpPassword.isNotEmpty;
}
