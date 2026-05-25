import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a unique referral code for a user
  String generateReferralCode(String userId) {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    return 'FAST$code';
  }

  // Get or create referral code for user
  Future<String> getOrCreateReferralCode(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (userDoc.exists && userDoc.data()?['referralCode'] != null) {
      return userDoc.data()!['referralCode'];
    }

    // Generate and save new code
    final code = generateReferralCode(userId);
    await _firestore.collection('users').doc(userId).update({
      'referralCode': code,
    });
    return code;
  }

  // Apply referral code
  Future<ReferralResult> applyReferralCode(String userId, String code) async {
    // Check if code is valid
    final referrerQuery = await _firestore
        .collection('users')
        .where('referralCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (referrerQuery.docs.isEmpty) {
      return ReferralResult(success: false, message: 'Invalid referral code');
    }

    final referrerId = referrerQuery.docs.first.id;

    // Check if user already used a referral
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.data()?['referredBy'] != null) {
      return ReferralResult(success: false, message: 'You have already used a referral code');
    }

    // Can't use own code
    if (referrerId == userId) {
      return ReferralResult(success: false, message: 'You cannot use your own referral code');
    }

    // Apply referral
    await _firestore.collection('users').doc(userId).update({
      'referredBy': referrerId,
      'referralBonusReceived': true,
    });

    // Track referral for referrer
    await _firestore.collection('users').doc(referrerId).collection('referrals').add({
      'userId': userId,
      'appliedAt': FieldValue.serverTimestamp(),
    });

    // Increment referrer's referral count
    await _firestore.collection('users').doc(referrerId).update({
      'referralCount': FieldValue.increment(1),
    });

    return ReferralResult(
      success: true,
      message: 'Referral applied! You both get ₦100 bonus.',
      bonusAmount: 100.0,
    );
  }

  // Get referral stats for a user
  Future<ReferralStats> getReferralStats(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final referralsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('referrals')
        .get();

    return ReferralStats(
      referralCode: userDoc.data()?['referralCode'] ?? '',
      referralCount: referralsQuery.docs.length,
      totalEarnings: referralsQuery.docs.length * 100.0, // ₦100 per referral
    );
  }
}

class ReferralResult {
  final bool success;
  final String message;
  final double bonusAmount;

  ReferralResult({
    required this.success,
    required this.message,
    this.bonusAmount = 0.0,
  });
}

class ReferralStats {
  final String referralCode;
  final int referralCount;
  final double totalEarnings;

  ReferralStats({
    required this.referralCode,
    required this.referralCount,
    required this.totalEarnings,
  });
}
