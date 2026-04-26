import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

part 'investor_model.freezed.dart';
part 'investor_model.g.dart';

@freezed
abstract class InvestorModel with _$InvestorModel {
  const InvestorModel._();
  const factory InvestorModel({
    required String id,
    required String userId,
    @Default(0.0) double totalInvested,
    @Default(0.0) double totalEarned,
    @Default(0) int activeBikes,
    @Default(0.0) double pendingWithdrawal,
    @TimestampConverter() required DateTime createdAt,
  }) = _InvestorModel;

  factory InvestorModel.fromJson(Map<String, dynamic> json) =>
      _$InvestorModelFromJson(json);

  factory InvestorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return InvestorModel.fromJson(data);
  }
}

extension InvestorModelX on InvestorModel {
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalInvested': totalInvested,
      'totalEarned': totalEarned,
      'activeBikes': activeBikes,
      'pendingWithdrawal': pendingWithdrawal,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
