import 'package:flutter/material.dart';
import 'package:firebase_performance/firebase_performance.dart';

/// Service for monitoring app performance
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final FirebasePerformance _performance = FirebasePerformance.instance;
  final Map<String, Trace> _activeTraces = {};

  /// Initialize performance monitoring
  Future<void> initialize() async {
    try {
      await _performance.setPerformanceCollectionEnabled(true);
      debugPrint('PerformanceService: Initialized successfully');
    } catch (e) {
      debugPrint('PerformanceService: Error initializing - $e');
    }
  }

  /// Start a custom trace
  Future<void> startTrace(String traceName) async {
    try {
      if (_activeTraces.containsKey(traceName)) {
        debugPrint('PerformanceService: Trace $traceName already active');
        return;
      }

      final trace = _performance.newTrace(traceName);
      await trace.start();
      _activeTraces[traceName] = trace;
      
      debugPrint('PerformanceService: Started trace - $traceName');
    } catch (e) {
      debugPrint('PerformanceService: Error starting trace - $e');
    }
  }

  /// Stop a custom trace
  Future<void> stopTrace(String traceName) async {
    try {
      final trace = _activeTraces.remove(traceName);
      if (trace == null) {
        debugPrint('PerformanceService: Trace $traceName not found');
        return;
      }

      await trace.stop();
      debugPrint('PerformanceService: Stopped trace - $traceName');
    } catch (e) {
      debugPrint('PerformanceService: Error stopping trace - $e');
    }
  }

  /// Add metric to active trace
  Future<void> setMetric(String traceName, String metricName, int value) async {
    try {
      final trace = _activeTraces[traceName];
      if (trace == null) {
        debugPrint('PerformanceService: Trace $traceName not found');
        return;
      }

      trace.setMetric(metricName, value);
    } catch (e) {
      debugPrint('PerformanceService: Error setting metric - $e');
    }
  }

  /// Add attribute to active trace
  Future<void> setAttribute(String traceName, String attributeName, String value) async {
    try {
      final trace = _activeTraces[traceName];
      if (trace == null) {
        debugPrint('PerformanceService: Trace $traceName not found');
        return;
      }

      trace.putAttribute(attributeName, value);
    } catch (e) {
      debugPrint('PerformanceService: Error setting attribute - $e');
    }
  }

  /// Measure async operation
  Future<T> measureAsync<T>(
    String traceName,
    Future<T> Function() operation,
  ) async {
    await startTrace(traceName);
    
    try {
      final result = await operation();
      await stopTrace(traceName);
      return result;
    } catch (e) {
      await stopTrace(traceName);
      rethrow;
    }
  }

  /// Measure screen rendering time
  Future<void> measureScreenLoad(String screenName, VoidCallback onComplete) async {
    final traceName = 'screen_load_$screenName';
    await startTrace(traceName);
    
    // Screen load completed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await stopTrace(traceName);
      onComplete();
    });
  }

  // ==================== Predefined Traces ====================

  /// Track ride booking performance
  Future<void> startRideBookingTrace() async {
    await startTrace('ride_booking');
  }

  Future<void> stopRideBookingTrace() async {
    await stopTrace('ride_booking');
  }

  /// Track payment processing performance
  Future<void> startPaymentTrace() async {
    await startTrace('payment_processing');
  }

  Future<void> stopPaymentTrace() async {
    await stopTrace('payment_processing');
  }

  /// Track map loading performance
  Future<void> startMapLoadTrace() async {
    await startTrace('map_load');
  }

  Future<void> stopMapLoadTrace() async {
    await stopTrace('map_load');
  }

  /// Track image upload performance
  Future<void> startImageUploadTrace() async {
    await startTrace('image_upload');
  }

  Future<void> stopImageUploadTrace() async {
    await stopTrace('image_upload');
  }

  /// Get all active traces (for debugging)
  List<String> getActiveTraces() {
    return _activeTraces.keys.toList();
  }
}
