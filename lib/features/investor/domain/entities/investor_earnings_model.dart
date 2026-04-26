import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

part 'investor_earnings_model.freezed.dart';
part 'investor_earnings_model.g.dart';

enum EarningStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('paid')
  paid,
}

@freezed
abstract class InvestorEarningsModel with _$InvestorEarningsModel {
  const InvestorEarningsModel._();
  const factory InvestorEarningsModel({
    required String id,
    required String investorId,
    required String bikeId,
    required String orderId,
    required double amount,
    @Default(EarningStatus.pending) EarningStatus status,
    @TimestampConverter() required DateTime createdAt,
  }) = _InvestorEarningsModel;

  factory InvestorEarningsModel.fromJson(Map<String, dynamic> json) =>
      _$InvestorEarningsModelFromJson(json);

  factory InvestorEarningsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return InvestorEarningsModel.fromJson(data);
  }
}

extension InvestorEarningsModelX on InvestorEarningsModel {
  Map<String, dynamic> toFirestore() {
    return {
      'investorId': investorId,
      'bikeId': bikeId,
      'orderId': orderId,
      'amount': amount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Investor withdrawal request model
@freezed
abstract class InvestorWithdrawalModel with _$InvestorWithdrawalModel {
  const InvestorWithdrawalModel._();
  const factory InvestorWithdrawalModel({
    required String id,
    required String investorId,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
    @Default('pending') String status,
    String? adminNotes,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? processedAt,
  }) = _InvestorWithdrawalModel;

  factory InvestorWithdrawalModel.fromJson(Map<String, dynamic> json) =>
      _$InvestorWithdrawalModelFromJson(json);

  factory InvestorWithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return InvestorWithdrawalModel.fromJson(data);
  }
}

extension InvestorWithdrawalModelX on InvestorWithdrawalModel {
  Map<String, dynamic> toFirestore() {
    return {
      'investorId': investorId,
      'amount': amount,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'status': status,
      'adminNotes': adminNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt':
          processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }
}
