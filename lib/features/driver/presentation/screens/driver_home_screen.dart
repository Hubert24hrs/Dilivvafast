import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/presentation/components/app_drawer.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/booking/presentation/widgets/address_search_field.dart';
import 'package:dilivvafast/features/driver/presentation/controllers/driver_route_controller.dart';
import 'package:dilivvafast/core/services/route_matching_service.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(driverRouteControllerProvider);
    final routeCtrl = ref.read(driverRouteControllerProvider.notifier);
    final user = ref.watch(currentUserProvider).value;
    final earnings = ref.watch(driverOrdersProvider).value ?? [];

    final todayEarnings = earnings
        .where(
          (o) =>
              o.deliveredAt != null && o.deliveredAt!.day == DateTime.now().day,
        )
        .fold(0.0, (sum, o) => sum + o.driverEarnings);

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with greeting + online toggle
            _buildTopBar(
              context,
              user?.fullName ?? 'Driver',
              routeState,
              routeCtrl,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row
                    _buildStatsRow(
                      context,
                      todayEarnings,
                      earnings.length,
                      user?.rating ?? 0,
                    ),
                    const SizedBox(height: 24),

                    // Route setup section
                    if (!routeState.hasRoute) ...[
                      _buildRouteSetup(context, routeState, routeCtrl),
                    ] else ...[
                      // Active route banner
                      _buildActiveRouteBanner(context, routeState, routeCtrl),
                      const SizedBox(height: 20),

                      // En-route orders
                      if (routeState.enRouteOrders.isNotEmpty) ...[
                        _buildSectionHeader(
                          context,
                          'Orders Along Your Route',
                          '${routeState.enRouteCount} available',
                        ),
                        const SizedBox(height: 12),
                        ...routeState.enRouteOrders.map(
                          (enRoute) => _buildEnRouteOrderCard(
                            context,
                            enRoute,
                            routeCtrl,
                          ),
                        ),
                      ] else
                        _buildEmptyState(context),
                    ],

                    const SizedBox(height: 24),

                    // Pending orders (all available)
                    _buildAllPendingOrders(context, ref),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    String name,
    DriverRouteState state,
    DriverRouteController ctrl,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.palette.surfaceBase,
            context.palette.surfaceRaised.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu, color: context.palette.textPrimary),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 4),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  context.palette.brand,
                  context.palette.brand.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'D',
                style: TextStyle(
                  color: context.palette.surfaceBase,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name',
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  state.isOnline ? 'You\'re online' : 'You\'re offline',
                  style: TextStyle(
                    color: state.isOnline
                        ? const Color(0xFF4CAF50)
                        : context.palette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Online toggle
          GestureDetector(
            onTap: ctrl.toggleOnline,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 64,
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                color: state.isOnline
                    ? const Color(0xFF4CAF50)
                    : context.palette.surfaceRaised,
                border: Border.all(
                  color: state.isOnline
                      ? const Color(0xFF4CAF50)
                      : context.palette.textMuted,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: state.isOnline
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.palette.textPrimary,
                  ),
                  child: Icon(
                    state.isOnline ? Icons.power : Icons.power_off,
                    size: 16,
                    color: state.isOnline
                        ? const Color(0xFF4CAF50)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    double earnings,
    int deliveries,
    double rating,
  ) {
    return Row(
      children: [
        _statCard(
          context,
          'Today',
          '₦${earnings.toStringAsFixed(0)}',
          Icons.attach_money,
          const Color(0xFF4CAF50),
        ),
        const SizedBox(width: 12),
        _statCard(
          context,
          'Deliveries',
          '$deliveries',
          Icons.local_shipping,
          context.palette.brand,
        ),
        const SizedBox(width: 12),
        _statCard(
          context,
          'Rating',
          rating.toStringAsFixed(1),
          Icons.star,
          const Color(0xFFFFAB00),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.palette.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Widget _buildRouteSetup(
    BuildContext context,
    DriverRouteState state,
    DriverRouteController ctrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.palette.brand.withValues(alpha: 0.08),
            context.palette.brand.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.palette.brand.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: context.palette.brand, size: 22),
              SizedBox(width: 8),
              Text(
                'Set Your Route',
                style: TextStyle(
                  color: context.palette.onBrand,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tell us where you\'re heading and we\'ll find deliveries along your path',
            style: TextStyle(color: context.palette.textPrimary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          AddressSearchField(
            label: 'Your current location',
            icon: Icons.my_location,
            onAddressSelected: ctrl.setOrigin,
          ),
          const SizedBox(height: 12),
          AddressSearchField(
            label: 'Where are you heading?',
            icon: Icons.flag,
            onAddressSelected: ctrl.setDestination,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (state.originLat != 0 && state.destinationLat != 0)
                  ? ctrl.buildRouteAndFindOrders
                  : null,
              icon: state.isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.palette.surfaceBase,
                      ),
                    )
                  : const Icon(Icons.search, size: 18),
              label: Text(state.isLoading ? 'Searching...' : 'Find Deliveries'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.brand,
                foregroundColor: context.palette.surfaceBase,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRouteBanner(
    BuildContext context,
    DriverRouteState state,
    DriverRouteController ctrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation, color: Color(0xFF4CAF50), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Route',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${state.originAddress} → ${state.destinationAddress}',
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: context.palette.textSecondary,
              size: 20,
            ),
            onPressed: ctrl.clearRoute,
          ),
        ],
      ),
    );
  }

  Widget _buildEnRouteOrderCard(
    BuildContext context,
    EnRouteOrder enRoute,
    DriverRouteController ctrl,
  ) {
    final order = enRoute.order;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.brand.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with fare and distance
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.palette.brand.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₦${order.driverEarnings.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: context.palette.brand,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${enRoute.detourKm.toStringAsFixed(1)}km detour',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${enRoute.distanceFromRoute.toStringAsFixed(1)}km away',
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route
          _orderRouteRow(
            context,
            Icons.location_on,
            order.pickupAddress,
            context.palette.brand,
          ),
          const SizedBox(height: 6),
          _orderRouteRow(
            context,
            Icons.flag,
            order.dropoffAddress,
            context.palette.brand,
          ),
          const SizedBox(height: 6),

          // Package info
          Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: context.palette.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '${order.packageCategory.name} • ${order.packageWeight}kg',
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ctrl.declineOrder(order.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.palette.textSecondary,
                    side: BorderSide(color: context.palette.textMuted),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => ctrl.acceptOrder(order.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.brand,
                    foregroundColor: context.palette.surfaceBase,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Accept Delivery',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderRouteRow(
    BuildContext context,
    IconData icon,
    String address,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: TextStyle(color: context.palette.textPrimary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 48,
              color: context.palette.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No deliveries along your route yet',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 14,
              ),
            ),
            Text(
              'We\'ll notify you when orders become available',
              style: TextStyle(color: context.palette.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String badge) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: context.palette.brand.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            badge,
            style: TextStyle(color: context.palette.brand, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildAllPendingOrders(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingOrdersProvider);

    return pendingAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: context.palette.brand),
      ),
      error: (e, _) =>
          Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (orders) {
        if (orders.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'All Pending Orders',
              '${orders.length}',
            ),
            const SizedBox(height: 12),
            ...orders
                .take(5)
                .map(
                  (order) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.palette.surfaceRaised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.palette.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.pickupAddress,
                                style: TextStyle(
                                  color: context.palette.textPrimary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '→ ${order.dropoffAddress}',
                                style: TextStyle(
                                  color: context.palette.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₦${order.driverEarnings.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: context.palette.brand,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
