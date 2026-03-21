// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  uid: json['uid'] as String,
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  photoUrl: json['photoUrl'] as String?,
  role:
      $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ?? UserRole.customer,
  isVerified: json['isVerified'] as bool? ?? false,
  isOnline: json['isOnline'] as bool? ?? false,
  walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
  referralCode: json['referralCode'] as String,
  referredBy: json['referredBy'] as String?,
  fcmToken: json['fcmToken'] as String?,
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  totalDeliveries: (json['totalDeliveries'] as num?)?.toInt() ?? 0,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
  updatedAt: const TimestampConverter().fromJson(
    json['updatedAt'] as Timestamp,
  ),
  location: const NullableGeoPointConverter().fromJson(
    json['location'] as Map<String, dynamic>?,
  ),
  address: json['address'] as String?,
  bvn: json['bvn'] as String?,
  vehicleType: json['vehicleType'] as String?,
  vehiclePlate: json['vehiclePlate'] as String?,
  licenseUrl: json['licenseUrl'] as String?,
  isAvailable: json['isAvailable'] as bool? ?? true,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'fullName': instance.fullName,
      'email': instance.email,
      'phone': instance.phone,
      'photoUrl': instance.photoUrl,
      'role': _$UserRoleEnumMap[instance.role]!,
      'isVerified': instance.isVerified,
      'isOnline': instance.isOnline,
      'walletBalance': instance.walletBalance,
      'referralCode': instance.referralCode,
      'referredBy': instance.referredBy,
      'fcmToken': instance.fcmToken,
      'rating': instance.rating,
      'totalDeliveries': instance.totalDeliveries,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'location': const NullableGeoPointConverter().toJson(instance.location),
      'address': instance.address,
      'bvn': instance.bvn,
      'vehicleType': instance.vehicleType,
      'vehiclePlate': instance.vehiclePlate,
      'licenseUrl': instance.licenseUrl,
      'isAvailable': instance.isAvailable,
    };

const _$UserRoleEnumMap = {
  UserRole.customer: 'customer',
  UserRole.driver: 'driver',
  UserRole.admin: 'admin',
  UserRole.investor: 'investor',
};
