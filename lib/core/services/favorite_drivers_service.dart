import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteDriversService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add driver to favorites
  Future<void> addFavorite({
    required String userId,
    required String driverId,
    required String driverName,
    String? driverPhoto,
    String? carModel,
    double? rating,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteDrivers')
        .doc(driverId)
        .set({
      'driverId': driverId,
      'driverName': driverName,
      'driverPhoto': driverPhoto,
      'carModel': carModel,
      'rating': rating,
      'addedAt': Timestamp.now(),
    });
  }

  // Remove driver from favorites
  Future<void> removeFavorite({
    required String userId,
    required String driverId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteDrivers')
        .doc(driverId)
        .delete();
  }

  // Check if driver is in favorites
  Future<bool> isFavorite({
    required String userId,
    required String driverId,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteDrivers')
        .doc(driverId)
        .get();
    return doc.exists;
  }

  // Get all favorite drivers
  Stream<List<FavoriteDriverModel>> getFavoriteDrivers(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteDrivers')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FavoriteDriverModel.fromFirestore(doc))
            .toList());
  }
}

class FavoriteDriverModel {
  final String driverId;
  final String driverName;
  final String? driverPhoto;
  final String? carModel;
  final double? rating;
  final DateTime addedAt;

  FavoriteDriverModel({
    required this.driverId,
    required this.driverName,
    this.driverPhoto,
    this.carModel,
    this.rating,
    required this.addedAt,
  });

  factory FavoriteDriverModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoriteDriverModel(
      driverId: data['driverId'] ?? doc.id,
      driverName: data['driverName'] ?? 'Unknown',
      driverPhoto: data['driverPhoto'],
      carModel: data['carModel'],
      rating: data['rating']?.toDouble(),
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
