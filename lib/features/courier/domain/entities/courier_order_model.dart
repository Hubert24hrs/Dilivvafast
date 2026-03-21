import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_delivery/features/auth/domain/entities/user_model.dart';

part 'courier_order_model.freezed.dart';
part 'courier_order_model.g.dart';

enum OrderStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('picked_up')
  pickedUp,
  @JsonValue('in_transit')
  inTransit,
  @JsonValue('delivered')
  delivered,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('failed')
  failed,
}

enum PackageCategory {
  @JsonValue('documents')
  documents,
  @JsonValue('fragile')
  fragile,
  @JsonValue('electronics')
  electronics,
  @JsonValue('food')
  food,
  @JsonValue('clothing')
  clothing,
  @JsonValue('other')
  other,
}

enum PaymentMethod {
  @JsonValue('wallet')
  wallet,
  @JsonValue('card')
  card,
  @JsonValue('cash')
  cash,
}

enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('paid')
  paid,
  @JsonValue('refunded')
  refunded,
}

/// JSON converter for Firestore GeoPoint
class GeoPointConverter implements JsonConverter<GeoPoint, Map<String, dynamic>> {
  const GeoPointConverter();

  @override
  GeoPoint fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(GeoPoint geoPoint) {
    return {
      'latitude': geoPoint.latitude,
      'longitude': geoPoint.longitude,
    };
  }
}

/// JSON converter for List<GeoPoint>
class GeoPointListConverter
    implements JsonConverter<List<GeoPoint>, List<dynamic>> {
  const GeoPointListConverter();

  @override
  List<GeoPoint> fromJson(List<dynamic> jsonList) {
    return jsonList.map((item) {
      final map = item as Map<String, dynamic>;
      return GeoPoint(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  List<dynamic> toJson(List<GeoPoint> geoPoints) {
    return geoPoints
        .map((gp) => {'latitude': gp.latitude, 'longitude': gp.longitude})
        .toList();
  }
}

@freezed
abstract class CourierOrderModel with _$CourierOrderModel {
  const CourierOrderModel._();
  const factory CourierOrderModel({
    required String id,
    required String userId,
    String? driverId,
    @Default(OrderStatus.pending) OrderStatus status,
    required String pickupAddress,
    @GeoPointConverter() required GeoPoint pickupGeoPoint,
    required String dropoffAddress,
    @GeoPointConverter() required GeoPoint dropoffGeoPoint,
    required String packageDescription,
    @Default(0.0) double packageWeight,
    @Default(PackageCategory.other) PackageCategory packageCategory,
    required String recipientName,
    required String recipientPhone,
    @Default(0.0) double estimatedDistanceKm,
    @Default(0) int estimatedDurationMin,
    @Default(0.0) double baseFare,
    @Default(1.0) double surgeMultiplier,
    @Default(0.0) double totalFare,
    @Default(PaymentMethod.wallet) PaymentMethod paymentMethod,
    @Default(PaymentStatus.pending) PaymentStatus paymentStatus,
    String? paystackReference,
    String? promoCode,
    @Default(0.0) double discountAmount,
    required String trackingCode,
    String? notes,
    String? proofOfDeliveryUrl,
    int? rating,
    String? ratingComment,
    @Default(0.0) double driverEarnings,
    @Default(0.0) double platformCommission,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @NullableTimestampConverter() DateTime? pickedUpAt,
    @NullableTimestampConverter() DateTime? deliveredAt,
    @NullableTimestampConverter() DateTime? estimatedDeliveryTime,
    @GeoPointListConverter() @Default([]) List<GeoPoint> polylinePoints,
  }) = _CourierOrderModel;

  factory CourierOrderModel.fromJson(Map<String, dynamic> json) =>
      _$CourierOrderModelFromJson(json);

  factory CourierOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return CourierOrderModel.fromJson(data);
  }
}

extension CourierOrderModelX on CourierOrderModel {
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'driverId': driverId,
      'status': status.name,
      'pickupAddress': pickupAddress,
      'pickupGeoPoint': pickupGeoPoint,
      'dropoffAddress': dropoffAddress,
      'dropoffGeoPoint': dropoffGeoPoint,
      'packageDescription': packageDescription,
      'packageWeight': packageWeight,
      'packageCategory': packageCategory.name,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'estimatedDistanceKm': estimatedDistanceKm,
      'estimatedDurationMin': estimatedDurationMin,
      'baseFare': baseFare,
      'surgeMultiplier': surgeMultiplier,
      'totalFare': totalFare,
      'paymentMethod': paymentMethod.name,
      'paymentStatus': paymentStatus.name,
      'paystackReference': paystackReference,
      'promoCode': promoCode,
      'discountAmount': discountAmount,
      'trackingCode': trackingCode,
      'notes': notes,
      'proofOfDeliveryUrl': proofOfDeliveryUrl,
      'rating': rating,
      'ratingComment': ratingComment,
      'driverEarnings': driverEarnings,
      'platformCommission': platformCommission,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'estimatedDeliveryTime': estimatedDeliveryTime != null
          ? Timestamp.fromDate(estimatedDeliveryTime!)
          : null,
      'polylinePoints': polylinePoints
          .map((gp) => GeoPoint(gp.latitude, gp.longitude))
          .toList(),
    };
  }

  /// Check if order can transition to the given status
  bool canTransitionTo(OrderStatus newStatus) {
    const allowedTransitions = {
      OrderStatus.pending: [OrderStatus.accepted, OrderStatus.cancelled],
      OrderStatus.accepted: [OrderStatus.pickedUp, OrderStatus.cancelled],
      OrderStatus.pickedUp: [OrderStatus.inTransit],
      OrderStatus.inTransit: [OrderStatus.delivered, OrderStatus.failed],
      OrderStatus.delivered: <OrderStatus>[],
      OrderStatus.cancelled: <OrderStatus>[],
      OrderStatus.failed: <OrderStatus>[],
    };
    return allowedTransitions[status]?.contains(newStatus) ?? false;
  }
}
