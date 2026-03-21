// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investor_earnings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvestorEarningsModel {

 String get id; String get investorId; String get bikeId; String get orderId; double get amount; EarningStatus get status;@TimestampConverter() DateTime get createdAt;
/// Create a copy of InvestorEarningsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorEarningsModelCopyWith<InvestorEarningsModel> get copyWith => _$InvestorEarningsModelCopyWithImpl<InvestorEarningsModel>(this as InvestorEarningsModel, _$identity);

  /// Serializes this InvestorEarningsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorEarningsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.bikeId, bikeId) || other.bikeId == bikeId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investorId,bikeId,orderId,amount,status,createdAt);

@override
String toString() {
  return 'InvestorEarningsModel(id: $id, investorId: $investorId, bikeId: $bikeId, orderId: $orderId, amount: $amount, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $InvestorEarningsModelCopyWith<$Res>  {
  factory $InvestorEarningsModelCopyWith(InvestorEarningsModel value, $Res Function(InvestorEarningsModel) _then) = _$InvestorEarningsModelCopyWithImpl;
@useResult
$Res call({
 String id, String investorId, String bikeId, String orderId, double amount, EarningStatus status,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$InvestorEarningsModelCopyWithImpl<$Res>
    implements $InvestorEarningsModelCopyWith<$Res> {
  _$InvestorEarningsModelCopyWithImpl(this._self, this._then);

  final InvestorEarningsModel _self;
  final $Res Function(InvestorEarningsModel) _then;

/// Create a copy of InvestorEarningsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? investorId = null,Object? bikeId = null,Object? orderId = null,Object? amount = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as String,bikeId: null == bikeId ? _self.bikeId : bikeId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EarningStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [InvestorEarningsModel].
extension InvestorEarningsModelPatterns on InvestorEarningsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestorEarningsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestorEarningsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestorEarningsModel value)  $default,){
final _that = this;
switch (_that) {
case _InvestorEarningsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestorEarningsModel value)?  $default,){
final _that = this;
switch (_that) {
case _InvestorEarningsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String investorId,  String bikeId,  String orderId,  double amount,  EarningStatus status, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestorEarningsModel() when $default != null:
return $default(_that.id,_that.investorId,_that.bikeId,_that.orderId,_that.amount,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String investorId,  String bikeId,  String orderId,  double amount,  EarningStatus status, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _InvestorEarningsModel():
return $default(_that.id,_that.investorId,_that.bikeId,_that.orderId,_that.amount,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String investorId,  String bikeId,  String orderId,  double amount,  EarningStatus status, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _InvestorEarningsModel() when $default != null:
return $default(_that.id,_that.investorId,_that.bikeId,_that.orderId,_that.amount,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestorEarningsModel extends InvestorEarningsModel {
  const _InvestorEarningsModel({required this.id, required this.investorId, required this.bikeId, required this.orderId, required this.amount, this.status = EarningStatus.pending, @TimestampConverter() required this.createdAt}): super._();
  factory _InvestorEarningsModel.fromJson(Map<String, dynamic> json) => _$InvestorEarningsModelFromJson(json);

@override final  String id;
@override final  String investorId;
@override final  String bikeId;
@override final  String orderId;
@override final  double amount;
@override@JsonKey() final  EarningStatus status;
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of InvestorEarningsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestorEarningsModelCopyWith<_InvestorEarningsModel> get copyWith => __$InvestorEarningsModelCopyWithImpl<_InvestorEarningsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestorEarningsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestorEarningsModel&&(identical(other.id, id) || other.id == id)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.bikeId, bikeId) || other.bikeId == bikeId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investorId,bikeId,orderId,amount,status,createdAt);

@override
String toString() {
  return 'InvestorEarningsModel(id: $id, investorId: $investorId, bikeId: $bikeId, orderId: $orderId, amount: $amount, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InvestorEarningsModelCopyWith<$Res> implements $InvestorEarningsModelCopyWith<$Res> {
  factory _$InvestorEarningsModelCopyWith(_InvestorEarningsModel value, $Res Function(_InvestorEarningsModel) _then) = __$InvestorEarningsModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String investorId, String bikeId, String orderId, double amount, EarningStatus status,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$InvestorEarningsModelCopyWithImpl<$Res>
    implements _$InvestorEarningsModelCopyWith<$Res> {
  __$InvestorEarningsModelCopyWithImpl(this._self, this._then);

  final _InvestorEarningsModel _self;
  final $Res Function(_InvestorEarningsModel) _then;

/// Create a copy of InvestorEarningsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? investorId = null,Object? bikeId = null,Object? orderId = null,Object? amount = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_InvestorEarningsModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as String,bikeId: null == bikeId ? _self.bikeId : bikeId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EarningStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$InvestorWithdrawalModel {

 String get id; String get investorId; double get amount; String get bankName; String get accountNumber; String get accountName; String get status; String? get adminNotes;@TimestampConverter() DateTime get createdAt;@NullableTimestampConverter() DateTime? get processedAt;
/// Create a copy of InvestorWithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorWithdrawalModelCopyWith<InvestorWithdrawalModel> get copyWith => _$InvestorWithdrawalModelCopyWithImpl<InvestorWithdrawalModel>(this as InvestorWithdrawalModel, _$identity);

  /// Serializes this InvestorWithdrawalModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorWithdrawalModel&&(identical(other.id, id) || other.id == id)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.status, status) || other.status == status)&&(identical(other.adminNotes, adminNotes) || other.adminNotes == adminNotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investorId,amount,bankName,accountNumber,accountName,status,adminNotes,createdAt,processedAt);

@override
String toString() {
  return 'InvestorWithdrawalModel(id: $id, investorId: $investorId, amount: $amount, bankName: $bankName, accountNumber: $accountNumber, accountName: $accountName, status: $status, adminNotes: $adminNotes, createdAt: $createdAt, processedAt: $processedAt)';
}


}

/// @nodoc
abstract mixin class $InvestorWithdrawalModelCopyWith<$Res>  {
  factory $InvestorWithdrawalModelCopyWith(InvestorWithdrawalModel value, $Res Function(InvestorWithdrawalModel) _then) = _$InvestorWithdrawalModelCopyWithImpl;
@useResult
$Res call({
 String id, String investorId, double amount, String bankName, String accountNumber, String accountName, String status, String? adminNotes,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? processedAt
});




}
/// @nodoc
class _$InvestorWithdrawalModelCopyWithImpl<$Res>
    implements $InvestorWithdrawalModelCopyWith<$Res> {
  _$InvestorWithdrawalModelCopyWithImpl(this._self, this._then);

  final InvestorWithdrawalModel _self;
  final $Res Function(InvestorWithdrawalModel) _then;

/// Create a copy of InvestorWithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? investorId = null,Object? amount = null,Object? bankName = null,Object? accountNumber = null,Object? accountName = null,Object? status = null,Object? adminNotes = freezed,Object? createdAt = null,Object? processedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,adminNotes: freezed == adminNotes ? _self.adminNotes : adminNotes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [InvestorWithdrawalModel].
extension InvestorWithdrawalModelPatterns on InvestorWithdrawalModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestorWithdrawalModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestorWithdrawalModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestorWithdrawalModel value)  $default,){
final _that = this;
switch (_that) {
case _InvestorWithdrawalModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestorWithdrawalModel value)?  $default,){
final _that = this;
switch (_that) {
case _InvestorWithdrawalModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String investorId,  double amount,  String bankName,  String accountNumber,  String accountName,  String status,  String? adminNotes, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? processedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestorWithdrawalModel() when $default != null:
return $default(_that.id,_that.investorId,_that.amount,_that.bankName,_that.accountNumber,_that.accountName,_that.status,_that.adminNotes,_that.createdAt,_that.processedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String investorId,  double amount,  String bankName,  String accountNumber,  String accountName,  String status,  String? adminNotes, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? processedAt)  $default,) {final _that = this;
switch (_that) {
case _InvestorWithdrawalModel():
return $default(_that.id,_that.investorId,_that.amount,_that.bankName,_that.accountNumber,_that.accountName,_that.status,_that.adminNotes,_that.createdAt,_that.processedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String investorId,  double amount,  String bankName,  String accountNumber,  String accountName,  String status,  String? adminNotes, @TimestampConverter()  DateTime createdAt, @NullableTimestampConverter()  DateTime? processedAt)?  $default,) {final _that = this;
switch (_that) {
case _InvestorWithdrawalModel() when $default != null:
return $default(_that.id,_that.investorId,_that.amount,_that.bankName,_that.accountNumber,_that.accountName,_that.status,_that.adminNotes,_that.createdAt,_that.processedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestorWithdrawalModel extends InvestorWithdrawalModel {
  const _InvestorWithdrawalModel({required this.id, required this.investorId, required this.amount, required this.bankName, required this.accountNumber, required this.accountName, this.status = 'pending', this.adminNotes, @TimestampConverter() required this.createdAt, @NullableTimestampConverter() this.processedAt}): super._();
  factory _InvestorWithdrawalModel.fromJson(Map<String, dynamic> json) => _$InvestorWithdrawalModelFromJson(json);

@override final  String id;
@override final  String investorId;
@override final  double amount;
@override final  String bankName;
@override final  String accountNumber;
@override final  String accountName;
@override@JsonKey() final  String status;
@override final  String? adminNotes;
@override@TimestampConverter() final  DateTime createdAt;
@override@NullableTimestampConverter() final  DateTime? processedAt;

/// Create a copy of InvestorWithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestorWithdrawalModelCopyWith<_InvestorWithdrawalModel> get copyWith => __$InvestorWithdrawalModelCopyWithImpl<_InvestorWithdrawalModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestorWithdrawalModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestorWithdrawalModel&&(identical(other.id, id) || other.id == id)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.status, status) || other.status == status)&&(identical(other.adminNotes, adminNotes) || other.adminNotes == adminNotes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investorId,amount,bankName,accountNumber,accountName,status,adminNotes,createdAt,processedAt);

@override
String toString() {
  return 'InvestorWithdrawalModel(id: $id, investorId: $investorId, amount: $amount, bankName: $bankName, accountNumber: $accountNumber, accountName: $accountName, status: $status, adminNotes: $adminNotes, createdAt: $createdAt, processedAt: $processedAt)';
}


}

/// @nodoc
abstract mixin class _$InvestorWithdrawalModelCopyWith<$Res> implements $InvestorWithdrawalModelCopyWith<$Res> {
  factory _$InvestorWithdrawalModelCopyWith(_InvestorWithdrawalModel value, $Res Function(_InvestorWithdrawalModel) _then) = __$InvestorWithdrawalModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String investorId, double amount, String bankName, String accountNumber, String accountName, String status, String? adminNotes,@TimestampConverter() DateTime createdAt,@NullableTimestampConverter() DateTime? processedAt
});




}
/// @nodoc
class __$InvestorWithdrawalModelCopyWithImpl<$Res>
    implements _$InvestorWithdrawalModelCopyWith<$Res> {
  __$InvestorWithdrawalModelCopyWithImpl(this._self, this._then);

  final _InvestorWithdrawalModel _self;
  final $Res Function(_InvestorWithdrawalModel) _then;

/// Create a copy of InvestorWithdrawalModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? investorId = null,Object? amount = null,Object? bankName = null,Object? accountNumber = null,Object? accountName = null,Object? status = null,Object? adminNotes = freezed,Object? createdAt = null,Object? processedAt = freezed,}) {
  return _then(_InvestorWithdrawalModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,adminNotes: freezed == adminNotes ? _self.adminNotes : adminNotes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
