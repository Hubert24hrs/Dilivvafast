// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'courier_order_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CourierOrderModel {

 String get id; String get userId; String? get driverId; OrderStatus get status; String get pickupAddress;@GeoPointConverter() GeoPoint get pickupGeoPoint; String get dropoffAddress;@GeoPointConverter() GeoPoint get dropoffGeoPoint; String get packageDescription; double get packageWeight; PackageCategory get packageCategory; String get recipientName; String get recipientPhone; double get estimatedDistanceKm; int get estimatedDurationMin; double get baseFare; double get surgeMultiplier; double get totalFare; PaymentMethod get paymentMethod; PaymentStatus get paymentStatus; String? get paystackReference; String? get promoCode; double get discountAmount; String get trackingCode; String? get notes; String? get proofOfDeliveryUrl; int? get rating; String? get ratingComment; double get driverEarnings; double get platformCommission;@TimestampConverter() DateTime get createdAt;@TimestampConverter() DateTime get updatedAt;@NullableTimestampConverter() DateTime? get pickedUpAt;@NullableTimestampConverter() DateTime? get deliveredAt;@NullableTimestampConverter() DateTime? get estimatedDeliveryTime;@GeoPointListConverter() List<GeoPoint> get polylinePoints;
/// Create a copy of CourierOrderModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourierOrderModelCopyWith<CourierOrderModel> get copyWith => _$CourierOrderModelCopyWithImpl<CourierOrderModel>(this as CourierOrderModel, _$identity);

  /// Serializes this CourierOrderModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourierOrderModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.status, status) || other.status == status)&&(identical(other.pickupAddress, pickupAddress) || other.pickupAddress == pickupAddress)&&(identical(other.pickupGeoPoint, pickupGeoPoint) || other.pickupGeoPoint == pickupGeoPoint)&&(identical(other.dropoffAddress, dropoffAddress) || other.dropoffAddress == dropoffAddress)&&(identical(other.dropoffGeoPoint, dropoffGeoPoint) || other.dropoffGeoPoint == dropoffGeoPoint)&&(identical(other.packageDescription, packageDescription) || other.packageDescription == packageDescription)&&(identical(other.packageWeight, packageWeight) || other.packageWeight == packageWeight)&&(identical(other.packageCategory, packageCategory) || other.packageCategory == packageCategory)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.estimatedDistanceKm, estimatedDistanceKm) || other.estimatedDistanceKm == estimatedDistanceKm)&&(identical(other.estimatedDurationMin, estimatedDurationMin) || other.estimatedDurationMin == estimatedDurationMin)&&(identical(other.baseFare, baseFare) || other.baseFare == baseFare)&&(identical(other.surgeMultiplier, surgeMultiplier) || other.surgeMultiplier == surgeMultiplier)&&(identical(other.totalFare, totalFare) || other.totalFare == totalFare)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paystackReference, paystackReference) || other.paystackReference == paystackReference)&&(identical(other.promoCode, promoCode) || other.promoCode == promoCode)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.trackingCode, trackingCode) || other.trackingCode == trackingCode)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.proofOfDeliveryUrl, proofOfDeliveryUrl) || other.proofOfDeliveryUrl == proofOfDeliveryUrl)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingComment, ratingComment) || other.ratingComment == ratingComment)&&(identical(other.driverEarnings, driverEarnings) || other.driverEarnings == driverEarnings)&&(identical(other.platformCommission, platformCommission) || other.platformCommission == platformCommission)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.pickedUpAt, pickedUpAt) || other.pickedUpAt == pickedUpAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.estimatedDeliveryTime, estimatedDeliveryTime) || other.estimatedDeliveryTime == estimatedDeliveryTime)&&const DeepCollectionEquality().equals(other.polylinePoints, polylinePoints));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,driverId,status,pickupAddress,pickupGeoPoint,dropoffAddress,dropoffGeoPoint,packageDescription,packageWeight,packageCategory,recipientName,recipientPhone,estimatedDistanceKm,estimatedDurationMin,baseFare,surgeMultiplier,totalFare,paymentMethod,paymentStatus,paystackReference,promoCode,discountAmount,trackingCode,notes,proofOfDeliveryUrl,rating,ratingComment,driverEarnings,platformCommission,createdAt,updatedAt,pickedUpAt,deliveredAt,estimatedDeliveryTime,const DeepCollectionEquality().hash(polylinePoints)]);

@override
String toString() {
  return 'CourierOrderModel(id: $id, userId: $userId, driverId: $driverId, status: $status, pickupAddress: $pickupAddress, pickupGeoPoint: $pickupGeoPoint, dropoffAddress: $dropoffAddress, dropoffGeoPoint: $dropoffGeoPoint, packageDescription: $packageDescription, packageWeight: $packageWeight, packageCategory: $packageCategory, recipientName: $recipientName, recipientPhone: $recipientPhone, estimatedDistanceKm: $estimatedDistanceKm, estimatedDurationMin: $estimatedDurationMin, baseFare: $baseFare, surgeMultiplier: $surgeMultiplier, totalFare: $totalFare, paymentMethod: $paymentMethod, paymentStatus: $paymentStatus, paystackReference: $paystackReference, promoCode: $promoCode, discountAmount: $discountAmount, trackingCode: $trackingCode, notes: $notes, proofOfDeliveryUrl: $proofOfDeliveryUrl, rating: $rating, ratingComment: $ratingComment, driverEarnings: $driverEarnings, platformCommission: $platformCommission, createdAt: $createdAt, updatedAt: $updatedAt, pickedUpAt: $pickedUpAt, deliveredAt: $deliveredAt, estimatedDeliveryTime: $estimatedDeliveryTime, polylinePoints: $polylinePoints)';
}


}

/// @nodoc
abstract mixin class $CourierOrderModelCopyWith<$Res>  {
  factory $CourierOrderModelCopyWith(CourierOrderModel value, $Res Function(CourierOrderModel) _then) = _$CourierOrderModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String? driverId, OrderStatus status, String pickupAddress,@GeoPointConverter() GeoPoint pickupGeoPoint, String dropoffAddress,@GeoPointConverter() GeoPoint dropoffGeoPoint, String packageDescription, double packageWeight, PackageCategory packageCategory, String recipientName, String recipientPhone, double estimatedDistanceKm, int estimatedDurationMin, double baseFare, double surgeMultiplier, double totalFare, PaymentMethod paymentMethod, PaymentStatus paymentStatus, String? paystackReference, String? promoCode, double discountAmount, String trackingCode, String? notes, String? proofOfDeliveryUrl, int? rating, String? ratingComment, double driverEarnings, double platformCommission,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt,@NullableTimestampConverter() DateTime? pickedUpAt,@NullableTimestampConverter() DateTime? deliveredAt,@NullableTimestampConverter() DateTime? estimatedDeliveryTime,@GeoPointListConverter() List<GeoPoint> polylinePoints
});




}
/// @nodoc
class _$CourierOrderModelCopyWithImpl<$Res>
    implements $CourierOrderModelCopyWith<$Res> {
  _$CourierOrderModelCopyWithImpl(this._self, this._then);

  final CourierOrderModel _self;
  final $Res Function(CourierOrderModel) _then;

/// Create a copy of CourierOrderModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? driverId = freezed,Object? status = null,Object? pickupAddress = null,Object? pickupGeoPoint = null,Object? dropoffAddress = null,Object? dropoffGeoPoint = null,Object? packageDescription = null,Object? packageWeight = null,Object? packageCategory = null,Object? recipientName = null,Object? recipientPhone = null,Object? estimatedDistanceKm = null,Object? estimatedDurationMin = null,Object? baseFare = null,Object? surgeMultiplier = null,Object? totalFare = null,Object? paymentMethod = null,Object? paymentStatus = null,Object? paystackReference = freezed,Object? promoCode = freezed,Object? discountAmount = null,Object? trackingCode = null,Object? notes = freezed,Object? proofOfDeliveryUrl = freezed,Object? rating = freezed,Object? ratingComment = freezed,Object? driverEarnings = null,Object? platformCommission = null,Object? createdAt = null,Object? updatedAt = null,Object? pickedUpAt = freezed,Object? deliveredAt = freezed,Object? estimatedDeliveryTime = freezed,Object? polylinePoints = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,pickupAddress: null == pickupAddress ? _self.pickupAddress : pickupAddress // ignore: cast_nullable_to_non_nullable
as String,pickupGeoPoint: null == pickupGeoPoint ? _self.pickupGeoPoint : pickupGeoPoint // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoffAddress: null == dropoffAddress ? _self.dropoffAddress : dropoffAddress // ignore: cast_nullable_to_non_nullable
as String,dropoffGeoPoint: null == dropoffGeoPoint ? _self.dropoffGeoPoint : dropoffGeoPoint // ignore: cast_nullable_to_non_nullable
as GeoPoint,packageDescription: null == packageDescription ? _self.packageDescription : packageDescription // ignore: cast_nullable_to_non_nullable
as String,packageWeight: null == packageWeight ? _self.packageWeight : packageWeight // ignore: cast_nullable_to_non_nullable
as double,packageCategory: null == packageCategory ? _self.packageCategory : packageCategory // ignore: cast_nullable_to_non_nullable
as PackageCategory,recipientName: null == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String,recipientPhone: null == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String,estimatedDistanceKm: null == estimatedDistanceKm ? _self.estimatedDistanceKm : estimatedDistanceKm // ignore: cast_nullable_to_non_nullable
as double,estimatedDurationMin: null == estimatedDurationMin ? _self.estimatedDurationMin : estimatedDurationMin // ignore: cast_nullable_to_non_nullable
as int,baseFare: null == baseFare ? _self.baseFare : baseFare // ignore: cast_nullable_to_non_nullable
as double,surgeMultiplier: null == surgeMultiplier ? _self.surgeMultiplier : surgeMultiplier // ignore: cast_nullable_to_non_nullable
as double,totalFare: null == totalFare ? _self.totalFare : totalFare // ignore: cast_nullable_to_non_nullable
as double,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,paystackReference: freezed == paystackReference ? _self.paystackReference : paystackReference // ignore: cast_nullable_to_non_nullable
as String?,promoCode: freezed == promoCode ? _self.promoCode : promoCode // ignore: cast_nullable_to_non_nullable
as String?,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,trackingCode: null == trackingCode ? _self.trackingCode : trackingCode // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,proofOfDeliveryUrl: freezed == proofOfDeliveryUrl ? _self.proofOfDeliveryUrl : proofOfDeliveryUrl // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,ratingComment: freezed == ratingComment ? _self.ratingComment : ratingComment // ignore: cast_nullable_to_non_nullable
as String?,driverEarnings: null == driverEarnings ? _self.driverEarnings : driverEarnings // ignore: cast_nullable_to_non_nullable
as double,platformCommission: null == platformCommission ? _self.platformCommission : platformCommission // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickedUpAt: freezed == pickedUpAt ? _self.pickedUpAt : pickedUpAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,estimatedDeliveryTime: freezed == estimatedDeliveryTime ? _self.estimatedDeliveryTime : estimatedDeliveryTime // ignore: cast_nullable_to_non_nullable
as DateTime?,polylinePoints: null == polylinePoints ? _self.polylinePoints : polylinePoints // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [CourierOrderModel].
extension CourierOrderModelPatterns on CourierOrderModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourierOrderModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourierOrderModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourierOrderModel value)  $default,){
final _that = this;
switch (_that) {
case _CourierOrderModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourierOrderModel value)?  $default,){
final _that = this;
switch (_that) {
case _CourierOrderModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String? driverId,  OrderStatus status,  String pickupAddress, @GeoPointConverter()  GeoPoint pickupGeoPoint,  String dropoffAddress, @GeoPointConverter()  GeoPoint dropoffGeoPoint,  String packageDescription,  double packageWeight,  PackageCategory packageCategory,  String recipientName,  String recipientPhone,  double estimatedDistanceKm,  int estimatedDurationMin,  double baseFare,  double surgeMultiplier,  double totalFare,  PaymentMethod paymentMethod,  PaymentStatus paymentStatus,  String? paystackReference,  String? promoCode,  double discountAmount,  String trackingCode,  String? notes,  String? proofOfDeliveryUrl,  int? rating,  String? ratingComment,  double driverEarnings,  double platformCommission, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableTimestampConverter()  DateTime? pickedUpAt, @NullableTimestampConverter()  DateTime? deliveredAt, @NullableTimestampConverter()  DateTime? estimatedDeliveryTime, @GeoPointListConverter()  List<GeoPoint> polylinePoints)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourierOrderModel() when $default != null:
return $default(_that.id,_that.userId,_that.driverId,_that.status,_that.pickupAddress,_that.pickupGeoPoint,_that.dropoffAddress,_that.dropoffGeoPoint,_that.packageDescription,_that.packageWeight,_that.packageCategory,_that.recipientName,_that.recipientPhone,_that.estimatedDistanceKm,_that.estimatedDurationMin,_that.baseFare,_that.surgeMultiplier,_that.totalFare,_that.paymentMethod,_that.paymentStatus,_that.paystackReference,_that.promoCode,_that.discountAmount,_that.trackingCode,_that.notes,_that.proofOfDeliveryUrl,_that.rating,_that.ratingComment,_that.driverEarnings,_that.platformCommission,_that.createdAt,_that.updatedAt,_that.pickedUpAt,_that.deliveredAt,_that.estimatedDeliveryTime,_that.polylinePoints);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String? driverId,  OrderStatus status,  String pickupAddress, @GeoPointConverter()  GeoPoint pickupGeoPoint,  String dropoffAddress, @GeoPointConverter()  GeoPoint dropoffGeoPoint,  String packageDescription,  double packageWeight,  PackageCategory packageCategory,  String recipientName,  String recipientPhone,  double estimatedDistanceKm,  int estimatedDurationMin,  double baseFare,  double surgeMultiplier,  double totalFare,  PaymentMethod paymentMethod,  PaymentStatus paymentStatus,  String? paystackReference,  String? promoCode,  double discountAmount,  String trackingCode,  String? notes,  String? proofOfDeliveryUrl,  int? rating,  String? ratingComment,  double driverEarnings,  double platformCommission, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableTimestampConverter()  DateTime? pickedUpAt, @NullableTimestampConverter()  DateTime? deliveredAt, @NullableTimestampConverter()  DateTime? estimatedDeliveryTime, @GeoPointListConverter()  List<GeoPoint> polylinePoints)  $default,) {final _that = this;
switch (_that) {
case _CourierOrderModel():
return $default(_that.id,_that.userId,_that.driverId,_that.status,_that.pickupAddress,_that.pickupGeoPoint,_that.dropoffAddress,_that.dropoffGeoPoint,_that.packageDescription,_that.packageWeight,_that.packageCategory,_that.recipientName,_that.recipientPhone,_that.estimatedDistanceKm,_that.estimatedDurationMin,_that.baseFare,_that.surgeMultiplier,_that.totalFare,_that.paymentMethod,_that.paymentStatus,_that.paystackReference,_that.promoCode,_that.discountAmount,_that.trackingCode,_that.notes,_that.proofOfDeliveryUrl,_that.rating,_that.ratingComment,_that.driverEarnings,_that.platformCommission,_that.createdAt,_that.updatedAt,_that.pickedUpAt,_that.deliveredAt,_that.estimatedDeliveryTime,_that.polylinePoints);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String? driverId,  OrderStatus status,  String pickupAddress, @GeoPointConverter()  GeoPoint pickupGeoPoint,  String dropoffAddress, @GeoPointConverter()  GeoPoint dropoffGeoPoint,  String packageDescription,  double packageWeight,  PackageCategory packageCategory,  String recipientName,  String recipientPhone,  double estimatedDistanceKm,  int estimatedDurationMin,  double baseFare,  double surgeMultiplier,  double totalFare,  PaymentMethod paymentMethod,  PaymentStatus paymentStatus,  String? paystackReference,  String? promoCode,  double discountAmount,  String trackingCode,  String? notes,  String? proofOfDeliveryUrl,  int? rating,  String? ratingComment,  double driverEarnings,  double platformCommission, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableTimestampConverter()  DateTime? pickedUpAt, @NullableTimestampConverter()  DateTime? deliveredAt, @NullableTimestampConverter()  DateTime? estimatedDeliveryTime, @GeoPointListConverter()  List<GeoPoint> polylinePoints)?  $default,) {final _that = this;
switch (_that) {
case _CourierOrderModel() when $default != null:
return $default(_that.id,_that.userId,_that.driverId,_that.status,_that.pickupAddress,_that.pickupGeoPoint,_that.dropoffAddress,_that.dropoffGeoPoint,_that.packageDescription,_that.packageWeight,_that.packageCategory,_that.recipientName,_that.recipientPhone,_that.estimatedDistanceKm,_that.estimatedDurationMin,_that.baseFare,_that.surgeMultiplier,_that.totalFare,_that.paymentMethod,_that.paymentStatus,_that.paystackReference,_that.promoCode,_that.discountAmount,_that.trackingCode,_that.notes,_that.proofOfDeliveryUrl,_that.rating,_that.ratingComment,_that.driverEarnings,_that.platformCommission,_that.createdAt,_that.updatedAt,_that.pickedUpAt,_that.deliveredAt,_that.estimatedDeliveryTime,_that.polylinePoints);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourierOrderModel extends CourierOrderModel {
  const _CourierOrderModel({required this.id, required this.userId, this.driverId, this.status = OrderStatus.pending, required this.pickupAddress, @GeoPointConverter() required this.pickupGeoPoint, required this.dropoffAddress, @GeoPointConverter() required this.dropoffGeoPoint, required this.packageDescription, this.packageWeight = 0.0, this.packageCategory = PackageCategory.other, required this.recipientName, required this.recipientPhone, this.estimatedDistanceKm = 0.0, this.estimatedDurationMin = 0, this.baseFare = 0.0, this.surgeMultiplier = 1.0, this.totalFare = 0.0, this.paymentMethod = PaymentMethod.wallet, this.paymentStatus = PaymentStatus.pending, this.paystackReference, this.promoCode, this.discountAmount = 0.0, required this.trackingCode, this.notes, this.proofOfDeliveryUrl, this.rating, this.ratingComment, this.driverEarnings = 0.0, this.platformCommission = 0.0, @TimestampConverter() required this.createdAt, @TimestampConverter() required this.updatedAt, @NullableTimestampConverter() this.pickedUpAt, @NullableTimestampConverter() this.deliveredAt, @NullableTimestampConverter() this.estimatedDeliveryTime, @GeoPointListConverter() final  List<GeoPoint> polylinePoints = const []}): _polylinePoints = polylinePoints,super._();
  factory _CourierOrderModel.fromJson(Map<String, dynamic> json) => _$CourierOrderModelFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String? driverId;
@override@JsonKey() final  OrderStatus status;
@override final  String pickupAddress;
@override@GeoPointConverter() final  GeoPoint pickupGeoPoint;
@override final  String dropoffAddress;
@override@GeoPointConverter() final  GeoPoint dropoffGeoPoint;
@override final  String packageDescription;
@override@JsonKey() final  double packageWeight;
@override@JsonKey() final  PackageCategory packageCategory;
@override final  String recipientName;
@override final  String recipientPhone;
@override@JsonKey() final  double estimatedDistanceKm;
@override@JsonKey() final  int estimatedDurationMin;
@override@JsonKey() final  double baseFare;
@override@JsonKey() final  double surgeMultiplier;
@override@JsonKey() final  double totalFare;
@override@JsonKey() final  PaymentMethod paymentMethod;
@override@JsonKey() final  PaymentStatus paymentStatus;
@override final  String? paystackReference;
@override final  String? promoCode;
@override@JsonKey() final  double discountAmount;
@override final  String trackingCode;
@override final  String? notes;
@override final  String? proofOfDeliveryUrl;
@override final  int? rating;
@override final  String? ratingComment;
@override@JsonKey() final  double driverEarnings;
@override@JsonKey() final  double platformCommission;
@override@TimestampConverter() final  DateTime createdAt;
@override@TimestampConverter() final  DateTime updatedAt;
@override@NullableTimestampConverter() final  DateTime? pickedUpAt;
@override@NullableTimestampConverter() final  DateTime? deliveredAt;
@override@NullableTimestampConverter() final  DateTime? estimatedDeliveryTime;
 final  List<GeoPoint> _polylinePoints;
@override@JsonKey()@GeoPointListConverter() List<GeoPoint> get polylinePoints {
  if (_polylinePoints is EqualUnmodifiableListView) return _polylinePoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_polylinePoints);
}


/// Create a copy of CourierOrderModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourierOrderModelCopyWith<_CourierOrderModel> get copyWith => __$CourierOrderModelCopyWithImpl<_CourierOrderModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourierOrderModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourierOrderModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.status, status) || other.status == status)&&(identical(other.pickupAddress, pickupAddress) || other.pickupAddress == pickupAddress)&&(identical(other.pickupGeoPoint, pickupGeoPoint) || other.pickupGeoPoint == pickupGeoPoint)&&(identical(other.dropoffAddress, dropoffAddress) || other.dropoffAddress == dropoffAddress)&&(identical(other.dropoffGeoPoint, dropoffGeoPoint) || other.dropoffGeoPoint == dropoffGeoPoint)&&(identical(other.packageDescription, packageDescription) || other.packageDescription == packageDescription)&&(identical(other.packageWeight, packageWeight) || other.packageWeight == packageWeight)&&(identical(other.packageCategory, packageCategory) || other.packageCategory == packageCategory)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.estimatedDistanceKm, estimatedDistanceKm) || other.estimatedDistanceKm == estimatedDistanceKm)&&(identical(other.estimatedDurationMin, estimatedDurationMin) || other.estimatedDurationMin == estimatedDurationMin)&&(identical(other.baseFare, baseFare) || other.baseFare == baseFare)&&(identical(other.surgeMultiplier, surgeMultiplier) || other.surgeMultiplier == surgeMultiplier)&&(identical(other.totalFare, totalFare) || other.totalFare == totalFare)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paystackReference, paystackReference) || other.paystackReference == paystackReference)&&(identical(other.promoCode, promoCode) || other.promoCode == promoCode)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.trackingCode, trackingCode) || other.trackingCode == trackingCode)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.proofOfDeliveryUrl, proofOfDeliveryUrl) || other.proofOfDeliveryUrl == proofOfDeliveryUrl)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingComment, ratingComment) || other.ratingComment == ratingComment)&&(identical(other.driverEarnings, driverEarnings) || other.driverEarnings == driverEarnings)&&(identical(other.platformCommission, platformCommission) || other.platformCommission == platformCommission)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.pickedUpAt, pickedUpAt) || other.pickedUpAt == pickedUpAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.estimatedDeliveryTime, estimatedDeliveryTime) || other.estimatedDeliveryTime == estimatedDeliveryTime)&&const DeepCollectionEquality().equals(other._polylinePoints, _polylinePoints));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,driverId,status,pickupAddress,pickupGeoPoint,dropoffAddress,dropoffGeoPoint,packageDescription,packageWeight,packageCategory,recipientName,recipientPhone,estimatedDistanceKm,estimatedDurationMin,baseFare,surgeMultiplier,totalFare,paymentMethod,paymentStatus,paystackReference,promoCode,discountAmount,trackingCode,notes,proofOfDeliveryUrl,rating,ratingComment,driverEarnings,platformCommission,createdAt,updatedAt,pickedUpAt,deliveredAt,estimatedDeliveryTime,const DeepCollectionEquality().hash(_polylinePoints)]);

@override
String toString() {
  return 'CourierOrderModel(id: $id, userId: $userId, driverId: $driverId, status: $status, pickupAddress: $pickupAddress, pickupGeoPoint: $pickupGeoPoint, dropoffAddress: $dropoffAddress, dropoffGeoPoint: $dropoffGeoPoint, packageDescription: $packageDescription, packageWeight: $packageWeight, packageCategory: $packageCategory, recipientName: $recipientName, recipientPhone: $recipientPhone, estimatedDistanceKm: $estimatedDistanceKm, estimatedDurationMin: $estimatedDurationMin, baseFare: $baseFare, surgeMultiplier: $surgeMultiplier, totalFare: $totalFare, paymentMethod: $paymentMethod, paymentStatus: $paymentStatus, paystackReference: $paystackReference, promoCode: $promoCode, discountAmount: $discountAmount, trackingCode: $trackingCode, notes: $notes, proofOfDeliveryUrl: $proofOfDeliveryUrl, rating: $rating, ratingComment: $ratingComment, driverEarnings: $driverEarnings, platformCommission: $platformCommission, createdAt: $createdAt, updatedAt: $updatedAt, pickedUpAt: $pickedUpAt, deliveredAt: $deliveredAt, estimatedDeliveryTime: $estimatedDeliveryTime, polylinePoints: $polylinePoints)';
}


}

/// @nodoc
abstract mixin class _$CourierOrderModelCopyWith<$Res> implements $CourierOrderModelCopyWith<$Res> {
  factory _$CourierOrderModelCopyWith(_CourierOrderModel value, $Res Function(_CourierOrderModel) _then) = __$CourierOrderModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String? driverId, OrderStatus status, String pickupAddress,@GeoPointConverter() GeoPoint pickupGeoPoint, String dropoffAddress,@GeoPointConverter() GeoPoint dropoffGeoPoint, String packageDescription, double packageWeight, PackageCategory packageCategory, String recipientName, String recipientPhone, double estimatedDistanceKm, int estimatedDurationMin, double baseFare, double surgeMultiplier, double totalFare, PaymentMethod paymentMethod, PaymentStatus paymentStatus, String? paystackReference, String? promoCode, double discountAmount, String trackingCode, String? notes, String? proofOfDeliveryUrl, int? rating, String? ratingComment, double driverEarnings, double platformCommission,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt,@NullableTimestampConverter() DateTime? pickedUpAt,@NullableTimestampConverter() DateTime? deliveredAt,@NullableTimestampConverter() DateTime? estimatedDeliveryTime,@GeoPointListConverter() List<GeoPoint> polylinePoints
});




}
/// @nodoc
class __$CourierOrderModelCopyWithImpl<$Res>
    implements _$CourierOrderModelCopyWith<$Res> {
  __$CourierOrderModelCopyWithImpl(this._self, this._then);

  final _CourierOrderModel _self;
  final $Res Function(_CourierOrderModel) _then;

/// Create a copy of CourierOrderModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? driverId = freezed,Object? status = null,Object? pickupAddress = null,Object? pickupGeoPoint = null,Object? dropoffAddress = null,Object? dropoffGeoPoint = null,Object? packageDescription = null,Object? packageWeight = null,Object? packageCategory = null,Object? recipientName = null,Object? recipientPhone = null,Object? estimatedDistanceKm = null,Object? estimatedDurationMin = null,Object? baseFare = null,Object? surgeMultiplier = null,Object? totalFare = null,Object? paymentMethod = null,Object? paymentStatus = null,Object? paystackReference = freezed,Object? promoCode = freezed,Object? discountAmount = null,Object? trackingCode = null,Object? notes = freezed,Object? proofOfDeliveryUrl = freezed,Object? rating = freezed,Object? ratingComment = freezed,Object? driverEarnings = null,Object? platformCommission = null,Object? createdAt = null,Object? updatedAt = null,Object? pickedUpAt = freezed,Object? deliveredAt = freezed,Object? estimatedDeliveryTime = freezed,Object? polylinePoints = null,}) {
  return _then(_CourierOrderModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,pickupAddress: null == pickupAddress ? _self.pickupAddress : pickupAddress // ignore: cast_nullable_to_non_nullable
as String,pickupGeoPoint: null == pickupGeoPoint ? _self.pickupGeoPoint : pickupGeoPoint // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoffAddress: null == dropoffAddress ? _self.dropoffAddress : dropoffAddress // ignore: cast_nullable_to_non_nullable
as String,dropoffGeoPoint: null == dropoffGeoPoint ? _self.dropoffGeoPoint : dropoffGeoPoint // ignore: cast_nullable_to_non_nullable
as GeoPoint,packageDescription: null == packageDescription ? _self.packageDescription : packageDescription // ignore: cast_nullable_to_non_nullable
as String,packageWeight: null == packageWeight ? _self.packageWeight : packageWeight // ignore: cast_nullable_to_non_nullable
as double,packageCategory: null == packageCategory ? _self.packageCategory : packageCategory // ignore: cast_nullable_to_non_nullable
as PackageCategory,recipientName: null == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String,recipientPhone: null == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String,estimatedDistanceKm: null == estimatedDistanceKm ? _self.estimatedDistanceKm : estimatedDistanceKm // ignore: cast_nullable_to_non_nullable
as double,estimatedDurationMin: null == estimatedDurationMin ? _self.estimatedDurationMin : estimatedDurationMin // ignore: cast_nullable_to_non_nullable
as int,baseFare: null == baseFare ? _self.baseFare : baseFare // ignore: cast_nullable_to_non_nullable
as double,surgeMultiplier: null == surgeMultiplier ? _self.surgeMultiplier : surgeMultiplier // ignore: cast_nullable_to_non_nullable
as double,totalFare: null == totalFare ? _self.totalFare : totalFare // ignore: cast_nullable_to_non_nullable
as double,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,paystackReference: freezed == paystackReference ? _self.paystackReference : paystackReference // ignore: cast_nullable_to_non_nullable
as String?,promoCode: freezed == promoCode ? _self.promoCode : promoCode // ignore: cast_nullable_to_non_nullable
as String?,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,trackingCode: null == trackingCode ? _self.trackingCode : trackingCode // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,proofOfDeliveryUrl: freezed == proofOfDeliveryUrl ? _self.proofOfDeliveryUrl : proofOfDeliveryUrl // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,ratingComment: freezed == ratingComment ? _self.ratingComment : ratingComment // ignore: cast_nullable_to_non_nullable
as String?,driverEarnings: null == driverEarnings ? _self.driverEarnings : driverEarnings // ignore: cast_nullable_to_non_nullable
as double,platformCommission: null == platformCommission ? _self.platformCommission : platformCommission // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pickedUpAt: freezed == pickedUpAt ? _self.pickedUpAt : pickedUpAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,estimatedDeliveryTime: freezed == estimatedDeliveryTime ? _self.estimatedDeliveryTime : estimatedDeliveryTime // ignore: cast_nullable_to_non_nullable
as DateTime?,polylinePoints: null == polylinePoints ? _self._polylinePoints : polylinePoints // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,
  ));
}


}

// dart format on
