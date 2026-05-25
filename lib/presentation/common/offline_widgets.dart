import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Widget that displays offline banner when network is unavailable
class OfflineBanner extends StatelessWidget {
  final List<ConnectivityResult> connectivityStatus;

  const OfflineBanner({
    super.key,
    required this.connectivityStatus,
  });

  bool get isOffline => 
      !connectivityStatus.contains(ConnectivityResult.mobile) &&
      !connectivityStatus.contains(ConnectivityResult.wifi) &&
      !connectivityStatus.contains(ConnectivityResult.ethernet);

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade800,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No internet connection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Could trigger a manual retry or show more info
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Waiting for connection...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'RETRY',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget for when there's no data to show offline
class OfflineEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const OfflineEmptyState({
    super.key,
    this.message = 'No data available offline',
    this.icon = Icons.cloud_off,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('RETRY'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
