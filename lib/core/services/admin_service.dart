import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/driver_application_model.dart';
import 'package:fast_delivery/core/models/investor_earnings_model.dart';
import 'package:fast_delivery/core/models/investor_model.dart';

class AdminService {
  final FirebaseFirestore _firestore;

  AdminService(this._firestore);

  // --- Analytics ---

  /// Stream of basic platform stats
  Stream<Map<String, dynamic>> getAnalytics() {
    // Note: In a real large-scale app, you'd use Cloud Functions to aggregate these
    // or a dedicated 'stats' document updated by triggers.
    // For now, we'll do client-side aggregation or simple counts where possible.
    
    // We can't efficiently count all docs in client without reading them all (expensive).
    // So we will rely on a dedicated 'stats' document if it exists, or just return mock/limited real data.
    // Let's implement a 'stats/platform' document approach which is best practice.
    // If that doc doesn't exist, we'll return zeroes.
    
    return _firestore.collection('stats').doc('platform').snapshots().map((doc) {
      if (!doc.exists) {
        return {
          'totalRevenue': 0.0,
          'activeRides': 0,
          'totalDrivers': 0,
          'totalInvestors': 0,
        };
      }
      return doc.data() as Map<String, dynamic>;
    });
  }

  // --- Drivers ---

  Stream<List<DriverApplicationModel>> getPendingDriverApplications() {
    return _firestore
        .collection('driver_applications')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverApplicationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> approveDriver(String userId, DriverApplicationModel app) async {
    final batch = _firestore.batch();
    
    // 1. Update Application Status
    final appRef = _firestore.collection('driver_applications').doc(userId);
    batch.update(appRef, {'status': 'approved'});

    // 2. Update User User Role
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'role': 'driver',
      'carModel': '${app.vehicleMake} ${app.vehicleModel}',
      'plateNumber': app.licensePlate,
    });

    await batch.commit();
  }

  Future<void> rejectDriver(String userId) async {
    await _firestore
        .collection('driver_applications')
        .doc(userId)
        .update({'status': 'rejected'});
  }

  // --- Investors ---

  Stream<List<InvestorModel>> getInvestors() {
    return _firestore
        .collection('investors')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvestorModel.fromFirestore(doc))
            .toList());
  }

  // --- Withdrawals ---

  Stream<List<InvestorWithdrawalModel>> getPendingWithdrawals() {
    return _firestore
        .collection('investor_withdrawals')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvestorWithdrawalModel.fromFirestore(doc))
            .toList());
  }

  Future<void> approveWithdrawal(String withdrawalId, String? paystackReference) async {
    await _firestore.collection('investor_withdrawals').doc(withdrawalId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'paystackReference': paystackReference,
    });
  }

  Future<void> rejectWithdrawal(String withdrawalId, String reason) async {
    // In a real app, you would also refund the amount to the wallet here inside a Transaction.
    // For now, we assume the amount was deducted when requested, so we should refund it.
    
    return _firestore.runTransaction((transaction) async {
      final withdrawalRef = _firestore.collection('investor_withdrawals').doc(withdrawalId);
      final withdrawalDoc = await transaction.get(withdrawalRef);
      
      if (!withdrawalDoc.exists) throw Exception("Withdrawal not found");
      
      final withdrawal = InvestorWithdrawalModel.fromFirestore(withdrawalDoc);
      
      // Update withdrawal status
      transaction.update(withdrawalRef, {
        'status': 'failed',
        'failureReason': reason,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Refund investor wallet
      final investorRef = _firestore.collection('investors').doc(withdrawal.investorId);
      transaction.update(investorRef, {
        'walletBalance': FieldValue.increment(withdrawal.amount),
        'totalWithdrawn': FieldValue.increment(-withdrawal.amount),
      });
    });
  }
}
