import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

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
      if (!mounted) return;
      final isOffline = results.contains(ConnectivityResult.none);
      if (_isOffline != isOffline) {
        setState(() => _isOffline = isOffline);
        if (_isOffline) {
          _showOfflineBanner();
        } else {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        }
      }
    });
  }

  void _showOfflineBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.redAccent,
        content: const Text(
          'No Internet Connection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: const Icon(Icons.wifi_off, color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
