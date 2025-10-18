import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/services/error_handling_service.dart';

/// A widget that handles async operations with proper error handling and loading states.
///
/// Provides consistent error handling, loading indicators, and user feedback
/// for async operations throughout the app.
class AsyncBuilder<T> extends StatefulWidget {
  const AsyncBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.initialData,
    this.context,
    this.showUserErrors = true,
  });

  /// The async operation to execute
  final Future<T> Function() future;

  /// Builder for the success state
  final Widget Function(BuildContext context, T data) builder;

  /// Optional custom loading widget
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Optional custom error widget
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Initial data to show before future completes
  final T? initialData;

  /// Context for error handling
  final String? context;

  /// Whether to show user-friendly error messages
  final bool showUserErrors;

  @override
  State<AsyncBuilder<T>> createState() => _AsyncBuilderState<T>();
}

class _AsyncBuilderState<T> extends State<AsyncBuilder<T>> {
  late Future<T?> _future;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _future = _executeWithErrorHandling();
  }

  Future<T?> _executeWithErrorHandling() async {
    return ErrorHandlingService.instance.handleAsync(
      widget.future,
      context: widget.context,
      userContext: mounted ? context : null,
      showUserError: widget.showUserErrors,
    );
  }

  void _retry() {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _future = _executeWithErrorHandling();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T?>(
      future: _future,
      initialData: widget.initialData,
      builder: (context, snapshot) {
        // Reset retry flag when future completes
        if (snapshot.connectionState != ConnectionState.waiting &&
            _isRetrying) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _isRetrying = false);
            }
          });
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              _buildDefaultErrorWidget(context, snapshot.error!);
        }

        // Success state
        if (snapshot.hasData && snapshot.data != null) {
          return widget.builder(context, snapshot.data as T);
        }

        // No data state
        return _buildNoDataWidget(context);
      },
    );
  }

  Widget _buildDefaultErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isRetrying ? null : _retry,
              icon: _isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isRetrying ? 'Retrying...' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isRetrying ? null : _retry,
              icon: _isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isRetrying ? 'Loading...' : 'Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A convenient wrapper for StreamBuilder with error handling
class AsyncStreamBuilder<T> extends StatelessWidget {
  const AsyncStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.initialData,
    this.context,
  });

  /// The stream to listen to
  final Stream<T> stream;

  /// Builder for the success state
  final Widget Function(BuildContext context, T data) builder;

  /// Optional custom loading widget
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Optional custom error widget
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Initial data to show before stream emits
  final T? initialData;

  /// Context for error handling
  final String? context;

  @override
  Widget build(BuildContext buildContext) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (snapshot.hasError) {
          // Log error
          ErrorHandlingService.instance.handleError(
            snapshot.error!,
            context: this.context ?? 'Stream Error',
            showToUser: false,
          );

          return errorBuilder?.call(context, snapshot.error!) ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connection error',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
        }

        // Success state
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        // Default loading state
        return loadingBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator());
      },
    );
  }
}
