import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:travel_wizards/src/services/performance_service.dart';
import 'package:travel_wizards/src/services/widget_cache_service.dart';
import 'package:travel_wizards/src/services/asset_optimization_service.dart';
import 'package:travel_wizards/src/widgets/performance/performance_monitor.dart'
    as pm;

/// Central manager for all performance optimizations
class PerformanceOptimizationManager {
  static PerformanceOptimizationManager? _instance;

  static PerformanceOptimizationManager get instance {
    _instance ??= PerformanceOptimizationManager._();
    return _instance!;
  }

  PerformanceOptimizationManager._();

  bool _isInitialized = false;

  /// Initialize all performance optimization services
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🚀 Initializing Performance Optimization Manager...');

    try {
      // Initialize performance monitoring
      PerformanceService.instance.setProfilingEnabled(kDebugMode);
      PerformanceService.instance.startFrameMonitoring();

      // Configure widget cache
      WidgetCacheService.instance.setMaxCacheSize(100);

      // Preload critical assets
      await AssetOptimizationService.instance.preloadCriticalAssets();

      // Optimize image cache
      await PerformanceService.instance.optimizeImageCache();

      _isInitialized = true;
      debugPrint('✅ Performance Optimization Manager initialized successfully');

      // Log initial performance state
      _logPerformanceStatus();
    } catch (e) {
      debugPrint('❌ Failed to initialize Performance Optimization Manager: $e');
    }
  }

  /// Preload assets for a specific screen
  Future<void> preloadScreenAssets(
    String screenName,
    List<String> assetPaths,
  ) async {
    PerformanceService.instance.startTimer('preload_$screenName');

    try {
      await AssetOptimizationService.instance.batchPreloadAssets(assetPaths);
      debugPrint(
        '✅ Preloaded assets for $screenName: ${assetPaths.length} assets',
      );
    } catch (e) {
      debugPrint('❌ Failed to preload assets for $screenName: $e');
    } finally {
      PerformanceService.instance.stopTimer('preload_$screenName');
    }
  }

  /// Optimize memory usage
  Future<void> optimizeMemory() async {
    PerformanceService.instance.startTimer('memory_optimization');

    try {
      // Clear expired widget cache
      final cacheStats = WidgetCacheService.instance.getCacheStatistics();
      debugPrint(
        'Widget cache before cleanup: ${cacheStats.totalEntries} entries, ${cacheStats.memoryUsageKB}KB',
      );

      // Clear old cached widgets (would implement smart eviction in real app)
      if (cacheStats.utilizationPercentage > 80) {
        WidgetCacheService.instance.clearAllCache();
        debugPrint('Widget cache cleared due to high utilization');
      }

      // Optimize image cache
      await PerformanceService.instance.optimizeImageCache();

      // Clear expired assets
      AssetOptimizationService.instance.clearAssetCache();

      debugPrint('✅ Memory optimization completed');
    } catch (e) {
      debugPrint('❌ Memory optimization failed: $e');
    } finally {
      PerformanceService.instance.stopTimer('memory_optimization');
    }
  }

  /// Get comprehensive performance report
  Future<PerformanceReport> getPerformanceReport() async {
    final performanceSummary = PerformanceService.instance
        .getPerformanceSummary();
    final cacheStats = WidgetCacheService.instance.getCacheStatistics();
    final assetStats = AssetOptimizationService.instance
        .getAssetCacheStatistics();
    final memoryInfo = await PerformanceService.instance.getMemoryInfo();

    return PerformanceReport(
      performanceSummary: performanceSummary,
      widgetCacheStats: cacheStats,
      assetCacheStats: assetStats,
      memoryInfo: memoryInfo,
      timestamp: DateTime.now(),
    );
  }

  /// Schedule periodic optimization
  void schedulePeriodicOptimization() {
    if (!kDebugMode) return; // Only in debug mode

    // Run optimization every 5 minutes in debug mode
    Stream.periodic(const Duration(minutes: 5)).listen((_) {
      optimizeMemory();
      _logPerformanceStatus();
    });
  }

  /// Log current performance status
  void _logPerformanceStatus() {
    if (!kDebugMode) return;

    final summary = PerformanceService.instance.getPerformanceSummary();
    final cacheStats = WidgetCacheService.instance.getCacheStatistics();
    final assetStats = AssetOptimizationService.instance
        .getAssetCacheStatistics();

    debugPrint('📊 Performance Status:');
    debugPrint(
      '   Operations: ${summary.totalOperations}, Avg: ${summary.averageOperationTime.toStringAsFixed(1)}ms',
    );
    debugPrint(
      '   Widget Cache: ${cacheStats.totalEntries} entries (${cacheStats.utilizationPercentage.toStringAsFixed(1)}% full)',
    );
    debugPrint(
      '   Asset Cache: ${assetStats.cachedAssets} assets (${assetStats.totalSizeMB.toStringAsFixed(1)}MB)',
    );
  }

  /// Clear all caches and reset performance tracking
  void resetPerformanceTracking() {
    PerformanceService.instance.clearMetrics();
    WidgetCacheService.instance.clearAllCache();
    AssetOptimizationService.instance.clearAssetCache();

    debugPrint('🔄 Performance tracking reset');
  }

  /// Configure performance settings for production
  void configureForProduction() {
    PerformanceService.instance.setProfilingEnabled(false);
    WidgetCacheService.instance.setMaxCacheSize(
      50,
    ); // Smaller cache for production

    debugPrint('🏭 Performance configured for production');
  }

  /// Configure performance settings for development
  void configureForDevelopment() {
    PerformanceService.instance.setProfilingEnabled(true);
    WidgetCacheService.instance.setMaxCacheSize(
      200,
    ); // Larger cache for development
    schedulePeriodicOptimization();

    debugPrint('🛠 Performance configured for development');
  }
}

/// Comprehensive performance report
class PerformanceReport {
  final PerformanceSummary performanceSummary;
  final CacheStatistics widgetCacheStats;
  final AssetCacheStatistics assetCacheStats;
  final MemoryInfo memoryInfo;
  final DateTime timestamp;

  const PerformanceReport({
    required this.performanceSummary,
    required this.widgetCacheStats,
    required this.assetCacheStats,
    required this.memoryInfo,
    required this.timestamp,
  });

  /// Get overall performance score (0-100)
  double get performanceScore {
    double score = 100;

    // Deduct points for slow operations
    if (performanceSummary.averageOperationTime > 100) {
      score -= 20;
    } else if (performanceSummary.averageOperationTime > 50) {
      score -= 10;
    }

    // Deduct points for high memory usage
    if (memoryInfo.usagePercentage > 80) {
      score -= 30;
    } else if (memoryInfo.usagePercentage > 60) {
      score -= 15;
    }

    // Deduct points for cache inefficiency
    if (widgetCacheStats.utilizationPercentage > 90) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }

  /// Get performance grade (A-F)
  String get performanceGrade {
    final score = performanceScore;
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// Get performance recommendations
  List<String> get recommendations {
    final recommendations = <String>[];

    if (performanceSummary.averageOperationTime > 100) {
      recommendations.add('Consider optimizing slow operations');
    }

    if (memoryInfo.usagePercentage > 70) {
      recommendations.add(
        'High memory usage detected - consider clearing caches',
      );
    }

    if (widgetCacheStats.utilizationPercentage > 85) {
      recommendations.add(
        'Widget cache is nearly full - consider increasing size or clearing old entries',
      );
    }

    if (assetCacheStats.totalSizeMB > 100) {
      recommendations.add(
        'Asset cache is large - consider optimizing asset sizes',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add('Performance looks good! 🎉');
    }

    return recommendations;
  }
}

/// Widget that automatically applies performance optimizations
class PerformanceOptimizedApp extends StatefulWidget {
  final Widget child;
  final bool enableMonitoring;
  final List<String> criticalAssets;

  const PerformanceOptimizedApp({
    super.key,
    required this.child,
    this.enableMonitoring = false,
    this.criticalAssets = const [],
  });

  @override
  State<PerformanceOptimizedApp> createState() =>
      _PerformanceOptimizedAppState();
}

class _PerformanceOptimizedAppState extends State<PerformanceOptimizedApp> {
  @override
  void initState() {
    super.initState();
    _initializePerformance();
  }

  Future<void> _initializePerformance() async {
    await PerformanceOptimizationManager.instance.initialize();

    if (widget.criticalAssets.isNotEmpty) {
      await PerformanceOptimizationManager.instance.preloadScreenAssets(
        'app_startup',
        widget.criticalAssets,
      );
    }

    if (kDebugMode) {
      PerformanceOptimizationManager.instance.configureForDevelopment();
    } else {
      PerformanceOptimizationManager.instance.configureForProduction();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;

    if (widget.enableMonitoring) {
      content = pm.PerformanceMonitor(child: content, showOverlay: kDebugMode);
    }

    // Ensure Directionality exists for overlays using AlignmentDirectional
    if (Directionality.maybeOf(context) == null) {
      content = Directionality(
        textDirection: TextDirection.ltr,
        child: content,
      );
    }

    return content;
  }
}

/// Mixin for screens that want to optimize their performance
mixin PerformanceOptimizedScreen<T extends StatefulWidget> on State<T> {
  String get screenName;
  List<String> get preloadAssets => [];

  @override
  void initState() {
    super.initState();
    _optimizeScreen();
  }

  Future<void> _optimizeScreen() async {
    PerformanceService.instance.startTimer('screen_load_$screenName');

    if (preloadAssets.isNotEmpty) {
      await PerformanceOptimizationManager.instance.preloadScreenAssets(
        screenName,
        preloadAssets,
      );
    }

    PerformanceService.instance.stopTimer('screen_load_$screenName');
  }

  @override
  void dispose() {
    // Could implement screen-specific cleanup here
    super.dispose();
  }
}
