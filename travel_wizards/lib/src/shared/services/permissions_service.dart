import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermission { location, contacts, calendar }

class PermissionsService {
  PermissionsService._();
  static final PermissionsService instance = PermissionsService._();

  Future<bool> request(
    BuildContext context,
    AppPermission perm, {
    String? rationaleTitle,
    String? rationaleMessage,
  }) async {
    // On web, we don't use permission_handler or dart:io Platform checks.
    // Most features either don't require explicit permissions on web or will
    // prompt via their own APIs (e.g., Geolocator).
    if (kIsWeb) return true;
    final permission = _toPlatformPermission(perm);

    // If already granted
    if (await permission.isGranted) return true;

    // Should show rationale
    if (await permission.shouldShowRequestRationale) {
      if (!context.mounted) return false;
      final ok = await _showRationaleDialog(
        context,
        title: rationaleTitle ?? 'Permission needed',
        message: rationaleMessage ?? _defaultRationale(perm),
      );
      if (ok != true) return false;
    }

    final status = await permission.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      // Ask user to open app settings
      if (!context.mounted) return false;
      final open = await _showOpenSettingsDialog(
        context,
        title: 'Permission required',
        message:
            'Please enable the permission in App Settings to use this feature.',
      );
      if (open == true) {
        await openAppSettings();
      }
    }
    return false;
  }

  /// Request permission without showing any dialogs or routing to settings.
  /// Returns immediately after calling platform request and ignores the result.
  Future<void> requestSilently(AppPermission perm) async {
    // No-op on web to avoid unsupported Platform and plugin APIs.
    if (kIsWeb) return;
    final permission = _toPlatformPermission(perm);
    if (await permission.isGranted) return;
    // Don't show rationale or settings; just attempt a single request.
    await permission.request();
  }

  Permission _toPlatformPermission(AppPermission p) {
    switch (p) {
      case AppPermission.location:
        // Avoid touching Platform on web; default to generic location.
        if (kIsWeb) return Permission.location;
        return Platform.isAndroid
            ? Permission.locationWhenInUse
            : Permission.location;
      case AppPermission.contacts:
        return Permission.contacts;
      case AppPermission.calendar:
        // Use the cross-platform calendar permission (safer across Android/iOS).
        return Permission.calendarFullAccess;
    }
  }

  String _defaultRationale(AppPermission p) {
    switch (p) {
      case AppPermission.location:
        return 'Location helps us suggest nearby places and weather for your trips.';
      case AppPermission.contacts:
        return 'Contacts access lets you invite buddies to trips easily.';
      case AppPermission.calendar:
        return 'Calendar access allows saving trip dates and reminders.';
    }
  }

  Future<bool?> _showRationaleDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showOpenSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
