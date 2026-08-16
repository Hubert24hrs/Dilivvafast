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
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('About Dilivvafast'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.delivery_dining,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'DILIVVAFAST',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version $_version (Build $_buildNumber)',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              const Text(
                'Dilivvafast is Nigeria\'s premier tech-driven logistics and courier delivery network. Connecting individuals, merchants, and enterprise businesses with reliable, real-time tracked dispatch riders.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                color: AppTheme.surfaceColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _infoRow('Developer', 'Dilivvafast Technologies Ltd'),
                      const Divider(color: Colors.white10),
                      _infoRow('Website', 'https://dilivvafast.app'),
                      const Divider(color: Colors.white10),
                      _infoRow('Contact Email', 'support@dilivvafast.app'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '© 2026 Dilivvafast Inc. All rights reserved.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
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
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
