
import 'package:fast_delivery/core/models/user_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/providers/settings_provider.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _showLanguageDialog(String currentLang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Select Language', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'French', 'Spanish'].map((lang) {
            return RadioListTile<String>(
              title: Text(lang, style: const TextStyle(color: Colors.white70)),
              value: lang,
              // ignore: deprecated_member_use
              groupValue: currentLang,
              activeColor: AppTheme.primaryColor,
              // ignore: deprecated_member_use
              onChanged: (val) {
                ref.read(settingsProvider.notifier).setLanguage(val!);
                Navigator.pop(context);
              },
              controlAffinity: ListTileControlAffinity.leading,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Theme Mode', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            {'label': 'System', 'value': ThemeMode.system},
            {'label': 'Dark', 'value': ThemeMode.dark},
            {'label': 'Light', 'value': ThemeMode.light},
          ].map((item) {
            final mode = item['value'] as ThemeMode;
            final label = item['label'] as String;
            return RadioListTile<ThemeMode>(
              title: Text(label, style: const TextStyle(color: Colors.white70)),
              value: mode,
              // ignore: deprecated_member_use
              groupValue: currentMode,
              activeColor: AppTheme.primaryColor,
              // ignore: deprecated_member_use
              onChanged: (val) {
                ref.read(settingsProvider.notifier).setThemeMode(val!);
                Navigator.pop(context);
              },
              controlAffinity: ListTileControlAffinity.leading,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final controller = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. To confirm, type "DELETE" below.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  hintStyle: TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                ),
                onChanged: (val) {
                  setState(() {
                    canDelete = val == 'DELETE';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: canDelete
                  ? () async {
                      Navigator.pop(dialogContext);
                      await ref.read(authServiceProvider).signOut();
                      // ignore: use_build_context_synchronously
                      if (mounted) context.go('/login');
                    }
                  : null,
              child: Text('Delete', style: TextStyle(color: canDelete ? Colors.red : Colors.white24)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotImplemented() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!', style: TextStyle(color: Colors.black)),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final userId = ref.watch(currentUserIdProvider);
    final userAsync = userId != null 
        ? ref.watch(databaseServiceProvider).getUserStream(userId)
        : const Stream<UserModel?>.empty();

    return StreamBuilder<UserModel?>(
      stream: userAsync,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GlassCard(
                borderRadius: 50,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(), 
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
                  children: [
                _buildSectionHeader('ACCOUNT'),
                GlassCard(
                  child: Column(
                    children: [
                      _buildListTile(
                        title: 'Phone Number',
                        subtitle: user?.phoneNumber ?? 'Not set',
                        icon: Icons.phone,
                        onTap: () {}, // Already set in profile
                      ),
                      const Divider(height: 1, color: Colors.white10, indent: 60),
                       _buildListTile(
                        title: 'Email',
                        subtitle: user?.email ?? '---',
                        icon: Icons.email,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                _buildSectionHeader('PREFERENCES'),
                GlassCard(
                  child: Column(
                    children: [
                      _buildListTile(
                        title: 'Language',
                        subtitle: settings.language,
                        icon: Icons.language,
                        onTap: () => _showLanguageDialog(settings.language),
                      ),
                      const Divider(height: 1, color: Colors.white10, indent: 60),
                      _buildListTile(
                        title: 'Theme',
                        subtitle: _getThemeLabel(settings.themeMode),
                        icon: Icons.brightness_6,
                        onTap: () => _showThemeDialog(settings.themeMode),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader('SUPPORT'),
                 GlassCard(
                  child: Column(
                    children: [
                      _buildListTile(
                        title: 'Help Center',
                        icon: Icons.help_outline,
                        onTap: _showNotImplemented,
                      ),
                      const Divider(height: 1, color: Colors.white10, indent: 60),
                      _buildListTile(
                        title: 'Terms & Privacy',
                        icon: Icons.privacy_tip_outlined,
                        onTap: _showNotImplemented,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                GlassCard(
                   color: Colors.red.withValues(alpha: 0.1),
                   borderColor: Colors.red.withValues(alpha: 0.3),
                   child: Column(
                     children: [
                       _buildListTile(
                          title: 'Log Out',
                          icon: Icons.logout,
                          iconColor: Colors.redAccent,
                          textColor: Colors.redAccent,
                          onTap: () async {
                            await ref.read(authServiceProvider).signOut();
                            if (mounted) context.go('/login');
                          },
                        ),
                        const Divider(height: 1, color: Colors.white10, indent: 60),
                        _buildListTile(
                          title: 'Delete Account',
                          icon: Icons.delete_forever,
                          iconColor: Colors.red,
                          textColor: Colors.red,
                          onTap: _showDeleteAccountDialog,
                        ),
                     ],
                   ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
            ],
          ),
        );
      }
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.light: return 'Light';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.white).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white70, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 13)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
