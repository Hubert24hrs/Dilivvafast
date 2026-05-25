import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:fast_delivery/presentation/common/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassCard(
            borderRadius: 50,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/'),
            ),
          ),
        ),
        title: const Text(
          'History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white70,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Rides'),
                Tab(text: 'Deliveries'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const BackgroundOrbs(),
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: userId == null
                ? const Center(child: Text('Please login to view history', style: TextStyle(color: Colors.white)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRidesList(userId),
                      _buildCouriersList(userId),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRidesList(String userId) {
    final ridesStream = ref.watch(databaseServiceProvider).getUserRides(userId);

    return StreamBuilder<List<RideModel>>(
      stream: ridesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        final rides = snapshot.data ?? [];
        if (rides.isEmpty) {
          return EmptyStateWidget(
            title: 'No past rides',
            message: 'Your completed rides will appear here.',
            icon: Icons.directions_car_outlined,
            buttonText: 'Book a Ride',
            onButtonPressed: () => context.go('/booking'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            return _buildHistoryCard(
              title: 'Ride to ${ride.dropoffAddress}',
              subtitle: DateFormat('MMM d, y • h:mm a').format(ride.createdAt),
              price: ride.price,
              status: ride.status,
              icon: Icons.directions_car,
              onTap: () => context.push('/history/details', extra: {'ride': ride}),
            );
          },
        );
      },
    );
  }

  Widget _buildCouriersList(String userId) {
    final couriersStream = ref.watch(databaseServiceProvider).getUserCouriers(userId);

    return StreamBuilder<List<CourierModel>>(
      stream: couriersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        final couriers = snapshot.data ?? [];
        if (couriers.isEmpty) {
          return EmptyStateWidget(
            title: 'No past deliveries',
            message: 'Your delivery history will appear here.',
            icon: Icons.local_shipping_outlined,
            buttonText: 'Send Package',
            onButtonPressed: () => context.go('/courier'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          itemCount: couriers.length,
          itemBuilder: (context, index) {
            final courier = couriers[index];
            return _buildHistoryCard(
              title: 'Delivery: ${courier.packageSize}',
              subtitle: DateFormat('MMM d, y • h:mm a').format(courier.createdAt),
              price: courier.price,
              status: courier.status,
              icon: Icons.local_shipping,
              onTap: () => context.push('/history/details', extra: {'courier': courier}),
            );
          },
        );
      },
    );
  }



  Widget _buildHistoryCard({
    required String title,
    required String subtitle,
    required double price,
    required String status,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    Color statusColor = Colors.grey;
    if (status == 'completed' || status == 'delivered') statusColor = AppTheme.primaryColor;
    if (status == 'cancelled') statusColor = Colors.red;
    if (status == 'accepted' || status == 'picked_up' || status == 'arrived' || status == 'in_progress') statusColor = Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₦${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
