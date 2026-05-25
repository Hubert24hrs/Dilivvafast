import 'package:flutter/material.dart';

/// Error boundary widget that catches errors in the widget tree.
/// Wraps a child widget and displays a fallback UI if a rendering error occurs.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({super.key, required this.child});

  final Widget child;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    // Override the error widget builder to catch rendering errors
    ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorDetails = details;
          });
        }
      });
      return const SizedBox.shrink();
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return GlobalErrorWidget(
        errorDetails: _errorDetails,
        onRetry: () => setState(() {
          _hasError = false;
          _errorDetails = null;
        }),
      );
    }
    return widget.child;
  }
}

/// Global error widget displayed when an unrecoverable error occurs
class GlobalErrorWidget extends StatelessWidget {
  const GlobalErrorWidget({
    super.key,
    this.errorDetails,
    this.onRetry,
  });

  final FlutterErrorDetails? errorDetails;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFFF6B00),
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'An unexpected error occurred.\nPlease try again.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
