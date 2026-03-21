// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_application_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DriverApplicationModel {

 String get id; String get userId; String get fullName; String get email; String get phone; String get vehicleType; String get vehiclePlate; String? get licenseUrl; String? get vehiclePhotoUrl; String? get governmentIdUrl; String? get bankName; String? get accountNumber; String? get accountName; ApplicationStatus get status; String? get rejectionReason;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get reviewedAt;
/// Create a copy of DriverApplicationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverApplicationModelCopyWith<DriverApplicationModel> get copyWith => _$DriverApplicationModelCopyWithImpl<DriverApplicationModel>(this as DriverApplicationModel, _$identity);

  /// Serializes this DriverApplicationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverApplicationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.licenseUrl, licenseUrl) || other.licenseUrl == licenseUrl)&&(identical(other.vehiclePhotoUrl, vehiclePhotoUrl) || other.vehiclePhotoUrl == vehiclePhotoUrl)&&(identical(other.governmentIdUrl, governmentIdUrl) || other.governmentIdUrl == governmentIdUrl)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,fullName,email,phone,vehicleType,vehiclePlate,licenseUrl,vehiclePhotoUrl,governmentIdUrl,bankName,accountNumber,accountName,status,rejectionReason,createdAt,reviewedAt);

@override
String toString() {
  return 'DriverApplicationModel(id: $id, userId: $userId, fullName: $fullName, email: $email, phone: $phone, vehicleType: $vehicleType, vehiclePlate: $vehiclePlate, licenseUrl: $licenseUrl, vehiclePhotoUrl: $vehiclePhotoUrl, governmentIdUrl: $governmentIdUrl, bankName: $bankName, accountNumber: $accountNumber, accountName: $accountName, status: $status, rejectionReason: $rejectionReason, createdAt: $createdAt, reviewedAt: $reviewedAt)';
}


}

/// @nodoc
abstract mixin class $DriverApplicationModelCopyWith<$Res>  {
  factory $DriverApplicationModelCopyWith(DriverApplicationModel value, $Res Function(DriverApplicationModel) _then) = _$DriverApplicationModelCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String fullName, String email, String phone, String vehicleType, String vehiclePlate, String? licenseUrl, String? vehiclePhotoUrl, String? governmentIdUrl, String? bankName, String? accountNumber, String? accountName, ApplicationStatus status, String? rejectionReason,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? reviewedAt
});




}
/// @nodoc
class _$DriverApplicationModelCopyWithImpl<$Res>
    implements $DriverApplicationModelCopyWith<$Res> {
  _$DriverApplicationModelCopyWithImpl(this._self, this._then);

  final DriverApplicationModel _self;
  final $Res Function(DriverApplicationModel) _then;

/// Create a copy of DriverApplicationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? fullName = null,Object? email = null,Object? phone = null,Object? vehicleType = null,Object? vehiclePlate = null,Object? licenseUrl = freezed,Object? vehiclePhotoUrl = freezed,Object? governmentIdUrl = freezed,Object? bankName = freezed,Object? accountNumber = freezed,Object? accountName = freezed,Object? status = null,Object? rejectionReason = freezed,Object? createdAt = null,Object? reviewedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,licenseUrl: freezed == licenseUrl ? _self.licenseUrl : licenseUrl // ignore: cast_nullable_to_non_nullable
as String?,vehiclePhotoUrl: freezed == vehiclePhotoUrl ? _self.vehiclePhotoUrl : vehiclePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,governmentIdUrl: freezed == governmentIdUrl ? _self.governmentIdUrl : governmentIdUrl // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,accountNumber: freezed == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String?,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ApplicationStatus,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DriverApplicationModel].
extension DriverApplicationModelPatterns on DriverApplicationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverApplicationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverApplicationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverApplicationModel value)  $default,){
final _that = this;
switch (_that) {
case _DriverApplicationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverApplicationModel value)?  $default,){
final _that = this;
switch (_that) {
case _DriverApplicationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String fullName,  String email,  String phone,  String vehicleType,  String vehiclePlate,  String? licenseUrl,  String? vehiclePhotoUrl,  String? governmentIdUrl,  String? bankName,  String? accountNumber,  String? accountName,  ApplicationStatus status,  String? rejectionReason, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? reviewedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverApplicationModel() when $default != null:
return $default(_that.id,_that.userId,_that.fullName,_that.email,_that.phone,_that.vehicleType,_that.vehiclePlate,_that.licenseUrl,_that.vehiclePhotoUrl,_that.governmentIdUrl,_that.bankName,_that.accountNumber,_that.accountName,_that.status,_that.rejectionReason,_that.createdAt,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String fullName,  String email,  String phone,  String vehicleType,  String vehiclePlate,  String? licenseUrl,  String? vehiclePhotoUrl,  String? governmentIdUrl,  String? bankName,  String? accountNumber,  String? accountName,  ApplicationStatus status,  String? rejectionReason, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? reviewedAt)  $default,) {final _that = this;
switch (_that) {
case _DriverApplicationModel():
return $default(_that.id,_that.userId,_that.fullName,_that.email,_that.phone,_that.vehicleType,_that.vehiclePlate,_that.licenseUrl,_that.vehiclePhotoUrl,_that.governmentIdUrl,_that.bankName,_that.accountNumber,_that.accountName,_that.status,_that.rejectionReason,_that.createdAt,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String fullName,  String email,  String phone,  String vehicleType,  String vehiclePlate,  String? licenseUrl,  String? vehiclePhotoUrl,  String? governmentIdUrl,  String? bankName,  String? accountNumber,  String? accountName,  ApplicationStatus status,  String? rejectionReason, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? reviewedAt)?  $default,) {final _that = this;
switch (_that) {
case _DriverApplicationModel() when $default != null:
return $default(_that.id,_that.userId,_that.fullName,_that.email,_that.phone,_that.vehicleType,_that.vehiclePlate,_that.licenseUrl,_that.vehiclePhotoUrl,_that.governmentIdUrl,_that.bankName,_that.accountNumber,_that.accountName,_that.status,_that.rejectionReason,_that.createdAt,_that.reviewedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverApplicationModel extends DriverApplicationModel {
  const _DriverApplicationModel({required this.id, required this.userId, required this.fullName, required this.email, required this.phone, required this.vehicleType, required this.vehiclePlate, this.licenseUrl, this.vehiclePhotoUrl, this.governmentIdUrl, this.bankName, this.accountNumber, this.accountName, this.status = ApplicationStatus.submitted, this.rejectionReason, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.reviewedAt}): super._();
  factory _DriverApplicationModel.fromJson(Map<String, dynamic> json) => _$DriverApplicationModelFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String fullName;
@override final  String email;
@override final  String phone;
@override final  String vehicleType;
@override final  String vehiclePlate;
@override final  String? licenseUrl;
@override final  String? vehiclePhotoUrl;
@override final  String? governmentIdUrl;
@override final  String? bankName;
@override final  String? accountNumber;
@override final  String? accountName;
@override@JsonKey() final  ApplicationStatus status;
@override final  String? rejectionReason;
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? reviewedAt;

/// Create a copy of DriverApplicationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverApplicationModelCopyWith<_DriverApplicationModel> get copyWith => __$DriverApplicationModelCopyWithImpl<_DriverApplicationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverApplicationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverApplicationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.licenseUrl, licenseUrl) || other.licenseUrl == licenseUrl)&&(identical(other.vehiclePhotoUrl, vehiclePhotoUrl) || other.vehiclePhotoUrl == vehiclePhotoUrl)&&(identical(other.governmentIdUrl, governmentIdUrl) || other.governmentIdUrl == governmentIdUrl)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,fullName,email,phone,vehicleType,vehiclePlate,licenseUrl,vehiclePhotoUrl,governmentIdUrl,bankName,accountNumber,accountName,status,rejectionReason,createdAt,reviewedAt);

@override
String toString() {
  return 'DriverApplicationModel(id: $id, userId: $userId, fullName: $fullName, email: $email, phone: $phone, vehicleType: $vehicleType, vehiclePlate: $vehiclePlate, licenseUrl: $licenseUrl, vehiclePhotoUrl: $vehiclePhotoUrl, governmentIdUrl: $governmentIdUrl, bankName: $bankName, accountNumber: $accountNumber, accountName: $accountName, status: $status, rejectionReason: $rejectionReason, createdAt: $createdAt, reviewedAt: $reviewedAt)';
}


}

/// @nodoc
abstract mixin class _$DriverApplicationModelCopyWith<$Res> implements $DriverApplicationModelCopyWith<$Res> {
  factory _$DriverApplicationModelCopyWith(_DriverApplicationModel value, $Res Function(_DriverApplicationModel) _then) = __$DriverApplicationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String fullName, String email, String phone, String vehicleType, String vehiclePlate, String? licenseUrl, String? vehiclePhotoUrl, String? governmentIdUrl, String? bankName, String? accountNumber, String? accountName, ApplicationStatus status, String? rejectionReason,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? reviewedAt
});




}
/// @nodoc
class __$DriverApplicationModelCopyWithImpl<$Res>
    implements _$DriverApplicationModelCopyWith<$Res> {
  __$DriverApplicationModelCopyWithImpl(this._self, this._then);

  final _DriverApplicationModel _self;
  final $Res Function(_DriverApplicationModel) _then;

/// Create a copy of DriverApplicationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? fullName = null,Object? email = null,Object? phone = null,Object? vehicleType = null,Object? vehiclePlate = null,Object? licenseUrl = freezed,Object? vehiclePhotoUrl = freezed,Object? governmentIdUrl = freezed,Object? bankName = freezed,Object? accountNumber = freezed,Object? accountName = freezed,Object? status = null,Object? rejectionReason = freezed,Object? createdAt = null,Object? reviewedAt = freezed,}) {
  return _then(_DriverApplicationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,vehicleType: null == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,licenseUrl: freezed == licenseUrl ? _self.licenseUrl : licenseUrl // ignore: cast_nullable_to_non_nullable
as String?,vehiclePhotoUrl: freezed == vehiclePhotoUrl ? _self.vehiclePhotoUrl : vehiclePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,governmentIdUrl: freezed == governmentIdUrl ? _self.governmentIdUrl : governmentIdUrl // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,accountNumber: freezed == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String?,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ApplicationStatus,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
