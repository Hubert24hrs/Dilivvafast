import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.1';
  String _buildNumber = '2';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      // The user can pop this screen while the platform channel is still in
      // flight; calling setState on a disposed State throws.
      if (!mounted) return;
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (e) {
      debugPrint('AboutScreen: could not read package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('About Dilivvafast'),
        backgroundColor: context.palette.surfaceRaised,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delivery_dining,
                size: 80,
                color: context.palette.brand,
              ),
              const SizedBox(height: 16),
              Text(
                'DILIVVAFAST',
                style: TextStyle(
                  color: context.palette.brand,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version $_version (Build $_buildNumber)',
                style: TextStyle(color: context.palette.textSecondary),
              ),
              const SizedBox(height: 24),
              Text(
                'Dilivvafast is Nigeria\'s premier tech-driven logistics and courier delivery network. Connecting individuals, merchants, and enterprise businesses with reliable, real-time tracked dispatch riders.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                color: context.palette.surfaceRaised,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _infoRow('Developer', 'Dilivvafast Technologies Ltd'),
                      Divider(color: context.palette.border),
                      _infoRow('Website', 'https://dilivvafast.app'),
                      Divider(color: context.palette.border),
                      _infoRow('Contact Email', 'support@dilivvafast.app'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '© 2026 Dilivvafast Inc. All rights reserved.',
                style: TextStyle(
                  color: context.palette.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.palette.textSecondary)),
        Text(
          val,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
