import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/payment/domain/entities/transaction_model.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        elevation: 0,
        title: Text(
          'Wallet',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance card
            _buildBalanceCard(context, balanceAsync),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                _actionButton(
                  'Fund Wallet',
                  Icons.add_circle_outline,
                  const Color(0xFF4CAF50),
                  () => context.push('/wallet/top-up'),
                ),
                const SizedBox(width: 12),
                _actionButton(
                  'Withdraw',
                  Icons.arrow_downward,
                  const Color(0xFFFF9800),
                  () => _showWithdrawDialog(context, ref),
                ),
                const SizedBox(width: 12),
                _actionButton(
                  'Transfer',
                  Icons.swap_horiz,
                  const Color(0xFF2196F3),
                  () {},
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Transactions list
            Text(
              'Recent Transactions',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            transactionsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: context.palette.brand),
              ),
              error: (e, _) => Text(
                'Error: $e',
                style: TextStyle(color: context.palette.danger),
              ),
              data: (txns) {
                if (txns.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: context.palette.surfaceRaised,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: context.palette.textMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: context.palette.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: txns
                      .map((tx) => _buildTransactionTile(context, tx))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    AsyncValue<double> balanceAsync,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: TextStyle(color: context.palette.textPrimary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          balanceAsync.when(
            loading: () => Text(
              '...',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 32,
              ),
            ),
            error: (_, _) => Text(
              '₦0.00',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 32,
              ),
            ),
            data: (balance) => Text(
              '₦${balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.palette.textMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Color(0xFF4CAF50), size: 14),
                SizedBox(width: 4),
                Text(
                  'Secured by Paystack',
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel tx) {
    final isCredit =
        tx.type == TransactionType.deliveryEarning ||
        tx.type == TransactionType.topUp ||
        tx.type == TransactionType.promoCredit ||
        tx.type == TransactionType.referralBonus ||
        tx.type == TransactionType.investorEarning;

    final icon = switch (tx.type) {
      TransactionType.deliveryEarning => Icons.arrow_downward,
      TransactionType.deliveryPayment => Icons.arrow_upward,
      TransactionType.topUp => Icons.add_circle,
      TransactionType.withdrawal => Icons.remove_circle,
      TransactionType.promoCredit => Icons.replay,
      TransactionType.referralBonus => Icons.card_giftcard,
      TransactionType.investment => Icons.trending_up,
      TransactionType.hpRepayment => Icons.payments,
      TransactionType.investorEarning => Icons.percent,
    };

    final color = isCredit ? const Color(0xFF4CAF50) : const Color(0xFFE91E63);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(tx.createdAt),
                  style: TextStyle(
                    color: context.palette.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₦${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showWithdrawDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final bankController = TextEditingController();
    final accountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: context.palette.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Withdraw Funds',
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: bankController,
                style: TextStyle(color: context.palette.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Bank Name',
                  labelStyle: TextStyle(color: context.palette.textSecondary),
                  filled: true,
                  fillColor: context.palette.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accountController,
                style: TextStyle(color: context.palette.textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Account Number',
                  labelStyle: TextStyle(color: context.palette.textSecondary),
                  filled: true,
                  fillColor: context.palette.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                style: TextStyle(color: context.palette.textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₦)',
                  labelStyle: TextStyle(color: context.palette.textSecondary),
                  filled: true,
                  fillColor: context.palette.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    if (amount == null || amount < 500) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Minimum withdrawal is ₦500'),
                          backgroundColor: context.palette.danger,
                        ),
                      );
                      return;
                    }
                    // Submit withdrawal request
                    try {
                      final user = ref.read(currentUserProvider).value;
                      if (user == null) return;
                      await ref
                          .read(firestoreProvider)
                          .collection('withdrawal_requests')
                          .add({
                            'userId': user.uid,
                            'amount': amount,
                            'bankName': bankController.text.trim(),
                            'accountNumber': accountController.text.trim(),
                            'status': 'pending',
                            'createdAt': DateTime.now().toIso8601String(),
                          });
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Withdrawal request submitted'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: context.palette.danger,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: context.palette.onBrand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Request Withdrawal',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
