import 'package:fpdart/fpdart.dart';
import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/features/payment/domain/entities/transaction_model.dart';

/// Abstract repository for payment and transaction operations.
abstract class IPaymentRepository {
  /// Stream transactions for a user
  Stream<List<TransactionModel>> watchTransactions(String userId);

  /// Stream transactions filtered by type
  Stream<List<TransactionModel>> watchTransactionsByType(
      String userId, TransactionType type);

  /// Get today's earnings for a driver
  Future<Either<Failure, double>> getTodayEarnings(String userId);

  /// Get earnings for a date range
  Future<Either<Failure, double>> getEarningsForRange(
      String userId, DateTime start, DateTime end);

  /// Get daily earnings for last N days (for charts)
  Future<Either<Failure, Map<DateTime, double>>> getDailyEarnings(
      String userId, int days);

  /// Create a transaction record
  Future<Either<Failure, TransactionModel>> createTransaction(
      TransactionModel transaction);

  /// Initialize Paystack payment
  Future<Either<Failure, String>> initializePayment({
    required double amount,
    required String email,
    required String reference,
  });

  /// Verify payment via Cloud Function
  Future<Either<Failure, Unit>> verifyPayment(String reference);
}
