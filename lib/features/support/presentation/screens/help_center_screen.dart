import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const List<Map<String, String>> faqs = [
    {
      'question': 'How do I place a delivery request?',
      'answer':
          'Tap "Send Package" on the home screen, select your package size/category, set the pickup and dropoff locations on the map, verify the calculated fare, and confirm your booking.',
    },
    {
      'question': 'How is the delivery fare calculated?',
      'answer':
          'Fares are calculated using a base fare plus distance-based and weight-based rates. Any active surge pricing or promotion discounts are automatically factored in.',
    },
    {
      'question': 'How do I fund my wallet?',
      'answer':
          'Go to the Wallet screen or tap "Top Up" on your home screen. Enter your desired amount and complete payment via Paystack using card, bank transfer, or USSD.',
    },
    {
      'question': 'What items are prohibited for delivery?',
      'answer':
          'Prohibited items include illegal substances, dangerous chemicals, firearms, explosives, unsealed liquids, and live animals. Couriers inspect packages before pickup.',
    },
    {
      'question': 'How can I become a driver partner?',
      'answer':
          'Switch your account role to Driver during registration or in Profile, submit your valid driver license, vehicle registration, and ID documents for verification.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Help Center & FAQs'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          ...faqs.map(
            (faq) => Card(
              color: AppTheme.surfaceColor,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                iconColor: AppTheme.primaryColor,
                collapsedIconColor: Colors.white70,
                title: Text(
                  faq['question']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      faq['answer']!,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Card(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.headset_mic_outlined,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Need Additional Assistance?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Our support team is available 24/7 to assist with active orders, account issues, or billing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'support@dilivvafast.app',
                        queryParameters: {'subject': 'Dilivvafast App Support'},
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    },
                    icon: const Icon(Icons.email),
                    label: const Text('Email Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
