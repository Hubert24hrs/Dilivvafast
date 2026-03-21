import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notification service — stub implementation
class NotificationService {
  NotificationService(this._ref);

  // ignore: unused_field
  final Ref _ref;

  Future<void> initialize() async {
    debugPrint('NotificationService initialized (stub)');
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('Local notification: $title - $body');
  }
}
