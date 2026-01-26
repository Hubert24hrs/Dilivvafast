import 'package:fast_delivery/core/models/courier_model.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/app_drawer.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/platform_map_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAccepting = false;


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ridesAsync = ref.watch(ridesStreamProvider);
    final couriersAsync = ref.watch(activeCouriersProvider);
    final isOnline = ref.watch(driverOnlineProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            const BackgroundOrbs(),
            ridesAsync.when(
              data: (rides) {
                final couriers = couriersAsync.maybeWhen(
                  data: (data) => data,
                  orElse: () => <CourierModel>[],
                );
                
                debugPrint('DriverDashboard: isOnline=$isOnline, rides=${rides.length}, couriers=${couriers.length}');
                
                if (isOnline) {
                  if (rides.isNotEmpty) {
                    debugPrint('DriverDashboard: Showing ride request');
                    return _buildRequestView(rides.first);
                  } else if (couriers.isNotEmpty) {
                    debugPrint('DriverDashboard: Showing courier request');
                    return _buildCourierRequestView(couriers.first);
                  }
                }
                return _buildDashboardView(isOnline);
              },
              loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              error: (err, stack) => _buildDashboardView(isOnline),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3D ULTRA MODERN DASHBOARD ---
  Widget _buildDashboardView(bool isOnline) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 380;
          final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
          
          return Column(
            children: [
              // Top Bar with menu and status toggle
              _buildDashboardAppBar(isOnline),
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3D Balance Card (replaces chart)
                      _build3DBalanceCard()
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0)
                          .shimmer(delay: 600.ms, duration: 1200.ms),
                      const SizedBox(height: 24),
                      
                      // Stats Title with glow
                      _buildSectionTitle('Stats Overview'),
                      const SizedBox(height: 16),
                      
                      // 3D Stats Grid
                      _build3DStatsGrid(isSmallScreen)
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Quick Actions Title
                      _buildSectionTitle('Quick Actions'),
                      const SizedBox(height: 16),
                      
                      // Horizontal Quick Actions
                      _build3DQuickActions()
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms),
                      
                      const SizedBox(height: 24),
                      
                      // Recent Activity
                      _buildSectionTitle('Recent Activity'),
                      const SizedBox(height: 16),
                      
                      _buildRecentTrips()
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 400.ms)
                          .slideX(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
  

  Widget _buildDashboardAppBar(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Menu Button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.neomorphicShadow(),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Text(
              'Driver Dashboard',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Online/Offline Toggle
          GestureDetector(
            onTap: () => ref.read(driverOnlineProvider.notifier).toggle(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isOnline 
                    ? AppTheme.primaryColor.withValues(alpha: 0.2) 
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isOnline ? AppTheme.primaryColor : Colors.red,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isOnline ? AppTheme.primaryColor : Colors.red).withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isOnline ? AppTheme.primaryColor : Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isOnline ? AppTheme.primaryColor : Colors.red).withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? 'ONLINE' : 'OFFLINE',
                    style: GoogleFonts.spaceGrotesk(
                      color: isOnline ? AppTheme.primaryColor : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3D BALANCE CARD ---
  Widget _build3DBalanceCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          // 3D depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
          // Inner glow
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.account_balance_wallet, 
                          color: AppTheme.primaryColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Available Balance',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white60,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₦',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '4,336',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ),
              const SizedBox(width: 12),
              // Withdraw Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/wallet'),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        'Withdraw',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Today's summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Today', '₦2,150', Icons.today),
                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
                _buildMiniStat('Week', '₦12,400', Icons.date_range),
                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
                _buildMiniStat('Trips', '8', Icons.directions_car),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // --- 3D STATS GRID ---
  Widget _build3DStatsGrid(bool isSmallScreen) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _build3DStatCard('Trips', '34', Icons.directions_car_rounded, const Color(0xFF4FC3F7), const Color(0xFF0288D1)),
        _build3DStatCard('Online', '5h 12m', Icons.schedule_rounded, const Color(0xFFFF8A65), const Color(0xFFF4511E)),
        _build3DStatCard('Rating', '4.9', Icons.star_rounded, const Color(0xFFFFD54F), const Color(0xFFFFA000)),
        _build3DStatCard('Accept', '94%', Icons.check_circle_rounded, AppTheme.primaryColor, const Color(0xFF00C853)),
      ],
    );
  }

  Widget _build3DStatCard(String title, String value, IconData icon, Color color, Color darkColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          // Main 3D shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          // Color accent glow
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          // Value and title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3D QUICK ACTIONS ---
  Widget _build3DQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _build3DActionChip(Icons.wallet, 'Wallet', () => context.push('/wallet')),
          const SizedBox(width: 12),
          _build3DActionChip(Icons.history, 'History', () => context.push('/history')),
          const SizedBox(width: 12),
          _build3DActionChip(Icons.bar_chart, 'Earnings', () => context.push('/driver-earnings')),
          const SizedBox(width: 12),
          _build3DActionChip(Icons.settings, 'Settings', () => context.push('/settings')),
          const SizedBox(width: 12),
          _build3DActionChip(Icons.help_outline, 'Help', () {}),
        ],
      ),
    );
  }
  
  Widget _build3DActionChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceColor,
              AppTheme.surfaceColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RECENT TRIPS ---
  Widget _buildRecentTrips() {
    final trips = [
      {'from': 'Ikeja Mall', 'to': 'Victoria Island', 'amount': '₦2,500', 'time': '2h ago'},
      {'from': 'Lekki Phase 1', 'to': 'Airport', 'amount': '₦4,200', 'time': '4h ago'},
      {'from': 'Yaba', 'to': 'Ajah', 'amount': '₦3,100', 'time': '6h ago'},
    ];
    
    return Column(
      children: trips.map((trip) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildTripCard(trip),
      )).toList(),
    );
  }
  
  Widget _buildTripCard(Map<String, String> trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor.withValues(alpha: 0.9),
            AppTheme.surfaceColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.directions_car, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip['from']} → ${trip['to']}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  trip['time']!,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trip['amount']!,
            style: GoogleFonts.spaceGrotesk(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // --- REFERENCE IMAGE 2: REQUEST / NEGOTIATION ---
  Widget _buildRequestView(RideModel ride) {
    return Stack(
      children: [
        // Full Screen Map with Padding for the left rail if we wanted... 
        // But Ref 2 usually shows full screen map. We'll do full screen.
        PlatformMapWidget(
          initialLat: ride.pickupLocation.latitude,
          initialLng: ride.pickupLocation.longitude,
          initialZoom: 14.5,
          onMapCreated: (_) {},
        ),

        // Floating Panel
        // Centered or Bottom Sheet style? Ref 2 implies a nice card on the side or bottom.
        // Let's use a nice floating card on the left-bottom for larger screens, bottom for mobile.
        Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            margin: const EdgeInsets.all(16),
            height: 400,
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildRequestPanel(ride),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestPanel(RideModel ride) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Accent
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF), // Purple Header
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 24,
                  child: Icon(FontAwesomeIcons.user, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Request',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'John Doe', // Mock Name
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '2.5 km',
                    style: TextStyle(color: const Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Price
                  Text(
                    '₦${ride.price.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    'Estimated Fare',
                     style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  // Timeline
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildTimelineTile(
                            isFirst: true,
                            isLast: false,
                            title: 'Pickup',
                            subtitle: ride.pickupAddress,
                            color: const Color(0xFF6C63FF),
                          ),
                          _buildTimelineTile(
                            isFirst: false,
                            isLast: true,
                            title: 'Dropoff',
                            subtitle: ride.dropoffAddress,
                            color: const Color(0xFF00E5FF),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _declineRide(ride),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            foregroundColor: Colors.grey[700],
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isAccepting ? null : () => _acceptRide(ride),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          ),
                          child: _isAccepting 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Accept Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required bool isFirst,
    required bool isLast,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 2),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey[200],
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRide(RideModel ride) async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    try {
      final driverId = ref.read(authServiceProvider).currentUser?.uid ?? 'driver_1';
      
      await ref.read(rideServiceProvider).updateRideStatus(
        ride.id, 
        'accepted', 
        driverId: driverId,
        driverName: 'John Doe',
        driverPhone: '08012345678',
        driverPhoto: 'https://i.pravatar.cc/150?img=11',
        carModel: 'Toyota Camry (Silver)',
        plateNumber: 'LND-823-XA',
      );

      if (mounted) {
        context.push('/driver-navigation', extra: {'ride': ride});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _declineRide(RideModel ride) async {
    try {
      await ref.read(rideServiceProvider).updateRideStatus(ride.id, 'cancelled');
    } catch (e) {
      debugPrint('Error declining: $e');
    }
  }

  // --- COURIER HANDLING ---

  Widget _buildCourierRequestView(CourierModel courier) {
    return Stack(
      children: [
        // Background (Light or Map) - Using light color for courier
        Container(color: const Color(0xFFF8F9FE)),

        // Floating Panel
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildCourierRequestPanel(courier),
          ),
        ),
      ],
    );
  }

  Widget _buildCourierRequestPanel(CourierModel courier) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Accent - Orange for Courier
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.orange, // Orange for Courier
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 24,
                  child: Icon(FontAwesomeIcons.box, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Courier Request',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        courier.receiverName.isNotEmpty ? courier.receiverName : 'Package Delivery',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    courier.packageSize,
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Price
                Text(
                  '₦${courier.price.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Proposed Fare',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 20),
                
                // Locations
                _buildTimelineTile(
                  isFirst: true,
                  isLast: false,
                  title: 'Pickup',
                  subtitle: courier.pickupAddress,
                  color: Colors.orange,
                ),
                _buildTimelineTile(
                  isFirst: false,
                  isLast: true,
                  title: 'Deliver to',
                  subtitle: courier.dropoffAddress,
                  color: Colors.green,
                ),
                
                const SizedBox(height: 20),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _declineCourier(courier),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAccepting ? null : () => _acceptCourier(courier),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isAccepting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Accept', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptCourier(CourierModel courier) async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    try {
      final driverId = ref.read(authServiceProvider).currentUser?.uid ?? 'driver_1';
      
      await ref.read(databaseServiceProvider).updateCourierStatus(
        courier.id, 
        'accepted', 
        driverId,
      );

      if (mounted) {
        context.push('/driver-navigation', extra: {'courier': courier});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _declineCourier(CourierModel courier) async {
    try {
      final driverId = ref.read(authServiceProvider).currentUser?.uid ?? '';
      await ref.read(databaseServiceProvider).updateCourierStatus(courier.id, 'cancelled', driverId);
    } catch (e) {
      debugPrint('Error declining courier: $e');
    }
  }
}
