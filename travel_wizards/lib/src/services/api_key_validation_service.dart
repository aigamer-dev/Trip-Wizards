import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'secrets_management_service.dart';

/// Validation result for API keys
@immutable
class ApiKeyValidationResult {
  final bool isValid;
  final String? errorMessage;
  final DateTime validatedAt;
  final Map<String, dynamic>? metadata;

  const ApiKeyValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.validatedAt,
    this.metadata,
  });

  factory ApiKeyValidationResult.valid({Map<String, dynamic>? metadata}) {
    return ApiKeyValidationResult(
      isValid: true,
      validatedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  factory ApiKeyValidationResult.invalid(String errorMessage) {
    return ApiKeyValidationResult(
      isValid: false,
      errorMessage: errorMessage,
      validatedAt: DateTime.now(),
    );
  }
}

/// Cache entry for validation results
@immutable
class ValidationCacheEntry {
  final ApiKeyValidationResult result;
  final DateTime cachedAt;

  const ValidationCacheEntry({required this.result, required this.cachedAt});

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > const Duration(hours: 24);
}

/// API key validation service for Travel Wizards
///
/// This service provides validation mechanisms for API keys to ensure they
/// are valid, properly formatted, and functional before making requests.
class ApiKeyValidationService {
  static ApiKeyValidationService? _instance;
  static ApiKeyValidationService get instance {
    _instance ??= ApiKeyValidationService._();
    return _instance!;
  }

  ApiKeyValidationService._();

  final _http = http.Client();
  final _validationCache = <String, ValidationCacheEntry>{};

  /// Validate Firebase API key
  Future<ApiKeyValidationResult> validateFirebaseApiKey(String apiKey) async {
    if (apiKey.isEmpty) {
      return ApiKeyValidationResult.invalid('API key is empty');
    }

    // Check format
    if (!apiKey.startsWith('AIza')) {
      return ApiKeyValidationResult.invalid('Invalid Firebase API key format');
    }

    if (apiKey.length < 35) {
      return ApiKeyValidationResult.invalid('Firebase API key is too short');
    }

    // Check cache
    final cached = _getFromCache(apiKey);
    if (cached != null) return cached;

    try {
      // Validate by making a test request to Firebase Auth
      final response = await _http.get(
        Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/projects?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = ApiKeyValidationResult.valid(
          metadata: {
            'service': 'firebase',
            'tested_endpoint': 'identitytoolkit',
          },
        );
        _cacheResult(apiKey, result);
        return result;
      } else if (response.statusCode == 400) {
        final body = json.decode(response.body);
        final error = body['error']['message'] ?? 'Unknown error';
        final result = ApiKeyValidationResult.invalid(
          'Firebase API key validation failed: $error',
        );
        _cacheResult(apiKey, result);
        return result;
      } else {
        final result = ApiKeyValidationResult.invalid(
          'Unable to validate Firebase API key',
        );
        return result; // Don't cache temporary failures
      }
    } catch (e) {
      _logValidationError('Firebase API key validation error', e);
      return ApiKeyValidationResult.invalid(
        'Network error during validation: $e',
      );
    }
  }

  /// Validate Google Maps API key
  Future<ApiKeyValidationResult> validateGoogleMapsApiKey(String apiKey) async {
    if (apiKey.isEmpty) {
      return ApiKeyValidationResult.invalid('API key is empty');
    }

    // Check format
    if (!apiKey.startsWith('AIza')) {
      return ApiKeyValidationResult.invalid('Invalid Google API key format');
    }

    // Check cache
    final cached = _getFromCache(apiKey);
    if (cached != null) return cached;

    try {
      // Test with a simple geocoding request
      final response = await _http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=test&key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == 'ZERO_RESULTS' || body['status'] == 'OK') {
          final result = ApiKeyValidationResult.valid(
            metadata: {
              'service': 'google_maps',
              'tested_endpoint': 'geocoding',
            },
          );
          _cacheResult(apiKey, result);
          return result;
        } else if (body['status'] == 'REQUEST_DENIED') {
          final error = body['error_message'] ?? 'Request denied';
          final result = ApiKeyValidationResult.invalid(
            'Google Maps API key validation failed: $error',
          );
          _cacheResult(apiKey, result);
          return result;
        }
      }

      final result = ApiKeyValidationResult.invalid(
        'Unable to validate Google Maps API key',
      );
      return result; // Don't cache temporary failures
    } catch (e) {
      _logValidationError('Google Maps API key validation error', e);
      return ApiKeyValidationResult.invalid(
        'Network error during validation: $e',
      );
    }
  }

  /// Validate Google Translate API key
  Future<ApiKeyValidationResult> validateGoogleTranslateApiKey(
    String apiKey,
  ) async {
    if (apiKey.isEmpty) {
      return ApiKeyValidationResult.invalid('API key is empty');
    }

    // Check format
    if (!apiKey.startsWith('AIza')) {
      return ApiKeyValidationResult.invalid('Invalid Google API key format');
    }

    // Check cache
    final cached = _getFromCache(apiKey);
    if (cached != null) return cached;

    try {
      // Test with a simple translation request
      final response = await _http.post(
        Uri.parse(
          'https://translation.googleapis.com/language/translate/v2?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'q': 'hello', 'target': 'es'}),
      );

      if (response.statusCode == 200) {
        final result = ApiKeyValidationResult.valid(
          metadata: {
            'service': 'google_translate',
            'tested_endpoint': 'translate',
          },
        );
        _cacheResult(apiKey, result);
        return result;
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        final body = json.decode(response.body);
        final error = body['error']['message'] ?? 'Unknown error';
        final result = ApiKeyValidationResult.invalid(
          'Google Translate API key validation failed: $error',
        );
        _cacheResult(apiKey, result);
        return result;
      }

      final result = ApiKeyValidationResult.invalid(
        'Unable to validate Google Translate API key',
      );
      return result; // Don't cache temporary failures
    } catch (e) {
      _logValidationError('Google Translate API key validation error', e);
      return ApiKeyValidationResult.invalid(
        'Network error during validation: $e',
      );
    }
  }

  /// Validate Stripe publishable key
  Future<ApiKeyValidationResult> validateStripeKey(String key) async {
    if (key.isEmpty) {
      return ApiKeyValidationResult.invalid('Stripe key is empty');
    }

    // Check format
    if (!key.startsWith('pk_') &&
        !key.startsWith('sk_') &&
        !key.startsWith('rk_')) {
      return ApiKeyValidationResult.invalid('Invalid Stripe key format');
    }

    // For secret keys, we should not validate over network for security
    if (key.startsWith('sk_')) {
      return ApiKeyValidationResult.valid(
        metadata: {
          'service': 'stripe',
          'type': 'secret',
          'validation': 'format_only',
        },
      );
    }

    // Check cache for publishable keys
    final cached = _getFromCache(key);
    if (cached != null) return cached;

    try {
      // For publishable keys, we can make a test request
      final response = await _http.get(
        Uri.parse('https://api.stripe.com/v1/payment_methods'),
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 401) {
        // This means the key format is correct but it's a publishable key being used for server-side
        // which is expected behavior - the key format is valid
        final result = ApiKeyValidationResult.valid(
          metadata: {'service': 'stripe', 'type': 'publishable'},
        );
        _cacheResult(key, result);
        return result;
      } else if (response.statusCode == 200) {
        final result = ApiKeyValidationResult.valid(
          metadata: {'service': 'stripe', 'type': 'publishable'},
        );
        _cacheResult(key, result);
        return result;
      }

      final result = ApiKeyValidationResult.invalid(
        'Unable to validate Stripe key',
      );
      return result; // Don't cache temporary failures
    } catch (e) {
      _logValidationError('Stripe key validation error', e);
      return ApiKeyValidationResult.invalid(
        'Network error during validation: $e',
      );
    }
  }

  /// Validate backend URL by making a health check request
  Future<ApiKeyValidationResult> validateBackendUrl(String url) async {
    if (url.isEmpty) {
      return ApiKeyValidationResult.invalid('Backend URL is empty');
    }

    // Check URL format
    Uri? uri;
    try {
      uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.hasAuthority && uri.host.isEmpty)) {
        return ApiKeyValidationResult.invalid('Invalid URL format');
      }
    } catch (e) {
      return ApiKeyValidationResult.invalid('Invalid URL format: $e');
    }

    // Check cache
    final cached = _getFromCache(url);
    if (cached != null) return cached;

    try {
      // Try health check endpoint
      final healthUrl = uri.resolve('/health');
      final response = await _http
          .get(healthUrl, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = ApiKeyValidationResult.valid(
          metadata: {
            'service': 'backend',
            'tested_endpoint': 'health',
            'response_time': DateTime.now().toIso8601String(),
          },
        );
        _cacheResult(url, result);
        return result;
      } else if (response.statusCode == 404) {
        // Try root endpoint
        final rootResponse = await _http
            .get(uri, headers: {'Content-Type': 'application/json'})
            .timeout(const Duration(seconds: 10));

        if (rootResponse.statusCode == 200 || rootResponse.statusCode == 404) {
          final result = ApiKeyValidationResult.valid(
            metadata: {
              'service': 'backend',
              'tested_endpoint': 'root',
              'note': 'Server reachable but no health endpoint',
            },
          );
          _cacheResult(url, result);
          return result;
        }
      }

      final result = ApiKeyValidationResult.invalid(
        'Backend server returned status ${response.statusCode}',
      );
      return result; // Don't cache temporary failures
    } catch (e) {
      _logValidationError('Backend URL validation error', e);
      return ApiKeyValidationResult.invalid('Cannot reach backend server: $e');
    }
  }

  /// Validate all configured API keys and URLs
  Future<Map<String, ApiKeyValidationResult>> validateAllSecrets() async {
    final results = <String, ApiKeyValidationResult>{};
    final secrets = SecretsManagementService.instance;

    try {
      // Validate Firebase secrets
      final firebaseSecrets = secrets.getFirebaseSecrets();
      results['firebase_web_api_key'] = await validateFirebaseApiKey(
        firebaseSecrets.webApiKey,
      );
      results['firebase_android_api_key'] = await validateFirebaseApiKey(
        firebaseSecrets.androidApiKey,
      );

      // Validate Google API secrets
      final googleSecrets = secrets.getGoogleApiSecrets();
      results['google_maps_api_key'] = await validateGoogleMapsApiKey(
        googleSecrets.mapsApiKey,
      );

      if (googleSecrets.translateApiKey != null) {
        results['google_translate_api_key'] =
            await validateGoogleTranslateApiKey(googleSecrets.translateApiKey!);
      }

      // Validate Stripe secrets
      final stripeSecrets = secrets.getStripeSecrets();
      if (stripeSecrets.publishableKey != null) {
        results['stripe_publishable_key'] = await validateStripeKey(
          stripeSecrets.publishableKey!,
        );
      }

      // Validate backend URLs
      final backendSecrets = secrets.getBackendSecrets();
      if (backendSecrets.baseUrl != null) {
        results['backend_base_url'] = await validateBackendUrl(
          backendSecrets.baseUrl!,
        );
      }
      if (backendSecrets.stripeBackendUrl != null) {
        results['stripe_backend_url'] = await validateBackendUrl(
          backendSecrets.stripeBackendUrl!,
        );
      }
    } catch (e) {
      _logValidationError('Bulk validation error', e);
      results['validation_error'] = ApiKeyValidationResult.invalid(
        'Error during bulk validation: $e',
      );
    }

    return results;
  }

  /// Get validation result from cache if available and not expired
  ApiKeyValidationResult? _getFromCache(String key) {
    final entry = _validationCache[key];
    if (entry != null && !entry.isExpired) {
      return entry.result;
    }
    return null;
  }

  /// Cache validation result
  void _cacheResult(String key, ApiKeyValidationResult result) {
    _validationCache[key] = ValidationCacheEntry(
      result: result,
      cachedAt: DateTime.now(),
    );

    // Clean expired entries periodically
    _cleanExpiredCache();
  }

  /// Clean expired cache entries
  void _cleanExpiredCache() {
    _validationCache.removeWhere((key, entry) => entry.isExpired);
  }

  /// Clear all validation cache
  void clearCache() {
    _validationCache.clear();
    _logValidationInfo('Validation cache cleared');
  }

  /// Log validation error
  void _logValidationError(String message, dynamic error) {
    if (kDebugMode) {
      debugPrint('🔑 API VALIDATION ERROR: $message - $error');
    }
  }

  /// Log validation info
  void _logValidationInfo(String message) {
    if (kDebugMode) {
      debugPrint('🔑 API VALIDATION: $message');
    }
  }

  /// Dispose resources
  void dispose() {
    _http.close();
    clearCache();
  }
}

/// Extension methods for easy validation
extension ApiKeyValidationExtension on SecretsManagementService {
  /// Quick validation for all secrets
  Future<bool> validateAllSecrets() async {
    final validator = ApiKeyValidationService.instance;
    final results = await validator.validateAllSecrets();

    return results.values.every((result) => result.isValid);
  }

  /// Validate specific secret type
  Future<bool> validateSecret(String secretValue, SecretType type) async {
    final validator = ApiKeyValidationService.instance;

    switch (type) {
      case SecretType.firebaseApiKey:
        final result = await validator.validateFirebaseApiKey(secretValue);
        return result.isValid;

      case SecretType.googleApiKey:
        final result = await validator.validateGoogleMapsApiKey(secretValue);
        return result.isValid;

      case SecretType.stripeKey:
        final result = await validator.validateStripeKey(secretValue);
        return result.isValid;

      case SecretType.backendUrl:
        final result = await validator.validateBackendUrl(secretValue);
        return result.isValid;

      default:
        return true; // No validation for other types
    }
  }
}
