import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/services/favorite_drivers_service.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoriteDriversScreen extends ConsumerWidget {
  const FavoriteDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    Stream<List<FavoriteDriverModel>>? favoritesStream;
    if (userId != null) {
      favoritesStream = ref.watch(favoriteDriversServiceProvider).getFavoriteDrivers(userId);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Favorite Drivers', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<FavoriteDriverModel>>(
        stream: favoritesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 24),
                    Text(
                      'No Favorite Drivers',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add drivers to your favorites after completing a trip',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final driver = favorites[index];
              return _buildDriverCard(context, ref, driver, userId!);
            },
          );
        },
      ),
    );
  }

  Widget _buildDriverCard(
    BuildContext context,
    WidgetRef ref,
    FavoriteDriverModel driver,
    String userId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Driver Photo
            CircleAvatar(
              radius: 30,
              backgroundImage: driver.driverPhoto != null
                  ? NetworkImage(driver.driverPhoto!)
                  : null,
              backgroundColor: Colors.grey[200],
              child: driver.driverPhoto == null
                  ? const Icon(Icons.person, size: 30, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),

            // Driver Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.driverName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (driver.carModel != null)
                    Text(
                      driver.carModel!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  if (driver.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          driver.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                // Request Button
                ElevatedButton(
                  onPressed: () => _showRequestDriverDialog(context, ref, driver, userId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('REQUEST', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 8),
                // Remove Button
                TextButton(
                  onPressed: () async {
                    await ref.read(favoriteDriversServiceProvider).removeFavorite(
                          userId: userId,
                          driverId: driver.driverId,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from favorites')),
                      );
                    }
                  },
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDriverDialog(
    BuildContext context,
    WidgetRef ref,
    FavoriteDriverModel driver,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: driver.driverPhoto != null
                  ? NetworkImage(driver.driverPhoto!)
                  : null,
              backgroundColor: Colors.grey[200],
              child: driver.driverPhoto == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request ${driver.driverName}?',
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (driver.rating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          driver.rating!.toStringAsFixed(1),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        content: const Text(
          'You\'ll enter your destination, and we\'ll try to assign this driver to your ride. If they\'re unavailable, we\'ll find another driver for you.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to destination search with preferred driver
              context.push('/destination', extra: {
                'preferredDriverId': driver.driverId,
                'preferredDriverName': driver.driverName,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
  }
}
