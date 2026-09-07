import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/utils/validators.dart';
import 'package:dilivvafast/features/auth/presentation/controllers/auth_controller.dart';

/// Sign-up flow.
///
/// Everyone registers as a customer — there is deliberately no role picker.
/// Driver and investor are unlocked afterwards from the drawer's mode
/// switcher, which routes into the vetting flows those modes require.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _totalSteps = 2;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();

  int _step = 0;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

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
    final palette = context.palette;
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_friendlyError(next.error)),
              backgroundColor: palette.danger,
            ),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: _step > 0 ? 'Previous step' : 'Back to sign in',
          onPressed: _handleBack,
        ),
        title: Text('Step ${_step + 1} of $_totalSteps',
            style: context.text.bodyMedium),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepProgress(step: _step, total: _totalSteps),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _step == 0 ? 'Create your account' : 'Almost done',
                      style: context.text.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _step == 0
                          ? 'A few details and you can start sending packages.'
                          : 'Add a referral code if you have one, then accept the terms.',
                      style: context.text.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _step == 0
                          ? _buildDetailsStep()
                          : _buildReferralStep(),
                    ),
                  ],
                ),
              ),
            ),
            _BottomBar(
              isLoading: authState.isLoading,
              enabled: _step == 0 || _acceptedTerms,
              label: _step == 0 ? 'Continue' : 'Create account',
              onPressed: _handleNext,
              footer: _step == 0 ? const _SignInLink() : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Steps ────────────────────────────────────────────────────────────────

  Widget _buildDetailsStep() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        key: const ValueKey('details'),
        children: [
          _Field(
            controller: _nameController,
            label: 'Full name',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            validator: Validators.name,
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _emailController,
            label: 'Email address',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _phoneController,
            label: 'Phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            ],
            validator: Validators.phoneNumber,
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.newPassword],
            validator: Validators.password,
            trailing: _ObscureToggle(
              obscured: _obscurePassword,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 8),
          _PasswordStrength(password: _passwordController.text),
          const SizedBox(height: 14),
          _Field(
            controller: _confirmPasswordController,
            label: 'Confirm password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            validator: (v) => Validators.confirmPassword(
              v,
              _passwordController.text,
            ),
            trailing: _ObscureToggle(
              obscured: _obscureConfirm,
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralStep() {
    final palette = context.palette;
    return Column(
      key: const ValueKey('referral'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          controller: _referralController,
          label: 'Referral code (optional)',
          icon: Icons.card_giftcard_outlined,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(12),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.brandSubtle,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: palette.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You are joining as a customer. You can apply to drive or '
                  'invest at any time from the menu once you are signed in.',
                  style: context.text.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _TermsCheckbox(
          value: _acceptedTerms,
          onChanged: (v) => setState(() => _acceptedTerms = v),
          onOpenTerms: () =>
              _openLegalUrl('https://hubert24hrs.github.io/Dilivvafast/terms.html'),
          onOpenPrivacy: () => _openLegalUrl(
              'https://hubert24hrs.github.io/Dilivvafast/privacy.html'),
        ),
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _handleBack() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.go('/login');
    }
  }

  void _handleNext() {
    FocusScope.of(context).unfocus();

    if (_step == 0) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _step = 1);
      }
      return;
    }

    if (!_acceptedTerms) return;

    // Role is intentionally not passed — registration always creates a
    // customer, and the repository defaults accordingly.
    ref.read(authControllerProvider.notifier).signUp(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          referralCode: _referralController.text.trim().isNotEmpty
              ? _referralController.text.trim().toUpperCase()
              : null,
        );
  }

  Future<void> _openLegalUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  String _friendlyError(Object? error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }
}

// ── Pieces ──────────────────────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: i <= step ? palette.brand : palette.border,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.trailing,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? trailing;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final List<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: trailing,
      ),
    );
  }
}

class _ObscureToggle extends StatelessWidget {
  const _ObscureToggle({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        size: 20,
      ),
    );
  }
}

/// Live feedback on password quality, mirroring the rules in [Validators].
class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final palette = context.palette;
    final checks = <bool>[
      password.length >= 8,
      RegExp(r'[A-Za-z]').hasMatch(password),
      RegExp(r'[0-9]').hasMatch(password),
      RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    ];
    final score = checks.where((c) => c).length;
    final (color, label) = switch (score) {
      <= 1 => (palette.danger, 'Weak'),
      2 => (palette.warning, 'Fair'),
      3 => (palette.info, 'Good'),
      _ => (palette.success, 'Strong'),
    };

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / checks.length,
              minHeight: 4,
              color: color,
              backgroundColor: palette.border,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: context.text.bodySmall?.copyWith(
                color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final linkStyle = context.text.bodySmall?.copyWith(
      color: palette.brand,
      fontWeight: FontWeight.w600,
    );

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: context.text.bodySmall,
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: onOpenTerms,
                          child: Text('Terms of Service', style: linkStyle),
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: onOpenPrivacy,
                          child: Text('Privacy Policy', style: linkStyle),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isLoading,
    required this.enabled,
    required this.label,
    required this.onPressed,
    this.footer,
  });

  final bool isLoading;
  final bool enabled;
  final String label;
  final VoidCallback onPressed;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: palette.surfaceBase,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: (isLoading || !enabled) ? null : onPressed,
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: palette.onBrand,
                    ),
                  )
                : Text(label),
          ),
          if (footer != null) ...[
            const SizedBox(height: 4),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _SignInLink extends StatelessWidget {
  const _SignInLink();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go('/login'),
      child: Text.rich(
        TextSpan(
          text: 'Already have an account? ',
          style: context.text.bodySmall,
          children: [
            TextSpan(
              text: 'Sign in',
              style: context.text.bodySmall?.copyWith(
                color: context.palette.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
