import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

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

/// JSON converter for Firestore GeoPoint.
///
/// Accepts BOTH a native [GeoPoint] and a `{latitude, longitude}` map.
/// This converter was declared as `JsonConverter<GeoPoint, Map<String,
/// dynamic>>`, so the generated decoder cast `json['pickupGeoPoint']` to a Map
/// — but `toFirestore()` stores a native GeoPoint (correctly, so the field
/// stays geo-queryable), and Firestore hands one back on read. Every attempt
/// to decode a courier order therefore threw
/// `type 'GeoPoint' is not a subtype of type 'Map<String, dynamic>'`,
/// taking out order history, active-order tracking and the driver job list.
///
/// Mirrors NullableGeoPointConverter in user_model.dart, which already had it
/// right. Writes stay native so existing documents and queries are unaffected.
class GeoPointConverter implements JsonConverter<GeoPoint, Object?> {
  const GeoPointConverter();

  @override
  GeoPoint fromJson(Object? json) {
    if (json is GeoPoint) return json;
    if (json is Map) {
      final lat = json['latitude'] as num?;
      final lng = json['longitude'] as num?;
      if (lat != null && lng != null) {
        return GeoPoint(lat.toDouble(), lng.toDouble());
      }
    }
    // Null Island: a lossy but non-fatal fallback. Throwing here would fail
    // the whole order list because of one malformed document.
    return const GeoPoint(0, 0);
  }

  @override
  Object? toJson(GeoPoint geoPoint) => geoPoint;
}

/// JSON converter for `List<GeoPoint>`
class GeoPointListConverter
    implements JsonConverter<List<GeoPoint>, List<dynamic>> {
  const GeoPointListConverter();

  /// Same dual-format handling as [GeoPointConverter]: route polylines are
  /// stored as native GeoPoints, so decoding must accept them.
  @override
  List<GeoPoint> fromJson(List<dynamic> jsonList) {
    return jsonList
        .map((item) {
          if (item is GeoPoint) return item;
          if (item is Map) {
            final lat = item['latitude'] as num?;
            final lng = item['longitude'] as num?;
            if (lat != null && lng != null) {
              return GeoPoint(lat.toDouble(), lng.toDouble());
            }
          }
          return null;
        })
        .whereType<GeoPoint>()
        .toList();
  }

  @override
  List<dynamic> toJson(List<GeoPoint> geoPoints) => geoPoints;
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
    // Older builds wrote `pickedUp` / `inTransit` (from `.name`) where the
    // schema declares `picked_up` / `in_transit`. Normalise before decoding so
    // documents written by those builds still load.
    data['status'] = orderStatusFromWire(data['status'] as String?).wireValue;
    return CourierOrderModel.fromJson(data);
  }
}

/// Canonical Firestore representation of an [OrderStatus].
///
/// Use this, never `.name`. The enum declares `@JsonValue('picked_up')` and
/// `@JsonValue('in_transit')`, so `fromJson` expects snake_case — but writes
/// used `.name`, which produces `pickedUp` / `inTransit`. Reads and writes
/// therefore disagreed on exactly the two mid-delivery states, and an order
/// that reached either one could not be deserialised again.
///
/// `_$OrderStatusEnumMap` is generated into the `part` file below, so it is
/// visible here and stays in step with the annotations automatically.
extension OrderStatusWire on OrderStatus {
  String get wireValue => _$OrderStatusEnumMap[this]!;
}

/// Parse a status written by any app version.
///
/// Accepts the canonical snake_case form and also tolerates the legacy
/// camelCase values that older builds wrote, so historical documents keep
/// loading. Unknown values fall back to [OrderStatus.pending] rather than
/// throwing and taking the whole order list down.
OrderStatus orderStatusFromWire(String? value) {
  if (value == null) return OrderStatus.pending;
  for (final entry in _$OrderStatusEnumMap.entries) {
    if (entry.value == value) return entry.key;
  }
  for (final status in OrderStatus.values) {
    if (status.name == value) return status; // legacy camelCase
  }
  return OrderStatus.pending;
}

extension CourierOrderModelX on CourierOrderModel {
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'driverId': driverId,
      'status': status.wireValue,
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
      'deliveredAt': deliveredAt != null
          ? Timestamp.fromDate(deliveredAt!)
          : null,
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
