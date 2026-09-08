import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/booking/domain/entities/promo_model.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// Provider for all promos
final promosProvider = StreamProvider<List<PromoModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('promos')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => PromoModel.fromFirestore(d)).toList(),
      );
});

class AdminPromosScreen extends ConsumerWidget {
  const AdminPromosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(promosProvider);

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        title: Text(
          'Promo Codes',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.palette.brand,
        child: Icon(Icons.add, color: context.palette.surfaceBase),
        onPressed: () => _showCreateDialog(context, ref),
      ),
      body: promosAsync.when(
        data: (promos) {
          if (promos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer,
                    size: 48,
                    color: context.palette.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No promo codes yet',
                    style: TextStyle(color: context.palette.textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promos.length,
            itemBuilder: (_, i) => _buildPromoCard(context, ref, promos[i]),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.brand),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: context.palette.danger),
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCard(
    BuildContext context,
    WidgetRef ref,
    PromoModel promo,
  ) {
    final isValid = promo.isValid;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isValid
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : context.palette.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isValid
                  ? context.palette.brand.withValues(alpha: 0.15)
                  : context.palette.border,
            ),
            child: Icon(
              Icons.local_offer,
              color: isValid
                  ? context.palette.brand
                  : context.palette.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      promo.code,
                      style: TextStyle(
                        color: context.palette.onBrand,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isValid
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isValid ? 'Active' : 'Expired',
                        style: TextStyle(
                          color: isValid
                              ? const Color(0xFF4CAF50)
                              : context.palette.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  promo.discountType == DiscountType.flat
                      ? '₦${promo.amount.toStringAsFixed(0)} off'
                      : '${promo.amount.toStringAsFixed(0)}% off',
                  style: TextStyle(color: context.palette.brand, fontSize: 13),
                ),
                Text(
                  'Used ${promo.usedCount}/${promo.maxUses == 0 ? '∞' : promo.maxUses}',
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Toggle active
          Switch(
            value: promo.isActive,
            activeThumbColor: const Color(0xFF4CAF50),
            inactiveThumbColor: context.palette.textMuted,
            onChanged: (v) {
              ref
                  .read(firestoreProvider)
                  .collection('promos')
                  .doc(promo.id)
                  .update({'isActive': v});
            },
          ),
          // Delete
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: context.palette.danger,
              size: 20,
            ),
            onPressed: () {
              ref
                  .read(firestoreProvider)
                  .collection('promos')
                  .doc(promo.id)
                  .delete();
            },
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final codeC = TextEditingController();
    final amountC = TextEditingController();
    final maxUsesC = TextEditingController(text: '100');
    final minOrderC = TextEditingController(text: '0');
    var discountType = DiscountType.flat;
    var daysValid = 30;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: context.palette.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Promo Code',
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _dialogField(
                  context,
                  codeC,
                  'Promo Code (e.g. LAGOS50)',
                  TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                // Discount type
                Row(
                  children: [
                    _typeChip(
                      context,
                      'Flat (₦)',
                      DiscountType.flat,
                      discountType,
                      (v) {
                        setDialogState(() => discountType = v);
                      },
                    ),
                    const SizedBox(width: 8),
                    _typeChip(
                      context,
                      'Percent (%)',
                      DiscountType.percent,
                      discountType,
                      (v) {
                        setDialogState(() => discountType = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _dialogField(
                  context,
                  amountC,
                  discountType == DiscountType.flat
                      ? 'Amount (₦)'
                      : 'Percent (%)',
                  TextCapitalization.none,
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _dialogField(
                  context,
                  maxUsesC,
                  'Max Uses (0 = unlimited)',
                  TextCapitalization.none,
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _dialogField(
                  context,
                  minOrderC,
                  'Min Order Amount (₦)',
                  TextCapitalization.none,
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Valid for:',
                      style: TextStyle(
                        color: context.palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: daysValid,
                      dropdownColor: context.palette.surfaceRaised,
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontSize: 13,
                      ),
                      items: [7, 14, 30, 60, 90]
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text('$d days'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => daysValid = v ?? 30),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (codeC.text.trim().isEmpty ||
                          amountC.text.trim().isEmpty) {
                        return;
                      }

                      final now = DateTime.now();
                      await ref
                          .read(firestoreProvider)
                          .collection('promos')
                          .add(
                            PromoModel(
                              id: '',
                              code: codeC.text.trim().toUpperCase(),
                              discountType: discountType,
                              amount: double.tryParse(amountC.text.trim()) ?? 0,
                              minOrderAmount:
                                  double.tryParse(minOrderC.text.trim()) ?? 0,
                              maxUses: int.tryParse(maxUsesC.text.trim()) ?? 0,
                              expiresAt: now.add(Duration(days: daysValid)),
                              createdAt: now,
                            ).toFirestore(),
                          );

                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.brand,
                      foregroundColor: context.palette.surfaceBase,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(
    BuildContext context,
    TextEditingController c,
    String hint,
    TextCapitalization cap, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surfaceBase,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        textCapitalization: cap,
        style: TextStyle(color: context.palette.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.palette.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _typeChip(
    BuildContext context,
    String label,
    DiscountType type,
    DiscountType selected,
    ValueChanged<DiscountType> onTap,
  ) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.palette.brand.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? context.palette.brand
                : context.palette.textMuted,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? context.palette.brand
                : context.palette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
