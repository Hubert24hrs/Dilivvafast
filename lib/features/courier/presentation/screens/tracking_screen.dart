import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:dilivvafast/core/presentation/widgets/live_map.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/utils/friendly_error.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderStreamProvider(orderId));

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Track Delivery',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: orderAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.brand),
        ),
        error: (e, _) => Center(
          child: Text(
            friendlyError(e),
            style: TextStyle(color: context.palette.danger),
          ),
        ),
        data: (order) {
          if (order == null) {
            return Center(
              child: Text(
                'Order not found',
                style: TextStyle(color: context.palette.textSecondary),
              ),
            );
          }
          return _buildTrackingBody(context, order);
        },
      ),
    );
  }

  Widget _buildTrackingBody(BuildContext context, CourierOrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live map
          Stack(
            children: [
              _TrackingMap(order: order),
              // Distance overlay
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${order.estimatedDistanceKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: context.palette.brand,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (order.estimatedDurationMin > 0) ...[
                        Text(
                          ' · ',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '~${order.estimatedDurationMin} min',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tracking code
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: context.palette.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.palette.brand.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '📦 ${order.trackingCode}',
                style: TextStyle(
                  color: context.palette.brand,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Status timeline
          _buildTimeline(context, order),
          const SizedBox(height: 24),

          // Route details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.palette.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.palette.border),
            ),
            child: Column(
              children: [
                _routeRow(
                  context,
                  Icons.location_on,
                  'Pickup',
                  order.pickupAddress,
                  context.palette.brand,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 2,
                        height: 6,
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        color: context.palette.textMuted,
                      ),
                    ),
                  ),
                ),
                _routeRow(
                  context,
                  Icons.flag,
                  'Dropoff',
                  order.dropoffAddress,
                  context.palette.brand,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Package + fare details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.palette.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.palette.border),
            ),
            child: Column(
              children: [
                _detailRow(context, 'Package', order.packageDescription),
                _detailRow(context, 'Recipient', order.recipientName),
                _detailRow(context, 'Phone', order.recipientPhone),
                _detailRow(context, 'Payment', order.paymentMethod.name),
                Divider(color: context.palette.border, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Fare',
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₦${order.totalFare.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: context.palette.brand,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rating. Nothing linked to the rating screen before, so no
          // courier ever received a rating.
          if (order.status == OrderStatus.delivered && order.rating == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => context.push('/rate/${order.id}'),
                  icon: const Icon(Icons.star_rounded),
                  label: const Text('Rate your courier'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC1F11D),
                    foregroundColor: const Color(0xFF111827),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

          // Action buttons
          if (order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/chat/${order.id}');
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.palette.brand,
                      side: BorderSide(color: context.palette.brand),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text:
                              'Track my Dilivvafast delivery!\n'
                              'Tracking Code: ${order.trackingCode}\n'
                              'Status: ${order.status.name}',
                        ),
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.palette.brand,
                      side: BorderSide(color: context.palette.brand),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, CourierOrderModel order) {
    final steps = [
      _TimelineStep('Order Placed', OrderStatus.pending, Icons.receipt),
      _TimelineStep('Accepted', OrderStatus.accepted, Icons.check_circle),
      _TimelineStep('Picked Up', OrderStatus.pickedUp, Icons.inventory),
      _TimelineStep('In Transit', OrderStatus.inTransit, Icons.local_shipping),
      _TimelineStep('Delivered', OrderStatus.delivered, Icons.done_all),
    ];

    final currentIdx = steps.indexWhere((s) => s.status == order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Status',
            style: TextStyle(
              color: context.palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isCompleted = i <= currentIdx;
            final isCurrent = i == currentIdx;
            final isLast = i == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? (isCurrent
                                  ? context.palette.brand
                                  : const Color(0xFF4CAF50))
                            : context.palette.surfaceRaised,
                        border: Border.all(
                          color: isCompleted
                              ? Colors.transparent
                              : context.palette.textMuted,
                          width: 2,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: context.palette.brand.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        step.icon,
                        size: 16,
                        color: isCompleted
                            ? context.palette.onBrand
                            : context.palette.textMuted,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32,
                        color: isCompleted
                            ? const Color(0xFF4CAF50)
                            : context.palette.border,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          color: isCompleted
                              ? context.palette.textPrimary
                              : context.palette.textMuted,
                          fontSize: 14,
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (isCurrent)
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Current status',
                            style: TextStyle(
                              color: context.palette.brand,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      SizedBox(height: isLast ? 0 : 20),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _routeRow(
    BuildContext context,
    IconData icon,
    String label,
    String addr,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                addr,
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.palette.textPrimary, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String label;
  final OrderStatus status;
  final IconData icon;
  const _TimelineStep(this.label, this.status, this.icon);
}

/// Pickup, drop-off and — once a courier is assigned — their live position.
///
/// The position comes from driver_locations, which the courier's app now
/// actually writes while they are online (see driverLocationSyncProvider).
/// It was never written before, so this map could not have shown a courier.
class _TrackingMap extends ConsumerWidget {
  const _TrackingMap({required this.order});

  final CourierOrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverId = order.driverId;
    final live =
        driverId != null &&
        (order.status == OrderStatus.accepted ||
            order.status == OrderStatus.pickedUp ||
            order.status == OrderStatus.inTransit);
    final position = live
        ? ref.watch(driverLocationProvider(driverId)).value
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: LiveMap(
          pickupLat: order.pickupGeoPoint.latitude,
          pickupLng: order.pickupGeoPoint.longitude,
          dropoffLat: order.dropoffGeoPoint.latitude,
          dropoffLng: order.dropoffGeoPoint.longitude,
          driverLat: position?.latitude,
          driverLng: position?.longitude,
          showUserLocation: false,
        ),
      ),
    );
  }
}
