import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dilivvafast/core/models/rider_payment_status.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class RiderPayNowScreen extends ConsumerStatefulWidget {
  const RiderPayNowScreen({super.key});

  @override
  ConsumerState<RiderPayNowScreen> createState() => _RiderPayNowScreenState();
}

class _RiderPayNowScreenState extends ConsumerState<RiderPayNowScreen> {
  bool _isProcessing = false;

  Future<void> _initiatePayment(RiderPaymentStatus status) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final paystackService = ref.read(paystackServiceProvider);
      
      await paystackService.chargeCard(
        context: context,
        amount: status.accumulatedDebt,
        email: user.email ?? '${user.uid}@dilivvafast.app',
        reference: 'RIDER-${user.uid}-${DateTime.now().millisecondsSinceEpoch}',
        onSuccess: (refId) async {
          await ref
              .read(riderPaymentServiceProvider)
              .clearDebtAndUnblock(user.uid);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '✅ Payment successful! You can now accept rides.'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
            context.pop();
          }
        },
        onCancel: (refId) {
          if (mounted) setState(() => _isProcessing = false);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(riderPaymentStatusProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: Colors.white,
        title: const Text('Pay Outstanding Fee',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: statusAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, _) => Center(child: Text('Error: $e',
            style: const TextStyle(color: Colors.white))),
        data: (status) => _buildContent(status),
      ),
    );
  }

  Widget _buildContent(RiderPaymentStatus status) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Status icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.15),
                border: Border.all(color: Colors.red, width: 3),
              ),
              child: const Icon(Icons.lock_clock,
                  color: Colors.red, size: 48),
            ),
            const SizedBox(height: 24),

            Text(
              '🔴 Rider Status: Blocked',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              status.debtSummary,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Breakdown card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fee Breakdown',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  ...status.lastRideFares.asMap().entries.map((entry) {
                    final i = entry.key + 1;
                    final fare = entry.value;
                    final fee = fare * 0.10;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ride $i (₦${fare.toStringAsFixed(0)})',
                              style:
                                  const TextStyle(color: Colors.white60)),
                          Text('₦${fee.toStringAsFixed(0)} (10%)',
                              style:
                                  const TextStyle(color: Colors.white)),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Due',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(
                        '₦${status.accumulatedDebt.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You cannot accept new requests until this fee is paid. '
                      'Your status resets automatically after successful payment.',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // PAY NOW button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _initiatePayment(status),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.payment),
                label: Text(
                  _isProcessing
                      ? 'Processing...'
                      : 'Pay ₦${status.accumulatedDebt.toStringAsFixed(0)} Now',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Secured by Paystack 🔒',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
