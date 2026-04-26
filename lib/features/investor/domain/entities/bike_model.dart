import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';

part 'bike_model.freezed.dart';
part 'bike_model.g.dart';

enum BikeStatus {
  @JsonValue('pending_funding')
  pendingFunding,
  @JsonValue('funded')
  funded,
  @JsonValue('assigned')
  assigned,
  @JsonValue('active')
  active,
  @JsonValue('maintenance')
  maintenance,
  @JsonValue('decommissioned')
  decommissioned,
}

@freezed
abstract class BikeModel with _$BikeModel {
  const BikeModel._();
  const factory BikeModel({
    required String id,
    required String make,
    required String model,
    required int year,
    required String plateNumber,
    required double purchasePrice,
    @Default(BikeStatus.pendingFunding) BikeStatus status,
    String? investorId,
    String? riderId,
    @Default(0.0) double totalRepayment,
    @Default(0.0) double repaidAmount,
    @Default(0.0) double monthlyInstalment,
    @Default(0.15) double commissionRate,
    @Default([]) List<String> imageUrls,
    @TimestampConverter() required DateTime createdAt,
  }) = _BikeModel;

  factory BikeModel.fromJson(Map<String, dynamic> json) =>
      _$BikeModelFromJson(json);

  factory BikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return BikeModel.fromJson(data);
  }
}

extension BikeModelX on BikeModel {
  Map<String, dynamic> toFirestore() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'purchasePrice': purchasePrice,
      'status': status.name,
      'investorId': investorId,
      'riderId': riderId,
      'totalRepayment': totalRepayment,
      'repaidAmount': repaidAmount,
      'monthlyInstalment': monthlyInstalment,
      'commissionRate': commissionRate,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double get repaymentProgress =>
      totalRepayment > 0 ? repaidAmount / totalRepayment : 0.0;

  double get remainingRepayment => totalRepayment - repaidAmount;
}
