// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_application_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DriverApplicationModel _$DriverApplicationModelFromJson(
  Map<String, dynamic> json,
) => _DriverApplicationModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  vehicleType: json['vehicleType'] as String,
  vehiclePlate: json['vehiclePlate'] as String,
  licenseUrl: json['licenseUrl'] as String?,
  vehiclePhotoUrl: json['vehiclePhotoUrl'] as String?,
  governmentIdUrl: json['governmentIdUrl'] as String?,
  bankName: json['bankName'] as String?,
  accountNumber: json['accountNumber'] as String?,
  accountName: json['accountName'] as String?,
  status:
      $enumDecodeNullable(_$ApplicationStatusEnumMap, json['status']) ??
      ApplicationStatus.submitted,
  rejectionReason: json['rejectionReason'] as String?,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
  reviewedAt: const NullableTimestampConverter().fromJson(
    json['reviewedAt'] as Timestamp?,
  ),
);

Map<String, dynamic> _$DriverApplicationModelToJson(
  _DriverApplicationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'fullName': instance.fullName,
  'email': instance.email,
  'phone': instance.phone,
  'vehicleType': instance.vehicleType,
  'vehiclePlate': instance.vehiclePlate,
  'licenseUrl': instance.licenseUrl,
  'vehiclePhotoUrl': instance.vehiclePhotoUrl,
  'governmentIdUrl': instance.governmentIdUrl,
  'bankName': instance.bankName,
  'accountNumber': instance.accountNumber,
  'accountName': instance.accountName,
  'status': _$ApplicationStatusEnumMap[instance.status]!,
  'rejectionReason': instance.rejectionReason,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'reviewedAt': const NullableTimestampConverter().toJson(instance.reviewedAt),
};

const _$ApplicationStatusEnumMap = {
  ApplicationStatus.submitted: 'submitted',
  ApplicationStatus.underReview: 'under_review',
  ApplicationStatus.approved: 'approved',
  ApplicationStatus.rejected: 'rejected',
};
