import 'package:flutter/material.dart';
import '../../app/travel_colors.dart';
import '../../app/travel_icons.dart';
import '../../common/ui/spacing.dart';

/// Enhanced trip card component with travel-themed styling.
///
/// Displays trip information with image, status, type, and key details
/// in a visually appealing card format optimized for travel content.
class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.title,
    required this.destination,
    this.imageUrl,
    this.tripType,
    this.status,
    this.startDate,
    this.endDate,
    this.price,
    this.currency,
    this.description,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.showActions = true,
  });

  final String title;
  final String destination;
  final String? imageUrl;
  final String? tripType;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? price;
  final String? currency;
  final String? description;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildImageHeader(context), _buildContentSection(context)],
        ),
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Image or placeholder
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                    onError: (_, __) {}, // Handle image load errors gracefully
                  )
                : null,
          ),
          child: imageUrl == null
              ? Icon(
                  TravelIcons.location,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                )
              : null,
        ),

        // Status badge
        if (status != null) ...[
          Positioned(
            top: 12,
            left: 12,
            child: TripStatusBadge(status: status!),
          ),
        ],

        // Favorite button
        if (showActions && onFavoriteToggle != null) ...[
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onFavoriteToggle,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isFavorite ? TravelIcons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],

        // Trip type chip
        if (tripType != null) ...[
          Positioned(
            bottom: 12,
            left: 12,
            child: TripTypeChip(tripType: tripType!),
          ),
        ],
      ],
    );
  }

  Widget _buildContentSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: Insets.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and destination
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                TravelIcons.location,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  destination,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Description
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Date range and price
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (startDate != null) ...[
                _buildDateInfo(context),
              ] else ...[
                const SizedBox.shrink(),
              ],
              if (price != null) ...[_buildPriceInfo(context)],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(BuildContext context) {
    final theme = Theme.of(context);

    String dateText;
    if (startDate != null && endDate != null) {
      final start = '${startDate!.day}/${startDate!.month}';
      final end = '${endDate!.day}/${endDate!.month}';
      dateText = '$start - $end';
    } else if (startDate != null) {
      dateText = '${startDate!.day}/${startDate!.month}/${startDate!.year}';
    } else {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Icon(
          TravelIcons.calendar,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          dateText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo(BuildContext context) {
    final theme = Theme.of(context);
    final currencySymbol = currency ?? '\$';

    return Text(
      '$currencySymbol${price!.toStringAsFixed(0)}',
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Status badge component for trip cards
class TripStatusBadge extends StatelessWidget {
  const TripStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = TravelColors.getStatusColor(status);
    final textColor = TravelColors.getContrastingTextColor(statusColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TravelIcons.getStatusIcon(status), size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Trip type chip component
class TripTypeChip extends StatelessWidget {
  const TripTypeChip({super.key, required this.tripType});

  final String tripType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TravelIcons.getActivityIcon(tripType),
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            tripType.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
