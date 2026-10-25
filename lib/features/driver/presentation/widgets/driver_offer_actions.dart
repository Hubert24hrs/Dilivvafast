import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_bid.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/features/driver/presentation/controllers/driver_route_controller.dart';

const _ink = Color(0xFF111827);
const _lime = Color(0xFFC1F11D);

/// A driver's side of the inDrive-style negotiation on one request.
///
/// Before offering: "Accept ₦X" at the customer's price, or one of three
/// counter-offers above it. After offering: the offer's live status —
/// waiting, declined (offer again), or accepted — with the option to
/// withdraw while the customer is still deciding.
///
/// Counter-offers are only ever above the customer's price, and capped at
/// the server's ceiling; firestore.rules rejects anything else regardless.
class DriverOfferActions extends ConsumerStatefulWidget {
  const DriverOfferActions({super.key, required this.order, this.onDismiss});

  final CourierOrderModel order;

  /// Hide this request from the list without making an offer.
  final VoidCallback? onDismiss;

  @override
  ConsumerState<DriverOfferActions> createState() => _DriverOfferActionsState();
}

class _DriverOfferActionsState extends ConsumerState<DriverOfferActions> {
  bool _sending = false;

  static const _counters = [200.0, 500.0, 1000.0];

  double get _customerOffer => widget.order.offeredFare > 0
      ? widget.order.offeredFare
      : widget.order.totalFare;

  double? get _ceiling => widget.order.recommendedFare > 0
      ? NegotiationBounds(recommended: widget.order.recommendedFare).ceiling
      : null;

  Future<void> _offer(double amount) async {
    setState(() => _sending = true);
    final error = await ref
        .read(driverRouteControllerProvider.notifier)
        .placeOffer(widget.order.id, amount);
    if (!mounted) return;
    setState(() => _sending = false);
    _toast(
      error ??
          'Offer of ₦${amount.toStringAsFixed(0)} sent. '
              'The customer is choosing.',
      error: error != null,
    );
  }

  Future<void> _withdraw() async {
    setState(() => _sending = true);
    final error = await ref
        .read(driverRouteControllerProvider.notifier)
        .withdrawOffer(widget.order.id);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) _toast(error, error: true);
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? context.palette.danger : _ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(myBidProvider(widget.order.id)).value;

    if (mine != null && mine.status != BidStatus.withdrawn) {
      return _OfferStatus(
        orderId: widget.order.id,
        bid: mine,
        busy: _sending,
        onWithdraw: _withdraw,
        onOfferAgain: () => _offer(_customerOffer),
      );
    }

    final ceiling = _ceiling;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (widget.onDismiss != null) ...[
              OutlinedButton(
                onPressed: _sending ? null : widget.onDismiss,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.palette.textSecondary,
                  side: BorderSide(color: context.palette.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Skip'),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton(
                onPressed: _sending ? null : () => _offer(_customerOffer),
                style: FilledButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: _ink,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _ink,
                        ),
                      )
                    : Text(
                        'Accept for ₦${_customerOffer.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Or offer your price',
          style: TextStyle(
            fontSize: 12.5,
            color: context.palette.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final add in _counters) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _sending ||
                          (ceiling != null && _customerOffer + add > ceiling)
                      ? null
                      : () => _offer(_customerOffer + add),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.palette.textPrimary,
                    side: BorderSide(color: context.palette.border),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '₦${(_customerOffer + add).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (add != _counters.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _OfferStatus extends StatelessWidget {
  const _OfferStatus({
    required this.orderId,
    required this.bid,
    required this.busy,
    required this.onWithdraw,
    required this.onOfferAgain,
  });

  final String orderId;
  final CourierBid bid;
  final bool busy;
  final VoidCallback onWithdraw;
  final VoidCallback onOfferAgain;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (icon, colour, text) = switch (bid.status) {
      BidStatus.accepted => (
        Icons.check_circle_rounded,
        palette.success,
        'Accepted at ₦${bid.amount.toStringAsFixed(0)} — head to pickup',
      ),
      BidStatus.declined => (
        Icons.cancel_outlined,
        palette.danger,
        'The customer chose another offer',
      ),
      _ => (
        Icons.hourglass_top_rounded,
        palette.warning,
        'Your offer: ₦${bid.amount.toStringAsFixed(0)} · waiting for the customer',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colour),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (bid.status == BidStatus.accepted)
            FilledButton(
              onPressed: () => context.push('/driver/active/$orderId'),
              style: FilledButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: _ink,
              ),
              child: const Text('Open job'),
            )
          else if (bid.status == BidStatus.open)
            TextButton(
              onPressed: busy ? null : onWithdraw,
              child: const Text('Withdraw'),
            )
          else if (bid.status == BidStatus.declined)
            TextButton(
              onPressed: busy ? null : onOfferAgain,
              child: const Text('Offer again'),
            ),
        ],
      ),
    );
  }
}
