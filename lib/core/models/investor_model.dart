import 'package:cloud_firestore/cloud_firestore.dart';

/// Bank details for investor withdrawals
class BankDetails {
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String? bankCode; // For Paystack transfers

  BankDetails({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.bankCode,
  });

  factory BankDetails.fromMap(Map<String, dynamic> data) {
    return BankDetails(
      bankName: data['bankName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      accountName: data['accountName'] ?? '',
      bankCode: data['bankCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'bankCode': bankCode,
    };
  }
}

/// Investor profile model for hire-purchase funding
class InvestorModel {
  final String id;
  final String userId;
  final String? displayName;
  final String email;
  final String? phone;
  final bool bvnVerified;
  final bool ninVerified;
  final String kycStatus; // 'pending', 'verified', 'rejected'
  final double walletBalance;
  final double totalInvested;
  final double totalReturns;
  final double totalWithdrawn;
  final BankDetails? bankDetails;
  final int activeBikes;
  final int completedHPAgreements;
  final DateTime createdAt;
  final DateTime? updatedAt;

  InvestorModel({
    required this.id,
    required this.userId,
    this.displayName,
    required this.email,
    this.phone,
    this.bvnVerified = false,
    this.ninVerified = false,
    this.kycStatus = 'pending',
    this.walletBalance = 0.0,
    this.totalInvested = 0.0,
    this.totalReturns = 0.0,
    this.totalWithdrawn = 0.0,
    this.bankDetails,
    this.activeBikes = 0,
    this.completedHPAgreements = 0,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isKycComplete => bvnVerified && ninVerified;

  factory InvestorModel.fromFirestore(DocumentSnapshot doc) {
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

    DateTime? parsedUpdatedAt;
    if (data['updatedAt'] != null) {
      try {
        if (data['updatedAt'] is Timestamp) {
          parsedUpdatedAt = (data['updatedAt'] as Timestamp).toDate();
        } else if (data['updatedAt'] is String) {
          parsedUpdatedAt = DateTime.parse(data['updatedAt']);
        }
      } catch (e) {
        parsedUpdatedAt = null;
      }
    }

    return InvestorModel(
      id: doc.id,
      userId: data['userId'] ?? doc.id,
      displayName: data['displayName'],
      email: data['email'] ?? '',
      phone: data['phone'],
      bvnVerified: data['bvnVerified'] ?? false,
      ninVerified: data['ninVerified'] ?? false,
      kycStatus: data['kycStatus'] ?? 'pending',
      walletBalance: (data['walletBalance'] ?? 0.0).toDouble(),
      totalInvested: (data['totalInvested'] ?? 0.0).toDouble(),
      totalReturns: (data['totalReturns'] ?? 0.0).toDouble(),
      totalWithdrawn: (data['totalWithdrawn'] ?? 0.0).toDouble(),
      bankDetails: data['bankDetails'] != null 
          ? BankDetails.fromMap(data['bankDetails']) 
          : null,
      activeBikes: data['activeBikes'] ?? 0,
      completedHPAgreements: data['completedHPAgreements'] ?? 0,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'bvnVerified': bvnVerified,
      'ninVerified': ninVerified,
      'kycStatus': kycStatus,
      'walletBalance': walletBalance,
      'totalInvested': totalInvested,
      'totalReturns': totalReturns,
      'totalWithdrawn': totalWithdrawn,
      'bankDetails': bankDetails?.toMap(),
      'activeBikes': activeBikes,
      'completedHPAgreements': completedHPAgreements,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  InvestorModel copyWith({
    String? displayName,
    String? phone,
    bool? bvnVerified,
    bool? ninVerified,
    String? kycStatus,
    double? walletBalance,
    double? totalInvested,
    double? totalReturns,
    double? totalWithdrawn,
    BankDetails? bankDetails,
    int? activeBikes,
    int? completedHPAgreements,
    DateTime? updatedAt,
  }) {
    return InvestorModel(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      email: email,
      phone: phone ?? this.phone,
      bvnVerified: bvnVerified ?? this.bvnVerified,
      ninVerified: ninVerified ?? this.ninVerified,
      kycStatus: kycStatus ?? this.kycStatus,
      walletBalance: walletBalance ?? this.walletBalance,
      totalInvested: totalInvested ?? this.totalInvested,
      totalReturns: totalReturns ?? this.totalReturns,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      bankDetails: bankDetails ?? this.bankDetails,
      activeBikes: activeBikes ?? this.activeBikes,
      completedHPAgreements: completedHPAgreements ?? this.completedHPAgreements,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
