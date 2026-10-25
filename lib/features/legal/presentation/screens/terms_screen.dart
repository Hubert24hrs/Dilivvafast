import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dilivvafast/core/constants/app_constants.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String termsMarkdown =
      '''
# Terms of Service

**Effective Date:** January 1, 2026

Welcome to Dilivvafast. By downloading, accessing, or using our mobile application, you agree to be bound by these Terms of Service.

## 1. Description of Service

Dilivvafast provides an on-demand logistics matching platform connecting senders ("Customers") with independent dispatch couriers ("Drivers").

## 2. User Accounts & Verification

- Users must be at least 18 years of age.
- You are responsible for maintaining the confidentiality of your account credentials.
- Drivers must provide accurate documentation (driver license, vehicle registration) prior to receiving delivery assignments.

## 3. Payments & Cancellations

- Delivery fees are displayed before order confirmation.
- Payments are processed securely through Paystack or via internal wallet balance.
- Cancellations requested before a driver is dispatched incur no fee. Cancellations made en-route may incur a nominal cancellation fee.

## 4. Prohibited Items & Conduct

Users agree not to send illegal, hazardous, flammable, or stolen items. Dilivvafast reserves the right to inspect packages and terminate accounts violating safety guidelines.

## 5. Limitation of Liability

Dilivvafast provides logistics facilitation. Max compensation for lost or damaged non-insured packages is subject to declared item valuation rules.

## 6. Governing Law

These Terms are governed by the laws of the Federal Republic of Nigeria.

## 7. Contact Us

For questions regarding these Terms, contact ${AppConstants.legalEmail}.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: context.palette.surfaceRaised,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final Uri url = Uri.parse(AppConstants.termsUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Markdown(
        data: termsMarkdown,
        styleSheet: MarkdownStyleSheet(
          h1: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          h2: TextStyle(
            color: context.palette.brand,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          p: TextStyle(color: context.palette.textSecondary, height: 1.5),
          listBullet: TextStyle(color: context.palette.brand),
        ),
      ),
    );
  }
}
