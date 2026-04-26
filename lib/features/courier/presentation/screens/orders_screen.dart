import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key, this.isDriver = false});
  final bool isDriver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = isDriver
        ? ref.watch(driverOrdersProvider)
        : ref.watch(customerOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: Text(isDriver ? 'Delivery History' : 'My Orders',
            style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Text('No orders yet',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                      isDriver
                          ? 'Accept deliveries to see them here'
                          : 'Book a delivery to get started',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) =>
                _buildOrderCard(context, orders[index]),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, CourierOrderModel order) {
    return GestureDetector(
      onTap: () => context.push('/customer/track/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: status + fare
            Row(
              children: [
                _statusChip(order.status),
                const Spacer(),
                Text('₦${order.totalFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Color(0xFFFF6B00),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),

            // Route
            Row(
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFFFF6B00), size: 16),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(order.pickupAddress,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.flag, color: Color(0xFFFF9500), size: 16),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(order.dropoffAddress,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom row
            Row(
              children: [
                Icon(Icons.access_time,
                    color: Colors.white.withValues(alpha: 0.4), size: 14),
                const SizedBox(width: 4),
                Text(
                  _formatDate(order.createdAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const Spacer(),
                Text(order.trackingCode,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        letterSpacing: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(OrderStatus status) {
    final (color, label) = switch (status) {
      OrderStatus.pending => (const Color(0xFFFF9800), 'Pending'),
      OrderStatus.accepted => (const Color(0xFF2196F3), 'Accepted'),
      OrderStatus.pickedUp => (const Color(0xFF9C27B0), 'Picked Up'),
      OrderStatus.inTransit => (const Color(0xFF00BCD4), 'In Transit'),
      OrderStatus.delivered => (const Color(0xFF4CAF50), 'Delivered'),
      OrderStatus.cancelled => (const Color(0xFFE91E63), 'Cancelled'),
      OrderStatus.failed => (const Color(0xFFF44336), 'Failed'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style:
              TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
