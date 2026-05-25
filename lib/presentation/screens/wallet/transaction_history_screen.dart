import 'package:fast_delivery/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Transaction History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: userId == null
          ? const Center(child: Text('Please login to view transactions'))
          : _buildTransactionList(ref, userId),
    );
  }

  Widget _buildTransactionList(WidgetRef ref, String userId) {
    final transactionsStream = ref.watch(databaseServiceProvider).getUserTransactions(userId);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: transactionsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return const Center(child: Text('No transactions yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final amount = tx['amount'] as double;
            final type = tx['type'] as String;
            final isDeposit = type == 'deposit';
            final date = tx['createdAt'] != null ? tx['createdAt'] as DateTime : DateTime.now();

            return Card(
              elevation: 0,
              color: Colors.grey[50],
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDeposit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  child: Icon(
                    isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isDeposit ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  tx['description'] ?? 'Transaction',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(DateFormat('MMM d, y • h:mm a').format(date)),
                trailing: Text(
                  '${isDeposit ? '+' : '-'}₦${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDeposit ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
