import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global provider for [AnalyticsService].
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Centralized analytics & crash-reporting service.
///
/// Wraps Firebase Analytics and Crashlytics behind a single facade
/// so the rest of the app never touches raw Firebase APIs directly.
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseCrashlytics? _crashlytics;

  /// Initialise Crashlytics error handlers.
  ///
  /// Call once in `initState` of the root widget (or in `main`).
  void initialize() {
    if (kIsWeb) return; // Crashlytics is not available on web

    _crashlytics = FirebaseCrashlytics.instance;

    // Pass all uncaught Flutter errors to Crashlytics
    FlutterError.onError = _crashlytics!.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics!.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Set the current user ID on both Analytics and Crashlytics.
  void setUserId(String userId) {
    _analytics.setUserId(id: userId);
    _crashlytics?.setUserIdentifier(userId);
  }

  /// Log the standard `app_open` event.
  Future<void> logAppOpen() => _analytics.logAppOpen();

  /// Log a screen view event.
  Future<void> logScreenView(String screenName) {
    return _analytics.logScreenView(screenName: screenName);
  }

  /// Log a custom event with optional parameters.
  Future<void> logEvent(String name, [Map<String, Object>? params]) {
    return _analytics.logEvent(name: name, parameters: params);
  }

  /// Log a purchase / booking event.
  Future<void> logPurchase({
    required double amount,
    required String currency,
    String? orderId,
  }) {
    return _analytics.logPurchase(
      value: amount,
      currency: currency,
      transactionId: orderId,
    );
  }

  /// Record a non-fatal error in Crashlytics.
  void recordError(dynamic error, StackTrace? stack, {String? reason}) {
    _crashlytics?.recordError(error, stack, reason: reason ?? 'non-fatal');
  }

  /// Add a breadcrumb log to Crashlytics for debugging.
  void log(String message) {
    _crashlytics?.log(message);
  }
}
