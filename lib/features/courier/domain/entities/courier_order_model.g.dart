// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'courier_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CourierOrderModel _$CourierOrderModelFromJson(
  Map<String, dynamic> json,
) => _CourierOrderModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  driverId: json['driverId'] as String?,
  status:
      $enumDecodeNullable(_$OrderStatusEnumMap, json['status']) ??
      OrderStatus.pending,
  pickupAddress: json['pickupAddress'] as String,
  pickupGeoPoint: const GeoPointConverter().fromJson(
    json['pickupGeoPoint'] as Map<String, dynamic>,
  ),
  dropoffAddress: json['dropoffAddress'] as String,
  dropoffGeoPoint: const GeoPointConverter().fromJson(
    json['dropoffGeoPoint'] as Map<String, dynamic>,
  ),
  packageDescription: json['packageDescription'] as String,
  packageWeight: (json['packageWeight'] as num?)?.toDouble() ?? 0.0,
  packageCategory:
      $enumDecodeNullable(_$PackageCategoryEnumMap, json['packageCategory']) ??
      PackageCategory.other,
  recipientName: json['recipientName'] as String,
  recipientPhone: json['recipientPhone'] as String,
  estimatedDistanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble() ?? 0.0,
  estimatedDurationMin: (json['estimatedDurationMin'] as num?)?.toInt() ?? 0,
  baseFare: (json['baseFare'] as num?)?.toDouble() ?? 0.0,
  surgeMultiplier: (json['surgeMultiplier'] as num?)?.toDouble() ?? 1.0,
  totalFare: (json['totalFare'] as num?)?.toDouble() ?? 0.0,
  paymentMethod:
      $enumDecodeNullable(_$PaymentMethodEnumMap, json['paymentMethod']) ??
      PaymentMethod.wallet,
  paymentStatus:
      $enumDecodeNullable(_$PaymentStatusEnumMap, json['paymentStatus']) ??
      PaymentStatus.pending,
  paystackReference: json['paystackReference'] as String?,
  promoCode: json['promoCode'] as String?,
  discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
  trackingCode: json['trackingCode'] as String,
  notes: json['notes'] as String?,
  proofOfDeliveryUrl: json['proofOfDeliveryUrl'] as String?,
  rating: (json['rating'] as num?)?.toInt(),
  ratingComment: json['ratingComment'] as String?,
  driverEarnings: (json['driverEarnings'] as num?)?.toDouble() ?? 0.0,
  platformCommission: (json['platformCommission'] as num?)?.toDouble() ?? 0.0,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
  updatedAt: const TimestampConverter().fromJson(
    json['updatedAt'] as Timestamp,
  ),
  pickedUpAt: const NullableTimestampConverter().fromJson(
    json['pickedUpAt'] as Timestamp?,
  ),
  deliveredAt: const NullableTimestampConverter().fromJson(
    json['deliveredAt'] as Timestamp?,
  ),
  estimatedDeliveryTime: const NullableTimestampConverter().fromJson(
    json['estimatedDeliveryTime'] as Timestamp?,
  ),
  polylinePoints: json['polylinePoints'] == null
      ? const []
      : const GeoPointListConverter().fromJson(json['polylinePoints'] as List),
);

Map<String, dynamic> _$CourierOrderModelToJson(
  _CourierOrderModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'driverId': instance.driverId,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'pickupAddress': instance.pickupAddress,
  'pickupGeoPoint': const GeoPointConverter().toJson(instance.pickupGeoPoint),
  'dropoffAddress': instance.dropoffAddress,
  'dropoffGeoPoint': const GeoPointConverter().toJson(instance.dropoffGeoPoint),
  'packageDescription': instance.packageDescription,
  'packageWeight': instance.packageWeight,
  'packageCategory': _$PackageCategoryEnumMap[instance.packageCategory]!,
  'recipientName': instance.recipientName,
  'recipientPhone': instance.recipientPhone,
  'estimatedDistanceKm': instance.estimatedDistanceKm,
  'estimatedDurationMin': instance.estimatedDurationMin,
  'baseFare': instance.baseFare,
  'surgeMultiplier': instance.surgeMultiplier,
  'totalFare': instance.totalFare,
  'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
  'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus]!,
  'paystackReference': instance.paystackReference,
  'promoCode': instance.promoCode,
  'discountAmount': instance.discountAmount,
  'trackingCode': instance.trackingCode,
  'notes': instance.notes,
  'proofOfDeliveryUrl': instance.proofOfDeliveryUrl,
  'rating': instance.rating,
  'ratingComment': instance.ratingComment,
  'driverEarnings': instance.driverEarnings,
  'platformCommission': instance.platformCommission,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
  'pickedUpAt': const NullableTimestampConverter().toJson(instance.pickedUpAt),
  'deliveredAt': const NullableTimestampConverter().toJson(
    instance.deliveredAt,
  ),
  'estimatedDeliveryTime': const NullableTimestampConverter().toJson(
    instance.estimatedDeliveryTime,
  ),
  'polylinePoints': const GeoPointListConverter().toJson(
    instance.polylinePoints,
  ),
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.accepted: 'accepted',
  OrderStatus.pickedUp: 'picked_up',
  OrderStatus.inTransit: 'in_transit',
  OrderStatus.delivered: 'delivered',
  OrderStatus.cancelled: 'cancelled',
  OrderStatus.failed: 'failed',
};

const _$PackageCategoryEnumMap = {
  PackageCategory.documents: 'documents',
  PackageCategory.fragile: 'fragile',
  PackageCategory.electronics: 'electronics',
  PackageCategory.food: 'food',
  PackageCategory.clothing: 'clothing',
  PackageCategory.other: 'other',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.wallet: 'wallet',
  PaymentMethod.card: 'card',
  PaymentMethod.cash: 'cash',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.paid: 'paid',
  PaymentStatus.refunded: 'refunded',
};
