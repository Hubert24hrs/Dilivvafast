import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/booking/presentation/controllers/courier_booking_controller.dart';

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

  /// Render a promo's value from the fields PromoModel actually writes.
  ///
  /// This read `promoData['discountPercent']`, which no promo document has —
  /// the schema is `discountType` (`flat` | `percent`) plus `amount` — so
  /// every applied code announced "0% off".
  ///
  /// The figure shown here is indicative. The binding discount is computed and
  /// redeemed server-side by `onCourierCreated`.
  String _describeDiscount(Map<String, dynamic> promoData) {
    final amount = (promoData['amount'] as num?)?.toDouble() ?? 0;
    final isPercent = promoData['discountType'] == 'percent';
    if (amount <= 0) return 'A discount';
    return isPercent
        ? '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)}%'
        : '₦${amount.toStringAsFixed(0)}';
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

      if (!mounted) return;

      if (snap.docs.isEmpty) {
        setState(() => _errorText = 'Invalid or expired promo code');
        return;
      }

      final promoData = snap.docs.first.data();

      // Client-side expiry check. This is a convenience so the customer sees
      // a clear message; the authoritative check is server-side when the
      // discount is applied to an order — a promo accepted here is only an
      // intent, never a committed discount. See SECURITY.md, "Promotions".
      final expiresAt = (promoData['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        setState(() => _errorText = 'That promo code has expired');
        return;
      }

      ref.read(appliedPromoProvider.notifier).set(promoData);
      // The code has to reach the booking for the server to redeem it.
      // Applying used to stop at appliedPromoProvider, which nothing read,
      // so no order ever carried a promo code.
      ref.read(courierBookingControllerProvider.notifier).setPromoCode(code);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Promo code "$code" applied! '
            '${_describeDiscount(promoData)} off your next delivery.',
          ),
          backgroundColor: context.palette.success,
        ),
      );
      _codeCtrl.clear();
    } catch (e) {
      // Never render a raw backend exception into the UI.
      debugPrint('Promo validation failed: $e');
      if (!mounted) return;
      setState(() => _errorText = 'Could not validate that code right now.');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shown only while the booking still carries it; placing the order
    // resets the booking, and a used code should not look active.
    final pendingCode = ref.watch(
      courierBookingControllerProvider.select((b) => b.promoCode),
    );
    final appliedPromo = ref.watch(appliedPromoProvider);
    final activePromo =
        appliedPromo != null && appliedPromo['code'] == pendingCode
        ? appliedPromo
        : null;

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Promotions & Coupons'),
        backgroundColor: context.palette.surfaceRaised,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code Input Section
            Card(
              color: context.palette.surfaceRaised,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Promo Code',
                      style: TextStyle(
                        color: context.palette.textPrimary,
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
                            style: TextStyle(
                              color: context.palette.textPrimary,
                            ),
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
                            backgroundColor: context.palette.brand,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          child: _isChecking
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.palette.onBrand,
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

            if (activePromo != null) ...[
              const SizedBox(height: 20),
              Card(
                color: context.palette.success.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.palette.success),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.check_circle,
                    color: context.palette.success,
                  ),
                  title: Text(
                    'Active Code: ${activePromo['code']}',
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${_describeDiscount(activePromo)} discount applied to '
                    'next booking',
                    style: TextStyle(color: context.palette.textSecondary),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: context.palette.textSecondary,
                    ),
                    onPressed: () {
                      ref.read(appliedPromoProvider.notifier).set(null);
                      ref
                          .read(courierBookingControllerProvider.notifier)
                          .setPromoCode('');
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              'AVAILABLE PROMOTIONS',
              style: TextStyle(
                color: context.palette.textSecondary,
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
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No public promo codes available right now.\nCheck back soon!',
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
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final code = data['code'] ?? '';
                    final desc = data['description'] ?? 'Special discount';
                    final discount = _describeDiscount(data);

                    return Card(
                      color: context.palette.surfaceRaised,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.palette.brand.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.local_offer,
                            color: context.palette.brand,
                          ),
                        ),
                        title: Text(
                          code,
                          style: TextStyle(
                            color: context.palette.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$desc — Save $discount',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                          ),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () {
                            ref.read(appliedPromoProvider.notifier).set(data);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Promo "$code" applied!'),
                                backgroundColor: context.palette.success,
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
