import 'package:cloud_firestore/cloud_firestore.dart';

class CourierModel {
  final String id;
  final String userId;
  final String? riderId;
  final GeoPoint pickupLocation;
  final GeoPoint dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final String packageSize; // 'Small', 'Medium', 'Large'
  final String receiverName;
  final String receiverPhone;
  final double price;
  final String status; // 'pending', 'accepted', 'picked_up', 'delivered', 'cancelled'
  final DateTime createdAt;

  CourierModel({
    required this.id,
    required this.userId,
    this.riderId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.packageSize,
    required this.receiverName,
    required this.receiverPhone,
    required this.price,
    this.status = 'pending',
    required this.createdAt,
  });

  factory CourierModel.fromMap(Map<String, dynamic> data, String id) {
    return CourierModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      riderId: data['riderId'] as String?,
      pickupLocation: data['pickupLocation'] as GeoPoint,
      dropoffLocation: data['dropoffLocation'] as GeoPoint,
      pickupAddress: data['pickupAddress'] as String? ?? '',
      dropoffAddress: data['dropoffAddress'] as String? ?? '',
      packageSize: data['packageSize'] as String? ?? 'Small',
      receiverName: data['receiverName'] as String? ?? '',
      receiverPhone: data['receiverPhone'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
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
      'packageSize': packageSize,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'price': price,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
