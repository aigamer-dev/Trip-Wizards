import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:http/http.dart' as http;

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  bool _inited = false;
  bool get isConfigured => _inited;
  bool _mockMode = false;
  bool get isMockMode => _mockMode;

  /// Initialize Stripe with the publishable key from environment.
  /// Returns false if no key configured.
  Future<bool> init() async {
    if (_inited) return true;
    // Prefer --dart-define over dotenv for CI/web builds
    String envVar(String name) => (dotenv.dotenv.env[name] ?? '').trim();
    // Helper to read from --dart-define safely (variable names not allowed in const)
    String defVar(String name) {
      switch (name) {
        case 'STRIPE_PUBLISHABLE_KEY_WEB':
          return const String.fromEnvironment(
            'STRIPE_PUBLISHABLE_KEY_WEB',
          ).trim();
        case 'STRIPE_PUBLISHABLE_KEY_ANDROID':
          return const String.fromEnvironment(
            'STRIPE_PUBLISHABLE_KEY_ANDROID',
          ).trim();
        case 'STRIPE_PUBLISHABLE_KEY_IOS':
          return const String.fromEnvironment(
            'STRIPE_PUBLISHABLE_KEY_IOS',
          ).trim();
        case 'STRIPE_PUBLISHABLE_KEY':
        default:
          return const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY').trim();
      }
    }

    // Mock mode toggle allows bypassing Stripe for local dev
    bool parseBool(String s) {
      final v = s.toLowerCase();
      return v == 'true' || v == '1' || v == 'yes' || v == 'y';
    }

    final mockFlags = <String>[
      const String.fromEnvironment('MOCK_PAYMENTS').trim(),
      const String.fromEnvironment('PAYMENTS_MOCK_MODE').trim(),
      envVar('MOCK_PAYMENTS'),
      envVar('PAYMENTS_MOCK_MODE'),
    ].where((e) => e.isNotEmpty).toList();
    _mockMode = mockFlags.any(parseBool);

    // Platform-specific override keys
    final platformKeyName = kIsWeb
        ? 'STRIPE_PUBLISHABLE_KEY_WEB'
        : (defaultTargetPlatform == TargetPlatform.android
              ? 'STRIPE_PUBLISHABLE_KEY_ANDROID'
              : (defaultTargetPlatform == TargetPlatform.iOS
                    ? 'STRIPE_PUBLISHABLE_KEY_IOS'
                    : 'STRIPE_PUBLISHABLE_KEY'));

    // Candidates in priority order: dart-define platform, dart-define generic,
    // .env platform, .env generic
    final candidates = <String>[
      defVar(platformKeyName),
      defVar('STRIPE_PUBLISHABLE_KEY'),
      envVar(platformKeyName),
      envVar('STRIPE_PUBLISHABLE_KEY'),
    ];
    final key = candidates.firstWhere((k) => k.isNotEmpty, orElse: () => '');
    // Validate publishable key format and avoid secret keys by mistake
    if (!_mockMode && (key.isEmpty || !key.startsWith('pk_'))) {
      if (kDebugMode) {
        debugPrint(
          '[StripeService] Missing or invalid STRIPE_PUBLISHABLE_KEY. '
          'Expected value starting with "pk_" via --dart-define or .env.',
        );
      }
      return false;
    }
    if (!_mockMode) {
      Stripe.publishableKey = key;
      // Optionally set a merchant identifier for Apple Pay in future.
      await Stripe.instance.applySettings();
    } else {
      if (kDebugMode) {
        debugPrint(
          '[StripeService] MOCK_PAYMENTS enabled: Stripe calls bypassed',
        );
      }
    }
    _inited = true;
    return true;
  }

  /// Creates a PaymentIntent via backend and presents the PaymentSheet.
  /// [amountCents] must be an integer in the smallest currency unit.
  Future<bool> payWithPaymentSheet({
    required int amountCents,
    String currency = 'USD',
    String? description,
  }) async {
    final ok = await init();
    if (!ok) return false;

    if (_mockMode) {
      // Simulate a short processing delay and succeed
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return true;
    }

    // Resolve backend base URL
    final base = backendBaseUrl;
    if (base == null) return false;
    final baseUri = Uri.parse(base);

    final uri = baseUri.resolve('/payments/create-intent');
    http.Response resp;
    try {
      resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amount': amountCents,
              'currency': currency,
              if (description != null) 'description': description,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('[StripeService] Backend request timed out: $uri');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StripeService] Backend request failed: $e');
      }
      return false;
    }
    if (resp.statusCode != 200) {
      if (kDebugMode) {
        debugPrint(
          '[StripeService] Backend error: ${resp.statusCode} ${resp.body}',
        );
      }
      return false;
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final clientSecret =
        (data['clientSecret'] ?? data['client_secret']) as String?;
    if (clientSecret == null || clientSecret.isEmpty) return false;

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Travel Wizards',
          style: ThemeMode.system,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[StripeService] StripeException: ${e.error.localizedMessage}',
        );
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StripeService] PaymentSheet error: $e');
      }
      return false;
    }
  }

  /// Returns the configured backend base URL if present and valid, else null.
  /// Priority: `--dart-define STRIPE_BACKEND_URL` > `--dart-define BACKEND_BASE_URL`
  /// > `.env STRIPE_BACKEND_URL` > `.env BACKEND_BASE_URL`.
  String? get backendBaseUrl {
    final definedBackend = const String.fromEnvironment('STRIPE_BACKEND_URL');
    final definedBase = const String.fromEnvironment('BACKEND_BASE_URL');
    final raw =
        (definedBackend.isNotEmpty
                ? definedBackend
                : (definedBase.isNotEmpty
                      ? definedBase
                      : (dotenv.dotenv.env['STRIPE_BACKEND_URL'] ??
                            dotenv.dotenv.env['BACKEND_BASE_URL'])))
            ?.trim();
    if (raw == null || raw.isEmpty) return null;
    // Avoid accidental secret keys and validate URL
    if (raw.startsWith('sk_') || raw.startsWith('rk_')) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return null;
    }
    return uri.toString();
  }

  /// Simple health check for the payments backend. Returns true if reachable.
  Future<bool> pingBackend({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final base = backendBaseUrl;
    if (base == null) return false;
    final uri = Uri.parse(base).resolve('/payments/health');
    try {
      final resp = await http.get(uri).timeout(timeout);
      return resp.statusCode == 200;
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('[StripeService] Backend health timeout: $uri');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StripeService] Backend health error: $e');
      }
      return false;
    }
  }
}
