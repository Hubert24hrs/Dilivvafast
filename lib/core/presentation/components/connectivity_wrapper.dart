import 'package:flutter/material.dart';

/// Wrapper that shows a connectivity banner when offline
class ConnectivityWrapper extends StatelessWidget {
  const ConnectivityWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO(dev): Implement real connectivity monitoring with connectivity_plus
    return child;
  }
}
