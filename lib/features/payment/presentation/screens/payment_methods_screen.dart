import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';

class DefaultPaymentMethodNotifier extends Notifier<String> {
  @override
  String build() => 'wallet';

  void set(String method) => state = method;
}

final defaultPaymentMethodProvider =
    NotifierProvider<DefaultPaymentMethodNotifier, String>(
      DefaultPaymentMethodNotifier.new,
    );

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    final walletBalance = ref.watch(walletBalanceProvider).value ?? 0.0;
    final selectedMethod = ref.watch(defaultPaymentMethodProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'SELECT DEFAULT PAYMENT METHOD',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Wallet Card
          Card(
            color: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selectedMethod == 'wallet'
                    ? AppTheme.primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              onTap: () {
                ref.read(defaultPaymentMethodProvider.notifier).set('wallet');
              },
              leading: const Icon(
                Icons.account_balance_wallet,
                color: AppTheme.primaryColor,
                size: 32,
              ),
              title: const Text(
                'Dilivvafast Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Balance: ₦${walletBalance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: selectedMethod == 'wallet'
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                  : const Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.white38,
                    ),
            ),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SAVED CARDS (PAYSTACK)',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Card tokenization is completed securely upon your next wallet top-up or delivery payment via Paystack.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Card'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          uid == null
              ? const SizedBox.shrink()
              : StreamBuilder<QuerySnapshot>(
                  stream: ref
                      .watch(firestoreProvider)
                      .collection('users')
                      .doc(uid)
                      .collection('payment_methods')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Card(
                        color: AppTheme.surfaceColor,
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No saved cards yet. Cards used during Paystack payments will be saved here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final cardId = d.id;
                        final last4 = data['last4'] ?? '****';
                        final brand = data['brand'] ?? 'Card';
                        final isSelected = selectedMethod == cardId;

                        return Card(
                          color: AppTheme.surfaceColor,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              ref
                                  .read(defaultPaymentMethodProvider.notifier)
                                  .set(cardId);
                            },
                            leading: const Icon(
                              Icons.credit_card,
                              color: Colors.white,
                            ),
                            title: Text(
                              '$brand ending in $last4',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primaryColor,
                                  )
                                : const Icon(
                                    Icons.radio_button_unchecked,
                                    color: Colors.white38,
                                  ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
