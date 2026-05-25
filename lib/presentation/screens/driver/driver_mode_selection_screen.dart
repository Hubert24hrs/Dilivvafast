
import 'package:fast_delivery/core/models/driver_application_model.dart';
import 'package:fast_delivery/core/models/user_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class DriverModeSelectionScreen extends ConsumerWidget {
  const DriverModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final userAsync = userId != null 
        ? ref.watch(databaseServiceProvider).getUserStream(userId)
        : const Stream<UserModel?>.empty();
    
    final appAsync = userId != null
        ? ref.watch(databaseServiceProvider).getDriverApplicationStream(userId)
        : const Stream<DriverApplicationModel?>.empty();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<UserModel?>(
        stream: userAsync,
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          final isDriver = user?.role == 'driver';

          return StreamBuilder<DriverApplicationModel?>(
            stream: appAsync,
            builder: (context, appSnapshot) {
              final application = appSnapshot.data;
              final hasPendingApp = application != null && application.status != 'rejected';

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              // Info Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCFF00), // Neon Lime
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Earn Money Driving',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(Icons.access_time, 'Set your own schedule'),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(Icons.account_balance_wallet, 'Control your earnings'),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(Icons.percent, 'Minimal commission fees'),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              if (isDriver) ...[
                                // Already a Driver
                                _buildOptionCard(
                                  context,
                                  icon: FontAwesomeIcons.car,
                                  title: 'Go to Driver Dashboard',
                                  onTap: () => context.go('/driver'),
                                ),
                              ] else if (hasPendingApp) ...[
                                // Application Pending
                                _buildOptionCard(
                                  context,
                                  icon: FontAwesomeIcons.clock,
                                  title: 'Check Application Status',
                                  onTap: () => context.push('/driver-pending'),
                                ),
                              ] else ...[
                                // New Application
                                _buildOptionCard(
                                  context,
                                  icon: FontAwesomeIcons.car,
                                  title: 'Become a Driver',
                                  onTap: () => context.push('/driver-registration?type=driver'),
                                ),
                                const SizedBox(height: 16),
                                _buildOptionCard(
                                  context,
                                  icon: FontAwesomeIcons.box,
                                  title: 'Become a Courier',
                                  onTap: () => context.push('/driver-registration?type=courier'),
                                ),
                              ],
                              
                              const Spacer(),
                              
                              // Footer
                              if (!isDriver && !hasPendingApp) ...[
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // If they have an account but aren't a driver, maybe they want to login as a different user?
                                      // Or if we had a separate "Driver Login" flow. 
                                      // For now, let's just keep it simple.
                                      context.push('/login'); 
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                    child: const Text('I already have a driver account'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              TextButton(
                                onPressed: () => context.go('/'),
                                child: const Text(
                                  'Go to passenger mode',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              );
            }
          );
        }
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.black, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildOptionCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 32),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
