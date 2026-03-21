import 'package:fpdart/fpdart.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:fast_delivery/core/errors/failures.dart';
import 'package:fast_delivery/features/auth/domain/entities/user_model.dart';

/// Abstract auth repository interface.
abstract class IAuthRepository {
  /// Stream of Firebase Auth state changes
  Stream<User?> get authStateChanges;

  /// Get current Firebase user
  User? get currentUser;

  /// Login with email and password
  Future<Either<Failure, UserModel>> loginWithEmail({
    required String email,
    required String password,
  });

  /// Register with email and password
  Future<Either<Failure, UserModel>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? referralCode,
  });

  /// Login with Google
  Future<Either<Failure, UserModel>> loginWithGoogle();

  /// Login with Apple
  Future<Either<Failure, UserModel>> loginWithApple();

  /// Logout
  Future<Either<Failure, Unit>> logout();

  /// Send password reset email
  Future<Either<Failure, Unit>> resetPassword(String email);

  /// Verify phone number with OTP
  Future<Either<Failure, Unit>> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
  });

  /// Confirm OTP code
  Future<Either<Failure, Unit>> confirmOtp({
    required String verificationId,
    required String otp,
  });
}
