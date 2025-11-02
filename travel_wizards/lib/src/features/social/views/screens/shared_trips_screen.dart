import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/services/clean_trip_sharing_service.dart'
    as clean_service;

class SharedTripsScreen extends StatefulWidget {
  const SharedTripsScreen({super.key});

  @override
  State<SharedTripsScreen> createState() => _SharedTripsScreenState();
}

class _SharedTripsScreenState extends State<SharedTripsScreen> {
  final _sharingService = clean_service.TripSharingService.instance;
  List<Map<String, dynamic>> _sharedTrips = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSharedTrips();
  }

  Future<void> _loadSharedTrips() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final trips = await _sharingService.getUserSharedTrips();

      if (mounted) {
        setState(() {
          _sharedTrips = trips;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Trips'),
        actions: [
          IconButton(
            icon: const Icon(Symbols.refresh_rounded),
            onPressed: _loadSharedTrips,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            Gaps.h16,
            Text(
              'Error loading shared trips',
              style: theme.textTheme.titleLarge,
            ),
            Gaps.h8,
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Gaps.h16,
            FilledButton.icon(
              onPressed: _loadSharedTrips,
              icon: const Icon(Symbols.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sharedTrips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.share_rounded,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            Gaps.h16,
            Text('No shared trips', style: theme.textTheme.titleLarge),
            Gaps.h8,
            Text(
              'Trips you share with others will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSharedTrips,
      child: ListView.builder(
        padding: Insets.allMd,
        itemCount: _sharedTrips.length,
        itemBuilder: (context, index) {
          final sharedTrip = _sharedTrips[index];
          return _buildSharedTripCard(sharedTrip, theme);
        },
      ),
    );
  }

  Widget _buildSharedTripCard(
    Map<String, dynamic> sharedTrip,
    ThemeData theme,
  ) {
    final tripTitle = sharedTrip['tripTitle'] as String;
    final viewCount = sharedTrip['viewCount'] as int? ?? 0;
    final sharedAt = sharedTrip['sharedAt']?.toDate() as DateTime?;
    final expiresAt = sharedTrip['expiresAt'] as DateTime?;
    final accessLevel = sharedTrip['accessLevel'] as String? ?? 'view';

    final isExpiringSoon =
        expiresAt != null &&
        expiresAt.isAfter(DateTime.now()) &&
        expiresAt.difference(DateTime.now()).inDays < 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tripTitle,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Symbols.visibility_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$viewCount ${viewCount == 1 ? 'view' : 'views'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Gaps.w16,
                          Icon(
                            _getAccessLevelIcon(accessLevel),
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getAccessLevelText(accessLevel),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Symbols.more_vert_rounded),
                  onSelected: (action) => _handleTripAction(action, sharedTrip),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'copy_link',
                      child: Row(
                        children: [
                          Icon(Symbols.link_rounded),
                          SizedBox(width: 12),
                          Text('Copy Link'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Symbols.share_rounded),
                          SizedBox(width: 12),
                          Text('Share Again'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'analytics',
                      child: Row(
                        children: [
                          Icon(Symbols.analytics_rounded),
                          SizedBox(width: 12),
                          Text('View Analytics'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'revoke',
                      child: Row(
                        children: [
                          Icon(Symbols.link_off_rounded, color: Colors.red),
                          SizedBox(width: 12),
                          Text(
                            'Revoke Access',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (sharedAt != null) ...[
              Gaps.h8,
              Text(
                'Shared ${_formatDate(sharedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            if (isExpiringSoon) ...[
              Gaps.h8,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.schedule_rounded,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires ${_formatDate(expiresAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getAccessLevelIcon(String accessLevel) {
    switch (accessLevel) {
      case 'view':
        return Symbols.visibility_rounded;
      case 'edit':
        return Symbols.edit_rounded;
      case 'collaborate':
        return Symbols.groups_rounded;
      default:
        return Symbols.lock_rounded;
    }
  }

  String _getAccessLevelText(String accessLevel) {
    switch (accessLevel) {
      case 'view':
        return 'View only';
      case 'edit':
        return 'Can edit';
      case 'collaborate':
        return 'Can collaborate';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _handleTripAction(
    String action,
    Map<String, dynamic> sharedTrip,
  ) async {
    final shareId = sharedTrip['shareId'] as String;
    final tripId = sharedTrip['tripId'] as String;
    final tripTitle = sharedTrip['tripTitle'] as String;

    switch (action) {
      case 'copy_link':
        await _copyShareLink(shareId);
        break;
      case 'share':
        await _shareAgain(tripId, tripTitle);
        break;
      case 'analytics':
        await _showAnalytics(tripId, tripTitle);
        break;
      case 'revoke':
        await _revokeAccess(shareId, tripTitle);
        break;
    }
  }

  Future<void> _copyShareLink(String shareId) async {
    try {
      await clean_service.TripSharingService.instance.copyShareableLink(
        shareId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Share link copied to clipboard'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error copying link: $e')));
      }
    }
  }

  Future<void> _shareAgain(String tripId, String tripTitle) async {
    try {
      // Get trip data for sharing
      await clean_service.TripSharingService.instance.shareTrip(
        tripId: tripId,
        tripTitle: tripTitle,
        destinations:
            [], // Would get actual destinations in real implementation
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing trip: $e')));
      }
    }
  }

  Future<void> _showAnalytics(String tripId, String tripTitle) async {
    try {
      final analytics = await _sharingService.getSharingAnalytics(tripId);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) =>
              _AnalyticsDialog(tripTitle: tripTitle, analytics: analytics),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  Future<void> _revokeAccess(String shareId, String tripTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text(
          'Are you sure you want to revoke access to "$tripTitle"? '
          'The shared link will no longer work.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _sharingService.revokeSharedLink(shareId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Access revoked successfully'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the list
          _loadSharedTrips();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error revoking access: $e')));
        }
      }
    }
  }
}

class _AnalyticsDialog extends StatelessWidget {
  final String tripTitle;
  final Map<String, dynamic> analytics;

  const _AnalyticsDialog({required this.tripTitle, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activityByType =
        analytics['activityByType'] as Map<String, dynamic>? ?? {};

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Symbols.analytics_rounded),
          Gaps.w8,
          const Expanded(child: Text('Sharing Analytics')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tripTitle, style: theme.textTheme.titleMedium),
            Gaps.h16,
            _buildAnalyticRow(
              'Total Shares',
              '${analytics['totalShares']}',
              theme,
            ),
            _buildAnalyticRow(
              'Total Views',
              '${analytics['totalViews']}',
              theme,
            ),
            _buildAnalyticRow(
              'Active Shares',
              '${analytics['activeShares']}',
              theme,
            ),

            if (activityByType.isNotEmpty) ...[
              Gaps.h16,
              Text('Sharing Methods', style: theme.textTheme.titleSmall),
              Gaps.h8,
              ...activityByType.entries.map((entry) {
                return _buildAnalyticRow(
                  _formatActivityType(entry.key),
                  '${entry.value}',
                  theme,
                );
              }),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildAnalyticRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatActivityType(String type) {
    switch (type) {
      case 'native_share':
        return 'Share Dialog';
      case 'copy_link':
        return 'Copy Link';
      case 'qr_code':
        return 'QR Code';
      case 'pdf_export':
        return 'PDF Export';
      default:
        return type;
    }
  }
}
