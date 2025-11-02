import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client_models.dart';

/// Logging interceptor for debugging and monitoring
class LoggingInterceptor extends ApiInterceptor {
  final bool enableVerboseLogging;
  final String tag;

  LoggingInterceptor({
    this.enableVerboseLogging = kDebugMode,
    this.tag = 'ApiClient',
  });

  @override
  Future<Map<String, String>> onRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
  ) async {
    if (enableVerboseLogging) {
      developer.log('📤 $method ${uri.toString()}', name: tag);

      if (headers.isNotEmpty) {
        final sanitizedHeaders = _sanitizeHeaders(headers);
        developer.log('Headers: ${jsonEncode(sanitizedHeaders)}', name: tag);
      }

      if (body != null) {
        final bodyStr = body is String ? body : jsonEncode(body);
        final truncatedBody = bodyStr.length > 1000
            ? '${bodyStr.substring(0, 1000)}...'
            : bodyStr;
        developer.log('Body: $truncatedBody', name: tag);
      }
    }

    return headers;
  }

  @override
  Future<void> onResponse(
    String method,
    Uri uri,
    int statusCode,
    Map<String, String> headers,
    dynamic body,
  ) async {
    if (enableVerboseLogging) {
      final statusEmoji = _getStatusEmoji(statusCode);
      developer.log(
        '$statusEmoji $method ${uri.toString()} - $statusCode',
        name: tag,
      );

      if (body != null) {
        final bodyStr = body is String ? body : jsonEncode(body);
        final truncatedBody = bodyStr.length > 1000
            ? '${bodyStr.substring(0, 1000)}...'
            : bodyStr;
        developer.log('Response: $truncatedBody', name: tag);
      }
    }
  }

  @override
  Future<void> onError(String method, Uri uri, ApiError error) async {
    developer.log(
      '❌ $method ${uri.toString()} - Error: ${error.message}',
      name: tag,
      error: error,
      stackTrace: error.stackTrace,
    );
  }

  Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    final sanitized = Map<String, String>.from(headers);

    // Remove sensitive headers
    const sensitiveKeys = [
      'authorization',
      'x-api-key',
      'x-auth-token',
      'cookie',
      'set-cookie',
    ];

    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key.toLowerCase())) {
        sanitized[key.toLowerCase()] = '***';
      }
    }

    return sanitized;
  }

  String _getStatusEmoji(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return '✅';
    if (statusCode >= 300 && statusCode < 400) return '🔄';
    if (statusCode >= 400 && statusCode < 500) return '⚠️';
    return '❌';
  }
}

/// Authentication interceptor for token management
class AuthenticationInterceptor extends ApiInterceptor {
  AuthToken? _currentToken;
  final Future<AuthToken?> Function()? tokenProvider;
  final Future<AuthToken?> Function(String refreshToken)? tokenRefresher;
  final Future<void> Function(AuthToken token)? tokenSaver;
  final Future<void> Function()? onTokenExpired;

  AuthenticationInterceptor({
    this.tokenProvider,
    this.tokenRefresher,
    this.tokenSaver,
    this.onTokenExpired,
  });

  /// Set the current authentication token
  void setToken(AuthToken? token) {
    _currentToken = token;
  }

  /// Get the current authentication token
  AuthToken? get currentToken => _currentToken;

  @override
  Future<Map<String, String>> onRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
  ) async {
    // Try to get token from provider if not set
    if (_currentToken == null && tokenProvider != null) {
      _currentToken = await tokenProvider!();
    }

    // Check if token needs refresh
    if (_currentToken?.isExpiringSoon == true &&
        _currentToken?.refreshToken != null &&
        tokenRefresher != null) {
      try {
        final newToken = await tokenRefresher!(_currentToken!.refreshToken!);
        if (newToken != null) {
          _currentToken = newToken;
          await tokenSaver?.call(newToken);
        }
      } catch (e) {
        developer.log(
          'Failed to refresh token: $e',
          name: 'AuthenticationInterceptor',
        );
        // Token refresh failed, may need to re-authenticate
        await onTokenExpired?.call();
      }
    }

    // Add authorization header if token is available
    if (_currentToken != null && !_currentToken!.isExpired) {
      headers['Authorization'] = _currentToken!.authorizationHeader;
    }

    return headers;
  }

  @override
  Future<void> onError(String method, Uri uri, ApiError error) async {
    // Handle authentication errors
    if (error.type == ApiErrorType.authentication) {
      _currentToken = null;
      await onTokenExpired?.call();
    }
  }
}

/// Caching interceptor for response caching
class CachingInterceptor extends ApiInterceptor {
  final Map<String, CacheEntry> _cache = {};
  final Duration defaultCacheDuration;
  final int maxCacheSize;

  CachingInterceptor({
    this.defaultCacheDuration = const Duration(minutes: 5),
    this.maxCacheSize = 100,
  });

  @override
  Future<Map<String, String>> onRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
  ) async {
    // Only cache GET requests
    if (method.toUpperCase() != 'GET') {
      return headers;
    }

    final cacheKey = _getCacheKey(method, uri);
    final entry = _cache[cacheKey];

    if (entry != null && !entry.isExpired) {
      // Add cache control headers to indicate cached response
      headers['X-Cache'] = 'HIT';
      headers['X-Cache-Expires'] = entry.expiresAt.toIso8601String();
    }

    return headers;
  }

  @override
  Future<void> onResponse(
    String method,
    Uri uri,
    int statusCode,
    Map<String, String> headers,
    dynamic body,
  ) async {
    // Only cache successful GET requests
    if (method.toUpperCase() != 'GET' ||
        statusCode < 200 ||
        statusCode >= 300) {
      return;
    }

    final cacheKey = _getCacheKey(method, uri);
    final entry = CacheEntry(
      data: body,
      statusCode: statusCode,
      headers: headers,
      expiresAt: DateTime.now().add(defaultCacheDuration),
    );

    _cache[cacheKey] = entry;

    // Implement LRU eviction if cache is full
    if (_cache.length > maxCacheSize) {
      _evictOldestEntry();
    }
  }

  /// Get cached response if available and not expired
  CacheEntry? getCachedResponse(String method, Uri uri) {
    if (method.toUpperCase() != 'GET') {
      return null;
    }

    final cacheKey = _getCacheKey(method, uri);
    final entry = _cache[cacheKey];

    if (entry != null && !entry.isExpired) {
      return entry;
    }

    // Remove expired entry
    if (entry != null) {
      _cache.remove(cacheKey);
    }

    return null;
  }

  /// Clear all cached entries
  void clearCache() {
    _cache.clear();
  }

  /// Clear expired entries
  void clearExpiredEntries() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }

  String _getCacheKey(String method, Uri uri) {
    return '$method:${uri.toString()}';
  }

  void _evictOldestEntry() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.createdAt.isBefore(oldestTime)) {
        oldestTime = entry.value.createdAt;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }
}

/// Cache entry model
@immutable
class CacheEntry {
  final dynamic data;
  final int statusCode;
  final Map<String, String> headers;
  final DateTime createdAt;
  final DateTime expiresAt;

  CacheEntry({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.expiresAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// User Agent interceptor for consistent user agent headers
class UserAgentInterceptor extends ApiInterceptor {
  final String appName;
  final String appVersion;
  final String platform;

  UserAgentInterceptor({
    required this.appName,
    required this.appVersion,
    required this.platform,
  });

  @override
  Future<Map<String, String>> onRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
  ) async {
    headers['User-Agent'] = '$appName/$appVersion ($platform)';
    return headers;
  }
}

/// Request ID interceptor for tracing
class RequestIdInterceptor extends ApiInterceptor {
  static int _requestCounter = 0;

  @override
  Future<Map<String, String>> onRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
  ) async {
    final requestId =
        'req_${DateTime.now().millisecondsSinceEpoch}_${++_requestCounter}';
    headers['X-Request-ID'] = requestId;
    return headers;
  }
}

/// Compression interceptor for request/response compression
class CompressionInterceptor extends ApiInterceptor {
  @override
  Future<Map<String, String>> onRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
  ) async {
    // Accept compressed responses
    headers['Accept-Encoding'] = 'gzip, deflate';
    return headers;
  }
}

/// Persistence interceptor for storing authentication data
class PersistenceInterceptor extends ApiInterceptor {
  static const String _tokenKey = 'auth_token';

  /// Save authentication token to persistent storage
  static Future<void> saveToken(AuthToken token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, jsonEncode(token.toJson()));
    } catch (e) {
      developer.log('Failed to save token: $e', name: 'PersistenceInterceptor');
    }
  }

  /// Load authentication token from persistent storage
  static Future<AuthToken?> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenJson = prefs.getString(_tokenKey);
      if (tokenJson != null) {
        final tokenData = jsonDecode(tokenJson) as Map<String, dynamic>;
        return AuthToken.fromJson(tokenData);
      }
    } catch (e) {
      developer.log('Failed to load token: $e', name: 'PersistenceInterceptor');
    }
    return null;
  }

  /// Clear stored authentication token
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      developer.log(
        'Failed to clear token: $e',
        name: 'PersistenceInterceptor',
      );
    }
  }
}
