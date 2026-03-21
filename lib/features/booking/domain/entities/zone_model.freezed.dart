// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'zone_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ZoneModel {

 String get id; String get name; String get city; double get baseFare; double get perKmRate; int get surgeThreshold; double get currentSurgeMultiplier;@GeoPointListConverter() List<GeoPoint> get polygonCoordinates; bool get isActive;@TimestampConverter() DateTime get createdAt;
/// Create a copy of ZoneModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ZoneModelCopyWith<ZoneModel> get copyWith => _$ZoneModelCopyWithImpl<ZoneModel>(this as ZoneModel, _$identity);

  /// Serializes this ZoneModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ZoneModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.baseFare, baseFare) || other.baseFare == baseFare)&&(identical(other.perKmRate, perKmRate) || other.perKmRate == perKmRate)&&(identical(other.surgeThreshold, surgeThreshold) || other.surgeThreshold == surgeThreshold)&&(identical(other.currentSurgeMultiplier, currentSurgeMultiplier) || other.currentSurgeMultiplier == currentSurgeMultiplier)&&const DeepCollectionEquality().equals(other.polygonCoordinates, polygonCoordinates)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,city,baseFare,perKmRate,surgeThreshold,currentSurgeMultiplier,const DeepCollectionEquality().hash(polygonCoordinates),isActive,createdAt);

@override
String toString() {
  return 'ZoneModel(id: $id, name: $name, city: $city, baseFare: $baseFare, perKmRate: $perKmRate, surgeThreshold: $surgeThreshold, currentSurgeMultiplier: $currentSurgeMultiplier, polygonCoordinates: $polygonCoordinates, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ZoneModelCopyWith<$Res>  {
  factory $ZoneModelCopyWith(ZoneModel value, $Res Function(ZoneModel) _then) = _$ZoneModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String city, double baseFare, double perKmRate, int surgeThreshold, double currentSurgeMultiplier,@GeoPointListConverter() List<GeoPoint> polygonCoordinates, bool isActive,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$ZoneModelCopyWithImpl<$Res>
    implements $ZoneModelCopyWith<$Res> {
  _$ZoneModelCopyWithImpl(this._self, this._then);

  final ZoneModel _self;
  final $Res Function(ZoneModel) _then;

/// Create a copy of ZoneModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? city = null,Object? baseFare = null,Object? perKmRate = null,Object? surgeThreshold = null,Object? currentSurgeMultiplier = null,Object? polygonCoordinates = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,baseFare: null == baseFare ? _self.baseFare : baseFare // ignore: cast_nullable_to_non_nullable
as double,perKmRate: null == perKmRate ? _self.perKmRate : perKmRate // ignore: cast_nullable_to_non_nullable
as double,surgeThreshold: null == surgeThreshold ? _self.surgeThreshold : surgeThreshold // ignore: cast_nullable_to_non_nullable
as int,currentSurgeMultiplier: null == currentSurgeMultiplier ? _self.currentSurgeMultiplier : currentSurgeMultiplier // ignore: cast_nullable_to_non_nullable
as double,polygonCoordinates: null == polygonCoordinates ? _self.polygonCoordinates : polygonCoordinates // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ZoneModel].
extension ZoneModelPatterns on ZoneModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ZoneModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ZoneModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ZoneModel value)  $default,){
final _that = this;
switch (_that) {
case _ZoneModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ZoneModel value)?  $default,){
final _that = this;
switch (_that) {
case _ZoneModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String city,  double baseFare,  double perKmRate,  int surgeThreshold,  double currentSurgeMultiplier, @GeoPointListConverter()  List<GeoPoint> polygonCoordinates,  bool isActive, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ZoneModel() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.baseFare,_that.perKmRate,_that.surgeThreshold,_that.currentSurgeMultiplier,_that.polygonCoordinates,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String city,  double baseFare,  double perKmRate,  int surgeThreshold,  double currentSurgeMultiplier, @GeoPointListConverter()  List<GeoPoint> polygonCoordinates,  bool isActive, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ZoneModel():
return $default(_that.id,_that.name,_that.city,_that.baseFare,_that.perKmRate,_that.surgeThreshold,_that.currentSurgeMultiplier,_that.polygonCoordinates,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String city,  double baseFare,  double perKmRate,  int surgeThreshold,  double currentSurgeMultiplier, @GeoPointListConverter()  List<GeoPoint> polygonCoordinates,  bool isActive, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ZoneModel() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.baseFare,_that.perKmRate,_that.surgeThreshold,_that.currentSurgeMultiplier,_that.polygonCoordinates,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ZoneModel extends ZoneModel {
  const _ZoneModel({required this.id, required this.name, required this.city, this.baseFare = 0.0, this.perKmRate = 0.0, this.surgeThreshold = 5, this.currentSurgeMultiplier = 1.0, @GeoPointListConverter() final  List<GeoPoint> polygonCoordinates = const [], this.isActive = true, @TimestampConverter() required this.createdAt}): _polygonCoordinates = polygonCoordinates,super._();
  factory _ZoneModel.fromJson(Map<String, dynamic> json) => _$ZoneModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String city;
@override@JsonKey() final  double baseFare;
@override@JsonKey() final  double perKmRate;
@override@JsonKey() final  int surgeThreshold;
@override@JsonKey() final  double currentSurgeMultiplier;
 final  List<GeoPoint> _polygonCoordinates;
@override@JsonKey()@GeoPointListConverter() List<GeoPoint> get polygonCoordinates {
  if (_polygonCoordinates is EqualUnmodifiableListView) return _polygonCoordinates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_polygonCoordinates);
}

@override@JsonKey() final  bool isActive;
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of ZoneModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ZoneModelCopyWith<_ZoneModel> get copyWith => __$ZoneModelCopyWithImpl<_ZoneModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ZoneModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ZoneModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.baseFare, baseFare) || other.baseFare == baseFare)&&(identical(other.perKmRate, perKmRate) || other.perKmRate == perKmRate)&&(identical(other.surgeThreshold, surgeThreshold) || other.surgeThreshold == surgeThreshold)&&(identical(other.currentSurgeMultiplier, currentSurgeMultiplier) || other.currentSurgeMultiplier == currentSurgeMultiplier)&&const DeepCollectionEquality().equals(other._polygonCoordinates, _polygonCoordinates)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,city,baseFare,perKmRate,surgeThreshold,currentSurgeMultiplier,const DeepCollectionEquality().hash(_polygonCoordinates),isActive,createdAt);

@override
String toString() {
  return 'ZoneModel(id: $id, name: $name, city: $city, baseFare: $baseFare, perKmRate: $perKmRate, surgeThreshold: $surgeThreshold, currentSurgeMultiplier: $currentSurgeMultiplier, polygonCoordinates: $polygonCoordinates, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ZoneModelCopyWith<$Res> implements $ZoneModelCopyWith<$Res> {
  factory _$ZoneModelCopyWith(_ZoneModel value, $Res Function(_ZoneModel) _then) = __$ZoneModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String city, double baseFare, double perKmRate, int surgeThreshold, double currentSurgeMultiplier,@GeoPointListConverter() List<GeoPoint> polygonCoordinates, bool isActive,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$ZoneModelCopyWithImpl<$Res>
    implements _$ZoneModelCopyWith<$Res> {
  __$ZoneModelCopyWithImpl(this._self, this._then);

  final _ZoneModel _self;
  final $Res Function(_ZoneModel) _then;

/// Create a copy of ZoneModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? city = null,Object? baseFare = null,Object? perKmRate = null,Object? surgeThreshold = null,Object? currentSurgeMultiplier = null,Object? polygonCoordinates = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_ZoneModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,baseFare: null == baseFare ? _self.baseFare : baseFare // ignore: cast_nullable_to_non_nullable
as double,perKmRate: null == perKmRate ? _self.perKmRate : perKmRate // ignore: cast_nullable_to_non_nullable
as double,surgeThreshold: null == surgeThreshold ? _self.surgeThreshold : surgeThreshold // ignore: cast_nullable_to_non_nullable
as int,currentSurgeMultiplier: null == currentSurgeMultiplier ? _self.currentSurgeMultiplier : currentSurgeMultiplier // ignore: cast_nullable_to_non_nullable
as double,polygonCoordinates: null == polygonCoordinates ? _self._polygonCoordinates : polygonCoordinates // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
