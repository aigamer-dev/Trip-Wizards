import 'package:flutter/material.dart';
import '../../../ui/design_tokens.dart';

/// A text field styled according to the design tokens.
///
/// This text field uses the design tokens for consistent styling across the app.
class TravelTextField extends StatelessWidget {
  const TravelTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.enabled,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.onTap,
    this.autofillHints,
    this.restorationId,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final bool? enabled;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final GestureTapCallback? onTap;
  final Iterable<String>? autofillHints;
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration:
          decoration ??
          InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            hintStyle: DesignTokens.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            labelStyle: DesignTokens.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style:
          style ??
          DesignTokens.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
      textAlign: textAlign,
      readOnly: readOnly,
      autofocus: autofocus,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      maxLength: maxLength,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      enabled: enabled,
      cursorColor: cursorColor ?? colorScheme.primary,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      enableInteractiveSelection: enableInteractiveSelection,
      onTap: onTap,
      autofillHints: autofillHints,
      restorationId: restorationId,
    );
  }
}
