import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/widgets/live_map.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _field = Color(0xFFF3F4F6);
const _lime = Color(0xFFC1F11D);

/// The driver's view of a job they have won: where to go next, who to call,
/// and one button that moves the job along accepted → picked up → in transit
/// → delivered.
///
/// Reached from the "active job" banner on driver home, the "Open job" button
/// on an accepted offer, or the "offer accepted" push notification.
///
/// The status button guards against double taps. Each tap reads the order's
/// *current* status and advances it one step, so before this guard a quick
/// double tap on "Confirm pickup" went straight past "picked up" to "in
/// transit". Marking a job delivered asks for confirmation, because it ends
/// the job and triggers the driver's payout.
class DriverActiveDeliveryScreen extends ConsumerStatefulWidget {
  const DriverActiveDeliveryScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<DriverActiveDeliveryScreen> createState() =>
      _DriverActiveDeliveryScreenState();
}

class _DriverActiveDeliveryScreenState
    extends ConsumerState<DriverActiveDeliveryScreen> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    // Keep publishing this driver's position while the job is open, so the
    // customer's tracking map shows them moving.
    ref.watch(driverLocationSyncProvider);
    final orderAsync = ref.watch(orderStreamProvider(widget.orderId));
    final me = ref.watch(currentUserIdProvider);
    final myPosition = me == null
        ? null
        : ref.watch(driverLocationProvider(me)).value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _ink,
        title: const Text(
          'Active delivery',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/driver/home'),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const _Message(
          icon: Icons.error_outline_rounded,
          text: 'Could not load this job. Check your connection.',
        ),
        data: (order) {
          if (order == null) {
            return const _Message(
              icon: Icons.search_off_rounded,
              text: 'This job no longer exists.',
            );
          }
          if (me != null && order.driverId != me) {
            return const _Message(
              icon: Icons.lock_outline_rounded,
              text: 'This job is assigned to another courier.',
            );
          }
          return _body(
            context,
            order,
            myPosition?.latitude,
            myPosition?.longitude,
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    CourierOrderModel order,
    double? myLat,
    double? myLng,
  ) {
    final headingToPickup = order.status == OrderStatus.accepted;
    final finished =
        order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.failed;
    final fare = order.totalFare;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: LiveMap(
                  pickupLat: order.pickupGeoPoint.latitude,
                  pickupLng: order.pickupGeoPoint.longitude,
                  dropoffLat: order.dropoffGeoPoint.latitude,
                  dropoffLng: order.dropoffGeoPoint.longitude,
                  driverLat: myLat,
                  driverLng: myLng,
                ),
              ),
              if (!finished)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 12,
                  child: _NextStopCard(
                    label: headingToPickup ? 'Go to pickup' : 'Go to drop-off',
                    address: headingToPickup
                        ? order.pickupAddress
                        : order.dropoffAddress,
                    onNavigate: () => _navigate(
                      headingToPickup
                          ? order.pickupGeoPoint.latitude
                          : order.dropoffGeoPoint.latitude,
                      headingToPickup
                          ? order.pickupGeoPoint.longitude
                          : order.dropoffGeoPoint.longitude,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.of(context).padding.bottom + 18,
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusSteps(status: order.status),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.recipientName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.packageDescription,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₦${fare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              if (!finished) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _RoundAction(
                        icon: Icons.call_rounded,
                        label: 'Call recipient',
                        onTap: () => _call(order.recipientPhone),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RoundAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat with customer',
                        onTap: () => context.push('/chat/${order.id}'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (finished)
                _FinishedPanel(order: order)
              else
                SizedBox(
                  height: 58,
                  child: FilledButton(
                    onPressed: _updating ? null : () => _advance(order),
                    style: FilledButton.styleFrom(
                      backgroundColor: _lime,
                      foregroundColor: _ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _updating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _ink,
                            ),
                          )
                        : Text(_actionLabel(order.status)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _actionLabel(OrderStatus status) => switch (status) {
    OrderStatus.accepted => 'I have picked up the package',
    OrderStatus.pickedUp => 'Start delivery',
    OrderStatus.inTransit => 'Mark as delivered',
    _ => 'Update',
  };

  static OrderStatus? _next(OrderStatus status) => switch (status) {
    OrderStatus.accepted => OrderStatus.pickedUp,
    OrderStatus.pickedUp => OrderStatus.inTransit,
    OrderStatus.inTransit => OrderStatus.delivered,
    _ => null,
  };

  Future<void> _advance(CourierOrderModel order) async {
    final next = _next(order.status);
    if (next == null || _updating) return;

    if (next == OrderStatus.delivered) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mark as delivered?'),
          content: Text(
            'Only confirm once ${order.recipientName} has the package. '
            'This completes the job.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not yet'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, delivered'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _updating = true);
    final result = await ref
        .read(courierRepositoryProvider)
        .updateOrderStatus(order.id, next);
    if (!mounted) return;
    setState(() => _updating = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not update the job. Please try again.'),
          backgroundColor: context.palette.danger,
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (_) {
        if (next == OrderStatus.delivered) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Delivered — nice work. Earnings are paid out daily.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start a call on this device.')),
      );
    }
  }

  Future<void> _navigate(double lat, double lng) async {
    final google = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(google)) {
      await launchUrl(google);
      return;
    }
    await launchUrl(
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
      mode: LaunchMode.externalApplication,
    );
  }
}

class _NextStopCard extends StatelessWidget {
  const _NextStopCard({
    required this.label,
    required this.address,
    required this.onNavigate,
  });

  final String label;
  final String address;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: _muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 2),
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
            IconButton.filled(
              tooltip: 'Navigate',
              onPressed: onNavigate,
              style: IconButton.styleFrom(backgroundColor: _ink),
              icon: const Icon(Icons.navigation_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
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
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: _ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
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
      ),
    );
  }
}

/// Accepted → Picked up → On the way → Delivered, with the current step lit.
class _StatusSteps extends StatelessWidget {
  const _StatusSteps({required this.status});

  final OrderStatus status;

  static const _steps = [
    (OrderStatus.accepted, 'Accepted'),
    (OrderStatus.pickedUp, 'Picked up'),
    (OrderStatus.inTransit, 'On the way'),
    (OrderStatus.delivered, 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexWhere((s) => s.$1 == status);
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= current ? _ink : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _steps[i].$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: i == current
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: i <= current ? _ink : _muted,
                  ),
                ),
              ],
            ),
          ),
          if (i != _steps.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _FinishedPanel extends StatelessWidget {
  const _FinishedPanel({required this.order});

  final CourierOrderModel order;

  @override
  Widget build(BuildContext context) {
    final delivered = order.status == OrderStatus.delivered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: delivered
                ? context.palette.successSubtle
                : context.palette.dangerSubtle,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            delivered
                ? 'Delivered. You earn ₦${order.driverEarnings.toStringAsFixed(0)} '
                      'on this job, paid into your wallet in the daily payout.'
                : 'This job was ${order.status.name}.',
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () => context.go('/driver/home'),
            style: FilledButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Back to requests'),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: _muted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}
