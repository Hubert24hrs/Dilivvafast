import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/constants/firestore_constants.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/utils/validators.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/auth/domain/entities/app_mode.dart';

/// Investor enrolment.
///
/// Reached from the drawer's mode switcher when a customer taps Investor
/// without an existing enrolment. Submitting creates the investor profile and
/// moves the account to [ModeAccess.pending]; an admin grants approval, which
/// is what actually unlocks the investor surface.
class InvestorJoinScreen extends ConsumerStatefulWidget {
  const InvestorJoinScreen({super.key});

  @override
  ConsumerState<InvestorJoinScreen> createState() => _InvestorJoinScreenState();
}

class _InvestorJoinScreenState extends ConsumerState<InvestorJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  bool _acceptedTerms = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider).value;
      if (user != null && _accountNameController.text.isEmpty) {
        _accountNameController.text = user.fullName;
      }
    });
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final status = user?.investorStatus ?? ModeAccess.none;

    return Scaffold(
      appBar: AppBar(title: const Text('Become an investor')),
      body: SafeArea(
        child: status == ModeAccess.pending
            ? const _PendingState()
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fund a bike, earn a share',
                      style: context.text.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'You fund a delivery bike. A vetted rider runs it under a '
                    'hire-purchase agreement, and you earn a share of what it '
                    'makes until the bike is paid off.',
                    style: context.text.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  const _HowItWorks(),
                  const SizedBox(height: 24),
                  Text('Payout account', style: context.text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Where we send your earnings. You can change this later.',
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bankNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Bank name',
                      prefixIcon:
                          Icon(Icons.account_balance_outlined, size: 20),
                    ),
                    validator: (v) => Validators.required(v, 'Bank name'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Account number',
                      prefixIcon: Icon(Icons.tag_rounded, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length != 10) {
                        return 'Enter the 10-digit account number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _accountNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Account name',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    validator: (v) => Validators.required(v, 'Account name'),
                  ),
                  const SizedBox(height: 20),
                  const _RiskNotice(),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _acceptedTerms,
                    onChanged: (v) =>
                        setState(() => _acceptedTerms = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'I understand returns are not guaranteed and my capital '
                      'is at risk.',
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: context.palette.surfaceBase,
            border: Border(top: BorderSide(color: context.palette.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_isSubmitting || !_acceptedTerms) ? null : _submit,
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: context.palette.onBrand,
                      ),
                    )
                  : const Text('Submit application'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final firestore = ref.read(firestoreProvider);

      // The investor profile is keyed by uid so the rules can check ownership
      // without an extra lookup.
      await firestore
          .collection(FirestoreConstants.investors)
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'totalInvested': 0.0,
        'totalEarned': 0.0,
        'activeBikes': 0,
        'pendingWithdrawal': 0.0,
        'payoutBankName': _bankNameController.text.trim(),
        'payoutAccountNumber': _accountNumberController.text.trim(),
        'payoutAccountName': _accountNameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Requesting access only ever writes `pending`; approval is an admin
      // action, enforced by the Firestore rules.
      final update = await ref
          .read(userRepositoryProvider)
          .updateUser(user.uid, {'investorStatus': ModeAccess.pending.name});

      if (!mounted) return;

      update.fold(
        (failure) => messenger.showSnackBar(
          SnackBar(content: Text(failure.message)),
        ),
        (_) => setState(() {}),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not submit your application: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    (Icons.payments_outlined, 'Fund a bike', 'Choose a bike and pay upfront.'),
    (
      Icons.two_wheeler_outlined,
      'A rider takes it on',
      'We match it to a vetted rider on a hire-purchase agreement.'
    ),
    (
      Icons.trending_up_rounded,
      'Earn weekly',
      'Your share is credited as the bike completes deliveries.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceSunken,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: palette.investorAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(_steps[i].$1,
                      size: 18, color: palette.investorAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_steps[i].$2,
                          style: context.text.titleMedium
                              ?.copyWith(fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(_steps[i].$3, style: context.text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RiskNotice extends StatelessWidget {
  const _RiskNotice();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.warningSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: palette.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Investing carries risk. Bikes can be damaged, stolen or idle, '
              'and earnings vary with demand. Never invest money you cannot '
              'afford to lose.',
              style: context.text.bodySmall
                  ?.copyWith(color: palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingState extends StatelessWidget {
  const _PendingState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.warningSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.hourglass_top_rounded,
                  size: 34, color: palette.warning),
            ),
            const SizedBox(height: 20),
            Text('Application received',
                style: context.text.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'We are reviewing your details. Once approved, Investor will '
              'become available in the menu and you can start funding bikes.',
              style: context.text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: () => context.go('/customer/home'),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}
