import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_client_models.dart';
import 'api_interceptors.dart';

/// Enhanced API client with comprehensive features
class EnhancedApiClient {
  final ApiClientConfig _config;
  final http.Client _httpClient;
  final List<ApiInterceptor> _interceptors;
  final RetryPolicy _retryPolicy;

  // Health monitoring
  ServiceHealth? _lastHealthCheck;
  Timer? _healthTimer;
  final StreamController<ServiceHealth> _healthStreamController;

  // Connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  EnhancedApiClient._({
    required ApiClientConfig config,
    http.Client? httpClient,
    List<ApiInterceptor>? interceptors,
    RetryPolicy? retryPolicy,
  }) : _config = config,
       _httpClient = httpClient ?? http.Client(),
       _interceptors = interceptors ?? [],
       _retryPolicy = retryPolicy ?? const RetryPolicy(),
       _healthStreamController = StreamController<ServiceHealth>.broadcast() {
    _initializeConnectivityMonitoring();
    _startHealthMonitoring();
  }

  /// Factory constructor with default configuration
  factory EnhancedApiClient({
    required ApiClientConfig config,
    http.Client? httpClient,
    List<ApiInterceptor>? interceptors,
    RetryPolicy? retryPolicy,
  }) {
    return EnhancedApiClient._(
      config: config,
      httpClient: httpClient,
      interceptors: interceptors,
      retryPolicy: retryPolicy,
    );
  }

  /// Factory constructor for Travel Wizards backend
  factory EnhancedApiClient.forTravelWizards({
    required String baseUrl,
    String? authToken,
    bool enableLogging = kDebugMode,
  }) {
    final config = ApiClientConfig(
      baseUrl: baseUrl,
      enableLogging: enableLogging,
    );

    final interceptors = <ApiInterceptor>[
      if (enableLogging) LoggingInterceptor(),
      AuthenticationInterceptor(
        tokenProvider: PersistenceInterceptor.loadToken,
        tokenSaver: PersistenceInterceptor.saveToken,
      ),
      UserAgentInterceptor(
        appName: 'TravelWizards',
        appVersion: '1.0.0',
        platform: _getPlatform(),
      ),
      RequestIdInterceptor(),
      CompressionInterceptor(),
      CachingInterceptor(),
    ];

    return EnhancedApiClient._(config: config, interceptors: interceptors);
  }

  /// Stream of health status updates
  Stream<ServiceHealth> get healthStream => _healthStreamController.stream;

  /// Current service health status
  ServiceHealth? get currentHealth => _lastHealthCheck;

  /// Whether the client is connected to the internet
  bool get isConnected => _isConnected;

  /// GET request with comprehensive error handling
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    return _executeRequest<T>(
      'GET',
      path,
      queryParameters: queryParameters,
      headers: headers,
      fromJson: fromJson,
    );
  }

  /// POST request with comprehensive error handling
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    return _executeRequest<T>(
      'POST',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      fromJson: fromJson,
    );
  }

  /// PUT request with comprehensive error handling
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    return _executeRequest<T>(
      'PUT',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      fromJson: fromJson,
    );
  }

  /// PATCH request with comprehensive error handling
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    return _executeRequest<T>(
      'PATCH',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      fromJson: fromJson,
    );
  }

  /// DELETE request with comprehensive error handling
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    return _executeRequest<T>(
      'DELETE',
      path,
      queryParameters: queryParameters,
      headers: headers,
      fromJson: fromJson,
    );
  }

  /// Execute request with retry logic and interceptors
  Future<ApiResponse<T>> _executeRequest<T>(
    String method,
    String path, {
    dynamic body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    // Check connectivity
    if (!_isConnected) {
      return ApiResponse.error(
        statusCode: 0,
        error: ApiError.network('No internet connection'),
      );
    }

    final uri = _config.buildUri(path, queryParameters: queryParameters);
    var requestHeaders = Map<String, String>.from(_config.defaultHeaders);
    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    // Check cache for GET requests
    if (method.toUpperCase() == 'GET') {
      final cachingInterceptor = _interceptors
          .whereType<CachingInterceptor>()
          .firstOrNull;
      if (cachingInterceptor != null) {
        final cachedResponse = cachingInterceptor.getCachedResponse(
          method,
          uri,
        );
        if (cachedResponse != null) {
          try {
            final data = fromJson != null
                ? fromJson(cachedResponse.data)
                : cachedResponse.data as T?;
            return ApiResponse.success(
              statusCode: cachedResponse.statusCode,
              data: data,
              metadata: {'cached': true},
            );
          } catch (e) {
            // Continue with network request if cache parsing fails
          }
        }
      }
    }

    int attempt = 0;
    while (attempt < _retryPolicy.maxAttempts) {
      try {
        // Apply request interceptors
        for (final interceptor in _interceptors) {
          requestHeaders = await interceptor.onRequest(
            method,
            uri,
            requestHeaders,
            body,
          );
        }

        final response = await _sendRequest(method, uri, requestHeaders, body);

        // Apply response interceptors
        for (final interceptor in _interceptors) {
          await interceptor.onResponse(
            method,
            uri,
            response.statusCode,
            response.headers,
            response.body,
          );
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Success response
          try {
            final responseData = response.body.isNotEmpty
                ? jsonDecode(response.body)
                : null;

            final data = fromJson != null && responseData != null
                ? fromJson(responseData)
                : responseData as T?;

            return ApiResponse.success(
              statusCode: response.statusCode,
              data: data,
              metadata: {
                'attempt': attempt + 1,
                'responseTime': '${DateTime.now().millisecondsSinceEpoch}ms',
              },
            );
          } catch (e, stackTrace) {
            final error = ApiError.parsing(
              'Failed to parse response: $e',
              stackTrace: stackTrace,
            );
            await _notifyErrorInterceptors(method, uri, error);
            return ApiResponse.error(
              statusCode: response.statusCode,
              error: error,
            );
          }
        } else {
          // Error response
          final error = _createErrorFromResponse(response);

          // Check if we should retry
          if (attempt < _retryPolicy.maxAttempts - 1 &&
              _retryPolicy.shouldRetry(response.statusCode)) {
            attempt++;
            await Future.delayed(_retryPolicy.getDelay(attempt));
            continue;
          }

          await _notifyErrorInterceptors(method, uri, error);
          return ApiResponse.error(
            statusCode: response.statusCode,
            error: error,
          );
        }
      } on TimeoutException catch (e) {
        final error = ApiError.timeout('Request timeout: ${e.message}');

        if (attempt < _retryPolicy.maxAttempts - 1 &&
            _retryPolicy.retryOnTimeout) {
          attempt++;
          await Future.delayed(_retryPolicy.getDelay(attempt));
          continue;
        }

        await _notifyErrorInterceptors(method, uri, error);
        return ApiResponse.error(statusCode: 408, error: error);
      } on SocketException catch (e) {
        final error = ApiError.network('Network error: ${e.message}');

        if (attempt < _retryPolicy.maxAttempts - 1 &&
            _retryPolicy.retryOnConnectionError) {
          attempt++;
          await Future.delayed(_retryPolicy.getDelay(attempt));
          continue;
        }

        await _notifyErrorInterceptors(method, uri, error);
        return ApiResponse.error(statusCode: 0, error: error);
      } catch (e, stackTrace) {
        final error = ApiError.unknown(
          'Unexpected error: $e',
          stackTrace: stackTrace,
        );
        await _notifyErrorInterceptors(method, uri, error);
        return ApiResponse.error(statusCode: 0, error: error);
      }
    }

    // This should never be reached, but just in case
    final error = ApiError.unknown('Max retry attempts exceeded');
    return ApiResponse.error(statusCode: 0, error: error);
  }

  /// Send HTTP request with timeout
  Future<http.Response> _sendRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
  ) async {
    final bodyString = body != null ? jsonEncode(body) : null;

    switch (method.toUpperCase()) {
      case 'GET':
        return await _httpClient
            .get(uri, headers: headers)
            .timeout(_config.receiveTimeout);
      case 'POST':
        return await _httpClient
            .post(uri, headers: headers, body: bodyString)
            .timeout(_config.sendTimeout);
      case 'PUT':
        return await _httpClient
            .put(uri, headers: headers, body: bodyString)
            .timeout(_config.sendTimeout);
      case 'PATCH':
        return await _httpClient
            .patch(uri, headers: headers, body: bodyString)
            .timeout(_config.sendTimeout);
      case 'DELETE':
        return await _httpClient
            .delete(uri, headers: headers)
            .timeout(_config.receiveTimeout);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Create API error from HTTP response
  ApiError _createErrorFromResponse(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);

      if (errorData is Map<String, dynamic>) {
        final message =
            errorData['message'] ??
            errorData['error'] ??
            'HTTP ${response.statusCode}';
        final errorCode = errorData['code'] ?? errorData['error_code'];

        switch (response.statusCode) {
          case 400:
            return ApiError.validation(
              message: message,
              errorCode: errorCode,
              details: errorData,
            );
          case 401:
            return ApiError.authentication(message, errorCode: errorCode);
          case 403:
            return ApiError.authorization(message, errorCode: errorCode);
          default:
            return ApiError.server(
              statusCode: response.statusCode,
              message: message,
              errorCode: errorCode,
              details: errorData,
            );
        }
      }
    } catch (_) {
      // If we can't parse the error response, use default message
    }

    return ApiError.server(
      statusCode: response.statusCode,
      message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
    );
  }

  /// Notify error interceptors
  Future<void> _notifyErrorInterceptors(
    String method,
    Uri uri,
    ApiError error,
  ) async {
    for (final interceptor in _interceptors) {
      try {
        await interceptor.onError(method, uri, error);
      } catch (e) {
        developer.log('Interceptor error: $e', name: 'EnhancedApiClient');
      }
    }
  }

  /// Perform health check
  Future<ServiceHealth> checkHealth() async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _executeRequest<Map<String, dynamic>>(
        'GET',
        '/health',
      );

      stopwatch.stop();

      if (response.isSuccess) {
        final health = ServiceHealth.healthy(
          responseTime: stopwatch.elapsed,
          metadata: response.data,
        );
        _lastHealthCheck = health;
        _healthStreamController.add(health);
        return health;
      } else {
        final health = ServiceHealth.degraded(
          responseTime: stopwatch.elapsed,
          message: response.error?.message ?? 'Service degraded',
          metadata: {'statusCode': response.statusCode},
        );
        _lastHealthCheck = health;
        _healthStreamController.add(health);
        return health;
      }
    } catch (e) {
      stopwatch.stop();
      final health = ServiceHealth.unhealthy(
        message: 'Health check failed: $e',
        responseTime: stopwatch.elapsed,
      );
      _lastHealthCheck = health;
      _healthStreamController.add(health);
      return health;
    }
  }

  /// Initialize connectivity monitoring
  void _initializeConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _isConnected = results.any((result) => result != ConnectivityResult.none);
    });
  }

  /// Start periodic health monitoring
  void _startHealthMonitoring() {
    // Initial health check
    checkHealth();

    // Periodic health checks every 5 minutes
    _healthTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => checkHealth(),
    );
  }

  /// Get current platform string
  static String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Set authentication token
  void setAuthToken(AuthToken token) {
    final authInterceptor = _interceptors
        .whereType<AuthenticationInterceptor>()
        .firstOrNull;
    authInterceptor?.setToken(token);
  }

  /// Clear authentication token
  void clearAuthToken() {
    final authInterceptor = _interceptors
        .whereType<AuthenticationInterceptor>()
        .firstOrNull;
    authInterceptor?.setToken(null);
    PersistenceInterceptor.clearToken();
  }

  /// Clear response cache
  void clearCache() {
    final cachingInterceptor = _interceptors
        .whereType<CachingInterceptor>()
        .firstOrNull;
    cachingInterceptor?.clearCache();
  }

  /// Dispose resources
  void dispose() {
    _healthTimer?.cancel();
    _connectivitySubscription?.cancel();
    _healthStreamController.close();
    _httpClient.close();
  }
}

// Extension for null-safe first or null
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    try {
      return first;
    } catch (_) {
      return null;
    }
  }
}
