import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fast_delivery/core/presentation/components/custom_text_field.dart';
import 'package:fast_delivery/core/presentation/components/glass_card.dart';
import 'package:fast_delivery/core/presentation/components/three_d_button.dart';
import 'package:fast_delivery/core/presentation/theme/app_theme.dart';
import 'package:fast_delivery/core/presentation/utils/validators.dart';
import 'package:fast_delivery/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fast_delivery/features/auth/domain/entities/user_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

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

      final controller = ref.read(authControllerProvider.notifier);
      if (_isLogin) {
        controller.signIn(email, password);
      } else {
        controller.signUp(
          fullName: email.split('@').first, // Temporary — full register screen in Phase 2
          email: email,
          phone: '',
          password: password,
        );
      }
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
                const Icon(
                  Icons.delivery_dining,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? 'Login Mode' : 'Signup Mode',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 32),
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
                          obscureText: true,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 24),
                        ThreeDButton(
                          key: const Key('login_btn'),
                          text: _isLogin ? 'LOGIN' : 'SIGN UP',
                          isLoading: authStateAsync.isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          key: const Key('toggle_btn'),
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'Create Account'
                                : 'Already have an account?',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Or continue with',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      key: const Key('google_btn'),
                      onTap: () {
                        ref.read(authControllerProvider.notifier).signInWithGoogle();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.g_mobiledata,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      key: const Key('apple_btn'),
                      onTap: () {
                        ref.read(authControllerProvider.notifier).signInWithApple();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
