import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dilivvafast/features/courier/domain/entities/courier_order_model.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

/// Legacy database service — functionality migrated to repositories.
/// This file is maintained temporarily for backward compatibility.
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toFirestore());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<void> updateWalletBalance(String uid, double amount) async {
    await _db.collection('users').doc(uid).update({
      'walletBalance': FieldValue.increment(amount),
    });
  }

  // --- Couriers ---
  Future<void> createCourierRequest(CourierOrderModel courier) async {
    await _db.collection('couriers').add(courier.toFirestore());
  }

  Stream<List<CourierOrderModel>> getActiveCouriers() {
    return _db
        .collection('couriers')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CourierOrderModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateCourierStatus(
    String courierId,
    String status,
    String riderId,
  ) async {
    await _db.collection('couriers').doc(courierId).update({
      'status': status,
      'driverId': riderId,
    });
  }
}
