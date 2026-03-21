// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zone_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ZoneModel _$ZoneModelFromJson(Map<String, dynamic> json) => _ZoneModel(
  id: json['id'] as String,
  name: json['name'] as String,
  city: json['city'] as String,
  baseFare: (json['baseFare'] as num?)?.toDouble() ?? 0.0,
  perKmRate: (json['perKmRate'] as num?)?.toDouble() ?? 0.0,
  surgeThreshold: (json['surgeThreshold'] as num?)?.toInt() ?? 5,
  currentSurgeMultiplier:
      (json['currentSurgeMultiplier'] as num?)?.toDouble() ?? 1.0,
  polygonCoordinates: json['polygonCoordinates'] == null
      ? const []
      : const GeoPointListConverter().fromJson(
          json['polygonCoordinates'] as List,
        ),
  isActive: json['isActive'] as bool? ?? true,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$ZoneModelToJson(_ZoneModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city': instance.city,
      'baseFare': instance.baseFare,
      'perKmRate': instance.perKmRate,
      'surgeThreshold': instance.surgeThreshold,
      'currentSurgeMultiplier': instance.currentSurgeMultiplier,
      'polygonCoordinates': const GeoPointListConverter().toJson(
        instance.polygonCoordinates,
      ),
      'isActive': instance.isActive,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
