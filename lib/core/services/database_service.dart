import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/chat_message_model.dart';
import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/driver_application_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Driver Applications ---
  Future<void> submitDriverApplication(DriverApplicationModel app) async {
    await _db.collection('driver_applications').doc(app.id).set(app.toMap());
  }

  Stream<DriverApplicationModel?> getDriverApplicationStream(String userId) {
    return _db.collection('driver_applications').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return DriverApplicationModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // --- Users ---
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.id).update(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> updateWalletBalance(String uid, double amount) async {
    await _db.collection('users').doc(uid).update({
      'walletBalance': FieldValue.increment(amount),
    });
  }

  // --- Rides ---
  Future<void> createRideRequest(RideModel ride) async {
    await _db.collection('rides').doc(ride.id).set(ride.toMap());
  }

  Stream<List<RideModel>> getActiveRides() {
    return _db
        .collection('rides')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateRideStatus(String rideId, String status, String driverId) async {
    await _db.collection('rides').doc(rideId).update({
      'status': status,
      'driverId': driverId,
    });
  }

  // --- Couriers ---
  Future<void> createCourierRequest(CourierModel courier) async {
    await _db.collection('couriers').doc(courier.id).set(courier.toMap());
  }

  Stream<List<CourierModel>> getActiveCouriers() {
    return _db
        .collection('couriers')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourierModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateCourierStatus(String courierId, String status, String riderId, {GeoPoint? driverLocation}) async {
    final Map<String, dynamic> data = {
      'status': status,
      'riderId': riderId,
    };
    
    // Set timestamps based on status transition
    final now = Timestamp.now();
    if (status == 'accepted') {
      data['acceptedAt'] = now;
    } else if (status == 'arrived') {
      data['arrivedAt'] = now;
    } else if (status == 'in_transit') {
      data['tripStartedAt'] = now;
    } else if (status == 'delivered') {
      data['tripEndedAt'] = now;
    }
    
    if (driverLocation != null) {
      data['driverLocation'] = driverLocation;
    }
    await _db.collection('couriers').doc(courierId).update(data);
  }

  // Stream a specific courier by ID
  Stream<CourierModel?> streamCourier(String courierId) {
    return _db.collection('couriers').doc(courierId).snapshots().map((doc) {
      if (doc.exists) {
        return CourierModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Get active courier for user (sender)
  Future<CourierModel?> getActiveCourierForUser(String userId) async {
    try {
      final snapshot = await _db
          .collection('couriers')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted', 'arrived', 'in_transit'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return CourierModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
    } catch (e) {
      // Index might not exist, fallback to simpler query
      final snapshot = await _db
          .collection('couriers')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in snapshot.docs) {
        final courier = CourierModel.fromMap(doc.data(), doc.id);
        if (['pending', 'accepted', 'arrived', 'in_transit'].contains(courier.status)) {
          return courier;
        }
      }
    }
    return null;
  }
  // ... existing methods ...

  Stream<List<RideModel>> getUserRides(String userId) {
    return _db
        .collection('rides')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RideModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<CourierModel>> getUserCouriers(String userId) {
    return _db
        .collection('couriers')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CourierModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // --- Wallet ---
  Future<void> addWalletTransaction({
    required String userId,
    required double amount,
    required String type, // 'deposit' or 'payment'
    required String description,
  }) async {
    final batch = _db.batch();

    // 1. Update User Balance
    final userRef = _db.collection('users').doc(userId);
    batch.set(userRef, {
      'walletBalance': FieldValue.increment(amount),
    }, SetOptions(merge: true));

    // 2. Add Transaction Record
    final transactionRef = _db.collection('transactions').doc();
    batch.set(transactionRef, {
      'id': transactionRef.id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getUserTransactions(String userId) {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Timestamp to DateTime for UI
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        return data;
      }).toList();
    });
  }

  // --- Chat ---
  Future<void> sendMessage(String rideId, ChatMessageModel message) async {
    await _db
        .collection('rides')
        .doc(rideId)
        .collection('messages')
        .add(message.toMap());
  }

  Stream<List<ChatMessageModel>> getMessagesStream(String rideId) {
    return _db
        .collection('rides')
        .doc(rideId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // --- Notifications ---
  Future<void> saveFcmToken(String userId, String token) async {
    await _db.collection('users').doc(userId).update({
      'fcmToken': token,
    });
  }
}
