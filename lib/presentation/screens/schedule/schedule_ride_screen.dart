import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ScheduleRideScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? rideDetails;

  const ScheduleRideScreen({super.key, this.rideDetails});

  @override
  ConsumerState<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
}

class _ScheduleRideScreenState extends ConsumerState<ScheduleRideScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isScheduling = false;
  String? _pickupAddress;
  String? _dropoffAddress;

  @override
  void initState() {
    super.initState();
    if (widget.rideDetails != null) {
      _pickupAddress = widget.rideDetails!['pickupAddress'];
      _dropoffAddress = widget.rideDetails!['dropoffAddress'];
    }
    // Round time to next 15 minutes
    final now = DateTime.now();
    final minutes = ((now.minute / 15).ceil() * 15) % 60;
    _selectedTime = TimeOfDay(hour: now.hour + (now.minute >= 45 ? 1 : 0), minute: minutes);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.black,
              surface: AppTheme.surfaceColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.black,
              surface: AppTheme.surfaceColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _scheduleRide() async {
    if (_pickupAddress == null || _dropoffAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and dropoff locations')),
      );
      return;
    }

    setState(() => _isScheduling = true);

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Check if time is in the future
    if (scheduledDateTime.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      setState(() => _isScheduling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please schedule at least 30 minutes in advance')),
      );
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      setState(() => _isScheduling = false);
      return;
    }

    // Create scheduled ride in Firestore
    try {
      final ride = RideModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        pickupAddress: _pickupAddress!,
        pickupLocation: widget.rideDetails?['pickupLocation'] ?? const GeoPoint(6.5244, 3.3792),
        dropoffAddress: _dropoffAddress!,
        dropoffLocation: widget.rideDetails?['dropoffLocation'] ?? const GeoPoint(6.45, 3.40),
        price: widget.rideDetails?['price'] ?? 500.0,
        createdAt: scheduledDateTime,
        status: 'scheduled',
      );
      
      await ref.read(rideServiceProvider).createRide(ride);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride scheduled for ${DateFormat('MMM d, h:mm a').format(scheduledDateTime)}'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling ride: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScheduling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d');
    final timeFormat = DateFormat('h:mm a');
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Schedule Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassCard(
            borderRadius: 50,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const BackgroundOrbs(),
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Schedule Icon and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.schedule, color: AppTheme.primaryColor, size: 48),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'When do you want to ride?',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(delay: 100.ms),

                const SizedBox(height: 32),

                // Date Selection
                const Text('DATE', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectDate,
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                          const SizedBox(width: 16),
                          Text(
                            dateFormat.format(_selectedDate),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                // Time Selection
                const Text('TIME', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectTime,
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppTheme.primaryColor),
                          const SizedBox(width: 16),
                          Text(
                            timeFormat.format(scheduledDateTime),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                // Route Summary
                if (_pickupAddress != null && _dropoffAddress != null) ...[
                  const Text('ROUTE', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.my_location, color: Colors.green, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _pickupAddress!,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Divider(color: Colors.white24, height: 24),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _dropoffAddress!,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],

                const SizedBox(height: 48),

                // Schedule Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isScheduling ? null : _scheduleRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isScheduling
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text(
                            'CONFIRM SCHEDULE',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
          ),
        ],
      ),
    );
  }
}
