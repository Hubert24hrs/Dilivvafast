import 'package:fast_delivery/core/models/bike_model.dart';
import 'package:fast_delivery/presentation/common/empty_state_widget.dart';
import 'package:fast_delivery/core/models/hp_agreement_model.dart';
import 'package:fast_delivery/core/models/investor_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/app_drawer.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class InvestorDashboardScreen extends ConsumerStatefulWidget {
  const InvestorDashboardScreen({super.key});

  @override
  ConsumerState<InvestorDashboardScreen> createState() =>
      _InvestorDashboardScreenState();
}

class _InvestorDashboardScreenState
    extends ConsumerState<InvestorDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // 1. Watch Investor Profile using existing currentInvestorProvider
    final investorAsync = ref.watch(currentInvestorProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            const BackgroundOrbs(),
            investorAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
              error: (error, stack) => Center(
                child: EmptyStateWidget(
                  title: 'Error Loading Dashboard',
                  message: error.toString(),
                  icon: Icons.error_outline,
                ),
              ),
              data: (investor) {
                if (investor == null) {
                  return Center(
                    child: EmptyStateWidget(
                      title: 'Investor Profile Not Found',
                      message: 'Please complete your investor onboarding',
                      icon: Icons.person_off,
                      buttonText: 'Go Back',
                      onButtonPressed: () => context.pop(),
                    ),
                  );
                }

                final bikesAsync = ref.watch(investorBikesProvider);
                final agreementsAsync = ref.watch(investorAgreementsProvider);
                
                final bikes = bikesAsync.value ?? [];
                final agreements = agreementsAsync.value ?? [];

                return _buildDashboard(investor, bikes, agreements);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(
    InvestorModel investor,
    List<BikeModel> bikes,
    List<HPAgreementModel> agreements,
  ) {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(investor),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(investor)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0)
                      .shimmer(delay: 600.ms, duration: 1200.ms),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Quick Actions'),
                  const SizedBox(height: 16),
                  _buildQuickActions().animate().fadeIn(
                    delay: 200.ms,
                    duration: 400.ms,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Your Bikes (${bikes.length})'),
                  const SizedBox(height: 16),
                  if (bikes.isEmpty)
                    _buildEmptyBikes()
                  else
                    ...bikes.asMap().entries.map(
                      (entry) => _buildBikeCard(entry.value, agreements)
                          .animate()
                          .fadeIn(delay: (300 + entry.key * 100).ms)
                          .slideX(begin: 0.1, end: 0),
                    ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('AI Insights'),
                  const SizedBox(height: 16),
                  _buildAIInsightsCard().animate().fadeIn(
                    delay: 500.ms,
                    duration: 400.ms,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(InvestorModel investor) {
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
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Investor Dashboard',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  investor.displayName ?? 'Welcome back!',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // KYC Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: investor.isKycComplete
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: investor.isKycComplete ? Colors.green : Colors.orange,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  investor.isKycComplete ? Icons.verified : Icons.pending,
                  size: 14,
                  color: investor.isKycComplete ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  investor.isKycComplete ? 'Verified' : 'Pending',
                  style: GoogleFonts.plusJakartaSans(
                    color: investor.isKycComplete
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 11,
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

  Widget _buildBalanceCard(InvestorModel investor) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF00FF94)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Available Balance',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₦',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatAmount(investor.walletBalance),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: MediaQuery.of(context).size.width * 0.08, // Responsive font size
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/investor/withdraw');
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        'Withdraw',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1A237E),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  'Invested',
                  '₦${_formatAmount(investor.totalInvested)}',
                  Icons.trending_up,
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _buildMiniStat(
                  'Returns',
                  '₦${_formatAmount(investor.totalReturns)}',
                  Icons.attach_money,
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                _buildMiniStat(
                  'Bikes',
                  '${investor.activeBikes}',
                  Icons.motorcycle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildActionChip(
            Icons.add_circle,
            'Fund Bike',
            () => context.push('/investor/fund-bike'),
          ),
          const SizedBox(width: 12),
          _buildActionChip(
            Icons.bar_chart,
            'Earnings',
            () => context.push('/investor/earnings'),
          ),
          const SizedBox(width: 12),
          _buildActionChip(
            Icons.history,
            'Withdrawals',
            () => context.push('/investor/withdraw'),
          ),
          const SizedBox(width: 12),
          _buildActionChip(
            Icons.settings,
            'Settings',
            () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceColor,
              AppTheme.surfaceColor.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBikes() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: EmptyStateWidget(
        title: 'No bikes yet',
        message: 'Fund your first bike to start earning returns',
        icon: Icons.motorcycle_outlined,
        buttonText: 'Fund a Bike',
        onButtonPressed: () => context.push('/investor/fund-bike'),
      ),
    );
  }

  Widget _buildBikeCard(BikeModel bike, List<HPAgreementModel> agreements) {
    final agreement = agreements.where((a) => a.bikeId == bike.id).firstOrNull;
    final progress = agreement?.progressPercentage ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withValues(alpha: 0.8),
          ],
        ),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/investor/bike/${bike.id}'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3949AB).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.motorcycle,
                        color: Color(0xFF3949AB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bike.displayName,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          bike.status,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
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
                if (agreement != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HP Progress',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white12,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress >= 1.0
                                      ? Colors.green
                                      : const Color(0xFF3949AB),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBikeStatItem('Rides', '${bike.totalRides}'),
                      _buildBikeStatItem(
                        'Earnings',
                        '₦${_formatAmount(bike.totalEarnings)}',
                      ),
                      _buildBikeStatItem(
                        'Remaining',
                        '₦${_formatAmount(agreement.remainingBalance)}',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBikeStatItem(String label, String value) {
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

  Widget _buildAIInsightsCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getInsights(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Fund your first bike to unlock AI insights',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final insight = snapshot.data!.first;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.2),
                Colors.purple.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    insight['title'] ?? 'AI Insight',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                insight['message'] ?? '',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getInsights() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return [];
    return ref.read(investorServiceProvider).getAIInsights(userId);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'funded':
        return AppTheme.primaryColor;
      case 'pending_funding':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'repossessed':
        return Colors.red;
      default:
        return Colors.grey;
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
}
