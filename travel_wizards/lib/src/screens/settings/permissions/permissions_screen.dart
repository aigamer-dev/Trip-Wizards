import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:travel_wizards/src/services/calendar_service.dart';
import 'package:travel_wizards/src/services/local_sync_repository.dart';
import 'package:travel_wizards/src/services/contacts_service.dart';

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Sync contacts',
              onPressed: _syncContacts,
              icon: const Icon(Icons.contacts_rounded),
            ),
            IconButton(
              tooltip: 'Sync calendar trips',
              onPressed: _syncCalendar,
              icon: const Icon(Icons.sync_rounded),
            ),
          ],
        ),
        _PermissionTile(
          title: 'Location',
          description: 'Suggest nearby places and weather',
          status: _statuses['Location'],
          onRequest: () => _request(Permission.locationWhenInUse),
        ),
        _PermissionTile(
          title: 'Contacts',
          description: 'Invite buddies to trips',
          status: _statuses['Contacts'],
          onRequest: () => _request(Permission.contacts),
        ),
        _PermissionTile(
          title: 'Calendar',
          description: 'Save trip dates and reminders',
          status: _statuses['Calendar'],
          onRequest: () => _request(Permission.calendarFullAccess),
        ),
        const SizedBox(height: 24),
        if (_lastCalTime != null || _lastContactsTime != null) ...[
          Text(
            'Last Calendar sync: '
            '${_lastCalTime != null ? '${_lastCalTime!.toLocal()} ($_lastCalCount events)' : 'never'}',
          ),
          const SizedBox(height: 4),
          Text(
            'Last Contacts sync: '
            '${_lastContactsTime != null ? '${_lastContactsTime!.toLocal()} ($_lastContactsCount contacts)' : 'never'}',
          ),
          const SizedBox(height: 16),
        ],
        FilledButton.icon(
          onPressed: openAppSettings,
          icon: const Icon(Icons.app_settings_alt_rounded),
          label: const Text('Change permissions in system settings'),
        ),
        if (_syncMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _syncMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
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
    return Card(
      child: ListTile(
        leading: Icon(
          granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: granted
              ? Colors.green
              : (denied ? Colors.red : Theme.of(context).colorScheme.outline),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: granted
            ? const Text('Allowed', style: TextStyle(color: Colors.green))
            : TextButton(onPressed: onRequest, child: const Text('Allow')),
      ),
    );
  }
}
