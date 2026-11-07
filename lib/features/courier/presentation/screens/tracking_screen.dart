import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:dilivvafast/core/constants/app_constants.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/utils/friendly_error.dart';
import 'package:dilivvafast/core/presentation/widgets/live_map.dart';
import 'package:dilivvafast/core/presentation/widgets/reason_sheet.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_bid.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/features/courier/presentation/widgets/pay_courier_card.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _field = Color(0xFFF3F4F6);
const _lime = Color(0xFFC1F11D);

/// The customer's live delivery, laid out after inDrive's trip screen.
///
/// The map with the courier's live position fills the top. The sheet below
/// leads with what is happening now ("Your courier has arrived"), then who is
/// coming — name, rating, vehicle and plate from their verified offer — the
/// price, chat / share / safety, the route, and cancelling while that is
/// still possible (until the courier has the package).
///
/// If the courier drops the job before pickup, the request goes back to
/// pending (courierCancelJob) and this screen hands over to the offers screen.
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  bool _cancelling = false;

  Future<void> _cancel(CourierOrderModel order) async {
    final reason = await showReasonSheet(
      context,
      title: 'Why do you want to cancel?',
      message: order.status == OrderStatus.pending
          ? null
          : 'Your courier will be told straight away.',
      reasons: customerCancelReasons,
      confirmLabel: 'Cancel delivery',
    );
    if (reason == null || !mounted) return;
    setState(() => _cancelling = true);
    final result = await ref
        .read(courierRepositoryProvider)
        .cancelOrder(order.id, reason: reason);
    if (!mounted) return;
    setState(() => _cancelling = false);
    result.fold(
      (f) => _toast(f.message, error: true),
      (_) => _toast('Delivery cancelled'),
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
    final orderAsync = ref.watch(orderStreamProvider(widget.orderId));

    // The courier dropped the job: it is back out to other couriers.
    ref.listen<AsyncValue<CourierOrderModel?>>(
      orderStreamProvider(widget.orderId),
      (prev, next) {
        final was = prev?.value;
        final now = next.value;
        if (now == null || was == null || !mounted) return;
        if (was.status != OrderStatus.pending &&
            now.status == OrderStatus.pending) {
          _toast('Your courier cancelled. Finding you another one…');
          context.go('/matching/${now.id}');
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              friendlyError(e),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.danger),
            ),
          ),
        ),
        data: (order) => order == null
            ? const Center(
                child: Text('Order not found', style: TextStyle(color: _muted)),
              )
            : _TripView(
                order: order,
                cancelling: _cancelling,
                onCancel: () => _cancel(order),
              ),
      ),
    );
  }
}

class _TripView extends StatelessWidget {
  const _TripView({
    required this.order,
    required this.cancelling,
    required this.onCancel,
  });

  final CourierOrderModel order;
  final bool cancelling;
  final VoidCallback onCancel;

  bool get _active => const [
    OrderStatus.accepted,
    OrderStatus.arrived,
    OrderStatus.pickedUp,
    OrderStatus.inTransit,
  ].contains(order.status);

  bool get _canCancel => const [
    OrderStatus.pending,
    OrderStatus.accepted,
    OrderStatus.arrived,
  ].contains(order.status);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final mapHeight = media.size.height * 0.40;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: mapHeight + 28,
          child: _TrackingMap(order: order),
        ),
        Positioned(
          top: media.padding.top + 10,
          left: 14,
          child: _MapButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/customer/home'),
          ),
        ),
        Positioned(
          top: media.padding.top + 10,
          right: 14,
          child: _MapButton(
            icon: Icons.shield_outlined,
            tooltip: 'Safety',
            onTap: () => context.push('/safety'),
          ),
        ),
        Positioned.fill(
          top: mapHeight,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 16,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                media.padding.bottom + 16,
              ),
              children: [
                _StatusHeadline(order: order),
                const SizedBox(height: 14),
                _Progress(status: order.status),
                const SizedBox(height: 16),
                // Paying the courier directly: cash or a bank transfer.
                if (showPayCourier(order)) ...[
                  PayCourierCard(order: order),
                  const SizedBox(height: 12),
                ],
                // Then rating, once delivered, as in inDrive.
                if (order.status == OrderStatus.delivered &&
                    order.rating == null) ...[
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/rate/${order.id}'),
                      icon: const Icon(Icons.star_rounded),
                      label: const Text('Rate your courier'),
                      style: _limeButton,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (order.status == OrderStatus.delivered &&
                    order.rating != null)
                  _RatedNote(rating: order.rating!),
                if (order.driverId != null)
                  _CourierCard(order: order, driverId: order.driverId!),
                if (order.status == OrderStatus.pending) ...[
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => context.go('/matching/${order.id}'),
                      style: _limeButton,
                      child: const Text('See courier offers'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _Actions(order: order, active: _active),
                const SizedBox(height: 16),
                _RouteCard(order: order),
                const SizedBox(height: 12),
                _DetailsCard(order: order),
                const SizedBox(height: 8),
                if (_canCancel)
                  TextButton(
                    onPressed: cancelling ? null : onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: context.palette.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      cancelling ? 'Cancelling…' : 'Cancel delivery',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final _limeButton = FilledButton.styleFrom(
  backgroundColor: _lime,
  foregroundColor: _ink,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
);

// ── Headline ─────────────────────────────────────────────────────────────────

/// What is happening right now, in one line, as inDrive leads with.
(String, String) headlineFor(CourierOrderModel order) {
  final eta = order.estimatedDurationMin > 0
      ? ' · about ${order.estimatedDurationMin} min'
      : '';
  return switch (order.status) {
    OrderStatus.pending => (
      'Looking for a courier',
      'Offers are coming in — choose one to continue.',
    ),
    OrderStatus.accepted => (
      'Your courier is on the way',
      'Heading to the pickup point',
    ),
    OrderStatus.arrived => (
      'Your courier has arrived',
      'Meet them at the pickup point with the package',
    ),
    OrderStatus.pickedUp => (
      'Package collected',
      'Your courier is starting the delivery',
    ),
    OrderStatus.inTransit => (
      'On the way to ${order.recipientName}',
      '${order.estimatedDistanceKm.toStringAsFixed(1)} km$eta',
    ),
    OrderStatus.delivered => ('Delivered', 'Thanks for using Dilivvafast'),
    OrderStatus.cancelled => (
      'Delivery cancelled',
      order.cancelReason ?? 'This request was cancelled.',
    ),
    OrderStatus.failed => (
      'Delivery not completed',
      'Contact support from the Help Centre for help.',
    ),
  };
}

class _StatusHeadline extends StatelessWidget {
  const _StatusHeadline({required this.order});
  final CourierOrderModel order;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = headlineFor(order);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14.5, color: _muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _field,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            order.trackingCode,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Accepted → arrived → picked up → on the way → delivered, as one bar.
class _Progress extends StatelessWidget {
  const _Progress({required this.status});
  final OrderStatus status;

  static const _steps = [
    (OrderStatus.accepted, 'Accepted'),
    (OrderStatus.arrived, 'Arrived'),
    (OrderStatus.pickedUp, 'Picked up'),
    (OrderStatus.inTransit, 'On the way'),
    (OrderStatus.delivered, 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled || status == OrderStatus.failed) {
      return const SizedBox.shrink();
    }
    final reached = _steps.indexWhere((s) => s.$1 == status);
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < _steps.length; i++) ...[
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= reached ? _lime : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i < _steps.length - 1) const SizedBox(width: 4),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < _steps.length; i++)
              Expanded(
                child: Text(
                  _steps[i].$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: i == reached ? _ink : _muted,
                    fontWeight: i == reached
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Courier ──────────────────────────────────────────────────────────────────

class _CourierCard extends ConsumerWidget {
  const _CourierCard({required this.order, required this.driverId});
  final CourierOrderModel order;
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bid = ref
        .watch(assignedCourierProvider((orderId: order.id, driverId: driverId)))
        .value;
    final name = bid?.driverName ?? 'Your courier';
    final vehicle = _vehicleLine(bid);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: _field,
            foregroundImage: bid?.driverPhotoUrl != null
                ? NetworkImage(bid!.driverPhotoUrl!)
                : null,
            child: Text(
              name.characters.first.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
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
                    Flexible(
                      child: Text(
                        (bid?.driverRating ?? 0) > 0
                            ? '${bid!.driverRating!.toStringAsFixed(2)} '
                                  '(${bid.driverTrips ?? 0})'
                            : 'New courier',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
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
          Text(
            '₦${order.totalFare.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  String _vehicleLine(CourierBid? bid) {
    if (bid == null) return '';
    final label = bid.vehicleLabel;
    return [
      if (label != null && label.isNotEmpty)
        label[0].toUpperCase() + label.substring(1),
      if (bid.vehiclePlate != null) bid.vehiclePlate!,
    ].join(' · ');
  }
}

// ── Actions ──────────────────────────────────────────────────────────────────

class _Actions extends StatelessWidget {
  const _Actions({required this.order, required this.active});
  final CourierOrderModel order;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (active) ...[
          Expanded(
            child: _ActionTile(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              onTap: () => context.push('/chat/${order.id}'),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: _ActionTile(
            icon: Icons.ios_share_rounded,
            label: 'Share',
            onTap: () => SharePlus.instance.share(
              ShareParams(text: shareTextFor(order)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.support_agent_rounded,
            label: 'Support',
            onTap: () => context.push('/help'),
          ),
        ),
      ],
    );
  }
}

/// What "Share" sends: where the delivery is up to, in plain words.
String shareTextFor(CourierOrderModel order) {
  final (title, _) = headlineFor(order);
  return 'My Dilivvafast delivery: $title.\n'
      'From ${order.pickupAddress.split(',').first} to '
      '${order.dropoffAddress.split(',').first}.\n'
      'Tracking code: ${order.trackingCode}\n'
      '${AppConstants.playStoreUrl}';
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _field,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: _ink),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Route & details ──────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.order});
  final CourierOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _field,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _stop(
            Icons.circle,
            const Color(0xFF2E7DF6),
            'From',
            order.pickupAddress,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 7),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 16,
                child: VerticalDivider(width: 2, color: Color(0xFFD1D5DB)),
              ),
            ),
          ),
          _stop(
            Icons.circle,
            const Color(0xFFE11D48),
            'To',
            order.dropoffAddress,
          ),
        ],
      ),
    );
  }

  Widget _stop(IconData icon, Color colour, String label, String address) {
    return Row(
      children: [
        Icon(icon, size: 14, color: colour),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.order});
  final CourierOrderModel order;

  @override
  Widget build(BuildContext context) {
    final paid = switch (order.paymentStatus) {
      PaymentStatus.paid => ' · paid',
      PaymentStatus.sent => ' · sent',
      _ => ' · after delivery',
    };
    final rows = [
      ('Package', order.packageDescription),
      ('Recipient', '${order.recipientName} · ${order.recipientPhone}'),
      ('Payment', '${order.paymentMethod.label}$paid'),
      ('Fare', '₦${order.totalFare.toStringAsFixed(0)}'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _field,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(label, style: const TextStyle(color: _muted)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RatedNote extends StatelessWidget {
  const _RatedNote({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: const Color(0xFFF5B301),
            ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Thanks for rating',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: _ink),
          ),
        ),
      ),
    );
  }
}

/// Pickup, drop-off and — once a courier is assigned — their live position.
///
/// The position comes from driver_locations, which the courier's app writes
/// while they are online (see driverLocationSyncProvider).
class _TrackingMap extends ConsumerWidget {
  const _TrackingMap({required this.order});

  final CourierOrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverId = order.driverId;
    final live =
        driverId != null &&
        const [
          OrderStatus.accepted,
          OrderStatus.arrived,
          OrderStatus.pickedUp,
          OrderStatus.inTransit,
        ].contains(order.status);
    final position = live
        ? ref.watch(driverLocationProvider(driverId)).value
        : null;

    return LiveMap(
      pickupLat: order.pickupGeoPoint.latitude,
      pickupLng: order.pickupGeoPoint.longitude,
      dropoffLat: order.dropoffGeoPoint.latitude,
      dropoffLng: order.dropoffGeoPoint.longitude,
      driverLat: position?.latitude,
      driverLng: position?.longitude,
      showUserLocation: false,
      bottomPadding: 28,
    );
  }
}
