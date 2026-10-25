import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/components/glass_card.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/features/auth/presentation/controllers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: context.palette.danger,
          ),
        );
      } else if (!next.isLoading && prev?.isLoading == true && !next.hasError) {
        setState(() => _emailSent = true);
      }
    });

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: context.palette.textPrimary,
                ),
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: 24),

              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _emailSent
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                        : context.palette.brand.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                    color: _emailSent
                        ? const Color(0xFF4CAF50)
                        : context.palette.brand,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  _emailSent ? 'Check Your Email' : 'Forgot Password?',
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _emailSent
                      ? 'We\'ve sent a password reset link to\n${_emailController.text}'
                      : 'Enter your email and we\'ll send you\na link to reset your password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              if (!_emailSent) ...[
                Form(
                  key: _formKey,
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: context.palette.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: context.palette.textMuted,
                            size: 20,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || !v.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.brand,
                      foregroundColor: context.palette.surfaceBase,
                      disabledBackgroundColor: context.palette.brand.withValues(
                        alpha: 0.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: authState.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: context.palette.surfaceBase,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Send Reset Link',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                // Success state
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.brand,
                      foregroundColor: context.palette.surfaceBase,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _emailSent = false),
                    child: Text(
                      'Didn\'t receive the email? Try again',
                      style: TextStyle(
                        color: context.palette.textSecondary,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: context.palette.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authControllerProvider.notifier)
          .resetPassword(_emailController.text.trim());
    }
  }
}
