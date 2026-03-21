// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    _TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      amount: (json['amount'] as num).toDouble(),
      balanceBefore: (json['balanceBefore'] as num).toDouble(),
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      reference: json['reference'] as String,
      description: json['description'] as String,
      status:
          $enumDecodeNullable(_$TransactionStatusEnumMap, json['status']) ??
          TransactionStatus.pending,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: const TimestampConverter().fromJson(
        json['createdAt'] as Timestamp,
      ),
    );

Map<String, dynamic> _$TransactionModelToJson(_TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'balanceBefore': instance.balanceBefore,
      'balanceAfter': instance.balanceAfter,
      'reference': instance.reference,
      'description': instance.description,
      'status': _$TransactionStatusEnumMap[instance.status]!,
      'metadata': instance.metadata,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };

const _$TransactionTypeEnumMap = {
  TransactionType.topUp: 'top_up',
  TransactionType.withdrawal: 'withdrawal',
  TransactionType.deliveryPayment: 'delivery_payment',
  TransactionType.deliveryEarning: 'delivery_earning',
  TransactionType.referralBonus: 'referral_bonus',
  TransactionType.promoCredit: 'promo_credit',
  TransactionType.investment: 'investment',
  TransactionType.hpRepayment: 'hp_repayment',
  TransactionType.investorEarning: 'investor_earning',
};

const _$TransactionStatusEnumMap = {
  TransactionStatus.pending: 'pending',
  TransactionStatus.success: 'success',
  TransactionStatus.failed: 'failed',
};
