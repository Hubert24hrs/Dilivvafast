import 'package:fast_delivery/core/models/investor_earnings_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvestorEarningsScreen extends ConsumerStatefulWidget {
  const InvestorEarningsScreen({super.key});

  @override
  ConsumerState<InvestorEarningsScreen> createState() =>
      _InvestorEarningsScreenState();
}

class _InvestorEarningsScreenState extends ConsumerState<InvestorEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            const BackgroundOrbs(),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildSummaryCards(userId),
                  _buildPeriodSelector(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildChartsTab(userId),
                        _buildTransactionsTab(userId),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.neomorphicShadow(),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Earnings',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(String userId) {
    return FutureBuilder<Map<String, double>>(
      future: ref.read(investorServiceProvider).getEarningsSummary(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 100);
        }

        final summary = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF004D26), AppTheme.primaryColor],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Total HP Deductions',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₦${_formatAmount(summary['total'] ?? 0)}',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(
                    'Today',
                    '₦${_formatAmount(summary['today'] ?? 0)}',
                  ),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _buildMiniStat(
                    'This Week',
                    '₦${_formatAmount(summary['week'] ?? 0)}',
                  ),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _buildMiniStat(
                    'Rides',
                    '${summary['ridesCount']?.toInt() ?? 0}',
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildPeriodChip('Today', 'today'),
          const SizedBox(width: 8),
          _buildPeriodChip('Week', 'week'),
          const SizedBox(width: 8),
          _buildPeriodChip('Month', 'month'),
          const SizedBox(width: 8),
          _buildPeriodChip('All Time', 'all'),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.white12,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Charts'),
          Tab(text: 'Transactions'),
        ],
      ),
    );
  }

  Widget _buildChartsTab(String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLineChart(
            userId,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 20),
          _buildRevenueSplitChart().animate().fadeIn(
            delay: 300.ms,
            duration: 400.ms,
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(String userId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Earnings Trend',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: StreamBuilder<List<InvestorEarningsModel>>(
              stream: ref
                  .read(investorServiceProvider)
                  .getInvestorEarnings(userId),
              builder: (context, snapshot) {
                final spots = _generateEarningsSpots(snapshot.data ?? []);

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: Colors.white12, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) => Text(
                            '₦${(value / 1000).toInt()}K',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final date = DateTime.now().subtract(
                              Duration(days: 6 - value.toInt()),
                            );
                            return Text(
                              DateFormat('E').format(date),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white54,
                                fontSize: 10,
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
                        spots: spots,
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, Color(0xFF00FF94)],
                        ),
                        barWidth: 4,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: AppTheme.primaryColor,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.3),
                              AppTheme.primaryColor.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSplitChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Split Breakdown',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          value: 50,
                          title: '50%',
                          color: AppTheme.primaryColor,
                          radius: 60,
                          titleStyle: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        PieChartSectionData(
                          value: 40,
                          title: '40%',
                          color: Colors.green,
                          radius: 60,
                          titleStyle: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        PieChartSectionData(
                          value: 10,
                          title: '10%',
                          color: Colors.orange,
                          radius: 60,
                          titleStyle: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem('Investor (HP)', AppTheme.primaryColor),
                  const SizedBox(height: 12),
                  _buildLegendItem('Rider', Colors.green),
                  const SizedBox(height: 12),
                  _buildLegendItem('App Fee', Colors.orange),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Split applies while HP is active. After completion, rider gets 90%.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab(String userId) {
    return StreamBuilder<List<InvestorEarningsModel>>(
      stream: ref.read(investorServiceProvider).getInvestorEarnings(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        final earnings = snapshot.data!;
        if (earnings.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: earnings.length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(earnings[index])
                .animate(delay: (index * 50).ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.1, end: 0);
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(InvestorEarningsModel earning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.motorcycle,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride ${earning.rideId.substring(0, 8)}...',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, y - h:mm a').format(earning.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₦${earning.hpDeduction.toStringAsFixed(0)}',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: earning.hpActive
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      earning.hpActive ? 'HP ACTIVE' : 'HP DONE',
                      style: GoogleFonts.plusJakartaSans(
                        color: earning.hpActive ? Colors.green : Colors.grey,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTransactionStat(
                'Fare',
                '₦${earning.fareAmount.toStringAsFixed(0)}',
              ),
              _buildTransactionStat(
                'Investor',
                '₦${earning.investorShare.toStringAsFixed(0)}',
              ),
              _buildTransactionStat(
                'Rider',
                '₦${earning.riderShare.toStringAsFixed(0)}',
              ),
              _buildTransactionStat(
                'App',
                '₦${earning.appFee.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 60, color: Colors.white30),
            const SizedBox(height: 16),
            Text(
              'No earnings yet',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fund a bike to start earning',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateEarningsSpots(List<InvestorEarningsModel> earnings) {
    // Group by day for last 7 days
    final now = DateTime.now();
    final dailyEarnings = List.generate(7, (i) => 0.0);

    for (var earning in earnings) {
      final daysDiff = now.difference(earning.createdAt).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        dailyEarnings[6 - daysDiff] += earning.hpDeduction;
      }
    }

    return List.generate(7, (i) => FlSpot(i.toDouble(), dailyEarnings[i]));
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
