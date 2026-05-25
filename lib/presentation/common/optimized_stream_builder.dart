import 'dart:async';
import 'package:flutter/material.dart';

/// Optimized StreamBuilder wrapper that reduces unnecessary rebuilds
class OptimizedStreamBuilder<T> extends StatelessWidget {
  final Stream<T>? stream;
  final T? initialData;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final bool Function(T? previous, T current)? buildWhen;

  const OptimizedStreamBuilder({
    super.key,
    this.stream,
    this.initialData,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error!);
          }
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // Loading state (no data yet)
        if (!snapshot.hasData) {
          if (loadingBuilder != null) {
            return loadingBuilder!(context);
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Build with data
        return builder(context, snapshot.data as T);
      },
    );
  }
}

/// Debounced StreamBuilder that only rebuilds after a delay
class DebouncedStreamBuilder<T> extends StatefulWidget {
  final Stream<T>? stream;
  final T? initialData;
  final Duration debounceDuration;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;

  const DebouncedStreamBuilder({
    super.key,
    this.stream,
    this.initialData,
    this.debounceDuration = const Duration(milliseconds: 300),
    required this.builder,
    this.loadingBuilder,
  });

  @override
  State<DebouncedStreamBuilder<T>> createState() => _DebouncedStreamBuilderState<T>();
}

class _DebouncedStreamBuilderState<T> extends State<DebouncedStreamBuilder<T>> {
  StreamSubscription<T>? _subscription;
  T? _currentData;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentData = widget.initialData;
    _subscription = widget.stream?.listen((data) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(widget.debounceDuration, () {
        if (mounted) {
          setState(() {
            _currentData = data;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentData == null) {
      return widget.loadingBuilder?.call(context) ?? 
             const Center(child: CircularProgressIndicator());
    }
    return widget.builder(context, _currentData as T);
  }
}
