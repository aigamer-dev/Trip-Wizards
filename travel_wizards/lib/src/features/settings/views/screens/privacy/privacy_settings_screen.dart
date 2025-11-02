import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;
import 'package:travel_wizards/src/core/app/settings_controller.dart';
import 'package:travel_wizards/src/core/config/env.dart';
import 'package:travel_wizards/src/shared/services/data_portability_service.dart';
import 'package:travel_wizards/src/shared/services/stripe_service.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return ModernPageScaffold(
      hero: _buildHeroCard(context),
      sections: [
        ModernSection(
          title: 'Privacy',
          subtitle: 'Control data retention and export your information.',
          icon: Icons.privacy_tip_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withDividers([
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: settings.privateMode,
                title: const Text('Private mode'),
                subtitle: const Text(
                  'Limit data persistence and sharing across services',
                ),
                onChanged: settings.setPrivateMode,
              ),
              _buildTile(
                context,
                leading: Icons.download_rounded,
                title: 'Export my data',
                subtitle: 'Download a JSON archive (GDPR portability)',
                onTap: () => _exportUserData(context),
              ),
              _buildTile(
                context,
                leading: Icons.delete_forever_rounded,
                title: 'Delete my account & data',
                subtitle:
                    'Permanently erase everything. This cannot be undone.',
                onTap: () => _confirmDeletion(context),
              ),
            ]),
          ),
        ),
        ModernSection(
          title: 'Notifications',
          subtitle: 'Stay informed while keeping control over alerts.',
          icon: Icons.notifications_active_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withDividers([
              FutureBuilder<NotificationSettings>(
                future: FirebaseMessaging.instance.getNotificationSettings(),
                builder: (context, snapshot) {
                  final ns = snapshot.data;
                  final status = ns?.authorizationStatus;
                  final descriptor = _notificationStatusDescriptor(status);
                  return _buildTile(
                    context,
                    leading: Icons.verified_user_rounded,
                    title: 'Notification permission',
                    subtitle: descriptor.message,
                    trailing: descriptor.trailing,
                    onTap: () => openAppSettings(),
                  );
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: settings.notificationsEnabled,
                title: const Text('Enable notifications'),
                subtitle: const Text(
                  'Receive trip reminders and concierge updates',
                ),
                onChanged: settings.setNotificationsEnabled,
              ),
              _buildTile(
                context,
                leading: Icons.send_rounded,
                title: 'Send test push to this device',
                subtitle:
                    'Requires backend connectivity and allowed notifications',
                onTap: () => _sendTestPush(context),
              ),
              _buildTile(
                context,
                leading: Icons.copy_rounded,
                title: 'Copy FCM token',
                subtitle: 'Handy for debugging backend integrations',
                onTap: () => _copyFcmToken(context),
              ),
            ]),
          ),
        ),
        ModernSection(
          title: 'Data usage',
          subtitle: 'Connectivity preferences for syncing content.',
          icon: Icons.wifi_rounded,
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: settings.wifiOnlySync,
            title: const Text('Wi-Fi only sync'),
            subtitle: const Text(
              'Reduce mobile data usage when updating content',
            ),
            onChanged: settings.setWifiOnlySync,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your privacy cockpit',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Export your data, manage notifications, and dial in the right amount of sync.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportUserData(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }

    try {
      final json = await DataPortabilityService.instance.exportUserData(
        uid: user.uid,
      );
      final dir = await getTemporaryDirectory();
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save exported data',
        fileName: 'travel_wizards_export.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: dir.path,
      );

      if (savePath == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export cancelled')));
        return;
      }

      await File(savePath).writeAsString(json);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Data exported to $savePath')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _confirmDeletion(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DataPortabilityService.instance.deleteUserData(uid: user.uid);
      await user.delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account and data deleted.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deletion failed: $e')));
    }
  }

  Future<void> _sendTestPush(BuildContext context) async {
    final base = StripeService.instance.backendBaseUrl ?? kBackendBaseUrl;
    if (base.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Backend URL not set')));
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No FCM token available')));
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

      if (!context.mounted) return;
      final ok = resp.statusCode >= 200 && resp.statusCode < 300;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Test push sent' : 'Failed to send test push'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error contacting backend')));
    }
  }

  Future<void> _copyFcmToken(BuildContext context) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No FCM token available')));
      return;
    }

    await Clipboard.setData(ClipboardData(text: token));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied FCM token')));
  }

  _NotificationDescriptor _notificationStatusDescriptor(
    AuthorizationStatus? status,
  ) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return _NotificationDescriptor(
          message: 'Authorized – notifications are enabled on this device.',
          trailing: const Chip(label: Text('On')),
        );
      case AuthorizationStatus.provisional:
        return _NotificationDescriptor(
          message: 'Provisional – alerts are partially limited.',
          trailing: const Chip(label: Text('Limited')),
        );
      case AuthorizationStatus.denied:
        return _NotificationDescriptor(
          message: 'Denied – enable notifications in system settings.',
          trailing: FilledButton.tonal(
            onPressed: () async {
              await FirebaseMessaging.instance.requestPermission();
            },
            child: const Text('Request'),
          ),
        );
      case AuthorizationStatus.notDetermined:
        return _NotificationDescriptor(
          message: 'Not determined – request permission to stay informed.',
          trailing: FilledButton.tonal(
            onPressed: () async {
              await FirebaseMessaging.instance.requestPermission();
            },
            child: const Text('Allow'),
          ),
        );
      default:
        return const _NotificationDescriptor(
          message: 'Notification status unavailable.',
        );
    }
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(leading, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
      horizontalTitleGap: 16,
    );
  }

  List<Widget> _withDividers(List<Widget> children) {
    final widgets = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      widgets.add(children[i]);
      if (i < children.length - 1) {
        widgets.add(const Divider(height: 20));
      }
    }
    return widgets;
  }
}

class _NotificationDescriptor {
  const _NotificationDescriptor({required this.message, this.trailing});

  final String message;
  final Widget? trailing;
}
