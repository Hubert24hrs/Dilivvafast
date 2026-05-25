import 'package:cloud_firestore/cloud_firestore.dart';

class CourierModel {
  final String id;
  final String userId;
  final String? riderId;
  final GeoPoint pickupLocation;
  final GeoPoint dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final GeoPoint? driverLocation;
  final String packageSize; // 'Small', 'Medium', 'Large'
  final String receiverName;
  final String receiverPhone;
  final double price;
  final double recommendedPrice; // System calculated recommended price
  final String status; // 'pending', 'accepted', 'arrived', 'in_transit', 'delivered', 'cancelled'
  final DateTime createdAt;
  
  // Activity Timeline Timestamps
  final DateTime? acceptedAt;    // When driver accepts the offer
  final DateTime? arrivedAt;     // When driver arrives at pickup
  final DateTime? tripStartedAt; // When trip actually begins
  final DateTime? tripEndedAt;   // When trip ends (delivered)

  final List<String> stops;
  final List<GeoPoint> stopLocations;

  CourierModel({
    required this.id,
    required this.userId,
    this.riderId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.driverLocation,
    required this.packageSize,
    required this.receiverName,
    required this.receiverPhone,
    required this.price,
    this.recommendedPrice = 0.0,
    this.status = 'pending',
    required this.createdAt,
    this.acceptedAt,
    this.arrivedAt,
    this.tripStartedAt,
    this.tripEndedAt,
    this.stops = const [],
    this.stopLocations = const [],
  });

  factory CourierModel.fromMap(Map<String, dynamic> data, String id) {
    return CourierModel(
      id: id,
      userId: data['userId'] ?? '',
      riderId: data['riderId'],
      pickupLocation: data['pickupLocation'] as GeoPoint,
      dropoffLocation: data['dropoffLocation'] as GeoPoint,
      pickupAddress: data['pickupAddress'] ?? '',
      dropoffAddress: data['dropoffAddress'] ?? '',
      driverLocation: data['driverLocation'] as GeoPoint?,
      packageSize: data['packageSize'] ?? 'Small',
      receiverName: data['receiverName'] ?? '',
      receiverPhone: data['receiverPhone'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      recommendedPrice: (data['recommendedPrice'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null ? (data['acceptedAt'] as Timestamp).toDate() : null,
      arrivedAt: data['arrivedAt'] != null ? (data['arrivedAt'] as Timestamp).toDate() : null,
      tripStartedAt: data['tripStartedAt'] != null ? (data['tripStartedAt'] as Timestamp).toDate() : null,
      tripEndedAt: data['tripEndedAt'] != null ? (data['tripEndedAt'] as Timestamp).toDate() : null,
      stops: List<String>.from(data['stops'] ?? []),
      stopLocations: List<GeoPoint>.from(data['stopLocations'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'riderId': riderId,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'driverLocation': driverLocation,
      'packageSize': packageSize,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'price': price,
      'recommendedPrice': recommendedPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'arrivedAt': arrivedAt != null ? Timestamp.fromDate(arrivedAt!) : null,
      'tripStartedAt': tripStartedAt != null ? Timestamp.fromDate(tripStartedAt!) : null,
      'tripEndedAt': tripEndedAt != null ? Timestamp.fromDate(tripEndedAt!) : null,
      'stops': stops,
      'stopLocations': stopLocations,
    };
  }
}
