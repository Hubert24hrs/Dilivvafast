import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';

class AppliedPromoNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void set(Map<String, dynamic>? promo) => state = promo;
}

final appliedPromoProvider =
    NotifierProvider<AppliedPromoNotifier, Map<String, dynamic>?>(
      AppliedPromoNotifier.new,
    );

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  final _codeCtrl = TextEditingController();
  bool _isChecking = false;
  String? _errorText;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    try {
      final snap = await ref
          .read(firestoreProvider)
          .collection('promos')
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) {
        setState(() => _errorText = 'Invalid or expired promo code');
        return;
      }

      final promoData = snap.docs.first.data();
      ref.read(appliedPromoProvider.notifier).set(promoData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Promo code "$code" applied! ${promoData['discountPercent'] ?? 0}% off your next delivery.',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _codeCtrl.clear();
      }
    } catch (e) {
      setState(() => _errorText = 'Error validating code: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appliedPromo = ref.watch(appliedPromoProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Promotions & Coupons'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code Input Section
            Card(
              color: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Promo Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'e.g. DILIVVA10',
                              errorText: _errorText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isChecking ? null : _applyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          child: _isChecking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (appliedPromo != null) ...[
              const SizedBox(height: 20),
              Card(
                color: AppTheme.successColor.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.successColor),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                  ),
                  title: Text(
                    'Active Code: ${appliedPromo['code']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${appliedPromo['discountPercent'] ?? 0}% discount applied to next booking',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      ref.read(appliedPromoProvider.notifier).set(null);
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text(
              'AVAILABLE PROMOTIONS',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: ref
                  .watch(firestoreProvider)
                  .collection('promos')
                  .where('isActive', isEqualTo: true)
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
                  return const Card(
                    color: AppTheme.surfaceColor,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No public promo codes available right now.\nCheck back soon!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final code = data['code'] ?? '';
                    final desc = data['description'] ?? 'Special discount';
                    final discount = data['discountPercent'] ?? 0;

                    return Card(
                      color: AppTheme.surfaceColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_offer,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$desc — Save $discount%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () {
                            ref.read(appliedPromoProvider.notifier).set(data);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Promo "$code" applied!'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          },
                          child: const Text('Use Code'),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
