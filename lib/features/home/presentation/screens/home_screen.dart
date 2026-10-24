import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/components/app_drawer.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/widgets/live_map.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/booking/presentation/controllers/courier_booking_controller.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

/// Customer home, laid out after inDrive.
///
/// A live map fills the top of the screen with the pickup point pinned over
/// it. Below sits a single white panel: a trust banner, the courier service
/// picker (bike or car), the "Where to & for how much?" entry point that
/// opens price negotiation, and recent destinations. Navigation lives in the
/// side menu, so there is no bottom bar here.
///
/// Pickup, vehicle and destination are written straight into the booking
/// controller, so the booking screen opens already filled in.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final booking = ref.read(courierBookingControllerProvider);
      if (!booking.hasPickup && !booking.isLoadingLocation) {
        ref
            .read(courierBookingControllerProvider.notifier)
            .initializeLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(courierBookingControllerProvider);
    final controller = ref.read(courierBookingControllerProvider.notifier);
    final activeOrder = ref.watch(activeOrderProvider).value;
    final unread = ref.watch(unreadNotificationCountProvider);
    final media = MediaQuery.of(context);
    final mapHeight = media.size.height * 0.46;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: mapHeight + 32, // runs under the panel's rounded corners
            child: LiveMap(
              centerLat: booking.hasPickup ? booking.pickupLat : null,
              centerLng: booking.hasPickup ? booking.pickupLng : null,
              bottomPadding: 32,
            ),
          ),

          // ── Floating controls ───────────────────────────────────────────
          Positioned(
            top: media.padding.top + 12,
            left: 16,
            child: _RoundButton(
              icon: Icons.menu_rounded,
              tooltip: 'Menu',
              badge: unread > 0,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          Positioned(
            top: mapHeight * 0.30,
            left: 0,
            right: 0,
            child: Center(
              child: _PickupCard(
                label: booking.pickupDisplayText,
                loading: booking.isLoadingLocation,
                onTap: () => context.go('/customer/book'),
              ),
            ),
          ),
          Positioned(
            top: mapHeight - 64,
            right: 16,
            child: _RoundButton(
              icon: Icons.near_me_outlined,
              tooltip: 'Use my location',
              onTap: controller.initializeLocation,
            ),
          ),

          // ── Panel ───────────────────────────────────────────────────────
          Positioned.fill(
            top: mapHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  media.padding.bottom + 16,
                ),
                children: [
                  if (activeOrder != null) ...[
                    _ActiveDeliveryStrip(order: activeOrder),
                    const SizedBox(height: 14),
                  ],
                  const _TrustBanner(),
                  const SizedBox(height: 16),
                  _ServicePicker(
                    selected: booking.vehicleType,
                    onSelected: controller.setVehicleType,
                  ),
                  const SizedBox(height: 14),
                  _WhereToBar(onTap: () => context.go('/customer/book')),
                  const SizedBox(height: 8),
                  _RecentDestinations(
                    onPick: (order) {
                      controller.setDropoff(
                        order.dropoffAddress,
                        order.dropoffGeoPoint.latitude,
                        order.dropoffGeoPoint.longitude,
                      );
                      context.go('/customer/book');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map overlays ─────────────────────────────────────────────────────────────

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 26, color: const Color(0xFF111827)),
                if (badge)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: context.palette.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickupCard extends StatelessWidget {
  const _PickupCard({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          elevation: 4,
          shadowColor: const Color(0x33000000),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Pickup point',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loading ? 'Finding you…' : label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF111827),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // The pin under the card, pointing at the pickup on the map.
        Container(width: 3, height: 18, color: const Color(0xFF111827)),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7DF6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ],
    );
  }
}

// ── Panel contents ───────────────────────────────────────────────────────────

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'All our couriers are screened and verified',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => context.push('/safety'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Learn more'),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 110,
            height: 120,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E5BFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.two_wheeler_rounded, size: 64, color: Colors.white),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Icon(
                    Icons.verified_rounded,
                    size: 24,
                    color: Color(0xFFC1F11D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bike or car — the area the redesign brief circled.
class _ServicePicker extends StatelessWidget {
  const _ServicePicker({required this.selected, required this.onSelected});

  final CourierVehicle selected;
  final ValueChanged<CourierVehicle> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final vehicle in CourierVehicle.values) ...[
          Expanded(
            child: _ServiceTile(
              vehicle: vehicle,
              selected: vehicle == selected,
              onTap: () => onSelected(vehicle),
            ),
          ),
          if (vehicle != CourierVehicle.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final CourierVehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = vehicle == CourierVehicle.bike
        ? Icons.two_wheeler_rounded
        : Icons.directions_car_filled_rounded;
    final subtitle = vehicle == CourierVehicle.bike
        ? 'Fast, small parcels'
        : 'Bigger loads';

    // One spoken label for the whole tile, rather than a screen reader
    // stepping through the icon, the name and the subtitle separately.
    return Semantics(
      selected: selected,
      button: true,
      label: '${vehicle.label} courier, $subtitle',
      excludeSemantics: true,
      child: Material(
        color: selected ? const Color(0xFFD6ECFA) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 34, color: const Color(0xFF111827)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhereToBar extends StatelessWidget {
  const _WhereToBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1EFEA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 26, color: Color(0xFF111827)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Where to & for how much?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The customer's last few distinct destinations, newest first.
class _RecentDestinations extends ConsumerWidget {
  const _RecentDestinations({required this.onPick});

  final ValueChanged<CourierOrderModel> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(customerOrdersProvider).value ?? const [];
    final seen = <String>{};
    final recent = <CourierOrderModel>[];
    for (final o in orders) {
      final key = o.dropoffAddress.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      recent.add(o);
      if (recent.length == 3) break;
    }

    if (recent.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Your recent destinations will appear here.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    return Column(
      children: [
        for (final order in recent)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const Icon(
              Icons.history_rounded,
              color: Color(0xFF6B7280),
            ),
            title: Text(
              order.dropoffAddress.split(',').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            subtitle: Text(
              order.dropoffAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            onTap: () => onPick(order),
          ),
      ],
    );
  }
}

/// A delivery in flight takes priority over starting a new one.
class _ActiveDeliveryStrip extends StatelessWidget {
  const _ActiveDeliveryStrip({required this.order});

  final CourierOrderModel order;

  @override
  Widget build(BuildContext context) {
    final searching = order.status == OrderStatus.pending;
    return Material(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          searching ? '/matching/${order.id}' : '/customer/track/${order.id}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                searching ? Icons.radar_rounded : Icons.local_shipping_rounded,
                color: const Color(0xFFC1F11D),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      searching
                          ? 'Waiting for courier offers'
                          : 'Delivery on the way',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      order.dropoffAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
