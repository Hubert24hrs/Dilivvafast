import 'package:fast_delivery/core/models/driver_application_model.dart';
import 'package:fast_delivery/core/providers/providers.dart';
import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:fast_delivery/presentation/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDriversTab extends ConsumerStatefulWidget {
  const AdminDriversTab({super.key});

  @override
  ConsumerState<AdminDriversTab> createState() => _AdminDriversTabState();
}

class _AdminDriversTabState extends ConsumerState<AdminDriversTab> {
  @override
  Widget build(BuildContext context) {
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
