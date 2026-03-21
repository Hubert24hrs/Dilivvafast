import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User roles in the app
enum UserRole {
  @JsonValue('customer')
  customer,
  @JsonValue('driver')
  driver,
  @JsonValue('admin')
  admin,
  @JsonValue('investor')
  investor,
}

/// JSON converter for Firestore Timestamps
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

/// JSON converter for nullable Timestamps
class NullableTimestampConverter
    implements JsonConverter<DateTime?, Timestamp?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Timestamp? timestamp) => timestamp?.toDate();

  @override
  Timestamp? toJson(DateTime? date) =>
      date != null ? Timestamp.fromDate(date) : null;
}

/// JSON converter for GeoPoint
class NullableGeoPointConverter
    implements JsonConverter<GeoPoint?, Map<String, dynamic>?> {
  const NullableGeoPointConverter();

  @override
  GeoPoint? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return GeoPoint(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic>? toJson(GeoPoint? geoPoint) {
    if (geoPoint == null) return null;
    return {
      'latitude': geoPoint.latitude,
      'longitude': geoPoint.longitude,
    };
  }
}

@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();
  const factory UserModel({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
    String? photoUrl,
    @Default(UserRole.customer) UserRole role,
    @Default(false) bool isVerified,
    @Default(false) bool isOnline,
    @Default(0.0) double walletBalance,
    required String referralCode,
    String? referredBy,
    String? fcmToken,
    @Default(0.0) double rating,
    @Default(0) int totalDeliveries,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @NullableGeoPointConverter() GeoPoint? location,
    String? address,
    // Driver-only fields
    String? bvn,
    String? vehicleType,
    String? vehiclePlate,
    String? licenseUrl,
    @Default(true) bool isAvailable,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Create from Firestore document snapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    // Ensure uid is set from doc.id
    data['uid'] = doc.id;
    return UserModel.fromJson(data);
  }
}

extension UserModelX on UserModel {
  /// Convert to Firestore-compatible map (with Timestamp, GeoPoint)
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role.name,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'walletBalance': walletBalance,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'fcmToken': fcmToken,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
      'address': address,
      'bvn': bvn,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'licenseUrl': licenseUrl,
      'isAvailable': isAvailable,
    };
    // Remove null values
    map.removeWhere((key, value) => value == null);
    return map;
  }
}
