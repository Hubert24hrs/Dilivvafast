import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to monitor network connectivity status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get connectivityStream => 
      _connectivity.onConnectivityChanged;

  /// Check current connectivity status
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) || 
           result.contains(ConnectivityResult.wifi) ||
           result.contains(ConnectivityResult.ethernet);
  }

  /// Check if device has active internet (not just WiFi connected)
  Future<bool> hasInternetConnection() async {
    try {
      final isConnected = await this.isConnected();
      if (!isConnected) return false;
      
      // Could add additional ping/HTTP check here if needed
      return true;
    } catch (e) {
      debugPrint('Error checking internet connection: $e');
      return false;
    }
  }
}

/// Provider for ConnectivityService
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provider for connectivity status stream
final connectivityStatusProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});

/// Provider to check if currently connected
final isConnectedProvider = FutureProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isConnected();
});
