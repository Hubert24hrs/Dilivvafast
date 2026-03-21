import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/features/auth/domain/entities/user_model.dart';
import 'package:fast_delivery/features/auth/presentation/screens/login_screen.dart';
import 'package:fast_delivery/features/home/presentation/screens/home_screen.dart';

// Phase 2 screens
import 'package:fast_delivery/features/booking/presentation/screens/booking_screen.dart';
import 'package:fast_delivery/features/courier/presentation/screens/tracking_screen.dart';
import 'package:fast_delivery/features/courier/presentation/screens/orders_screen.dart';
import 'package:fast_delivery/features/courier/presentation/screens/chat_screen.dart';
import 'package:fast_delivery/features/payment/presentation/screens/wallet_screen.dart';
import 'package:fast_delivery/features/driver/presentation/screens/driver_home_screen.dart';
import 'package:fast_delivery/features/driver/presentation/screens/driver_active_delivery_screen.dart';
import 'package:fast_delivery/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:fast_delivery/features/admin/presentation/screens/admin_screens.dart';
import 'package:fast_delivery/features/investor/presentation/screens/investor_screens.dart';
import 'package:fast_delivery/features/profile/presentation/screens/profile_screen.dart';
import 'package:fast_delivery/features/rating/presentation/screens/rating_screen.dart';

// Phase 3 screens
import 'package:fast_delivery/features/auth/presentation/screens/register_screen.dart';
import 'package:fast_delivery/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:fast_delivery/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:fast_delivery/features/notification/presentation/screens/notifications_screen.dart';
import 'package:fast_delivery/features/driver/presentation/screens/driver_application_screen.dart';
import 'package:fast_delivery/features/admin/presentation/screens/admin_promos_screen.dart';
import 'package:fast_delivery/features/admin/presentation/screens/admin_zones_screen.dart';

// Phase 4 screens
import 'package:fast_delivery/features/payment/presentation/screens/top_up_screen.dart';
import 'package:fast_delivery/features/investor/presentation/screens/investor_bike_detail_screen.dart';

// Phase 5 screens
import 'package:fast_delivery/features/profile/presentation/screens/settings_screen.dart';

// Phase 6 screens
import 'package:fast_delivery/features/admin/presentation/screens/admin_analytics_screen.dart';
import 'package:fast_delivery/features/support/presentation/screens/chatbot_screen.dart';
import 'package:fast_delivery/features/referral/presentation/screens/referral_screen.dart';


// ==================== SCAFFOLD WITH BOTTOM NAV ====================

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({
    required this.child,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.role,
  });

  final Widget child;
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1D1E33),
        selectedItemColor: const Color(0xFF00F0FF),
        unselectedItemColor: Colors.white54,
        items: items,
      ),
    );
  }
}

// ==================== ROUTER PROVIDER ====================

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRole = ref.watch(currentUserRoleProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/';

      // Not logged in — redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // Logged in but on auth route — redirect to role-based home
      if (isLoggedIn && isAuthRoute && state.matchedLocation != '/') {
        return _getHomeRouteForRole(userRole);
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
        builder: (context, state, child) {
          final index = _getCustomerTabIndex(state.matchedLocation);
          return _ShellScaffold(
            currentIndex: index,
            role: 'customer',
            onTap: (i) => _onCustomerTabTap(context, i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.add_box), label: 'Book'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long), label: 'Orders'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/customer/home',
            name: 'customerHome',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/customer/book',
            name: 'customerBook',
            builder: (context, state) => const BookingScreen(),
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
        builder: (context, state) => TrackingScreen(
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/customer/orders/:orderId',
        name: 'customerOrderDetail',
        builder: (context, state) => TrackingScreen(
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/customer/notifications',
        name: 'customerNotifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chat/:orderId',
        name: 'chat',
        builder: (context, state) => ChatScreen(
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/rate/:orderId',
        name: 'rate',
        builder: (context, state) => RatingScreen(
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),

      // ========== DRIVER ROUTES ==========
      ShellRoute(
        builder: (context, state, child) {
          final index = _getDriverTabIndex(state.matchedLocation);
          return _ShellScaffold(
            currentIndex: index,
            role: 'driver',
            onTap: (i) => _onDriverTabTap(context, i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history), label: 'History'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/driver/home',
            name: 'driverHome',
            builder: (context, state) => const DriverHomeScreen(),
          ),
          GoRoute(
            path: '/driver/history',
            name: 'driverHistory',
            builder: (context, state) =>
                const OrdersScreen(isDriver: true),
          ),
          GoRoute(
            path: '/driver/earnings',
            name: 'driverEarnings',
            builder: (context, state) => const WalletScreen(),
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
        builder: (context, state, child) {
          final index = _getAdminTabIndex(state.matchedLocation);
          return _ShellScaffold(
            currentIndex: index,
            role: 'admin',
            onTap: (i) => _onAdminTabTap(context, i),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long), label: 'Orders'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people), label: 'Users'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.assignment), label: 'Applications'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.attach_money), label: 'Finance'),
            ],
            child: child,
          );
        },
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

      // ========== INVESTOR ROUTES ==========
      ShellRoute(
        builder: (context, state, child) {
          final index = _getInvestorTabIndex(state.matchedLocation);
          return _ShellScaffold(
            currentIndex: index,
            role: 'investor',
            onTap: (i) => _onInvestorTabTap(context, i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.attach_money), label: 'Earnings'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
            child: child,
          );
        },
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
      // Referral System
      GoRoute(
        path: '/referral',
        name: 'referral',
        builder: (context, state) => const ReferralScreen(),
      ),
    ],
  );
});

// ==================== HELPER FUNCTIONS ====================

String _getHomeRouteForRole(UserRole? role) {
  switch (role) {
    case UserRole.customer:
      return '/customer/home';
    case UserRole.driver:
      return '/driver/home';
    case UserRole.admin:
      return '/admin/dashboard';
    case UserRole.investor:
      return '/investor/home';
    case null:
      return '/customer/home'; // Default for unknown role
  }
}

int _getCustomerTabIndex(String location) {
  if (location.startsWith('/customer/book')) return 1;
  if (location.startsWith('/customer/orders')) return 2;
  if (location.startsWith('/customer/wallet')) return 3;
  if (location.startsWith('/customer/profile')) return 4;
  return 0;
}

void _onCustomerTabTap(BuildContext context, int index) {
  const routes = [
    '/customer/home',
    '/customer/book',
    '/customer/orders',
    '/customer/wallet',
    '/customer/profile',
  ];
  context.go(routes[index]);
}

int _getDriverTabIndex(String location) {
  if (location.startsWith('/driver/history')) return 1;
  if (location.startsWith('/driver/earnings')) return 2;
  if (location.startsWith('/driver/profile')) return 3;
  return 0;
}

void _onDriverTabTap(BuildContext context, int index) {
  const routes = [
    '/driver/home',
    '/driver/history',
    '/driver/earnings',
    '/driver/profile',
  ];
  context.go(routes[index]);
}

int _getAdminTabIndex(String location) {
  if (location.startsWith('/admin/orders')) return 1;
  if (location.startsWith('/admin/users')) return 2;
  if (location.startsWith('/admin/applications')) return 3;
  if (location.startsWith('/admin/finance')) return 4;
  return 0;
}

void _onAdminTabTap(BuildContext context, int index) {
  const routes = [
    '/admin/dashboard',
    '/admin/orders',
    '/admin/users',
    '/admin/applications',
    '/admin/finance',
  ];
  context.go(routes[index]);
}

int _getInvestorTabIndex(String location) {
  if (location.startsWith('/investor/earnings')) return 1;
  if (location.startsWith('/investor/profile')) return 2;
  return 0;
}

void _onInvestorTabTap(BuildContext context, int index) {
  const routes = [
    '/investor/home',
    '/investor/earnings',
    '/investor/profile',
  ];
  context.go(routes[index]);
}

// ==================== SPLASH SCREEN ====================

class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    final userRole = ref.read(currentUserRoleProvider);

    if (authState.value != null) {
      context.go(_getHomeRouteForRole(userRole));
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delivery_dining,
                size: 80, color: Color(0xFF00F0FF)),
            const SizedBox(height: 24),
            Text(
              'DILIVVAFAST',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: const Color(0xFF00F0FF),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: Color(0xFF00F0FF)),
          ],
        ),
      ),
    );
  }
}
