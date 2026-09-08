import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';

class ReferEarnScreen extends ConsumerWidget {
  const ReferEarnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final referralCode = currentUser?.referralCode ?? '---';

    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        backgroundColor: context.palette.surfaceRaised,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.card_giftcard, size: 80, color: context.palette.brand),
            const SizedBox(height: 16),
            Text(
              'Earn ₦500 per Friend!',
              style: TextStyle(
                color: context.palette.onBrand,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Invite your friends to Dilivvafast. When they sign up and complete their first delivery, you both get ₦500 added to your wallet!',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Code Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.palette.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.palette.brand.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'YOUR REFERRAL CODE',
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        referralCode,
                        style: TextStyle(
                          color: context.palette.brand,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          color: context.palette.textSecondary,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Referral code copied to clipboard!',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  final text =
                      'Join Dilivvafast using my referral code $referralCode and get ₦500 off your first delivery! Download at https://dilivvafast.app';
                  // ignore: deprecated_member_use
                  Share.share(text);
                },
                icon: const Icon(Icons.share),
                label: const Text(
                  'Share Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'YOUR REFERRALS',
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: ref
                  .watch(firestoreProvider)
                  .collection('referrals')
                  .where('referralCode', isEqualTo: referralCode)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: context.palette.brand,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Card(
                    color: context.palette.surfaceRaised,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No referrals yet. Start sharing to earn rewards!',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    final bonusPaid = data['bonusPaid'] ?? false;

                    return Card(
                      color: context.palette.surfaceRaised,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: context.palette.brand,
                          child: Icon(
                            Icons.person,
                            color: context.palette.onBrand,
                          ),
                        ),
                        title: Text(
                          'Referral #${d.id.substring(0, 6)}',
                          style: TextStyle(color: context.palette.onBrand),
                        ),
                        subtitle: Text(
                          'Status: $status',
                          style: TextStyle(
                            color: context.palette.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          bonusPaid ? '+₦500' : 'Pending',
                          style: TextStyle(
                            color: bonusPaid
                                ? context.palette.success
                                : context.palette.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
