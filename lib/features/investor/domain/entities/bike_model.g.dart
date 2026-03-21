// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bike_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BikeModel _$BikeModelFromJson(Map<String, dynamic> json) => _BikeModel(
  id: json['id'] as String,
  make: json['make'] as String,
  model: json['model'] as String,
  year: (json['year'] as num).toInt(),
  plateNumber: json['plateNumber'] as String,
  purchasePrice: (json['purchasePrice'] as num).toDouble(),
  status:
      $enumDecodeNullable(_$BikeStatusEnumMap, json['status']) ??
      BikeStatus.pendingFunding,
  investorId: json['investorId'] as String?,
  riderId: json['riderId'] as String?,
  totalRepayment: (json['totalRepayment'] as num?)?.toDouble() ?? 0.0,
  repaidAmount: (json['repaidAmount'] as num?)?.toDouble() ?? 0.0,
  monthlyInstalment: (json['monthlyInstalment'] as num?)?.toDouble() ?? 0.0,
  commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 0.15,
  imageUrls:
      (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$BikeModelToJson(_BikeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'make': instance.make,
      'model': instance.model,
      'year': instance.year,
      'plateNumber': instance.plateNumber,
      'purchasePrice': instance.purchasePrice,
      'status': _$BikeStatusEnumMap[instance.status]!,
      'investorId': instance.investorId,
      'riderId': instance.riderId,
      'totalRepayment': instance.totalRepayment,
      'repaidAmount': instance.repaidAmount,
      'monthlyInstalment': instance.monthlyInstalment,
      'commissionRate': instance.commissionRate,
      'imageUrls': instance.imageUrls,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };

const _$BikeStatusEnumMap = {
  BikeStatus.pendingFunding: 'pending_funding',
  BikeStatus.funded: 'funded',
  BikeStatus.assigned: 'assigned',
  BikeStatus.active: 'active',
  BikeStatus.maintenance: 'maintenance',
  BikeStatus.decommissioned: 'decommissioned',
};
