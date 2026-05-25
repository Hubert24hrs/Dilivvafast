import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Ref _ref;

  NotificationService(this._ref);

  Future<void> initialize() async {
    try {
      // 1. Request Permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
        
        // 2. Setup Local Notifications
        await _setupLocalNotifications();

        // 3. Get Token
        String? token = await _messaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          _saveToken(token);
        }

        // 4. Handle Foreground Messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          debugPrint('Message data: ${message.data}');

          if (message.notification != null) {
            _showLocalNotification(message);
          }
        });

        // 5. Handle Background/Terminated Taps
        _setupInteractedMessage();
        
        // 6. Set Background Handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // 7. Listen for Token Refresh
        _messaging.onTokenRefresh.listen(_saveToken);

      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false, 
          requestBadgePermission: false, 
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = json.decode(response.payload!);
          _handleNotificationTap(data);
        }
      },
    );

    // Create Android Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00E676), // Green accent
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      // Reuse the public method but keep null safety checks
      await showLocalNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        payload: json.encode(message.data),
      );
    }
  }

  Future<void> _setupInteractedMessage() async {
    // Get any messages which caused the application to open from a terminated state.
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    _handleNotificationTap(message.data);
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Use the router from the provider to navigate
    final router = _ref.read(routerProvider);
    
    if (data['type'] == 'chat') {
      if (data['rideId'] != null) {
        router.push('/chat', extra: {
          'rideId': data['rideId'],
          'otherUserName': 'User', // You might want to pass this in data too
        });
      }
    } else if (data['type'] == 'ride_update') {
       // Navigate to ride details or map based on status
       // If status is completed, maybe go to rating
       final _ = data['status'];
       // For now, push to home which will redirect to active ride automatically
       router.push('/');
    }
  }

  Future<void> _saveToken(String token) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      debugPrint('Saving FCM Token to Firestore...');
      await _ref.read(databaseServiceProvider).saveFcmToken(user.uid, token);
    } else {
      debugPrint('User not logged in, cannot save token yet.');
    }
  }

  // For testing purposes only
  Future<void> testNotification() async {
    await showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test local notification confirming configuration works.',
      payload: json.encode({'type': 'test'}),
    );
  }

  // Ride status update notifications
  Future<void> notifyRideStatusUpdate({
    required String rideId,
    required String status,
    String? driverName,
    String? driverPhone,
  }) async {
    String title;
    String body;

    switch (status) {
      case 'accepted':
        title = '🚗 Driver Found!';
        body = '${driverName ?? "A driver"} has accepted your ride request.';
        break;
      case 'arrived':
        title = '📍 Driver Arrived';
        body = 'Your driver has arrived at the pickup location.';
        break;
      case 'in_progress':
      case 'ongoing':
        title = '🚀 Trip Started';
        body = 'Your trip is now in progress. Enjoy your ride!';
        break;
      case 'completed':
        title = '✅ Trip Completed';
        body = 'Thanks for riding with Fast Delivery! Rate your trip.';
        break;
      case 'cancelled':
        title = '❌ Ride Cancelled';
        body = 'Your ride has been cancelled.';
        break;
      default:
        title = 'Ride Update';
        body = 'Your ride status has been updated to: $status';
    }

    await showLocalNotification(
      title: title,
      body: body,
      payload: json.encode({
        'type': 'ride_update',
        'rideId': rideId,
        'status': status,
      }),
    );
  }

  // Driver arrival alert with vibration/sound emphasis
  Future<void> notifyDriverArrival({
    required String rideId,
    required String driverName,
    String? vehicleInfo,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'driver_arrival_channel',
      'Driver Arrival Alerts',
      channelDescription: 'Alerts when your driver arrives',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00E676),
      playSound: true,
      enableVibration: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        sound: 'default',
      ),
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      '📍 Your Driver Has Arrived!',
      '$driverName is waiting for you${vehicleInfo != null ? " in $vehicleInfo" : ""}',
      details,
      payload: json.encode({
        'type': 'driver_arrival',
        'rideId': rideId,
      }),
    );
  }

  // Courier/Delivery status updates
  Future<void> notifyCourierStatusUpdate({
    required String courierId,
    required String status,
    String? deliveryInfo,
  }) async {
    String title;
    String body;

    switch (status) {
      case 'accepted':
        title = '📦 Courier Assigned';
        body = 'A dispatch rider has been assigned to your delivery.';
        break;
      case 'arrived':
        title = '📍 Driver Arrived';
        body = 'Your driver has arrived at the pickup location.';
        break;
      case 'in_transit':
        title = '📬 Package Picked Up';
        body = 'Your package has been picked up and is on the way.';
        break;
      case 'picked_up':
        title = '📬 Package Picked Up';
        body = 'Your package has been picked up and is on the way.';
        break;
      case 'delivered':
        title = '✅ Delivery Complete';
        body = 'Your package has been delivered successfully!';
        break;
      case 'cancelled':
        title = '❌ Delivery Cancelled';
        body = 'Your delivery request has been cancelled.';
        break;
      default:
        title = 'Delivery Update';
        body = 'Your delivery status: $status';
    }

    await showLocalNotification(
      title: title,
      body: body,
      payload: json.encode({
        'type': 'courier_update',
        'courierId': courierId,
        'status': status,
      }),
    );
  }

  // New ride request for drivers
  Future<void> notifyNewRideRequest({
    required String rideId,
    required String pickupAddress,
    required double price,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ride_request_channel',
      'New Ride Requests',
      channelDescription: 'Notifications for new ride requests',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00E676),
      playSound: true,
      enableVibration: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      '🚗 New Ride Request!',
      'Pickup: $pickupAddress • ₦${price.toStringAsFixed(0)}',
      details,
      payload: json.encode({
        'type': 'new_ride_request',
        'rideId': rideId,
      }),
    );
  }
  // Investor earnings notification
  Future<void> notifyInvestorEarnings({
    required String bikeId,
    required double amount,
  }) async {
    await showLocalNotification(
      title: '💰 New Earnings Received!',
      body: 'Your bike has generated ₦${amount.toStringAsFixed(0)} in earnings.',
      payload: json.encode({
        'type': 'investor_earnings',
        'bikeId': bikeId,
      }),
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
