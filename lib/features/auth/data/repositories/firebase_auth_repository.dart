import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';

import 'package:fast_delivery/core/errors/failures.dart';
import 'package:fast_delivery/core/constants/firestore_constants.dart';
import 'package:fast_delivery/features/auth/domain/entities/user_model.dart';
import 'package:fast_delivery/features/auth/domain/repositories/i_auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
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
        role: role,
        referralCode: _generateReferralCode(),
        referredBy: referralCode,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(FirestoreConstants.users)
          .doc(userModel.uid)
          .set(userModel.toFirestore());

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

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check and try again.';
      default:
        return 'Authentication error. Please try again.';
    }
  }
}
