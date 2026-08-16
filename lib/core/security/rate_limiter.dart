import 'package:flutter/material.dart';

/// Rate limiter to prevent API abuse
class RateLimiter {
  final Map<String, List<DateTime>> _requestHistory = {};
  final Duration _window;
  final int _maxRequests;

  RateLimiter({
    Duration window = const Duration(minutes: 1),
    int maxRequests = 60,
  }) : _window = window,
       _maxRequests = maxRequests;

  /// Check if request is allowed
  bool isAllowed(String identifier) {
    final now = DateTime.now();
    final history = _requestHistory[identifier] ?? [];

    // Remove old requests outside the window
    history.removeWhere((time) => now.difference(time) > _window);

    // Check if under limit
    if (history.length < _maxRequests) {
      history.add(now);
      _requestHistory[identifier] = history;
      return true;
    }

    debugPrint('RateLimiter: Rate limit exceeded for $identifier');
    return false;
  }

  /// Get remaining requests for identifier
  int getRemainingRequests(String identifier) {
    final now = DateTime.now();
    final history = _requestHistory[identifier] ?? [];

    // Remove old requests
    history.removeWhere((time) => now.difference(time) > _window);

    return _maxRequests - history.length;
  }

  /// Get time until next request allowed
  Duration? getTimeUntilNextRequest(String identifier) {
    final now = DateTime.now();
    final history = _requestHistory[identifier] ?? [];

    if (history.isEmpty) return null;
    if (history.length < _maxRequests) return null;

    // Find oldest request
    final oldest = history.reduce((a, b) => a.isBefore(b) ? a : b);
    final resetTime = oldest.add(_window);

    if (resetTime.isAfter(now)) {
      return resetTime.difference(now);
    }

    return null;
  }

  /// Clear history for identifier
  void clearHistory(String identifier) {
    _requestHistory.remove(identifier);
  }

  /// Clear all history
  void clearAll() {
    _requestHistory.clear();
  }
}

/// Global rate limiters for different services
class AppRateLimiters {
  // API calls
  static final apiCalls = RateLimiter(
    window: const Duration(minutes: 1),
    maxRequests: 60,
  );

  // Authentication attempts
  static final authAttempts = RateLimiter(
    window: const Duration(minutes: 5),
    maxRequests: 5,
  );

  // Payment initiation
  static final payments = RateLimiter(
    window: const Duration(minutes: 1),
    maxRequests: 3,
  );

  // Ride requests
  static final rideRequests = RateLimiter(
    window: const Duration(minutes: 1),
    maxRequests: 10,
  );

  // Image uploads
  static final imageUploads = RateLimiter(
    window: const Duration(minutes: 5),
    maxRequests: 10,
  );
}
