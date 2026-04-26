import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

enum TransactionType {
  @JsonValue('top_up')
  topUp,
  @JsonValue('withdrawal')
  withdrawal,
  @JsonValue('delivery_payment')
  deliveryPayment,
  @JsonValue('delivery_earning')
  deliveryEarning,
  @JsonValue('referral_bonus')
  referralBonus,
  @JsonValue('promo_credit')
  promoCredit,
  @JsonValue('investment')
  investment,
  @JsonValue('hp_repayment')
  hpRepayment,
  @JsonValue('investor_earning')
  investorEarning,
}

enum TransactionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('success')
  success,
  @JsonValue('failed')
  failed,
}

@freezed
abstract class TransactionModel with _$TransactionModel {
  const TransactionModel._();
  const factory TransactionModel({
    required String id,
    required String userId,
    required TransactionType type,
    required double amount,
    required double balanceBefore,
    required double balanceAfter,
    required String reference,
    required String description,
    @Default(TransactionStatus.pending) TransactionStatus status,
    Map<String, dynamic>? metadata,
    @TimestampConverter() required DateTime createdAt,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return TransactionModel.fromJson(data);
  }
}

extension TransactionModelX on TransactionModel {
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'reference': reference,
      'description': description,
      'status': status.name,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
