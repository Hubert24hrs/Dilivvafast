import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String rideId;
  final String driverId;
  final String passengerId;
  final int stars; // 1-5
  final String? feedback;
  final double? tip;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.rideId,
    required this.driverId,
    required this.passengerId,
    required this.stars,
    this.feedback,
    this.tip,
    required this.createdAt,
  });

  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RatingModel(
      id: doc.id,
      rideId: data['rideId'] ?? '',
      driverId: data['driverId'] ?? '',
      passengerId: data['passengerId'] ?? '',
      stars: (data['stars'] ?? 5).toInt(),
      feedback: data['feedback'],
      tip: data['tip']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'driverId': driverId,
      'passengerId': passengerId,
      'stars': stars,
      'feedback': feedback,
      'tip': tip,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
