import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);
    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        elevation: 0,
        title: Text(
          'Manage Orders',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: ordersAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.brand),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: context.palette.danger),
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Text(
                'No orders',
                style: TextStyle(color: context.palette.textSecondary),
              ),
            );
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
                  color: context.palette.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          o.trackingCode,
                          style: TextStyle(
                            color: context.palette.brand,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.palette.border,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            o.status.name,
                            style: TextStyle(
                              color: context.palette.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${o.pickupAddress} → ${o.dropoffAddress}',
                      style: TextStyle(
                        color: context.palette.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fare: ₦${o.totalFare.toStringAsFixed(0)} | Commission: ₦${o.platformCommission.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: context.palette.textMuted,
                        fontSize: 11,
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

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(onlineDriversProvider);
    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        elevation: 0,
        title: Text(
          'Manage Users',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: driversAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.brand),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: context.palette.danger),
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                'No users online',
                style: TextStyle(color: context.palette.textSecondary),
              ),
            );
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
                  color: context.palette.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.palette.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: context.palette.brand.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        u.fullName.isNotEmpty ? u.fullName[0] : '?',
                        style: TextStyle(color: context.palette.brand),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.fullName,
                            style: TextStyle(
                              color: context.palette.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${u.email} • ${u.role.name}',
                            style: TextStyle(
                              color: context.palette.textSecondary,
                              fontSize: 11,
                            ),
                          ),
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
                            : context.palette.textMuted,
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

class AdminFinanceScreen extends ConsumerWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);
    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        elevation: 0,
        title: Text(
          'Finance',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: ordersAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.brand),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: context.palette.danger),
          ),
        ),
        data: (orders) {
          final revenue = orders.fold(0.0, (s, o) => s + o.totalFare);
          final commission = orders.fold(
            0.0,
            (s, o) => s + o.platformCommission,
          );
          final driverPayouts = orders.fold(
            0.0,
            (s, o) => s + o.driverEarnings,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _financeCard(
                  context,
                  'Total Revenue',
                  '₦${revenue.toStringAsFixed(0)}',
                  context.palette.brand,
                ),
                const SizedBox(height: 12),
                _financeCard(
                  context,
                  'Platform Commission',
                  '₦${commission.toStringAsFixed(0)}',
                  context.palette.brand,
                ),
                const SizedBox(height: 12),
                _financeCard(
                  context,
                  'Driver Payouts',
                  '₦${driverPayouts.toStringAsFixed(0)}',
                  const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 12),
                _financeCard(
                  context,
                  'Total Orders',
                  '${orders.length}',
                  const Color(0xFFFF9800),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _financeCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
