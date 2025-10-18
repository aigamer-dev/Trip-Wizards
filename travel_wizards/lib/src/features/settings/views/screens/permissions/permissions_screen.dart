import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:travel_wizards/src/shared/services/calendar_service.dart';
import 'package:travel_wizards/src/shared/services/contacts_service.dart';
import 'package:travel_wizards/src/shared/services/local_sync_repository.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _busy = false;
  Map<String, PermissionStatus> _statuses = {};
  String? _syncMessage;
  int _lastCalCount = 0;
  DateTime? _lastCalTime;
  int _lastContactsCount = 0;
  DateTime? _lastContactsTime;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final map = <String, PermissionStatus>{};
    if (kIsWeb) {
      // On web, permissions are either not applicable or handled by browser APIs.
      // Mark them as granted-for-web to avoid errors and simplify UI.
      map['Location'] = PermissionStatus.granted;
      map['Contacts'] = PermissionStatus.denied; // Not applicable on web
      map['Calendar'] = PermissionStatus.denied; // Not applicable on web
    } else {
      map['Location'] = await Permission.locationWhenInUse.status;
      map['Contacts'] = await Permission.contacts.status;
      map['Calendar'] = await Permission.calendarFullAccess.status;
    }
    final repo = LocalSyncRepository.instance;
    _lastCalCount = repo.calendarLastCount;
    _lastCalTime = repo.calendarLastTime;
    _lastContactsCount = repo.contactsLastCount;
    _lastContactsTime = repo.contactsLastTime;
    if (!mounted) return;
    setState(() => _statuses = map);
  }

  Future<void> _request(Permission p) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!kIsWeb) {
        await p.request();
      }
    } finally {
      await _refresh();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncCalendar() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _syncMessage = null;
    });
    try {
      await CalendarService.syncTripsFromCalendar();
      if (!mounted) return;
      setState(() {
        _syncMessage = 'Calendar sync complete';
        _lastCalCount = LocalSyncRepository.instance.calendarLastCount;
        _lastCalTime = LocalSyncRepository.instance.calendarLastTime;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _syncMessage = 'Calendar sync failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncContacts() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _syncMessage = null;
    });
    try {
      await ContactsService.instance.syncContacts();
      if (!mounted) return;
      setState(() {
        _syncMessage = 'Contacts sync complete';
        _lastContactsCount = LocalSyncRepository.instance.contactsLastCount;
        _lastContactsTime = LocalSyncRepository.instance.contactsLastTime;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _syncMessage = 'Contacts sync failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernPageScaffold(
      hero: _buildHeroCard(context),
      sections: [
        ModernSection(
          title: 'Quick controls',
          subtitle: 'Refresh statuses or resync local sources in one tap.',
          icon: Icons.bolt_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _busy ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh statuses'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _busy ? null : _syncContacts,
                    icon: const Icon(Icons.contacts_rounded),
                    label: const Text('Sync contacts'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _busy ? null : _syncCalendar,
                    icon: const Icon(Icons.event_repeat_rounded),
                    label: const Text('Sync calendar trips'),
                  ),
                ],
              ),
              if (_busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
        ModernSection(
          title: 'System permissions',
          subtitle:
              'Grant access so Travel Wizards can personalize recommendations.',
          icon: Icons.verified_user_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PermissionTile(
                title: 'Location',
                description: 'Suggest nearby places and weather',
                status: _statuses['Location'],
                onRequest: () => _request(Permission.locationWhenInUse),
              ),
              const SizedBox(height: 12),
              _PermissionTile(
                title: 'Contacts',
                description: 'Invite buddies to trips',
                status: _statuses['Contacts'],
                onRequest: () => _request(Permission.contacts),
              ),
              const SizedBox(height: 12),
              _PermissionTile(
                title: 'Calendar',
                description: 'Save trip dates and reminders',
                status: _statuses['Calendar'],
                onRequest: () => _request(Permission.calendarFullAccess),
              ),
            ],
          ),
        ),
        ModernSection(
          title: 'Sync history',
          subtitle:
              'Keep an eye on the last successful imports from your device.',
          icon: Icons.history_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSyncRow(
                context,
                label: 'Calendar',
                timestamp: _lastCalTime,
                count: _lastCalCount,
                unit: 'events',
              ),
              const SizedBox(height: 8),
              _buildSyncRow(
                context,
                label: 'Contacts',
                timestamp: _lastContactsTime,
                count: _lastContactsCount,
                unit: 'contacts',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.app_settings_alt_rounded),
                label: const Text('Open system settings'),
              ),
              if (_syncMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _syncMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final theme = Theme.of(context);
    final grantedCount = _statuses.values.where((s) => s.isGranted).length;
    final totalCount = _statuses.length;
    final pending = totalCount - grantedCount;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device access overview',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Grant permissions so we can personalize recommendations, sync contacts, and stay on top of your calendar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatBadge(
                  context,
                  label: 'Granted',
                  value: '$grantedCount',
                  tone: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _buildStatBadge(
                  context,
                  label: 'Pending',
                  value: pending.isNegative ? '–' : '$pending',
                  tone: theme.colorScheme.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context, {
    required String label,
    required String value,
    required Color tone,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncRow(
    BuildContext context, {
    required String label,
    required DateTime? timestamp,
    required int count,
    required String unit,
  }) {
    final theme = Theme.of(context);
    final localTimestamp = timestamp?.toLocal();
    final hasSync = localTimestamp != null;
    final text = hasSync ? '$localTimestamp ($count $unit)' : 'Never synced';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          hasSync ? Icons.check_circle_rounded : Icons.schedule_rounded,
          color: hasSync
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label sync', style: theme.textTheme.titleMedium),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final String description;
  final PermissionStatus? status;
  final VoidCallback onRequest;
  const _PermissionTile({
    required this.title,
    required this.description,
    required this.status,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final granted = status?.isGranted == true;
    final denied =
        status?.isDenied == true ||
        status?.isPermanentlyDenied == true ||
        status?.isRestricted == true;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconColor = granted
        ? scheme.primary
        : (denied ? scheme.error : scheme.outline);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          granted
              ? Chip(
                  label: const Text('Allowed'),
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : FilledButton.tonal(
                  onPressed: onRequest,
                  child: const Text('Allow'),
                ),
        ],
      ),
    );
  }
}
