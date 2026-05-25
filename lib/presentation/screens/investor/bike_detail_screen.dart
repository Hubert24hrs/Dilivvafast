import 'package:fast_delivery/core/models/bike_model.dart';
import 'package:fast_delivery/core/models/hp_agreement_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fast_delivery/core/models/investor_earnings_model.dart';
import 'package:intl/intl.dart';

class BikeDetailScreen extends ConsumerStatefulWidget {
  final String bikeId;

  const BikeDetailScreen({super.key, required this.bikeId});

  @override
  ConsumerState<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends ConsumerState<BikeDetailScreen> {
  // Map not used in this screen - field kept for future implementation

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            const BackgroundOrbs(),
            SafeArea(
              child: StreamBuilder<BikeModel?>(
                stream: ref
                    .read(investorServiceProvider)
                    .streamBike(widget.bikeId),
                builder: (context, bikeSnapshot) {
                  if (!bikeSnapshot.hasData || bikeSnapshot.data == null) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }

                  final bike = bikeSnapshot.data!;

                  return Column(
                    children: [
                      _buildAppBar(bike),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildMapSection(bike)
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.1, end: 0),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStatsCards(bike).animate().fadeIn(
                                      delay: 200.ms,
                                      duration: 400.ms,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildHPProgressSection(
                                      bike,
                                    ).animate().fadeIn(
                                      delay: 300.ms,
                                      duration: 400.ms,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildMaintenanceSection(
                                      bike,
                                    ).animate().fadeIn(
                                      delay: 400.ms,
                                      duration: 400.ms,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildEarningsChart(bike).animate().fadeIn(
                                      delay: 500.ms,
                                      duration: 400.ms,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BikeModel bike) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bike.displayName,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  bike.id,
                  style: GoogleFonts.sourceCodePro(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(bike.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getStatusColor(bike.status)),
            ),
            child: Text(
              bike.status.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                color: _getStatusColor(bike.status),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(BikeModel bike) {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: AppTheme.surfaceColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  bike.currentLocation != null ? Icons.location_on : Icons.location_off,
                  size: 48,
                  color: bike.currentLocation != null ? AppTheme.primaryColor : Colors.white30,
                ),
                const SizedBox(height: 12),
                Text(
                  bike.currentLocation != null
                      ? 'Location: ${bike.currentLocation!.latitude.toStringAsFixed(4)}, ${bike.currentLocation!.longitude.toStringAsFixed(4)}'
                      : 'Location not available',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(BikeModel bike) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Rides',
            bike.totalRides.toString(),
            Icons.route,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Earnings',
            '₦${_formatAmount(bike.totalEarnings)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHPProgressSection(BikeModel bike) {
    return FutureBuilder<HPAgreementModel?>(
      future: ref.read(investorServiceProvider).getHPAgreement(bike.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final agreement = snapshot.data!;
        final progress = agreement.progressPercentage;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF004D26).withValues(alpha: 0.3),
                AppTheme.primaryColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HP Progress',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? Colors.green : AppTheme.primaryColor,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHPStat(
                    'Paid',
                    '₦${_formatAmount(agreement.amountPaid)}',
                  ),
                  _buildHPStat(
                    'Remaining',
                    '₦${_formatAmount(agreement.remainingBalance)}',
                  ),
                  _buildHPStat(
                    'Total',
                    '₦${_formatAmount(agreement.totalRepayment)}',
                  ),
                ],
              ),
              if (agreement.projectedCompletionDate != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Projected completion: ${_formatDate(agreement.projectedCompletionDate!)}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHPStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceSection(BikeModel bike) {
    final activeAlerts = bike.maintenanceAlerts
        .where((a) => !a.isResolved)
        .toList();

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: activeAlerts.isEmpty
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  activeAlerts.isEmpty ? Icons.check_circle : Icons.build,
                  color: activeAlerts.isEmpty ? Colors.green : Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Maintenance',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activeAlerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No pending maintenance',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...activeAlerts.map((alert) => _buildMaintenanceAlert(alert)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Service',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              Text(
                bike.lastServiceDate != null
                    ? _formatDate(bike.lastServiceDate!)
                    : 'Not recorded',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceAlert(MaintenanceAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_getMaintenanceIcon(alert.type), color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Due: ${_formatDate(alert.dueDate)}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart(BikeModel bike) {
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
            'Earnings Trend (Last 7 Days)',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: StreamBuilder<List<InvestorEarningsModel>>(
              stream: ref
                  .read(investorServiceProvider)
                  .getBikeEarnings(bike.id),
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
                          reservedSize: 40,
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
                        color: const Color(0xFF3949AB),
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF3949AB).withValues(alpha: 0.2),
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

  List<FlSpot> _generateEarningsSpots(List<InvestorEarningsModel> earnings) {
    // Group by day for last 7 days
    final now = DateTime.now();
    final dailyEarnings = List.generate(7, (i) => 0.0);

    for (var earning in earnings) {
      final daysDiff = now.difference(earning.createdAt).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        // Use index 6 for today (0 days diff), 5 for yesterday, etc.
        dailyEarnings[6 - daysDiff] += earning.hpDeduction;
      }
    }

    return List.generate(7, (i) => FlSpot(i.toDouble(), dailyEarnings[i]));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'funded':
        return const Color(0xFF3949AB);
      case 'pending_funding':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getMaintenanceIcon(String type) {
    switch (type) {
      case 'oil_change':
        return Icons.water_drop;
      case 'tire_check':
        return Icons.album;
      case 'service_due':
        return Icons.construction;
      case 'repair':
        return Icons.build;
      default:
        return Icons.warning;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
