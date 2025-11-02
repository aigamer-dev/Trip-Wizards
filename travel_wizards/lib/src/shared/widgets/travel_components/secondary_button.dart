import 'package:flutter/material.dart';
import '../../../ui/design_tokens.dart';

/// A secondary button styled according to the design tokens.
///
/// This button uses the secondary color from the color scheme and is intended
/// for less important actions or alternatives to primary actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
  });

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final ValueChanged<bool>? onFocusChange;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      onHover: onHover,
      onFocusChange: onFocusChange,
      style:
          style ??
          OutlinedButton.styleFrom(
            foregroundColor: colorScheme.secondary,
            side: BorderSide(color: colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.space3,
              vertical: DesignTokens.space1 + DesignTokens.space1,
            ),
            minimumSize: const Size(48.0, 48.0),
            textStyle: DesignTokens.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
      focusNode: focusNode,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
