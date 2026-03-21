import 'package:fpdart/fpdart.dart';
import 'package:fast_delivery/core/errors/failures.dart';
import 'package:fast_delivery/features/auth/domain/entities/user_model.dart';

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
      String userId, Map<String, dynamic> data);

  /// Update FCM token
  Future<Either<Failure, Unit>> updateFcmToken(
      String userId, String token);

  /// Update user location (GeoPoint)
  Future<Either<Failure, Unit>> updateLocation(
      String userId, double latitude, double longitude);

  /// Update online/available status (for drivers)
  Future<Either<Failure, Unit>> updateOnlineStatus(
      String userId, bool isOnline, bool isAvailable);

  /// Upload profile photo and update URL
  Future<Either<Failure, String>> uploadProfilePhoto(
      String userId, String filePath);

  /// Get all online available drivers
  Stream<List<UserModel>> watchOnlineDrivers();

  /// Get user by referral code
  Future<Either<Failure, UserModel?>> getUserByReferralCode(String code);
}
