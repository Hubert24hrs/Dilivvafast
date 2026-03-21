// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'promo_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PromoModel {

 String get id; String get code; DiscountType get discountType; double get amount; double get minOrderAmount;@TimestampConverter() DateTime get expiresAt; int get maxUses; int get usedCount; bool get isActive;@TimestampConverter() DateTime get createdAt;
/// Create a copy of PromoModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromoModelCopyWith<PromoModel> get copyWith => _$PromoModelCopyWithImpl<PromoModel>(this as PromoModel, _$identity);

  /// Serializes this PromoModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromoModel&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.discountType, discountType) || other.discountType == discountType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.minOrderAmount, minOrderAmount) || other.minOrderAmount == minOrderAmount)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.usedCount, usedCount) || other.usedCount == usedCount)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,discountType,amount,minOrderAmount,expiresAt,maxUses,usedCount,isActive,createdAt);

@override
String toString() {
  return 'PromoModel(id: $id, code: $code, discountType: $discountType, amount: $amount, minOrderAmount: $minOrderAmount, expiresAt: $expiresAt, maxUses: $maxUses, usedCount: $usedCount, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PromoModelCopyWith<$Res>  {
  factory $PromoModelCopyWith(PromoModel value, $Res Function(PromoModel) _then) = _$PromoModelCopyWithImpl;
@useResult
$Res call({
 String id, String code, DiscountType discountType, double amount, double minOrderAmount,@TimestampConverter() DateTime expiresAt, int maxUses, int usedCount, bool isActive,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$PromoModelCopyWithImpl<$Res>
    implements $PromoModelCopyWith<$Res> {
  _$PromoModelCopyWithImpl(this._self, this._then);

  final PromoModel _self;
  final $Res Function(PromoModel) _then;

/// Create a copy of PromoModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? discountType = null,Object? amount = null,Object? minOrderAmount = null,Object? expiresAt = null,Object? maxUses = null,Object? usedCount = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,discountType: null == discountType ? _self.discountType : discountType // ignore: cast_nullable_to_non_nullable
as DiscountType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,minOrderAmount: null == minOrderAmount ? _self.minOrderAmount : minOrderAmount // ignore: cast_nullable_to_non_nullable
as double,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,usedCount: null == usedCount ? _self.usedCount : usedCount // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PromoModel].
extension PromoModelPatterns on PromoModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PromoModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PromoModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PromoModel value)  $default,){
final _that = this;
switch (_that) {
case _PromoModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PromoModel value)?  $default,){
final _that = this;
switch (_that) {
case _PromoModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  DiscountType discountType,  double amount,  double minOrderAmount, @TimestampConverter()  DateTime expiresAt,  int maxUses,  int usedCount,  bool isActive, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PromoModel() when $default != null:
return $default(_that.id,_that.code,_that.discountType,_that.amount,_that.minOrderAmount,_that.expiresAt,_that.maxUses,_that.usedCount,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  DiscountType discountType,  double amount,  double minOrderAmount, @TimestampConverter()  DateTime expiresAt,  int maxUses,  int usedCount,  bool isActive, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _PromoModel():
return $default(_that.id,_that.code,_that.discountType,_that.amount,_that.minOrderAmount,_that.expiresAt,_that.maxUses,_that.usedCount,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  DiscountType discountType,  double amount,  double minOrderAmount, @TimestampConverter()  DateTime expiresAt,  int maxUses,  int usedCount,  bool isActive, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PromoModel() when $default != null:
return $default(_that.id,_that.code,_that.discountType,_that.amount,_that.minOrderAmount,_that.expiresAt,_that.maxUses,_that.usedCount,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PromoModel extends PromoModel {
  const _PromoModel({required this.id, required this.code, this.discountType = DiscountType.flat, required this.amount, this.minOrderAmount = 0.0, @TimestampConverter() required this.expiresAt, this.maxUses = 0, this.usedCount = 0, this.isActive = true, @TimestampConverter() required this.createdAt}): super._();
  factory _PromoModel.fromJson(Map<String, dynamic> json) => _$PromoModelFromJson(json);

@override final  String id;
@override final  String code;
@override@JsonKey() final  DiscountType discountType;
@override final  double amount;
@override@JsonKey() final  double minOrderAmount;
@override@TimestampConverter() final  DateTime expiresAt;
@override@JsonKey() final  int maxUses;
@override@JsonKey() final  int usedCount;
@override@JsonKey() final  bool isActive;
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of PromoModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromoModelCopyWith<_PromoModel> get copyWith => __$PromoModelCopyWithImpl<_PromoModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PromoModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromoModel&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.discountType, discountType) || other.discountType == discountType)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.minOrderAmount, minOrderAmount) || other.minOrderAmount == minOrderAmount)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.usedCount, usedCount) || other.usedCount == usedCount)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,discountType,amount,minOrderAmount,expiresAt,maxUses,usedCount,isActive,createdAt);

@override
String toString() {
  return 'PromoModel(id: $id, code: $code, discountType: $discountType, amount: $amount, minOrderAmount: $minOrderAmount, expiresAt: $expiresAt, maxUses: $maxUses, usedCount: $usedCount, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PromoModelCopyWith<$Res> implements $PromoModelCopyWith<$Res> {
  factory _$PromoModelCopyWith(_PromoModel value, $Res Function(_PromoModel) _then) = __$PromoModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, DiscountType discountType, double amount, double minOrderAmount,@TimestampConverter() DateTime expiresAt, int maxUses, int usedCount, bool isActive,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$PromoModelCopyWithImpl<$Res>
    implements _$PromoModelCopyWith<$Res> {
  __$PromoModelCopyWithImpl(this._self, this._then);

  final _PromoModel _self;
  final $Res Function(_PromoModel) _then;

/// Create a copy of PromoModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? discountType = null,Object? amount = null,Object? minOrderAmount = null,Object? expiresAt = null,Object? maxUses = null,Object? usedCount = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_PromoModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,discountType: null == discountType ? _self.discountType : discountType // ignore: cast_nullable_to_non_nullable
as DiscountType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,minOrderAmount: null == minOrderAmount ? _self.minOrderAmount : minOrderAmount // ignore: cast_nullable_to_non_nullable
as double,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,maxUses: null == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int,usedCount: null == usedCount ? _self.usedCount : usedCount // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
