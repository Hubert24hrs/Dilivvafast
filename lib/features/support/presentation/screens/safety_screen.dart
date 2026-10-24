import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/features/support/presentation/widgets/sos_alert_button.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

/// Safety — reached from the side menu and the home screen's "screened and
/// verified" banner.
///
/// Every claim here describes something the platform actually does: drivers
/// are approved by an admin who reviews their licence and ID (signed-URL
/// access, audit-logged), customers see a courier's verified name, rating and
/// plate before accepting, and SOS alerts reach the admin team.
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _ink,
        title: const Text(
          'Safety',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                SosAlertButton(size: 60),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency SOS',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Alerts our safety team immediately with your '
                        'account and current delivery.',
                        style: TextStyle(color: _muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _Point(
            icon: Icons.verified_user_outlined,
            title: 'Every courier is reviewed',
            body:
                'Couriers submit a driving licence, government ID and vehicle '
                'photos. Our team reviews them before anyone can take a job.',
          ),
          const _Point(
            icon: Icons.badge_outlined,
            title: 'You see who you are choosing',
            body:
                'Each offer shows the courier\'s name, rating and vehicle, '
                'taken from their verified profile — couriers cannot edit it.',
          ),
          const _Point(
            icon: Icons.location_on_outlined,
            title: 'Live tracking',
            body:
                'Follow your package on the map from pickup to drop-off. Your '
                'courier only sees your details for the job they are doing.',
          ),
          const _Point(
            icon: Icons.lock_outline_rounded,
            title: 'Payments stay protected',
            body:
                'Card payments are handled by Paystack. We never see or store '
                'your card details.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/support-chat'),
            icon: const Icon(Icons.forum_outlined),
            label: const Text('Report a safety concern'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: _ink),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: _muted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
