import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/components/app_drawer.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';

/// Customer home.
///
/// Ordered by what someone opening the app actually needs: any delivery in
/// flight first, then the primary action, then wallet and secondary shortcuts.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final activeOrder = ref.watch(activeOrderProvider);
    final walletBalance = ref.watch(walletBalanceProvider);
    // Presence projection, not full user records — customers are not
    // permitted to read the `users` collection.
    final onlineDrivers = ref.watch(onlineDriverPresenceProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Dilivvafast'),
        actions: [
          _NotificationBell(
            count: unread,
            onPressed: () => context.push('/customer/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(activeOrderProvider);
          ref.invalidate(walletBalanceProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _Greeting(name: currentUser.value?.fullName),
            const SizedBox(height: 20),

            // An in-flight delivery is the most time-sensitive thing here, so
            // it sits above the fold when one exists.
            activeOrder.when(
              data: (order) => order == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _ActiveDeliveryCard(order: order),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            _SendPackageCta(onTap: () => context.go('/customer/book')),
            const SizedBox(height: 20),

            _WalletCard(
              balance: walletBalance,
              onTopUp: () => context.push('/wallet/top-up'),
              onOpen: () => context.go('/customer/wallet'),
            ),
            const SizedBox(height: 24),

            _SectionHeading('Shortcuts'),
            const SizedBox(height: 12),
            _ShortcutGrid(),
            const SizedBox(height: 20),

            onlineDrivers.when(
              data: (drivers) => _AvailabilityNote(count: drivers.length),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final firstName = (name == null || name!.trim().isEmpty)
        ? null
        : name!.trim().split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(salutation, style: context.text.bodyMedium),
        const SizedBox(height: 2),
        Text(firstName ?? 'Welcome back', style: context.text.headlineMedium),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return IconButton(
      onPressed: onPressed,
      tooltip: count > 0 ? '$count unread notifications' : 'Notifications',
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: palette.danger,
        label: Text(count > 9 ? '9+' : '$count'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}

// ── Primary action ──────────────────────────────────────────────────────────

class _SendPackageCta extends StatelessWidget {
  const _SendPackageCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.brand,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send a package',
                      style: context.text.titleLarge?.copyWith(
                        color: palette.onBrand,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Door to door across Nigeria',
                      style: context.text.bodyMedium?.copyWith(
                        color: palette.onBrand.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: palette.onBrand),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Active delivery ─────────────────────────────────────────────────────────

class _ActiveDeliveryCard extends StatelessWidget {
  const _ActiveDeliveryCard({required this.order});

  final CourierOrderModel order;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surfaceRaised,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/customer/track/${order.id}'),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusPill(status: order.status),
                  const Spacer(),
                  Text('#${order.trackingCode}', style: context.text.bodySmall),
                ],
              ),
              const SizedBox(height: 14),
              _RoutePoint(
                colour: palette.success,
                label: order.pickupAddress,
                isLast: false,
              ),
              _RoutePoint(
                colour: palette.brand,
                label: order.dropoffAddress,
                isLast: true,
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: palette.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '₦${order.totalFare.toStringAsFixed(0)}',
                    style: context.text.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    'Track delivery',
                    style: context.text.bodyMedium?.copyWith(
                      color: palette.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: palette.brand,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.colour,
    required this.label,
    required this.isLast,
  });

  final Color colour;
  final String label;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: colour,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 1.5, color: palette.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Text(
                label,
                style: context.text.bodyMedium?.copyWith(
                  color: palette.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (bg, fg) = switch (status) {
      OrderStatus.delivered => (palette.successSubtle, palette.success),
      OrderStatus.cancelled => (palette.dangerSubtle, palette.danger),
      OrderStatus.pending => (palette.warningSubtle, palette.warning),
      _ => (palette.infoSubtle, palette.info),
    };

    // "inTransit" reads better as separate words in the UI.
    final label = status.name
        .replaceAllMapped(RegExp('[A-Z]'), (m) => ' ${m[0]!.toLowerCase()}')
        .trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: context.text.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

// ── Wallet ──────────────────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.balance,
    required this.onTopUp,
    required this.onOpen,
  });

  final AsyncValue<double> balance;
  final VoidCallback onTopUp;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surfaceSunken,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wallet balance', style: context.text.bodySmall),
                const SizedBox(height: 4),
                balance.when(
                  data: (value) => Text(
                    '₦${value.toStringAsFixed(2)}',
                    style: context.text.headlineSmall,
                  ),
                  loading: () => Text('₦—', style: context.text.headlineSmall),
                  error: (_, _) => Text(
                    'Unavailable',
                    style: context.text.titleMedium?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onOpen, child: const Text('Details')),
          const SizedBox(width: 4),
          FilledButton(onPressed: onTopUp, child: const Text('Top up')),
        ],
      ),
    );
  }
}

// ── Shortcuts ───────────────────────────────────────────────────────────────

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid();

  @override
  Widget build(BuildContext context) {
    final shortcuts = <(IconData, String, String)>[
      (Icons.receipt_long_outlined, 'My orders', '/customer/orders'),
      (Icons.location_on_outlined, 'Addresses', '/customer/addresses'),
      (Icons.local_offer_outlined, 'Promotions', '/customer/promotions'),
      (Icons.card_giftcard_outlined, 'Refer & earn', '/customer/refer'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        for (final (icon, label, route) in shortcuts)
          _ShortcutTile(icon: icon, label: label, route: route),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surfaceBase,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Shortcuts to shell tabs replace the tab; the rest push a page.
        onTap: () => route == '/customer/orders'
            ? context.go(route)
            : context.push(route),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: palette.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyMedium?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: context.text.titleMedium);
  }
}

class _AvailabilityNote extends StatelessWidget {
  const _AvailabilityNote({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: count > 0 ? palette.success : palette.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          count > 0
              ? '$count ${count == 1 ? 'rider' : 'riders'} available nearby'
              : 'No riders nearby right now',
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}
