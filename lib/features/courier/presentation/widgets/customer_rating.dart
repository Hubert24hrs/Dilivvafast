import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _star = Color(0xFFF5B301);

/// "★ 4.8 (12)" — the customer's rating from couriers, shown on a request
/// before a courier makes an offer, as inDrive shows a passenger's rating.
class CustomerRatingBadge extends StatelessWidget {
  const CustomerRatingBadge({super.key, required this.order});
  final CourierOrderModel order;

  @override
  Widget build(BuildContext context) {
    final avg = order.customerRatingAvg ?? 0;
    final rated = order.customerRatingCount > 0 && avg > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          rated ? Icons.star_rounded : Icons.person_outline_rounded,
          size: 16,
          color: rated ? _star : _muted,
        ),
        const SizedBox(width: 4),
        Text(
          rated
              ? '${avg.toStringAsFixed(1)} (${order.customerRatingCount})'
              : 'New customer',
          style: const TextStyle(
            color: _muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// After a delivery, the courier rates the customer (1–5 stars), once.
class RateCustomerRow extends ConsumerStatefulWidget {
  const RateCustomerRow({super.key, required this.order});
  final CourierOrderModel order;

  @override
  ConsumerState<RateCustomerRow> createState() => _RateCustomerRowState();
}

class _RateCustomerRowState extends ConsumerState<RateCustomerRow> {
  int? _sent;
  bool _busy = false;

  Future<void> _rate(int stars) async {
    setState(() => _busy = true);
    final result = await ref
        .read(courierRepositoryProvider)
        .rateCustomer(widget.order.id, stars);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: context.palette.danger,
        ),
      ),
      (_) => setState(() => _sent = stars),
    );
  }

  @override
  Widget build(BuildContext context) {
    final given = widget.order.customerRatingByCourier ?? _sent;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              given == null ? 'Rate the customer' : 'You rated the customer',
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
          for (var i = 1; i <= 5; i++)
            given == null
                ? IconButton(
                    tooltip:
                        'Rate the customer $i '
                        'star${i == 1 ? '' : 's'}',
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy ? null : () => _rate(i),
                    icon: const Icon(
                      Icons.star_outline_rounded,
                      color: _star,
                      size: 28,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i <= given
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: _star,
                      size: 24,
                    ),
                  ),
        ],
      ),
    );
  }
}
