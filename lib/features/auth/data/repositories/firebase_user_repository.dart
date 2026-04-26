import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:io';

import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/constants/firestore_constants.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';
import 'package:dilivvafast/features/auth/domain/repositories/i_user_repository.dart';

class FirebaseUserRepository implements IUserRepository {
  FirebaseUserRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(FirestoreConstants.users);

  @override
  Future<Either<Failure, UserModel>> getUserById(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists) {
        return const Left(FirestoreFailure('User not found'));
      }
      return Right(UserModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Stream<UserModel?> watchUser(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  @override
  Stream<double> watchWalletBalance(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      final data = doc.data();
      return (data?['walletBalance'] as num?)?.toDouble() ?? 0.0;
    });
  }

  @override
  Future<Either<Failure, Unit>> updateUser(
      String userId, Map<String, dynamic> data) async {
    try {
      data[FirestoreConstants.fieldUpdatedAt] = FieldValue.serverTimestamp();
      await _usersRef.doc(userId).update(data);
      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateFcmToken(
      String userId, String token) async {
    try {
      await _usersRef.doc(userId).update({
        'fcmToken': token,
        FirestoreConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateLocation(
      String userId, double latitude, double longitude) async {
    try {
      await _usersRef.doc(userId).update({
        'location': GeoPoint(latitude, longitude),
        FirestoreConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateOnlineStatus(
      String userId, bool isOnline, bool isAvailable) async {
    try {
      await _usersRef.doc(userId).update({
        FirestoreConstants.fieldIsOnline: isOnline,
        FirestoreConstants.fieldIsAvailable: isAvailable,
        FirestoreConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto(
      String userId, String filePath) async {
    try {
      final ref = _storage.ref('profile_photos/$userId.jpg');
      await ref.putFile(File(filePath));
      final url = await ref.getDownloadURL();

      await _usersRef.doc(userId).update({
        'photoUrl': url,
        FirestoreConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });

      return Right(url);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Stream<List<UserModel>> watchOnlineDrivers() {
    return _usersRef
        .where(FirestoreConstants.fieldRole, isEqualTo: 'driver')
        .where(FirestoreConstants.fieldIsOnline, isEqualTo: true)
        .where(FirestoreConstants.fieldIsAvailable, isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  @override
  Future<Either<Failure, UserModel?>> getUserByReferralCode(
      String code) async {
    try {
      final query = await _usersRef
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return const Right(null);
      return Right(UserModel.fromFirestore(query.docs.first));
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }
}
