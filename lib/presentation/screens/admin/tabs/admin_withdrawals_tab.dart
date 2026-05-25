import 'package:fast_delivery/core/models/investor_earnings_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminWithdrawalsTab extends ConsumerStatefulWidget {
  const AdminWithdrawalsTab({super.key});

  @override
  ConsumerState<AdminWithdrawalsTab> createState() => _AdminWithdrawalsTabState();
}

class _AdminWithdrawalsTabState extends ConsumerState<AdminWithdrawalsTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InvestorWithdrawalModel>>(
      stream: ref.watch(adminServiceProvider).getPendingWithdrawals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final withdrawals = snapshot.data ?? [];

        if (withdrawals.isEmpty) {
          return const Center(
            child: Text(
              'No pending withdrawals',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: withdrawals.length,
          itemBuilder: (context, index) {
            return _buildWithdrawalCard(withdrawals[index]);
          },
        );
      },
    );
  }

  Widget _buildWithdrawalCard(InvestorWithdrawalModel withdrawal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Withdrawal Request',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₦${withdrawal.amount.toStringAsFixed(2)}',
                        style: TextStyle(color: AppTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'PENDING',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              Text(
                'Bank Details',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${withdrawal.bankName} - ${withdrawal.accountNumber}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                withdrawal.accountName,
                style: const TextStyle(color: Colors.white70),
              ),
               const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectWithdrawal(withdrawal),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveWithdrawal(withdrawal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('PAY (MANUAL)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveWithdrawal(InvestorWithdrawalModel withdrawal) async {
    // In production, this would integrate with Paystack Transfers API properly
    // For now, we simulate manual approval
    try {
      await ref.read(adminServiceProvider).approveWithdrawal(withdrawal.id, 'MANUAL-PAYMENT-${DateTime.now().millisecondsSinceEpoch}');
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal marked as paid')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectWithdrawal(InvestorWithdrawalModel withdrawal) async {
    try {
      await ref.read(adminServiceProvider).rejectWithdrawal(withdrawal.id, 'Rejected by Admin');
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal rejected and refunded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
