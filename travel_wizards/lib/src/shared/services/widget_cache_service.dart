import 'dart:collection';

import 'package:flutter/material.dart';

/// Service for caching widgets to improve performance
class WidgetCacheService {
  static WidgetCacheService? _instance;

  static WidgetCacheService get instance {
    _instance ??= WidgetCacheService._();
    return _instance!;
  }

  WidgetCacheService._();

  final Map<String, Widget> _widgetCache = HashMap();
  final Map<String, DateTime> _cacheTimestamps = HashMap();
  final Duration _cacheExpiration = const Duration(minutes: 30);
  int _maxCacheSize = 100;

  /// Set maximum cache size
  void setMaxCacheSize(int size) {
    _maxCacheSize = size;
    _evictOldEntries();
  }

  /// Cache a widget with a unique key
  void cacheWidget(String key, Widget widget) {
    // Remove expired entries first
    _removeExpiredEntries();

    // If cache is full, remove oldest entry
    if (_widgetCache.length >= _maxCacheSize) {
      _evictOldestEntry();
    }

    _widgetCache[key] = widget;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Get a cached widget
  Widget? getCachedWidget(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;

    // Check if cache entry is expired
    if (DateTime.now().difference(timestamp) > _cacheExpiration) {
      _widgetCache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }

    return _widgetCache[key];
  }

  /// Check if a widget is cached
  bool isWidgetCached(String key) {
    return getCachedWidget(key) != null;
  }

  /// Clear specific cached widget
  void clearCachedWidget(String key) {
    _widgetCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Clear all cached widgets
  void clearAllCache() {
    _widgetCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache statistics
  CacheStatistics getCacheStatistics() {
    _removeExpiredEntries();

    return CacheStatistics(
      totalEntries: _widgetCache.length,
      maxSize: _maxCacheSize,
      memoryUsageKB: _estimateMemoryUsage(),
      hitRate: 0.0, // Would need to track hits/misses for accurate calculation
    );
  }

  void _removeExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiration) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _widgetCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  void _evictOldEntries() {
    while (_widgetCache.length > _maxCacheSize) {
      _evictOldestEntry();
    }
  }

  void _evictOldestEntry() {
    if (_cacheTimestamps.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cacheTimestamps.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _widgetCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
  }

  double _estimateMemoryUsage() {
    // Rough estimation - in a real app you'd want more accurate memory measurement
    return _widgetCache.length * 2.0; // 2KB per widget estimate
  }
}

/// Cache statistics data class
class CacheStatistics {
  final int totalEntries;
  final int maxSize;
  final double memoryUsageKB;
  final double hitRate;

  const CacheStatistics({
    required this.totalEntries,
    required this.maxSize,
    required this.memoryUsageKB,
    required this.hitRate,
  });

  double get utilizationPercentage =>
      maxSize > 0 ? (totalEntries / maxSize) * 100 : 0;
}

/// Widget that automatically caches its child
class CachedWidget extends StatelessWidget {
  final String cacheKey;
  final Widget Function() builder;
  final bool enableCaching;
  final Duration? customExpiration;

  const CachedWidget({
    super.key,
    required this.cacheKey,
    required this.builder,
    this.enableCaching = true,
    this.customExpiration,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableCaching) {
      return builder();
    }

    // Try to get from cache first
    final cached = WidgetCacheService.instance.getCachedWidget(cacheKey);
    if (cached != null) {
      return cached;
    }

    // Build and cache the widget
    final widget = builder();
    WidgetCacheService.instance.cacheWidget(cacheKey, widget);

    return widget;
  }
}

/// Mixin for widgets that want to implement their own caching
mixin WidgetCacheMixin<T extends StatelessWidget> on StatelessWidget {
  String get cacheKey;
  bool get enableCaching => true;

  Widget buildCached(BuildContext context);

  @override
  Widget build(BuildContext context) {
    if (!enableCaching) {
      return buildCached(context);
    }

    final cached = WidgetCacheService.instance.getCachedWidget(cacheKey);
    if (cached != null) {
      return cached;
    }

    final widget = buildCached(context);
    WidgetCacheService.instance.cacheWidget(cacheKey, widget);

    return widget;
  }
}

/// Memory-efficient ListView with widget caching
class CachedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String Function(T item, int index) cacheKeyBuilder;
  final ScrollController? scrollController;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool enableCaching;

  const CachedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.cacheKeyBuilder,
    this.scrollController,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.enableCaching = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final cacheKey = cacheKeyBuilder(item, index);

        return CachedWidget(
          cacheKey: cacheKey,
          enableCaching: enableCaching,
          builder: () =>
              RepaintBoundary(child: itemBuilder(context, item, index)),
        );
      },
    );
  }
}

/// Performance-optimized grid view
class OptimizedGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.scrollController,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }
}

/// Widget that builds only when visible in viewport
class ViewportAwareWidget extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final Widget? placeholder;
  final double threshold;

  const ViewportAwareWidget({
    super.key,
    required this.builder,
    this.placeholder,
    this.threshold = 0.1,
  });

  @override
  State<ViewportAwareWidget> createState() => _ViewportAwareWidgetState();
}

class _ViewportAwareWidgetState extends State<ViewportAwareWidget> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Simplified visibility detection
        // In a real implementation, you'd use proper viewport detection
        if (!_isVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isVisible = true;
              });
            }
          });
        }

        if (_isVisible) {
          return widget.builder(context);
        }

        return widget.placeholder ??
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            );
      },
    );
  }
}
