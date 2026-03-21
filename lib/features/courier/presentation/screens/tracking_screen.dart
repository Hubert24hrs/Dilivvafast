import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fast_delivery/core/presentation/widgets/delivery_map_widget.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/features/courier/domain/entities/courier_order_model.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderStreamProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Track Delivery',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: orderAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (order) {
          if (order == null) {
            return const Center(
                child: Text('Order not found',
                    style: TextStyle(color: Colors.white54)));
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
              DeliveryMapWidget(
                height: 200,
                pickupLat: order.pickupGeoPoint.latitude,
                pickupLng: order.pickupGeoPoint.longitude,
                dropoffLat: order.dropoffGeoPoint.latitude,
                dropoffLng: order.dropoffGeoPoint.longitude,
                pickupLabel: 'Pickup',
                dropoffLabel: 'Dropoff',
              ),
              // Distance overlay
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${order.estimatedDistanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      if (order.estimatedDurationMin > 0) ...[
                        Text(' · ',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12)),
                        Text(
                          '~${order.estimatedDurationMin} min',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
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
                color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
              ),
              child: Text(
                '📦 ${order.trackingCode}',
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Status timeline
          _buildTimeline(order),
          const SizedBox(height: 24),

          // Route details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _routeRow(Icons.location_on, 'Pickup', order.pickupAddress,
                    const Color(0xFF00F0FF)),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    children: List.generate(
                        3,
                        (_) => Container(
                              width: 2,
                              height: 6,
                              margin: const EdgeInsets.symmetric(vertical: 1),
                              color: Colors.white24,
                            )),
                  ),
                ),
                _routeRow(Icons.flag, 'Dropoff', order.dropoffAddress,
                    const Color(0xFFFF00AA)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Package + fare details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _detailRow('Package', order.packageDescription),
                _detailRow('Recipient', order.recipientName),
                _detailRow('Phone', order.recipientPhone),
                _detailRow('Payment', order.paymentMethod.name),
                const Divider(color: Colors.white12, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Fare',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    Text('₦${order.totalFare.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          if (order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Open chat
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00F0FF),
                      side: const BorderSide(color: Color(0xFF00F0FF)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Share tracking link
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF00AA),
                      side: const BorderSide(color: Color(0xFFFF00AA)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
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

  Widget _buildTimeline(CourierOrderModel order) {
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
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Status',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
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
                                ? const Color(0xFF00F0FF)
                                : const Color(0xFF4CAF50))
                            : const Color(0xFF1D1E33),
                        border: Border.all(
                          color: isCompleted
                              ? Colors.transparent
                              : Colors.white24,
                          width: 2,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00F0FF)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        step.icon,
                        size: 16,
                        color: isCompleted ? Colors.white : Colors.white38,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32,
                        color: isCompleted
                            ? const Color(0xFF4CAF50)
                            : Colors.white12,
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
                          color: isCompleted ? Colors.white : Colors.white38,
                          fontSize: 14,
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isCurrent)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text('Current status',
                              style: TextStyle(
                                  color: Color(0xFF00F0FF), fontSize: 11)),
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

  Widget _routeRow(IconData icon, String label, String addr, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11)),
              Text(addr,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          Flexible(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.right),
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
