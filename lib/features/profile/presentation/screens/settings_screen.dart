import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dilivvafast/core/presentation/theme/theme_controller.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _orderUpdates = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.palette.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: context.palette.textPrimary, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile summary
            userAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (user) {
                if (user == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceRaised,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.palette.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: context.palette.brand.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: context.palette.brand,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: TextStyle(
                                color: context.palette.onBrand,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: context.palette.textSecondary,
                                fontSize: 12,
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
                          color: const Color(
                            0xFF4CAF50,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          user.role.name.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Appearance section
            _sectionHeader('Appearance'),
            const SizedBox(height: 8),
            const _AppearancePicker(),
            const SizedBox(height: 28),

            // Notifications section
            _sectionHeader('Notifications'),
            const SizedBox(height: 8),
            _switchTile(
              icon: Icons.notifications_active,
              title: 'Push Notifications',
              subtitle: 'Receive push notifications',
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
              color: context.palette.brand,
            ),
            _switchTile(
              icon: Icons.local_shipping,
              title: 'Order Updates',
              subtitle: 'Status changes for your deliveries',
              value: _orderUpdates,
              onChanged: (v) => setState(() => _orderUpdates = v),
              color: const Color(0xFF4CAF50),
            ),
            _switchTile(
              icon: Icons.campaign,
              title: 'Promotions',
              subtitle: 'Deals, discounts, and offers',
              value: _promotions,
              onChanged: (v) => setState(() => _promotions = v),
              color: const Color(0xFFFF9800),
            ),
            const SizedBox(height: 24),

            // About section
            _sectionHeader('About'),
            const SizedBox(height: 8),
            _linkTile(
              icon: Icons.description,
              title: 'Terms of Service',
              onTap: () => _openUrl(
                'https://hubert24hrs.github.io/Dilivvafast/terms.html',
              ),
            ),
            _linkTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () => _openUrl(
                'https://hubert24hrs.github.io/Dilivvafast/privacy.html',
              ),
            ),
            _linkTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => _openUrl(
                'https://hubert24hrs.github.io/Dilivvafast/support.html',
              ),
            ),
            const SizedBox(height: 24),

            // App info
            _sectionHeader('App'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.palette.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.palette.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Version',
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '1.0.0',
                    style: TextStyle(
                      color: context.palette.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, ref),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5252),
                  side: const BorderSide(color: Color(0xFFFF5252)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Delete account
            Center(
              child: TextButton(
                onPressed: () => _confirmDeleteAccount(context, ref),
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    color: context.palette.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.palette.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.palette.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveThumbColor: context.palette.textMuted,
            inactiveTrackColor: context.palette.border,
          ),
        ],
      ),
    );
  }

  Widget _linkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        tileColor: context.palette.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: context.palette.textMuted, size: 20),
        title: Text(
          title,
          style: TextStyle(color: context.palette.textPrimary, fontSize: 14),
        ),
        trailing: Icon(Icons.chevron_right, color: context.palette.textMuted),
        onTap: onTap,
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.palette.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out',
          style: TextStyle(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: context.palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Color(0xFFFF5252)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.palette.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account',
          style: TextStyle(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? This action is irreversible and all your data will be permanently wiped.',
          style: TextStyle(color: context.palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (!context.mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5252)),
                ),
              );

              final result = await ref
                  .read(authRepositoryProvider)
                  .deleteAccount();

              if (!context.mounted) return;
              Navigator.pop(context); // Dismiss loading dialog

              result.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(failure.message),
                      backgroundColor: context.palette.danger,
                    ),
                  );
                },
                (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Your account has been deleted successfully.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.go('/login');
                },
              );
            },
            child: const Text(
              'Delete permanently',
              style: TextStyle(color: Color(0xFFFF5252)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Light / dark / follow-system selector.
class _AppearancePicker extends ConsumerWidget {
  const _AppearancePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final current = ref.watch(themeModeProvider);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceSunken,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          for (final mode in ThemeMode.values)
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    ref.read(themeControllerProvider.notifier).setMode(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: mode == current
                        ? palette.surfaceRaised
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: mode == current
                          ? palette.border
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        mode.icon,
                        size: 20,
                        color: mode == current
                            ? palette.brand
                            : palette.textMuted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode.label,
                        style: context.text.bodySmall?.copyWith(
                          color: mode == current
                              ? palette.textPrimary
                              : palette.textMuted,
                          fontWeight: mode == current
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
