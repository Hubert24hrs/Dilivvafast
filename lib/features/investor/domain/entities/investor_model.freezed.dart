// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investor_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvestorModel {

 String get id; String get userId; double get totalInvested; double get totalEarned; int get activeBikes; double get pendingWithdrawal;@TimestampConverter() DateTime get createdAt;
/// Create a copy of InvestorModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorModelCopyWith<InvestorModel> get copyWith => _$InvestorModelCopyWithImpl<InvestorModel>(this as InvestorModel, _$identity);

  /// Serializes this InvestorModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.totalInvested, totalInvested) || other.totalInvested == totalInvested)&&(identical(other.totalEarned, totalEarned) || other.totalEarned == totalEarned)&&(identical(other.activeBikes, activeBikes) || other.activeBikes == activeBikes)&&(identical(other.pendingWithdrawal, pendingWithdrawal) || other.pendingWithdrawal == pendingWithdrawal)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,totalInvested,totalEarned,activeBikes,pendingWithdrawal,createdAt);

@override
String toString() {
  return 'InvestorModel(id: $id, userId: $userId, totalInvested: $totalInvested, totalEarned: $totalEarned, activeBikes: $activeBikes, pendingWithdrawal: $pendingWithdrawal, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $InvestorModelCopyWith<$Res>  {
  factory $InvestorModelCopyWith(InvestorModel value, $Res Function(InvestorModel) _then) = _$InvestorModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, double totalInvested, double totalEarned, int activeBikes, double pendingWithdrawal,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$InvestorModelCopyWithImpl<$Res>
    implements $InvestorModelCopyWith<$Res> {
  _$InvestorModelCopyWithImpl(this._self, this._then);

  final InvestorModel _self;
  final $Res Function(InvestorModel) _then;

/// Create a copy of InvestorModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? totalInvested = null,Object? totalEarned = null,Object? activeBikes = null,Object? pendingWithdrawal = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,totalInvested: null == totalInvested ? _self.totalInvested : totalInvested // ignore: cast_nullable_to_non_nullable
as double,totalEarned: null == totalEarned ? _self.totalEarned : totalEarned // ignore: cast_nullable_to_non_nullable
as double,activeBikes: null == activeBikes ? _self.activeBikes : activeBikes // ignore: cast_nullable_to_non_nullable
as int,pendingWithdrawal: null == pendingWithdrawal ? _self.pendingWithdrawal : pendingWithdrawal // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [InvestorModel].
extension InvestorModelPatterns on InvestorModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestorModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestorModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestorModel value)  $default,){
final _that = this;
switch (_that) {
case _InvestorModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestorModel value)?  $default,){
final _that = this;
switch (_that) {
case _InvestorModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  double totalInvested,  double totalEarned,  int activeBikes,  double pendingWithdrawal, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestorModel() when $default != null:
return $default(_that.id,_that.userId,_that.totalInvested,_that.totalEarned,_that.activeBikes,_that.pendingWithdrawal,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  double totalInvested,  double totalEarned,  int activeBikes,  double pendingWithdrawal, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _InvestorModel():
return $default(_that.id,_that.userId,_that.totalInvested,_that.totalEarned,_that.activeBikes,_that.pendingWithdrawal,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  double totalInvested,  double totalEarned,  int activeBikes,  double pendingWithdrawal, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _InvestorModel() when $default != null:
return $default(_that.id,_that.userId,_that.totalInvested,_that.totalEarned,_that.activeBikes,_that.pendingWithdrawal,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestorModel extends InvestorModel {
  const _InvestorModel({required this.id, required this.userId, this.totalInvested = 0.0, this.totalEarned = 0.0, this.activeBikes = 0, this.pendingWithdrawal = 0.0, @TimestampConverter() required this.createdAt}): super._();
  factory _InvestorModel.fromJson(Map<String, dynamic> json) => _$InvestorModelFromJson(json);

@override final  String id;
@override final  String userId;
@override@JsonKey() final  double totalInvested;
@override@JsonKey() final  double totalEarned;
@override@JsonKey() final  int activeBikes;
@override@JsonKey() final  double pendingWithdrawal;
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of InvestorModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestorModelCopyWith<_InvestorModel> get copyWith => __$InvestorModelCopyWithImpl<_InvestorModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestorModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.totalInvested, totalInvested) || other.totalInvested == totalInvested)&&(identical(other.totalEarned, totalEarned) || other.totalEarned == totalEarned)&&(identical(other.activeBikes, activeBikes) || other.activeBikes == activeBikes)&&(identical(other.pendingWithdrawal, pendingWithdrawal) || other.pendingWithdrawal == pendingWithdrawal)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,totalInvested,totalEarned,activeBikes,pendingWithdrawal,createdAt);

@override
String toString() {
  return 'InvestorModel(id: $id, userId: $userId, totalInvested: $totalInvested, totalEarned: $totalEarned, activeBikes: $activeBikes, pendingWithdrawal: $pendingWithdrawal, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InvestorModelCopyWith<$Res> implements $InvestorModelCopyWith<$Res> {
  factory _$InvestorModelCopyWith(_InvestorModel value, $Res Function(_InvestorModel) _then) = __$InvestorModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, double totalInvested, double totalEarned, int activeBikes, double pendingWithdrawal,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$InvestorModelCopyWithImpl<$Res>
    implements _$InvestorModelCopyWith<$Res> {
  __$InvestorModelCopyWithImpl(this._self, this._then);

  final _InvestorModel _self;
  final $Res Function(_InvestorModel) _then;

/// Create a copy of InvestorModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? totalInvested = null,Object? totalEarned = null,Object? activeBikes = null,Object? pendingWithdrawal = null,Object? createdAt = null,}) {
  return _then(_InvestorModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,totalInvested: null == totalInvested ? _self.totalInvested : totalInvested // ignore: cast_nullable_to_non_nullable
as double,totalEarned: null == totalEarned ? _self.totalEarned : totalEarned // ignore: cast_nullable_to_non_nullable
as double,activeBikes: null == activeBikes ? _self.activeBikes : activeBikes // ignore: cast_nullable_to_non_nullable
as int,pendingWithdrawal: null == pendingWithdrawal ? _self.pendingWithdrawal : pendingWithdrawal // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
