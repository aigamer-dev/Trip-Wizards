import 'package:flutter/material.dart';

/// Displays a circular profile avatar that gracefully handles loading and
/// network failures without throwing runtime exceptions. When the network image
/// cannot be fetched (e.g. HTTP 429 from Google profile URLs), the widget falls
/// back to an icon or initials.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.size = 40,
    this.initials,
    this.icon = Icons.person_outline_rounded,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.borderWidth = 0,
    this.semanticLabel,
  });

  /// Remote image URL to display.
  final String? photoUrl;

  /// Diameter of the avatar in logical pixels.
  final double size;

  /// Optional initials to show when [photoUrl] is unavailable.
  final String? initials;

  /// Icon to render when neither [photoUrl] nor [initials] are provided.
  final IconData icon;

  /// Background color for the avatar when rendering fallback content.
  final Color? backgroundColor;

  /// Foreground color for the icon/initials fallback.
  final Color? iconColor;

  /// Optional border color.
  final Color? borderColor;

  /// Border width in logical pixels. Ignored when zero.
  final double borderWidth;

  /// Optional semantics label for accessibility tools.
  final String? semanticLabel;

  bool get _hasImage => photoUrl != null && photoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackground =
        backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurface;

    Widget fallback() {
      final textStyle = theme.textTheme.titleMedium?.copyWith(
        color: effectiveIconColor,
        fontWeight: FontWeight.w600,
      );

      final child = (initials != null && initials!.trim().isNotEmpty)
          ? Text(initials!.trim(), style: textStyle)
          : Icon(icon, color: effectiveIconColor, size: size * 0.5);

      return Container(
        alignment: Alignment.center,
        color: effectiveBackground,
        child: child,
      );
    }

    Widget buildImage(BuildContext context) {
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
      final targetSize = (size * dpr).round();

      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        cacheWidth: targetSize > 0 ? targetSize : null,
        cacheHeight: targetSize > 0 ? targetSize : null,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return fallback();
        },
      );
    }

    final child = _hasImage ? buildImage(context) : fallback();

    final avatar = Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: effectiveBackground,
            border: borderWidth > 0
                ? Border.all(
                    color:
                        borderColor ??
                        effectiveIconColor.withAlpha((0.2 * 255).round()),
                    width: borderWidth,
                  )
                : null,
          ),
          child: ClipOval(child: child),
        ),
      ),
    );

    return avatar;
  }
}
