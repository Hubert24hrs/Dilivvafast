import 'package:cloud_firestore/cloud_firestore.dart';

/// Public projection of a driver's live presence.
///
/// This is everything a customer is allowed to know about a courier they have
/// not been matched with: where they are and whether they can take a job.
/// Name, phone, email, wallet balance and FCM token stay on the `users`
/// document, which customers cannot read.
class DriverPresence {
  const DriverPresence({
    required this.driverId,
    required this.isOnline,
    required this.isAvailable,
    this.location,
    this.heading,
    this.vehicleType,
    this.lastSeen,
  });

  final String driverId;
  final bool isOnline;
  final bool isAvailable;
  final GeoPoint? location;
  final double? heading;
  final String? vehicleType;
  final DateTime? lastSeen;

  factory DriverPresence.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    return DriverPresence(
      driverId: data['driverId'] as String? ?? doc.id,
      isOnline: data['isOnline'] as bool? ?? false,
      isAvailable: data['isAvailable'] as bool? ?? false,
      location: data['location'] as GeoPoint?,
      heading: (data['heading'] as num?)?.toDouble(),
      vehicleType: data['vehicleType'] as String?,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }
}
