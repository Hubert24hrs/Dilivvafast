import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String policyMarkdown = '''
# Privacy Policy

**Effective Date:** January 1, 2026

Dilivvafast ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how your personal information is collected, used, and disclosed by Dilivvafast.

## 1. Information We Collect

- **Personal Information:** Name, email address, phone number, profile photo, and delivery addresses provided during registration and booking.
- **Location Data:** We collect precise and coarse location data from your device to match pick-up/drop-off locations and enable real-time tracking for active deliveries (including background location for driver partners).
- **Payment Information:** Processed securely via Paystack. We do not store raw credit/debit card numbers on our servers.
- **Device & Technical Information:** Device model, operating system, unique device identifiers, IP address, and crash reports collected via Firebase Analytics and Crashlytics.

## 2. How We Use Your Information

- To provide, maintain, and improve our logistics services.
- To process transactions and send order confirmations/receipts.
- To facilitate driver-customer communication regarding package delivery.
- To ensure platform security, prevent fraud, and comply with legal obligations.

## 3. Sharing of Information

We share information only as necessary to fulfill deliveries:
- With dispatch drivers assigned to your delivery.
- With third-party service providers (Firebase, Mapbox, Paystack) operating under strict data protection standards.
- When required by law or to protect rights and safety.

## 4. Your Rights & Data Deletion

You have the right to access, correct, or request deletion of your personal data at any time directly in-app under **Settings → Delete Account**, or by contacting privacy@dilivvafast.app.

## 5. Contact Us

If you have questions about this policy, please reach out to us at privacy@dilivvafast.app.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final Uri url = Uri.parse(
                'https://hubert24hrs.github.io/Dilivvafast/privacy.html',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Markdown(
        data: policyMarkdown,
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          h2: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          p: const TextStyle(color: Colors.white70, height: 1.5),
          listBullet: const TextStyle(color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}
