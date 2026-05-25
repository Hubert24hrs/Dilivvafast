import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a rating for a ride
  Future<void> submitRating({
    required String rideId,
    required String driverId,
    required String passengerId,
    required int stars,
    String? feedback,
    double? tip,
  }) async {
    final rating = RatingModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rideId: rideId,
      driverId: driverId,
      passengerId: passengerId,
      stars: stars,
      feedback: feedback,
      tip: tip,
      createdAt: DateTime.now(),
    );

    // Save to ratings collection
    await _firestore
        .collection('ratings')
        .doc(rating.id)
        .set(rating.toMap());

    // Update ride document with rating
    await _firestore.collection('rides').doc(rideId).update({
      'rating': stars,
      'ratingFeedback': feedback,
      'tip': tip,
    });

    // Update driver's average rating
    await _updateDriverAverageRating(driverId);
  }

  // Calculate and update driver's average rating
  Future<void> _updateDriverAverageRating(String driverId) async {
    final ratings = await _firestore
        .collection('ratings')
        .where('driverId', isEqualTo: driverId)
        .get();

    if (ratings.docs.isEmpty) return;

    double total = 0;
    for (var doc in ratings.docs) {
      total += (doc.data()['stars'] ?? 5).toInt();
    }
    final average = total / ratings.docs.length;

    // Update driver's profile
    await _firestore.collection('users').doc(driverId).update({
      'averageRating': average,
      'totalRatings': ratings.docs.length,
    });
  }

  // Get ratings for a driver
  Stream<List<RatingModel>> getDriverRatings(String driverId) {
    return _firestore
        .collection('ratings')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RatingModel.fromFirestore(doc))
            .toList());
  }

  // Get driver's average rating
  Future<Map<String, dynamic>> getDriverRatingStats(String driverId) async {
    final snapshot = await _firestore
        .collection('ratings')
        .where('driverId', isEqualTo: driverId)
        .get();

    if (snapshot.docs.isEmpty) {
      return {'average': 5.0, 'total': 0, 'distribution': <int, int>{}};
    }

    double total = 0;
    Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var doc in snapshot.docs) {
      final stars = (doc.data()['stars'] ?? 5).toInt();
      total += stars;
      distribution[stars] = (distribution[stars] ?? 0) + 1;
    }

    return {
      'average': total / snapshot.docs.length,
      'total': snapshot.docs.length,
      'distribution': distribution,
    };
  }

  // Check if a ride has been rated
  Future<bool> isRideRated(String rideId) async {
    final snapshot = await _firestore
        .collection('ratings')
        .where('rideId', isEqualTo: rideId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
