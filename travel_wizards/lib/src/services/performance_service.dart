import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for monitoring and optimizing app performance
class PerformanceService {
  static PerformanceService? _instance;

  static PerformanceService get instance {
    _instance ??= PerformanceService._();
    return _instance!;
  }

  PerformanceService._();

  final Map<String, Stopwatch> _timers = {};
  final List<PerformanceMetric> _metrics = [];
  bool _isProfilingEnabled = kDebugMode;

  /// Enable or disable performance profiling
  void setProfilingEnabled(bool enabled) {
    _isProfilingEnabled = enabled;
  }

  /// Start timing an operation
  void startTimer(String operationName) {
    if (!_isProfilingEnabled) return;

    _timers[operationName] = Stopwatch()..start();
  }

  /// Stop timing an operation and log the result
  void stopTimer(String operationName) {
    if (!_isProfilingEnabled) return;

    final timer = _timers[operationName];
    if (timer == null) return;

    timer.stop();
    final duration = timer.elapsedMilliseconds;

    _metrics.add(
      PerformanceMetric(
        operationName: operationName,
        duration: duration,
        timestamp: DateTime.now(),
      ),
    );

    _timers.remove(operationName);
  }

  /// Time an async operation
  Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startTimer(operationName);
    try {
      return await operation();
    } finally {
      stopTimer(operationName);
    }
  }

  /// Get performance metrics
  List<PerformanceMetric> getMetrics() {
    return List.unmodifiable(_metrics);
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
  }

  /// Get memory usage information
  Future<MemoryInfo> getMemoryInfo() async {
    if (kIsWeb) {
      return MemoryInfo(
        usedMemoryMB: 0,
        totalMemoryMB: 0,
        availableMemoryMB: 0,
      );
    }

    try {
      // Get VM memory stats
      final info = await _getVmMemoryInfo();
      return info;
    } catch (e) {
      debugPrint('Failed to get memory info: $e');
      return MemoryInfo(
        usedMemoryMB: 0,
        totalMemoryMB: 0,
        availableMemoryMB: 0,
      );
    }
  }

  Future<MemoryInfo> _getVmMemoryInfo() async {
    // This is a simplified implementation
    // In a real app, you might use platform channels to get actual memory info
    return MemoryInfo(
      usedMemoryMB: 50, // Placeholder
      totalMemoryMB: 200, // Placeholder
      availableMemoryMB: 150, // Placeholder
    );
  }

  /// Monitor frame rendering performance
  void startFrameMonitoring() {
    if (!_isProfilingEnabled) return;
  }

  /// Optimize images by caching and compression
  Future<void> optimizeImageCache() async {
    try {
      // Clear old cached images
      PaintingBinding.instance.imageCache.clear();

      // Set cache limits
      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes =
          50 * 1024 * 1024; // 50MB

      debugPrint('Image cache optimized');
    } catch (e) {
      debugPrint('Failed to optimize image cache: $e');
    }
  }

  /// Preload critical assets
  Future<void> preloadCriticalAssets(BuildContext context) async {
    startTimer('preload_assets');

    try {
      // Preload critical images
      await Future.wait([
        precacheImage(const AssetImage('assets/images/logo.png'), context),
        // Add other critical assets here
      ]);

      debugPrint('Critical assets preloaded');
    } catch (e) {
      debugPrint('Failed to preload assets: $e');
    } finally {
      stopTimer('preload_assets');
    }
  }

  /// Get app performance summary
  PerformanceSummary getPerformanceSummary() {
    final metrics = getMetrics();

    if (metrics.isEmpty) {
      return PerformanceSummary(
        averageOperationTime: 0,
        slowestOperation: '',
        totalOperations: 0,
        memoryUsageMB: 0,
      );
    }

    final totalTime = metrics.fold<int>(
      0,
      (sum, metric) => sum + metric.duration,
    );
    final averageTime = totalTime / metrics.length;

    final slowest = metrics.reduce((a, b) => a.duration > b.duration ? a : b);

    return PerformanceSummary(
      averageOperationTime: averageTime,
      slowestOperation: '${slowest.operationName} (${slowest.duration}ms)',
      totalOperations: metrics.length,
      memoryUsageMB: 0, // Would be populated with real memory info
    );
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String operationName;
  final int duration; // in milliseconds
  final DateTime timestamp;

  const PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
  });
}

/// Memory information data class
class MemoryInfo {
  final double usedMemoryMB;
  final double totalMemoryMB;
  final double availableMemoryMB;

  const MemoryInfo({
    required this.usedMemoryMB,
    required this.totalMemoryMB,
    required this.availableMemoryMB,
  });

  double get usagePercentage =>
      totalMemoryMB > 0 ? (usedMemoryMB / totalMemoryMB) * 100 : 0;
}

/// Performance summary data class
class PerformanceSummary {
  final double averageOperationTime;
  final String slowestOperation;
  final int totalOperations;
  final double memoryUsageMB;

  const PerformanceSummary({
    required this.averageOperationTime,
    required this.slowestOperation,
    required this.totalOperations,
    required this.memoryUsageMB,
  });
}

/// Widget for monitoring performance in debug mode
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.showOverlay = kDebugMode,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  Timer? _updateTimer;
  PerformanceSummary _summary = const PerformanceSummary(
    averageOperationTime: 0,
    slowestOperation: '',
    totalOperations: 0,
    memoryUsageMB: 0,
  );

  @override
  void initState() {
    super.initState();

    if (widget.showOverlay) {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _summary = PerformanceService.instance.getPerformanceSummary();
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay && kDebugMode)
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Performance',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ops: ${_summary.totalOperations}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                  ),
                  Text(
                    'Avg: ${_summary.averageOperationTime.toStringAsFixed(1)}ms',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
