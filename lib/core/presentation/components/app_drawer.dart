import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dilivvafast/core/constants/app_constants.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/auth/domain/entities/app_mode.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';
import 'package:dilivvafast/features/auth/presentation/controllers/mode_controller.dart';

/// Side menu, laid out after inDrive.
///
/// Profile header (photo, name, rating) on top, a plain list of destinations
/// in the middle, and one large lime button at the foot that flips between
/// customer and driver mode. Investor and admin access stay reachable through
/// small links under that button, shown only to accounts that have them.
///
/// Log out lives in Settings, as it does in inDrive.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const _lime = Color(0xFFC1F11D);
  static const _ink = Color(0xFF111827);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final activeMode = ref.watch(activeModeProvider);
    final here = _currentPath(context);

    final otherModes = <AppMode>[
      if (activeMode != AppMode.investor &&
          user?.accessFor(AppMode.investor) == ModeAccess.approved)
        AppMode.investor,
      if (activeMode != AppMode.admin && user?.role == UserRole.admin)
        AppMode.admin,
    ];

    final toggleTarget = activeMode == AppMode.customer
        ? AppMode.driver
        : AppMode.customer;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            _ProfileHeader(
              user: user,
              onTap: () => _push(context, _profileRoute(activeMode)),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final item in _itemsFor(activeMode))
                    _MenuItem(
                      icon: item.icon,
                      label: item.label,
                      selected: here == item.route,
                      onTap: () => item.replacesTab
                          ? _go(context, item.route)
                          : _push(context, item.route),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => _switchMode(context, ref, toggleTarget),
                  style: FilledButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: _ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    toggleTarget == AppMode.driver
                        ? 'Driver mode'
                        : 'Customer mode',
                  ),
                ),
              ),
            ),
            if (otherModes.isNotEmpty)
              Wrap(
                spacing: 4,
                children: [
                  for (final mode in otherModes)
                    TextButton(
                      onPressed: () => _switchMode(context, ref, mode),
                      child: Text(
                        '${mode.label} mode',
                        style: const TextStyle(color: Color(0xFF4B5563)),
                      ),
                    ),
                ],
              ),
            const _SocialLinks(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Destinations per mode ────────────────────────────────────────────────

  static String _profileRoute(AppMode mode) => switch (mode) {
    AppMode.driver => '/driver/profile',
    AppMode.investor => '/investor/profile',
    _ => '/customer/profile',
  };

  static List<_Item> _itemsFor(AppMode mode) {
    const shared = [
      _Item(
        Icons.notifications_none_rounded,
        'Notifications',
        '/customer/notifications',
      ),
      _Item(Icons.shield_outlined, 'Safety', '/safety'),
      _Item(Icons.settings_outlined, 'Settings', '/settings'),
      _Item(Icons.info_outline_rounded, 'Help', '/help'),
      _Item(Icons.forum_outlined, 'Support', '/support-chat'),
    ];

    return switch (mode) {
      AppMode.customer => const [
        _Item(
          Icons.directions_car_outlined,
          'City',
          '/customer/home',
          tab: true,
        ),
        _Item(
          Icons.history_rounded,
          'Request history',
          '/customer/orders',
          tab: true,
        ),
        _Item(
          Icons.inventory_2_outlined,
          'Couriers',
          '/customer/book',
          tab: true,
        ),
        _Item(
          Icons.account_balance_wallet_outlined,
          'Wallet',
          '/customer/wallet',
          tab: true,
        ),
        _Item(Icons.place_outlined, 'Saved addresses', '/customer/addresses'),
        _Item(Icons.local_offer_outlined, 'Promotions', '/customer/promotions'),
        _Item(Icons.card_giftcard_outlined, 'Refer & earn', '/customer/refer'),
        ...shared,
      ],
      AppMode.driver => const [
        _Item(
          Icons.two_wheeler_outlined,
          'Requests',
          '/driver/home',
          tab: true,
        ),
        _Item(
          Icons.history_rounded,
          'Trip history',
          '/driver/history',
          tab: true,
        ),
        _Item(
          Icons.payments_outlined,
          'Earnings',
          '/driver/earnings',
          tab: true,
        ),
        _Item(Icons.folder_outlined, 'Documents', '/driver/documents'),
        _Item(Icons.badge_outlined, 'Vehicle', '/driver/vehicle'),
        ...shared,
      ],
      AppMode.investor => const [
        _Item(
          Icons.pedal_bike_outlined,
          'My bikes',
          '/investor/home',
          tab: true,
        ),
        _Item(
          Icons.trending_up_rounded,
          'Earnings',
          '/investor/earnings',
          tab: true,
        ),
        ...shared,
      ],
      AppMode.admin => const [
        _Item(
          Icons.dashboard_outlined,
          'Dashboard',
          '/admin/dashboard',
          tab: true,
        ),
        _Item(
          Icons.assignment_outlined,
          'Applications',
          '/admin/applications',
          tab: true,
        ),
        _Item(Icons.insights_outlined, 'Analytics', '/admin/analytics'),
        _Item(Icons.support_agent_outlined, 'Support inbox', '/admin/support'),
        _Item(Icons.local_offer_outlined, 'Promo codes', '/admin/promos'),
        _Item(Icons.map_outlined, 'Delivery zones', '/admin/zones'),
        ...shared,
      ],
    };
  }

  /// The current route, for highlighting. Absent outside a router (tests).
  static String? _currentPath(BuildContext context) {
    try {
      return GoRouterState.of(context).matchedLocation;
    } catch (_) {
      return null;
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _switchMode(
    BuildContext context,
    WidgetRef ref,
    AppMode mode,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    Navigator.of(context).pop();

    final result = await ref
        .read(modeControllerProvider.notifier)
        .requestMode(mode);

    switch (result) {
      case ModeSwitched(:final route):
        router.go(route);
      case ModeEnrollmentRequired(:final route):
        router.push(route);
      case ModeAwaitingReview(:final mode):
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Your ${mode.label.toLowerCase()} application is still under '
              'review. We will let you know as soon as it is approved.',
            ),
          ),
        );
      case ModeUnavailable(:final reason):
        messenger.showSnackBar(SnackBar(content: Text(reason)));
      case ModeSwitchFailed(:final message):
        messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  static void _push(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.push(route);
  }

  /// Destinations that live inside a shell replace the current tab instead
  /// of stacking a second scaffold on top.
  static void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }
}

class _Item {
  const _Item(this.icon, this.label, this.route, {this.tab = false});

  final IconData icon;
  final String label;
  final String route;
  final bool tab;

  bool get replacesTab => tab;
}

// ── Header ───────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onTap});

  final UserModel? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName.trim() ?? '';
    final firstName = name.isEmpty ? 'Your account' : name.split(' ').first;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final rating = user?.rating ?? 0;
    final count = user?.totalDeliveries ?? 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFFF3F4F6),
              foregroundImage: user?.photoUrl != null
                  ? NetworkImage(user!.photoUrl!)
                  : null,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: context.palette.brand,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppDrawer._ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _RatingRow(rating: rating, count: count),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: AppDrawer._ink,
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) {
      return const Text(
        'New on Dilivvafast',
        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      );
    }
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i - 0.25
                ? Icons.star_rounded
                : rating >= i - 0.75
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            size: 20,
            color: const Color(0xFFF5B301),
          ),
        const SizedBox(width: 6),
        Text(
          '${rating.toStringAsFixed(2)} ($count)',
          style: const TextStyle(fontSize: 15, color: Color(0xFF374151)),
        ),
      ],
    );
  }
}

// ── Menu rows ────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF1EFEA) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 26, color: const Color(0xFF4B5563)),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppDrawer._ink,
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

/// Facebook and Instagram, shown only once real URLs are configured in
/// [AppConstants] — a guessed handle could point at someone else's page.
class _SocialLinks extends StatelessWidget {
  const _SocialLinks();

  @override
  Widget build(BuildContext context) {
    final links = <(IconData, String, String)>[
      if (AppConstants.facebookUrl.isNotEmpty)
        (Icons.facebook_rounded, 'Facebook', AppConstants.facebookUrl),
      if (AppConstants.instagramUrl.isNotEmpty)
        (Icons.camera_alt_outlined, 'Instagram', AppConstants.instagramUrl),
    ];
    if (links.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (icon, label, url) in links)
          IconButton(
            tooltip: label,
            iconSize: 30,
            color: AppDrawer._ink,
            icon: Icon(icon),
            onPressed: () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
      ],
    );
  }
}
