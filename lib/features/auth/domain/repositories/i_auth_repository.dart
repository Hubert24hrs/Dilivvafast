import 'package:fpdart/fpdart.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

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

  /// Delete the current user account
  Future<Either<Failure, Unit>> deleteAccount();

  /// Whether the signed-in user has confirmed their email address.
  ///
  /// This is Firebase Auth's `emailVerified`, which the client cannot forge.
  /// It is deliberately NOT the `isVerified` field on the user document —
  /// that is an admin-controlled identity-verification flag with a different
  /// meaning, and firestore.rules freezes it against client writes.
  bool get isEmailVerified;

  /// Re-send the confirmation email to the signed-in user.
  Future<Either<Failure, Unit>> sendVerificationEmail();

  /// Refresh the auth token and report the current verification state.
  /// `emailVerified` is cached in the ID token, so it only changes after a
  /// reload — checking without this returns a stale answer.
  Future<Either<Failure, bool>> refreshEmailVerified();
}
