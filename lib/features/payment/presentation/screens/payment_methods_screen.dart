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
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: context.palette.surfaceRaised,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'SELECT DEFAULT PAYMENT METHOD',
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Wallet Card
          Card(
            color: context.palette.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selectedMethod == 'wallet'
                    ? context.palette.brand
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              onTap: () {
                ref.read(defaultPaymentMethodProvider.notifier).set('wallet');
              },
              leading: Icon(
                Icons.account_balance_wallet,
                color: context.palette.brand,
                size: 32,
              ),
              title: Text(
                'Dilivvafast Wallet',
                style: TextStyle(
                  color: context.palette.onBrand,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Balance: ₦${walletBalance.toStringAsFixed(2)}',
                style: TextStyle(color: context.palette.textSecondary),
              ),
              trailing: selectedMethod == 'wallet'
                  ? Icon(Icons.check_circle, color: context.palette.brand)
                  : Icon(
                      Icons.radio_button_unchecked,
                      color: context.palette.textMuted,
                    ),
            ),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SAVED CARDS (PAYSTACK)',
                style: TextStyle(
                  color: context.palette.textSecondary,
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
                      return Center(
                        child: CircularProgressIndicator(
                          color: context.palette.brand,
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Card(
                        color: context.palette.surfaceRaised,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No saved cards yet. Cards used during Paystack payments will be saved here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.palette.textSecondary,
                              ),
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
                          color: context.palette.surfaceRaised,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? context.palette.brand
                                  : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              ref
                                  .read(defaultPaymentMethodProvider.notifier)
                                  .set(cardId);
                            },
                            leading: Icon(
                              Icons.credit_card,
                              color: context.palette.onBrand,
                            ),
                            title: Text(
                              '$brand ending in $last4',
                              style: TextStyle(
                                color: context.palette.textPrimary,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: context.palette.brand,
                                  )
                                : Icon(
                                    Icons.radio_button_unchecked,
                                    color: context.palette.textMuted,
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
