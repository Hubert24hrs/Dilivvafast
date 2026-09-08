import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:io';

import 'package:dilivvafast/core/domain/entities/driver_presence.dart';
import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/constants/firestore_constants.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';
import 'package:dilivvafast/features/auth/domain/repositories/i_user_repository.dart';

class FirebaseUserRepository implements IUserRepository {
  FirebaseUserRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(FirestoreConstants.users);

  CollectionReference<Map<String, dynamic>> get _driverLocationsRef =>
      _firestore.collection(FirestoreConstants.driverLocations);

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
    String userId,
    Map<String, dynamic> data,
  ) async {
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
    String userId,
    String token,
  ) async {
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
    String userId,
    double latitude,
    double longitude,
  ) async {
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

  /// Flip the driver online/available.
  ///
  /// Written to both places: `users` remains the driver's own record, and
  /// `driver_locations` is the projection customers and the dispatch trigger
  /// read. Going offline clears the last position so a stale pin cannot linger
  /// on the customer map.
  @override
  Future<Either<Failure, Unit>> updateOnlineStatus(
    String userId,
    bool isOnline,
    bool isAvailable,
  ) async {
    try {
      final batch = _firestore.batch();

      batch.update(_usersRef.doc(userId), {
        FirestoreConstants.fieldIsOnline: isOnline,
        FirestoreConstants.fieldIsAvailable: isAvailable,
        FirestoreConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });

      batch.set(_driverLocationsRef.doc(userId), {
        'driverId': userId,
        'isOnline': isOnline,
        'isAvailable': isAvailable,
        'lastSeen': FieldValue.serverTimestamp(),
        if (!isOnline) 'location': FieldValue.delete(),
      }, SetOptions(merge: true));

      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto(
    String userId,
    String filePath,
  ) async {
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

  /// Full driver records. Readable by administrators only — customers get
  /// [watchOnlineDriverPresence] instead.
  @override
  Stream<List<UserModel>> watchOnlineDrivers() {
    return _usersRef
        .where(FirestoreConstants.fieldRole, isEqualTo: 'driver')
        .where(FirestoreConstants.fieldIsOnline, isEqualTo: true)
        .where(FirestoreConstants.fieldIsAvailable, isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  /// Live courier presence for the customer map and availability indicator.
  /// Carries no personal or financial data.
  @override
  Stream<List<DriverPresence>> watchOnlineDriverPresence() {
    return _driverLocationsRef
        .where('isOnline', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DriverPresence.fromFirestore(doc))
              .toList(),
        );
  }

  /// Resolve a referral code to its owner.
  ///
  /// Goes through the `lookupReferralCode` Cloud Function. The direct
  /// `where('referralCode', ...)` query this replaced required the ability to
  /// query arbitrary user documents, which the hardened rules deny — and which
  /// would have let anyone enumerate the user base a code at a time. Only the
  /// referrer's uid comes back, never their record.
  @override
  Future<Either<Failure, String?>> getUserIdByReferralCode(String code) async {
    try {
      final callable = _functions.httpsCallable('lookupReferralCode');
      final result = await callable.call<Map<String, dynamic>>({'code': code});
      final found = result.data['found'] as bool? ?? false;
      if (!found) return const Right(null);
      return Right(result.data['referrerId'] as String?);
    } on FirebaseFunctionsException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Referral lookup failed.'));
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }
}
