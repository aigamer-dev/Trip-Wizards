import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/services/notification_service.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';

// --- TOP-LEVEL HELPER FUNCTIONS ---

Color _getNotificationColor(TripNotificationType type) {
  switch (type) {
    case TripNotificationType.emergency:
      return Colors.red.shade700;
    case TripNotificationType.weatherAlert:
      return Colors.orange.shade700;
    case TripNotificationType.delay:
      return Colors.amber.shade700;
    case TripNotificationType.reminder:
      return Colors.blue.shade700;
    case TripNotificationType.checkIn:
      return Colors.green.shade700;
    case TripNotificationType.itineraryUpdate:
      return Colors.purple.shade700;
    case TripNotificationType.bookingUpdate:
      return Colors.teal.shade700;
    case TripNotificationType.general:
      return Colors.grey.shade700;
  }
}

IconData _getNotificationIcon(TripNotificationType type) {
  switch (type) {
    case TripNotificationType.emergency:
      return Symbols.emergency_rounded;
    case TripNotificationType.weatherAlert:
      return Symbols.wb_sunny_rounded;
    case TripNotificationType.delay:
      return Symbols.schedule_rounded;
    case TripNotificationType.reminder:
      return Symbols.schedule_rounded;
    case TripNotificationType.checkIn:
      return Symbols.location_on_rounded;
    case TripNotificationType.itineraryUpdate:
      return Symbols.update_rounded;
    case TripNotificationType.bookingUpdate:
      return Symbols.receipt_long_rounded;
    case TripNotificationType.general:
      return Symbols.info_rounded;
  }
}

String _formatNotificationTime(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  } else {
    return '${difference.inDays}d ago';
  }
}

/// Screen for viewing and managing trip notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (!_notificationService.isInitialized) {
      try {
        await _notificationService.initialize();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to initialize notifications: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernPageScaffold(
      pageTitle: 'Notifications',
      actions: [
        IconButton(
          icon: const Icon(Symbols.mark_email_read_rounded),
          onPressed: () => _handleMenuAction('mark_all_read'),
          tooltip: 'Mark All Read',
        ),
        IconButton(
          icon: const Icon(Symbols.clear_all_rounded),
          onPressed: () => _handleMenuAction('clear_all'),
          tooltip: 'Clear All',
        ),
      ],
      sections: [
        ModernSection(
          title: 'Recent Notifications',
          child: _buildNotificationsList(),
        ),
        _buildNotificationSettings(),
      ],
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<List<TripNotification>>(
      stream: _notificationService.notificationListStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Symbols.error_rounded, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading notifications: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeNotifications,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Symbols.notifications_off_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see your trip updates and alerts here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const VGap(Insets.xl),
              ],
            ),
          );
        }

        // Group notifications by date
        final groupedNotifications = _groupNotificationsByDate(notifications);

        return Column(
          children: groupedNotifications.map((group) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.lg,
                    Insets.md,
                    Insets.lg,
                    Insets.sm,
                  ),
                  child: Text(
                    _formatGroupDate(group.date),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...group.notifications.map(
                  (notification) => _NotificationCard(
                    notification: notification,
                    onTap: () => _handleNotificationTap(notification),
                    onLongPress: () => _showNotificationOptions(notification),
                  ),
                ),
                const VGap(Insets.xl),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildNotificationSettings() {
    return StreamBuilder<NotificationSettings>(
      stream: _notificationService.settingsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final settings = snapshot.data!;

        return ModernSection(
          title: 'Notification Settings',
          children: [
            _buildSettingsTile(
              'Enable Notifications',
              'Receive trip updates and alerts',
              Symbols.notifications_rounded,
              settings.enabled,
              (value) => _updateSettings(settings.copyWith(enabled: value)),
            ),
            _buildSettingsTile(
              'Real-time Updates',
              'Get live updates during your trip',
              Symbols.update_rounded,
              settings.realTimeUpdates,
              (value) =>
                  _updateSettings(settings.copyWith(realTimeUpdates: value)),
            ),
            _buildSettingsTile(
              'In-app Notifications',
              'Show notifications while using the app',
              Symbols.notifications_active_rounded,
              settings.showInAppNotifications,
              (value) => _updateSettings(
                settings.copyWith(showInAppNotifications: value),
              ),
            ),
            const Divider(),
            _buildSettingsTile(
              'Trip Updates',
              'Itinerary changes and updates',
              Symbols.update_rounded,
              settings.tripUpdates,
              (value) => _updateSettings(settings.copyWith(tripUpdates: value)),
            ),
            _buildSettingsTile(
              'Weather Alerts',
              'Weather warnings for your destination',
              Symbols.wb_sunny_rounded,
              settings.weatherAlerts,
              (value) =>
                  _updateSettings(settings.copyWith(weatherAlerts: value)),
            ),
            _buildSettingsTile(
              'Reminders',
              'Trip and activity reminders',
              Symbols.schedule_rounded,
              settings.reminders,
              (value) => _updateSettings(settings.copyWith(reminders: value)),
            ),
            _buildSettingsTile(
              'Booking Updates',
              'Confirmation and booking changes',
              Symbols.receipt_long_rounded,
              settings.bookingUpdates,
              (value) =>
                  _updateSettings(settings.copyWith(bookingUpdates: value)),
            ),
            _buildSettingsTile(
              'Emergency Alerts',
              'Important safety notifications',
              Symbols.emergency_rounded,
              settings.emergencyAlerts,
              (value) =>
                  _updateSettings(settings.copyWith(emergencyAlerts: value)),
            ),
            const Divider(),
            _buildSettingsTile(
              'Sound',
              'Play notification sounds',
              Symbols.volume_up_rounded,
              settings.soundEnabled,
              (value) =>
                  _updateSettings(settings.copyWith(soundEnabled: value)),
            ),
            _buildSettingsTile(
              'Vibration',
              'Vibrate for notifications',
              Symbols.vibration_rounded,
              settings.vibrationEnabled,
              (value) =>
                  _updateSettings(settings.copyWith(vibrationEnabled: value)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }

  // Helper methods
  List<NotificationGroup> _groupNotificationsByDate(
    List<TripNotification> notifications,
  ) {
    final groups = <NotificationGroup>[];

    for (final notification in notifications) {
      final date = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );

      final existingGroup = groups.cast<NotificationGroup?>().firstWhere(
        (group) => group?.date == date,
        orElse: () => null,
      );

      if (existingGroup != null) {
        existingGroup.notifications.add(notification);
      } else {
        groups.add(
          NotificationGroup(date: date, notifications: [notification]),
        );
      }
    }

    return groups;
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleNotificationTap(TripNotification notification) {
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // Navigate to relevant screen based on notification type
    switch (notification.type) {
      case TripNotificationType.itineraryUpdate:
      case TripNotificationType.checkIn:
        if (notification.tripId.isNotEmpty) {
          Navigator.of(context).pushNamed(
            'trip_details',
            arguments: {'tripId': notification.tripId},
          );
        }
        break;
      case TripNotificationType.bookingUpdate:
        Navigator.of(context).pushNamed('bookings');
        break;
      case TripNotificationType.weatherAlert:
        // Could open weather details or trip details
        break;
      default:
        // Show notification details dialog
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(TripNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              'Received: ${_formatNotificationTime(notification.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Additional details available',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationOptions(TripNotification notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.mark_email_read_rounded),
              title: Text(
                notification.isRead ? 'Mark as Unread' : 'Mark as Read',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _notificationService.markAsRead(notification.id);
              },
            ),
            ListTile(
              leading: const Icon(Symbols.info_rounded),
              title: const Text('View Details'),
              onTap: () {
                Navigator.of(context).pop();
                _showNotificationDetails(notification);
              },
            ),
            if (notification.tripId.isNotEmpty)
              ListTile(
                leading: const Icon(Symbols.map_rounded),
                title: const Text('View Trip'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(
                    'trip_details',
                    arguments: {'tripId': notification.tripId},
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        _notificationService.markAllAsRead();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _notificationService.clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _updateSettings(NotificationSettings newSettings) {
    _notificationService.updateSettings(newSettings);
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    this.onTap,
    this.onLongPress,
  });

  final TripNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Card(
      elevation: isUnread ? 2 : 1,
      margin: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: Corners.lgBorder,
        side: isUnread
            ? BorderSide(color: theme.colorScheme.primary, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: Corners.lgBorder,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                size: 40,
                backgroundColor: _getNotificationColor(notification.type),
                icon: _getNotificationIcon(notification.type),
                iconColor: Colors.white,
              ),
              const HGap(Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const VGap(Insets.xs),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const VGap(Insets.sm),
                    Row(
                      children: [
                        Icon(
                          Symbols.schedule_rounded,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const HGap(Insets.xs),
                        Text(
                          _formatNotificationTime(notification.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const Spacer(),
                        if (notification.priority == NotificationPriority.high)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: Corners.xlBorder,
                            ),
                            child: Text(
                              'High',
                              style: TextStyle(
                                color: theme.colorScheme.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isUnread) ...[
                const HGap(Insets.sm),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class for grouping notifications by date
class NotificationGroup {
  final DateTime date;
  final List<TripNotification> notifications;

  NotificationGroup({required this.date, required this.notifications});
}
