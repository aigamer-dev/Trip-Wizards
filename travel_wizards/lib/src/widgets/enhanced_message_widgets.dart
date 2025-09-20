import 'package:flutter/material.dart';
import 'package:travel_wizards/src/data/conversation_controller.dart';
import 'package:travel_wizards/src/models/trip.dart';

/// Enhanced message bubble with delivery status and rich content support
class MessageBubble extends StatelessWidget {
  final ConversationMessage message;
  final bool showTimestamp;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    if (isSystem) {
      return _buildSystemMessage(context, theme);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _getBubbleColor(theme, isUser),
                  borderRadius: _getBubbleBorderRadius(isUser),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _getTextColor(theme, isUser),
                      ),
                    ),
                    if (message.metadata != null &&
                        message.metadata!.isNotEmpty)
                      _buildMetadataChips(context, theme),
                  ],
                ),
              ),
              _buildMessageFooter(context, theme, isUser),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.7,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  message.content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(
    BuildContext context,
    ThemeData theme,
    bool isUser,
  ) {
    final List<Widget> footerItems = [];

    // Add timestamp if requested
    if (showTimestamp) {
      footerItems.add(
        Text(
          _formatTimestamp(message.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      );
    }

    // Add delivery status for user messages
    if (isUser) {
      footerItems.add(_buildDeliveryStatus(theme));
    }

    if (footerItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            footerItems
                .expand((widget) => [widget, const SizedBox(width: 8)])
                .toList()
              ..removeLast(), // Remove last spacer
      ),
    );
  }

  Widget _buildDeliveryStatus(ThemeData theme) {
    IconData icon;
    Color color;
    String tooltip;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.schedule;
        color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
        tooltip = 'Sending...';
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
        tooltip = 'Sent';
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = theme.colorScheme.primary;
        tooltip = 'Delivered';
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = theme.colorScheme.error;
        tooltip = 'Failed to send';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildMetadataChips(BuildContext context, ThemeData theme) {
    final metadata = message.metadata!;
    final chips = <Widget>[];

    // Show active trip if available
    if (metadata.containsKey('activeTrip')) {
      final trip = metadata['activeTrip'] as Map<String, dynamic>;
      chips.add(
        Chip(
          avatar: Icon(Icons.place, size: 16, color: theme.colorScheme.primary),
          label: Text(
            trip['title'] as String,
            style: theme.textTheme.bodySmall,
          ),
          backgroundColor: theme.colorScheme.primaryContainer.withValues(
            alpha: 0.3,
          ),
          side: BorderSide.none,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }

  Color _getBubbleColor(ThemeData theme, bool isUser) {
    if (isUser) {
      return theme.colorScheme.primaryContainer;
    } else {
      return theme.colorScheme.surfaceContainerHighest;
    }
  }

  Color _getTextColor(ThemeData theme, bool isUser) {
    if (isUser) {
      return theme.colorScheme.onPrimaryContainer;
    } else {
      return theme.colorScheme.onSurface;
    }
  }

  BorderRadius _getBubbleBorderRadius(bool isUser) {
    if (isUser) {
      return const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(4),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(20),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Typing indicator widget with animated dots
class TypingIndicator extends StatefulWidget {
  final String? userName;

  const TypingIndicator({super.key, this.userName});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = widget.userName ?? 'AI Assistant';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Row(
                  children: List.generate(3, (index) {
                    final delay = index * 0.33;
                    final animationValue = (_animation.value + delay) % 1.0;
                    final opacity = (animationValue < 0.5)
                        ? animationValue * 2
                        : (1.0 - animationValue) * 2;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: opacity.clamp(0.3, 1.0),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              '$userName is typing...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Connection status indicator
class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ConnectionStatusIndicator({
    super.key,
    required this.isConnected,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: theme.colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Lost',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
            ),
        ],
      ),
    );
  }
}

/// Trip context chip for quick trip switching
class TripContextChip extends StatelessWidget {
  final Trip? activeTrip;
  final List<Trip> availableTrips;
  final ValueChanged<Trip?> onTripSelected;

  const TripContextChip({
    super.key,
    this.activeTrip,
    required this.availableTrips,
    required this.onTripSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (availableTrips.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.place, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Trip Context:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('None'),
                    selected: activeTrip == null,
                    onSelected: (_) => onTripSelected(null),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  ...availableTrips.map(
                    (trip) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(trip.title),
                        selected: activeTrip?.id == trip.id,
                        onSelected: (_) => onTripSelected(trip),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
