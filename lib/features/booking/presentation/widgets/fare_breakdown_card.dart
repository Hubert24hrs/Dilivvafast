import 'package:flutter/material.dart';
import 'package:dilivvafast/core/services/fare_calculator_service.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// Itemized fare breakdown card showing base fare, distance, surge, promo, etc.
class FareBreakdownCard extends StatelessWidget {
  const FareBreakdownCard({
    super.key,
    required this.breakdown,
    this.isLoading = false,
  });

  final FareBreakdown? breakdown;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildShimmer(context);
    }
    if (breakdown == null) {
      return const SizedBox.shrink();
    }

    final b = breakdown!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.palette.surfaceRaised,
            context.palette.surfaceRaised.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.brand.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: context.palette.brand, size: 20),
              SizedBox(width: 8),
              Text(
                'Fare Breakdown',
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _fareRow(context, 'Base fare', '₦${b.baseFare.toStringAsFixed(0)}'),
          _fareRow(
            context,
            'Distance',
            '₦${b.distanceFare.toStringAsFixed(0)}',
          ),
          if (b.weightSurcharge > 0)
            _fareRow(
              context,
              'Weight surcharge',
              '₦${b.weightSurcharge.toStringAsFixed(0)}',
            ),
          if (b.surgeMultiplier > 1.0)
            _fareRow(
              context,
              'Surge (${b.surgeMultiplier.toStringAsFixed(1)}x)',
              '',
              highlight: true,
            ),
          if (b.promoDiscount > 0)
            _fareRow(
              context,
              'Promo discount',
              '-₦${b.promoDiscount.toStringAsFixed(0)}',
              isDiscount: true,
            ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: context.palette.textMuted, height: 1),
          ),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₦${b.totalFare.toStringAsFixed(0)}',
                style: TextStyle(
                  color: context.palette.brand,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (b.zoneName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.palette.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📍 ${b.zoneName}',
                style: TextStyle(color: context.palette.brand, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fareRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight
                  ? const Color(0xFFFF9800)
                  : context.palette.textPrimary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDiscount
                  ? const Color(0xFF4CAF50)
                  : highlight
                  ? const Color(0xFFFF9800)
                  : context.palette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: context.palette.brand,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
