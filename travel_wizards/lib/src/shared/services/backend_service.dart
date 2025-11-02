import 'package:flutter/foundation.dart';
import 'enhanced_api_client.dart';
import 'api_client_models.dart';
import 'service_health_monitor.dart';

@immutable
class BackendConfig {
  final Uri baseUrl;
  final Duration timeout;

  const BackendConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 8),
  });
}

class BackendService {
  BackendService._(this._apiClient);
  static BackendService? _instance;
  final EnhancedApiClient _apiClient;

  static BackendService init(BackendConfig config) {
    final apiClient = EnhancedApiClient.forTravelWizards(
      baseUrl: config.baseUrl.toString(),
      enableLogging: kDebugMode,
    );

    _instance = BackendService._(apiClient);

    // Register with health monitor
    ServiceHealthMonitor.instance.registerService(
      serviceName: 'backend',
      apiClient: apiClient,
      checkInterval: const Duration(minutes: 2),
      failureThreshold: 3,
    );

    return _instance!;
  }

  static BackendService get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('BackendService not initialized');
    }
    return i;
  }

  /// Enhanced API client for advanced operations
  EnhancedApiClient get apiClient => _apiClient;

  /// Service health status
  ServiceHealth? get health =>
      ServiceHealthMonitor.instance.getServiceHealth('backend');

  /// Check if backend service is healthy
  bool get isHealthy => health?.isHealthy ?? false;

  /// Set authentication token
  void setAuthToken(AuthToken token) {
    _apiClient.setAuthToken(token);
  }

  /// Clear authentication token
  void clearAuthToken() {
    _apiClient.clearAuthToken();
  }

  /// Fetch travel ideas with enhanced error handling
  Future<List<Map<String, dynamic>>> fetchIdeas({String? query}) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/ideas',
        queryParameters: query != null && query.isNotEmpty
            ? {'q': query}
            : null,
        fromJson: (data) => data as List<dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!.cast<Map<String, dynamic>>();
      } else {
        throw BackendException(
          'Failed to fetch ideas: ${response.error?.message ?? 'Unknown error'}',
          statusCode: response.statusCode,
          errorType: response.error?.type,
        );
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(
        'Network error while fetching ideas: $e',
        errorType: ApiErrorType.network,
      );
    }
  }

  /// Create booking with enhanced error handling
  Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> bookingData,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/bookings',
        body: bookingData,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw BackendException(
          'Failed to create booking: ${response.error?.message ?? 'Unknown error'}',
          statusCode: response.statusCode,
          errorType: response.error?.type,
        );
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(
        'Network error while creating booking: $e',
        errorType: ApiErrorType.network,
      );
    }
  }

  /// Get booking by ID
  Future<Map<String, dynamic>> getBooking(String bookingId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/bookings/$bookingId',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw BackendException(
          'Failed to get booking: ${response.error?.message ?? 'Unknown error'}',
          statusCode: response.statusCode,
          errorType: response.error?.type,
        );
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(
        'Network error while getting booking: $e',
        errorType: ApiErrorType.network,
      );
    }
  }

  /// Get all bookings for user
  Future<List<Map<String, dynamic>>> getBookings() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/bookings',
        fromJson: (data) => data as List<dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!.cast<Map<String, dynamic>>();
      } else {
        throw BackendException(
          'Failed to get bookings: ${response.error?.message ?? 'Unknown error'}',
          statusCode: response.statusCode,
          errorType: response.error?.type,
        );
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(
        'Network error while getting bookings: $e',
        errorType: ApiErrorType.network,
      );
    }
  }

  /// Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent(
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/payments/create-intent',
        body: paymentData,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw BackendException(
          'Failed to create payment intent: ${response.error?.message ?? 'Unknown error'}',
          statusCode: response.statusCode,
          errorType: response.error?.type,
        );
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(
        'Network error while creating payment intent: $e',
        errorType: ApiErrorType.network,
      );
    }
  }

  /// Register FCM token
  Future<void> registerFcmToken(String token, String platform) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/notifications/register',
        body: {'token': token, 'platform': platform},
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw BackendException(
          'Failed to register FCM token: ${response.error?.message ?? 'Unknown error'}',
          statusCode: response.statusCode,
          errorType: response.error?.type,
        );
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(
        'Network error while registering FCM token: $e',
        errorType: ApiErrorType.network,
      );
    }
  }

  /// Force health check
  Future<ServiceHealth> checkHealth() async {
    return await _apiClient.checkHealth();
  }

  /// Dispose resources
  void dispose() {
    ServiceHealthMonitor.instance.unregisterService('backend');
    _apiClient.dispose();
  }
}

/// Custom exception for backend errors
class BackendException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorType? errorType;

  const BackendException(this.message, {this.statusCode, this.errorType});

  @override
  String toString() => 'BackendException: $message';

  bool get isNetworkError => errorType == ApiErrorType.network;
  bool get isAuthError => errorType == ApiErrorType.authentication;
  bool get isServerError => errorType == ApiErrorType.server;
  bool get isValidationError => errorType == ApiErrorType.validation;
}
