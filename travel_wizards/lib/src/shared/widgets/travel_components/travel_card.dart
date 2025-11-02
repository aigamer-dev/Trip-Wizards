import 'package:flutter/material.dart';
import '../../../ui/design_tokens.dart';

/// A card styled according to the design tokens.
///
/// This card uses the design tokens for consistent styling across the app.
class TravelCard extends StatelessWidget {
  const TravelCard({
    super.key,
    this.child,
    this.color,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.shape,
    this.borderOnForeground = true,
    this.margin,
    this.clipBehavior,
    this.semanticContainer = true,
    this.onTap,
    this.onLongPress,
  });

  final Widget? child;
  final Color? color;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool borderOnForeground;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;
  final bool semanticContainer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      elevation: elevation ?? 1.0,
      shape:
          shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
      borderOnForeground: borderOnForeground,
      margin: margin ?? EdgeInsets.zero,
      clipBehavior: clipBehavior ?? Clip.none,
      semanticContainer: semanticContainer,
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        child: card,
      );
    }

    return card;
  }
}
