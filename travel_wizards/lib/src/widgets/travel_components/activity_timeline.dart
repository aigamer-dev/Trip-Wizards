import 'package:flutter/material.dart';
import '../../app/travel_colors.dart';
import '../../app/travel_icons.dart';
import '../../common/ui/spacing.dart';

/// Activity timeline component for displaying trip itineraries.
///
/// Shows a vertical timeline of activities with time, location, and details
/// in a travel-themed design optimized for itinerary display.
class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({
    super.key,
    required this.activities,
    this.showDates = true,
    this.isCompact = false,
  });

  final List<TimelineActivity> activities;
  final bool showDates;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        for (int index = 0; index < activities.length; index++)
          _buildTimelineItem(
            context,
            activities[index],
            isFirst: index == 0,
            isLast: index == activities.length - 1,
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: Insets.allLg,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            TravelIcons.itinerary,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No activities planned yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start building your itinerary',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    TimelineActivity activity, {
    required bool isFirst,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          _buildTimelineIndicator(context, activity, isFirst, isLast),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 24),
              child: isCompact
                  ? _buildCompactContent(context, activity)
                  : _buildFullContent(context, activity),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator(
    BuildContext context,
    TimelineActivity activity,
    bool isFirst,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final statusColor = TravelColors.getStatusColor(activity.status ?? 'draft');

    return Column(
      children: [
        // Top line (if not first)
        if (!isFirst)
          Container(
            width: 2,
            height: 24,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),

        // Activity indicator
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.surface, width: 3),
          ),
          child: Icon(
            activity.icon ??
                TravelIcons.getActivityIcon(activity.type ?? 'location'),
            size: 20,
            color: TravelColors.getContrastingTextColor(statusColor),
          ),
        ),

        // Bottom line (if not last)
        if (!isLast)
          Expanded(
            child: Container(
              width: 2,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactContent(BuildContext context, TimelineActivity activity) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (activity.startTime != null) ...[
                Text(
                  activity.startTime!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  activity.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (activity.location != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  TravelIcons.location,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    activity.location!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullContent(BuildContext context, TimelineActivity activity) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time and title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity.startTime != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activity.startTime!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    activity.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (activity.duration != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activity.duration!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Location
            if (activity.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    TravelIcons.location,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      activity.location!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Description
            if (activity.description != null) ...[
              const SizedBox(height: 8),
              Text(activity.description!, style: theme.textTheme.bodyMedium),
            ],

            // Status and additional info
            if (activity.status != null || activity.price != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (activity.status != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TravelColors.getStatusColor(activity.status!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        activity.status!.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: TravelColors.getContrastingTextColor(
                            TravelColors.getStatusColor(activity.status!),
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (activity.price != null) ...[
                    Text(
                      '${activity.currency ?? '\$'}${activity.price!.toStringAsFixed(0)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Timeline activity data model
class TimelineActivity {
  const TimelineActivity({
    required this.title,
    this.startTime,
    this.endTime,
    this.duration,
    this.location,
    this.description,
    this.type,
    this.status,
    this.price,
    this.currency,
    this.icon,
  });

  final String title;
  final String? startTime; // e.g., "09:00", "Morning"
  final String? endTime;
  final String? duration; // e.g., "2h", "All day"
  final String? location;
  final String? description;
  final String? type; // activity type for icon selection
  final String? status; // booked, pending, cancelled, etc.
  final double? price;
  final String? currency;
  final IconData? icon; // Custom icon override
}
