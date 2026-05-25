import 'package:fast_delivery/core/models/driver_application_model.dart';
import 'package:fast_delivery/core/models/user_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DriverPendingScreen extends ConsumerWidget {
  const DriverPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final appStream = userId != null
        ? ref.watch(databaseServiceProvider).getDriverApplicationStream(userId)
        : const Stream<DriverApplicationModel?>.empty();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<DriverApplicationModel?>(
          stream: appStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final app = snapshot.data;
            final isApproved = app?.status == 'approved';
            final isRejected = app?.status == 'rejected';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Animation
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isApproved 
                            ? Colors.green.withValues(alpha: 0.1)
                            : isRejected 
                                ? Colors.red.withValues(alpha: 0.1)
                                : AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isApproved 
                            ? Icons.check_circle 
                            : isRejected 
                                ? Icons.cancel 
                                : Icons.access_time,
                        size: 80,
                        color: isApproved 
                            ? Colors.green 
                            : isRejected 
                                ? Colors.red 
                                : AppTheme.primaryColor,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      isApproved 
                          ? 'Application Approved!' 
                          : isRejected 
                              ? 'Application Rejected' 
                              : 'Under Review',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      isApproved
                          ? 'Congratulations! You have been approved to become a driver. You can now start accepting rides.'
                          : isRejected
                              ? 'We are sorry, but your application has been rejected. Please contact support for more information.'
                              : 'Thank you for applying to become a driver. We have received your documents and they are currently under review.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 24),

                    if (!isApproved && !isRejected)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: AppTheme.secondaryColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Estimated Review Time',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '24 - 48 Hours',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 700.ms).slideX(),

                    const SizedBox(height: 32),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isApproved) {
                            // Update User Role and Navigate
                            final user = await ref.read(databaseServiceProvider).getUser(userId!);
                            if (user != null) {
                              final updatedUser = UserModel(
                                id: user.id,
                                email: user.email,
                                displayName: user.displayName,
                                phoneNumber: user.phoneNumber,
                                photoUrl: user.photoUrl,
                                role: 'driver', // Update role
                                walletBalance: user.walletBalance,
                                homeAddress: user.homeAddress,
                                workAddress: user.workAddress,
                                createdAt: user.createdAt,
                              );
                              await ref.read(databaseServiceProvider).updateUser(updatedUser);
                              if (context.mounted) context.go('/driver');
                            }
                          } else {
                            context.go('/');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isApproved ? AppTheme.primaryColor : Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isApproved ? 'Start Driving' : 'Back to Home',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ).animate().fadeIn(delay: 900.ms),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
