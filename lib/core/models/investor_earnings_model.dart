import 'package:cloud_firestore/cloud_firestore.dart';

/// Investor earnings per ride with auto-split tracking
class InvestorEarningsModel {
  final String id;
  final String investorId;
  final String bikeId;
  final String rideId;
  final String? courierId; // For courier deliveries
  final double fareAmount;
  final double investorShare; // 50% during HP
  final double riderShare; // 40% during HP
  final double appFee; // 10% always
  final double hpDeduction; // Amount deducted from HP balance
  final double netToInvestor; // What goes to investor wallet
  final bool hpActive; // Whether HP was active for this ride
  final String splitType; // 'hp_active' or 'hp_complete'
  final DateTime createdAt;

  InvestorEarningsModel({
    required this.id,
    required this.investorId,
    required this.bikeId,
    required this.rideId,
    this.courierId,
    required this.fareAmount,
    required this.investorShare,
    required this.riderShare,
    required this.appFee,
    required this.hpDeduction,
    required this.netToInvestor,
    required this.hpActive,
    required this.splitType,
    required this.createdAt,
  });

  /// Calculate split for HP-active rides (50/40/10)
  factory InvestorEarningsModel.hpActiveSplit({
    required String id,
    required String investorId,
    required String bikeId,
    required String rideId,
    String? courierId,
    required double fareAmount,
  }) {
    final investorShare = fareAmount * 0.50;
    final riderShare = fareAmount * 0.40;
    final appFee = fareAmount * 0.10;
    
    return InvestorEarningsModel(
      id: id,
      investorId: investorId,
      bikeId: bikeId,
      rideId: rideId,
      courierId: courierId,
      fareAmount: fareAmount,
      investorShare: investorShare,
      riderShare: riderShare,
      appFee: appFee,
      hpDeduction: investorShare, // All investor share goes to HP
      netToInvestor: 0, // Nothing to wallet until HP complete
      hpActive: true,
      splitType: 'hp_active',
      createdAt: DateTime.now(),
    );
  }

  /// Calculate split for HP-complete rides (0/90/10 - investor gets nothing)
  factory InvestorEarningsModel.hpCompleteSplit({
    required String id,
    required String investorId,
    required String bikeId,
    required String rideId,
    String? courierId,
    required double fareAmount,
  }) {
    final riderShare = fareAmount * 0.90;
    final appFee = fareAmount * 0.10;
    
    return InvestorEarningsModel(
      id: id,
      investorId: investorId,
      bikeId: bikeId,
      rideId: rideId,
      courierId: courierId,
      fareAmount: fareAmount,
      investorShare: 0,
      riderShare: riderShare,
      appFee: appFee,
      hpDeduction: 0,
      netToInvestor: 0,
      hpActive: false,
      splitType: 'hp_complete',
      createdAt: DateTime.now(),
    );
  }

  factory InvestorEarningsModel.fromFirestore(DocumentSnapshot doc) {
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

    return InvestorEarningsModel(
      id: doc.id,
      investorId: data['investorId'] ?? '',
      bikeId: data['bikeId'] ?? '',
      rideId: data['rideId'] ?? '',
      courierId: data['courierId'],
      fareAmount: (data['fareAmount'] ?? 0.0).toDouble(),
      investorShare: (data['investorShare'] ?? 0.0).toDouble(),
      riderShare: (data['riderShare'] ?? 0.0).toDouble(),
      appFee: (data['appFee'] ?? 0.0).toDouble(),
      hpDeduction: (data['hpDeduction'] ?? 0.0).toDouble(),
      netToInvestor: (data['netToInvestor'] ?? 0.0).toDouble(),
      hpActive: data['hpActive'] ?? true,
      splitType: data['splitType'] ?? 'hp_active',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'investorId': investorId,
      'bikeId': bikeId,
      'rideId': rideId,
      'courierId': courierId,
      'fareAmount': fareAmount,
      'investorShare': investorShare,
      'riderShare': riderShare,
      'appFee': appFee,
      'hpDeduction': hpDeduction,
      'netToInvestor': netToInvestor,
      'hpActive': hpActive,
      'splitType': splitType,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Investor withdrawal model
class InvestorWithdrawalModel {
  final String id;
  final String investorId;
  final double amount;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String status; // 'pending', 'processing', 'completed', 'failed'
  final String? paystackReference;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? completedAt;

  InvestorWithdrawalModel({
    required this.id,
    required this.investorId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.status = 'pending',
    this.paystackReference,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
  });

  factory InvestorWithdrawalModel.fromFirestore(DocumentSnapshot doc) {
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

    DateTime? parsedCompletedAt;
    if (data['completedAt'] != null) {
      try {
        if (data['completedAt'] is Timestamp) {
          parsedCompletedAt = (data['completedAt'] as Timestamp).toDate();
        } else if (data['completedAt'] is String) {
          parsedCompletedAt = DateTime.parse(data['completedAt']);
        }
      } catch (e) {
        parsedCompletedAt = null;
      }
    }

    return InvestorWithdrawalModel(
      id: doc.id,
      investorId: data['investorId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      bankName: data['bankName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      accountName: data['accountName'] ?? '',
      status: data['status'] ?? 'pending',
      paystackReference: data['paystackReference'],
      failureReason: data['failureReason'],
      createdAt: parsedCreatedAt,
      completedAt: parsedCompletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'investorId': investorId,
      'amount': amount,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'status': status,
      'paystackReference': paystackReference,
      'failureReason': failureReason,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
