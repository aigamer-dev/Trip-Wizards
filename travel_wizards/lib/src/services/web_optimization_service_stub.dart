import 'package:flutter/foundation.dart';

/// Fallback (non-web) implementation to avoid importing dart:html on mobile/desktop.
class WebOptimizationService {
  static WebOptimizationService? _instance;
  static WebOptimizationService get instance {
    _instance ??= WebOptimizationService._();
    return _instance!;
  }

  WebOptimizationService._();

  bool _isInitialized = false;
  WebConfiguration _configuration = const WebConfiguration(
    browserName: 'non-web',
    userAgent: 'n/a',
    capabilities: [],
    supportsPWA: false,
    isOnline: true,
  );

  Future<void> initialize() async {
    // No-op on non-web platforms
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('WebOptimizationService (stub) initialized');
    }
  }

  WebConfiguration get configuration => _configuration;
  bool get isInitialized => _isInitialized;
  bool get isOnline => true;
  void showInstallPrompt() {}
}

class WebConfiguration {
  final String browserName;
  final String userAgent;
  final List<String> capabilities;
  final bool supportsPWA;
  final bool isOnline;

  const WebConfiguration({
    required this.browserName,
    required this.userAgent,
    required this.capabilities,
    required this.supportsPWA,
    required this.isOnline,
  });

  bool hasCapability(String capability) => false;
  String get description => 'Non-web platform';
  bool get isModernBrowser => false;
}
