import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hp_agreement_model.dart';
import '../models/investor_earnings_model.dart';
import 'notification_service.dart';
import 'dart:convert';

/// Service for handling revenue splits between investor, rider, and app
class RevenueSplitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;

  RevenueSplitService(this._ref);

  // Revenue split percentages
  static const double investorSharePercent = 0.50; // 50% during HP
  static const double riderSharePercentHP = 0.40; // 40% during HP
  static const double riderSharePercentComplete = 0.90; // 90% after HP
  static const double appFeePercent = 0.10; // 10% always

  /// Process revenue split for a completed ride
  /// 
  /// During HP: Investor 50%, Rider 40%, App 10%
  /// After HP: Rider 90%, App 10%, Investor 0%
  Future<InvestorEarningsModel?> processRideSplit({
    required String bikeId,
    required String rideId,
    required double fareAmount,
    String? courierId,
  }) async {
    // Get the bike to find investor
    final bikeDoc = await _firestore.collection('bikes').doc(bikeId).get();
    if (!bikeDoc.exists) {
      debugPrint('RevenueSplitService: Bike $bikeId not found');
      return null;
    }

    final investorId = bikeDoc.data()?['investorId'];
    if (investorId == null) {
      debugPrint('RevenueSplitService: No investor for bike $bikeId');
      return null;
    }

    // Get active HP agreement
    final hpSnapshot = await _firestore
        .collection('hp_agreements')
        .where('bikeId', isEqualTo: bikeId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    bool hpActive = false;
    HPAgreementModel? agreement;
    
    if (hpSnapshot.docs.isNotEmpty) {
      agreement = HPAgreementModel.fromFirestore(hpSnapshot.docs.first);
      hpActive = agreement.remainingBalance > 0;
    }

    // Generate earning record ID
    final earningId = '${rideId}_${DateTime.now().millisecondsSinceEpoch}';
    
    InvestorEarningsModel earning;
    
    if (hpActive && agreement != null) {
      // HP is active - 50/40/10 split
      earning = InvestorEarningsModel.hpActiveSplit(
        id: earningId,
        investorId: investorId,
        bikeId: bikeId,
        rideId: rideId,
        courierId: courierId,
        fareAmount: fareAmount,
      );

      // Deduct from HP balance
      final newBalance = agreement.remainingBalance - earning.investorShare;
      
      await _firestore
          .collection('hp_agreements')
          .doc(agreement.id)
          .update({
        'remainingBalance': newBalance > 0 ? newBalance : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Check if HP is now complete
      if (newBalance <= 0) {
        await _completeHPAgreement(agreement.id, investorId, bikeId);
      }

      // Update investor stats
      await _firestore.collection('investors').doc(investorId).update({
        'totalReturns': FieldValue.increment(earning.investorShare),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('RevenueSplitService: HP active split - Fare: ₦$fareAmount, '
          'Investor: ₦${earning.investorShare}, Rider: ₦${earning.riderShare}, App: ₦${earning.appFee}');
    } else {
      // HP complete or no HP - 90/10 split (investor gets nothing)
      earning = InvestorEarningsModel.hpCompleteSplit(
        id: earningId,
        investorId: investorId,
        bikeId: bikeId,
        rideId: rideId,
        courierId: courierId,
        fareAmount: fareAmount,
      );

      debugPrint('RevenueSplitService: HP complete split - Fare: ₦$fareAmount, '
          'Rider: ₦${earning.riderShare}, App: ₦${earning.appFee}');
    }

    // Save earning record
    await _firestore
        .collection('investor_earnings')
        .doc(earningId)
        .set(earning.toMap());

    // Update bike stats
    await _firestore.collection('bikes').doc(bikeId).update({
      'totalRides': FieldValue.increment(1),
      'totalEarnings': FieldValue.increment(fareAmount),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Notify Investor
    if (earning.investorShare > 0) {
      try {
        await _ref.read(notificationServiceProvider).notifyInvestorEarnings(
              bikeId: bikeId,
              amount: earning.investorShare,
            );
      } catch (e) {
        debugPrint('Error sending investor notification: $e');
      }
    }

    return earning;
  }

  /// Complete HP agreement when fully paid
  Future<void> _completeHPAgreement(
    String agreementId, 
    String investorId, 
    String bikeId,
  ) async {
    // Update agreement status
    await _firestore.collection('hp_agreements').doc(agreementId).update({
      'status': 'completed',
      'actualCompletionDate': DateTime.now().toIso8601String(),
      'remainingBalance': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Update bike status
    await _firestore.collection('bikes').doc(bikeId).update({
      'status': 'completed',
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Update investor stats
    await _firestore.collection('investors').doc(investorId).update({
      'activeBikes': FieldValue.increment(-1),
      'completedHPAgreements': FieldValue.increment(1),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    debugPrint('RevenueSplitService: HP agreement $agreementId completed! Bike now owned by rider.');

    debugPrint('RevenueSplitService: HP agreement $agreementId completed! Bike now owned by rider.');

    // Send push notification to both investor and rider
    try {
      await _ref.read(notificationServiceProvider).showLocalNotification(
            title: '🎉 HP Agreement Completed!',
            body: 'Congratulations! The Hire Purchase agreement for this bike is now complete.',
            payload: json.encode({
              'type': 'hp_complete',
              'bikeId': bikeId,
              'agreementId': agreementId,
            }),
          );
    } catch (e) {
      debugPrint('Error sending completion notification: $e');
    }
  }

  /// Get HP progress for a bike
  Future<Map<String, dynamic>?> getHPProgress(String bikeId) async {
    final snapshot = await _firestore
        .collection('hp_agreements')
        .where('bikeId', isEqualTo: bikeId)
        .where('status', whereIn: ['pending_rider', 'active'])
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final agreement = HPAgreementModel.fromFirestore(snapshot.docs.first);
    
    return {
      'agreementId': agreement.id,
      'principalAmount': agreement.principalAmount,
      'totalRepayment': agreement.totalRepayment,
      'remainingBalance': agreement.remainingBalance,
      'amountPaid': agreement.amountPaid,
      'progressPercentage': agreement.progressPercentage,
      'isComplete': agreement.isComplete,
      'projectedCompletionDate': agreement.projectedCompletionDate,
      'status': agreement.status,
    };
  }

  /// Calculate expected rider earnings for a bike
  Map<String, double> calculateRiderEarnings(double fareAmount, bool hpActive) {
    if (hpActive) {
      return {
        'riderShare': fareAmount * riderSharePercentHP,
        'investorShare': fareAmount * investorSharePercent,
        'appFee': fareAmount * appFeePercent,
      };
    } else {
      return {
        'riderShare': fareAmount * riderSharePercentComplete,
        'investorShare': 0,
        'appFee': fareAmount * appFeePercent,
      };
    }
  }
}

/// Provider for RevenueSplitService
final revenueSplitServiceProvider = Provider<RevenueSplitService>((ref) {
  return RevenueSplitService(ref);
});
