import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fast_delivery/core/providers/providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);
    final driversAsync = ref.watch(onlineDriversProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: const Text('Admin Dashboard',
            style: TextStyle(color: Colors.white, fontSize: 18)),
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
                _statCard(
                  'Total Orders',
                  '${ordersAsync.value?.length ?? 0}',
                  Icons.receipt_long,
                  const Color(0xFF00F0FF),
                ),
                _statCard(
                  'Active Drivers',
                  '${driversAsync.value?.length ?? 0}',
                  Icons.delivery_dining,
                  const Color(0xFF4CAF50),
                ),
                _statCard(
                  'Revenue',
                  '₦${_totalRevenue(ordersAsync).toStringAsFixed(0)}',
                  Icons.attach_money,
                  const Color(0xFFFF9800),
                ),
                _statCard(
                  'Commission',
                  '₦${_totalCommission(ordersAsync).toStringAsFixed(0)}',
                  Icons.trending_up,
                  const Color(0xFFFF00AA),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Recent orders
            const Text('Recent Orders',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            ordersAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: Color(0xFF00F0FF))),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: Colors.redAccent)),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                      child: Text('No orders yet',
                          style: TextStyle(color: Colors.white54)));
                }
                return Column(
                  children: orders
                      .take(10)
                      .map((order) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D1E33),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _statusColor(order.status.name),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(order.trackingCode,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                          '${order.pickupAddress} → ${order.dropoffAddress}',
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                Text(
                                    '₦${order.totalFare.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: Color(0xFF00F0FF),
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

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
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
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
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

  Color _statusColor(String status) {
    return switch (status) {
      'pending' => const Color(0xFFFF9800),
      'accepted' => const Color(0xFF2196F3),
      'inTransit' => const Color(0xFF00BCD4),
      'delivered' => const Color(0xFF4CAF50),
      'cancelled' => const Color(0xFFE91E63),
      _ => Colors.white54,
    };
  }
}
