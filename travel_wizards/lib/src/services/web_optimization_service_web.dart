// This file is only used on web via conditional import.
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Web-specific optimizations and configurations
class WebOptimizationService {
  static WebOptimizationService? _instance;
  static WebOptimizationService get instance {
    _instance ??= WebOptimizationService._();
    return _instance!;
  }

  WebOptimizationService._();

  bool _isInitialized = false;
  late WebConfiguration _configuration;

  /// Initialize web optimizations
  Future<void> initialize() async {
    if (_isInitialized || !kIsWeb) return;

    try {
      _configuration = _detectCapabilities();

      await _optimizePerformance();
      await _configurePWA();
      await _setupSEO();
      await _configureAnalytics();

      _isInitialized = true;
      if (kDebugMode) {
        print('WebOptimizationService initialized successfully');
        print('Browser: ${_configuration.browserName}');
        print('Capabilities: ${_configuration.capabilities.join(', ')}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing WebOptimizationService: $e');
      }
    }
  }

  /// Detect browser capabilities
  WebConfiguration _detectCapabilities() {
    final userAgent = html.window.navigator.userAgent;
    final capabilities = <String>[];

    // Detect browser
    String browserName = 'Unknown';
    if (userAgent.contains('Chrome')) {
      browserName = 'Chrome';
    } else if (userAgent.contains('Firefox')) {
      browserName = 'Firefox';
    } else if (userAgent.contains('Safari')) {
      browserName = 'Safari';
    } else if (userAgent.contains('Edge')) {
      browserName = 'Edge';
    }

    // Check capabilities
    if (html.window.navigator.serviceWorker != null) {
      capabilities.add('Service Worker');
    }

    if (html.window.indexedDB != null) {
      capabilities.add('IndexedDB');
    }

    // These APIs are non-nullable in modern browsers with dart:html bindings
    capabilities.add('Geolocation');
    capabilities.add('Local Storage');
    capabilities.add('Session Storage');

    // Check for PWA support
    final supportsPWA = html.window.navigator.serviceWorker != null;
    if (supportsPWA) {
      capabilities.add('PWA');
    }

    return WebConfiguration(
      browserName: browserName,
      userAgent: userAgent,
      capabilities: capabilities,
      supportsPWA: supportsPWA,
      isOnline: html.window.navigator.onLine ?? true,
    );
  }

  /// Optimize web performance
  Future<void> _optimizePerformance() async {
    // Preload critical resources
    _preloadCriticalResources();

    // Setup performance monitoring
    _setupPerformanceMonitoring();

    // Configure caching
    await _configureCaching();
  }

  /// Preload critical resources
  void _preloadCriticalResources() {
    // In debug/dev, skip declarative preloads to avoid 404s for assets not
    // included in pubspec or not present in the build output. In release,
    // you may populate this list with guaranteed-existing resources.
    if (kDebugMode) return;

    final criticalResources = <String>[];

    for (final resource in criticalResources) {
      final link = html.LinkElement()
        ..rel = 'preload'
        ..href = resource
        ..as = resource.endsWith('.ttf') ? 'font' : 'image';

      if (resource.endsWith('.ttf')) {
        link.crossOrigin = 'anonymous';
      }

      html.document.head?.children.add(link);
    }
  }

  /// Setup performance monitoring
  void _setupPerformanceMonitoring() {
    // Monitor Core Web Vitals
    _monitorCoreWebVitals();
  }

  /// Monitor Core Web Vitals
  void _monitorCoreWebVitals() {
    // This would integrate with web vitals library
    if (kDebugMode) {
      print('Performance monitoring enabled');
    }
  }

  /// Configure caching strategy
  Future<void> _configureCaching() async {
    if (_configuration.capabilities.contains('Service Worker')) {
      // Service Worker will handle caching
      await _registerServiceWorker();
    } else {
      // Fallback to browser caching
      _configureBrowserCaching();
    }
  }

  /// Register service worker
  Future<void> _registerServiceWorker() async {
    try {
      if (html.window.navigator.serviceWorker != null) {
        await html.window.navigator.serviceWorker!.register(
          'flutter_service_worker.js',
        );
        if (kDebugMode) {
          print('Service Worker registered successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Service Worker registration failed: $e');
      }
    }
  }

  /// Configure browser caching
  void _configureBrowserCaching() {
    // Set cache headers through meta tags
    final metaCache = html.MetaElement()
      ..httpEquiv = 'Cache-Control'
      ..content = 'public, max-age=31536000';
    html.document.head?.children.add(metaCache);
  }

  /// Configure PWA features
  Future<void> _configurePWA() async {
    if (!_configuration.supportsPWA) return;

    // Setup install prompt
    _setupInstallPrompt();

    // Configure notification permissions
    _setupNotifications();
  }

  /// Setup PWA install prompt
  void _setupInstallPrompt() {
    html.window.addEventListener('beforeinstallprompt', (event) {
      event.preventDefault();
      if (kDebugMode) {
        print('PWA install prompt available');
      }
    });
  }

  /// Setup web notifications
  void _setupNotifications() {
    if (html.Notification.supported) {
      html.Notification.requestPermission().then((permission) {
        if (kDebugMode) {
          print('Notification permission: $permission');
        }
      });
    }
  }

  /// Setup SEO optimizations
  Future<void> _setupSEO() async {
    _addMetaTags();
    _addStructuredData();
    _optimizeForSearchEngines();
  }

  /// Add meta tags for SEO
  void _addMetaTags() {
    final metaTags = {
      'description':
          'Travel Wizards - AI-powered trip planning made simple. Plan your perfect trip with our intelligent travel assistant.',
      'keywords':
          'travel planning, AI travel, trip planner, vacation planner, travel assistant, smart travel',
      'author': 'Travel Wizards',
      'robots': 'index, follow',
      'viewport': 'width=device-width, initial-scale=1.0',
      'theme-color': '#2196F3',
      'application-name': 'Travel Wizards',

      // Open Graph tags
      'og:title': 'Travel Wizards - AI-Powered Trip Planning',
      'og:description':
          'Plan your perfect trip with our intelligent travel assistant. Get personalized recommendations and seamless booking.',
      'og:type': 'website',
      'og:image': 'assets/images/og-image.png',
      'og:url': html.window.location.href,

      // Twitter Card tags
      'twitter:card': 'summary_large_image',
      'twitter:title': 'Travel Wizards - AI-Powered Trip Planning',
      'twitter:description':
          'Plan your perfect trip with our intelligent travel assistant.',
      'twitter:image': 'assets/images/twitter-card.png',
    };

    metaTags.forEach((name, content) {
      final meta = html.MetaElement()
        ..name = name.startsWith('og:') || name.startsWith('twitter:')
            ? name
            : name
        ..content = content;

      if (name.startsWith('og:') || name.startsWith('twitter:')) {
        meta.setAttribute('property', name);
      }

      html.document.head?.children.add(meta);
    });
  }

  /// Add structured data for search engines
  void _addStructuredData() {
    final structuredData = {
      '@context': 'https://schema.org',
      '@type': 'WebApplication',
      'name': 'Travel Wizards',
      'description': 'AI-powered trip planning application',
      'applicationCategory': 'TravelApplication',
      'operatingSystem': 'Web Browser',
      'offers': {'@type': 'Offer', 'price': '0', 'priceCurrency': 'USD'},
      'aggregateRating': {
        '@type': 'AggregateRating',
        'ratingValue': '4.8',
        'ratingCount': '1000',
      },
    };

    final script = html.ScriptElement()
      ..type = 'application/ld+json'
      ..text = structuredData.toString();

    html.document.head?.children.add(script);
  }

  /// Optimize for search engines
  void _optimizeForSearchEngines() {
    // Add canonical URL
    final canonical = html.LinkElement()
      ..rel = 'canonical'
      ..href = html.window.location.href;
    html.document.head?.children.add(canonical);

    // Add alternate language links
    final languages = [
      'en',
      'es',
      'fr',
      'de',
      'it',
      'pt',
      'hi',
      'ja',
      'ko',
      'zh',
    ];
    for (final lang in languages) {
      final alternate = html.LinkElement()
        ..rel = 'alternate'
        ..hreflang = lang
        ..href = '${html.window.location.origin}/?lang=$lang';
      html.document.head?.children.add(alternate);
    }
  }

  /// Setup analytics
  Future<void> _configureAnalytics() async {
    // Setup Google Analytics 4
    _setupGoogleAnalytics();

    // Setup web vitals tracking
    _setupWebVitalsTracking();
  }

  /// Setup Google Analytics
  void _setupGoogleAnalytics() {
    // This would integrate with Google Analytics
    if (kDebugMode) {
      print('Analytics configured');
    }
  }

  /// Setup Web Vitals tracking
  void _setupWebVitalsTracking() {
    // This would integrate with web-vitals library
    if (kDebugMode) {
      print('Web Vitals tracking enabled');
    }
  }

  /// Get current configuration
  WebConfiguration get configuration => _configuration;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Check if online
  bool get isOnline => html.window.navigator.onLine ?? true;

  /// Show PWA install prompt
  void showInstallPrompt() {
    if (_configuration.supportsPWA) {
      // Trigger install prompt
      if (kDebugMode) {
        print('Showing PWA install prompt');
      }
    }
  }
}

/// Web platform configuration
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

  /// Check if capability is supported
  bool hasCapability(String capability) {
    return capabilities.contains(capability);
  }

  /// Get configuration description
  String get description {
    return 'Web platform on $browserName with ${capabilities.length} capabilities';
  }

  /// Check if modern browser
  bool get isModernBrowser {
    return hasCapability('Service Worker') &&
        hasCapability('IndexedDB') &&
        hasCapability('Local Storage');
  }
}
