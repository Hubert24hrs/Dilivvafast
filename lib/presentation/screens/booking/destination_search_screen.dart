import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/services/saved_destinations_service.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/background_orbs.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';

class DestinationSearchScreen extends ConsumerStatefulWidget {
  final String? preferredDriverId;
  final String? preferredDriverName;
  
  const DestinationSearchScreen({
    super.key,
    this.preferredDriverId,
    this.preferredDriverName,
  });

  @override
  ConsumerState<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends ConsumerState<DestinationSearchScreen> {
  final TextEditingController _pickupController = TextEditingController(text: "Current Location");
  final TextEditingController _dropoffController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];
  bool _isLoading = false;
  
  // Saved destinations
  SavedDestination? _homeDestination;
  SavedDestination? _workDestination;

  @override
  void initState() {
    super.initState();
    _loadSavedDestinations();
  }

  Future<void> _loadSavedDestinations() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    
    try {
      final stream = ref.read(savedDestinationsServiceProvider).getSavedDestinations(userId);
      stream.listen((destinations) {
        if (mounted) {
          setState(() {
            _homeDestination = destinations.where((d) => d.name.toLowerCase() == 'home').firstOrNull;
            _workDestination = destinations.where((d) => d.name.toLowerCase() == 'work').firstOrNull;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading saved destinations: $e');
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() {
      _stopControllers.add(TextEditingController());
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stopControllers[index].dispose();
      _stopControllers.removeAt(index);
    });
  }

  Future<void> _selectDestination(String destinationName) async {
    setState(() => _isLoading = true);

    try {
      // 1. Try to get real coordinates
      List<Location> locations = await locationFromAddress(destinationName);
      
      if (locations.isNotEmpty) {
        final location = locations.first;

        if (mounted) {
          context.pop({
            'name': destinationName,
            'lat': location.latitude,
            'lng': location.longitude,
            'preferredDriverId': widget.preferredDriverId,
          });
        }
      } else {
        // Fallback if no location found
        _showError('Location not found. Using mock destination.');
        _returnMock(destinationName);
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      if (mounted) {
         _returnMock(destinationName);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _returnMock(String destinationName) {
    // Mock Destination Coordinates (e.g., Victoria Island, Lagos)
    context.pop({
      'name': destinationName,
      'lat': 6.4281,
      'lng': 3.4241,
      'preferredDriverId': widget.preferredDriverId,
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      body: Stack(
        children: [
          const BackgroundOrbs(),
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
            children: [
              // Custom AppBar (since we want full control)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Your route',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _addStop,
                    ),
                  ],
                ),
              ),

              // Preferred Driver Banner
              if (widget.preferredDriverName != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Requesting ${widget.preferredDriverName}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => context.pop(), // Cancel preferred driver
                      ),
                    ],
                  ),
                ),

              // Input Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  opacity: 0.1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        // Pickup
                        _buildInputRow(
                          controller: _pickupController,
                          icon: Icons.my_location,
                          iconColor: AppTheme.secondaryColor,
                          hint: 'Pickup location',
                          isReadOnly: true,
                        ),
                        const SizedBox(height: 12),

                        // Stops
                        for (int i = 0; i < _stopControllers.length; i++) ...[
                          _buildInputRow(
                            controller: _stopControllers[i],
                            icon: Icons.stop_circle_outlined,
                            iconColor: Colors.orange,
                            hint: 'Add stop',
                            onRemove: () => _removeStop(i),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Dropoff
                        _buildInputRow(
                          controller: _dropoffController,
                          icon: Icons.location_on_outlined,
                          iconColor: AppTheme.primaryColor,
                          hint: 'Dropoff location',
                          autofocus: true,
                          isLoading: _isLoading,
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _selectDestination(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Saved Destinations Quick Access
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSavedDestinationCard(
                        icon: Icons.home,
                        label: 'Home',
                        address: _homeDestination?.address ?? 'Tap to set',
                        isSaved: _homeDestination != null,
                        onTap: () {
                          if (_homeDestination != null) {
                            _selectSavedDestination(_homeDestination!);
                          } else {
                            _promptSetDestination('Home');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSavedDestinationCard(
                        icon: Icons.work,
                        label: 'Work',
                        address: _workDestination?.address ?? 'Tap to set',
                        isSaved: _workDestination != null,
                        onTap: () {
                          if (_workDestination != null) {
                            _selectSavedDestination(_workDestination!);
                          } else {
                            _promptSetDestination('Work');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              // Recent Places Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'RECENT PLACES',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Recent Places List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildRecentPlace(
                      'First Bank Lekki',
                      '3 Chris Efunyemi Onanuga Street, Lekki',
                      '3 km',
                    ),
                    _buildRecentPlace(
                      '15 Nike Art Gallery Road',
                      'Lagos, Nigeria',
                      '< 1 km',
                    ),
                    _buildRecentPlace(
                      'Murtala Muhammed Airport',
                      '1 Airport Road, Ikeja',
                      '24.4 km',
                      icon: Icons.local_airport,
                    ),
                    _buildRecentPlace(
                      'Eko Hotel',
                      '1415 Adetokunbo Ademola Street',
                      '6.2 km',
                    ),
                    _buildRecentPlace(
                      'Lekki Phase One',
                      'Lekki, Lagos',
                      '2.1 km',
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ],
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

  Widget _buildInputRow({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hint,
    bool isReadOnly = false,
    bool autofocus = false,
    bool isLoading = false,
    VoidCallback? onRemove,
    Function(String)? onSubmitted,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              readOnly: isReadOnly,
              autofocus: autofocus,
              onSubmitted: onSubmitted,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                          ),
                        ),
                      )
                    : (onRemove != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                            onPressed: onRemove,
                          )
                        : null),
              ),
            ),
          ),
        ),
        if (onRemove == null) ...[
          const SizedBox(width: 8),
          const Icon(Icons.add, color: Colors.white54, size: 24),
        ],
      ],
    );
  }

  Widget _buildRecentPlace(String title, String subtitle, String distance, {IconData icon = Icons.access_time}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.white10,
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Text(
        distance,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      onTap: () => _selectDestination(title),
    );
  }

  void _selectSavedDestination(SavedDestination destination) {
    context.pop({
      'name': destination.address,
      'lat': destination.latitude,
      'lng': destination.longitude,
    });
  }

  void _promptSetDestination(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enter a $type address and it will be saved'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildSavedDestinationCard({
    required IconData icon,
    required String label,
    required String address,
    required VoidCallback onTap,
    bool isSaved = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSaved ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSaved ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    address,
                    style: TextStyle(
                      color: isSaved ? Colors.white70 : Colors.white54,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSaved)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 16),
          ],
        ),
      ),
    );
  }
}
