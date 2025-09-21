import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for optimizing and managing app assets
class AssetOptimizationService {
  static AssetOptimizationService? _instance;

  static AssetOptimizationService get instance {
    _instance ??= AssetOptimizationService._();
    return _instance!;
  }

  AssetOptimizationService._();

  final Map<String, Uint8List> _assetCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheExpiration = const Duration(hours: 1);

  /// Preload critical assets
  Future<void> preloadCriticalAssets() async {
    // No-op by default to avoid 404s when assets are not declared in pubspec.
    // Screens/features should request preloads explicitly via batchPreloadAssets.
    if (kDebugMode) {
      debugPrint('Skipped global critical assets preload (none configured).');
    }
  }

  /// Preload a single asset
  Future<void> _preloadAsset(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      _assetCache[assetPath] = bytes;
      _cacheTimestamps[assetPath] = DateTime.now();

      debugPrint('Preloaded asset: $assetPath (${bytes.length} bytes)');
    } catch (e) {
      debugPrint('Failed to preload asset $assetPath: $e');
    }
  }

  /// Get cached asset bytes
  Uint8List? getCachedAsset(String assetPath) {
    final timestamp = _cacheTimestamps[assetPath];
    if (timestamp == null) return null;

    // Check if cache entry is expired
    if (DateTime.now().difference(timestamp) > _cacheExpiration) {
      _assetCache.remove(assetPath);
      _cacheTimestamps.remove(assetPath);
      return null;
    }

    return _assetCache[assetPath];
  }

  /// Load asset with caching
  Future<Uint8List> loadAssetWithCache(String assetPath) async {
    // Try cache first
    final cached = getCachedAsset(assetPath);
    if (cached != null) {
      return cached;
    }

    // Load from bundle and cache
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();

    _assetCache[assetPath] = bytes;
    _cacheTimestamps[assetPath] = DateTime.now();

    return bytes;
  }

  /// Clear asset cache
  void clearAssetCache() {
    _assetCache.clear();
    _cacheTimestamps.clear();
    debugPrint('Asset cache cleared');
  }

  /// Get asset cache statistics
  AssetCacheStatistics getAssetCacheStatistics() {
    _removeExpiredAssets();

    final totalSize = _assetCache.values.fold<int>(
      0,
      (sum, bytes) => sum + bytes.length,
    );

    return AssetCacheStatistics(
      cachedAssets: _assetCache.length,
      totalSizeBytes: totalSize,
      totalSizeMB: totalSize / (1024 * 1024),
    );
  }

  void _removeExpiredAssets() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiration) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _assetCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Optimize image assets (placeholder implementation)
  Future<Uint8List> optimizeImageAsset(
    String assetPath, {
    int? maxWidth,
    int? maxHeight,
    int quality = 80,
  }) async {
    // In a real implementation, you would:
    // 1. Load the image
    // 2. Resize if needed
    // 3. Compress with specified quality
    // 4. Return optimized bytes

    // For now, just return the original asset
    return await loadAssetWithCache(assetPath);
  }

  /// Get recommended asset format for platform
  String getRecommendedImageFormat() {
    if (kIsWeb) {
      return 'webp'; // WebP is well supported on web
    } else {
      return 'png'; // PNG for mobile for compatibility
    }
  }

  /// Batch preload assets
  Future<void> batchPreloadAssets(List<String> assetPaths) async {
    const batchSize = 5; // Process 5 assets at a time

    for (int i = 0; i < assetPaths.length; i += batchSize) {
      final batch = assetPaths.skip(i).take(batchSize).toList();

      await Future.wait(batch.map((asset) => _preloadAsset(asset)));

      // Small delay between batches to avoid overwhelming the system
      if (i + batchSize < assetPaths.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    debugPrint('Batch preloaded ${assetPaths.length} assets');
  }
}

/// Asset cache statistics
class AssetCacheStatistics {
  final int cachedAssets;
  final int totalSizeBytes;
  final double totalSizeMB;

  const AssetCacheStatistics({
    required this.cachedAssets,
    required this.totalSizeBytes,
    required this.totalSizeMB,
  });
}

/// Asset loading configuration
class AssetConfig {
  final String basePath;
  final List<String> supportedFormats;
  final int maxCacheSize;
  final Duration cacheExpiration;

  const AssetConfig({
    this.basePath = 'assets/',
    this.supportedFormats = const ['png', 'jpg', 'jpeg', 'webp'],
    this.maxCacheSize = 50 * 1024 * 1024, // 50MB
    this.cacheExpiration = const Duration(hours: 1),
  });
}

/// Optimized asset image widget
class OptimizedAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableCaching;

  const OptimizedAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableCaching = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableCaching) {
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    }

    return FutureBuilder<Uint8List>(
      future: AssetOptimizationService.instance.loadAssetWithCache(assetPath),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorBuilder(context, snapshot.error!, StackTrace.current);
        }

        if (!snapshot.hasData) {
          return placeholder ?? _defaultPlaceholder();
        }

        return Image.memory(
          snapshot.data!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: _errorBuilder,
        );
      },
    );
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return errorWidget ?? _defaultErrorWidget();
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.error_outline, color: Colors.grey),
    );
  }
}

/// Smart asset loader that chooses the best format for the platform
class SmartAssetLoader {
  static const Map<String, List<String>> _formatPriority = {
    'web': ['webp', 'png', 'jpg'],
    'mobile': ['png', 'jpg', 'webp'],
  };

  /// Load the best available asset format
  static Future<String> getBestAssetPath(String baseName) async {
    final platform = kIsWeb ? 'web' : 'mobile';
    final formats = _formatPriority[platform] ?? ['png'];

    for (final format in formats) {
      final assetPath = '$baseName.$format';
      try {
        // Check if asset exists
        await rootBundle.load(assetPath);
        return assetPath;
      } catch (e) {
        // Asset doesn't exist, try next format
        continue;
      }
    }

    // Fallback to original name
    return '$baseName.png';
  }
}

/// Lazy asset loader for images that loads when needed
class LazyAssetImage extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final double loadThreshold;

  const LazyAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.loadThreshold = 200,
  });

  @override
  State<LazyAssetImage> createState() => _LazyAssetImageState();
}

class _LazyAssetImageState extends State<LazyAssetImage> {
  bool _shouldLoad = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Simple visibility detection
        if (!_shouldLoad) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _shouldLoad = true;
              });
            }
          });
        }

        if (_shouldLoad) {
          return OptimizedAssetImage(
            assetPath: widget.assetPath,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        }

        return widget.placeholder ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[300],
            );
      },
    );
  }
}
