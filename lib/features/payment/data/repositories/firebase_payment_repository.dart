import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/constants/firestore_constants.dart';
import 'package:dilivvafast/features/payment/domain/entities/transaction_model.dart';
import 'package:dilivvafast/features/payment/domain/repositories/i_payment_repository.dart';

class FirebasePaymentRepository implements IPaymentRepository {
  FirebasePaymentRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection(FirestoreConstants.transactions);

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _transactionsRef
        .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Stream<List<TransactionModel>> watchTransactionsByType(
    String userId,
    TransactionType type,
  ) {
    return _transactionsRef
        .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<Either<Failure, double>> getTodayEarnings(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snapshot = await _transactionsRef
          .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
          .where('type', isEqualTo: TransactionType.deliveryEarning.name)
          .where(
            FirestoreConstants.fieldCreatedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

      final total = snapshot.docs.fold<double>(0.0, (total, doc) {
        final data = doc.data();
        return total + ((data['amount'] as num?)?.toDouble() ?? 0.0);
      });

      return Right(total);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getEarningsForRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _transactionsRef
          .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
          .where('type', isEqualTo: TransactionType.deliveryEarning.name)
          .where(
            FirestoreConstants.fieldCreatedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            FirestoreConstants.fieldCreatedAt,
            isLessThanOrEqualTo: Timestamp.fromDate(end),
          )
          .get();

      final total = snapshot.docs.fold<double>(0.0, (total, doc) {
        final data = doc.data();
        return total + ((data['amount'] as num?)?.toDouble() ?? 0.0);
      });

      return Right(total);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, double>>> getDailyEarnings(
    String userId,
    int days,
  ) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - days);

      final snapshot = await _transactionsRef
          .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
          .where('type', isEqualTo: TransactionType.deliveryEarning.name)
          .where(
            FirestoreConstants.fieldCreatedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .orderBy(FirestoreConstants.fieldCreatedAt)
          .get();

      final Map<DateTime, double> dailyMap = {};
      for (var i = 0; i < days; i++) {
        final day = DateTime(now.year, now.month, now.day - i);
        dailyMap[day] = 0.0;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = (data[FirestoreConstants.fieldCreatedAt] as Timestamp)
            .toDate();
        final dayKey = DateTime(date.year, date.month, date.day);
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        dailyMap[dayKey] = (dailyMap[dayKey] ?? 0.0) + amount;
      }

      return Right(dailyMap);
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionModel>> createTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final docRef = await _transactionsRef.add(transaction.toFirestore());
      final doc = await docRef.get();
      return Right(TransactionModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  /// Starts a Paystack transaction and returns the checkout URL to open.
  ///
  /// This previously returned the caller's own `reference` string without
  /// contacting Paystack at all. `canLaunchUrl` then rejected it, nothing
  /// opened, and the user was still shown a "payment processing" dialog — so
  /// wallet top-up never worked. The reference is now minted server-side; the
  /// one passed in is ignored so a client cannot pin a reference it has
  /// already had credited.
  @override
  Future<Either<Failure, PaymentInit>> initializePayment({
    required double amount,
    required String email,
    required String reference,
  }) async {
    try {
      final callable = _functions.httpsCallable('initializePaystackPayment');
      final result = await callable.call<Map<String, dynamic>>({
        'amount': amount,
        'email': email,
      });

      final data = result.data;
      final url = data['authorizationUrl'] as String?;
      final serverReference = data['reference'] as String?;

      if (url == null || url.isEmpty || serverReference == null) {
        return const Left(
          PaymentFailure('Payment could not be started. Please try again.'),
        );
      }

      return Right(
        PaymentInit(authorizationUrl: url, reference: serverReference),
      );
    } on FirebaseFunctionsException catch (e) {
      return Left(PaymentFailure(_friendlyMessage(e)));
    } catch (e, stack) {
      // Never surface a raw exception to the user.
      debugPrint('initializePayment failed: $e\n$stack');
      return const Left(
        PaymentFailure('Payment could not be started. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> verifyPayment(String reference) async {
    try {
      final callable = _functions.httpsCallable('verifyPaystackPayment');
      await callable.call<Map<String, dynamic>>({'reference': reference});
      return const Right(unit);
    } on FirebaseFunctionsException catch (e) {
      return Left(PaymentFailure(_friendlyMessage(e)));
    } catch (e, stack) {
      debugPrint('verifyPayment failed: $e\n$stack');
      return const Left(
        PaymentFailure('We could not confirm that payment yet.'),
      );
    }
  }

  /// Cloud Functions already return user-safe text in `message`; anything else
  /// is mapped to a generic string so backend internals never reach the UI.
  String _friendlyMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in again to continue.';
      case 'resource-exhausted':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'invalid-argument':
      case 'failed-precondition':
      case 'permission-denied':
        return e.message ?? 'That payment could not be processed.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
