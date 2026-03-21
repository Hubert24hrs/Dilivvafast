// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investor_earnings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvestorEarningsModel _$InvestorEarningsModelFromJson(
  Map<String, dynamic> json,
) => _InvestorEarningsModel(
  id: json['id'] as String,
  investorId: json['investorId'] as String,
  bikeId: json['bikeId'] as String,
  orderId: json['orderId'] as String,
  amount: (json['amount'] as num).toDouble(),
  status:
      $enumDecodeNullable(_$EarningStatusEnumMap, json['status']) ??
      EarningStatus.pending,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
);

Map<String, dynamic> _$InvestorEarningsModelToJson(
  _InvestorEarningsModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'investorId': instance.investorId,
  'bikeId': instance.bikeId,
  'orderId': instance.orderId,
  'amount': instance.amount,
  'status': _$EarningStatusEnumMap[instance.status]!,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
};

const _$EarningStatusEnumMap = {
  EarningStatus.pending: 'pending',
  EarningStatus.paid: 'paid',
};

_InvestorWithdrawalModel _$InvestorWithdrawalModelFromJson(
  Map<String, dynamic> json,
) => _InvestorWithdrawalModel(
  id: json['id'] as String,
  investorId: json['investorId'] as String,
  amount: (json['amount'] as num).toDouble(),
  bankName: json['bankName'] as String,
  accountNumber: json['accountNumber'] as String,
  accountName: json['accountName'] as String,
  status: json['status'] as String? ?? 'pending',
  adminNotes: json['adminNotes'] as String?,
  createdAt: const TimestampConverter().fromJson(
    json['createdAt'] as Timestamp,
  ),
  processedAt: const NullableTimestampConverter().fromJson(
    json['processedAt'] as Timestamp?,
  ),
);

Map<String, dynamic> _$InvestorWithdrawalModelToJson(
  _InvestorWithdrawalModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'investorId': instance.investorId,
  'amount': instance.amount,
  'bankName': instance.bankName,
  'accountNumber': instance.accountNumber,
  'accountName': instance.accountName,
  'status': instance.status,
  'adminNotes': instance.adminNotes,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'processedAt': const NullableTimestampConverter().toJson(
    instance.processedAt,
  ),
};
