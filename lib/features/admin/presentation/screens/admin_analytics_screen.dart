import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// Providers for admin analytics
final _adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final ordersSnap = await firestore.collection('couriers').get();
  final usersSnap = await firestore.collection('users').get();

  int totalOrders = ordersSnap.docs.length;
  int deliveredOrders = ordersSnap.docs
      .where((d) => d.data()['status'] == 'delivered')
      .length;
  int activeDrivers = usersSnap.docs
      .where(
        (d) => d.data()['role'] == 'driver' && d.data()['isOnline'] == true,
      )
      .length;
  int totalUsers = usersSnap.docs.length;
  double totalRevenue = ordersSnap.docs.fold<double>(0.0, (total, doc) {
    return total + ((doc.data()['totalFare'] as num?)?.toDouble() ?? 0);
  });

  // Aggregate daily revenue for the last 7 days from delivered orders
  final now = DateTime.now();
  final sevenDaysAgo = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 6));
  final dailyRevenue = <int, double>{};
  for (var i = 0; i < 7; i++) {
    dailyRevenue[i] = 0;
  }
  for (final doc in ordersSnap.docs) {
    final data = doc.data();
    if (data['status'] != 'delivered') continue;
    final deliveredAt = data['deliveredAt'];
    if (deliveredAt == null) continue;
    final date = (deliveredAt as Timestamp).toDate();
    if (date.isBefore(sevenDaysAgo)) continue;
    final dayIndex = date.difference(sevenDaysAgo).inDays.clamp(0, 6);
    dailyRevenue[dayIndex] =
        (dailyRevenue[dayIndex] ?? 0) +
        ((data['totalFare'] as num?)?.toDouble() ?? 0);
  }

  return {
    'totalOrders': totalOrders,
    'deliveredOrders': deliveredOrders,
    'activeDrivers': activeDrivers,
    'totalUsers': totalUsers,
    'totalRevenue': totalRevenue,
    'dailyRevenue': dailyRevenue,
  };
});

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_adminStatsProvider);

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
          'Analytics',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.palette.brand),
            onPressed: () => ref.invalidate(_adminStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.brand),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: context.palette.danger),
          ),
        ),
        data: (stats) => _buildBody(context, stats),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI cards
          Row(
            children: [
              _kpiCard(
                context,
                'Revenue',
                '₦${_formatNum(stats['totalRevenue'])}',
                Icons.attach_money,
                const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 10),
              _kpiCard(
                context,
                'Orders',
                '${stats['totalOrders']}',
                Icons.receipt_long,
                context.palette.brand,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _kpiCard(
                context,
                'Users',
                '${stats['totalUsers']}',
                Icons.people,
                const Color(0xFFFF9800),
              ),
              const SizedBox(width: 10),
              _kpiCard(
                context,
                'Active Drivers',
                '${stats['activeDrivers']}',
                Icons.directions_bike,
                const Color(0xFFE040FB),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Delivery rate
          _deliveryRateCard(
            context,
            stats['deliveredOrders'] as int,
            stats['totalOrders'] as int,
          ),
          const SizedBox(height: 24),

          // Revenue chart (live data)
          Text(
            'Revenue Trend (Last 7 Days)',
            style: TextStyle(
              color: context.palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _revenueChart(context, stats),
          const SizedBox(height: 24),

          // Order distribution
          Text(
            'Order Status Distribution',
            style: TextStyle(
              color: context.palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _statusBreakdown(context, stats),
        ],
      ),
    );
  }

  Widget _kpiCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deliveryRateCard(BuildContext context, int delivered, int total) {
    final rate = total > 0 ? (delivered / total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Success Rate',
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(rate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: context.palette.surfaceBase,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4CAF50),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$delivered of $total orders delivered',
            style: TextStyle(color: context.palette.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _revenueChart(BuildContext context, Map<String, dynamic> stats) {
    final now = DateTime.now();
    final dailyRevenue = (stats['dailyRevenue'] as Map<int, double>?) ?? {};
    final data = List.generate(7, (i) {
      return FlSpot(i.toDouble(), dailyRevenue[i] ?? 0);
    });

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1000,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: context.palette.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${(v / 1000).toStringAsFixed(0)}K',
                  style: TextStyle(
                    color: context.palette.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final date = now.subtract(Duration(days: 6 - v.toInt()));
                  return Text(
                    [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ][date.weekday - 1],
                    style: TextStyle(
                      color: context.palette.textMuted,
                      fontSize: 9,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: const Color(0xFF4CAF50),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF4CAF50).withValues(alpha: 0.2),
                    const Color(0xFF4CAF50).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBreakdown(BuildContext context, Map<String, dynamic> stats) {
    final total = stats['totalOrders'] as int;
    final delivered = stats['deliveredOrders'] as int;
    final pending = total - delivered;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        children: [
          _statusRow(context, 'Delivered', delivered, const Color(0xFF4CAF50)),
          const SizedBox(height: 8),
          _statusRow(
            context,
            'In Progress / Pending',
            pending,
            const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatNum(dynamic value) {
    final n = (value as num?)?.toDouble() ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }
}
