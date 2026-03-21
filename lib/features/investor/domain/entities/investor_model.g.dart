// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvestorModel _$InvestorModelFromJson(Map<String, dynamic> json) =>
    _InvestorModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      totalInvested: (json['totalInvested'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0.0,
      activeBikes: (json['activeBikes'] as num?)?.toInt() ?? 0,
      pendingWithdrawal: (json['pendingWithdrawal'] as num?)?.toDouble() ?? 0.0,
      createdAt: const TimestampConverter().fromJson(
        json['createdAt'] as Timestamp,
      ),
    );

Map<String, dynamic> _$InvestorModelToJson(_InvestorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'totalInvested': instance.totalInvested,
      'totalEarned': instance.totalEarned,
      'activeBikes': instance.activeBikes,
      'pendingWithdrawal': instance.pendingWithdrawal,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
