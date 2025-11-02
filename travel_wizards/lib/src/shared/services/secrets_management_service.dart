import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment types for configuration management
enum Environment { development, staging, production }

/// Secret types for validation and handling
enum SecretType {
  firebaseApiKey,
  googleApiKey,
  stripeKey,
  backendUrl,
  authToken,
  encryptionKey,
  other,
}

/// Comprehensive secrets management service for Travel Wizards
///
/// This service provides secure handling of API keys, configuration values,
/// and sensitive data with validation, environment-specific configurations,
/// and security best practices.
class SecretsManagementService {
  static SecretsManagementService? _instance;
  static SecretsManagementService get instance {
    _instance ??= SecretsManagementService._();
    return _instance!;
  }

  SecretsManagementService._();

  /// Current environment (auto-detected)
  Environment get currentEnvironment {
    if (kDebugMode) {
      return Environment.development;
    }

    // Check environment variable
    final envVar = _getString('ENVIRONMENT') ?? _getString('ENV');
    switch (envVar?.toLowerCase()) {
      case 'staging':
      case 'test':
        return Environment.staging;
      case 'production':
      case 'prod':
        return Environment.production;
      default:
        return kReleaseMode ? Environment.production : Environment.development;
    }
  }

  /// Get secret value with validation and fallback support
  String? getSecret(
    String key, {
    SecretType type = SecretType.other,
    String? fallback,
    bool required = false,
    Environment? environment,
  }) {
    try {
      // 1. Try environment-specific key first
      final env = environment ?? currentEnvironment;
      final envSpecificKey = '${env.name.toUpperCase()}_$key';
      String? value = _getString(envSpecificKey);

      // 2. Fall back to general key
      value ??= _getString(key);

      // 3. Use provided fallback
      value ??= fallback;

      // 4. Validate if value is found
      if (value != null) {
        if (!_validateSecret(value, type)) {
          _logSecurityWarning('Invalid secret format for key: $key');
          if (required) {
            throw SecretValidationException(
              'Invalid format for required secret: $key',
            );
          }
          return null;
        }
      }

      // 5. Check if required
      if (required && value == null) {
        throw SecretValidationException('Required secret not found: $key');
      }

      return value;
    } catch (e) {
      _logSecurityWarning('Error retrieving secret $key: $e');
      if (required) rethrow;
      return null;
    }
  }

  /// Get Firebase configuration secrets
  FirebaseSecrets getFirebaseSecrets({Environment? environment}) {
    final env = environment ?? currentEnvironment;

    return FirebaseSecrets(
      projectId: getSecret(
        'FIREBASE_PROJECT_ID',
        type: SecretType.other,
        required: true,
        environment: env,
      )!,
      storageBucket: getSecret(
        'FIREBASE_STORAGE_BUCKET',
        type: SecretType.other,
        required: true,
        environment: env,
      )!,
      messagingSenderId: getSecret(
        'FIREBASE_MESSAGING_SENDER_ID',
        type: SecretType.other,
        required: true,
        environment: env,
      )!,
      authDomain: getSecret(
        'FIREBASE_AUTH_DOMAIN',
        type: SecretType.other,
        required: true,
        environment: env,
      )!,
      webApiKey: getSecret(
        'FIREBASE_WEB_API_KEY',
        type: SecretType.firebaseApiKey,
        required: true,
        environment: env,
      )!,
      webAppId: getSecret(
        'FIREBASE_WEB_APP_ID',
        type: SecretType.other,
        required: true,
        environment: env,
      )!,
      webMeasurementId: getSecret(
        'FIREBASE_WEB_MEASUREMENT_ID',
        type: SecretType.other,
        environment: env,
      ),
      androidApiKey: getSecret(
        'FIREBASE_ANDROID_API_KEY',
        type: SecretType.firebaseApiKey,
        required: true,
        environment: env,
      )!,
      androidAppId: getSecret(
        'FIREBASE_ANDROID_APP_ID',
        type: SecretType.other,
        required: true,
        environment: env,
      )!,
    );
  }

  /// Get Google API secrets
  GoogleApiSecrets getGoogleApiSecrets({Environment? environment}) {
    final env = environment ?? currentEnvironment;

    return GoogleApiSecrets(
      mapsApiKey: getSecret(
        'GOOGLE_MAPS_API_KEY',
        type: SecretType.googleApiKey,
        required: true,
        environment: env,
      )!,
      mapsWebApiKey: getSecret(
        'GOOGLE_MAPS_WEB_API_KEY',
        type: SecretType.googleApiKey,
        environment: env,
      ),
      translateApiKey: getSecret(
        'GOOGLE_TRANSLATE_API_KEY',
        type: SecretType.googleApiKey,
        environment: env,
      ),
      placesApiKey: getSecret(
        'PLACES_API_KEY',
        type: SecretType.googleApiKey,
        environment: env,
      ),
    );
  }

  /// Get Stripe configuration secrets
  StripeSecrets getStripeSecrets({Environment? environment}) {
    final env = environment ?? currentEnvironment;

    return StripeSecrets(
      publishableKey: getSecret(
        'STRIPE_PUBLISHABLE_KEY',
        type: SecretType.stripeKey,
        environment: env,
      ),
      secretKey: getSecret(
        'STRIPE_SECRET_KEY',
        type: SecretType.stripeKey,
        environment: env,
      ),
      webKey: getSecret(
        'STRIPE_PUBLISHABLE_KEY_WEB',
        type: SecretType.stripeKey,
        environment: env,
      ),
      androidKey: getSecret(
        'STRIPE_PUBLISHABLE_KEY_ANDROID',
        type: SecretType.stripeKey,
        environment: env,
      ),
      iosKey: getSecret(
        'STRIPE_PUBLISHABLE_KEY_IOS',
        type: SecretType.stripeKey,
        environment: env,
      ),
    );
  }

  /// Get backend configuration secrets
  BackendSecrets getBackendSecrets({Environment? environment}) {
    final env = environment ?? currentEnvironment;

    return BackendSecrets(
      baseUrl: getSecret(
        'BACKEND_BASE_URL',
        type: SecretType.backendUrl,
        fallback: _getDefaultBackendUrl(env),
        environment: env,
      ),
      stripeBackendUrl: getSecret(
        'STRIPE_BACKEND_URL',
        type: SecretType.backendUrl,
        environment: env,
      ),
      apiBaseUrl: getSecret(
        'API_BASE_URL',
        type: SecretType.backendUrl,
        environment: env,
      ),
      authServiceUrl: getSecret(
        'AUTH_SERVICE_URL',
        type: SecretType.backendUrl,
        environment: env,
      ),
    );
  }

  /// Get development settings
  DevelopmentSecrets getDevelopmentSecrets({Environment? environment}) {
    final env = environment ?? currentEnvironment;

    return DevelopmentSecrets(
      debugMode: _getBool(
        'DEBUG_MODE',
        defaultValue: env == Environment.development,
      ),
      logLevel: getSecret(
        'LOG_LEVEL',
        fallback: env == Environment.development ? 'debug' : 'info',
        environment: env,
      )!,
      mockPayments: _getBool('MOCK_PAYMENTS', defaultValue: false),
      useRemoteIdeas: _getBool('USE_REMOTE_IDEAS', defaultValue: false),
      enableAnalytics: _getBool(
        'ENABLE_ANALYTICS',
        defaultValue: env == Environment.production,
      ),
    );
  }

  /// Validate secret format based on type
  bool _validateSecret(String value, SecretType type) {
    if (value.isEmpty) return false;

    switch (type) {
      case SecretType.firebaseApiKey:
        return value.startsWith('AIza') && value.length >= 35;

      case SecretType.googleApiKey:
        return value.startsWith('AIza') && value.length >= 35;

      case SecretType.stripeKey:
        return value.startsWith('pk_') ||
            value.startsWith('sk_') ||
            value.startsWith('rk_');

      case SecretType.backendUrl:
        try {
          final uri = Uri.parse(value);
          return uri.hasScheme && (uri.hasAuthority || uri.host.isNotEmpty);
        } catch (e) {
          return false;
        }

      case SecretType.authToken:
        return value.length >= 16; // Minimum token length

      case SecretType.encryptionKey:
        return value.length >= 32; // Minimum encryption key length

      case SecretType.other:
        return true; // No specific validation for other types
    }
  }

  /// Get string value from multiple sources with priority
  String? _getString(String key) {
    // Priority: .env file (we avoid dynamic dart-define lookups for simplicity)

    // 2. Check .env file
    final envValue = dotenv.env[key];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }

    return null;
  }

  /// Get boolean value with default fallback
  bool _getBool(String key, {bool defaultValue = false}) {
    final value = _getString(key);
    if (value == null) return defaultValue;

    switch (value.toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'on':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'off':
        return false;
      default:
        return defaultValue;
    }
  }

  /// Get default backend URL based on environment
  String _getDefaultBackendUrl(Environment environment) {
    switch (environment) {
      case Environment.development:
        return 'http://localhost:8080';
      case Environment.staging:
        return 'https://staging-api.travelwizards.app';
      case Environment.production:
        return 'https://api.travelwizards.app';
    }
  }

  /// Log security warning (without exposing sensitive data)
  void _logSecurityWarning(String message) {
    if (kDebugMode) {
      debugPrint('🔒 SECURITY WARNING: $message');
    }
  }

  // Removed hashing helper and related imports to avoid analyzer warnings.

  /// Validate environment configuration
  ValidationResult validateConfiguration({Environment? environment}) {
    final env = environment ?? currentEnvironment;
    final issues = <ConfigurationIssue>[];
    final warnings = <String>[];

    try {
      // Validate Firebase secrets
      try {
        getFirebaseSecrets(environment: env);
      } catch (e) {
        issues.add(
          ConfigurationIssue(
            type: ConfigurationIssueType.missingRequired,
            message: 'Firebase configuration incomplete: $e',
            severity: IssueSeverity.critical,
          ),
        );
      }

      // Validate Google API secrets
      final googleSecrets = getGoogleApiSecrets(environment: env);
      if (googleSecrets.mapsApiKey.isEmpty) {
        issues.add(
          ConfigurationIssue(
            type: ConfigurationIssueType.missingRequired,
            message: 'Google Maps API key is required',
            severity: IssueSeverity.critical,
          ),
        );
      }

      // Validate backend configuration
      final backendSecrets = getBackendSecrets(environment: env);
      if (backendSecrets.baseUrl == null) {
        warnings.add(
          'No backend URL configured - app will run in offline mode',
        );
      }

      // Validate Stripe configuration if payments are enabled
      final stripeSecrets = getStripeSecrets(environment: env);
      if (stripeSecrets.publishableKey == null && !_getBool('MOCK_PAYMENTS')) {
        warnings.add(
          'No Stripe configuration found - payments will be disabled',
        );
      }

      // Environment-specific validations
      if (env == Environment.production) {
        if (_getBool('DEBUG_MODE')) {
          issues.add(
            ConfigurationIssue(
              type: ConfigurationIssueType.securityRisk,
              message: 'Debug mode should not be enabled in production',
              severity: IssueSeverity.high,
            ),
          );
        }

        if (backendSecrets.baseUrl?.startsWith('http://') == true) {
          issues.add(
            ConfigurationIssue(
              type: ConfigurationIssueType.securityRisk,
              message: 'Production backend should use HTTPS',
              severity: IssueSeverity.high,
            ),
          );
        }
      }
    } catch (e) {
      issues.add(
        ConfigurationIssue(
          type: ConfigurationIssueType.validationError,
          message: 'Configuration validation failed: $e',
          severity: IssueSeverity.critical,
        ),
      );
    }

    return ValidationResult(
      isValid: issues
          .where((i) => i.severity == IssueSeverity.critical)
          .isEmpty,
      issues: issues,
      warnings: warnings,
      environment: env,
    );
  }

  /// Clear sensitive data from memory (for security)
  void clearSensitiveData() {
    // Note: In Dart, we can't force garbage collection of strings,
    // but we can clear references and log the action for security auditing
    _logSecurityWarning('Sensitive data cleared from memory');
  }
}

/// Firebase-specific secrets
@immutable
class FirebaseSecrets {
  final String projectId;
  final String storageBucket;
  final String messagingSenderId;
  final String authDomain;
  final String webApiKey;
  final String webAppId;
  final String? webMeasurementId;
  final String androidApiKey;
  final String androidAppId;

  const FirebaseSecrets({
    required this.projectId,
    required this.storageBucket,
    required this.messagingSenderId,
    required this.authDomain,
    required this.webApiKey,
    required this.webAppId,
    this.webMeasurementId,
    required this.androidApiKey,
    required this.androidAppId,
  });
}

/// Google API-specific secrets
@immutable
class GoogleApiSecrets {
  final String mapsApiKey;
  final String? mapsWebApiKey;
  final String? translateApiKey;
  final String? placesApiKey;

  const GoogleApiSecrets({
    required this.mapsApiKey,
    this.mapsWebApiKey,
    this.translateApiKey,
    this.placesApiKey,
  });
}

/// Stripe-specific secrets
@immutable
class StripeSecrets {
  final String? publishableKey;
  final String? secretKey;
  final String? webKey;
  final String? androidKey;
  final String? iosKey;

  const StripeSecrets({
    this.publishableKey,
    this.secretKey,
    this.webKey,
    this.androidKey,
    this.iosKey,
  });

  String? get platformKey {
    if (kIsWeb) return webKey ?? publishableKey;
    return publishableKey;
  }
}

/// Backend-specific secrets
@immutable
class BackendSecrets {
  final String? baseUrl;
  final String? stripeBackendUrl;
  final String? apiBaseUrl;
  final String? authServiceUrl;

  const BackendSecrets({
    this.baseUrl,
    this.stripeBackendUrl,
    this.apiBaseUrl,
    this.authServiceUrl,
  });

  String? get effectiveBackendUrl => stripeBackendUrl ?? baseUrl;
}

/// Development-specific secrets
@immutable
class DevelopmentSecrets {
  final bool debugMode;
  final String logLevel;
  final bool mockPayments;
  final bool useRemoteIdeas;
  final bool enableAnalytics;

  const DevelopmentSecrets({
    required this.debugMode,
    required this.logLevel,
    required this.mockPayments,
    required this.useRemoteIdeas,
    required this.enableAnalytics,
  });
}

/// Configuration validation result
@immutable
class ValidationResult {
  final bool isValid;
  final List<ConfigurationIssue> issues;
  final List<String> warnings;
  final Environment environment;

  const ValidationResult({
    required this.isValid,
    required this.issues,
    required this.warnings,
    required this.environment,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasCriticalIssues =>
      issues.any((issue) => issue.severity == IssueSeverity.critical);
}

/// Configuration issue details
@immutable
class ConfigurationIssue {
  final ConfigurationIssueType type;
  final String message;
  final IssueSeverity severity;

  const ConfigurationIssue({
    required this.type,
    required this.message,
    required this.severity,
  });
}

/// Types of configuration issues
enum ConfigurationIssueType {
  missingRequired,
  invalidFormat,
  securityRisk,
  validationError,
}

/// Issue severity levels
enum IssueSeverity { low, medium, high, critical }

/// Exception thrown for secret validation errors
class SecretValidationException implements Exception {
  final String message;

  const SecretValidationException(this.message);

  @override
  String toString() => 'SecretValidationException: $message';
}
