import 'dart:async';
import 'package:flutter/material.dart';

/// Retry logic for failed network requests
class RetryHelper {
  /// Execute a function with exponential backoff retry logic
  /// 
  /// [fn] - The async function to retry
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay in milliseconds (default: 1000ms)
  /// [maxDelay] - Maximum delay between retries (default: 10000ms)
  /// [onRetry] - Optional callback fired on each retry attempt
  static Future<T> exponentialBackoff<T>({
    required Future<T> Function() fn,
    int maxRetries = 3,
    int initialDelay = 1000,
    int maxDelay = 10000,
    void Function(int attempt, Duration delay)? onRetry,
  }) async {
    int attempt = 0;
    Duration delay = Duration(milliseconds: initialDelay);

    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        
        if (attempt > maxRetries) {
          debugPrint('Max retries ($maxRetries) exceeded. Last error: $e');
          rethrow;
        }

        debugPrint('Retry attempt $attempt/$maxRetries after ${delay.inMilliseconds}ms. Error: $e');
        onRetry?.call(attempt, delay);
        
        await Future.delayed(delay);
        
        // Exponential backoff: double the delay, but cap at maxDelay
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2).clamp(initialDelay, maxDelay),
        );
      }
    }
  }

  /// Retry with linear backoff (constant delay between retries)
  static Future<T> linearBackoff<T>({
    required Future<T> Function() fn,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
    void Function(int attempt)? onRetry,
  }) async {
    int attempt = 0;

    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        
        if (attempt > maxRetries) {
          debugPrint('Max retries ($maxRetries) exceeded. Last error: $e');
          rethrow;
        }

        debugPrint('Retry attempt $attempt/$maxRetries. Error: $e');
        onRetry?.call(attempt);
        
        await Future.delayed(delay);
      }
    }
  }
}

/// Queue for actions that should be retried when connection is restored
class OfflineActionQueue {
  final List<Future<void> Function()> _queue = [];

  /// Add an action to the queue
  void enqueue(Future<void> Function() action) {
    _queue.add(action);
    debugPrint('Action enqueued. Queue size: ${_queue.length}');
  }

  /// Process all queued actions
  Future<void> processQueue() async {
    if (_queue.isEmpty) return;

    debugPrint('Processing ${_queue.length} queued actions...');
    final actions = List<Future<void> Function()>.from(_queue);
    _queue.clear();

    for (final action in actions) {
      try {
        await action();
      } catch (e) {
        debugPrint('Error processing queued action: $e');
        // Re-queue failed actions
        _queue.add(action);
      }
    }

    if (_queue.isNotEmpty) {
      debugPrint('${_queue.length} actions failed and re-queued');
    }
  }

  /// Check if queue has pending actions
  bool get hasPendingActions => _queue.isNotEmpty;

  /// Get number of pending actions
  int get pendingCount => _queue.length;

  /// Clear all pending actions
  void clear() {
    _queue.clear();
    debugPrint('Queue cleared');
  }
}
