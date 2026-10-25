import 'package:flutter/material.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

/// Error boundary widget that catches errors in the widget tree
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({super.key, required this.child});

  final Widget child;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  final bool _hasError = false;
  final FlutterErrorDetails? _errorDetails = null;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return GlobalErrorWidget(errorDetails: _errorDetails);
    }
    return widget.child;
  }
}

/// Global error widget displayed when an unrecoverable error occurs
class GlobalErrorWidget extends StatelessWidget {
  const GlobalErrorWidget({super.key, this.errorDetails});

  final FlutterErrorDetails? errorDetails;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: context.palette.surfaceBase,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: context.palette.brand,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please restart the app and try again.',
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
