import 'package:cloud_firestore/cloud_firestore.dart';

/// Hire-Purchase Agreement model
class HPAgreementModel {
  final String id;
  final String bikeId;
  final String investorId;
  final String? riderId; // Assigned later when matched
  final double principalAmount; // Original bike cost (e.g., ₦1,500,000)
  final double interestRate; // Annual interest rate (e.g., 0.20 for 20%)
  final int termMonths; // Duration in months (e.g., 18)
  final double totalRepayment; // Principal + Interest
  final double remainingBalance; // Tracks HP progress
  final double monthlyDeduction; // Expected monthly deduction from earnings
  final String status; // 'pending_rider', 'active', 'completed', 'defaulted', 'cancelled'
  final DateTime? startDate;
  final DateTime? projectedCompletionDate;
  final DateTime? actualCompletionDate;
  final String? investorSignatureUrl;
  final String? riderSignatureUrl;
  final DateTime? investorSignedAt;
  final DateTime? riderSignedAt;
  final int missedPaymentWeeks; // For default tracking
  final String? defaultReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  HPAgreementModel({
    required this.id,
    required this.bikeId,
    required this.investorId,
    this.riderId,
    required this.principalAmount,
    required this.interestRate,
    required this.termMonths,
    required this.totalRepayment,
    required this.remainingBalance,
    required this.monthlyDeduction,
    this.status = 'pending_rider',
    this.startDate,
    this.projectedCompletionDate,
    this.actualCompletionDate,
    this.investorSignatureUrl,
    this.riderSignatureUrl,
    this.investorSignedAt,
    this.riderSignedAt,
    this.missedPaymentWeeks = 0,
    this.defaultReason,
    required this.createdAt,
    this.updatedAt,
  });

  /// Calculate HP details from principal and terms
  factory HPAgreementModel.calculate({
    required String id,
    required String bikeId,
    required String investorId,
    required double principalAmount,
    required double interestRate,
    required int termMonths,
  }) {
    final totalInterest = principalAmount * interestRate * (termMonths / 12);
    final totalRepayment = principalAmount + totalInterest;
    final monthlyDeduction = totalRepayment / termMonths;
    
    return HPAgreementModel(
      id: id,
      bikeId: bikeId,
      investorId: investorId,
      principalAmount: principalAmount,
      interestRate: interestRate,
      termMonths: termMonths,
      totalRepayment: totalRepayment,
      remainingBalance: totalRepayment,
      monthlyDeduction: monthlyDeduction,
      createdAt: DateTime.now(),
    );
  }

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (totalRepayment == 0) return 0.0;
    return (totalRepayment - remainingBalance) / totalRepayment;
  }

  /// Amount paid so far
  double get amountPaid => totalRepayment - remainingBalance;

  /// Investor's expected total return
  double get expectedReturn => totalRepayment - principalAmount;

  /// Is HP complete
  bool get isComplete => remainingBalance <= 0;

  /// Is at risk of default (missed 3+ weeks)
  bool get isAtRisk => missedPaymentWeeks >= 3;

  factory HPAgreementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime parsedCreatedAt;
    try {
      if (data['createdAt'] is Timestamp) {
        parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        parsedCreatedAt = DateTime.parse(data['createdAt']);
      } else {
        parsedCreatedAt = DateTime.now();
      }
    } catch (e) {
      parsedCreatedAt = DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      try {
        if (value is Timestamp) return value.toDate();
        if (value is String) return DateTime.parse(value);
      } catch (e) {
        return null;
      }
      return null;
    }

    return HPAgreementModel(
      id: doc.id,
      bikeId: data['bikeId'] ?? '',
      investorId: data['investorId'] ?? '',
      riderId: data['riderId'],
      principalAmount: (data['principalAmount'] ?? 0.0).toDouble(),
      interestRate: (data['interestRate'] ?? 0.0).toDouble(),
      termMonths: data['termMonths'] ?? 12,
      totalRepayment: (data['totalRepayment'] ?? 0.0).toDouble(),
      remainingBalance: (data['remainingBalance'] ?? 0.0).toDouble(),
      monthlyDeduction: (data['monthlyDeduction'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending_rider',
      startDate: parseNullableDate(data['startDate']),
      projectedCompletionDate: parseNullableDate(data['projectedCompletionDate']),
      actualCompletionDate: parseNullableDate(data['actualCompletionDate']),
      investorSignatureUrl: data['investorSignatureUrl'],
      riderSignatureUrl: data['riderSignatureUrl'],
      investorSignedAt: parseNullableDate(data['investorSignedAt']),
      riderSignedAt: parseNullableDate(data['riderSignedAt']),
      missedPaymentWeeks: data['missedPaymentWeeks'] ?? 0,
      defaultReason: data['defaultReason'],
      createdAt: parsedCreatedAt,
      updatedAt: parseNullableDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bikeId': bikeId,
      'investorId': investorId,
      'riderId': riderId,
      'principalAmount': principalAmount,
      'interestRate': interestRate,
      'termMonths': termMonths,
      'totalRepayment': totalRepayment,
      'remainingBalance': remainingBalance,
      'monthlyDeduction': monthlyDeduction,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'projectedCompletionDate': projectedCompletionDate?.toIso8601String(),
      'actualCompletionDate': actualCompletionDate?.toIso8601String(),
      'investorSignatureUrl': investorSignatureUrl,
      'riderSignatureUrl': riderSignatureUrl,
      'investorSignedAt': investorSignedAt?.toIso8601String(),
      'riderSignedAt': riderSignedAt?.toIso8601String(),
      'missedPaymentWeeks': missedPaymentWeeks,
      'defaultReason': defaultReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  HPAgreementModel copyWith({
    String? riderId,
    double? remainingBalance,
    String? status,
    DateTime? startDate,
    DateTime? projectedCompletionDate,
    DateTime? actualCompletionDate,
    String? investorSignatureUrl,
    String? riderSignatureUrl,
    DateTime? investorSignedAt,
    DateTime? riderSignedAt,
    int? missedPaymentWeeks,
    String? defaultReason,
    DateTime? updatedAt,
  }) {
    return HPAgreementModel(
      id: id,
      bikeId: bikeId,
      investorId: investorId,
      riderId: riderId ?? this.riderId,
      principalAmount: principalAmount,
      interestRate: interestRate,
      termMonths: termMonths,
      totalRepayment: totalRepayment,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      monthlyDeduction: monthlyDeduction,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      projectedCompletionDate: projectedCompletionDate ?? this.projectedCompletionDate,
      actualCompletionDate: actualCompletionDate ?? this.actualCompletionDate,
      investorSignatureUrl: investorSignatureUrl ?? this.investorSignatureUrl,
      riderSignatureUrl: riderSignatureUrl ?? this.riderSignatureUrl,
      investorSignedAt: investorSignedAt ?? this.investorSignedAt,
      riderSignedAt: riderSignedAt ?? this.riderSignedAt,
      missedPaymentWeeks: missedPaymentWeeks ?? this.missedPaymentWeeks,
      defaultReason: defaultReason ?? this.defaultReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
