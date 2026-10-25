import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dilivvafast/core/constants/app_constants.dart';
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
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Help Center & FAQs'),
        backgroundColor: context.palette.surfaceRaised,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          ...faqs.map(
            (faq) => Card(
              color: context.palette.surfaceRaised,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                iconColor: context.palette.brand,
                collapsedIconColor: context.palette.textSecondary,
                title: Text(
                  faq['question']!,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      faq['answer']!,
                      style: TextStyle(
                        color: context.palette.textSecondary,
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
            color: context.palette.brand.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: context.palette.brand.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.headset_mic_outlined,
                    size: 48,
                    color: context.palette.brand,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Need Additional Assistance?',
                    style: TextStyle(
                      color: context.palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ask Maya for instant answers, or message our support '
                    'team about orders, accounts or payments.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // The assistant and the support chat both existed but
                  // nothing in the app opened either from here.
                  FilledButton.icon(
                    onPressed: () => context.push('/support/chat'),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Ask Maya'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/support-chat'),
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Message support'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: AppConstants.supportEmail,
                        queryParameters: {'subject': 'Dilivvafast App Support'},
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Email support'),
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
