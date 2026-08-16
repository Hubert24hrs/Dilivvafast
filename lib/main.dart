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

// Global flag — set to true only after Firebase.initializeApp() succeeds.
bool _firebaseReady = false;

void main() async {
  // MUST be first — initialises Flutter engine bindings before any plugin/channel calls.
  WidgetsFlutterBinding.ensureInitialized();

  // Wrap entire app in error zone.
  runZonedGuarded(() async {
    MapboxInit.init();

    // Initialise Hive for local storage.
    await Hive.initFlutter();

    // Set up global error handlers (Crashlytics wired in later after Firebase init).
    _setupPreFirebaseErrorHandlers();

    // Load environment variables.
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Could not load .env file: $e');
    }

    // -----------------------------------------------------------------------
    // Firebase initialisation — MUST NOT be silent on failure.
    // If this fails the app has no auth, Firestore, or FCM backend.
    // We show a blocking error screen instead of proceeding silently.
    // -----------------------------------------------------------------------
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseReady = true;

      // REMOVE AFTER VERIFYING iOS AUTH — temporary diagnostic log
      // ignore: avoid_print
      if (kDebugMode) {
        debugPrint(
          '[Dilivvafast] Firebase ready — iOS options: '
          '${DefaultFirebaseOptions.currentPlatform.appId}',
        );
      }

      // Register FCM background message handler AFTER Firebase is ready.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request FCM notification permissions.
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e, stack) {
      // Firebase init failed — do NOT proceed with a broken backend.
      // Log the error then show a non-dismissable error screen.
      debugPrint('[Dilivvafast] Firebase initialization FAILED: $e\n$stack');
      _firebaseReady = false;
    }

    runApp(
      ProviderScope(
        child: _firebaseReady
            ? const DilivvafastApp()
            : const _FirebaseInitErrorApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('[Dilivvafast] Uncaught async error: $error');
  });
}

/// Set up Flutter and platform error handlers before Firebase is available.
/// Crashlytics integration is added later in [AnalyticsService.initialize].
void _setupPreFirebaseErrorHandlers() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    return GlobalErrorWidget(errorDetails: details);
  };
}

// ---------------------------------------------------------------------------
// App root — only rendered when Firebase is ready
// ---------------------------------------------------------------------------

class DilivvafastApp extends ConsumerStatefulWidget {
  const DilivvafastApp({super.key});

  @override
  ConsumerState<DilivvafastApp> createState() => _DilivvafastAppState();
}

class _DilivvafastAppState extends ConsumerState<DilivvafastApp> {
  /// Whether FCM has been registered for the currently signed-in user.
  String? _fcmRegisteredFor;

  @override
  void initState() {
    super.initState();
    // Initialise Analytics and Crashlytics (safe — Firebase is ready here).
    ref.read(analyticsServiceProvider).initialize();

    // Log app open event.
    ref.read(analyticsServiceProvider).logAppOpen();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Register for push notifications once we actually have a signed-in user.
    //
    // This used to run in initState, where currentUserProvider is still
    // loading, so it always took the "no authenticated user" branch and no
    // fcmToken was ever written. Without a token every server-side
    // notification — new order, driver accepted, delivered — silently went
    // nowhere. Watching auth state means it fires on sign-in, and again after
    // a sign-out/sign-in as a different account.
    if (!kIsWeb) {
      ref.listen(currentUserProvider, (previous, next) {
        final user = next.value;
        if (user == null) {
          _fcmRegisteredFor = null;
          return;
        }
        if (_fcmRegisteredFor == user.uid) return;
        _fcmRegisteredFor = user.uid;
        ref.read(notificationServiceProvider).initialize();
      });
    }

    return MaterialApp.router(
      title: 'Dilivvafast',
      theme: AppTheme.cleanDarkTheme,
      darkTheme: AppTheme.cleanDarkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ErrorBoundary(
          child: ConnectivityWrapper(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Blocking error app — shown when Firebase init fails
// ---------------------------------------------------------------------------

class _FirebaseInitErrorApp extends StatelessWidget {
  const _FirebaseInitErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const _FirebaseInitErrorScreen(),
    );
  }
}

class _FirebaseInitErrorScreen extends StatelessWidget {
  const _FirebaseInitErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 72,
                color: Color(0xFFFF6B00),
              ),
              const SizedBox(height: 24),
              const Text(
                'Service Unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Dilivvafast could not connect to its backend services.\n\n'
                'Please check your internet connection and try again, '
                'or update the app if a newer version is available.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // Restart the app by re-running main.
                  // On mobile this triggers a hot restart equivalent through
                  // the platform channel — simplest UX for the user.
                  main();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
