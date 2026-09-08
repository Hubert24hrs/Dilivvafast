import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/utils/validators.dart';
import 'package:dilivvafast/features/auth/presentation/controllers/auth_controller.dart';

/// Sign-in screen.
///
/// Sign-up lives on its own route rather than behind a toggle, so this screen
/// stays a single clear task.
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (next.hasError) {
        _notify(_friendlyError(next.error), palette.danger);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Keeps the form readable on tablets and foldables instead of
            // stretching a single column across the full width.
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Wordmark(),
                    const SizedBox(height: 36),
                    Text('Welcome back', style: context.text.headlineMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to track deliveries and manage your wallet.',
                      style: context.text.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            style: context.text.bodyLarge,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                size: 20,
                              ),
                            ),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            style: context.text.bodyLarge,
                            onFieldSubmitted: (_) => _handleSignIn(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Enter your password'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('login_btn'),
                      onPressed: authState.isLoading ? null : _handleSignIn,
                      child: authState.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: palette.onBrand,
                              ),
                            )
                          : const Text('Log in'),
                    ),
                    const SizedBox(height: 24),
                    const _OrDivider(),
                    const SizedBox(height: 20),
                    _SocialButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Continue with Google',
                      onPressed: authState.isLoading
                          ? null
                          : () => ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle(),
                    ),
                    if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                      const SizedBox(height: 12),
                      _SocialButton(
                        icon: Icons.apple_rounded,
                        label: 'Continue with Apple',
                        onPressed: authState.isLoading
                            ? null
                            : () => ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithApple(),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Center(
                      child: TextButton(
                        key: const Key('toggle_btn'),
                        onPressed: () => context.go('/register'),
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: context.text.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Sign up',
                                style: context.text.bodyMedium?.copyWith(
                                  color: palette.brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _handleSignIn() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref
        .read(authControllerProvider.notifier)
        .signIn(_emailController.text.trim(), _passwordController.text);
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || Validators.email(email) != null) {
      _notify(
        'Enter your email address above, then tap Forgot password.',
        context.palette.warning,
      );
      return;
    }

    await ref.read(authControllerProvider.notifier).resetPassword(email);
    if (!mounted) return;

    // Confirm regardless of whether the address exists — saying otherwise
    // would let anyone probe for registered accounts.
    _notify(
      'If an account exists for $email, a reset link is on its way.',
      context.palette.success,
    );
  }

  void _notify(String message, Color background) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: background),
      );
  }

  String _friendlyError(Object? error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }
}

// ── Pieces ──────────────────────────────────────────────────────────────────

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: palette.brandSubtle,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Icon(
            Icons.delivery_dining_rounded,
            size: 34,
            color: palette.brand,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Dilivvafast',
          style: context.text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: palette.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: context.text.bodySmall),
        ),
        Expanded(child: Divider(color: palette.border)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22, color: context.palette.textPrimary),
      label: Text(label),
    );
  }
}
