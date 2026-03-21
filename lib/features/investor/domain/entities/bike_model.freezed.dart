// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bike_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BikeModel {

 String get id; String get make; String get model; int get year; String get plateNumber; double get purchasePrice; BikeStatus get status; String? get investorId; String? get riderId; double get totalRepayment; double get repaidAmount; double get monthlyInstalment; double get commissionRate; List<String> get imageUrls;@TimestampConverter() DateTime get createdAt;
/// Create a copy of BikeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BikeModelCopyWith<BikeModel> get copyWith => _$BikeModelCopyWithImpl<BikeModel>(this as BikeModel, _$identity);

  /// Serializes this BikeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BikeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.status, status) || other.status == status)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.riderId, riderId) || other.riderId == riderId)&&(identical(other.totalRepayment, totalRepayment) || other.totalRepayment == totalRepayment)&&(identical(other.repaidAmount, repaidAmount) || other.repaidAmount == repaidAmount)&&(identical(other.monthlyInstalment, monthlyInstalment) || other.monthlyInstalment == monthlyInstalment)&&(identical(other.commissionRate, commissionRate) || other.commissionRate == commissionRate)&&const DeepCollectionEquality().equals(other.imageUrls, imageUrls)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,make,model,year,plateNumber,purchasePrice,status,investorId,riderId,totalRepayment,repaidAmount,monthlyInstalment,commissionRate,const DeepCollectionEquality().hash(imageUrls),createdAt);

@override
String toString() {
  return 'BikeModel(id: $id, make: $make, model: $model, year: $year, plateNumber: $plateNumber, purchasePrice: $purchasePrice, status: $status, investorId: $investorId, riderId: $riderId, totalRepayment: $totalRepayment, repaidAmount: $repaidAmount, monthlyInstalment: $monthlyInstalment, commissionRate: $commissionRate, imageUrls: $imageUrls, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BikeModelCopyWith<$Res>  {
  factory $BikeModelCopyWith(BikeModel value, $Res Function(BikeModel) _then) = _$BikeModelCopyWithImpl;
@useResult
$Res call({
 String id, String make, String model, int year, String plateNumber, double purchasePrice, BikeStatus status, String? investorId, String? riderId, double totalRepayment, double repaidAmount, double monthlyInstalment, double commissionRate, List<String> imageUrls,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$BikeModelCopyWithImpl<$Res>
    implements $BikeModelCopyWith<$Res> {
  _$BikeModelCopyWithImpl(this._self, this._then);

  final BikeModel _self;
  final $Res Function(BikeModel) _then;

/// Create a copy of BikeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? make = null,Object? model = null,Object? year = null,Object? plateNumber = null,Object? purchasePrice = null,Object? status = null,Object? investorId = freezed,Object? riderId = freezed,Object? totalRepayment = null,Object? repaidAmount = null,Object? monthlyInstalment = null,Object? commissionRate = null,Object? imageUrls = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,make: null == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,plateNumber: null == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String,purchasePrice: null == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BikeStatus,investorId: freezed == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as String?,riderId: freezed == riderId ? _self.riderId : riderId // ignore: cast_nullable_to_non_nullable
as String?,totalRepayment: null == totalRepayment ? _self.totalRepayment : totalRepayment // ignore: cast_nullable_to_non_nullable
as double,repaidAmount: null == repaidAmount ? _self.repaidAmount : repaidAmount // ignore: cast_nullable_to_non_nullable
as double,monthlyInstalment: null == monthlyInstalment ? _self.monthlyInstalment : monthlyInstalment // ignore: cast_nullable_to_non_nullable
as double,commissionRate: null == commissionRate ? _self.commissionRate : commissionRate // ignore: cast_nullable_to_non_nullable
as double,imageUrls: null == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BikeModel].
extension BikeModelPatterns on BikeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BikeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BikeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BikeModel value)  $default,){
final _that = this;
switch (_that) {
case _BikeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BikeModel value)?  $default,){
final _that = this;
switch (_that) {
case _BikeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String make,  String model,  int year,  String plateNumber,  double purchasePrice,  BikeStatus status,  String? investorId,  String? riderId,  double totalRepayment,  double repaidAmount,  double monthlyInstalment,  double commissionRate,  List<String> imageUrls, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BikeModel() when $default != null:
return $default(_that.id,_that.make,_that.model,_that.year,_that.plateNumber,_that.purchasePrice,_that.status,_that.investorId,_that.riderId,_that.totalRepayment,_that.repaidAmount,_that.monthlyInstalment,_that.commissionRate,_that.imageUrls,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String make,  String model,  int year,  String plateNumber,  double purchasePrice,  BikeStatus status,  String? investorId,  String? riderId,  double totalRepayment,  double repaidAmount,  double monthlyInstalment,  double commissionRate,  List<String> imageUrls, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _BikeModel():
return $default(_that.id,_that.make,_that.model,_that.year,_that.plateNumber,_that.purchasePrice,_that.status,_that.investorId,_that.riderId,_that.totalRepayment,_that.repaidAmount,_that.monthlyInstalment,_that.commissionRate,_that.imageUrls,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String make,  String model,  int year,  String plateNumber,  double purchasePrice,  BikeStatus status,  String? investorId,  String? riderId,  double totalRepayment,  double repaidAmount,  double monthlyInstalment,  double commissionRate,  List<String> imageUrls, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _BikeModel() when $default != null:
return $default(_that.id,_that.make,_that.model,_that.year,_that.plateNumber,_that.purchasePrice,_that.status,_that.investorId,_that.riderId,_that.totalRepayment,_that.repaidAmount,_that.monthlyInstalment,_that.commissionRate,_that.imageUrls,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BikeModel extends BikeModel {
  const _BikeModel({required this.id, required this.make, required this.model, required this.year, required this.plateNumber, required this.purchasePrice, this.status = BikeStatus.pendingFunding, this.investorId, this.riderId, this.totalRepayment = 0.0, this.repaidAmount = 0.0, this.monthlyInstalment = 0.0, this.commissionRate = 0.15, final  List<String> imageUrls = const [], @TimestampConverter() required this.createdAt}): _imageUrls = imageUrls,super._();
  factory _BikeModel.fromJson(Map<String, dynamic> json) => _$BikeModelFromJson(json);

@override final  String id;
@override final  String make;
@override final  String model;
@override final  int year;
@override final  String plateNumber;
@override final  double purchasePrice;
@override@JsonKey() final  BikeStatus status;
@override final  String? investorId;
@override final  String? riderId;
@override@JsonKey() final  double totalRepayment;
@override@JsonKey() final  double repaidAmount;
@override@JsonKey() final  double monthlyInstalment;
@override@JsonKey() final  double commissionRate;
 final  List<String> _imageUrls;
@override@JsonKey() List<String> get imageUrls {
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageUrls);
}

@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of BikeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BikeModelCopyWith<_BikeModel> get copyWith => __$BikeModelCopyWithImpl<_BikeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BikeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BikeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.year, year) || other.year == year)&&(identical(other.plateNumber, plateNumber) || other.plateNumber == plateNumber)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.status, status) || other.status == status)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.riderId, riderId) || other.riderId == riderId)&&(identical(other.totalRepayment, totalRepayment) || other.totalRepayment == totalRepayment)&&(identical(other.repaidAmount, repaidAmount) || other.repaidAmount == repaidAmount)&&(identical(other.monthlyInstalment, monthlyInstalment) || other.monthlyInstalment == monthlyInstalment)&&(identical(other.commissionRate, commissionRate) || other.commissionRate == commissionRate)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,make,model,year,plateNumber,purchasePrice,status,investorId,riderId,totalRepayment,repaidAmount,monthlyInstalment,commissionRate,const DeepCollectionEquality().hash(_imageUrls),createdAt);

@override
String toString() {
  return 'BikeModel(id: $id, make: $make, model: $model, year: $year, plateNumber: $plateNumber, purchasePrice: $purchasePrice, status: $status, investorId: $investorId, riderId: $riderId, totalRepayment: $totalRepayment, repaidAmount: $repaidAmount, monthlyInstalment: $monthlyInstalment, commissionRate: $commissionRate, imageUrls: $imageUrls, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BikeModelCopyWith<$Res> implements $BikeModelCopyWith<$Res> {
  factory _$BikeModelCopyWith(_BikeModel value, $Res Function(_BikeModel) _then) = __$BikeModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String make, String model, int year, String plateNumber, double purchasePrice, BikeStatus status, String? investorId, String? riderId, double totalRepayment, double repaidAmount, double monthlyInstalment, double commissionRate, List<String> imageUrls,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$BikeModelCopyWithImpl<$Res>
    implements _$BikeModelCopyWith<$Res> {
  __$BikeModelCopyWithImpl(this._self, this._then);

  final _BikeModel _self;
  final $Res Function(_BikeModel) _then;

/// Create a copy of BikeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? make = null,Object? model = null,Object? year = null,Object? plateNumber = null,Object? purchasePrice = null,Object? status = null,Object? investorId = freezed,Object? riderId = freezed,Object? totalRepayment = null,Object? repaidAmount = null,Object? monthlyInstalment = null,Object? commissionRate = null,Object? imageUrls = null,Object? createdAt = null,}) {
  return _then(_BikeModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,make: null == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,plateNumber: null == plateNumber ? _self.plateNumber : plateNumber // ignore: cast_nullable_to_non_nullable
as String,purchasePrice: null == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BikeStatus,investorId: freezed == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as String?,riderId: freezed == riderId ? _self.riderId : riderId // ignore: cast_nullable_to_non_nullable
as String?,totalRepayment: null == totalRepayment ? _self.totalRepayment : totalRepayment // ignore: cast_nullable_to_non_nullable
as double,repaidAmount: null == repaidAmount ? _self.repaidAmount : repaidAmount // ignore: cast_nullable_to_non_nullable
as double,monthlyInstalment: null == monthlyInstalment ? _self.monthlyInstalment : monthlyInstalment // ignore: cast_nullable_to_non_nullable
as double,commissionRate: null == commissionRate ? _self.commissionRate : commissionRate // ignore: cast_nullable_to_non_nullable
as double,imageUrls: null == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
