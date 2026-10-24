import 'package:fpdart/fpdart.dart';
import 'package:dilivvafast/core/domain/entities/driver_presence.dart';
import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

/// Abstract user repository interface for user profile operations.
abstract class IUserRepository {
  /// Get user by ID (one-time)
  Future<Either<Failure, UserModel>> getUserById(String userId);

  /// Stream user profile changes
  Stream<UserModel?> watchUser(String userId);

  /// Stream wallet balance
  Stream<double> watchWalletBalance(String userId);

  /// Update user profile fields
  Future<Either<Failure, Unit>> updateUser(
    String userId,
    Map<String, dynamic> data,
  );

  /// Update FCM token
  Future<Either<Failure, Unit>> updateFcmToken(String userId, String token);

  /// Update user location (GeoPoint)
  Future<Either<Failure, Unit>> updateLocation(
    String userId,
    double latitude,
    double longitude,
  );

  /// Update online/available status (for drivers)
  ///
  /// [vehicleType] is published on the driver's public presence record so
  /// dispatch can offer bike bookings to bike riders and car bookings to car
  /// drivers. It is the driver's own approved vehicle, not a secret.
  Future<Either<Failure, Unit>> updateOnlineStatus(
    String userId,
    bool isOnline,
    bool isAvailable, {
    String? vehicleType,
  });

  /// Upload profile photo and update URL
  Future<Either<Failure, String>> uploadProfilePhoto(
    String userId,
    String filePath,
  );

  /// Full records for all online available drivers. Admin-only — reading
  /// arbitrary user documents is denied to customers by firestore.rules.
  Stream<List<UserModel>> watchOnlineDrivers();

  /// Live courier presence for the customer map. Contains no personal data.
  Stream<List<DriverPresence>> watchOnlineDriverPresence();

  /// Resolve a referral code to the referrer's uid via Cloud Function.
  /// Returns null when the code does not exist.
  Future<Either<Failure, String?>> getUserIdByReferralCode(String code);
}
