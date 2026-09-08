import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/constants/firestore_constants.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';
import 'package:dilivvafast/features/auth/domain/repositories/i_auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<Either<Failure, UserModel>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = await _getOrCreateUserModel(credential.user!);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code), code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? referralCode,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(fullName);

      final now = DateTime.now();
      final userModel = UserModel(
        uid: credential.user!.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        // Registration always creates a customer, whatever the caller asked
        // for. Elevated roles are granted server-side by an admin through the
        // `setUserRole` Cloud Function, which writes a custom claim.
        // firestore.rules rejects any create with a different role, so this is
        // defence in depth rather than the only barrier — but the parameter
        // should never have been able to reach the document.
        role: UserRole.customer,
        referralCode: _generateReferralCode(),
        referredBy: referralCode,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(FirestoreConstants.users)
          .doc(userModel.uid)
          .set(userModel.toFirestore());

      // Kick off address confirmation. Non-fatal: a delivery failure here must
      // not strand a user who already has an account.
      try {
        await credential.user!.sendEmailVerification();
      } catch (e) {
        debugPrint('Could not send verification email: $e');
      }

      // If referred, save referral record
      if (referralCode != null && referralCode.isNotEmpty) {
        await _saveReferral(credential.user!.uid, referralCode);
      }

      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code), code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> loginWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider()..addScope('email');
      final userCredential = await _auth.signInWithProvider(googleProvider);
      final user = await _getOrCreateUserModel(userCredential.user!);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code), code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> loginWithApple() async {
    try {
      final appleProvider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      final userCredential = await _auth.signInWithProvider(appleProvider);
      final user = await _getOrCreateUserModel(userCredential.user!);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code), code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _auth.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code), code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          throw e;
        },
        codeSent: (verificationId, _) => onCodeSent(verificationId),
        codeAutoRetrievalTimeout: (_) {},
      );
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code), code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> confirmOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.currentUser?.linkWithCredential(credential);
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code), code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return Left(const AuthFailure('No authenticated user found to delete.'));
    }
    try {
      final uid = user.uid;

      // 1. Delete this user's notifications.
      //
      // These live in the top-level `notifications` collection keyed by
      // userId — the per-user sub-collection this previously cleared is not
      // where the app writes them, so deletion left the records behind.
      final notifsSnap = await _firestore
          .collection(FirestoreConstants.notifications)
          .where(FirestoreConstants.fieldUserId, isEqualTo: uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in notifsSnap.docs) {
        batch.delete(doc.reference);
      }

      // 2. Delete user doc
      batch.delete(_firestore.collection(FirestoreConstants.users).doc(uid));
      await batch.commit();

      // 3. Delete Firebase Auth user
      await user.delete();
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return Left(
          const AuthFailure(
            'This operation requires recent authentication. Please log in again.',
          ),
        );
      }
      return Left(AuthFailure(_mapAuthError(e.code), code: e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // --- Private helpers ---

  Future<UserModel> _getOrCreateUserModel(User firebaseUser) async {
    final doc = await _firestore
        .collection(FirestoreConstants.users)
        .doc(firebaseUser.uid)
        .get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    // Create new user doc for social sign-in
    final now = DateTime.now();
    final userModel = UserModel(
      uid: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      phone: firebaseUser.phoneNumber ?? '',
      photoUrl: firebaseUser.photoURL,
      referralCode: _generateReferralCode(),
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(FirestoreConstants.users)
        .doc(userModel.uid)
        .set(userModel.toFirestore());

    return userModel;
  }

  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _saveReferral(String refereeId, String referralCode) async {
    try {
      await _firestore.collection(FirestoreConstants.referrals).add({
        'refereeId': refereeId,
        'referralCode': referralCode,
        'status': 'pending',
        'bonusPaid': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-critical — don't fail registration if referral save fails
    }
  }

  @override
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  @override
  Future<Either<Failure, Unit>> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      return Left(const AuthFailure('Please sign in first.'));
    }
    if (user.emailVerified) return const Right(unit);

    try {
      await user.sendEmailVerification();
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code), code: e.code));
    } catch (e) {
      debugPrint('sendVerificationEmail failed: $e');
      return Left(const AuthFailure('Could not send the email. Try again.'));
    }
  }

  @override
  Future<Either<Failure, bool>> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) {
      return Left(const AuthFailure('Please sign in first.'));
    }
    try {
      // emailVerified is cached in the ID token; without a reload this keeps
      // reporting the value from whenever the token was minted.
      await user.reload();
      return Right(_auth.currentUser?.emailVerified ?? false);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapAuthError(e.code), code: e.code));
    } catch (e) {
      debugPrint('refreshEmailVerified failed: $e');
      return Left(const AuthFailure('Could not check verification status.'));
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      // Firebase Auth v10+ consolidates wrong-password + user-not-found
      // into a single 'invalid-credential' code to prevent user enumeration.
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password. Please check and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters with a number.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been suspended. Contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not currently enabled.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'requires-recent-login':
        return 'This action requires you to sign in again for security.';
      default:
        return 'Authentication error ($code). Please try again.';
    }
  }
}
