import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:travel_wizards/src/services/performance_service.dart';
import 'package:travel_wizards/src/services/performance_optimization_manager.dart';

/// Widget that shows performance metrics in debug mode
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
  bool _showMetrics = false;
  PerformanceReport? _lastReport;

  @override
  void initState() {
    super.initState();
    if (widget.showOverlay) {
      _updateMetrics();
      // Update metrics every 2 seconds
      Stream.periodic(const Duration(seconds: 2)).listen((_) {
        if (mounted) _updateMetrics();
      });
    }
  }

  Future<void> _updateMetrics() async {
    try {
      final report = await PerformanceOptimizationManager.instance
          .getPerformanceReport();
      if (mounted) {
        setState(() {
          _lastReport = report;
        });
      }
    } catch (e) {
      debugPrint('Failed to update performance metrics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay && kDebugMode) ...[
          // Performance toggle button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _showMetrics = !_showMetrics;
                });
              },
              backgroundColor: Colors.blue.withOpacity(0.8),
              child: Icon(
                _showMetrics ? Icons.close : Icons.analytics,
                color: Colors.white,
              ),
            ),
          ),
          // Performance metrics overlay
          if (_showMetrics && _lastReport != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              right: 10,
              child: PerformanceMetricsCard(report: _lastReport!),
            ),
        ],
      ],
    );
  }
}

/// Card that displays performance metrics
class PerformanceMetricsCard extends StatelessWidget {
  final PerformanceReport report;

  const PerformanceMetricsCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with score
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Text(
                'Performance ${report.performanceGrade}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getScoreColor(report.performanceScore),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${report.performanceScore.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Performance metrics
          _buildMetricRow(
            'Operations',
            '${report.performanceSummary.totalOperations}',
            'Avg: ${report.performanceSummary.averageOperationTime.toStringAsFixed(1)}ms',
          ),
          _buildMetricRow(
            'Memory',
            '${report.memoryInfo.usedMemoryMB.toStringAsFixed(1)}MB',
            '${report.memoryInfo.usagePercentage.toStringAsFixed(1)}%',
          ),
          _buildMetricRow(
            'Widget Cache',
            '${report.widgetCacheStats.totalEntries}',
            '${report.widgetCacheStats.utilizationPercentage.toStringAsFixed(1)}%',
          ),
          _buildMetricRow(
            'Asset Cache',
            '${report.assetCacheStats.cachedAssets}',
            '${report.assetCacheStats.totalSizeMB.toStringAsFixed(1)}MB',
          ),

          const SizedBox(height: 8),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Optimize',
                  Icons.speed,
                  () =>
                      PerformanceOptimizationManager.instance.optimizeMemory(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'Reset',
                  Icons.refresh,
                  () => PerformanceOptimizationManager.instance
                      .resetPerformanceTracking(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            detail,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 28,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.orange;
    if (score >= 70) return Colors.deepOrange;
    return Colors.red;
  }
}

/// Performance profiler widget for wrapping expensive operations
class PerformanceProfiler extends StatefulWidget {
  final Widget child;
  final String operationName;
  final bool enabled;

  const PerformanceProfiler({
    super.key,
    required this.child,
    required this.operationName,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceProfiler> createState() => _PerformanceProfilerState();
}

class _PerformanceProfilerState extends State<PerformanceProfiler> {
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      PerformanceService.instance.startTimer(widget.operationName);
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      PerformanceService.instance.stopTimer(widget.operationName);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Utility class for one-off performance measurements
class PerformanceTimer {
  static final Map<String, Stopwatch> _timers = {};

  static void start(String name) {
    if (!kDebugMode) return;

    _timers[name] = Stopwatch()..start();
    PerformanceService.instance.startTimer(name);
  }

  static void stop(String name) {
    if (!kDebugMode) return;

    final timer = _timers.remove(name);
    if (timer != null) {
      timer.stop();
      debugPrint('⏱ $name: ${timer.elapsedMilliseconds}ms');
    }
    PerformanceService.instance.stopTimer(name);
  }

  static T measure<T>(String name, T Function() operation) {
    if (!kDebugMode) return operation();

    start(name);
    try {
      return operation();
    } finally {
      stop(name);
    }
  }

  static Future<T> measureAsync<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) return await operation();

    start(name);
    try {
      return await operation();
    } finally {
      stop(name);
    }
  }
}
