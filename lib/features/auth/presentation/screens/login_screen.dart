import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dilivvafast/core/presentation/components/custom_text_field.dart';
import 'package:dilivvafast/core/presentation/components/glass_card.dart';
import 'package:dilivvafast/core/presentation/components/three_d_button.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/utils/validators.dart';
import 'package:dilivvafast/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';
import 'package:dilivvafast/core/providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      ref.read(authControllerProvider.notifier).signIn(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auth redirect is handled by GoRouter's redirect guard.
    // Listen for auth state changes to navigate to the role-based home.
    ref.listen(authStateProvider, (previous, next) {
      if (next.hasValue && next.value != null && context.mounted) {
        final role = ref.read(currentUserRoleProvider);
        switch (role) {
          case UserRole.driver:
            context.go('/driver/home');
          case UserRole.admin:
            context.go('/admin/dashboard');
          case UserRole.investor:
            context.go('/investor/home');
          default:
            context.go('/customer/home');
        }
      }
    });

    // Listen for auth errors
    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        },
      );
    });

    final authStateAsync = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF1D1E33),
              AppTheme.backgroundColor,
            ],
            center: Alignment.topLeft,
            radius: 1.5,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: const [AppTheme.neonShadow],
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'DILIVVAFAST',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white54,
                      ),
                ),
                const SizedBox(height: 32),

                // Login form
                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          key: const Key('email_field'),
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          key: const Key('password_field'),
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          validator: Validators.password,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white38,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        // Forgot Password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppTheme.secondaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ThreeDButton(
                          key: const Key('login_btn'),
                          text: 'LOGIN',
                          isLoading: authStateAsync.isLoading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Social login divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Social buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                      key: const Key('google_btn'),
                      icon: Icons.g_mobiledata,
                      label: 'Google',
                      onTap: () {
                        ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle();
                      },
                    ),
                    const SizedBox(width: 16),
                    _SocialButton(
                      key: const Key('apple_btn'),
                      icon: Icons.apple,
                      label: 'Apple',
                      onTap: () {
                        ref
                            .read(authControllerProvider.notifier)
                            .signInWithApple();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Register link
                GestureDetector(
                  onTap: () => context.push('/register'),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Styled social login button
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
