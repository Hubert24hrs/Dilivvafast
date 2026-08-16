import 'package:fpdart/fpdart.dart';
import 'package:dilivvafast/core/errors/failures.dart';
import 'package:dilivvafast/features/payment/domain/entities/transaction_model.dart';

/// A Paystack checkout session created server-side.
class PaymentSession {
  const PaymentSession({
    required this.authorizationUrl,
    required this.reference,
  });

  /// Hosted Paystack checkout page to open in a browser.
  final String authorizationUrl;

  /// Server-generated reference used later to verify the payment.
  final String reference;
}

/// Outcome of asking the backend to verify a Paystack reference.
class PaymentVerification {
  const PaymentVerification({
    required this.amount,
    required this.alreadyProcessed,
    required this.message,
  });

  /// Amount credited, in Naira.
  final double amount;

  /// True when this reference had already been credited by an earlier call or
  /// by the Paystack webhook — the wallet was not credited twice.
  final bool alreadyProcessed;

  final String message;
}

/// Abstract repository for payment and transaction operations.
abstract class IPaymentRepository {
  /// Stream transactions for a user
  Stream<List<TransactionModel>> watchTransactions(String userId);

  /// Stream transactions filtered by type
  Stream<List<TransactionModel>> watchTransactionsByType(
    String userId,
    TransactionType type,
  );

  /// Get today's earnings for a driver
  Future<Either<Failure, double>> getTodayEarnings(String userId);

  /// Get earnings for a date range
  Future<Either<Failure, double>> getEarningsForRange(
    String userId,
    DateTime start,
    DateTime end,
  );

  /// Get daily earnings for last N days (for charts)
  Future<Either<Failure, Map<DateTime, double>>> getDailyEarnings(
    String userId,
    int days,
  );

  /// Create a transaction record
  Future<Either<Failure, TransactionModel>> createTransaction(
    TransactionModel transaction,
  );

  /// Start a Paystack checkout for [amount] Naira.
  ///
  /// The reference and the customer email are decided server-side, so the app
  /// only supplies the amount.
  Future<Either<Failure, PaymentSession>> initializePayment({
    required double amount,
  });

  /// Verify a completed payment and credit the wallet. Safe to call more than
  /// once for the same reference — the backend credits at most once.
  Future<Either<Failure, PaymentVerification>> verifyPayment(String reference);
}
