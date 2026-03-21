import 'package:flutter/material.dart';
import 'package:fast_delivery/core/services/fare_calculator_service.dart';

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
      return _buildShimmer();
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
            const Color(0xFF1D1E33),
            const Color(0xFF1D1E33).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFF00F0FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Fare Breakdown',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _fareRow('Base fare', '₦${b.baseFare.toStringAsFixed(0)}'),
          _fareRow('Distance', '₦${b.distanceFare.toStringAsFixed(0)}'),
          if (b.weightSurcharge > 0)
            _fareRow('Weight surcharge', '₦${b.weightSurcharge.toStringAsFixed(0)}'),
          if (b.surgeMultiplier > 1.0)
            _fareRow(
              'Surge (${b.surgeMultiplier.toStringAsFixed(1)}x)',
              '',
              highlight: true,
            ),
          if (b.promoDiscount > 0)
            _fareRow(
              'Promo discount',
              '-₦${b.promoDiscount.toStringAsFixed(0)}',
              isDiscount: true,
            ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24, height: 1),
          ),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₦${b.totalFare.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
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
                color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📍 ${b.zoneName}',
                style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value,
      {bool highlight = false, bool isDiscount = false}) {
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
                  : Colors.white.withValues(alpha: 0.7),
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
                      : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00F0FF),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
