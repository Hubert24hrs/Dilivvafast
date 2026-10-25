import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: context.palette.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.brand),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: context.palette.danger),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'Not signed in',
                style: TextStyle(color: context.palette.textSecondary),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
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
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: context.palette.surfaceBase,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.role.name.toUpperCase(),
                    style: TextStyle(
                      color: context.palette.brand,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Info sections
                _infoTile(context, Icons.phone, 'Phone', user.phone),
                _infoTile(
                  context,
                  Icons.qr_code,
                  'Referral Code',
                  user.referralCode,
                ),
                _infoTile(
                  context,
                  Icons.star,
                  'Rating',
                  '${user.rating.toStringAsFixed(1)} ⭐',
                ),
                _infoTile(
                  context,
                  Icons.calendar_today,
                  'Member Since',
                  '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                ),

                const SizedBox(height: 28),

                // Menu items
                _menuTile(context, Icons.lock, 'Change Password', () {}),
                _menuTile(
                  context,
                  Icons.notifications_outlined,
                  'Notifications',
                  () {},
                ),
                _menuTile(context, Icons.help_outline, 'Help & Support', () {}),
                _menuTile(context, Icons.info_outline, 'About', () {}),

                const SizedBox(height: 20),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE91E63),
                      side: const BorderSide(color: Color(0xFFE91E63)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.palette.brand, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: context.palette.textPrimary, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: context.palette.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.palette.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.palette.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: context.palette.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
