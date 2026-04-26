import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

class DriverEarningsScreen extends ConsumerStatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  ConsumerState<DriverEarningsScreen> createState() =>
      _DriverEarningsScreenState();
}

class _DriverEarningsScreenState
    extends ConsumerState<DriverEarningsScreen> {
  int _selectedPeriod = 0; // 0=week, 1=month, 2=all
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(driverOrdersProvider);
    final walletAsync = ref.watch(walletBalanceProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Earnings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined,
                color: AppTheme.primaryColor),
            onPressed: () => context.push('/wallet/top-up'),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent))),
        data: (orders) {
          final walletBalance = walletAsync.value ?? 0.0;
          final deliveredOrders = orders
              .where((o) => o.status == OrderStatus.delivered)
              .toList();

          return _buildBody(deliveredOrders, walletBalance);
        },
      ),
    );
  }

  Widget _buildBody(List<CourierOrderModel> deliveredOrders, double walletBalance) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));

    // Today's earnings
    final todayOrders = deliveredOrders.where((o) =>
        o.deliveredAt != null &&
        o.deliveredAt!.isAfter(today));
    final todayEarnings =
        todayOrders.fold(0.0, (sum, o) => sum + o.driverEarnings);
    final todayTrips = todayOrders.length;

    // Weekly earnings
    final weekOrders = deliveredOrders.where((o) =>
        o.deliveredAt != null &&
        o.deliveredAt!.isAfter(weekStart));
    final weeklyEarnings =
        weekOrders.fold(0.0, (sum, o) => sum + o.driverEarnings);
    final weeklyTrips = weekOrders.length;

    // Build per-day data for chart
    final weeklyData = List.generate(7, (dayIndex) {
      final day = weekStart.add(Duration(days: dayIndex));
      final nextDay = day.add(const Duration(days: 1));
      return deliveredOrders
          .where((o) =>
              o.deliveredAt != null &&
              o.deliveredAt!.isAfter(day) &&
              o.deliveredAt!.isBefore(nextDay))
          .fold(0.0, (sum, o) => sum + o.driverEarnings);
    });

    // Recent trips (last 10)
    final recentTrips = deliveredOrders.toList()
      ..sort((a, b) => (b.deliveredAt ?? DateTime(2000))
          .compareTo(a.deliveredAt ?? DateTime(2000)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet balance card
          _buildWalletCard(walletBalance, todayEarnings)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today',
                  _currencyFormat.format(todayEarnings),
                  '$todayTrips trips',
                  Icons.today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'This Week',
                  _currencyFormat.format(weeklyEarnings),
                  '$weeklyTrips trips',
                  Icons.date_range,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Period selector
          _buildPeriodSelector(),

          const SizedBox(height: 16),

          // Bar chart
          _buildEarningsChart(weeklyData)
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Recent trips
          const Text('Recent Trips',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (recentTrips.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('No completed deliveries yet',
                    style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            ...List.generate(recentTrips.take(10).length, (index) {
              return _buildTripItem(recentTrips[index])
                  .animate()
                  .fadeIn(
                      delay: Duration(milliseconds: 500 + (index * 100)),
                      duration: 300.ms)
                  .slideX(begin: 0.05, end: 0);
            }),
        ],
      ),
    );
  }

  Widget _buildWalletCard(double walletBalance, double todayEarnings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wallet Balance',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Withdraw',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currencyFormat.format(walletBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                '+${_currencyFormat.format(todayEarnings)} today',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Week', 'Month', 'All Time'];
    return Row(
      children: List.generate(periods.length, (index) {
        final isSelected = _selectedPeriod == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(periods[index]),
            selected: isSelected,
            selectedColor: AppTheme.primaryColor,
            backgroundColor: AppTheme.surfaceColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.white.withValues(alpha: 0.1),
            ),
            onSelected: (selected) {
              if (selected) setState(() => _selectedPeriod = index);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEarningsChart(List<double> weeklyData) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxY = weeklyData.isEmpty
        ? 1000.0
        : weeklyData.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 1000 : maxY * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  _currencyFormat.format(rod.toY),
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < weekDays.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(weekDays[idx],
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withValues(alpha: 0.05),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(weeklyData.length, (index) {
            final isToday = index == DateTime.now().weekday - 1;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: weeklyData[index],
                  color: isToday
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withValues(alpha: 0.4),
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTripItem(CourierOrderModel order) {
    final timeFormat = DateFormat.jm();
    final route = '${order.pickupAddress} → ${order.dropoffAddress}';
    final time = order.deliveredAt ?? order.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_outlined,
                color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(timeFormat.format(time),
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '+${_currencyFormat.format(order.driverEarnings)}',
            style: const TextStyle(
              color: AppTheme.successColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
