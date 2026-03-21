// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PromoModel _$PromoModelFromJson(Map<String, dynamic> json) => _PromoModel(
  id: json['id'] as String,
  code: json['code'] as String,
  discountType:
      $enumDecodeNullable(_$DiscountTypeEnumMap, json['discountType']) ??
      DiscountType.flat,
  amount: (json['amount'] as num).toDouble(),
  minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
  expiresAt: const TimestampConverter().fromJson(
    json['expiresAt'] as Timestamp,
  ),
  maxUses: (json['maxUses'] as num?)?.toInt() ?? 0,
  usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$PromoModelToJson(_PromoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'discountType': _$DiscountTypeEnumMap[instance.discountType]!,
      'amount': instance.amount,
      'minOrderAmount': instance.minOrderAmount,
      'expiresAt': const TimestampConverter().toJson(instance.expiresAt),
      'maxUses': instance.maxUses,
      'usedCount': instance.usedCount,
      'isActive': instance.isActive,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };

const _$DiscountTypeEnumMap = {
  DiscountType.flat: 'flat',
  DiscountType.percent: 'percent',
};
