// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hp_agreement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HPAgreementModel _$HPAgreementModelFromJson(Map<String, dynamic> json) =>
    _HPAgreementModel(
      id: json['id'] as String,
      bikeId: json['bikeId'] as String,
      investorId: json['investorId'] as String,
      riderId: json['riderId'] as String,
      totalRepayment: (json['totalRepayment'] as num).toDouble(),
      repaidAmount: (json['repaidAmount'] as num?)?.toDouble() ?? 0.0,
      monthlyInstalment: (json['monthlyInstalment'] as num).toDouble(),
      status:
          $enumDecodeNullable(_$AgreementStatusEnumMap, json['status']) ??
          AgreementStatus.active,
      startDate: const TimestampConverter().fromJson(
        json['startDate'] as Timestamp,
      ),
      endDate: const TimestampConverter().fromJson(
        json['endDate'] as Timestamp,
      ),
      createdAt: const TimestampConverter().fromJson(
        json['createdAt'] as Timestamp,
      ),
    );

Map<String, dynamic> _$HPAgreementModelToJson(_HPAgreementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bikeId': instance.bikeId,
      'investorId': instance.investorId,
      'riderId': instance.riderId,
      'totalRepayment': instance.totalRepayment,
      'repaidAmount': instance.repaidAmount,
      'monthlyInstalment': instance.monthlyInstalment,
      'status': _$AgreementStatusEnumMap[instance.status]!,
      'startDate': const TimestampConverter().toJson(instance.startDate),
      'endDate': const TimestampConverter().toJson(instance.endDate),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };

const _$AgreementStatusEnumMap = {
  AgreementStatus.active: 'active',
  AgreementStatus.completed: 'completed',
  AgreementStatus.defaulted: 'defaulted',
};
