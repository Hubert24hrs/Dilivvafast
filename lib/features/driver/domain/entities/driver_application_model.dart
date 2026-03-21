import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_delivery/features/auth/domain/entities/user_model.dart';

part 'driver_application_model.freezed.dart';
part 'driver_application_model.g.dart';

enum ApplicationStatus {
  @JsonValue('submitted')
  submitted,
  @JsonValue('under_review')
  underReview,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

@freezed
abstract class DriverApplicationModel with _$DriverApplicationModel {
  const DriverApplicationModel._();
  const factory DriverApplicationModel({
    required String id,
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    required String vehicleType,
    required String vehiclePlate,
    String? licenseUrl,
    String? vehiclePhotoUrl,
    String? governmentIdUrl,
    String? bankName,
    String? accountNumber,
    String? accountName,
    @Default(ApplicationStatus.submitted) ApplicationStatus status,
    String? rejectionReason,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? reviewedAt,
  }) = _DriverApplicationModel;

  factory DriverApplicationModel.fromJson(Map<String, dynamic> json) =>
      _$DriverApplicationModelFromJson(json);

  factory DriverApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return DriverApplicationModel.fromJson(data);
  }
}

extension DriverApplicationModelX on DriverApplicationModel {
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'licenseUrl': licenseUrl,
      'vehiclePhotoUrl': vehiclePhotoUrl,
      'governmentIdUrl': governmentIdUrl,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt':
          reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }
}
