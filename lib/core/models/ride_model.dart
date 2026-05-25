import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String id;
  final String userId;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final String? carModel;
  final String? plateNumber;
  final GeoPoint? driverLocation;
  
  final GeoPoint pickupLocation;
  final GeoPoint dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final double price;
  final String status; // 'pending', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled'
  final DateTime createdAt;

  // Status transition timestamps
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? tripStartedAt;
  final DateTime? completedAt;

  final String? userPhone; // Contact for the passenger

  final List<String> stops;
  final List<GeoPoint> stopLocations;

  RideModel({
    required this.id,
    required this.userId,
    this.userPhone,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.carModel,
    this.plateNumber,
    this.driverLocation,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.price,
    this.status = 'pending',
    required this.createdAt,
    this.acceptedAt,
    this.arrivedAt,
    this.tripStartedAt,
    this.completedAt,
    this.stops = const [],
    this.stopLocations = const [],
  });

  factory RideModel.fromMap(Map<String, dynamic> data, String id) {
    return RideModel(
      id: id,
      userId: data['userId'] ?? '',
      userPhone: data['userPhone'],
      driverId: data['driverId'],
      driverName: data['driverName'],
      driverPhone: data['driverPhone'],
      driverPhoto: data['driverPhoto'],
      carModel: data['carModel'],
      plateNumber: data['plateNumber'],
      driverLocation: data['driverLocation'] as GeoPoint?,
      pickupLocation: data['pickupLocation'] as GeoPoint,
      dropoffLocation: data['dropoffLocation'] as GeoPoint,
      pickupAddress: data['pickupAddress'] ?? '',
      dropoffAddress: data['dropoffAddress'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null ? (data['acceptedAt'] as Timestamp).toDate() : null,
      arrivedAt: data['arrivedAt'] != null ? (data['arrivedAt'] as Timestamp).toDate() : null,
      tripStartedAt: data['tripStartedAt'] != null ? (data['tripStartedAt'] as Timestamp).toDate() : null,
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      stops: List<String>.from(data['stops'] ?? []),
      stopLocations: List<GeoPoint>.from(data['stopLocations'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userPhone': userPhone,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverPhoto': driverPhoto,
      'carModel': carModel,
      'plateNumber': plateNumber,
      'driverLocation': driverLocation,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'price': price,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'arrivedAt': arrivedAt != null ? Timestamp.fromDate(arrivedAt!) : null,
      'tripStartedAt': tripStartedAt != null ? Timestamp.fromDate(tripStartedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'stops': stops,
      'stopLocations': stopLocations,
    };
  }
}
