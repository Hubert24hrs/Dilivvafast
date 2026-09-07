import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/presentation/theme/theme_controller.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/auth/domain/entities/app_mode.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';
import 'package:dilivvafast/features/auth/presentation/controllers/mode_controller.dart';

/// The app's main navigation drawer.
///
/// Its first section is the mode switcher: customer, driver and investor are
/// all listed for every signed-in person, with a status chip showing whether
/// each one is active, under review or not yet applied for. Tapping a mode the
/// user is not entitled to opens that mode's onboarding rather than failing.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final activeMode = ref.watch(activeModeProvider);

    return Drawer(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DrawerHeader(user: user, activeMode: activeMode),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  _SectionLabel('Modes'),
                  ...AppMode.switchable.map(
                    (mode) => _ModeTile(
                      mode: mode,
                      isActive: mode == activeMode,
                      access: user?.accessFor(mode) ?? ModeAccess.none,
                      onTap: () => _switchMode(context, ref, mode),
                    ),
                  ),
                  const _SectionDivider(),
                  ..._itemsForMode(activeMode),
                  const _SectionDivider(),
                  _SectionLabel('Preferences'),
                  const _ThemeTile(),
                  _NavTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: (c) => _push(c, '/settings'),
                  ),
                  _NavTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help centre',
                    onTap: (c) => _push(c, '/help'),
                  ),
                  _NavTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About Dilivvafast',
                    onTap: (c) => _push(c, '/about'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _NavTile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              danger: true,
              onTap: (c) => _confirmLogout(c, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Mode-specific navigation ─────────────────────────────────────────────

  List<Widget> _itemsForMode(AppMode mode) => switch (mode) {
        AppMode.customer => _customerItems(),
        AppMode.driver => _driverItems(),
        AppMode.investor => _investorItems(),
        AppMode.admin => _adminItems(),
      };

  List<Widget> _customerItems() => [
        _SectionLabel('Deliveries'),
        _NavTile(
          icon: Icons.add_box_outlined,
          label: 'Send a package',
          onTap: (c) => _go(c, '/customer/book'),
        ),
        _NavTile(
          icon: Icons.local_shipping_outlined,
          label: 'My orders',
          onTap: (c) => _go(c, '/customer/orders'),
        ),
        _NavTile(
          icon: Icons.location_on_outlined,
          label: 'Saved addresses',
          onTap: (c) => _push(c, '/customer/addresses'),
        ),
        _SectionLabel('Money'),
        _NavTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Wallet',
          onTap: (c) => _go(c, '/customer/wallet'),
        ),
        _NavTile(
          icon: Icons.credit_card_outlined,
          label: 'Payment methods',
          onTap: (c) => _push(c, '/payment-methods'),
        ),
        _NavTile(
          icon: Icons.local_offer_outlined,
          label: 'Promotions',
          onTap: (c) => _push(c, '/customer/promotions'),
        ),
        _NavTile(
          icon: Icons.card_giftcard_outlined,
          label: 'Refer and earn',
          onTap: (c) => _push(c, '/customer/refer'),
        ),
      ];

  List<Widget> _driverItems() => [
        _SectionLabel('Driving'),
        _NavTile(
          icon: Icons.history_rounded,
          label: 'Trip history',
          onTap: (c) => _go(c, '/driver/history'),
        ),
        _NavTile(
          icon: Icons.payments_outlined,
          label: 'Earnings and payouts',
          onTap: (c) => _go(c, '/driver/earnings'),
        ),
        _SectionLabel('Compliance'),
        _NavTile(
          icon: Icons.folder_outlined,
          label: 'Documents',
          onTap: (c) => _push(c, '/driver/documents'),
        ),
        _NavTile(
          icon: Icons.two_wheeler_outlined,
          label: 'Vehicle details',
          onTap: (c) => _push(c, '/driver/vehicle'),
        ),
      ];

  List<Widget> _investorItems() => [
        _SectionLabel('Portfolio'),
        _NavTile(
          icon: Icons.pedal_bike_outlined,
          label: 'My bikes',
          onTap: (c) => _go(c, '/investor/home'),
        ),
        _NavTile(
          icon: Icons.trending_up_rounded,
          label: 'Earnings',
          onTap: (c) => _go(c, '/investor/earnings'),
        ),
      ];

  List<Widget> _adminItems() => [
        _SectionLabel('Operations'),
        _NavTile(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          onTap: (c) => _go(c, '/admin/dashboard'),
        ),
        _NavTile(
          icon: Icons.assignment_outlined,
          label: 'Applications',
          onTap: (c) => _go(c, '/admin/applications'),
        ),
        _NavTile(
          icon: Icons.insights_outlined,
          label: 'Analytics',
          onTap: (c) => _push(c, '/admin/analytics'),
        ),
      ];

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _switchMode(
      BuildContext context, WidgetRef ref, AppMode mode) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    Navigator.of(context).pop();

    final result =
        await ref.read(modeControllerProvider.notifier).requestMode(mode);

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

  /// Used for destinations that live inside a shell so they replace the
  /// current tab instead of stacking a second scaffold and bottom bar on top.
  static void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.palette.danger,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(authRepositoryProvider).logout();
      router.go('/login');
    }
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.user, required this.activeMode});

  final UserModel? user;
  final AppMode activeMode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final name = user?.fullName.trim();
    final initial = (name != null && name.isNotEmpty)
        ? name.characters.first.toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: palette.brandSubtle,
            foregroundImage:
                user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
            child: Text(
              initial,
              style: context.text.titleLarge?.copyWith(color: palette.brand),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name?.isNotEmpty == true ? name! : 'Your account',
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode tile ───────────────────────────────────────────────────────────────

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.isActive,
    required this.access,
    required this.onTap,
  });

  final AppMode mode;
  final bool isActive;
  final ModeAccess access;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = switch (mode) {
      AppMode.customer => palette.brand,
      AppMode.driver => palette.driverAccent,
      AppMode.investor => palette.investorAccent,
      AppMode.admin => palette.info,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Material(
        color: isActive ? accent.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isActive ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(_icon, size: 19, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.label,
                        style: context.text.titleMedium?.copyWith(
                          fontSize: 15,
                          color: isActive ? accent : palette.textPrimary,
                        ),
                      ),
                      Text(
                        isActive ? 'Current mode' : _subtitle,
                        style: context.text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Icon(Icons.check_circle_rounded, size: 20, color: accent)
                else
                  _AccessChip(access: access),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (mode) {
        AppMode.customer => Icons.inventory_2_outlined,
        AppMode.driver => Icons.two_wheeler_outlined,
        AppMode.investor => Icons.trending_up_rounded,
        AppMode.admin => Icons.shield_outlined,
      };

  String get _subtitle => switch (access) {
        ModeAccess.approved => 'Tap to switch',
        ModeAccess.pending => 'Application under review',
        ModeAccess.none => mode.tagline,
        ModeAccess.rejected => 'Application declined',
        ModeAccess.suspended => 'Access suspended',
      };
}

class _AccessChip extends StatelessWidget {
  const _AccessChip({required this.access});

  final ModeAccess access;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (access == ModeAccess.none) {
      return Text(
        'Join',
        style: context.text.bodySmall?.copyWith(
          color: palette.brand,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final (bg, fg) = switch (access) {
      ModeAccess.pending => (palette.warningSubtle, palette.warning),
      ModeAccess.approved => (palette.successSubtle, palette.success),
      ModeAccess.rejected ||
      ModeAccess.suspended =>
        (palette.dangerSubtle, palette.danger),
      ModeAccess.none => (palette.surfaceSunken, palette.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        access.label,
        style: context.text.labelSmall?.copyWith(color: fg, letterSpacing: 0.2),
      ),
    );
  }
}

// ── Shared pieces ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
      child: Text(
        title.toUpperCase(),
        style: context.text.labelSmall,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Divider(height: 1, color: context.palette.border),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;

  /// Accepts the tile's own context so callers can navigate after popping.
  final void Function(BuildContext) onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = danger ? palette.danger : palette.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(icon,
            size: 21, color: danger ? palette.danger : palette.textSecondary),
        title: Text(
          label,
          style: context.text.bodyLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        onTap: () => onTap(context),
      ),
    );
  }
}

/// Cycles system → light → dark without leaving the drawer.
class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(mode.icon, size: 21, color: palette.textSecondary),
        title: Text(
          'Appearance',
          style: context.text.bodyLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          mode.label,
          style: context.text.bodySmall?.copyWith(
            color: palette.brand,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () => ref.read(themeControllerProvider.notifier).cycle(),
      ),
    );
  }
}
