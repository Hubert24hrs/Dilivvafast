import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dilivvafast/core/domain/entities/bank_account.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

part 'courier_order_model.freezed.dart';
part 'courier_order_model.g.dart';

enum OrderStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,

  /// The courier is at the pickup point (inDrive's "I've arrived").
  @JsonValue('arrived')
  arrived,
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

/// How the customer pays their courier. There is no in-app wallet or card:
/// the money goes straight from the customer to the courier once the
/// delivery is done, as cash or as a bank transfer to the courier's account.
enum PaymentMethod {
  @JsonValue('cash')
  cash,
  @JsonValue('transfer')
  transfer;

  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.transfer => 'Bank transfer',
  };
}

/// pending → (customer, transfer only) sent → (courier) paid.
///
/// `sent` is the customer saying "I've made the transfer"; only the courier
/// can confirm the money arrived. Enforced in firestore.rules.
enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('sent')
  sent,
  @JsonValue('paid')
  paid,
  @JsonValue('refunded')
  refunded,
}

/// The kind of courier a customer is booking.
///
/// This is the service the customer picks on the home screen. It is matched
/// against a driver's own vehicle when offers are placed: a `bike` job can be
/// taken by a motorcycle or bicycle rider, a `car` job by a car or van driver.
/// The same mapping is enforced in firestore.rules and in the dispatch trigger.
enum CourierVehicle {
  @JsonValue('bike')
  bike,
  @JsonValue('car')
  car;

  String get label => switch (this) {
    CourierVehicle.bike => 'Bike',
    CourierVehicle.car => 'Car',
  };

  /// Driver vehicle types (from the driver application) that can serve this.
  List<String> get driverVehicleTypes => switch (this) {
    CourierVehicle.bike => const ['motorcycle', 'bicycle'],
    CourierVehicle.car => const ['car', 'van'],
  };

  /// Firestore value — the @JsonValue, not `.name` (they happen to coincide
  /// here, but going through one accessor keeps that from being load-bearing).
  String get wireValue => this == CourierVehicle.bike ? 'bike' : 'car';

  static CourierVehicle forDriverVehicle(String? driverVehicleType) =>
      switch (driverVehicleType) {
        'car' || 'van' => CourierVehicle.car,
        _ => CourierVehicle.bike,
      };
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

    /// Which courier service was booked. Orders created before this field
    /// existed decode as [CourierVehicle.bike], the only service then offered.
    // Freezed forwards this to the generated field; the analyzer cannot see
    // that. The generated decoder does use unknownValue (see the .g.dart).
    // ignore: invalid_annotation_target
    @JsonKey(unknownEnumValue: CourierVehicle.bike)
    @Default(CourierVehicle.bike)
    CourierVehicle vehicleType,

    /// The price the customer is offering, inDrive-style. Server-validated:
    /// `onCourierCreated` clamps it to the allowed band around
    /// [recommendedFare], and only `raiseOffer` may change it afterwards.
    @Default(0.0) double offeredFare,

    /// Assign the first courier who offers exactly [offeredFare], without the
    /// customer having to tap Accept (inDrive's auto-accept). Done
    /// server-side by onBidWritten.
    @Default(false) bool autoAccept,

    /// The fare the server computed from distance, weight and zone pricing.
    /// Shown to the customer as guidance and used to bound offers.
    @Default(0.0) double recommendedFare,

    /// Orders from builds that offered "wallet" or "card" read as cash.
    // ignore: invalid_annotation_target
    @JsonKey(unknownEnumValue: PaymentMethod.cash)
    @Default(PaymentMethod.cash)
    PaymentMethod paymentMethod,
    // ignore: invalid_annotation_target
    @JsonKey(unknownEnumValue: PaymentStatus.pending)
    @Default(PaymentStatus.pending)
    PaymentStatus paymentStatus,

    /// The courier's bank details, copied onto the order by the server when
    /// their offer is accepted, so the customer can pay them by transfer.
    /// Null until then, or if the courier has not added an account.
    @BankAccountConverter() BankAccount? courierBank,
    String? promoCode,
    @Default(0.0) double discountAmount,
    required String trackingCode,
    String? notes,

    /// Why the customer cancelled, from the reasons offered in the app.
    String? cancelReason,

    /// Who cancelled: `customer` (written by the app, enforced by the
    /// rules). A courier cancelling does not end the order — it goes back to
    /// pending through `courierCancelJob`.
    String? cancelledBy,
    String? proofOfDeliveryUrl,
    int? rating,
    String? ratingComment,

    /// Compliments chosen with the rating ("Fast delivery", …).
    @Default(<String>[]) List<String> ratingTags,

    /// The customer's own rating as couriers have rated them, copied onto the
    /// request by the server when it is created (onCourierCreated), so a
    /// courier can see it before making an offer, as in inDrive. Null and 0
    /// for a customer nobody has rated yet.
    double? customerRatingAvg,
    @Default(0) int customerRatingCount,

    /// The courier's rating of the customer for this delivery (1–5), given
    /// once it is delivered. Counted into the customer's average server-side.
    int? customerRatingByCourier,
    @Default(0.0) double driverEarnings,
    @Default(0.0) double platformCommission,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @NullableTimestampConverter() DateTime? arrivedAt,
    @NullableTimestampConverter() DateTime? pickedUpAt,
    @NullableTimestampConverter() DateTime? deliveredAt,

    /// When the courier confirmed they were paid.
    @NullableTimestampConverter() DateTime? paidAt,
    @NullableTimestampConverter() DateTime? estimatedDeliveryTime,
    @GeoPointListConverter() @Default([]) List<GeoPoint> polylinePoints,
  }) = _CourierOrderModel;

  factory CourierOrderModel.fromJson(Map<String, dynamic> json) =>
      _$CourierOrderModelFromJson(json);

  /// [fromFirestore], or null for a document this version cannot read —
  /// e.g. orders written by the first version of the app, which used a
  /// different layout (riderId, pickupLocation, price…) and have no
  /// tracking code or coordinates. Lists skip them instead of failing.
  static CourierOrderModel? tryFromFirestore(DocumentSnapshot doc) {
    try {
      return CourierOrderModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

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
      'vehicleType': vehicleType.wireValue,
      'offeredFare': offeredFare,
      'autoAccept': autoAccept,
      'recommendedFare': recommendedFare,
      'paymentMethod': paymentMethod.name,
      'paymentStatus': paymentStatus.name,
      'promoCode': promoCode,
      'discountAmount': discountAmount,
      'trackingCode': trackingCode,
      'notes': notes,
      'cancelReason': cancelReason,
      'cancelledBy': cancelledBy,
      'proofOfDeliveryUrl': proofOfDeliveryUrl,
      'rating': rating,
      'ratingComment': ratingComment,
      'ratingTags': ratingTags,
      'driverEarnings': driverEarnings,
      'platformCommission': platformCommission,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'arrivedAt': arrivedAt != null ? Timestamp.fromDate(arrivedAt!) : null,
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
      // Arriving is optional, so a courier who goes straight to pickup is
      // not blocked; both paths end at picked up.
      OrderStatus.accepted: [
        OrderStatus.arrived,
        OrderStatus.pickedUp,
        OrderStatus.cancelled,
      ],
      OrderStatus.arrived: [OrderStatus.pickedUp, OrderStatus.cancelled],
      OrderStatus.pickedUp: [OrderStatus.inTransit],
      OrderStatus.inTransit: [OrderStatus.delivered, OrderStatus.failed],
      OrderStatus.delivered: <OrderStatus>[],
      OrderStatus.cancelled: <OrderStatus>[],
      OrderStatus.failed: <OrderStatus>[],
    };
    return allowedTransitions[status]?.contains(newStatus) ?? false;
  }
}
