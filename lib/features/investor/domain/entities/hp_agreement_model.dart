import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

part 'hp_agreement_model.freezed.dart';
part 'hp_agreement_model.g.dart';

enum AgreementStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('defaulted')
  defaulted,
}

@freezed
abstract class HPAgreementModel with _$HPAgreementModel {
  const HPAgreementModel._();
  const factory HPAgreementModel({
    required String id,
    required String bikeId,
    required String investorId,
    required String riderId,
    required double totalRepayment,
    @Default(0.0) double repaidAmount,
    required double monthlyInstalment,
    @Default(AgreementStatus.active) AgreementStatus status,
    @TimestampConverter() required DateTime startDate,
    @TimestampConverter() required DateTime endDate,
    @TimestampConverter() required DateTime createdAt,
  }) = _HPAgreementModel;

  factory HPAgreementModel.fromJson(Map<String, dynamic> json) =>
      _$HPAgreementModelFromJson(json);

  factory HPAgreementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return HPAgreementModel.fromJson(data);
  }
}

extension HPAgreementModelX on HPAgreementModel {
  Map<String, dynamic> toFirestore() {
    return {
      'bikeId': bikeId,
      'investorId': investorId,
      'riderId': riderId,
      'totalRepayment': totalRepayment,
      'repaidAmount': repaidAmount,
      'monthlyInstalment': monthlyInstalment,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double get progress =>
      totalRepayment > 0 ? repaidAmount / totalRepayment : 0.0;
  double get remainingAmount => totalRepayment - repaidAmount;
}
