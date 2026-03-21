import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_delivery/features/investor/domain/entities/investor_model.dart';
import 'package:fast_delivery/features/investor/domain/entities/bike_model.dart';
import 'package:fast_delivery/features/investor/domain/entities/hp_agreement_model.dart';
import 'package:fast_delivery/features/investor/domain/entities/investor_earnings_model.dart';

/// Stub investor service
class InvestorService {
  InvestorService(this._ref);

  // ignore: unused_field
  final Ref _ref;

  Stream<InvestorModel?> streamInvestorProfile(String userId) {
    debugPrint('InvestorService.streamInvestorProfile (stub)');
    return Stream.value(null);
  }

  Stream<List<BikeModel>> getInvestorBikes(String userId) {
    debugPrint('InvestorService.getInvestorBikes (stub)');
    return Stream.value([]);
  }

  Stream<List<HPAgreementModel>> getInvestorAgreements(String userId) {
    debugPrint('InvestorService.getInvestorAgreements (stub)');
    return Stream.value([]);
  }

  Stream<List<InvestorEarningsModel>> getInvestorEarnings(String userId) {
    debugPrint('InvestorService.getInvestorEarnings (stub)');
    return Stream.value([]);
  }

  Stream<List<BikeModel>> getAvailableBikeCampaigns() {
    debugPrint('InvestorService.getAvailableBikeCampaigns (stub)');
    return Stream.value([]);
  }

  Stream<List<InvestorWithdrawalModel>> getWithdrawalHistory(String userId) {
    debugPrint('InvestorService.getWithdrawalHistory (stub)');
    return Stream.value([]);
  }

  Future<bool> isInvestor(String userId) async {
    debugPrint('InvestorService.isInvestor (stub)');
    return false;
  }
}
