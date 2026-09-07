import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// Wrapper that shows a connectivity banner when the device goes offline.
/// Automatically hides when connectivity is restored.
class ConnectivityWrapper extends StatefulWidget {
  const ConnectivityWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline && mounted) {
        setState(() => _isOffline = offline);
      }
    });

    // Check initial state
    Connectivity().checkConnectivity().then((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline && mounted) {
        setState(() => _isOffline = offline);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOffline ? 36 : 0,
          color: context.palette.danger,
          child: _isOffline
              ? Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: context.palette.onBrand, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'No internet connection',
                        style: TextStyle(
                          color: context.palette.onBrand,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}
