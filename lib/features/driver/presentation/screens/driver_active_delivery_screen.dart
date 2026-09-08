import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class DriverActiveDeliveryScreen extends ConsumerWidget {
  const DriverActiveDeliveryScreen({super.key, required this.orderId});
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
          'Active Delivery',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: orderAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.brand),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
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
          return _buildBody(context, ref, order);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CourierOrderModel order,
  ) {
    return Column(
      children: [
        // Map placeholder
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.palette.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.palette.border),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation,
                    color: context.palette.brand,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Navigate to ${order.status == OrderStatus.accepted ? 'pickup' : 'dropoff'}',
                    style: TextStyle(color: context.palette.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.status == OrderStatus.accepted
                        ? order.pickupAddress
                        : order.dropoffAddress,
                    style: TextStyle(
                      color: context.palette.onBrand,
                      fontSize: 14,
                    ),
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
            color: context.palette.surfaceRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
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
                  color: context.palette.textMuted,
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
                        Text(
                          order.recipientName,
                          style: TextStyle(
                            color: context.palette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          order.recipientPhone,
                          style: TextStyle(
                            color: context.palette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
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
                    child: const Icon(
                      Icons.phone,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.palette.brand.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.chat_bubble,
                      color: context.palette.brand,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Package info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.palette.surfaceBase,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      color: context.palette.brand,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.packageDescription,
                        style: TextStyle(
                          color: context.palette.onBrand,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '₦${order.driverEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                    backgroundColor: _getStatusButtonColor(
                      context,
                      order.status,
                    ),
                    foregroundColor: context.palette.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _getStatusButtonLabel(order.status),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusButtonColor(BuildContext context, OrderStatus status) {
    return switch (status) {
      OrderStatus.accepted => const Color(0xFF2196F3),
      OrderStatus.pickedUp => const Color(0xFF9C27B0),
      OrderStatus.inTransit => const Color(0xFF4CAF50),
      _ => context.palette.brand,
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
