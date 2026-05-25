import 'package:flutter/foundation.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/utils/role_guard.dart';
import 'package:fast_delivery/core/utils/router_utils.dart';
import 'package:fast_delivery/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:fast_delivery/presentation/screens/auth/login_screen.dart';
import 'package:fast_delivery/presentation/screens/common/location_picker_screen.dart';
import 'package:fast_delivery/presentation/screens/booking/destination_search_screen.dart';
import 'package:fast_delivery/presentation/screens/chat/chat_screen.dart';
import 'package:fast_delivery/presentation/screens/courier/courier_screen.dart';
import 'package:fast_delivery/presentation/screens/courier/courier_tracking_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_dashboard_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_mode_selection_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_navigation_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_pending_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_registration_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_earnings_screen.dart';
import 'package:fast_delivery/presentation/screens/driver/driver_reviews_screen.dart';
import 'package:fast_delivery/presentation/screens/profile/favorite_drivers_screen.dart';
import 'package:fast_delivery/presentation/screens/history/history_details_screen.dart';
import 'package:fast_delivery/presentation/screens/history/history_screen.dart';
import 'package:fast_delivery/presentation/screens/home/home_screen.dart';
import 'package:fast_delivery/presentation/screens/map/map_screen.dart';
import 'package:fast_delivery/presentation/screens/profile/profile_screen.dart';
import 'package:fast_delivery/presentation/screens/promo/promo_screen.dart';
import 'package:fast_delivery/presentation/screens/referral/referral_screen.dart';
import 'package:fast_delivery/presentation/screens/schedule/schedule_ride_screen.dart';
import 'package:fast_delivery/presentation/screens/settings/settings_screen.dart';
import 'package:fast_delivery/presentation/screens/splash/splash_screen.dart';
import 'package:fast_delivery/presentation/screens/tracking/tracking_screen.dart';
import 'package:fast_delivery/presentation/screens/wallet/add_card_screen.dart';
import 'package:fast_delivery/presentation/screens/wallet/transaction_history_screen.dart';
import 'package:fast_delivery/presentation/screens/wallet/wallet_screen.dart';
import 'package:fast_delivery/presentation/screens/investor/investor_onboarding_screen.dart';
import 'package:fast_delivery/presentation/screens/investor/investor_dashboard_screen.dart';
import 'package:fast_delivery/presentation/screens/investor/fund_bike_screen.dart';
import 'package:fast_delivery/presentation/screens/investor/bike_detail_screen.dart';
import 'package:fast_delivery/presentation/screens/investor/investor_earnings_screen.dart';
import 'package:fast_delivery/presentation/screens/investor/investor_withdraw_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRoleAsync = ref.watch(currentUserRoleProvider);
  // Extract role from AsyncValue - null if loading or error
  final userRole = userRoleAsync.when(
    data: (role) => role,
    loading: () => null,
    error: (_, __) => null,
  );

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authState.isLoading ? null : GoRouterRefreshStream(ref.watch(authServiceProvider).authStateChanges),
    redirect: (context, state) {
      if (authState.isLoading || authState.hasError) return null;

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.path == '/login';
      final isSplash = state.uri.path == '/splash';
      final currentPath = state.uri.path;

      if (isSplash) {
        return null; // Let splash handle its own navigation
      }

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      // Role-based route protection
      if (isLoggedIn && userRole != null) {
        final roleRedirect = RoleGuard.getRedirectPath(
          userRole: userRole,
          attemptedPath: currentPath,
        );
        if (roleRedirect != null) {
          return roleRedirect;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/location-picker',
        builder: (context, state) => const LocationPickerScreen(),
      ),
      GoRoute(
        path: '/destination',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return DestinationSearchScreen(
            preferredDriverId: extra?['preferredDriverId'],
            preferredDriverName: extra?['preferredDriverName'],
          );
        },
      ),
      GoRoute(
        path: '/courier',
        builder: (context, state) => const CourierScreen(),
      ),
      GoRoute(
        path: '/courier-tracking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          // Support both extra (for in-app navigation) and query params (for web URL persistence)
          final courierId = extra?['courierId'] ?? state.uri.queryParameters['courierId'];
          return CourierTrackingScreen(courierId: courierId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
        routes: [
          GoRoute(
            path: 'add-card',
            builder: (context, state) => const AddCardScreen(),
          ),
          GoRoute(
            path: 'transactions',
            builder: (context, state) => const TransactionHistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/promo',
        builder: (context, state) => const PromoScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ScheduleRideScreen(rideDetails: extra);
        },
      ),
      GoRoute(
        path: '/driver-selection',
        builder: (context, state) => const DriverModeSelectionScreen(),
      ),
      GoRoute(
        path: '/driver-registration',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'driver';
          return DriverRegistrationScreen(type: type);
        },
      ),
      GoRoute(
        path: '/driver-pending',
        builder: (context, state) => const DriverPendingScreen(),
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverDashboardScreen(),
      ),
      GoRoute(
        path: '/tracking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          // Support both extra (for in-app navigation) and query params (for web URL persistence)
          final rideId = extra?['rideId'] ?? state.uri.queryParameters['rideId'];
          final destinationName = extra?['destinationName'] ?? state.uri.queryParameters['dest'];
          debugPrint('Router /tracking: rideId=$rideId, from extra=${extra?['rideId']}, from query=${state.uri.queryParameters['rideId']}');
          return TrackingScreen(
            destinationName: destinationName,
            rideId: rideId,
          );
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          debugPrint('Chat route - extra: $extra');
          debugPrint('Chat route - rideId: ${extra?['rideId']}');
          debugPrint('Chat route - otherUserName: ${extra?['otherUserName']}');
          return ChatScreen(
            rideId: extra?['rideId'],
            otherUserName: extra?['otherUserName'],
          );
        },
      ),
      GoRoute(
        path: '/destination-search',
        builder: (context, state) => const DestinationSearchScreen(),
      ),
      GoRoute(
        path: '/driver-navigation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return DriverNavigationScreen(
            ride: extra?['ride'],
            courier: extra?['courier'],
          );
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
        routes: [
          GoRoute(
            path: 'details',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return HistoryDetailsScreen(
                ride: extra?['ride'],
                courier: extra?['courier'],
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/driver-earnings',
        builder: (context, state) => const DriverEarningsScreen(),
      ),
      GoRoute(
        path: '/driver-reviews',
        builder: (context, state) => const DriverReviewsScreen(),
      ),
      GoRoute(
        path: '/favorite-drivers',
        builder: (context, state) => const FavoriteDriversScreen(),
      ),
      // ==================== INVESTOR ROUTES ====================
      GoRoute(
        path: '/investor',
        builder: (context, state) => const InvestorDashboardScreen(),
      ),
      GoRoute(
        path: '/investor/onboarding',
        builder: (context, state) => const InvestorOnboardingScreen(),
      ),
      GoRoute(
        path: '/investor/dashboard',
        builder: (context, state) => const InvestorDashboardScreen(),
      ),
      GoRoute(
        path: '/investor/fund-bike',
        builder: (context, state) => const FundBikeScreen(),
      ),
      GoRoute(
        path: '/investor/earnings',
        builder: (context, state) => const InvestorEarningsScreen(),
      ),
      GoRoute(
        path: '/investor/withdraw',
        builder: (context, state) => const InvestorWithdrawScreen(),
      ),
      GoRoute(
        path: '/investor/bike/:bikeId',
        builder: (context, state) {
          final bikeId = state.pathParameters['bikeId']!;
          debugPrint('Investor bike detail: bikeId=$bikeId');
          return BikeDetailScreen(bikeId: bikeId);
        },
      ),
    ],
  );
});
