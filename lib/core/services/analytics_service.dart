import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for tracking analytics events
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Initialize analytics
  Future<void> initialize() async {
    try {
      // Enable analytics collection
      await _analytics.setAnalyticsCollectionEnabled(true);
      
      debugPrint('AnalyticsService: Initialized successfully');
    } catch (e) {
      debugPrint('AnalyticsService: Error initializing - $e');
    }
  }

  /// Set user ID for analytics
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      debugPrint('AnalyticsService: User ID set to $userId');
    } catch (e) {
      debugPrint('AnalyticsService: Error setting user ID - $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('AnalyticsService: Error setting user property - $e');
    }
  }

  ///Log a custom event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters?.map((key, value) => MapEntry(key, value as Object)),
      );
      debugPrint('AnalyticsService: Event logged - $name ${parameters ?? ""}');
    } catch (e) {
      debugPrint('AnalyticsService: Error logging event - $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('AnalyticsService: Screen view - $screenName');
    } catch (e) {
      debugPrint('AnalyticsService: Error logging screen view - $e');
    }
  }

  // ==================== App Events ====================
  
  Future<void> logAppOpen() async {
    await logEvent('app_open');
  }

  Future<void> logLogin(String method) async {
    await logEvent('login', parameters: {'method': method});
  }

  Future<void> logSignUp(String method) async {
    await logEvent('sign_up', parameters: {'method': method});
  }

  // ==================== Ride Events ====================
  
  Future<void> logRideRequested({
    required String rideType,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    await logEvent('ride_requested', parameters: {
      'ride_type': rideType,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
    });
  }

  Future<void> logRideAccepted(String rideId, String driverId) async {
    await logEvent('ride_accepted', parameters: {
      'ride_id': rideId,
      'driver_id': driverId,
    });
  }

  Future<void> logRideCompleted({
    required String rideId,
    required double fare,
    required int durationMinutes,
    required double distanceKm,
  }) async {
    await logEvent('ride_completed', parameters: {
      'ride_id': rideId,
      'fare': fare,
      'duration_minutes': durationMinutes,
      'distance_km': distanceKm,
      'value': fare, // For revenue tracking
      'currency': 'NGN',
    });
  }

  Future<void> logRideCancelled(String rideId, String reason) async {
    await logEvent('ride_cancelled', parameters: {
      'ride_id': rideId,
      'reason': reason,
    });
  }

  Future<void> logRideRated(String rideId, int rating) async {
    await logEvent('ride_rated', parameters: {
      'ride_id': rideId,
      'rating': rating,
    });
  }

  // ==================== Courier Events ====================
  
  Future<void> logCourierRequested({
    required String packageSize,
    required double estimatedPrice,
  }) async {
    await logEvent('courier_requested', parameters: {
      'package_size': packageSize,
      'estimated_price': estimatedPrice,
    });
  }

  Future<void> logCourierCompleted({
    required String courierId,
    required double price,
  }) async {
    await logEvent('courier_completed', parameters: {
      'courier_id': courierId,
      'price': price,
      'value': price,
      'currency': 'NGN',
    });
  }

  // ==================== Payment Events ====================
  
  Future<void> logPaymentInitiated({
    required String paymentMethod,
    required double amount,
  }) async {
    await logEvent('payment_initiated', parameters: {
      'payment_method': paymentMethod,
      'amount': amount,
      'currency': 'NGN',
    });
  }

  Future<void> logPaymentCompleted({
    required String paymentMethod,
    required double amount,
    required String transactionId,
  }) async {
    await logEvent('payment_completed', parameters: {
      'payment_method': paymentMethod,
      'amount': amount,
      'transaction_id': transactionId,
      'value': amount,
      'currency': 'NGN',
    });
  }

  Future<void> logPaymentFailed({
    required String paymentMethod,
    required double amount,
    required String errorMessage,
  }) async {
    await logEvent('payment_failed', parameters: {
      'payment_method': paymentMethod,
      'amount': amount,
      'error_message': errorMessage,
    });
  }

  // ==================== Driver Events ====================
  
  Future<void> logDriverModeEnabled() async {
    await logEvent('driver_mode_enabled');
  }

  Future<void> logDriverModeDisabled() async {
    await logEvent('driver_mode_disabled');
  }

  Future<void> logDriverEarningsWithdrawn(double amount) async {
    await logEvent('driver_earnings_withdrawn', parameters: {
    });
  }
}


/// Provider for AnalyticsService
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Navigation observer for automatic screen tracking
class AnalyticsNavigationObserver extends NavigatorObserver {
  final AnalyticsService analyticsService;

  AnalyticsNavigationObserver(this.analyticsService);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      analyticsService.logScreenView(route.settings.name!);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name != null) {
      analyticsService.logScreenView(previousRoute!.settings.name!);
    }
  }
}
