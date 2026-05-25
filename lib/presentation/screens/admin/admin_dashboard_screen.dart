import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/screens/admin/tabs/admin_analytics_tab.dart';
import 'package:fast_delivery/presentation/screens/admin/tabs/admin_drivers_tab.dart';
import 'package:fast_delivery/presentation/screens/admin/tabs/admin_investors_tab.dart';
import 'package:fast_delivery/presentation/screens/admin/tabs/admin_withdrawals_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const BackgroundOrbs(),
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        AdminAnalyticsTab(),
                        AdminDriversTab(),
                        AdminInvestorsTab(),
                        AdminWithdrawalsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Analytics', icon: Icon(Icons.dashboard)),
              Tab(text: 'Drivers', icon: Icon(Icons.drive_eta)),
              Tab(text: 'Investors', icon: Icon(Icons.business_center)),
              Tab(text: 'Withdrawals', icon: Icon(Icons.account_balance_wallet)),
            ],
          ),
        ],
      ),
    );
  }
}
