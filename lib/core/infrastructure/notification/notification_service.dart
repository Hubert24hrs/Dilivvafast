import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dilivvafast/core/infrastructure/notification/fcm_service.dart';
import 'package:dilivvafast/core/providers/providers.dart';

/// Notification service — wired to FCMService for production push notifications.
class NotificationService {
  NotificationService(this._ref);

  final Ref _ref;
  FCMService? _fcmService;

  Future<void> initialize() async {
    try {
      final user = _ref.read(currentUserProvider).value;
      if (user == null) {
        debugPrint('NotificationService: No authenticated user, skipping FCM init');
        return;
      }

      _fcmService = _ref.read(fcmServiceProvider);
      await _fcmService!.initialize(user.uid);
      debugPrint('NotificationService: FCM initialized for ${user.uid}');
    } catch (e) {
      debugPrint('NotificationService: FCM init failed: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('Local notification: $title - $body');
  }

  /// Call on logout to clear FCM token
  Future<void> unregister(String userId) async {
    try {
      await _fcmService?.unregister(userId);
    } catch (e) {
      debugPrint('NotificationService: Unregister failed: $e');
    }
  }
}
