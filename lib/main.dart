import 'dart:async';

import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';

import 'package:fast_delivery/presentation/common/connectivity_wrapper.dart';
import 'package:fast_delivery/presentation/common/error_boundary.dart';
import 'package:flutter/foundation.dart';
import 'package:fast_delivery/core/router/app_router.dart';
import 'package:fast_delivery/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fast_delivery/core/config/mapbox_init_stub.dart'
    if (dart.library.io) 'package:fast_delivery/core/config/mapbox_init_mobile.dart'
    if (dart.library.html) 'package:fast_delivery/core/config/mapbox_init_web.dart';

void main() async {
  // Wrap entire app in error zone
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    MapboxInit.init();
    
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
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }

    runApp(const ProviderScope(child: FastDeliveryApp()));
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

class FastDeliveryApp extends ConsumerStatefulWidget {
  const FastDeliveryApp({super.key});

  @override
  ConsumerState<FastDeliveryApp> createState() => _FastDeliveryAppState();
}

class _FastDeliveryAppState extends ConsumerState<FastDeliveryApp> {
  @override
  void initState() {
    super.initState();
    // Initialize Analytics and Crashlytics
    // ref.read(analyticsServiceProvider).initialize();
    
    // Initialize Notification Service
    if (!kIsWeb) {
      ref.read(notificationServiceProvider).initialize();
    }
    
    // Log app open event
    // ref.read(analyticsServiceProvider).logAppOpen();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Fast Delivery',
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

