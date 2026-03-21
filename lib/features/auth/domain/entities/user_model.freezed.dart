// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

 String get uid; String get fullName; String get email; String get phone; String? get photoUrl; UserRole get role; bool get isVerified; bool get isOnline; double get walletBalance; String get referralCode; String? get referredBy; String? get fcmToken; double get rating; int get totalDeliveries;@TimestampConverter() DateTime get createdAt;@TimestampConverter() DateTime get updatedAt;@NullableGeoPointConverter() GeoPoint? get location; String? get address;// Driver-only fields
 String? get bvn; String? get vehicleType; String? get vehiclePlate; String? get licenseUrl; bool get isAvailable;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.role, role) || other.role == role)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.referralCode, referralCode) || other.referralCode == referralCode)&&(identical(other.referredBy, referredBy) || other.referredBy == referredBy)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.totalDeliveries, totalDeliveries) || other.totalDeliveries == totalDeliveries)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.location, location) || other.location == location)&&(identical(other.address, address) || other.address == address)&&(identical(other.bvn, bvn) || other.bvn == bvn)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.licenseUrl, licenseUrl) || other.licenseUrl == licenseUrl)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,uid,fullName,email,phone,photoUrl,role,isVerified,isOnline,walletBalance,referralCode,referredBy,fcmToken,rating,totalDeliveries,createdAt,updatedAt,location,address,bvn,vehicleType,vehiclePlate,licenseUrl,isAvailable]);

@override
String toString() {
  return 'UserModel(uid: $uid, fullName: $fullName, email: $email, phone: $phone, photoUrl: $photoUrl, role: $role, isVerified: $isVerified, isOnline: $isOnline, walletBalance: $walletBalance, referralCode: $referralCode, referredBy: $referredBy, fcmToken: $fcmToken, rating: $rating, totalDeliveries: $totalDeliveries, createdAt: $createdAt, updatedAt: $updatedAt, location: $location, address: $address, bvn: $bvn, vehicleType: $vehicleType, vehiclePlate: $vehiclePlate, licenseUrl: $licenseUrl, isAvailable: $isAvailable)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 String uid, String fullName, String email, String phone, String? photoUrl, UserRole role, bool isVerified, bool isOnline, double walletBalance, String referralCode, String? referredBy, String? fcmToken, double rating, int totalDeliveries,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt,@NullableGeoPointConverter() GeoPoint? location, String? address, String? bvn, String? vehicleType, String? vehiclePlate, String? licenseUrl, bool isAvailable
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? fullName = null,Object? email = null,Object? phone = null,Object? photoUrl = freezed,Object? role = null,Object? isVerified = null,Object? isOnline = null,Object? walletBalance = null,Object? referralCode = null,Object? referredBy = freezed,Object? fcmToken = freezed,Object? rating = null,Object? totalDeliveries = null,Object? createdAt = null,Object? updatedAt = null,Object? location = freezed,Object? address = freezed,Object? bvn = freezed,Object? vehicleType = freezed,Object? vehiclePlate = freezed,Object? licenseUrl = freezed,Object? isAvailable = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as double,referralCode: null == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String,referredBy: freezed == referredBy ? _self.referredBy : referredBy // ignore: cast_nullable_to_non_nullable
as String?,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,totalDeliveries: null == totalDeliveries ? _self.totalDeliveries : totalDeliveries // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,bvn: freezed == bvn ? _self.bvn : bvn // ignore: cast_nullable_to_non_nullable
as String?,vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String?,vehiclePlate: freezed == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String?,licenseUrl: freezed == licenseUrl ? _self.licenseUrl : licenseUrl // ignore: cast_nullable_to_non_nullable
as String?,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String fullName,  String email,  String phone,  String? photoUrl,  UserRole role,  bool isVerified,  bool isOnline,  double walletBalance,  String referralCode,  String? referredBy,  String? fcmToken,  double rating,  int totalDeliveries, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableGeoPointConverter()  GeoPoint? location,  String? address,  String? bvn,  String? vehicleType,  String? vehiclePlate,  String? licenseUrl,  bool isAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.uid,_that.fullName,_that.email,_that.phone,_that.photoUrl,_that.role,_that.isVerified,_that.isOnline,_that.walletBalance,_that.referralCode,_that.referredBy,_that.fcmToken,_that.rating,_that.totalDeliveries,_that.createdAt,_that.updatedAt,_that.location,_that.address,_that.bvn,_that.vehicleType,_that.vehiclePlate,_that.licenseUrl,_that.isAvailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String fullName,  String email,  String phone,  String? photoUrl,  UserRole role,  bool isVerified,  bool isOnline,  double walletBalance,  String referralCode,  String? referredBy,  String? fcmToken,  double rating,  int totalDeliveries, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableGeoPointConverter()  GeoPoint? location,  String? address,  String? bvn,  String? vehicleType,  String? vehiclePlate,  String? licenseUrl,  bool isAvailable)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.uid,_that.fullName,_that.email,_that.phone,_that.photoUrl,_that.role,_that.isVerified,_that.isOnline,_that.walletBalance,_that.referralCode,_that.referredBy,_that.fcmToken,_that.rating,_that.totalDeliveries,_that.createdAt,_that.updatedAt,_that.location,_that.address,_that.bvn,_that.vehicleType,_that.vehiclePlate,_that.licenseUrl,_that.isAvailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String fullName,  String email,  String phone,  String? photoUrl,  UserRole role,  bool isVerified,  bool isOnline,  double walletBalance,  String referralCode,  String? referredBy,  String? fcmToken,  double rating,  int totalDeliveries, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt, @NullableGeoPointConverter()  GeoPoint? location,  String? address,  String? bvn,  String? vehicleType,  String? vehiclePlate,  String? licenseUrl,  bool isAvailable)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.uid,_that.fullName,_that.email,_that.phone,_that.photoUrl,_that.role,_that.isVerified,_that.isOnline,_that.walletBalance,_that.referralCode,_that.referredBy,_that.fcmToken,_that.rating,_that.totalDeliveries,_that.createdAt,_that.updatedAt,_that.location,_that.address,_that.bvn,_that.vehicleType,_that.vehiclePlate,_that.licenseUrl,_that.isAvailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserModel extends UserModel {
  const _UserModel({required this.uid, required this.fullName, required this.email, required this.phone, this.photoUrl, this.role = UserRole.customer, this.isVerified = false, this.isOnline = false, this.walletBalance = 0.0, required this.referralCode, this.referredBy, this.fcmToken, this.rating = 0.0, this.totalDeliveries = 0, @TimestampConverter() required this.createdAt, @TimestampConverter() required this.updatedAt, @NullableGeoPointConverter() this.location, this.address, this.bvn, this.vehicleType, this.vehiclePlate, this.licenseUrl, this.isAvailable = true}): super._();
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override final  String uid;
@override final  String fullName;
@override final  String email;
@override final  String phone;
@override final  String? photoUrl;
@override@JsonKey() final  UserRole role;
@override@JsonKey() final  bool isVerified;
@override@JsonKey() final  bool isOnline;
@override@JsonKey() final  double walletBalance;
@override final  String referralCode;
@override final  String? referredBy;
@override final  String? fcmToken;
@override@JsonKey() final  double rating;
@override@JsonKey() final  int totalDeliveries;
@override@TimestampConverter() final  DateTime createdAt;
@override@TimestampConverter() final  DateTime updatedAt;
@override@NullableGeoPointConverter() final  GeoPoint? location;
@override final  String? address;
// Driver-only fields
@override final  String? bvn;
@override final  String? vehicleType;
@override final  String? vehiclePlate;
@override final  String? licenseUrl;
@override@JsonKey() final  bool isAvailable;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.role, role) || other.role == role)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.referralCode, referralCode) || other.referralCode == referralCode)&&(identical(other.referredBy, referredBy) || other.referredBy == referredBy)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.totalDeliveries, totalDeliveries) || other.totalDeliveries == totalDeliveries)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.location, location) || other.location == location)&&(identical(other.address, address) || other.address == address)&&(identical(other.bvn, bvn) || other.bvn == bvn)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.licenseUrl, licenseUrl) || other.licenseUrl == licenseUrl)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,uid,fullName,email,phone,photoUrl,role,isVerified,isOnline,walletBalance,referralCode,referredBy,fcmToken,rating,totalDeliveries,createdAt,updatedAt,location,address,bvn,vehicleType,vehiclePlate,licenseUrl,isAvailable]);

@override
String toString() {
  return 'UserModel(uid: $uid, fullName: $fullName, email: $email, phone: $phone, photoUrl: $photoUrl, role: $role, isVerified: $isVerified, isOnline: $isOnline, walletBalance: $walletBalance, referralCode: $referralCode, referredBy: $referredBy, fcmToken: $fcmToken, rating: $rating, totalDeliveries: $totalDeliveries, createdAt: $createdAt, updatedAt: $updatedAt, location: $location, address: $address, bvn: $bvn, vehicleType: $vehicleType, vehiclePlate: $vehiclePlate, licenseUrl: $licenseUrl, isAvailable: $isAvailable)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 String uid, String fullName, String email, String phone, String? photoUrl, UserRole role, bool isVerified, bool isOnline, double walletBalance, String referralCode, String? referredBy, String? fcmToken, double rating, int totalDeliveries,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt,@NullableGeoPointConverter() GeoPoint? location, String? address, String? bvn, String? vehicleType, String? vehiclePlate, String? licenseUrl, bool isAvailable
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? fullName = null,Object? email = null,Object? phone = null,Object? photoUrl = freezed,Object? role = null,Object? isVerified = null,Object? isOnline = null,Object? walletBalance = null,Object? referralCode = null,Object? referredBy = freezed,Object? fcmToken = freezed,Object? rating = null,Object? totalDeliveries = null,Object? createdAt = null,Object? updatedAt = null,Object? location = freezed,Object? address = freezed,Object? bvn = freezed,Object? vehicleType = freezed,Object? vehiclePlate = freezed,Object? licenseUrl = freezed,Object? isAvailable = null,}) {
  return _then(_UserModel(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as double,referralCode: null == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String,referredBy: freezed == referredBy ? _self.referredBy : referredBy // ignore: cast_nullable_to_non_nullable
as String?,fcmToken: freezed == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,totalDeliveries: null == totalDeliveries ? _self.totalDeliveries : totalDeliveries // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as GeoPoint?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,bvn: freezed == bvn ? _self.bvn : bvn // ignore: cast_nullable_to_non_nullable
as String?,vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String?,vehiclePlate: freezed == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String?,licenseUrl: freezed == licenseUrl ? _self.licenseUrl : licenseUrl // ignore: cast_nullable_to_non_nullable
as String?,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
