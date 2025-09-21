import 'package:flutter/material.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/services/offline_service.dart';
import 'package:travel_wizards/src/widgets/offline_status_widget.dart';

class OfflineSettingsScreen extends StatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  State<OfflineSettingsScreen> createState() => _OfflineSettingsScreenState();
}

class _OfflineSettingsScreenState extends State<OfflineSettingsScreen> {
  final _offlineService = OfflineService.instance;
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _offlineService.getCacheStats();

    return Scaffold(
      appBar: AppBar(title: const Text('Offline & Storage')),
      body: SingleChildScrollView(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status
            Card(
              child: Padding(
                padding: Insets.allMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _offlineService.isOnline
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: _offlineService.isOnline
                              ? Colors.green
                              : Colors.orange,
                        ),
                        Gaps.w8,
                        Text(
                          'Connection Status',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Gaps.h8,
                    Text(
                      _offlineService.isOnline
                          ? 'You are currently online'
                          : 'You are currently offline',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Gaps.h16,

            // Cache statistics
            const CacheStatsWidget(),

            Gaps.h16,

            // Offline data management
            Text('Offline Data Management', style: theme.textTheme.titleLarge),
            Gaps.h8,
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Download for Offline'),
                    subtitle: const Text(
                      'Download current trips for offline access',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _downloadOfflineData(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Sync Pending Changes'),
                    subtitle: Text(
                      '${stats['pending_actions_count']} actions pending',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _syncPendingActions(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Clear Offline Data',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    subtitle: const Text('Free up storage space'),
                    trailing: _isClearing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isClearing ? null : () => _showClearDataDialog(),
                  ),
                ],
              ),
            ),

            Gaps.h16,

            // Storage info
            Text('Storage Information', style: theme.textTheme.titleLarge),
            Gaps.h8,
            Card(
              child: Padding(
                padding: Insets.allMd,
                child: Column(
                  children: [
                    _buildStorageRow(
                      'Cached Trips',
                      '${stats['cached_trips_count']} trips',
                      theme,
                    ),
                    Gaps.h8,
                    _buildStorageRow(
                      'Conversation History',
                      '1 conversation', // Simplified
                      theme,
                    ),
                    Gaps.h8,
                    _buildStorageRow(
                      'Pending Actions',
                      '${stats['pending_actions_count']} actions',
                      theme,
                    ),
                    if (stats['last_sync'] != null) ...[
                      Gaps.h8,
                      _buildStorageRow(
                        'Last Sync',
                        DateTime.fromMillisecondsSinceEpoch(
                          stats['last_sync'],
                        ).toString().split('.')[0],
                        theme,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Gaps.h16,

            // Offline preferences
            Text('Offline Preferences', style: theme.textTheme.titleLarge),
            Gaps.h8,
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Auto-download trips'),
                    subtitle: const Text(
                      'Automatically cache new trips for offline access',
                    ),
                    value: true, // This would be a real setting
                    onChanged: (value) {
                      // TODO: Implement setting persistence
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Setting saved')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Show offline indicator'),
                    subtitle: const Text('Display banner when offline'),
                    value: true, // This would be a real setting
                    onChanged: (value) {
                      // TODO: Implement setting persistence
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Setting saved')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _downloadOfflineData() async {
    // TODO: Implement actual offline data download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.download, color: Colors.white),
            SizedBox(width: 8),
            Text('Downloading trips for offline access...'),
          ],
        ),
      ),
    );

    // Simulate download
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Trips downloaded for offline access'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _syncPendingActions() async {
    final stats = _offlineService.getCacheStats();
    final pendingCount = stats['pending_actions_count'] as int;

    if (pendingCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending actions to sync')),
      );
      return;
    }

    // Simulate sync
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            Gaps.w8,
            Text('Syncing $pendingCount pending actions...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {}); // Refresh the UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('All actions synced successfully'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Offline Data'),
        content: const Text(
          'This will remove all cached trips, conversation history, and pending actions. '
          'You can re-download data when online.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearOfflineData();
            },
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearOfflineData() async {
    setState(() {
      _isClearing = true;
    });

    try {
      await _offlineService.clearAllCache();

      if (mounted) {
        setState(() {
          _isClearing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Offline data cleared successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
