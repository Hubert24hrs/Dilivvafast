import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dilivvafast/core/constants/firestore_constants.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';
import 'package:dilivvafast/core/providers/providers.dart';

/// Animated "Finding your courier" screen shown after booking confirmation.
/// Listens to the courier order document for driverId assignment.
class MatchingScreen extends ConsumerStatefulWidget {
  final String? orderId;

  const MatchingScreen({super.key, this.orderId});

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  Timer? _timeoutTimer;
  Timer? _statusTimer;
  int _elapsedSeconds = 0;
  bool _driverFound = false;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  String _statusText = 'Finding your courier...';

  // Driver search phases shown while waiting
  final List<String> _searchPhases = [
    'Finding your courier...',
    'Searching nearby couriers...',
    'Matching you with the best courier...',
    'Almost there...',
    'Expanding search area...',
  ];
  int _currentPhase = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Update elapsed time and rotate status text
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
          if (_elapsedSeconds % 10 == 0 &&
              _currentPhase < _searchPhases.length - 1) {
            _currentPhase++;
            _statusText = _searchPhases[_currentPhase];
          }
        });
      }
    });

    // Timeout after 2 minutes
    _timeoutTimer = Timer(const Duration(minutes: 2), () {
      if (mounted && !_driverFound) {
        _showTimeoutDialog();
      }
    });

    // Listen for real-time driver assignment on Firestore
    _listenForDriverAssignment();
  }

  /// Attaches a Firestore snapshot listener to couriers/{orderId}.
  /// When a driverId is written to the document (by a driver claiming the job,
  /// or by an admin), the screen transitions to the live tracking view.
  ///
  /// This listened on `orders/` until now — the wrong collection, and one that
  /// firestore.rules denies outright — so a driver could accept a job and the
  /// customer would sit on the searching screen until it timed out.
  void _listenForDriverAssignment() {
    final orderId = widget.orderId;
    if (orderId == null || orderId.isEmpty) return;

    final firestore = ref.read(firestoreProvider);
    _orderSubscription = firestore
        .collection(FirestoreConstants.couriers)
        .doc(orderId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || _driverFound) return;

      final data = snapshot.data();
      if (data != null && data['driverId'] != null) {
        _onDriverFound(data);
      }
    }, onError: (error) {
      debugPrint('MatchingScreen: Firestore listener error: $error');
    });
  }

  /// Called when a driver has been assigned to this order.
  void _onDriverFound(Map<String, dynamic> orderData) {
    if (!mounted || _driverFound) return;

    setState(() {
      _driverFound = true;
      _statusText = 'Courier found!';
    });

    _timeoutTimer?.cancel();
    _statusTimer?.cancel();

    // Brief delay to show the "Driver found!" state, then navigate
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        context.go('/customer/track/${widget.orderId}');
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.palette.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('No Couriers Available',
            style: TextStyle(color: context.palette.textPrimary)),
        content: Text(
          'We couldn\'t find a courier right now. This might be due to high demand or limited availability in your area.',
          style: TextStyle(color: context.palette.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Keep searching
              _timeoutTimer = Timer(const Duration(minutes: 2), () {
                if (mounted && !_driverFound) _showTimeoutDialog();
              });
            },
            child: Text('Keep Waiting',
                style: TextStyle(color: context.palette.brand)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/customer/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.brand,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cancel',
                style: TextStyle(color: context.palette.onBrand)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    _timeoutTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with cancel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/customer/home'),
                    icon: Icon(Icons.close, color: context.palette.textSecondary, size: 20),
                    label: Text('Cancel',
                        style: TextStyle(color: context.palette.textSecondary)),
                  ),
                  Text(_formattedTime,
                      style:
                          TextStyle(color: context.palette.textMuted, fontSize: 14)),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Animated search visualization
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rotating ring
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * pi,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.palette.brand
                                  .withValues(alpha: 0.15),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 0,
                                left: 100,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.palette.brand,
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.palette.brand
                                            .withValues(alpha: 0.6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Middle pulsing ring
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1 + (_pulseController.value * 0.08);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.palette.brand
                                  .withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Ripple effects
                  ...List.generate(3, (index) {
                    return _AnimatedRipple(
                      delay: Duration(milliseconds: index * 600),
                      color: context.palette.brand,
                    );
                  }),

                  // Center icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: context.palette.brand
                              .withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _driverFound
                          ? Icons.check_rounded
                          : Icons.local_shipping_rounded,
                      color: context.palette.onBrand,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Status text
            Text(
              _statusText,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            )
                .animate(
                    target: _driverFound ? 1 : 0,
                    onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 12),

            Text(
              _driverFound
                  ? 'Preparing your delivery...'
                  : 'Please wait while we connect you with a nearby courier',
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Progress dots
            if (!_driverFound)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isActive = index <= _currentPhase;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? context.palette.brand
                          : context.palette.textMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                      .animate()
                      .fadeIn(
                          delay: Duration(milliseconds: 200 * index),
                          duration: 300.ms);
                }),
              ),

            const Spacer(flex: 3),

            // Tip card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.palette.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.palette.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: context.palette.brand, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: You can track your courier in real-time once matched!',
                      style: TextStyle(
                        color: context.palette.textPrimary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 1.seconds, duration: 600.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Animated expanding ripple circle
class _AnimatedRipple extends StatefulWidget {
  final Duration delay;
  final Color color;

  const _AnimatedRipple({required this.delay, required this.color});

  @override
  State<_AnimatedRipple> createState() => _AnimatedRippleState();
}

class _AnimatedRippleState extends State<_AnimatedRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 80 + (_controller.value * 120),
          height: 80 + (_controller.value * 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color
                  .withValues(alpha: 0.3 * (1 - _controller.value)),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
}
