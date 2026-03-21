import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_delivery/features/auth/domain/entities/user_model.dart';
import 'package:fast_delivery/features/courier/domain/entities/courier_order_model.dart';

part 'zone_model.freezed.dart';
part 'zone_model.g.dart';

@freezed
abstract class ZoneModel with _$ZoneModel {
  const ZoneModel._();
  const factory ZoneModel({
    required String id,
    required String name,
    required String city,
    @Default(0.0) double baseFare,
    @Default(0.0) double perKmRate,
    @Default(5) int surgeThreshold,
    @Default(1.0) double currentSurgeMultiplier,
    @GeoPointListConverter() @Default([]) List<GeoPoint> polygonCoordinates,
    @Default(true) bool isActive,
    @TimestampConverter() required DateTime createdAt,
  }) = _ZoneModel;

  factory ZoneModel.fromJson(Map<String, dynamic> json) =>
      _$ZoneModelFromJson(json);

  factory ZoneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return ZoneModel.fromJson(data);
  }
}

extension ZoneModelX on ZoneModel {
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'city': city,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'surgeThreshold': surgeThreshold,
      'currentSurgeMultiplier': currentSurgeMultiplier,
      'polygonCoordinates': polygonCoordinates
          .map((gp) => GeoPoint(gp.latitude, gp.longitude))
          .toList(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
