import 'package:dilivvafast/core/models/driver_application_model.dart';
import 'package:dilivvafast/core/models/rider_payment_status.dart';
import 'package:dilivvafast/core/providers/providers.dart';
import 'package:dilivvafast/core/theme/app_theme.dart';
import 'package:dilivvafast/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDriversTab extends ConsumerStatefulWidget {
  const AdminDriversTab({super.key});

  @override
  ConsumerState<AdminDriversTab> createState() => _AdminDriversTabState();
}

class _AdminDriversTabState extends ConsumerState<AdminDriversTab> {
  int _currentTab = 0; // 0 = Applications, 1 = Blocked (Red Status)

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom segmented control matching cyberpunk theme
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _currentTab == 0
                            ? AppTheme.primaryColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: _currentTab == 0
                            ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3))
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Center(
                        child: Text(
                          'Applications',
                          style: TextStyle(
                            color: _currentTab == 0 ? AppTheme.primaryColor : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _currentTab == 1
                            ? Colors.red.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: _currentTab == 1
                            ? Border.all(color: Colors.red.withValues(alpha: 0.3))
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Center(
                        child: Text(
                          'Blocked (Red Status)',
                          style: TextStyle(
                            color: _currentTab == 1 ? Colors.red : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        Expanded(
          child: _currentTab == 0
              ? _buildApplicationsView()
              : _buildBlockedRidersView(),
        ),
      ],
    );
  }

  Widget _buildApplicationsView() {
    return StreamBuilder<List<DriverApplicationModel>>(
      stream: ref.watch(adminServiceProvider).getPendingDriverApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final apps = snapshot.data ?? [];

        if (apps.isEmpty) {
          return const Center(
            child: Text(
              'No pending driver applications',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            return _buildDriverCard(apps[index]);
          },
        );
      },
    );
  }

  Widget _buildBlockedRidersView() {
    final paymentService = ref.watch(riderPaymentServiceProvider);
    return StreamBuilder<List<RiderPaymentStatus>>(
      stream: paymentService.blockedRidersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        final blockedList = snapshot.data ?? [];

        if (blockedList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                const SizedBox(height: 12),
                Text(
                  'No riders are currently blocked!',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: blockedList.length,
          itemBuilder: (context, index) {
            return _buildBlockedRiderCard(blockedList[index]);
          },
        );
      },
    );
  }

  Widget _buildBlockedRiderCard(RiderPaymentStatus status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<dynamic>(
            future: ref.read(databaseServiceProvider).getUser(status.riderId),
            builder: (context, userSnap) {
              final user = userSnap.data;
              final name = user != null 
                  ? (user.fullName ?? user.name ?? 'Unknown Rider') 
                  : 'Rider: ${status.riderId.length > 6 ? '${status.riderId.substring(0, 6)}...' : status.riderId}';
              final phone = user != null ? (user.phoneNumber ?? 'No Phone') : 'Loading...';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.lock_person, color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Phone: $phone',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Due badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '₦${status.accumulatedDebt.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rides in cycle: ${status.completedRidesCount} completed',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        status.lastPaymentAt != null
                            ? 'Last paid: ${status.lastPaymentAt!.day}/${status.lastPaymentAt!.month}'
                            : 'No payment recorded',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _clearRiderDebt(status.riderId),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text(
                        'FORCE UNBLOCK & CLEAR DEBT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withValues(alpha: 0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _clearRiderDebt(String riderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Confirm Action', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to manually clear this rider\'s debt and unblock them? Use this if they settled platform fees offline.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('YES, UNBLOCK'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(riderPaymentServiceProvider).clearDebtAndUnblock(riderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rider unblocked and debt cleared successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildDriverCard(DriverApplicationModel app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white10,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${app.vehicleMake} ${app.vehicleModel} (${app.vehicleYear})',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          app.phoneNumber,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(app.id, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      child: const Text('DECLINE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showDriverDocuments(context, app),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        side: const BorderSide(color: Colors.blueAccent),
                      ),
                      child: const Text('DOCS'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(app.id, 'approved', app),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('APPROVE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDriverDocuments(BuildContext context, DriverApplicationModel app) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surfaceColor,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${app.fullName}\'s Documents',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDocItem('License', app.licenseUrl),
              _buildDocItem('Registration', app.registrationUrl),
              _buildDocItem('Insurance', app.insuranceUrl),
              _buildDocItem('Permit (Courier)', app.permitUrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocItem(String label, String? url) {
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.white10,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (c, o, s) => Container(
                height: 200,
                color: Colors.red.withValues(alpha: 0.1),
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String userId, String status, [DriverApplicationModel? app]) async {
    try {
      if (status == 'approved' && app != null) {
        await ref.read(adminServiceProvider).approveDriver(userId, app);
      } else {
        await ref.read(adminServiceProvider).rejectDriver(userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application $status successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
