import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

class DriverActiveDeliveryScreen extends ConsumerWidget {
  const DriverActiveDeliveryScreen({super.key, required this.orderId});
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
        title: const Text('Active Delivery',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: orderAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (order) {
          if (order == null) {
            return const Center(
                child: Text('Order not found',
                    style: TextStyle(color: Colors.white54)));
          }
          return _buildBody(context, ref, order);
        },
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, CourierOrderModel order) {
    return Column(
      children: [
        // Map placeholder
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.navigation,
                      color: Color(0xFFFF6B00), size: 48),
                  const SizedBox(height: 8),
                  Text('Navigate to ${order.status == OrderStatus.accepted ? 'pickup' : 'dropoff'}',
                      style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 4),
                  Text(
                    order.status == OrderStatus.accepted
                        ? order.pickupAddress
                        : order.dropoffAddress,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1E33),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Order info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.recipientName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        Text(order.recipientPhone,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                  // Call button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.phone,
                        color: Color(0xFF4CAF50), size: 20),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.chat_bubble,
                        color: Color(0xFFFF6B00), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Package info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E21),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2,
                        color: Color(0xFFFF6B00), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(order.packageDescription,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ),
                    Text('₦${order.driverEarnings.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status update button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(ref, order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getStatusButtonColor(order.status),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _getStatusButtonLabel(order.status),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusButtonColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.accepted => const Color(0xFF2196F3),
      OrderStatus.pickedUp => const Color(0xFF9C27B0),
      OrderStatus.inTransit => const Color(0xFF4CAF50),
      _ => const Color(0xFFFF6B00),
    };
  }

  String _getStatusButtonLabel(OrderStatus status) {
    return switch (status) {
      OrderStatus.accepted => '📦 Confirm Pickup',
      OrderStatus.pickedUp => '🚀 Start Delivery',
      OrderStatus.inTransit => '✅ Mark Delivered',
      _ => 'Update Status',
    };
  }

  Future<void> _updateStatus(WidgetRef ref, CourierOrderModel order) async {
    final nextStatus = switch (order.status) {
      OrderStatus.accepted => OrderStatus.pickedUp,
      OrderStatus.pickedUp => OrderStatus.inTransit,
      OrderStatus.inTransit => OrderStatus.delivered,
      _ => null,
    };

    if (nextStatus == null) return;

    final courierRepo = ref.read(courierRepositoryProvider);
    await courierRepo.updateOrderStatus(order.id, nextStatus);
  }
}
