import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider);

    return Drawer(
      backgroundColor: AppTheme.surfaceColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            _DrawerHeader(currentUser: currentUser),

            // ── Menu items ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: role == UserRole.driver
                    ? _driverItems(context)
                    : _customerItems(context),
              ),
            ),

            // ── Bottom divider + logout ─────────────────────────────────
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              textColor: AppTheme.errorColor,
              iconColor: AppTheme.errorColor,
              onTap: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Customer menu items ──────────────────────────────────────────────────

  List<Widget> _customerItems(BuildContext context) => [
        _DrawerSection(title: 'MY ACCOUNT'),
        _DrawerItem(
          icon: Icons.person_outline_rounded,
          label: 'Profile',
          onTap: () => _navigate(context, '/customer/profile'),
        ),
        _DrawerItem(
          icon: Icons.local_shipping_outlined,
          label: 'My Orders',
          onTap: () => _navigate(context, '/customer/orders'),
        ),
        _DrawerItem(
          icon: Icons.location_on_outlined,
          label: 'Saved Addresses',
          onTap: () => _navigate(context, '/customer/addresses'),
        ),
        _DrawerItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Wallet & Payments',
          onTap: () => _navigate(context, '/customer/wallet'),
        ),
        _DrawerItem(
          icon: Icons.credit_card_outlined,
          label: 'Payment Methods',
          onTap: () => _navigate(context, '/payment-methods'),
        ),

        _DrawerSection(title: 'OFFERS'),
        _DrawerItem(
          icon: Icons.local_offer_outlined,
          label: 'Promotions & Coupons',
          onTap: () => _navigate(context, '/customer/promotions'),
        ),
        _DrawerItem(
          icon: Icons.card_giftcard_outlined,
          label: 'Refer & Earn',
          onTap: () => _navigate(context, '/customer/refer'),
        ),

        _DrawerSection(title: 'SUPPORT'),
        _DrawerItem(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () => _navigate(context, '/customer/notifications'),
        ),
        _DrawerItem(
          icon: Icons.help_outline_rounded,
          label: 'Help Center',
          onTap: () => _navigate(context, '/help'),
        ),
        _DrawerItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat with Support',
          onTap: () => _navigate(context, '/support-chat'),
        ),

        _DrawerSection(title: 'SETTINGS'),
        _DrawerItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () => _navigate(context, '/settings'),
        ),
        _DrawerItem(
          icon: Icons.info_outline_rounded,
          label: 'About Dilivvafast',
          onTap: () => _navigate(context, '/about'),
        ),
        _DrawerItem(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          onTap: () => _navigate(context, '/legal/privacy'),
        ),
        _DrawerItem(
          icon: Icons.description_outlined,
          label: 'Terms of Service',
          onTap: () => _navigate(context, '/legal/terms'),
        ),
        _DrawerItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Account',
          textColor: AppTheme.errorColor,
          iconColor: AppTheme.errorColor,
          onTap: () => _navigate(context, '/settings/delete-account'),
        ),
      ];

  // ── Driver menu items ────────────────────────────────────────────────────

  List<Widget> _driverItems(BuildContext context) => [
        _DrawerSection(title: 'MY ACCOUNT'),
        _DrawerItem(
          icon: Icons.person_outline_rounded,
          label: 'Profile',
          onTap: () => _navigate(context, '/driver/profile'),
        ),
        _DrawerItem(
          icon: Icons.history_rounded,
          label: 'Trip History',
          onTap: () => _navigate(context, '/driver/history'),
        ),
        _DrawerItem(
          icon: Icons.attach_money_rounded,
          label: 'Earnings & Payouts',
          onTap: () => _navigate(context, '/driver/earnings'),
        ),

        _DrawerSection(title: 'DOCUMENTS'),
        _DrawerItem(
          icon: Icons.folder_outlined,
          label: 'Documents & Verification',
          onTap: () => _navigate(context, '/driver/documents'),
        ),
        _DrawerItem(
          icon: Icons.directions_bike_outlined,
          label: 'Vehicle Details',
          onTap: () => _navigate(context, '/driver/vehicle'),
        ),

        _DrawerSection(title: 'SUPPORT'),
        _DrawerItem(
          icon: Icons.help_outline_rounded,
          label: 'Help Center',
          onTap: () => _navigate(context, '/help'),
        ),
        _DrawerItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () => _navigate(context, '/settings'),
        ),
        _DrawerItem(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Account',
          textColor: AppTheme.errorColor,
          iconColor: AppTheme.errorColor,
          onTap: () => _navigate(context, '/settings/delete-account'),
        ),
      ];

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pop(); // close drawer first
    context.push(route);
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authRepositoryProvider).logout();
      if (context.mounted) context.go('/login');
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.currentUser});

  final AsyncValue<UserModel?> currentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: currentUser.when(
        loading: () => const _HeaderSkeleton(),
        error: (_, _) => const _HeaderSkeleton(),
        data: (user) => Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              backgroundImage:
                  user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null
                  ? Text(
                      (user?.fullName.isNotEmpty == true)
                          ? user!.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _roleLabel(user?.role),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
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

  String _roleLabel(UserRole? role) {
    return switch (role) {
      UserRole.customer => 'CUSTOMER',
      UserRole.driver => 'DRIVER',
      UserRole.admin => 'ADMIN',
      UserRole.investor => 'INVESTOR',
      null => 'USER',
    };
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.cardColor,
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 120, height: 14, color: AppTheme.cardColor),
            const SizedBox(height: 6),
            Container(width: 80, height: 11, color: AppTheme.cardColor),
          ],
        ),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Item ──────────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor = Colors.white,
    this.iconColor = Colors.white70,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minLeadingWidth: 28,
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.white.withValues(alpha: 0.05),
      splashColor: AppTheme.primaryColor.withValues(alpha: 0.08),
    );
  }
}
