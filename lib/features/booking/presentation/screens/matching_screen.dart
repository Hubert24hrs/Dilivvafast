import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_bid.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _field = Color(0xFFF3F4F6);
const _lime = Color(0xFFC1F11D);

/// Waiting for couriers, inDrive-style.
///
/// The customer's request is out with their offered fare. Couriers answer
/// with offers — at that price or a counter-price — which appear here live,
/// cheapest first, each with the courier's (server-verified) name, rating
/// and vehicle. The customer can accept one, decline one, or raise their own
/// offer to attract more. Accepting is atomic on the server: the first
/// accepted offer wins and the rest close.
class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({super.key, this.orderId});

  final String? orderId;

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  String? _busyDriverId;
  bool _raising = false;
  bool _cancelling = false;

  String get _orderId => widget.orderId ?? '';

  Future<void> _accept(CourierBid bid) async {
    setState(() => _busyDriverId = bid.driverId);
    final result = await ref
        .read(courierRepositoryProvider)
        .acceptBid(_orderId, bid.driverId);
    if (!mounted) return;
    setState(() => _busyDriverId = null);
    result.fold(
      (f) => _toast(f.message, error: true),
      (_) => context.go('/customer/track/$_orderId'),
    );
  }

  Future<void> _decline(CourierBid bid) async {
    final result = await ref
        .read(courierRepositoryProvider)
        .declineBid(_orderId, bid.driverId);
    if (!mounted) return;
    result.fold((f) => _toast(f.message, error: true), (_) {});
  }

  Future<void> _raise(CourierOrderModel order, double by) async {
    setState(() => _raising = true);
    final result = await ref
        .read(courierRepositoryProvider)
        .raiseOffer(_orderId, order.offeredFare + by);
    if (!mounted) return;
    setState(() => _raising = false);
    result.fold(
      (f) => _toast(f.message, error: true),
      (fare) => _toast('Your offer is now ₦${fare.toStringAsFixed(0)}'),
    );
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text('Couriers will stop seeing it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep waiting'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.palette.danger),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    final result = await ref
        .read(courierRepositoryProvider)
        .cancelOrder(_orderId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    result.fold(
      (f) => _toast(f.message, error: true),
      (_) => context.go('/customer/home'),
    );
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
    if (_orderId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Request not found.')));
    }

    final order = ref.watch(orderStreamProvider(_orderId)).value;
    final bids = ref.watch(orderBidsProvider(_orderId));

    // Assigned from anywhere — this device, another, or an admin — means
    // the waiting is over.
    ref.listen<AsyncValue<CourierOrderModel?>>(orderStreamProvider(_orderId), (
      _,
      next,
    ) {
      final o = next.value;
      if (o == null || !mounted) return;
      if (o.driverId != null && o.status != OrderStatus.pending) {
        context.go('/customer/track/$_orderId');
      } else if (o.status == OrderStatus.cancelled) {
        context.go('/customer/home');
      }
    });

    final offers = bids.value ?? const <CourierBid>[];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _ink,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Back to home',
          onPressed: () => context.go('/customer/home'),
        ),
        title: Text(
          offers.isEmpty ? 'Finding couriers' : 'Choose a courier',
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
      ),
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _YourOffer(
                  order: order,
                  raising: _raising,
                  onRaise: (by) => _raise(order, by),
                ),
                Expanded(
                  child: offers.isEmpty
                      ? const _Searching()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: offers.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _OfferCard(
                            bid: offers[i],
                            yourOffer: order.offeredFare,
                            busy: _busyDriverId == offers[i].driverId,
                            disabled: _busyDriverId != null,
                            onAccept: () => _accept(offers[i]),
                            onDecline: () => _decline(offers[i]),
                          ),
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _cancelling ? null : _cancel,
                        style: TextButton.styleFrom(
                          foregroundColor: context.palette.danger,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _cancelling ? 'Cancelling…' : 'Cancel request',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// The customer's current offer, with inDrive's quick "raise" buttons.
class _YourOffer extends StatelessWidget {
  const _YourOffer({
    required this.order,
    required this.raising,
    required this.onRaise,
  });

  final CourierOrderModel order;
  final bool raising;
  final ValueChanged<double> onRaise;

  @override
  Widget build(BuildContext context) {
    final bounds = order.recommendedFare > 0
        ? NegotiationBounds(recommended: order.recommendedFare)
        : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _field,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                order.vehicleType == CourierVehicle.bike
                    ? Icons.two_wheeler_rounded
                    : Icons.directions_car_filled_rounded,
                color: _ink,
              ),
              const SizedBox(width: 8),
              const Text('Your offer', style: TextStyle(color: _muted)),
              const Spacer(),
              Text(
                '₦${order.offeredFare.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.pickupAddress.split(',').first}  →  '
            '${order.dropoffAddress.split(',').first}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          const Text(
            'Raise your offer to get couriers faster',
            style: TextStyle(fontSize: 12.5, color: _muted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final by in const [100.0, 200.0, 500.0]) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        raising ||
                            (bounds != null &&
                                order.offeredFare + by > bounds.ceiling)
                        ? null
                        : () => onRaise(by),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '+₦${by.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (by != 500.0) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Searching extends StatelessWidget {
  const _Searching();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 3, color: _ink),
            ),
            SizedBox(height: 20),
            Text(
              'Sending your request to nearby couriers',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Offers will appear here. You choose who to go with.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// One courier's offer — inDrive's offer card.
class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.bid,
    required this.yourOffer,
    required this.busy,
    required this.disabled,
    required this.onAccept,
    required this.onDecline,
  });

  final CourierBid bid;
  final double yourOffer;
  final bool busy;
  final bool disabled;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final matchesYours = (bid.amount - yourOffer).abs() < 1;
    final name = bid.driverName ?? 'Courier';
    final vehicle = [
      if (bid.vehicleLabel != null)
        bid.vehicleLabel![0].toUpperCase() + bid.vehicleLabel!.substring(1),
      if (bid.vehiclePlate != null) bid.vehiclePlate!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _field,
                foregroundImage: bid.driverPhotoUrl != null
                    ? NetworkImage(bid.driverPhotoUrl!)
                    : null,
                child: Text(
                  name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF5B301),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (bid.driverRating ?? 0) > 0
                              ? '${bid.driverRating!.toStringAsFixed(2)} '
                                    '(${bid.driverTrips ?? 0})'
                              : 'New courier',
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                      ],
                    ),
                    if (vehicle.isNotEmpty)
                      Text(
                        vehicle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₦${bid.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  if (bid.etaMinutes != null)
                    Text(
                      '${bid.etaMinutes} min away',
                      style: const TextStyle(color: _muted, fontSize: 12.5),
                    ),
                  if (!matchesYours)
                    const Text(
                      'Counter-offer',
                      style: TextStyle(
                        color: Color(0xFFB54708),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: disabled ? null : onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: disabled ? null : onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: _ink,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _ink,
                          ),
                        )
                      : Text(
                          'Accept ₦${bid.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
