import 'package:flutter/material.dart';
import '../../../ui/design_tokens.dart';

/// A circular avatar styled according to the design tokens.
///
/// This avatar uses the design tokens for consistent styling across the app.
class TravelAvatar extends StatelessWidget {
  const TravelAvatar({
    super.key,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.radius,
    this.minRadius,
    this.maxRadius,
    this.onBackgroundImageError,
    this.onForegroundImageError,
    this.semanticLabel,
  });

  final Widget? child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? radius;
  final double? minRadius;
  final double? maxRadius;
  final ImageErrorListener? onBackgroundImageError;
  final ImageErrorListener? onForegroundImageError;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: backgroundColor ?? colorScheme.surfaceContainerHighest,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      radius: radius ?? DesignTokens.avatarRadius,
      minRadius: minRadius,
      maxRadius: maxRadius,
      onBackgroundImageError: onBackgroundImageError,
      onForegroundImageError: onForegroundImageError,
      child: child,
    );
  }
}
