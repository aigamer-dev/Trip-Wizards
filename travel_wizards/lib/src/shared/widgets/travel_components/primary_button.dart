import 'package:flutter/material.dart';
import '../../../ui/design_tokens.dart';

/// A primary button styled according to the design tokens.
///
/// This button uses the primary color from the color scheme and is intended
/// for the most important actions in the UI.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
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
    return ElevatedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      onHover: onHover,
      onFocusChange: onFocusChange,
      style:
          style ??
          ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
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
