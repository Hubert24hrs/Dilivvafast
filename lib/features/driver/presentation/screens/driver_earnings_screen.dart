import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/core/presentation/utils/friendly_error.dart';

class DriverEarningsScreen extends ConsumerStatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  ConsumerState<DriverEarningsScreen> createState() =>
      _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends ConsumerState<DriverEarningsScreen> {
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
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Earnings',
          style: TextStyle(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.account_balance_wallet_outlined,
              color: context.palette.brand,
            ),
            onPressed: () => context.push('/wallet/top-up'),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.brand),
        ),
        error: (e, _) => Center(
          child: Text(
            friendlyError(e),
            style: TextStyle(color: context.palette.danger),
          ),
        ),
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

  Widget _buildBody(
    List<CourierOrderModel> deliveredOrders,
    double walletBalance,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));

    // Today's earnings
    final todayOrders = deliveredOrders.where(
      (o) => o.deliveredAt != null && o.deliveredAt!.isAfter(today),
    );
    final todayEarnings = todayOrders.fold(
      0.0,
      (sum, o) => sum + o.driverEarnings,
    );
    final todayTrips = todayOrders.length;

    // Weekly earnings
    final weekOrders = deliveredOrders.where(
      (o) => o.deliveredAt != null && o.deliveredAt!.isAfter(weekStart),
    );
    final weeklyEarnings = weekOrders.fold(
      0.0,
      (sum, o) => sum + o.driverEarnings,
    );
    final weeklyTrips = weekOrders.length;

    // Build per-day data for chart
    final weeklyData = List.generate(7, (dayIndex) {
      final day = weekStart.add(Duration(days: dayIndex));
      final nextDay = day.add(const Duration(days: 1));
      return deliveredOrders
          .where(
            (o) =>
                o.deliveredAt != null &&
                o.deliveredAt!.isAfter(day) &&
                o.deliveredAt!.isBefore(nextDay),
          )
          .fold(0.0, (sum, o) => sum + o.driverEarnings);
    });

    // Recent trips (last 10)
    final recentTrips = deliveredOrders.toList()
      ..sort(
        (a, b) => (b.deliveredAt ?? DateTime(2000)).compareTo(
          a.deliveredAt ?? DateTime(2000),
        ),
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet balance card
          _buildWalletCard(
            walletBalance,
            todayEarnings,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

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
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Period selector
          _buildPeriodSelector(),

          const SizedBox(height: 16),

          // Bar chart
          _buildEarningsChart(
            weeklyData,
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // Recent trips
          Text(
            'Recent Trips',
            style: TextStyle(
              color: context.palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (recentTrips.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: context.palette.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'No completed deliveries yet',
                  style: TextStyle(color: context.palette.textSecondary),
                ),
              ),
            )
          else
            ...List.generate(recentTrips.take(10).length, (index) {
              return _buildTripItem(recentTrips[index])
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 500 + (index * 100)),
                    duration: 300.ms,
                  )
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
            color: context.palette.brand.withValues(alpha: 0.3),
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
              Text(
                'Wallet Balance',
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.palette.textMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Withdraw',
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currencyFormat.format(walletBalance),
            style: TextStyle(
              color: context.palette.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: context.palette.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '+${_currencyFormat.format(todayEarnings)} today',
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: context.palette.brand, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: context.palette.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: context.palette.textMuted, fontSize: 11),
          ),
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
            selectedColor: context.palette.brand,
            backgroundColor: context.palette.surfaceRaised,
            labelStyle: TextStyle(
              color: isSelected
                  ? context.palette.onBrand
                  : context.palette.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: BorderSide(
              color: isSelected
                  ? context.palette.brand
                  : context.palette.border,
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
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 1000 : maxY * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  _currencyFormat.format(rod.toY),
                  TextStyle(
                    color: context.palette.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
                      child: Text(
                        weekDays[idx],
                        style: TextStyle(
                          color: context.palette.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: context.palette.border, strokeWidth: 1);
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
                      ? context.palette.brand
                      : context.palette.brand.withValues(alpha: 0.4),
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
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
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.palette.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: context.palette.brand,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeFormat.format(time),
                  style: TextStyle(
                    color: context.palette.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${_currencyFormat.format(order.driverEarnings)}',
            style: TextStyle(
              color: context.palette.success,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
