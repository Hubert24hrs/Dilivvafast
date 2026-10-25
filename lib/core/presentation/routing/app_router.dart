import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dilivvafast/core/constants/app_constants.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/features/auth/domain/entities/app_mode.dart';
import 'package:dilivvafast/features/auth/domain/entities/user_model.dart';
import 'package:dilivvafast/features/auth/presentation/screens/login_screen.dart';
import 'package:dilivvafast/features/home/presentation/screens/home_screen.dart';

// Phase 2 screens
import 'package:dilivvafast/features/booking/presentation/screens/courier_booking_screen.dart';
import 'package:dilivvafast/features/courier/presentation/screens/tracking_screen.dart';
import 'package:dilivvafast/features/courier/presentation/screens/orders_screen.dart';
import 'package:dilivvafast/features/courier/presentation/screens/chat_screen.dart';
import 'package:dilivvafast/features/payment/presentation/screens/wallet_screen.dart';
import 'package:dilivvafast/features/driver/presentation/screens/driver_home_screen.dart';
import 'package:dilivvafast/features/driver/presentation/screens/driver_active_delivery_screen.dart';
import 'package:dilivvafast/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:dilivvafast/features/admin/presentation/screens/admin_screens.dart';
import 'package:dilivvafast/features/admin/presentation/screens/admin_applications_screen.dart';
import 'package:dilivvafast/features/investor/presentation/screens/investor_screens.dart';
import 'package:dilivvafast/features/profile/presentation/screens/profile_screen.dart';
import 'package:dilivvafast/features/rating/presentation/screens/rating_screen.dart';

// Phase 3 screens
import 'package:dilivvafast/features/auth/presentation/screens/register_screen.dart';
import 'package:dilivvafast/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:dilivvafast/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:dilivvafast/features/notification/presentation/screens/notifications_screen.dart';
import 'package:dilivvafast/features/driver/presentation/screens/driver_application_screen.dart';
import 'package:dilivvafast/features/admin/presentation/screens/admin_promos_screen.dart';
import 'package:dilivvafast/features/admin/presentation/screens/admin_zones_screen.dart';
import 'package:dilivvafast/features/admin/presentation/screens/admin_support_screen.dart';

// Phase 4 screens
import 'package:dilivvafast/features/payment/presentation/screens/top_up_screen.dart';
import 'package:dilivvafast/features/investor/presentation/screens/investor_bike_detail_screen.dart';
import 'package:dilivvafast/features/investor/presentation/screens/investor_join_screen.dart';

// Phase 5 screens
import 'package:dilivvafast/features/profile/presentation/screens/settings_screen.dart';

// Phase 6 screens
import 'package:dilivvafast/features/admin/presentation/screens/admin_analytics_screen.dart';
import 'package:dilivvafast/features/support/presentation/screens/chatbot_screen.dart';

// Phase 7 screens (new)
import 'package:dilivvafast/features/auth/presentation/screens/biometric_setup_screen.dart';
import 'package:dilivvafast/features/driver/presentation/screens/driver_earnings_screen.dart';
import 'package:dilivvafast/features/booking/presentation/screens/matching_screen.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

// Phase 2 drawer screens
import 'package:dilivvafast/features/profile/presentation/screens/saved_addresses_screen.dart';
import 'package:dilivvafast/features/payment/presentation/screens/promotions_screen.dart';
import 'package:dilivvafast/features/referral/presentation/screens/refer_earn_screen.dart';
import 'package:dilivvafast/features/payment/presentation/screens/payment_methods_screen.dart';
import 'package:dilivvafast/features/support/presentation/screens/help_center_screen.dart';
import 'package:dilivvafast/features/support/presentation/screens/safety_screen.dart';
import 'package:dilivvafast/features/support/presentation/screens/support_chat_screen.dart';
import 'package:dilivvafast/features/about/presentation/screens/about_screen.dart';
import 'package:dilivvafast/features/legal/presentation/screens/privacy_policy_screen.dart';
import 'package:dilivvafast/features/legal/presentation/screens/terms_screen.dart';
import 'package:dilivvafast/features/auth/presentation/screens/delete_account_screen.dart';
import 'package:dilivvafast/features/driver/presentation/screens/driver_documents_screen.dart';
import 'package:dilivvafast/features/driver/presentation/screens/driver_vehicle_screen.dart';

// ==================== SCAFFOLD WITH BOTTOM NAV ====================

/// Destination descriptor for the mode shells' bottom navigation.
class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label, this.route);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
}

/// Shared scaffold for the customer, driver, admin and investor shells.
///
/// Uses Material 3's [NavigationBar] with a hairline top border, which is the
/// current convention on both platforms and reads correctly in light and dark.
const _fullBleedRoutes = {'/customer/home', '/customer/book'};

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({
    required this.child,
    required this.destinations,
    required this.currentIndex,
  });

  final Widget child;
  final List<_Destination> destinations;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final location = GoRouterState.of(context).matchedLocation;

    // The map-first screens (customer home and booking) are laid out like
    // inDrive: navigation lives in the side menu, and the bottom of the
    // screen belongs to the map sheet. Every other tab keeps its bar.
    if (_fullBleedRoutes.contains(location)) {
      return Scaffold(body: child);
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) {
            final target = destinations[i].route;
            if (target != GoRouterState.of(context).matchedLocation) {
              context.go(target);
            }
          },
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
                tooltip: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

/// Resolves the selected tab from the current location.
///
/// Matches the longest route first so `/customer/orders/abc` selects Orders
/// rather than falling through to the first tab.
int _indexFor(String location, List<_Destination> destinations) {
  var bestIndex = 0;
  var bestLength = -1;
  for (var i = 0; i < destinations.length; i++) {
    final route = destinations[i].route;
    if (location.startsWith(route) && route.length > bestLength) {
      bestIndex = i;
      bestLength = route.length;
    }
  }
  return bestIndex;
}

const _customerDestinations = [
  _Destination(
    Icons.home_outlined,
    Icons.home_rounded,
    'Home',
    '/customer/home',
  ),
  _Destination(
    Icons.add_box_outlined,
    Icons.add_box_rounded,
    'Send',
    '/customer/book',
  ),
  _Destination(
    Icons.receipt_long_outlined,
    Icons.receipt_long_rounded,
    'Orders',
    '/customer/orders',
  ),
  _Destination(
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet_rounded,
    'Wallet',
    '/customer/wallet',
  ),
  _Destination(
    Icons.person_outline_rounded,
    Icons.person_rounded,
    'Profile',
    '/customer/profile',
  ),
];

const _driverDestinations = [
  _Destination(
    Icons.explore_outlined,
    Icons.explore_rounded,
    'Jobs',
    '/driver/home',
  ),
  _Destination(
    Icons.history_rounded,
    Icons.history_rounded,
    'History',
    '/driver/history',
  ),
  _Destination(
    Icons.payments_outlined,
    Icons.payments_rounded,
    'Earnings',
    '/driver/earnings',
  ),
  _Destination(
    Icons.person_outline_rounded,
    Icons.person_rounded,
    'Profile',
    '/driver/profile',
  ),
];

const _adminDestinations = [
  _Destination(
    Icons.dashboard_outlined,
    Icons.dashboard_rounded,
    'Dashboard',
    '/admin/dashboard',
  ),
  _Destination(
    Icons.receipt_long_outlined,
    Icons.receipt_long_rounded,
    'Orders',
    '/admin/orders',
  ),
  _Destination(
    Icons.people_outline_rounded,
    Icons.people_rounded,
    'Users',
    '/admin/users',
  ),
  _Destination(
    Icons.assignment_outlined,
    Icons.assignment_rounded,
    'Applications',
    '/admin/applications',
  ),
  _Destination(
    Icons.attach_money_rounded,
    Icons.attach_money_rounded,
    'Finance',
    '/admin/finance',
  ),
];

const _investorDestinations = [
  _Destination(
    Icons.pedal_bike_outlined,
    Icons.pedal_bike_rounded,
    'Bikes',
    '/investor/home',
  ),
  _Destination(
    Icons.trending_up_outlined,
    Icons.trending_up_rounded,
    'Earnings',
    '/investor/earnings',
  ),
  _Destination(
    Icons.person_outline_rounded,
    Icons.person_rounded,
    'Profile',
    '/investor/profile',
  ),
];

// ==================== ROUTER PROVIDER ====================

/// Routes reachable without being signed in.
const _authRoutes = {
  '/login',
  '/register',
  '/forgot-password',
  '/onboarding',
  '/biometric-setup',
};

/// Onboarding flows that deliberately sit under a mode's path prefix but must
/// stay reachable by people who have not been granted that mode yet.
const _enrollmentRoutes = {'/driver/apply', '/investor/join'};

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // The splash screen decides where to go once auth has settled.
      if (location == '/') return null;

      final isLoggedIn = authState.value != null;
      final isAuthRoute = _authRoutes.contains(location);

      if (!isLoggedIn) return isAuthRoute ? null : '/login';

      // Signed in, but the profile document has not arrived yet. Redirecting
      // now would bounce drivers and investors to the customer home, so hold
      // position until the entitlements are known.
      final user = userAsync.value;
      if (user == null) return null;

      final mode = user.effectiveMode;
      if (isAuthRoute) return mode.homeRoute;

      if (_enrollmentRoutes.contains(location) &&
          (location != '/investor/join' || AppConstants.investorModeEnabled)) {
        return null;
      }

      // Keep people out of surfaces they are not entitled to, sending them to
      // that mode's onboarding rather than a screen that would fail to load.
      for (final guarded in const [
        AppMode.driver,
        AppMode.investor,
        AppMode.admin,
      ]) {
        if (location.startsWith(guarded.routePrefix) &&
            !user.canEnter(guarded)) {
          return _entryPointFor(guarded);
        }
      }

      return null;
    },
    routes: [
      // ========== AUTH ROUTES ==========
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ========== CUSTOMER ROUTES ==========
      ShellRoute(
        builder: (context, state, child) => _ShellScaffold(
          currentIndex: _indexFor(state.matchedLocation, _customerDestinations),
          destinations: _customerDestinations,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/customer/home',
            name: 'customerHome',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/customer/book',
            name: 'customerBook',
            builder: (context, state) => const CourierBookingScreen(),
          ),
          GoRoute(
            path: '/customer/orders',
            name: 'customerOrders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/customer/wallet',
            name: 'customerWallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/customer/profile',
            name: 'customerProfile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Customer modal routes (outside shell)
      GoRoute(
        path: '/customer/track/:orderId',
        name: 'customerTrack',
        builder: (context, state) =>
            TrackingScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
      GoRoute(
        path: '/customer/orders/:orderId',
        name: 'customerOrderDetail',
        builder: (context, state) =>
            TrackingScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
      GoRoute(
        path: '/customer/notifications',
        name: 'customerNotifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chat/:orderId',
        name: 'chat',
        builder: (context, state) =>
            ChatScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
      GoRoute(
        path: '/rate/:orderId',
        name: 'rate',
        builder: (context, state) =>
            RatingScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),

      // ========== DRIVER ROUTES ==========
      ShellRoute(
        builder: (context, state, child) => _ShellScaffold(
          currentIndex: _indexFor(state.matchedLocation, _driverDestinations),
          destinations: _driverDestinations,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/driver/home',
            name: 'driverHome',
            builder: (context, state) => const DriverHomeScreen(),
          ),
          GoRoute(
            path: '/driver/history',
            name: 'driverHistory',
            builder: (context, state) => const OrdersScreen(isDriver: true),
          ),
          GoRoute(
            path: '/driver/earnings',
            name: 'driverEarnings',
            builder: (context, state) => const DriverEarningsScreen(),
          ),
          GoRoute(
            path: '/driver/profile',
            name: 'driverProfile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Driver flow routes (outside shell)
      GoRoute(
        path: '/driver/active/:orderId',
        name: 'driverActiveDelivery',
        builder: (context, state) => DriverActiveDeliveryScreen(
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/driver/apply',
        name: 'driverApply',
        builder: (context, state) => const DriverApplicationScreen(),
      ),

      // ========== ADMIN ROUTES ==========
      ShellRoute(
        builder: (context, state, child) => _ShellScaffold(
          currentIndex: _indexFor(state.matchedLocation, _adminDestinations),
          destinations: _adminDestinations,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            name: 'adminDashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/orders',
            name: 'adminOrders',
            builder: (context, state) => const AdminOrdersScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'adminUsers',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/applications',
            name: 'adminApplications',
            builder: (context, state) => const AdminApplicationsScreen(),
          ),
          GoRoute(
            path: '/admin/finance',
            name: 'adminFinance',
            builder: (context, state) => const AdminFinanceScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin/promos',
        name: 'adminPromos',
        builder: (context, state) => const AdminPromosScreen(),
      ),
      GoRoute(
        path: '/admin/zones',
        name: 'adminZones',
        builder: (context, state) => const AdminZonesScreen(),
      ),
      GoRoute(
        path: '/admin/support',
        name: 'adminSupport',
        builder: (context, state) => const AdminSupportScreen(),
      ),
      GoRoute(
        path: '/admin/support/:userId',
        name: 'adminSupportThread',
        builder: (context, state) =>
            SupportChatScreen(userId: state.pathParameters['userId']),
      ),

      // ========== INVESTOR ROUTES ==========
      ShellRoute(
        builder: (context, state, child) => _ShellScaffold(
          currentIndex: _indexFor(state.matchedLocation, _investorDestinations),
          destinations: _investorDestinations,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/investor/home',
            name: 'investorHome',
            builder: (context, state) => const InvestorHomeScreen(),
          ),
          GoRoute(
            path: '/investor/earnings',
            name: 'investorEarnings',
            builder: (context, state) => const InvestorEarningsScreen(),
          ),
          GoRoute(
            path: '/investor/profile',
            name: 'investorProfile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/investor/join',
        name: 'investorJoin',
        builder: (context, state) => const InvestorJoinScreen(),
      ),
      GoRoute(
        path: '/investor/bikes/:bikeId',
        name: 'investorBikeDetail',
        builder: (context, state) => InvestorBikeDetailScreen(
          bikeId: state.pathParameters['bikeId'] ?? '',
        ),
      ),
      // Wallet top-up
      GoRoute(
        path: '/wallet/top-up',
        name: 'walletTopUp',
        builder: (context, state) => const TopUpScreen(),
      ),
      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Admin Analytics
      GoRoute(
        path: '/admin/analytics',
        name: 'adminAnalytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      // AI Chatbot
      GoRoute(
        path: '/support/chat',
        name: 'supportChat',
        builder: (context, state) => const ChatbotScreen(),
      ),
      // Biometric Setup (post-registration)
      GoRoute(
        path: '/biometric-setup',
        name: 'biometricSetup',
        builder: (context, state) => const BiometricSetupScreen(),
      ),
      // Driver Matching (finding driver animation)
      GoRoute(
        path: '/matching/:orderId',
        name: 'matching',
        builder: (context, state) =>
            MatchingScreen(orderId: state.pathParameters['orderId']),
      ),

      // ── Phase 2: Drawer-linked screens ─────────────────────────────
      GoRoute(
        path: '/customer/addresses',
        name: 'savedAddresses',
        builder: (context, state) => const SavedAddressesScreen(),
      ),
      GoRoute(
        path: '/customer/promotions',
        name: 'promotions',
        builder: (context, state) => const PromotionsScreen(),
      ),
      GoRoute(
        path: '/customer/refer',
        name: 'referEarn',
        builder: (context, state) => const ReferEarnScreen(),
      ),
      GoRoute(
        path: '/payment-methods',
        name: 'paymentMethods',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/help',
        name: 'helpCenter',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/safety',
        name: 'safety',
        builder: (context, state) => const SafetyScreen(),
      ),
      GoRoute(
        path: '/support-chat',
        name: 'supportChatDirect',
        builder: (context, state) => const SupportChatScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/settings/delete-account',
        name: 'deleteAccount',
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: '/driver/documents',
        name: 'driverDocuments',
        builder: (context, state) => const DriverDocumentsScreen(),
      ),
      GoRoute(
        path: '/driver/vehicle',
        name: 'driverVehicle',
        builder: (context, state) => const DriverVehicleScreen(),
      ),
    ],
  );
});

// ==================== HELPER FUNCTIONS ====================

/// Where to send someone who reached a mode they are not entitled to.
String _entryPointFor(AppMode mode) => switch (mode) {
  AppMode.driver => '/driver/apply',
  AppMode.investor =>
    AppConstants.investorModeEnabled ? '/investor/join' : '/customer/home',
  // There is no self-service route into admin.
  AppMode.admin || AppMode.customer => '/customer/home',
};

// ==================== SPLASH SCREEN ====================

class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  /// Minimum time the brand mark stays up, so the splash never flashes.
  static const _minimumDwell = Duration(milliseconds: 900);

  /// How long to wait for the profile document before falling back to the
  /// customer home, so a slow or failing read cannot strand people here.
  static const _profileTimeout = Duration(seconds: 6);

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    final deadline = DateTime.now().add(_profileTimeout);
    await Future<void>.delayed(_minimumDwell);

    while (mounted && DateTime.now().isBefore(deadline)) {
      final auth = ref.read(authStateProvider);

      // Auth itself has not resolved yet.
      if (auth.isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        continue;
      }

      if (auth.value == null) return _goTo('/login');

      // Signed in — wait for the profile so we route by the right mode.
      final user = ref.read(currentUserProvider).value;
      if (user != null) return _goTo(user.effectiveMode.homeRoute);

      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    if (!mounted) return;
    _goTo(
      ref.read(authStateProvider).value == null
          ? '/login'
          : AppMode.customer.homeRoute,
    );
  }

  void _goTo(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: palette.brandSubtle,
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              child: Icon(
                Icons.delivery_dining_rounded,
                size: 46,
                color: palette.brand,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Dilivvafast',
              style: context.text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text('Delivery, sorted.', style: context.text.bodyMedium),
            const SizedBox(height: 32),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: palette.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
