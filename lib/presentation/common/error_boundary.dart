import 'package:fast_delivery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Error boundary widget that catches and displays errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails error)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    // We don't override FlutterError.onError here as it's done globally in main.dart
  }

// ignore: unused_element
  void _handleError(FlutterErrorDetails details) {
    setState(() {
      _error = details;
    });
  }

  void _resetError() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? _DefaultErrorView(
        error: _error!,
        onRetry: _resetError,
      );
    }

    return widget.child;
  }
}

/// Default error view shown when an error occurs
class _DefaultErrorView extends StatelessWidget {
  final FlutterErrorDetails error;
  final VoidCallback onRetry;

  const _DefaultErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 32),
              
              // Error Title
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Error Message
              Text(
                'We encountered an unexpected error. Please try again.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Retry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Go Home Button
              TextButton(
                onPressed: () {
                  // Navigate to home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Go to Home',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
              
              // Debug info in debug mode
              if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                const SizedBox(height: 32),
                ExpansionTile(
                  title: const Text(
                    'Error Details (Debug)',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        error.exceptionAsString(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Global error widget that replaces the red error screen in release mode
class GlobalErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const GlobalErrorWidget({
    super.key,
    required this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please restart the app',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
