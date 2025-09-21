import 'package:flutter/material.dart';
import 'package:travel_wizards/src/services/notification_service.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';

/// Screen for viewing and managing trip notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Notifications', icon: Icon(Icons.notifications)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: ListTile(
                  leading: Icon(Icons.mark_email_read),
                  title: Text('Mark All Read'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Clear All'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildNotificationsList(), _buildNotificationSettings()],
      ),
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
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                  Icons.notifications_none,
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
              ],
            ),
          );
        }

        // Group notifications by date
        final groupedNotifications = _groupNotificationsByDate(notifications);

        return ListView.builder(
          padding: Insets.allMd,
          itemCount: groupedNotifications.length,
          itemBuilder: (context, index) {
            final group = groupedNotifications[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == 0 ||
                    groupedNotifications[index - 1].date != group.date) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _formatGroupDate(group.date),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                ...group.notifications.map(
                  (notification) => _buildNotificationCard(notification),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(TripNotification notification) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isUnread
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
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
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'High',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _handleNotificationTap(notification),
        onLongPress: () => _showNotificationOptions(notification),
      ),
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

        return ListView(
          padding: Insets.allMd,
          children: [
            _buildSettingsSection('General', [
              _buildSettingsTile(
                'Enable Notifications',
                'Receive trip updates and alerts',
                Icons.notifications,
                settings.enabled,
                (value) => _updateSettings(settings.copyWith(enabled: value)),
              ),
              _buildSettingsTile(
                'Real-time Updates',
                'Get live updates during your trip',
                Icons.update,
                settings.realTimeUpdates,
                (value) =>
                    _updateSettings(settings.copyWith(realTimeUpdates: value)),
              ),
              _buildSettingsTile(
                'In-app Notifications',
                'Show notifications while using the app',
                Icons.notifications_active,
                settings.showInAppNotifications,
                (value) => _updateSettings(
                  settings.copyWith(showInAppNotifications: value),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSettingsSection('Notification Types', [
              _buildSettingsTile(
                'Trip Updates',
                'Itinerary changes and updates',
                Icons.update,
                settings.tripUpdates,
                (value) =>
                    _updateSettings(settings.copyWith(tripUpdates: value)),
              ),
              _buildSettingsTile(
                'Weather Alerts',
                'Weather warnings for your destination',
                Icons.wb_sunny,
                settings.weatherAlerts,
                (value) =>
                    _updateSettings(settings.copyWith(weatherAlerts: value)),
              ),
              _buildSettingsTile(
                'Reminders',
                'Trip and activity reminders',
                Icons.schedule,
                settings.reminders,
                (value) => _updateSettings(settings.copyWith(reminders: value)),
              ),
              _buildSettingsTile(
                'Booking Updates',
                'Confirmation and booking changes',
                Icons.receipt,
                settings.bookingUpdates,
                (value) =>
                    _updateSettings(settings.copyWith(bookingUpdates: value)),
              ),
              _buildSettingsTile(
                'Emergency Alerts',
                'Important safety notifications',
                Icons.emergency,
                settings.emergencyAlerts,
                (value) =>
                    _updateSettings(settings.copyWith(emergencyAlerts: value)),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSettingsSection('Sound & Vibration', [
              _buildSettingsTile(
                'Sound',
                'Play notification sounds',
                Icons.volume_up,
                settings.soundEnabled,
                (value) =>
                    _updateSettings(settings.copyWith(soundEnabled: value)),
              ),
              _buildSettingsTile(
                'Vibration',
                'Vibrate for notifications',
                Icons.vibration,
                settings.vibrationEnabled,
                (value) =>
                    _updateSettings(settings.copyWith(vibrationEnabled: value)),
              ),
            ]),
          ],
        );
      },
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(child: Column(children: children)),
      ],
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
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
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

  Color _getNotificationColor(TripNotificationType type) {
    switch (type) {
      case TripNotificationType.emergency:
        return Colors.red;
      case TripNotificationType.weatherAlert:
        return Colors.orange;
      case TripNotificationType.delay:
        return Colors.amber;
      case TripNotificationType.reminder:
        return Colors.blue;
      case TripNotificationType.checkIn:
        return Colors.green;
      case TripNotificationType.itineraryUpdate:
        return Colors.purple;
      case TripNotificationType.bookingUpdate:
        return Colors.teal;
      case TripNotificationType.general:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(TripNotificationType type) {
    switch (type) {
      case TripNotificationType.emergency:
        return Icons.emergency;
      case TripNotificationType.weatherAlert:
        return Icons.wb_sunny;
      case TripNotificationType.delay:
        return Icons.access_time;
      case TripNotificationType.reminder:
        return Icons.schedule;
      case TripNotificationType.checkIn:
        return Icons.location_on;
      case TripNotificationType.itineraryUpdate:
        return Icons.update;
      case TripNotificationType.bookingUpdate:
        return Icons.receipt;
      case TripNotificationType.general:
        return Icons.info;
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
              leading: const Icon(Icons.mark_email_read),
              title: Text(
                notification.isRead ? 'Mark as Unread' : 'Mark as Read',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _notificationService.markAsRead(notification.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.of(context).pop();
                _showNotificationDetails(notification);
              },
            ),
            if (notification.tripId.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.map),
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

/// Helper class for grouping notifications by date
class NotificationGroup {
  final DateTime date;
  final List<TripNotification> notifications;

  NotificationGroup({required this.date, required this.notifications});
}
