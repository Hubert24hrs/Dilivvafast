import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/providers/providers.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: const Text('Manage Orders',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
                child: Text('No orders',
                    style: TextStyle(color: Colors.white54)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1E33),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(o.trackingCode,
                            style: const TextStyle(
                                color: Color(0xFFFF6B00),
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(o.status.name,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${o.pickupAddress} → ${o.dropoffAddress}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                        'Fare: ₦${o.totalFare.toStringAsFixed(0)} | Commission: ₦${o.platformCommission.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(onlineDriversProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: const Text('Manage Users',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: driversAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
                child: Text('No users online',
                    style: TextStyle(color: Colors.white54)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1E33),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                      child: Text(u.fullName.isNotEmpty ? u.fullName[0] : '?',
                          style: const TextStyle(color: Color(0xFFFF6B00))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.fullName,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                          Text('${u.email} • ${u.role.name}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: u.isOnline
                            ? const Color(0xFF4CAF50)
                            : Colors.white24,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminApplicationsScreen extends StatelessWidget {
  const AdminApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: const Text('Driver Applications',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment, color: Color(0xFFFF6B00), size: 48),
            const SizedBox(height: 12),
            Text('Driver applications will appear here',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class AdminFinanceScreen extends ConsumerWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: const Text('Finance',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (orders) {
          final revenue = orders.fold(0.0, (s, o) => s + o.totalFare);
          final commission =
              orders.fold(0.0, (s, o) => s + o.platformCommission);
          final driverPayouts =
              orders.fold(0.0, (s, o) => s + o.driverEarnings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _financeCard('Total Revenue', '₦${revenue.toStringAsFixed(0)}',
                    const Color(0xFFFF6B00)),
                const SizedBox(height: 12),
                _financeCard(
                    'Platform Commission',
                    '₦${commission.toStringAsFixed(0)}',
                    const Color(0xFFFF9500)),
                const SizedBox(height: 12),
                _financeCard(
                    'Driver Payouts',
                    '₦${driverPayouts.toStringAsFixed(0)}',
                    const Color(0xFF4CAF50)),
                const SizedBox(height: 12),
                _financeCard('Total Orders', '${orders.length}',
                    const Color(0xFFFF9800)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _financeCard(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
