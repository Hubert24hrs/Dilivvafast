import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:dilivvafast/core/constants/app_constants.dart';
import 'package:dilivvafast/core/domain/entities/bank_account.dart';
import 'package:dilivvafast/features/auth/domain/entities/app_mode.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User roles in the app
enum UserRole {
  @JsonValue('customer')
  customer,
  @JsonValue('driver')
  driver,
  @JsonValue('admin')
  admin,
  @JsonValue('investor')
  investor,
}

/// JSON converter for Firestore Timestamps
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

/// JSON converter for nullable Timestamps
class NullableTimestampConverter
    implements JsonConverter<DateTime?, Timestamp?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Timestamp? timestamp) => timestamp?.toDate();

  @override
  Timestamp? toJson(DateTime? date) =>
      date != null ? Timestamp.fromDate(date) : null;
}

/// JSON converter for GeoPoint.
///
/// [toFirestore] persists a native [GeoPoint], so reads come back as a
/// [GeoPoint] rather than a map. Older documents written before that may still
/// hold a `{latitude, longitude}` map, so both shapes are accepted.
class NullableGeoPointConverter implements JsonConverter<GeoPoint?, Object?> {
  const NullableGeoPointConverter();

  @override
  GeoPoint? fromJson(Object? json) {
    if (json == null) return null;
    if (json is GeoPoint) return json;
    if (json is Map) {
      final lat = json['latitude'] as num?;
      final lng = json['longitude'] as num?;
      if (lat == null || lng == null) return null;
      return GeoPoint(lat.toDouble(), lng.toDouble());
    }
    return null;
  }

  @override
  Object? toJson(GeoPoint? geoPoint) => geoPoint;
}

@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();
  const factory UserModel({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
    String? photoUrl,
    @Default(UserRole.customer) UserRole role,
    @Default(false) bool isVerified,
    @Default(false) bool isOnline,
    required String referralCode,
    String? referredBy,
    String? fcmToken,
    @Default(0.0) double rating,
    @Default(0) int totalDeliveries,

    /// How couriers have rated this user as a customer. Server-maintained.
    @Default(0.0) double customerRating,
    @Default(0) int customerRatingCount,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @NullableGeoPointConverter() GeoPoint? location,
    String? address,
    // Driver-only fields
    String? vehicleType,
    String? vehiclePlate,
    String? licenseUrl,
    @Default(true) bool isAvailable,

    /// Where customers send bank transfers for this courier's deliveries.
    @BankAccountConverter() BankAccount? payoutAccount,
    // Mode entitlements — everyone registers as a customer and unlocks the
    // driver/investor surfaces afterwards. Only the backend may set these to
    // ModeAccess.approved.
    @Default(ModeAccess.none) ModeAccess driverStatus,
    @Default(ModeAccess.none) ModeAccess investorStatus,
    @Default(AppMode.customer) AppMode activeMode,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Create from Firestore document snapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) => UserModel.fromJson(
    normalizeUserData(doc.data() as Map<String, dynamic>? ?? const {}, doc.id),
  );
}

/// Makes a stored profile safe to decode, whichever app version wrote it.
///
/// The production project was first used by an earlier version of the app,
/// whose profiles store the name as `displayName`, the phone as
/// `phoneNumber`, `createdAt` as an ISO string, and `role: user`. Decoding
/// those as-is threw ("type 'Null' is not a subtype of type 'String'"), so
/// the signed-in user came back as null: the profile screen showed the error
/// and switching to Driver mode said "You need to be signed in".
@visibleForTesting
Map<String, dynamic> normalizeUserData(Map<String, dynamic> raw, String uid) {
  final data = Map<String, dynamic>.from(raw)..['uid'] = uid;
  String text(Object? v) => v is String ? v : '';
  String firstText(List<String> keys) {
    for (final k in keys) {
      final v = text(data[k]).trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  data['fullName'] = firstText(['fullName', 'displayName', 'name']);
  data['phone'] = firstText(['phone', 'phoneNumber']);
  data['email'] = text(data['email']);
  data['referralCode'] = text(data['referralCode']);

  final created =
      _asTimestamp(data['createdAt']) ??
      _asTimestamp(data['updatedAt']) ??
      Timestamp.fromMillisecondsSinceEpoch(0);
  data['createdAt'] = created;
  data['updatedAt'] = _asTimestamp(data['updatedAt']) ?? created;

  // Enum fields: map the old app's values, and drop anything unknown so the
  // field takes its default instead of failing the whole profile.
  if (data['role'] == 'user') data['role'] = 'customer';
  void keepIf(String key, Iterable<String> allowed) {
    if (data[key] != null && !allowed.contains(data[key])) data.remove(key);
  }

  keepIf('role', _$UserRoleEnumMap.values);
  keepIf('driverStatus', const [
    'none',
    'pending',
    'approved',
    'rejected',
    'suspended',
  ]);
  keepIf('investorStatus', const [
    'none',
    'pending',
    'approved',
    'rejected',
    'suspended',
  ]);
  keepIf('activeMode', const ['customer', 'driver', 'investor', 'admin']);
  for (final key in ['rating', 'totalDeliveries', 'customerRating']) {
    if (data[key] != null && data[key] is! num) data.remove(key);
  }
  return data;
}

Timestamp? _asTimestamp(Object? value) => switch (value) {
  final Timestamp t => t,
  final DateTime d => Timestamp.fromDate(d),
  final int ms => Timestamp.fromMillisecondsSinceEpoch(ms),
  final String s when DateTime.tryParse(s) != null => Timestamp.fromDate(
    DateTime.parse(s),
  ),
  _ => null,
};

extension UserModelX on UserModel {
  /// How far this user has progressed towards being allowed into [mode].
  ///
  /// Customer is granted to everyone at registration. Admin follows the
  /// backend-controlled [role] and is never selectable from the client.
  ModeAccess accessFor(AppMode mode) => switch (mode) {
    AppMode.customer => ModeAccess.approved,
    AppMode.driver => driverStatus,
    AppMode.investor =>
      AppConstants.investorModeEnabled ? investorStatus : ModeAccess.none,
    AppMode.admin =>
      role == UserRole.admin ? ModeAccess.approved : ModeAccess.none,
  };

  /// Whether [mode] can be entered right now.
  bool canEnter(AppMode mode) => accessFor(mode).isApproved;

  /// Every mode this user is currently allowed into.
  List<AppMode> get availableModes =>
      AppMode.values.where(canEnter).toList(growable: false);

  /// The mode the app should actually show.
  ///
  /// Falls back to customer when [activeMode] points at a surface the user is
  /// no longer entitled to — e.g. a driver whose approval was revoked while
  /// they were signed in.
  AppMode get effectiveMode {
    if (role == UserRole.admin) return AppMode.admin;
    return canEnter(activeMode) ? activeMode : AppMode.customer;
  }

  /// Convert to Firestore-compatible map (with Timestamp, GeoPoint)
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role.name,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'fcmToken': fcmToken,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
      'address': address,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'licenseUrl': licenseUrl,
      'isAvailable': isAvailable,
      'driverStatus': driverStatus.name,
      'investorStatus': investorStatus.name,
      'activeMode': activeMode.name,
    };
    // Remove null values
    map.removeWhere((key, value) => value == null);
    return map;
  }
}
