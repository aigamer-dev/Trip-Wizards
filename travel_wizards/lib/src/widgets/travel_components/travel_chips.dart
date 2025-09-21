import 'package:flutter/material.dart';
import '../../app/travel_colors.dart';
import '../../app/travel_icons.dart';

/// Destination chip component for displaying locations.
///
/// A styled chip that displays destination information with optional
/// icons, actions, and travel-themed styling.
class DestinationChip extends StatelessWidget {
  const DestinationChip({
    super.key,
    required this.destination,
    this.country,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.showIcon = true,
    this.backgroundColor,
    this.textColor,
  });

  final String destination;
  final String? country;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool showIcon;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              TravelIcons.location,
              size: 16,
              color: isSelected
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            destination,
            style: theme.textTheme.labelMedium?.copyWith(
              color:
                  textColor ??
                  (isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          if (country != null) ...[
            Text(
              ', $country',
              style: theme.textTheme.labelSmall?.copyWith(
                color:
                    textColor ??
                    (isSelected
                        ? colorScheme.onSecondaryContainer.withValues(
                            alpha: 0.8,
                          )
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      onDeleted: onDelete,
      deleteIcon: onDelete != null
          ? Icon(
              Icons.close,
              size: 16,
              color: isSelected
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            )
          : null,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      selectedColor: backgroundColor ?? colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? colorScheme.secondary : colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}

/// Activity type chip component
class ActivityChip extends StatelessWidget {
  const ActivityChip({
    super.key,
    required this.activity,
    this.onTap,
    this.isSelected = false,
    this.backgroundColor,
    this.selectedColor,
  });

  final String activity;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activityColor = TravelColors.getTripTypeColor(activity);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TravelIcons.getActivityIcon(activity),
            size: 16,
            color: isSelected ? colorScheme.onPrimary : activityColor,
          ),
          const SizedBox(width: 6),
          Text(
            activity,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? colorScheme.onPrimary : activityColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      selectedColor: selectedColor ?? activityColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? activityColor
              : activityColor.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}

/// Price display chip component
class PriceChip extends StatelessWidget {
  const PriceChip({
    super.key,
    required this.price,
    this.currency = '\$',
    this.originalPrice,
    this.showDiscount = false,
    this.backgroundColor,
    this.textColor,
  });

  final double price;
  final String currency;
  final double? originalPrice;
  final bool showDiscount;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasDiscount =
        showDiscount && originalPrice != null && originalPrice! > price;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TravelIcons.budget,
            size: 16,
            color: textColor ?? colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          if (hasDiscount) ...[
            Text(
              '$currency${originalPrice!.toStringAsFixed(0)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: (textColor ?? colorScheme.onPrimaryContainer).withValues(
                  alpha: 0.6,
                ),
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '$currency${price.toStringAsFixed(0)}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor ?? colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Transportation mode chip component
class TransportationChip extends StatelessWidget {
  const TransportationChip({
    super.key,
    required this.transportType,
    this.duration,
    this.onTap,
    this.isSelected = false,
  });

  final String transportType;
  final String? duration;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TravelIcons.getTransportationIcon(transportType),
            size: 18,
            color: isSelected
                ? colorScheme.onSecondaryContainer
                : colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            transportType,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (duration != null) ...[
            const SizedBox(width: 4),
            Text(
              '($duration)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? colorScheme.onSecondaryContainer.withValues(alpha: 0.8)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isSelected ? colorScheme.secondary : colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}
