import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final String role; // 'user', 'driver', 'admin'
  final String? homeAddress;
  final String? workAddress;
  final double walletBalance;
  final String? fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.role = 'user',
    this.walletBalance = 0.0,
    this.homeAddress,
    this.workAddress,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
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

    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'user',
      walletBalance: (data['walletBalance'] is int) 
          ? (data['walletBalance'] as int).toDouble() 
          : (data['walletBalance'] ?? 0.0).toDouble(),
      homeAddress: data['homeAddress'],
      workAddress: data['workAddress'],
      fcmToken: data['fcmToken'],
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role,
      'walletBalance': walletBalance,
      'homeAddress': homeAddress,
      'workAddress': workAddress,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
