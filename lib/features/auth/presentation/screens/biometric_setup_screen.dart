import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isBiometricsAvailable = false;
  bool _isEnrolling = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();

      // Three platform round-trips: the screen can easily be gone by now.
      if (!mounted) return;
      setState(() {
        _isBiometricsAvailable = isAvailable && isDeviceSupported;
        _availableBiometrics = available;
      });
    } catch (e) {
      debugPrint('Biometric check error: $e');
      if (!mounted) return;
      // Fail closed: if we cannot establish that biometrics are available,
      // the enrolment path stays hidden.
      setState(() => _isBiometricsAvailable = false);
    }
  }

  Future<void> _enableBiometrics() async {
    setState(() => _isEnrolling = true);

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason:
            'Authenticate to enable biometric login for Dilivvafast',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        await _secureStorage.write(key: 'biometric_enabled', value: 'true');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Biometric login enabled! 🎉'),
              backgroundColor: context.palette.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          context.go('/customer/home');
        }
      }
    } catch (e) {
      debugPrint('Biometric enrollment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric setup failed: $e'),
            backgroundColor: context.palette.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  String get _biometricTypeName {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    }
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    return 'Biometric';
  }

  IconData get _biometricIcon {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    }
    return Icons.fingerprint;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon with glow
              Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: context.palette.brand.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: Icon(
                      _biometricIcon,
                      size: 56,
                      color: context.palette.onBrand,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 40),

              // Title
              Text(
                    'Enable $_biometricTypeName',
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Quick and secure access to your Dilivvafast account. '
                'No need to type your password every time.',
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 15,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: 48),

              // Features
              _buildFeatureRow(
                Icons.shield_outlined,
                'Secure Authentication',
                'Your biometrics never leave your device',
              ),
              const SizedBox(height: 16),
              _buildFeatureRow(
                Icons.bolt,
                'Instant Login',
                'Skip password entry every time',
              ),
              const SizedBox(height: 16),
              _buildFeatureRow(
                Icons.lock_outline,
                'Privacy First',
                'Encrypted & stored locally',
              ),

              const Spacer(flex: 3),

              // Enable button
              if (_isBiometricsAvailable)
                SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isEnrolling ? null : _enableBiometrics,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.palette.brand,
                          foregroundColor: context.palette.onBrand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: context.palette.brand.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        child: _isEnrolling
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: context.palette.onBrand,
                                ),
                              )
                            : Text(
                                'Enable $_biometricTypeName',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0)
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.palette.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.palette.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: context.palette.warning,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Biometric authentication is not available on this device.',
                          style: TextStyle(
                            color: context.palette.warning,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Skip button
              TextButton(
                onPressed: () => context.go('/customer/home'),
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.palette.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: context.palette.brand, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.palette.onBrand,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideX(begin: -0.1, end: 0);
  }
}
