// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hp_agreement_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HPAgreementModel {

 String get id; String get bikeId; String get investorId; String get riderId; double get totalRepayment; double get repaidAmount; double get monthlyInstalment; AgreementStatus get status;@TimestampConverter() DateTime get startDate;@TimestampConverter() DateTime get endDate;@TimestampConverter() DateTime get createdAt;
/// Create a copy of HPAgreementModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HPAgreementModelCopyWith<HPAgreementModel> get copyWith => _$HPAgreementModelCopyWithImpl<HPAgreementModel>(this as HPAgreementModel, _$identity);

  /// Serializes this HPAgreementModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HPAgreementModel&&(identical(other.id, id) || other.id == id)&&(identical(other.bikeId, bikeId) || other.bikeId == bikeId)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.riderId, riderId) || other.riderId == riderId)&&(identical(other.totalRepayment, totalRepayment) || other.totalRepayment == totalRepayment)&&(identical(other.repaidAmount, repaidAmount) || other.repaidAmount == repaidAmount)&&(identical(other.monthlyInstalment, monthlyInstalment) || other.monthlyInstalment == monthlyInstalment)&&(identical(other.status, status) || other.status == status)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bikeId,investorId,riderId,totalRepayment,repaidAmount,monthlyInstalment,status,startDate,endDate,createdAt);

@override
String toString() {
  return 'HPAgreementModel(id: $id, bikeId: $bikeId, investorId: $investorId, riderId: $riderId, totalRepayment: $totalRepayment, repaidAmount: $repaidAmount, monthlyInstalment: $monthlyInstalment, status: $status, startDate: $startDate, endDate: $endDate, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $HPAgreementModelCopyWith<$Res>  {
  factory $HPAgreementModelCopyWith(HPAgreementModel value, $Res Function(HPAgreementModel) _then) = _$HPAgreementModelCopyWithImpl;
@useResult
$Res call({
 String id, String bikeId, String investorId, String riderId, double totalRepayment, double repaidAmount, double monthlyInstalment, AgreementStatus status,@TimestampConverter() DateTime startDate,@TimestampConverter() DateTime endDate,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$HPAgreementModelCopyWithImpl<$Res>
    implements $HPAgreementModelCopyWith<$Res> {
  _$HPAgreementModelCopyWithImpl(this._self, this._then);

  final HPAgreementModel _self;
  final $Res Function(HPAgreementModel) _then;

/// Create a copy of HPAgreementModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bikeId = null,Object? investorId = null,Object? riderId = null,Object? totalRepayment = null,Object? repaidAmount = null,Object? monthlyInstalment = null,Object? status = null,Object? startDate = null,Object? endDate = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bikeId: null == bikeId ? _self.bikeId : bikeId // ignore: cast_nullable_to_non_nullable
as String,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as String,riderId: null == riderId ? _self.riderId : riderId // ignore: cast_nullable_to_non_nullable
as String,totalRepayment: null == totalRepayment ? _self.totalRepayment : totalRepayment // ignore: cast_nullable_to_non_nullable
as double,repaidAmount: null == repaidAmount ? _self.repaidAmount : repaidAmount // ignore: cast_nullable_to_non_nullable
as double,monthlyInstalment: null == monthlyInstalment ? _self.monthlyInstalment : monthlyInstalment // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AgreementStatus,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [HPAgreementModel].
extension HPAgreementModelPatterns on HPAgreementModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HPAgreementModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HPAgreementModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HPAgreementModel value)  $default,){
final _that = this;
switch (_that) {
case _HPAgreementModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HPAgreementModel value)?  $default,){
final _that = this;
switch (_that) {
case _HPAgreementModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String bikeId,  String investorId,  String riderId,  double totalRepayment,  double repaidAmount,  double monthlyInstalment,  AgreementStatus status, @TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HPAgreementModel() when $default != null:
return $default(_that.id,_that.bikeId,_that.investorId,_that.riderId,_that.totalRepayment,_that.repaidAmount,_that.monthlyInstalment,_that.status,_that.startDate,_that.endDate,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String bikeId,  String investorId,  String riderId,  double totalRepayment,  double repaidAmount,  double monthlyInstalment,  AgreementStatus status, @TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _HPAgreementModel():
return $default(_that.id,_that.bikeId,_that.investorId,_that.riderId,_that.totalRepayment,_that.repaidAmount,_that.monthlyInstalment,_that.status,_that.startDate,_that.endDate,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String bikeId,  String investorId,  String riderId,  double totalRepayment,  double repaidAmount,  double monthlyInstalment,  AgreementStatus status, @TimestampConverter()  DateTime startDate, @TimestampConverter()  DateTime endDate, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _HPAgreementModel() when $default != null:
return $default(_that.id,_that.bikeId,_that.investorId,_that.riderId,_that.totalRepayment,_that.repaidAmount,_that.monthlyInstalment,_that.status,_that.startDate,_that.endDate,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HPAgreementModel extends HPAgreementModel {
  const _HPAgreementModel({required this.id, required this.bikeId, required this.investorId, required this.riderId, required this.totalRepayment, this.repaidAmount = 0.0, required this.monthlyInstalment, this.status = AgreementStatus.active, @TimestampConverter() required this.startDate, @TimestampConverter() required this.endDate, @TimestampConverter() required this.createdAt}): super._();
  factory _HPAgreementModel.fromJson(Map<String, dynamic> json) => _$HPAgreementModelFromJson(json);

@override final  String id;
@override final  String bikeId;
@override final  String investorId;
@override final  String riderId;
@override final  double totalRepayment;
@override@JsonKey() final  double repaidAmount;
@override final  double monthlyInstalment;
@override@JsonKey() final  AgreementStatus status;
@override@TimestampConverter() final  DateTime startDate;
@override@TimestampConverter() final  DateTime endDate;
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of HPAgreementModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HPAgreementModelCopyWith<_HPAgreementModel> get copyWith => __$HPAgreementModelCopyWithImpl<_HPAgreementModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HPAgreementModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HPAgreementModel&&(identical(other.id, id) || other.id == id)&&(identical(other.bikeId, bikeId) || other.bikeId == bikeId)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.riderId, riderId) || other.riderId == riderId)&&(identical(other.totalRepayment, totalRepayment) || other.totalRepayment == totalRepayment)&&(identical(other.repaidAmount, repaidAmount) || other.repaidAmount == repaidAmount)&&(identical(other.monthlyInstalment, monthlyInstalment) || other.monthlyInstalment == monthlyInstalment)&&(identical(other.status, status) || other.status == status)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bikeId,investorId,riderId,totalRepayment,repaidAmount,monthlyInstalment,status,startDate,endDate,createdAt);

@override
String toString() {
  return 'HPAgreementModel(id: $id, bikeId: $bikeId, investorId: $investorId, riderId: $riderId, totalRepayment: $totalRepayment, repaidAmount: $repaidAmount, monthlyInstalment: $monthlyInstalment, status: $status, startDate: $startDate, endDate: $endDate, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HPAgreementModelCopyWith<$Res> implements $HPAgreementModelCopyWith<$Res> {
  factory _$HPAgreementModelCopyWith(_HPAgreementModel value, $Res Function(_HPAgreementModel) _then) = __$HPAgreementModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String bikeId, String investorId, String riderId, double totalRepayment, double repaidAmount, double monthlyInstalment, AgreementStatus status,@TimestampConverter() DateTime startDate,@TimestampConverter() DateTime endDate,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$HPAgreementModelCopyWithImpl<$Res>
    implements _$HPAgreementModelCopyWith<$Res> {
  __$HPAgreementModelCopyWithImpl(this._self, this._then);

  final _HPAgreementModel _self;
  final $Res Function(_HPAgreementModel) _then;

/// Create a copy of HPAgreementModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bikeId = null,Object? investorId = null,Object? riderId = null,Object? totalRepayment = null,Object? repaidAmount = null,Object? monthlyInstalment = null,Object? status = null,Object? startDate = null,Object? endDate = null,Object? createdAt = null,}) {
  return _then(_HPAgreementModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bikeId: null == bikeId ? _self.bikeId : bikeId // ignore: cast_nullable_to_non_nullable
as String,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as String,riderId: null == riderId ? _self.riderId : riderId // ignore: cast_nullable_to_non_nullable
as String,totalRepayment: null == totalRepayment ? _self.totalRepayment : totalRepayment // ignore: cast_nullable_to_non_nullable
as double,repaidAmount: null == repaidAmount ? _self.repaidAmount : repaidAmount // ignore: cast_nullable_to_non_nullable
as double,monthlyInstalment: null == monthlyInstalment ? _self.monthlyInstalment : monthlyInstalment // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AgreementStatus,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
