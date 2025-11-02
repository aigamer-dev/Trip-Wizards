import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/services/calendar_service.dart';
import 'package:travel_wizards/src/shared/services/local_sync_repository.dart';

/// Screen for managing Sync & Backup settings
class SyncBackupScreen extends StatefulWidget {
  const SyncBackupScreen({super.key});

  @override
  State<SyncBackupScreen> createState() => _SyncBackupScreenState();
}

class _SyncBackupScreenState extends State<SyncBackupScreen> {
  bool _isSyncing = false;
  String? _lastSyncStatus;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  void _loadSyncStatus() {
    final repo = LocalSyncRepository.instance;
    final lastTime = repo.calendarLastTime;
    final lastCount = repo.calendarLastCount;

    if (lastTime != null) {
      setState(() {
        _lastSyncStatus = '$lastCount events • Synced ${_formatTime(lastTime)}';
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  Future<void> _performCalendarSync() async {
    setState(() => _isSyncing = true);
    try {
      final count = await CalendarService.syncTripsFromCalendar();
      _loadSyncStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synced $count calendar events'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync calendar'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sync & Backup'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              'Synchronization',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calendar Events',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Import events from your device calendar as trips',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_lastSyncStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _lastSyncStatus!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: _isSyncing ? null : _performCalendarSync,
                    icon: _isSyncing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                scheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(_isSyncing ? 'Syncing...' : 'Sync Calendar'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'About',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Sync Works',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoBullet(
                      context,
                      'Calendar events recognized as trips are imported automatically.',
                    ),
                    _buildInfoBullet(
                      context,
                      'Imported events appear with a calendar badge and are kept separate from manually created trips.',
                    ),
                    _buildInfoBullet(
                      context,
                      'Tap "Sync Calendar" anytime to check for new or updated events.',
                    ),
                    _buildInfoBullet(
                      context,
                      'Your event data syncs securely using your device\'s calendar and Travel Wizards.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(BuildContext context, String text) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: CircleAvatar(
              radius: 3,
              backgroundColor: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
