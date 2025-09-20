import 'package:flutter/material.dart';
import 'package:travel_wizards/src/app/settings_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;
import 'package:travel_wizards/src/services/stripe_service.dart';
import 'package:travel_wizards/src/config/env.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return ListView(
      children: [
        const _SectionHeader('Privacy'),
        SwitchListTile(
          value: settings.privateMode,
          title: const Text('Private mode'),
          subtitle: const Text('Limit data persistence and sharing'),
          onChanged: (v) => settings.setPrivateMode(v),
        ),
        const Divider(),
        const _SectionHeader('Notifications'),
        FutureBuilder<NotificationSettings>(
          future: FirebaseMessaging.instance.getNotificationSettings(),
          builder: (context, snapshot) {
            final ns = snapshot.data;
            final status = ns?.authorizationStatus;
            String subtitle;
            Widget? trailing;
            switch (status) {
              case AuthorizationStatus.authorized:
                subtitle = 'Notifications: Authorized';
                trailing = const Chip(label: Text('On'));
                break;
              case AuthorizationStatus.provisional:
                subtitle = 'Notifications: Provisional';
                trailing = const Chip(label: Text('Limited'));
                break;
              case AuthorizationStatus.denied:
                subtitle = 'Notifications: Denied';
                trailing = FilledButton.tonal(
                  onPressed: () async {
                    await FirebaseMessaging.instance.requestPermission();
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text('Request'),
                );
                break;
              case AuthorizationStatus.notDetermined:
                subtitle = 'Notifications: Not determined';
                trailing = FilledButton.tonal(
                  onPressed: () async {
                    await FirebaseMessaging.instance.requestPermission();
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text('Allow'),
                );
                break;
              default:
                subtitle = 'Notifications';
            }
            return ListTile(
              leading: const Icon(Icons.notifications_active_rounded),
              title: const Text('Notifications status'),
              subtitle: Text(subtitle),
              trailing: trailing,
              onTap: () async {
                await openAppSettings();
              },
            );
          },
        ),
        SwitchListTile(
          value: settings.notificationsEnabled,
          title: const Text('Notifications'),
          subtitle: const Text('Receive trip updates and reminders'),
          onChanged: (v) => settings.setNotificationsEnabled(v),
        ),
        ListTile(
          leading: const Icon(Icons.send_rounded),
          title: const Text('Send test push to this device'),
          subtitle: const Text('Requires backend and notifications allowed'),
          onTap: () async {
            // Prefer StripeService backendBaseUrl, fallback to kBackendBaseUrl
            final base =
                StripeService.instance.backendBaseUrl ?? kBackendBaseUrl;
            if (base.isEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backend URL not set')),
                );
              }
              return;
            }
            final token = await FirebaseMessaging.instance.getToken();
            if (token == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No FCM token available')),
                );
              }
              return;
            }
            final uri = Uri.parse(base).resolve('/notifications/send');
            try {
              final resp = await http.post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'tokens': [token],
                  'title': 'Test Notification',
                  'body': 'Hello from backend \u{1F44B}',
                }),
              );
              if (context.mounted) {
                final ok = resp.statusCode >= 200 && resp.statusCode < 300;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Test push sent' : 'Failed to send test push',
                    ),
                  ),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error contacting backend')),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.copy_rounded),
          title: const Text('Copy FCM token'),
          subtitle: const Text('Useful for backend debugging'),
          onTap: () async {
            final token = await FirebaseMessaging.instance.getToken();
            if (token == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No FCM token available')),
                );
              }
              return;
            }
            await Clipboard.setData(ClipboardData(text: token));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Copied FCM token')));
            }
          },
        ),
        SwitchListTile(
          value: settings.wifiOnlySync,
          title: const Text('Wi\u2011Fi only sync'),
          subtitle: const Text('Reduce mobile data usage'),
          onChanged: (v) => settings.setWifiOnlySync(v),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
  }
}
