import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fpdart/fpdart.dart';

import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/core/constants/firestore_constants.dart';
import 'package:dilivvafast/features/payment/domain/entities/transaction_model.dart';
import 'package:dilivvafast/features/payment/domain/repositories/i_payment_repository.dart';

class FirebasePaymentRepository implements IPaymentRepository {
  FirebasePaymentRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
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
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<TransactionModel>> watchTransactionsByType(
      String userId, TransactionType type) {
    return _transactionsRef
        .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .orderBy(FirestoreConstants.fieldCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<Either<Failure, double>> getTodayEarnings(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snapshot = await _transactionsRef
          .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
          .where('type', isEqualTo: TransactionType.deliveryEarning.name)
          .where(FirestoreConstants.fieldCreatedAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
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
      String userId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _transactionsRef
          .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
          .where('type', isEqualTo: TransactionType.deliveryEarning.name)
          .where(FirestoreConstants.fieldCreatedAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where(FirestoreConstants.fieldCreatedAt,
              isLessThanOrEqualTo: Timestamp.fromDate(end))
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
      String userId, int days) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - days);

      final snapshot = await _transactionsRef
          .where(FirestoreConstants.fieldUserId, isEqualTo: userId)
          .where('type', isEqualTo: TransactionType.deliveryEarning.name)
          .where(FirestoreConstants.fieldCreatedAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .orderBy(FirestoreConstants.fieldCreatedAt)
          .get();

      final Map<DateTime, double> dailyMap = {};
      for (var i = 0; i < days; i++) {
        final day = DateTime(now.year, now.month, now.day - i);
        dailyMap[day] = 0.0;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date =
            (data[FirestoreConstants.fieldCreatedAt] as Timestamp).toDate();
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
      TransactionModel transaction) async {
    try {
      final docRef =
          await _transactionsRef.add(transaction.toFirestore());
      final doc = await docRef.get();
      return Right(TransactionModel.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> initializePayment({
    required double amount,
    required String email,
    required String reference,
  }) async {
    try {
      // This returns a reference/URL from the Cloud Function
      // Actual Paystack initialization happens via PaystackService
      return Right(reference);
    } catch (e) {
      return Left(PaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> verifyPayment(String reference) async {
    try {
      final callable = _functions.httpsCallable('verifyPaystackPayment');
      await callable.call({'reference': reference});
      return const Right(unit);
    } catch (e) {
      return Left(PaymentFailure(e.toString()));
    }
  }
}
