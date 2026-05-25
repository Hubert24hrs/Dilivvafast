import 'package:cloud_firestore/cloud_firestore.dart';

class EarningsModel {
  final String id;
  final String driverId;
  final String rideId;
  final double amount;
  final double platformFee; // Percentage taken by platform
  final double netAmount; // Amount after fee
  final String status; // 'pending', 'available', 'withdrawn'
  final DateTime createdAt;
  final String? withdrawalId;

  EarningsModel({
    required this.id,
    required this.driverId,
    required this.rideId,
    required this.amount,
    this.platformFee = 0.15, // 15% default
    double? netAmount,
    this.status = 'available',
    required this.createdAt,
    this.withdrawalId,
  }) : netAmount = netAmount ?? (amount * (1 - platformFee));

  factory EarningsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EarningsModel(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      rideId: data['rideId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      platformFee: (data['platformFee'] ?? 0.15).toDouble(),
      netAmount: (data['netAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'available',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      withdrawalId: data['withdrawalId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'rideId': rideId,
      'amount': amount,
      'platformFee': platformFee,
      'netAmount': netAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'withdrawalId': withdrawalId,
    };
  }
}

class WithdrawalModel {
  final String id;
  final String driverId;
  final double amount;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String status; // 'pending', 'processing', 'completed', 'failed'
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? reference; // Paystack reference

  WithdrawalModel({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.status = 'pending',
    required this.createdAt,
    this.completedAt,
    this.reference,
  });

  factory WithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawalModel(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      bankName: data['bankName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      accountName: data['accountName'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      reference: data['reference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'amount': amount,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'reference': reference,
    };
  }
}
