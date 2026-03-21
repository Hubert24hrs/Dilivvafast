import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fast_delivery/core/providers/providers.dart';

/// Providers for admin analytics
final _adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final ordersSnap = await firestore.collection('orders').get();
  final usersSnap = await firestore.collection('users').get();

  int totalOrders = ordersSnap.docs.length;
  int deliveredOrders =
      ordersSnap.docs.where((d) => d.data()['status'] == 'delivered').length;
  int activeDrivers =
      usersSnap.docs.where((d) => d.data()['role'] == 'driver' && d.data()['isOnline'] == true).length;
  int totalUsers = usersSnap.docs.length;
  double totalRevenue = ordersSnap.docs.fold(0.0, (sum, doc) {
    return sum + ((doc.data()['totalFare'] as num?)?.toDouble() ?? 0);
  });

  return {
    'totalOrders': totalOrders,
    'deliveredOrders': deliveredOrders,
    'activeDrivers': activeDrivers,
    'totalUsers': totalUsers,
    'totalRevenue': totalRevenue,
  };
});

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_adminStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Analytics',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00F0FF)),
            onPressed: () => ref.invalidate(_adminStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (stats) => _buildBody(stats),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI cards
          Row(
            children: [
              _kpiCard('Revenue', '₦${_formatNum(stats['totalRevenue'])}',
                  Icons.attach_money, const Color(0xFF4CAF50)),
              const SizedBox(width: 10),
              _kpiCard('Orders', '${stats['totalOrders']}',
                  Icons.receipt_long, const Color(0xFF00F0FF)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _kpiCard('Users', '${stats['totalUsers']}',
                  Icons.people, const Color(0xFFFF9800)),
              const SizedBox(width: 10),
              _kpiCard('Active Drivers', '${stats['activeDrivers']}',
                  Icons.directions_bike, const Color(0xFFE040FB)),
            ],
          ),
          const SizedBox(height: 24),

          // Delivery rate
          _deliveryRateCard(
              stats['deliveredOrders'] as int, stats['totalOrders'] as int),
          const SizedBox(height: 24),

          // Revenue chart (sample data)
          const Text('Revenue Trend (Last 7 Days)',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _revenueChart(),
          const SizedBox(height: 24),

          // Order distribution
          const Text('Order Status Distribution',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _statusBreakdown(stats),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
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
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _deliveryRateCard(int delivered, int total) {
    final rate = total > 0 ? (delivered / total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Success Rate',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text('${(rate * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: const Color(0xFF0A0E21),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
          const SizedBox(height: 8),
          Text('$delivered of $total orders delivered',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _revenueChart() {
    final now = DateTime.now();
    final data = List.generate(7, (i) {
      return FlSpot(i.toDouble(), (500 + (i * 317 % 3000)).toDouble());
    });

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1000,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${(v / 1000).toStringAsFixed(0)}K',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final date = now.subtract(Duration(days: 6 - v.toInt()));
                  return Text(
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 9),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
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

  Widget _statusBreakdown(Map<String, dynamic> stats) {
    final total = stats['totalOrders'] as int;
    final delivered = stats['deliveredOrders'] as int;
    final pending = total - delivered;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _statusRow('Delivered', delivered, const Color(0xFF4CAF50)),
          const SizedBox(height: 8),
          _statusRow('In Progress / Pending', pending, const Color(0xFFFF9800)),
        ],
      ),
    );
  }

  Widget _statusRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        Text('$count',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 14)),
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
