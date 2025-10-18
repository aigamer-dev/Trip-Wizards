import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'secrets_management_service.dart';

/// Security level configurations
enum SecurityLevel { basic, standard, strict }

/// Security headers configuration and management service
///
/// This service provides comprehensive security headers for HTTP requests
/// and web security configuration to protect against common attacks.
class SecurityHeadersService {
  static SecurityHeadersService? _instance;
  static SecurityHeadersService get instance {
    _instance ??= SecurityHeadersService._();
    return _instance!;
  }

  SecurityHeadersService._();

  /// Get security headers for HTTP requests
  Map<String, String> getSecurityHeaders({
    SecurityLevel level = SecurityLevel.standard,
    Environment? environment,
    Map<String, String>? customHeaders,
  }) {
    final env =
        environment ?? SecretsManagementService.instance.currentEnvironment;
    final headers = <String, String>{};

    // Basic headers (always included)
    headers.addAll(_getBasicHeaders());

    // Level-specific headers
    switch (level) {
      case SecurityLevel.basic:
        headers.addAll(_getBasicSecurityHeaders(env));
        break;
      case SecurityLevel.standard:
        headers.addAll(_getBasicSecurityHeaders(env));
        headers.addAll(_getStandardSecurityHeaders(env));
        break;
      case SecurityLevel.strict:
        headers.addAll(_getBasicSecurityHeaders(env));
        headers.addAll(_getStandardSecurityHeaders(env));
        headers.addAll(_getStrictSecurityHeaders(env));
        break;
    }

    // Add custom headers (override if specified)
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Get Content Security Policy (CSP) header
  String getContentSecurityPolicy({
    Environment? environment,
    List<String>? additionalScriptSources,
    List<String>? additionalStyleSources,
    List<String>? additionalImageSources,
    List<String>? additionalConnectSources,
    bool allowInlineStyles = false,
    bool allowInlineScripts = false,
  }) {
    final env =
        environment ?? SecretsManagementService.instance.currentEnvironment;
    final csp = <String>[];

    // Default source
    csp.add("default-src 'self'");

    // Script sources
    final scriptSources = <String>['self'];
    if (allowInlineScripts || env == Environment.development) {
      scriptSources.add("'unsafe-inline'");
    }
    scriptSources.addAll([
      'https://www.googletagmanager.com',
      'https://www.google-analytics.com',
      'https://js.stripe.com',
      'https://apis.google.com',
      'https://maps.googleapis.com',
    ]);
    if (additionalScriptSources != null) {
      scriptSources.addAll(additionalScriptSources);
    }
    csp.add(
      "script-src ${scriptSources.map((s) => s.startsWith("'") ? s : "'$s'").join(' ')}",
    );

    // Style sources
    final styleSources = <String>['self'];
    if (allowInlineStyles || env == Environment.development) {
      styleSources.add("'unsafe-inline'");
    }
    styleSources.addAll([
      'https://fonts.googleapis.com',
      'https://fonts.gstatic.com',
    ]);
    if (additionalStyleSources != null) {
      styleSources.addAll(additionalStyleSources);
    }
    csp.add(
      "style-src ${styleSources.map((s) => s.startsWith("'") ? s : "'$s'").join(' ')}",
    );

    // Image sources
    final imageSources = <String>['self', 'data:', 'blob:'];
    imageSources.addAll([
      'https://images.unsplash.com',
      'https://maps.googleapis.com',
      'https://maps.gstatic.com',
      'https://www.google-analytics.com',
      'https://www.googletagmanager.com',
      'https://lh3.googleusercontent.com',
    ]);
    if (additionalImageSources != null) {
      imageSources.addAll(additionalImageSources);
    }
    csp.add(
      "img-src ${imageSources.map((s) => s.startsWith("'") ? s : "'$s'").join(' ')}",
    );

    // Connect sources (for API calls)
    final connectSources = <String>['self'];
    connectSources.addAll([
      'https://identitytoolkit.googleapis.com',
      'https://securetoken.googleapis.com',
      'https://firestore.googleapis.com',
      'https://firebase.googleapis.com',
      'https://www.googleapis.com',
      'https://api.stripe.com',
      'https://maps.googleapis.com',
      'https://translation.googleapis.com',
      'https://www.google-analytics.com',
      'https://region1.google-analytics.com',
    ]);

    // Add backend URLs if configured
    final backendSecrets = SecretsManagementService.instance.getBackendSecrets(
      environment: env,
    );
    if (backendSecrets.baseUrl != null) {
      final uri = Uri.parse(backendSecrets.baseUrl!);
      connectSources.add(
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}',
      );
    }
    if (backendSecrets.stripeBackendUrl != null) {
      final uri = Uri.parse(backendSecrets.stripeBackendUrl!);
      connectSources.add(
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}',
      );
    }

    if (additionalConnectSources != null) {
      connectSources.addAll(additionalConnectSources);
    }
    csp.add(
      "connect-src ${connectSources.map((s) => s.startsWith("'") ? s : "'$s'").join(' ')}",
    );

    // Font sources
    csp.add("font-src 'self' https://fonts.gstatic.com data:");

    // Object and embed restrictions
    csp.add("object-src 'none'");
    csp.add("embed-src 'none'");

    // Frame restrictions
    csp.add("frame-ancestors 'none'");
    csp.add("frame-src 'self' https://js.stripe.com");

    // Media sources
    csp.add("media-src 'self' blob: data:");

    // Worker sources
    csp.add("worker-src 'self'");

    // Manifest source
    csp.add("manifest-src 'self'");

    // Base URI restriction
    csp.add("base-uri 'self'");

    // Form action restriction
    csp.add("form-action 'self'");

    return csp.join('; ');
  }

  /// Get basic HTTP headers
  Map<String, String> _getBasicHeaders() {
    return {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
    };
  }

  /// Get basic security headers
  Map<String, String> _getBasicSecurityHeaders(Environment environment) {
    final headers = <String, String>{
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'X-Permitted-Cross-Domain-Policies': 'none',
    };

    // Add CSP header
    headers['Content-Security-Policy'] = getContentSecurityPolicy(
      environment: environment,
    );

    return headers;
  }

  /// Get standard security headers
  Map<String, String> _getStandardSecurityHeaders(Environment environment) {
    final headers = <String, String>{
      'Permissions-Policy': _getPermissionsPolicy(),
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Resource-Policy': 'same-origin',
    };

    // Add HSTS for production
    if (environment == Environment.production) {
      headers['Strict-Transport-Security'] =
          'max-age=31536000; includeSubDomains; preload';
    }

    return headers;
  }

  /// Get strict security headers
  Map<String, String> _getStrictSecurityHeaders(Environment environment) {
    final headers = <String, String>{
      'X-Download-Options': 'noopen',
      'X-DNS-Prefetch-Control': 'off',
      'Expect-CT': 'max-age=86400, enforce',
    };

    // Additional CSP with nonce for scripts in strict mode
    headers['Content-Security-Policy'] = getContentSecurityPolicy(
      environment: environment,
      allowInlineScripts: false,
      allowInlineStyles: false,
    );

    return headers;
  }

  /// Get Permissions Policy header value
  String _getPermissionsPolicy() {
    final policies = <String>[
      'accelerometer=()',
      'ambient-light-sensor=()',
      'autoplay=()',
      'battery=()',
      'camera=(self)',
      'cross-origin-isolated=()',
      'display-capture=()',
      'document-domain=()',
      'encrypted-media=()',
      'execution-while-not-rendered=()',
      'execution-while-out-of-viewport=()',
      'fullscreen=(self)',
      'geolocation=(self)',
      'gyroscope=()',
      'magnetometer=()',
      'microphone=(self)',
      'midi=()',
      'navigation-override=()',
      'payment=(self)',
      'picture-in-picture=()',
      'publickey-credentials-get=(self)',
      'screen-wake-lock=()',
      'sync-xhr=()',
      'usb=()',
      'web-share=(self)',
      'xr-spatial-tracking=()',
    ];

    return policies.join(', ');
  }

  /// Create secure HTTP client with security headers
  http.Client createSecureHttpClient({
    SecurityLevel level = SecurityLevel.standard,
    Environment? environment,
    Map<String, String>? additionalHeaders,
  }) {
    return _SecureHttpClient(
      securityHeaders: getSecurityHeaders(
        level: level,
        environment: environment,
        customHeaders: additionalHeaders,
      ),
    );
  }

  /// Validate security configuration
  SecurityValidationResult validateSecurityConfiguration({
    Environment? environment,
  }) {
    final env =
        environment ?? SecretsManagementService.instance.currentEnvironment;
    final issues = <SecurityIssue>[];
    final recommendations = <String>[];

    // Check HTTPS usage in production
    if (env == Environment.production) {
      final backendSecrets = SecretsManagementService.instance
          .getBackendSecrets(environment: env);
      if (backendSecrets.baseUrl?.startsWith('http://') == true) {
        issues.add(
          SecurityIssue(
            type: SecurityIssueType.insecureTransport,
            severity: SecuritySeverity.high,
            message: 'Backend URL uses HTTP in production environment',
            recommendation: 'Use HTTPS for all production endpoints',
          ),
        );
      }
    }

    // Check development settings in production
    if (env == Environment.production) {
      final devSecrets = SecretsManagementService.instance
          .getDevelopmentSecrets(environment: env);
      if (devSecrets.debugMode) {
        issues.add(
          SecurityIssue(
            type: SecurityIssueType.insecureConfiguration,
            severity: SecuritySeverity.critical,
            message: 'Debug mode enabled in production',
            recommendation: 'Disable debug mode for production builds',
          ),
        );
      }
    }

    // Check API key validation
    try {
      final firebaseSecrets = SecretsManagementService.instance
          .getFirebaseSecrets(environment: env);
      if (firebaseSecrets.webApiKey.isEmpty ||
          firebaseSecrets.androidApiKey.isEmpty) {
        issues.add(
          SecurityIssue(
            type: SecurityIssueType.missingCredentials,
            severity: SecuritySeverity.high,
            message: 'Missing Firebase API keys',
            recommendation: 'Configure all required Firebase API keys',
          ),
        );
      }
    } catch (e) {
      issues.add(
        SecurityIssue(
          type: SecurityIssueType.configurationError,
          severity: SecuritySeverity.critical,
          message: 'Firebase configuration error: $e',
          recommendation: 'Fix Firebase configuration',
        ),
      );
    }

    // Add recommendations based on environment
    switch (env) {
      case Environment.development:
        recommendations.addAll([
          'Consider using HTTPS even in development',
          'Enable CSP reporting to identify issues early',
          'Test with strict security headers',
        ]);
        break;
      case Environment.staging:
        recommendations.addAll([
          'Use production-like security settings',
          'Test all security headers',
          'Validate CSP policies',
        ]);
        break;
      case Environment.production:
        recommendations.addAll([
          'Enable security monitoring',
          'Implement security incident response',
          'Regular security audits',
        ]);
        break;
    }

    return SecurityValidationResult(
      isSecure: issues
          .where((i) => i.severity == SecuritySeverity.critical)
          .isEmpty,
      issues: issues,
      recommendations: recommendations,
      environment: env,
    );
  }
}

/// Secure HTTP client that automatically adds security headers
class _SecureHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> securityHeaders;

  _SecureHttpClient({required this.securityHeaders, http.Client? innerClient})
    : _inner = innerClient ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Add security headers to all requests
    request.headers.addAll(securityHeaders);

    // Ensure User-Agent is set
    if (!request.headers.containsKey('User-Agent')) {
      request.headers['User-Agent'] = 'TravelWizards/1.0 (Flutter; Secure)';
    }

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

/// Security validation result
@immutable
class SecurityValidationResult {
  final bool isSecure;
  final List<SecurityIssue> issues;
  final List<String> recommendations;
  final Environment environment;

  const SecurityValidationResult({
    required this.isSecure,
    required this.issues,
    required this.recommendations,
    required this.environment,
  });

  bool get hasCriticalIssues =>
      issues.any((issue) => issue.severity == SecuritySeverity.critical);
}

/// Security issue details
@immutable
class SecurityIssue {
  final SecurityIssueType type;
  final SecuritySeverity severity;
  final String message;
  final String recommendation;

  const SecurityIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.recommendation,
  });
}

/// Types of security issues
enum SecurityIssueType {
  insecureTransport,
  insecureConfiguration,
  missingCredentials,
  configurationError,
  weakSecurity,
}

/// Security severity levels
enum SecuritySeverity { low, medium, high, critical }
