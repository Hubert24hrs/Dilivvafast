import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Stub admin service
class AdminService {
  AdminService(this._firestore);

  // ignore: unused_field
  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>> getDashboardStats() async {
    debugPrint('AdminService.getDashboardStats (stub)');
    return {
      'totalUsers': 0,
      'totalDrivers': 0,
      'totalRides': 0,
      'totalRevenue': 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    debugPrint('AdminService.getAllUsers (stub)');
    return [];
  }
}
