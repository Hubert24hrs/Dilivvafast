import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/earnings_model.dart';

class EarningsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Record earnings for a completed ride
  Future<void> recordEarning({
    required String driverId,
    required String rideId,
    required double amount,
    double platformFee = 0.15,
  }) async {
    final earning = EarningsModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      driverId: driverId,
      rideId: rideId,
      amount: amount,
      platformFee: platformFee,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('earnings')
        .doc(earning.id)
        .set(earning.toMap());
  }

  // Get driver's earnings stream
  Stream<List<EarningsModel>> getDriverEarnings(String driverId) {
    return _firestore
        .collection('earnings')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EarningsModel.fromFirestore(doc))
            .toList());
  }

  // Get available balance
  Future<double> getAvailableBalance(String driverId) async {
    final snapshot = await _firestore
        .collection('earnings')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'available')
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final earning = EarningsModel.fromFirestore(doc);
      total += earning.netAmount;
    }
    return total;
  }

  // Get earnings summary (today, week, month, total)
  Future<Map<String, double>> getEarningsSummary(String driverId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await _firestore
        .collection('earnings')
        .where('driverId', isEqualTo: driverId)
        .get();

    double today = 0, week = 0, month = 0, total = 0;

    for (var doc in snapshot.docs) {
      final earning = EarningsModel.fromFirestore(doc);
      total += earning.netAmount;

      if (earning.createdAt.isAfter(startOfDay)) {
        today += earning.netAmount;
      }
      if (earning.createdAt.isAfter(startOfWeek)) {
        week += earning.netAmount;
      }
      if (earning.createdAt.isAfter(startOfMonth)) {
        month += earning.netAmount;
      }
    }

    return {
      'today': today,
      'week': week,
      'month': month,
      'total': total,
    };
  }

  // Request withdrawal (Mock flow - will integrate Paystack later)
  Future<WithdrawalModel> requestWithdrawal({
    required String driverId,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    // Check available balance
    final balance = await getAvailableBalance(driverId);
    if (amount > balance) {
      throw Exception('Insufficient balance. Available: ₦${balance.toStringAsFixed(2)}');
    }

    // Create withdrawal request
    final withdrawal = WithdrawalModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      driverId: driverId,
      amount: amount,
      bankName: bankName,
      accountNumber: accountNumber,
      accountName: accountName,
      status: 'processing', // Mock: goes straight to processing
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('withdrawals')
        .doc(withdrawal.id)
        .set(withdrawal.toMap());

    // Mark earnings as withdrawn (up to the amount)
    double remaining = amount;
    final earnings = await _firestore
        .collection('earnings')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt')
        .get();

    for (var doc in earnings.docs) {
      if (remaining <= 0) break;
      final earning = EarningsModel.fromFirestore(doc);
      
      await doc.reference.update({
        'status': 'withdrawn',
        'withdrawalId': withdrawal.id,
      });
      
      remaining -= earning.netAmount;
    }

    // Mock: Complete the withdrawal after a short delay
    Future.delayed(const Duration(seconds: 2), () async {
      await _firestore.collection('withdrawals').doc(withdrawal.id).update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'reference': 'MOCK_${withdrawal.id}',
      });
    });

    return withdrawal;
  }

  // Get withdrawal history
  Stream<List<WithdrawalModel>> getWithdrawalHistory(String driverId) {
    return _firestore
        .collection('withdrawals')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WithdrawalModel.fromFirestore(doc))
            .toList());
  }
}
