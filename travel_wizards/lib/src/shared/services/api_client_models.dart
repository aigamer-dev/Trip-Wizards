import 'package:flutter/foundation.dart';

/// API client configuration with comprehensive settings
@immutable
class ApiClientConfig {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final int maxRetries;
  final Duration retryDelay;
  final Map<String, String> defaultHeaders;
  final bool enableLogging;
  final String apiVersion;

  const ApiClientConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.enableLogging = kDebugMode,
    this.apiVersion = 'v1',
  });

  ApiClientConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    int? maxRetries,
    Duration? retryDelay,
    Map<String, String>? defaultHeaders,
    bool? enableLogging,
    String? apiVersion,
  }) {
    return ApiClientConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      enableLogging: enableLogging ?? this.enableLogging,
      apiVersion: apiVersion ?? this.apiVersion,
    );
  }

  Uri buildUri(String path, {Map<String, String>? queryParameters}) {
    // Ensure path starts with /
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    // Add API version prefix if not already present
    final versionedPath = normalizedPath.startsWith('/api/')
        ? normalizedPath
        : '/api/$apiVersion$normalizedPath';

    return Uri.parse(baseUrl).replace(
      path: versionedPath,
      queryParameters: queryParameters?.isNotEmpty == true
          ? queryParameters
          : null,
    );
  }
}

/// Retry policy configuration
@immutable
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final List<int> retryStatusCodes;
  final bool retryOnTimeout;
  final bool retryOnConnectionError;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.retryStatusCodes = const [408, 429, 500, 502, 503, 504],
    this.retryOnTimeout = true,
    this.retryOnConnectionError = true,
  });

  Duration getDelay(int attempt) {
    final delay = initialDelay * (backoffMultiplier * attempt);
    return delay > maxDelay ? maxDelay : delay;
  }

  bool shouldRetry(
    int statusCode, {
    bool isTimeout = false,
    bool isConnectionError = false,
  }) {
    if (isTimeout && retryOnTimeout) return true;
    if (isConnectionError && retryOnConnectionError) return true;
    return retryStatusCodes.contains(statusCode);
  }
}

/// Authentication token model
@immutable
class AuthToken {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String tokenType;

  const AuthToken({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.tokenType = 'Bearer',
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final buffer = const Duration(minutes: 5);
    return DateTime.now().add(buffer).isAfter(expiresAt!);
  }

  String get authorizationHeader => '$tokenType $accessToken';

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt?.toIso8601String(),
      'token_type': tokenType,
    };
  }
}

/// API response wrapper
@immutable
class ApiResponse<T> {
  final int statusCode;
  final T? data;
  final String? message;
  final Map<String, dynamic>? metadata;
  final bool success;
  final ApiError? error;

  const ApiResponse._({
    required this.statusCode,
    this.data,
    this.message,
    this.metadata,
    required this.success,
    this.error,
  });

  factory ApiResponse.success({
    required int statusCode,
    T? data,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse._(
      statusCode: statusCode,
      data: data,
      message: message,
      metadata: metadata,
      success: true,
    );
  }

  factory ApiResponse.error({
    required int statusCode,
    required ApiError error,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse._(
      statusCode: statusCode,
      message: message,
      metadata: metadata,
      success: false,
      error: error,
    );
  }

  bool get isSuccess => success && error == null;
  bool get isError => !success || error != null;
}

/// Comprehensive API error types
@immutable
class ApiError implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? details;
  final StackTrace? stackTrace;

  const ApiError({
    required this.type,
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
    this.stackTrace,
  });

  factory ApiError.network(String message, {StackTrace? stackTrace}) {
    return ApiError(
      type: ApiErrorType.network,
      message: message,
      stackTrace: stackTrace,
    );
  }

  factory ApiError.timeout(String message, {StackTrace? stackTrace}) {
    return ApiError(
      type: ApiErrorType.timeout,
      message: message,
      stackTrace: stackTrace,
    );
  }

  factory ApiError.server({
    required int statusCode,
    required String message,
    String? errorCode,
    Map<String, dynamic>? details,
  }) {
    return ApiError(
      type: ApiErrorType.server,
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      details: details,
    );
  }

  factory ApiError.authentication(String message, {String? errorCode}) {
    return ApiError(
      type: ApiErrorType.authentication,
      message: message,
      statusCode: 401,
      errorCode: errorCode,
    );
  }

  factory ApiError.authorization(String message, {String? errorCode}) {
    return ApiError(
      type: ApiErrorType.authorization,
      message: message,
      statusCode: 403,
      errorCode: errorCode,
    );
  }

  factory ApiError.validation({
    required String message,
    Map<String, dynamic>? details,
    String? errorCode,
  }) {
    return ApiError(
      type: ApiErrorType.validation,
      message: message,
      statusCode: 400,
      errorCode: errorCode,
      details: details,
    );
  }

  factory ApiError.parsing(String message, {StackTrace? stackTrace}) {
    return ApiError(
      type: ApiErrorType.parsing,
      message: message,
      stackTrace: stackTrace,
    );
  }

  factory ApiError.unknown(String message, {StackTrace? stackTrace}) {
    return ApiError(
      type: ApiErrorType.unknown,
      message: message,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    return 'ApiError(type: $type, message: $message, statusCode: $statusCode, errorCode: $errorCode)';
  }
}

enum ApiErrorType {
  network,
  timeout,
  server,
  authentication,
  authorization,
  validation,
  parsing,
  unknown,
}

/// Request/Response interceptor interface
abstract class ApiInterceptor {
  /// Called before request is sent
  Future<Map<String, String>> onRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
  ) async {
    return headers;
  }

  /// Called after response is received
  Future<void> onResponse(
    String method,
    Uri uri,
    int statusCode,
    Map<String, String> headers,
    dynamic body,
  ) async {}

  /// Called when an error occurs
  Future<void> onError(String method, Uri uri, ApiError error) async {}
}

/// Service health status
enum ServiceHealthStatus { healthy, degraded, unhealthy, unknown }

/// Service health information
@immutable
class ServiceHealth {
  final ServiceHealthStatus status;
  final String message;
  final Duration responseTime;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ServiceHealth({
    required this.status,
    required this.message,
    required this.responseTime,
    required this.timestamp,
    this.metadata,
  });

  bool get isHealthy => status == ServiceHealthStatus.healthy;
  bool get isDegraded => status == ServiceHealthStatus.degraded;
  bool get isUnhealthy => status == ServiceHealthStatus.unhealthy;

  factory ServiceHealth.healthy({
    required Duration responseTime,
    String message = 'Service is healthy',
    Map<String, dynamic>? metadata,
  }) {
    return ServiceHealth(
      status: ServiceHealthStatus.healthy,
      message: message,
      responseTime: responseTime,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  factory ServiceHealth.degraded({
    required Duration responseTime,
    required String message,
    Map<String, dynamic>? metadata,
  }) {
    return ServiceHealth(
      status: ServiceHealthStatus.degraded,
      message: message,
      responseTime: responseTime,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  factory ServiceHealth.unhealthy({
    required String message,
    Duration? responseTime,
    Map<String, dynamic>? metadata,
  }) {
    return ServiceHealth(
      status: ServiceHealthStatus.unhealthy,
      message: message,
      responseTime: responseTime ?? Duration.zero,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }
}
