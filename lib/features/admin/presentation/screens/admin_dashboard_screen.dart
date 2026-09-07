import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);
    final driversAsync = ref.watch(onlineDriversProvider);

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        elevation: 0,
        title: Text('Admin Dashboard',
            style: TextStyle(color: context.palette.textPrimary, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _statCard(context, 
                  'Total Orders',
                  '${ordersAsync.value?.length ?? 0}',
                  Icons.receipt_long,
                  context.palette.brand,
                ),
                _statCard(context, 
                  'Active Drivers',
                  '${driversAsync.value?.length ?? 0}',
                  Icons.delivery_dining,
                  const Color(0xFF4CAF50),
                ),
                _statCard(context, 
                  'Revenue',
                  '₦${_totalRevenue(ordersAsync).toStringAsFixed(0)}',
                  Icons.attach_money,
                  const Color(0xFFFF9800),
                ),
                _statCard(context, 
                  'Commission',
                  '₦${_totalCommission(ordersAsync).toStringAsFixed(0)}',
                  Icons.trending_up,
                  context.palette.brand,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Recent orders
            Text('Recent Orders',
                style: TextStyle(
                    color: context.palette.onBrand,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            ordersAsync.when(
              loading: () => Center(
                  child:
                      CircularProgressIndicator(color: context.palette.brand)),
              error: (e, _) => Text('Error: $e',
                  style: TextStyle(color: context.palette.danger)),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                      child: Text('No orders yet',
                          style: TextStyle(color: context.palette.textSecondary)));
                }
                return Column(
                  children: orders
                      .take(10)
                      .map((order) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.palette.surfaceRaised,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.palette.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _statusColor(context, order.status.name),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(order.trackingCode,
                                          style: TextStyle(
                                              color: context.palette.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                          '${order.pickupAddress} → ${order.dropoffAddress}',
                                          style: TextStyle(
                                              color: context.palette.textSecondary,
                                              fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                Text(
                                    '₦${order.totalFare.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        color: context.palette.brand,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(color: context.palette.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  double _totalRevenue(AsyncValue<dynamic> ordersAsync) {
    final orders = ordersAsync.value;
    if (orders == null) return 0;
    return (orders as List).fold(0.0, (sum, o) => sum + (o.totalFare as double));
  }

  double _totalCommission(AsyncValue<dynamic> ordersAsync) {
    final orders = ordersAsync.value;
    if (orders == null) return 0;
    return (orders as List)
        .fold(0.0, (sum, o) => sum + (o.platformCommission as double));
  }

  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'pending' => const Color(0xFFFF9800),
      'accepted' => const Color(0xFF2196F3),
      'inTransit' => const Color(0xFF00BCD4),
      'delivered' => const Color(0xFF4CAF50),
      'cancelled' => const Color(0xFFE91E63),
      _ => context.palette.textSecondary,
    };
  }
}
