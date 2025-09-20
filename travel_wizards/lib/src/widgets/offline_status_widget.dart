import 'package:flutter/material.dart';
import 'package:travel_wizards/src/services/offline_service.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';

/// Widget that shows offline status and allows manual sync
class OfflineStatusWidget extends StatefulWidget {
  const OfflineStatusWidget({super.key});

  @override
  State<OfflineStatusWidget> createState() => _OfflineStatusWidgetState();
}

class _OfflineStatusWidgetState extends State<OfflineStatusWidget> {
  final _offlineService = OfflineService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_offlineService.isOnline) {
      return const SizedBox.shrink(); // Don't show anything when online
    }

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: Insets.allSm,
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          Gaps.w8,
          Expanded(
            child: Text(
              'You\'re offline. Changes will sync when connected.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (_offlineService.getPendingActions().isNotEmpty) ...[
            Gaps.w8,
            Chip(
              label: Text('${_offlineService.getPendingActions().length}'),
              backgroundColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget that shows cache statistics for debugging
class CacheStatsWidget extends StatelessWidget {
  const CacheStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = OfflineService.instance.getCacheStats();

    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offline Cache Status', style: theme.textTheme.titleMedium),
            Gaps.h8,
            _buildStatRow(
              'Status',
              stats['is_online'] ? 'Online' : 'Offline',
              theme,
            ),
            _buildStatRow(
              'Cached Items',
              '${stats['total_cached_items']}',
              theme,
            ),
            _buildStatRow(
              'Cached Trips',
              '${stats['cached_trips_count']}',
              theme,
            ),
            _buildStatRow(
              'Pending Actions',
              '${stats['pending_actions_count']}',
              theme,
            ),
            if (stats['last_sync'] != null) ...[
              _buildStatRow(
                'Last Sync',
                DateTime.fromMillisecondsSinceEpoch(
                  stats['last_sync'],
                ).toString().split('.')[0],
                theme,
              ),
            ],
            Gaps.h16,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await OfflineService.instance.clearAllCache();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache cleared')),
                      );
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Cache'),
                  ),
                ),
                Gaps.w8,
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // Force sync - in a real app this would trigger network requests
                      OfflineService.instance.setOnlineStatus(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sync triggered')),
                      );
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Force Sync'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mixin to add offline awareness to widgets
mixin OfflineAware<T extends StatefulWidget> on State<T> {
  bool get isOffline => OfflineService.instance.isOffline;
  bool get isOnline => OfflineService.instance.isOnline;

  /// Show offline indicator
  void showOfflineMessage([String? customMessage]) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white),
            Gaps.w8,
            Expanded(
              child: Text(
                customMessage ?? 'Action queued for when you\'re back online',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Handle offline action
  Future<void> handleOfflineAction(
    String actionType,
    Map<String, dynamic> actionData, {
    String? offlineMessage,
  }) async {
    await OfflineService.instance.addPendingAction({
      'type': actionType,
      ...actionData,
    });

    showOfflineMessage(offlineMessage);
  }
}
