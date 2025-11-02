import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:travel_wizards/src/shared/services/stripe_service.dart';
import 'package:travel_wizards/src/shared/services/notifications_service.dart';
import 'error_handling_service.dart';

/// Handles FCM push notifications: permissions, token registration, and
/// background message handling. Foreground UI is handled by
/// NotificationsService via SnackBars.
class PushNotificationsService {
  PushNotificationsService._();
  static final PushNotificationsService instance = PushNotificationsService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<String>? _tokenSub;
  bool _permissionsRequested = false;
  bool _permissionsGranted = false;
  Future<void>? _permissionInFlight;

  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    // No-op: relying on system notifications defined in payload or service worker (web).
  }

  Future<void> init() async {
    // Register top-level background handler (Android). Safe to call multiple times.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Permissions are requested post-login via requestPermissionsIfNeeded().

    // Android notification presentation (foreground) is by default disabled; let OS handle if payload has notification.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Subscribe to auth changes to keep token registration current.
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await requestPermissionsIfNeeded();
      }
    });

    // Listen for token refresh events
    _tokenSub?.cancel();
    _tokenSub = _messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
    });

    // Initial token fetch deferred until permissions granted

    // Foreground messages: show a lightweight in-app banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      try {
        final title = message.notification?.title ?? 'Notification';
        final body = message.notification?.body ?? '';
        NotificationsService.instance.show(
          body.isNotEmpty ? '$title: $body' : title,
        );
      } catch (e) {
        ErrorHandlingService.instance.handleError(
          e,
          context: 'PushNotificationsService: Display foreground message',
          showToUser: false,
        );
      }
    });
  }

  Future<void> requestPermissionsIfNeeded({bool force = false}) async {
    if (_permissionsGranted && !force) return;

    if (_permissionInFlight != null) {
      return _permissionInFlight!;
    }

    _permissionInFlight = _runPermissionRequest(force: force);
    try {
      await _permissionInFlight;
    } finally {
      _permissionInFlight = null;
    }
  }

  Future<void> _runPermissionRequest({required bool force}) async {
    if (!force && _permissionsRequested && !_permissionsGranted) {
      return;
    }

    _permissionsRequested = true;

    final granted = await _requestPermissionIfNeeded();
    _permissionsGranted = granted;

    if (granted) {
      await _refreshAndSaveToken();
    }
  }

  Future<bool> _requestPermissionIfNeeded() async {
    if (kIsWeb) return true; // Web prompts via getToken (VAPID)
    // Android 13+ requires runtime permission; Firebase handles this via requestPermission.
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _refreshAndSaveToken() async {
    try {
      String? token;
      if (kIsWeb) {
        // Optionally use VAPID key via env define; fallback to null for browsers supporting auto.
        // To set: --dart-define=WEB_PUSH_VAPID_KEY=... or .env WEB_PUSH_VAPID_KEY
        const vapid = String.fromEnvironment(
          'WEB_PUSH_VAPID_KEY',
          defaultValue: '',
        );
        token = await _messaging.getToken(
          vapidKey: vapid.isEmpty ? null : vapid,
        );
      } else {
        token = await _messaging.getToken();
      }
      if (token != null) {
        await _saveToken(token);
      }
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'PushNotificationsService: Refresh and save FCM token',
        showToUser: false,
      );
    }
  }

  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = {
      'token': token,
      'platform': _platformName(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(token);
    await ref.set(data, SetOptions(merge: true));

    // Also register token with backend if configured (best-effort)
    final base = StripeService.instance.backendBaseUrl;
    if (base != null) {
      final uri = Uri.parse(base).resolve('/notifications/register');
      const maxAttempts = 3;
      var attempt = 0;
      var delayMs = 300; // start with 300ms
      while (attempt < maxAttempts) {
        attempt++;
        try {
          final resp = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'token': token, 'platform': _platformName()}),
              )
              .timeout(const Duration(seconds: 8));
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            break; // success
          }
        } catch (_) {
          // swallow and retry
        }
        // exponential backoff with jitter
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs = (delayMs * 2.2).toInt().clamp(300, 5000);
      }
    }
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  void dispose() {
    _authSub?.cancel();
    _tokenSub?.cancel();
    _authSub = null;
    _tokenSub = null;
  }
}
