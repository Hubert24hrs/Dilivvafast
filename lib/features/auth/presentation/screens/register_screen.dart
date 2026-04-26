import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/components/glass_card.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();

  int _step = 0;
  UserRole _selectedRole = UserRole.customer;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (_step > 0) {
                    setState(() => _step--);
                  } else {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 8),

              // Header
              Text(
                _step == 0
                    ? 'Create Account'
                    : _step == 1
                        ? 'Choose Your Role'
                        : 'Almost Done!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _step == 0
                    ? 'Fill in your details to get started'
                    : _step == 1
                        ? 'How will you use Dilivvafast?'
                        : 'Got a referral code? Enter it below',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),

              // Progress
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= _step
                            ? AppTheme.primaryColor
                            : const Color(0xFF1D1E33),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),

              // Steps
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 0
                    ? _buildPersonalInfoStep()
                    : _step == 1
                        ? _buildRoleStep()
                        : _buildReferralStep(),
              ),
              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: const Color(0xFF0A0E21),
                    disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF0A0E21),
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _step < 2 ? 'Continue' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Login link
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14),
                      children: const [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: Color(0xFFFF6B00),
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
    );
  }

  Widget _buildPersonalInfoStep() {
    return Form(
      key: _formKey,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildTextField(_nameController, 'Full Name', Icons.person_outline),
              const SizedBox(height: 14),
              _buildTextField(_emailController, 'Email Address', Icons.email_outlined,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              _buildPasswordField(_passwordController, 'Password',
                  _obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
              const SizedBox(height: 14),
              _buildPasswordField(_confirmPasswordController, 'Confirm Password',
                  _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController c, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null,
    );
  }

  Widget _buildPasswordField(
    TextEditingController c,
    String label,
    bool obscure,
    VoidCallback toggleObscure, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white38,
          ),
          onPressed: toggleObscure,
        ),
      ),
      validator: validator ??
          (v) {
            if (v == null || v.length < 6) return 'Min 6 characters';
            return null;
          },
    );
  }

  Widget _buildRoleStep() {
    return Column(
      key: const ValueKey('role'),
      children: UserRole.values
          .where((r) => r != UserRole.admin) // Admin is internal only
          .map((role) {
        final isSelected = _selectedRole == role;
        return GestureDetector(
          onTap: () => setState(() => _selectedRole = role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.12)
                  : const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isSelected ? AppTheme.primaryColor : Colors.white12,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _roleColor(role).withValues(alpha: 0.15),
                  ),
                  child: Icon(_roleIcon(role),
                      color: _roleColor(role), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _roleLabel(role),
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _roleDescription(role),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: Color(0xFFFF6B00), size: 24),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReferralStep() {
    return GlassCard(
      key: const ValueKey('referral'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.card_giftcard,
                  color: Color(0xFFFF6B00), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Referral Code (Optional)',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a referral code to earn bonus credits',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _referralController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                labelText: 'Referral Code',
                prefixIcon:
                    Icon(Icons.qr_code, color: Colors.white38, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNext() {
    if (_step == 0) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _step = 1);
      }
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else {
      ref.read(authControllerProvider.notifier).signUp(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
            referralCode: _referralController.text.trim().isNotEmpty
                ? _referralController.text.trim()
                : null,
          );
    }
  }

  IconData _roleIcon(UserRole role) {
    return switch (role) {
      UserRole.customer => Icons.person,
      UserRole.driver => Icons.delivery_dining,
      UserRole.investor => Icons.trending_up,
      UserRole.admin => Icons.admin_panel_settings,
    };
  }

  Color _roleColor(UserRole role) {
    return switch (role) {
      UserRole.customer => const Color(0xFFFF6B00),
      UserRole.driver => const Color(0xFF4CAF50),
      UserRole.investor => const Color(0xFFFF9800),
      UserRole.admin => const Color(0xFFE91E63),
    };
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.customer => 'Customer',
      UserRole.driver => 'Driver / Rider',
      UserRole.investor => 'Investor',
      UserRole.admin => 'Admin',
    };
  }

  String _roleDescription(UserRole role) {
    return switch (role) {
      UserRole.customer => 'Send and receive packages across Nigeria',
      UserRole.driver => 'Earn by delivering packages on your route',
      UserRole.investor => 'Fund bikes and earn passive income',
      UserRole.admin => 'Manage the platform',
    };
  }
}
