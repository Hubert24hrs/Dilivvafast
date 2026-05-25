import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dilivvafast/core/models/rider_payment_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Platform commission rate charged to riders.
const double kPlatformCommissionRate = 0.10; // 10%

/// Number of rides before rider must pay.
const int kRidesPerPaymentCycle = 3;

/// Firestore collection where rider payment statuses are stored.
const String kRiderPaymentCollection = 'rider_payment_status';

/// Service that manages the rider payment cycle:
///  - Records each completed ride's 10% fee.
///  - Blocks the rider after [kRidesPerPaymentCycle] rides.
///  - Clears debt and unblocks after Paystack payment is confirmed.
class RiderPaymentService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RiderPaymentService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ─────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────

  String? get _currentRiderId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _doc(String riderId) =>
      _db.collection(kRiderPaymentCollection).doc(riderId);

  /// Stream of the current rider's payment status.
  Stream<RiderPaymentStatus> statusStream(String riderId) {
    return _doc(riderId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return RiderPaymentStatus(
          riderId: riderId,
          completedRidesCount: 0,
          accumulatedDebt: 0,
          isBlocked: false,
        );
      }
      return RiderPaymentStatus.fromMap(snap.data()!);
    });
  }

  /// Fetch current status once.
  Future<RiderPaymentStatus> fetchStatus(String riderId) async {
    final snap = await _doc(riderId).get();
    if (!snap.exists || snap.data() == null) {
      return RiderPaymentStatus(
        riderId: riderId,
        completedRidesCount: 0,
        accumulatedDebt: 0,
        isBlocked: false,
      );
    }
    return RiderPaymentStatus.fromMap(snap.data()!);
  }

  // ─────────────────────────────────────────────────────────────
  // WRITE — called when a ride completes
  // ─────────────────────────────────────────────────────────────

  /// Call this immediately after a ride is marked "completed".
  /// [fareAmount] is the full ride fare in Naira.
  /// Returns the updated status.
  Future<RiderPaymentStatus> recordCompletedRide({
    required String riderId,
    required double fareAmount,
  }) async {
    final current = await fetchStatus(riderId);
    final commission = fareAmount * kPlatformCommissionRate;

    final newCount = current.completedRidesCount + 1;
    final newDebt = current.accumulatedDebt + commission;
    final newFares = [...current.lastRideFares, fareAmount];

    final shouldBlock = newCount >= kRidesPerPaymentCycle;

    final updated = current.copyWith(
      completedRidesCount: newCount,
      accumulatedDebt: newDebt,
      isBlocked: shouldBlock,
      lastRideFares: newFares,
    );

    await _doc(riderId).set(updated.toMap(), SetOptions(merge: true));

    // Update rider's global online/status field in users collection
    if (shouldBlock) {
      await _db.collection('users').doc(riderId).update({
        'riderStatus': 'blocked',
        'isOnline': false,
      });
      await _sendBlockedNotification(riderId, newDebt, newCount);
    }

    debugPrint('[RiderPayment] Ride recorded. Count=$newCount Debt=₦$newDebt Blocked=$shouldBlock');
    return updated;
  }

  // ─────────────────────────────────────────────────────────────
  // WRITE — called after successful Paystack payment (webhook)
  // ─────────────────────────────────────────────────────────────

  /// Clears debt, resets counter, unblocks rider.
  /// Call this from the Paystack webhook Cloud Function
  /// OR directly after client-side payment verification.
  Future<void> clearDebtAndUnblock(String riderId) async {
    final reset = RiderPaymentStatus(
      riderId: riderId,
      completedRidesCount: 0,
      accumulatedDebt: 0,
      isBlocked: false,
      lastPaymentAt: DateTime.now(),
      lastRideFares: [],
    );
    await _doc(riderId).set(reset.toMap());

    // Re-activate rider in the users collection
    await _db.collection('users').doc(riderId).update({
      'riderStatus': 'active',
      'isOnline': true,
    });

    debugPrint('[RiderPayment] Debt cleared for $riderId. Rider re-activated.');
  }

  // ─────────────────────────────────────────────────────────────
  // CHECK — called before assigning any delivery request
  // ─────────────────────────────────────────────────────────────

  /// Returns true if the rider is allowed to accept new requests.
  Future<bool> canAcceptRequest(String riderId) async {
    final status = await fetchStatus(riderId);
    return !status.isBlocked;
  }

  // ─────────────────────────────────────────────────────────────
  // ADMIN
  // ─────────────────────────────────────────────────────────────

  /// Stream of all riders currently blocked (for admin dashboard).
  Stream<List<RiderPaymentStatus>> blockedRidersStream() {
    return _db
        .collection(kRiderPaymentCollection)
        .where('isBlocked', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => RiderPaymentStatus.fromMap(d.data())).toList());
  }

  // ─────────────────────────────────────────────────────────────
  // PRIVATE
  // ─────────────────────────────────────────────────────────────

  Future<void> _sendBlockedNotification(
      String riderId, double debt, int rideCount) async {
    try {
      // Get the rider's FCM token
      final userSnap = await _db.collection('users').doc(riderId).get();
      final fcmToken = userSnap.data()?['fcmToken'] as String?;
      if (fcmToken == null) return;

      // The actual push is sent from Cloud Functions via Admin SDK.
      // Here we store a notification document for the CF trigger.
      await _db.collection('notifications_queue').add({
        'token': fcmToken,
        'title': '🔴 Payment Required',
        'body':
            'You have completed $rideCount rides. Please pay ₦${debt.toStringAsFixed(0)} to continue receiving requests.',
        'riderId': riderId,
        'type': 'rider_payment_blocked',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[RiderPayment] Failed to queue notification: $e');
    }
  }
}
