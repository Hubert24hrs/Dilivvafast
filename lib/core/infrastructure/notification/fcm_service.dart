import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — must be top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint('FCM background message: ${message.messageId}');
}

/// The screen a notification should open, from the `type` and `orderId` the
/// Cloud Functions put in its data payload. Null means "just open the app".
///
/// Kept as a pure function so the mapping is unit-tested; it must stay in
/// step with the `type` values sent from functions/src/index.ts.
String? notificationRouteFor(Map<String, dynamic> data) {
  final type = data['type'] as String?;
  final orderId = data['orderId'] as String?;
  final hasOrder = orderId != null && orderId.isNotEmpty;
  return switch (type) {
    'new_order' => '/driver/home',
    'new_bid' when hasOrder => '/matching/$orderId',
    'bid_accepted' when hasOrder => '/driver/active/$orderId',
    'order_update' when hasOrder => '/customer/track/$orderId',
    'referral_bonus' => '/customer/wallet',
    'weekly_report' => '/driver/earnings',
    'sos_alert' => '/admin/dashboard',
    'support_reply' => '/support-chat',
    'support_message' when (data['userId'] as String? ?? '').isNotEmpty =>
      '/admin/support/${data['userId']}',
    _ => null,
  };
}

/// Service for Firebase Cloud Messaging push notifications.
class FCMService {
  FCMService({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    this.onOpenRoute,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  /// Navigates to a route. Supplied by the provider so this service does not
  /// depend on the router directly.
  final void Function(String route)? onOpenRoute;

  /// initialize() runs on every sign-in. Without this guard each sign-in
  /// added another set of listeners and every push arrived twice.
  bool _listening = false;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel
  static const _androidChannel = AndroidNotificationChannel(
    'dilivvafast_default',
    'Dilivvafast Notifications',
    description: 'Default notification channel for Dilivvafast',
    importance: Importance.high,
    playSound: true,
  );

  /// Initialize FCM and local notifications
  Future<void> initialize(String userId) async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      debugPrint('FCM: User declined notification permission');
      return;
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get and save FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(userId, token);
    }

    _currentUserId = userId;
    if (!_listening) {
      _listening = true;

      // Listen for token refresh — saved for whoever is signed in now.
      _messaging.onTokenRefresh.listen((newToken) {
        final uid = _currentUserId;
        if (uid != null) _saveToken(uid, newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap (when app is in background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    }

    // Check for initial message (app opened via notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('FCM: Initialized with token $token');
  }

  /// Initialize flutter_local_notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        // A tap on a notification shown while the app was in the foreground.
        final payload = response.payload;
        if (payload == null) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _open(data);
        } catch (e) {
          debugPrint('FCM: bad local notification payload: $e');
        }
      },
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  /// Handle foreground message — show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  String? _currentUserId;

  /// Handle notification tap (app opened from background or terminated).
  void _handleNotificationTap(RemoteMessage message) => _open(message.data);

  void _open(Map<String, dynamic> data) {
    final route = notificationRouteFor(data);
    if (route == null) return;
    // On a cold start the router may still be settling; defer one frame.
    Future<void>.delayed(Duration.zero, () => onOpenRoute?.call(route));
  }

  /// Save FCM token to Firestore
  Future<void> _saveToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FCM: Error saving token: $e');
    }
  }

  /// Unregister — clear token from Firestore (on logout)
  Future<void> unregister(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
