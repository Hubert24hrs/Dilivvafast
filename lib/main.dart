import 'dart:async';

import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/services/analytics_service.dart';

import 'package:dilivvafast/core/presentation/components/connectivity_wrapper.dart';
import 'package:dilivvafast/core/presentation/components/error_boundary.dart';
import 'package:flutter/foundation.dart';
import 'package:dilivvafast/core/presentation/routing/app_router.dart';
import 'package:dilivvafast/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dilivvafast/core/config/mapbox_init_stub.dart'
    if (dart.library.io) 'package:dilivvafast/core/config/mapbox_init_mobile.dart'
    if (dart.library.html) 'package:dilivvafast/core/config/mapbox_init_web.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dilivvafast/core/infrastructure/notification/fcm_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  // Register FCM background message handler (must be before runApp)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Wrap entire app in error zone
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    MapboxInit.init();
    
    // Initialize Hive for local storage
    await Hive.initFlutter();
    
    // Set up global error handlers
    _setupErrorHandlers();
    
    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Could not load .env file: $e");
    }
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Request FCM notification permissions
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }

    runApp(const ProviderScope(child: DilivvafastApp()));
  }, (error, stackTrace) {
    // Handled by Crashlytics in AnalyticsService
    debugPrint('Uncaught async error: $error');
  });
}

/// Set up global error handlers (now handled by AnalyticsService)
void _setupErrorHandlers() {
  // Error handling is now managed by AnalyticsService.initialize()
  // which sets up Crashlytics integration
  
  // Override error widget for release mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    return GlobalErrorWidget(errorDetails: details);
  };
}

class DilivvafastApp extends ConsumerStatefulWidget {
  const DilivvafastApp({super.key});

  @override
  ConsumerState<DilivvafastApp> createState() => _DilivvafastAppState();
}

class _DilivvafastAppState extends ConsumerState<DilivvafastApp> {
  @override
  void initState() {
    super.initState();
    // Initialize Analytics and Crashlytics
    ref.read(analyticsServiceProvider).initialize();
    
    // Initialize Notification Service
    if (!kIsWeb) {
      ref.read(notificationServiceProvider).initialize();
    }
    
    // Log app open event
    ref.read(analyticsServiceProvider).logAppOpen();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Dilivvafast',
      theme: AppTheme.futuristicTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Wrap with error boundary for additional protection
        return ErrorBoundary(
          child: ConnectivityWrapper(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

