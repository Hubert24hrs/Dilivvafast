import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  final _amountController = TextEditingController();
  bool _isProcessing = false;
  int? _selectedPreset;

  static const _presets = [1000, 2000, 5000, 10000, 20000, 50000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Fund Wallet',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.palette.brand.withValues(alpha: 0.12),
                    context.palette.brand.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.palette.brand.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Balance',
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Was hardcoded to ₦0.00, so the screen told every customer
                  // their wallet was empty regardless of the real balance.
                  Text(
                    '₦${(ref.watch(currentUserProvider).value?.walletBalance ?? 0).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: context.palette.onBrand,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Amount input
            Text(
              'Enter Amount',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.palette.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.palette.border),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (_) => setState(() => _selectedPreset = null),
                decoration: InputDecoration(
                  prefixText: '₦ ',
                  prefixStyle: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: context.palette.textMuted,
                    fontSize: 24,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Preset amounts
            Text(
              'Quick Select',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _presets.map((amount) {
                final isSelected = _selectedPreset == amount;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPreset = amount;
                      _amountController.text = amount.toString();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.palette.brand.withValues(alpha: 0.15)
                          : context.palette.surfaceRaised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? context.palette.brand
                            : context.palette.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '₦${_formatAmount(amount)}',
                      style: TextStyle(
                        color: isSelected
                            ? context.palette.brand
                            : context.palette.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Payment method
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.palette.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.palette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00C853).withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      color: Color(0xFF00C853),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paystack',
                          style: TextStyle(
                            color: context.palette.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Card, Bank Transfer, USSD',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00C853),
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayment,
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
                child: _isProcessing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: context.palette.surfaceBase,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Security note
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 14, color: context.palette.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Secured by Paystack',
                    style: TextStyle(
                      color: context.palette.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toString();
  }

  Future<void> _handlePayment() async {
    final amountStr = _amountController.text.trim();
    final amount = double.tryParse(amountStr);
    if (amount == null || amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum amount is ₦100'),
          backgroundColor: context.palette.danger,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('Not authenticated');

      final result = await ref
          .read(paymentRepositoryProvider)
          .initializePayment(
            amount: amount,
            email: user.email,
            reference: '', // minted server-side
          );

      // `fold` is synchronous: the previous version passed an async callback
      // into it and never awaited the result, so the browser launch and the
      // dialog raced the `finally` block below.
      final failure = result.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: context.palette.danger,
            ),
          );
        }
        return;
      }

      final init = result.getOrElse((_) => throw StateError('unreachable'));
      final uri = Uri.parse(init.authorizationUrl);

      if (!await canLaunchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not open the payment page.'),
              backgroundColor: context.palette.danger,
            ),
          );
        }
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // The webhook credits the wallet on its own, but the customer is
      // standing here now — offer an explicit check so they get immediate
      // confirmation. Verification is idempotent, so this is safe to repeat.
      if (mounted) {
        await _showPendingDialog(init.reference);
      }
    } catch (e, stack) {
      debugPrint('Top-up failed: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Something went wrong. Please try again.'),
            backgroundColor: context.palette.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmPayment(String reference) async {
    setState(() => _isProcessing = true);
    final result = await ref
        .read(paymentRepositoryProvider)
        .verifyPayment(reference);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: context.palette.danger,
        ),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Wallet funded successfully.'),
            backgroundColor: context.palette.success,
          ),
        );
        context.pop();
      },
    );
  }

  Future<void> _showPendingDialog(String reference) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.palette.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.palette.brand.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.hourglass_top,
                  color: context.palette.brand,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Payment Processing',
                style: TextStyle(
                  color: context.palette.onBrand,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Finish paying in the browser, then come back and tap '
                '"I have paid" to credit your wallet straight away.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _confirmPayment(reference);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.brand,
                    foregroundColor: context.palette.surfaceBase,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'I have paid',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(color: context.palette.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
