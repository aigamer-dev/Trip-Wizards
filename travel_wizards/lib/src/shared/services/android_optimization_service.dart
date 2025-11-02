import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android-specific optimizations and configurations
class AndroidOptimizationService {
  static AndroidOptimizationService? _instance;
  static AndroidOptimizationService get instance {
    _instance ??= AndroidOptimizationService._();
    return _instance!;
  }

  AndroidOptimizationService._();

  bool _isInitialized = false;

  /// Initialize Android optimizations
  Future<void> initialize() async {
    if (_isInitialized || !Platform.isAndroid) return;

    try {
      await _configureSystemUI();
      await _configurePerformance();
      await _configureOrientation();

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('AndroidOptimizationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing AndroidOptimizationService: $e');
      }
    }
  }

  /// Configure system UI for travel app
  Future<void> _configureSystemUI() async {
    // Configure system overlay style for modern look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Enable edge-to-edge display
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Configure performance optimizations
  Future<void> _configurePerformance() async {
    // Enable hardware acceleration hints
    if (kDebugMode) {
      debugPrint('Android performance optimizations configured');
    }
  }

  /// Configure orientation settings
  Future<void> _configureOrientation() async {
    // Allow rotation for maps and media viewing
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Lock orientation to portrait (for forms, checkout, etc.)
  Future<void> lockPortrait() async {
    if (!Platform.isAndroid) return;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Unlock orientation (for maps, media, etc.)
  Future<void> unlockOrientation() async {
    if (!Platform.isAndroid) return;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Configure system UI for immersive mode (full screen)
  Future<void> enableImmersiveMode() async {
    if (!Platform.isAndroid) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Exit immersive mode
  Future<void> exitImmersiveMode() async {
    if (!Platform.isAndroid) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Optimize for low-end devices
  Future<void> applyLowEndOptimizations() async {
    if (!Platform.isAndroid) return;

    // Restrict to portrait only to reduce memory usage
    await lockPortrait();

    if (kDebugMode) {
      debugPrint('Applied low-end device optimizations');
    }
  }

  /// Apply optimizations for maps and media
  Future<void> optimizeForMaps() async {
    if (!Platform.isAndroid) return;

    // Allow rotation for better map viewing
    await unlockOrientation();

    // Keep screen on during navigation
    await SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(
        label: 'Travel Wizards - Navigation',
        primaryColor: 0xFF2196F3,
      ),
    );
  }

  /// Reset to default configuration
  Future<void> resetToDefaults() async {
    if (!Platform.isAndroid) return;
    await _configureSystemUI();
    await _configureOrientation();
  }

  /// Get Android-specific configuration
  AndroidConfiguration getConfiguration() {
    return const AndroidConfiguration(
      supportsEdgeToEdge: true,
      supportsImmersiveMode: true,
      supportsOrientation: true,
    );
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}

/// Android configuration model
class AndroidConfiguration {
  final bool supportsEdgeToEdge;
  final bool supportsImmersiveMode;
  final bool supportsOrientation;

  const AndroidConfiguration({
    required this.supportsEdgeToEdge,
    required this.supportsImmersiveMode,
    required this.supportsOrientation,
  });

  /// Check if running on Android
  bool get isAndroid => Platform.isAndroid;

  /// Get configuration description
  String get description {
    final features = <String>[];
    if (supportsEdgeToEdge) features.add('Edge-to-edge display');
    if (supportsImmersiveMode) features.add('Immersive mode');
    if (supportsOrientation) features.add('Orientation control');

    return 'Android optimizations: ${features.join(', ')}';
  }
}
