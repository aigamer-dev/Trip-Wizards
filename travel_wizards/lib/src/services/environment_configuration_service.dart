import 'package:flutter/foundation.dart';
import 'secrets_management_service.dart';
import 'security_headers_service.dart';

/// Environment-specific configuration management service
///
/// This service manages environment-specific configurations for development,
/// staging, and production environments with automatic detection and validation.
class EnvironmentConfigurationService {
  static EnvironmentConfigurationService? _instance;
  static EnvironmentConfigurationService get instance {
    _instance ??= EnvironmentConfigurationService._();
    return _instance!;
  }

  EnvironmentConfigurationService._();

  late final Environment _currentEnvironment;
  late final EnvironmentConfig _currentConfig;
  bool _initialized = false;

  /// Initialize the service and detect current environment
  Future<void> initialize() async {
    if (_initialized) return;

    _currentEnvironment = _detectEnvironment();
    _currentConfig = await _buildEnvironmentConfig(_currentEnvironment);

    await _validateEnvironmentConfig();

    _initialized = true;
    _logEnvironmentInfo(
      'Environment configuration initialized for ${_currentEnvironment.name}',
    );
  }

  /// Get current environment
  Environment get currentEnvironment {
    _ensureInitialized();
    return _currentEnvironment;
  }

  /// Get current environment configuration
  EnvironmentConfig get currentConfig {
    _ensureInitialized();
    return _currentConfig;
  }

  /// Get configuration for specific environment
  Future<EnvironmentConfig> getEnvironmentConfig(
    Environment environment,
  ) async {
    return await _buildEnvironmentConfig(environment);
  }

  /// Check if current environment is development
  bool get isDevelopment => currentEnvironment == Environment.development;

  /// Check if current environment is staging
  bool get isStaging => currentEnvironment == Environment.staging;

  /// Check if current environment is production
  bool get isProduction => currentEnvironment == Environment.production;

  /// Get API base URLs for current environment
  ApiUrls get apiUrls => currentConfig.apiUrls;

  /// Get security configuration for current environment
  SecurityConfig get securityConfig => currentConfig.securityConfig;

  /// Get feature flags for current environment
  FeatureFlags get featureFlags => currentConfig.featureFlags;

  /// Get app configuration for current environment
  AppConfig get appConfig => currentConfig.appConfig;

  /// Switch to different environment (for testing purposes)
  Future<void> switchEnvironment(Environment environment) async {
    if (!kDebugMode && environment == Environment.production) {
      throw StateError(
        'Cannot switch to production environment in release mode',
      );
    }

    _currentEnvironment = environment;
    _currentConfig = await _buildEnvironmentConfig(environment);
    await _validateEnvironmentConfig();

    _logEnvironmentInfo('Switched to ${environment.name} environment');
  }

  /// Detect current environment based on various factors
  Environment _detectEnvironment() {
    // 1. Check explicit environment variable
    final secrets = SecretsManagementService.instance;
    final envVar = secrets.getSecret('ENVIRONMENT') ?? secrets.getSecret('ENV');
    if (envVar != null) {
      switch (envVar.toLowerCase()) {
        case 'development':
        case 'dev':
        case 'debug':
          return Environment.development;
        case 'staging':
        case 'stage':
        case 'test':
          return Environment.staging;
        case 'production':
        case 'prod':
        case 'release':
          return Environment.production;
      }
    }

    // 2. Check Flutter build mode
    if (kDebugMode) {
      return Environment.development;
    } else if (kProfileMode) {
      return Environment.staging;
    } else if (kReleaseMode) {
      return Environment.production;
    }

    // 3. Default fallback
    return Environment.development;
  }

  /// Build environment-specific configuration
  Future<EnvironmentConfig> _buildEnvironmentConfig(
    Environment environment,
  ) async {
    final secrets = SecretsManagementService.instance;

    return EnvironmentConfig(
      environment: environment,
      apiUrls: _buildApiUrls(environment, secrets),
      securityConfig: _buildSecurityConfig(environment),
      featureFlags: _buildFeatureFlags(environment, secrets),
      appConfig: _buildAppConfig(environment, secrets),
    );
  }

  /// Build API URLs configuration
  ApiUrls _buildApiUrls(
    Environment environment,
    SecretsManagementService secrets,
  ) {
    final backendSecrets = secrets.getBackendSecrets(environment: environment);

    return ApiUrls(
      backend: backendSecrets.baseUrl ?? _getDefaultBackendUrl(environment),
      stripeBackend: backendSecrets.stripeBackendUrl ?? backendSecrets.baseUrl,
      authService: backendSecrets.authServiceUrl,
      firebase: _getFirebaseUrls(environment),
      google: _getGoogleUrls(environment),
    );
  }

  /// Build security configuration
  SecurityConfig _buildSecurityConfig(Environment environment) {
    final securityLevel = switch (environment) {
      Environment.development => SecurityLevel.basic,
      Environment.staging => SecurityLevel.standard,
      Environment.production => SecurityLevel.strict,
    };

    return SecurityConfig(
      securityLevel: securityLevel,
      enforceHttps: environment == Environment.production,
      enableCSP: true,
      enableHSTS: environment == Environment.production,
      enableCORS: true,
      maxCacheAge: switch (environment) {
        Environment.development => const Duration(minutes: 5),
        Environment.staging => const Duration(hours: 1),
        Environment.production => const Duration(hours: 24),
      },
    );
  }

  /// Build feature flags configuration
  FeatureFlags _buildFeatureFlags(
    Environment environment,
    SecretsManagementService secrets,
  ) {
    final devSecrets = secrets.getDevelopmentSecrets(environment: environment);

    return FeatureFlags(
      enableAnalytics: devSecrets.enableAnalytics,
      enableCrashReporting: environment != Environment.development,
      enableRemoteIdeas: devSecrets.useRemoteIdeas,
      enableMockPayments: devSecrets.mockPayments,
      enableDebugMode: devSecrets.debugMode,
      enablePerformanceMonitoring: environment == Environment.production,
      enableA11yTesting: environment == Environment.development,
      enableExperimentalFeatures: environment == Environment.development,
    );
  }

  /// Build app configuration
  AppConfig _buildAppConfig(
    Environment environment,
    SecretsManagementService secrets,
  ) {
    return AppConfig(
      appName: switch (environment) {
        Environment.development => 'Travel Wizards (Dev)',
        Environment.staging => 'Travel Wizards (Staging)',
        Environment.production => 'Travel Wizards',
      },
      versionSuffix: switch (environment) {
        Environment.development => '-dev',
        Environment.staging => '-staging',
        Environment.production => '',
      },
      logLevel: switch (environment) {
        Environment.development => LogLevel.debug,
        Environment.staging => LogLevel.info,
        Environment.production => LogLevel.warning,
      },
      enableLogging: environment != Environment.production,
      cacheTimeout: switch (environment) {
        Environment.development => const Duration(minutes: 1),
        Environment.staging => const Duration(minutes: 15),
        Environment.production => const Duration(hours: 1),
      },
      networkTimeout: switch (environment) {
        Environment.development => const Duration(seconds: 30),
        Environment.staging => const Duration(seconds: 15),
        Environment.production => const Duration(seconds: 10),
      },
    );
  }

  /// Get default backend URL for environment
  String _getDefaultBackendUrl(Environment environment) {
    return switch (environment) {
      Environment.development => 'http://localhost:8080',
      Environment.staging => 'https://staging-api.travelwizards.app',
      Environment.production => 'https://api.travelwizards.app',
    };
  }

  /// Get Firebase URLs configuration
  Map<String, String> _getFirebaseUrls(Environment environment) {
    final projectId = SecretsManagementService.instance
        .getFirebaseSecrets(environment: environment)
        .projectId;

    return {
      'auth': 'https://identitytoolkit.googleapis.com/v1',
      'firestore': 'https://firestore.googleapis.com/v1/projects/$projectId',
      'storage':
          'https://firebasestorage.googleapis.com/v0/b/$projectId.appspot.com',
      'functions': 'https://us-central1-$projectId.cloudfunctions.net',
    };
  }

  /// Get Google APIs URLs configuration
  Map<String, String> _getGoogleUrls(Environment environment) {
    return {
      'maps': 'https://maps.googleapis.com/maps/api',
      'places': 'https://maps.googleapis.com/maps/api/place',
      'directions': 'https://maps.googleapis.com/maps/api/directions',
      'geocoding': 'https://maps.googleapis.com/maps/api/geocode',
      'translate': 'https://translation.googleapis.com/language/translate/v2',
      'calendar': 'https://www.googleapis.com/calendar/v3',
      'contacts': 'https://people.googleapis.com/v1',
    };
  }

  /// Validate environment configuration
  Future<void> _validateEnvironmentConfig() async {
    final issues = <String>[];

    // Validate secrets
    final secretsValidation = SecretsManagementService.instance
        .validateConfiguration(environment: _currentEnvironment);
    if (!secretsValidation.isValid) {
      issues.addAll(secretsValidation.issues.map((i) => i.message));
    }

    // Validate security configuration
    final securityValidation = SecurityHeadersService.instance
        .validateSecurityConfiguration(environment: _currentEnvironment);
    if (!securityValidation.isSecure) {
      issues.addAll(securityValidation.issues.map((i) => i.message));
    }

    // Environment-specific validations
    switch (_currentEnvironment) {
      case Environment.development:
        // Allow more flexibility in development
        break;

      case Environment.staging:
        if (!_currentConfig.apiUrls.backend.startsWith('https://')) {
          issues.add('Staging environment should use HTTPS');
        }
        break;

      case Environment.production:
        if (!_currentConfig.apiUrls.backend.startsWith('https://')) {
          issues.add('Production environment must use HTTPS');
        }
        if (_currentConfig.featureFlags.enableDebugMode) {
          issues.add('Debug mode should not be enabled in production');
        }
        if (_currentConfig.featureFlags.enableMockPayments) {
          issues.add('Mock payments should not be enabled in production');
        }
        break;
    }

    if (issues.isNotEmpty && _currentEnvironment == Environment.production) {
      throw EnvironmentConfigurationException(
        'Critical environment configuration issues found: ${issues.join(', ')}',
      );
    }

    if (issues.isNotEmpty) {
      _logEnvironmentWarning(
        'Environment configuration issues: ${issues.join(', ')}',
      );
    }
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'EnvironmentConfigurationService not initialized. Call initialize() first.',
      );
    }
  }

  /// Log environment information
  void _logEnvironmentInfo(String message) {
    if (kDebugMode) {
      debugPrint('🌍 ENVIRONMENT: $message');
    }
  }

  /// Log environment warning
  void _logEnvironmentWarning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ ENVIRONMENT WARNING: $message');
    }
  }
}

/// Complete environment configuration
@immutable
class EnvironmentConfig {
  final Environment environment;
  final ApiUrls apiUrls;
  final SecurityConfig securityConfig;
  final FeatureFlags featureFlags;
  final AppConfig appConfig;

  const EnvironmentConfig({
    required this.environment,
    required this.apiUrls,
    required this.securityConfig,
    required this.featureFlags,
    required this.appConfig,
  });
}

/// API URLs configuration
@immutable
class ApiUrls {
  final String backend;
  final String? stripeBackend;
  final String? authService;
  final Map<String, String> firebase;
  final Map<String, String> google;

  const ApiUrls({
    required this.backend,
    this.stripeBackend,
    this.authService,
    required this.firebase,
    required this.google,
  });

  String get effectiveStripeBackend => stripeBackend ?? backend;
  String get effectiveAuthService => authService ?? backend;
}

/// Security configuration
@immutable
class SecurityConfig {
  final SecurityLevel securityLevel;
  final bool enforceHttps;
  final bool enableCSP;
  final bool enableHSTS;
  final bool enableCORS;
  final Duration maxCacheAge;

  const SecurityConfig({
    required this.securityLevel,
    required this.enforceHttps,
    required this.enableCSP,
    required this.enableHSTS,
    required this.enableCORS,
    required this.maxCacheAge,
  });
}

/// Feature flags configuration
@immutable
class FeatureFlags {
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool enableRemoteIdeas;
  final bool enableMockPayments;
  final bool enableDebugMode;
  final bool enablePerformanceMonitoring;
  final bool enableA11yTesting;
  final bool enableExperimentalFeatures;

  const FeatureFlags({
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.enableRemoteIdeas,
    required this.enableMockPayments,
    required this.enableDebugMode,
    required this.enablePerformanceMonitoring,
    required this.enableA11yTesting,
    required this.enableExperimentalFeatures,
  });
}

/// App configuration
@immutable
class AppConfig {
  final String appName;
  final String versionSuffix;
  final LogLevel logLevel;
  final bool enableLogging;
  final Duration cacheTimeout;
  final Duration networkTimeout;

  const AppConfig({
    required this.appName,
    required this.versionSuffix,
    required this.logLevel,
    required this.enableLogging,
    required this.cacheTimeout,
    required this.networkTimeout,
  });
}

/// Log levels for application logging
enum LogLevel { debug, info, warning, error }

/// Exception thrown for environment configuration errors
class EnvironmentConfigurationException implements Exception {
  final String message;

  const EnvironmentConfigurationException(this.message);

  @override
  String toString() => 'EnvironmentConfigurationException: $message';
}

/// Extension methods for environment configuration
extension EnvironmentConfigurationExtension on EnvironmentConfigurationService {
  /// Quick check if development features are enabled
  bool get isDevelopmentFeaturesEnabled =>
      currentConfig.featureFlags.enableDebugMode ||
      currentConfig.featureFlags.enableExperimentalFeatures;

  /// Quick check if production security is enabled
  bool get isProductionSecurityEnabled =>
      currentConfig.securityConfig.enforceHttps &&
      currentConfig.securityConfig.enableHSTS;

  /// Get environment-appropriate cache duration
  Duration getCacheDuration(CacheType type) {
    return switch (type) {
      CacheType.api => currentConfig.appConfig.cacheTimeout,
      CacheType.images => Duration(
        hours: currentEnvironment == Environment.production ? 24 : 1,
      ),
      CacheType.static => Duration(
        days: currentEnvironment == Environment.production ? 7 : 1,
      ),
    };
  }
}

/// Cache types for environment-specific configuration
enum CacheType { api, images, static }
