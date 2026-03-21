import 'package:fpdart/fpdart.dart';
import 'package:fast_delivery/core/errors/failures.dart';
import 'package:fast_delivery/features/investor/domain/entities/bike_model.dart';
import 'package:fast_delivery/features/investor/domain/entities/hp_agreement_model.dart';
import 'package:fast_delivery/features/investor/domain/entities/investor_model.dart';
import 'package:fast_delivery/features/investor/domain/entities/investor_earnings_model.dart';

/// Abstract repository for investor operations.
abstract class IInvestorRepository {
  /// Stream investor profile
  Stream<InvestorModel?> watchInvestorProfile(String userId);

  /// Stream investor's funded bikes
  Stream<List<BikeModel>> watchInvestorBikes(String userId);

  /// Stream available bikes for funding
  Stream<List<BikeModel>> watchAvailableBikes();

  /// Stream HP agreements for investor
  Stream<List<HPAgreementModel>> watchInvestorAgreements(String userId);

  /// Stream investor earnings
  Stream<List<InvestorEarningsModel>> watchInvestorEarnings(String userId);

  /// Stream withdrawal history
  Stream<List<InvestorWithdrawalModel>> watchWithdrawals(String userId);

  /// Fund a bike
  Future<Either<Failure, Unit>> fundBike(String bikeId, String investorId);

  /// Request withdrawal
  Future<Either<Failure, Unit>> requestWithdrawal({
    required String investorId,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  });

  /// Check if user is an investor
  Future<Either<Failure, bool>> isInvestor(String userId);

  /// Get bike by ID
  Future<Either<Failure, BikeModel>> getBikeById(String bikeId);
}
