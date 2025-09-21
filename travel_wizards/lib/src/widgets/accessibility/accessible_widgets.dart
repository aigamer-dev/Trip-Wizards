import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../services/accessibility_service.dart';

/// Enhanced button with comprehensive accessibility features
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final String? hint;
  final ButtonStyle? style;
  final bool isPrimary;
  final bool isDestructive;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.hint,
    this.style,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;

    Widget button;
    if (isPrimary) {
      button = ElevatedButton(
        onPressed: _handlePress(accessibilityService),
        style: style,
        child: child,
      );
    } else {
      button = OutlinedButton(
        onPressed: _handlePress(accessibilityService),
        style: style,
        child: child,
      );
    }

    return Tooltip(
      message: tooltip ?? semanticLabel ?? '',
      child: Semantics(
        label: semanticLabel,
        hint:
            hint ??
            (isDestructive ? 'Warning: This action cannot be undone' : null),
        button: true,
        enabled: onPressed != null,
        child: button,
      ),
    );
  }

  VoidCallback? _handlePress(AccessibilityService accessibilityService) {
    if (onPressed == null) return null;

    return () {
      accessibilityService.provideHapticFeedback();
      if (isDestructive) {
        accessibilityService.announceToScreenReader(
          'Destructive action activated',
        );
      }
      onPressed!();
    };
  }
}

/// Enhanced card with accessibility features
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final String? hint;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isHeader;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AccessibleCard({
    super.key,
    required this.child,
    this.semanticLabel,
    this.hint,
    this.onTap,
    this.isSelected = false,
    this.isHeader = false,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Semantics(
        label: semanticLabel,
        hint: hint,
        button: onTap != null,
        selected: isSelected,
        header: isHeader,
        child: Card(
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    accessibilityService.provideHapticFeedback();
                    accessibilityService.announceToScreenReader(
                      isSelected
                          ? '$semanticLabel selected'
                          : '$semanticLabel activated',
                    );
                    onTap!();
                  },
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced text field with accessibility features
class AccessibleTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? semanticLabel;
  final String? errorText;
  final bool required;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const AccessibleTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.semanticLabel,
    this.errorText,
    this.required = false,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;

    return Semantics(
      label: semanticLabel ?? label,
      hint: hint,
      textField: true,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
          errorText: errorText,
          suffixIcon: required
              ? const Icon(Icons.star, size: 8, color: Colors.red)
              : null,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: (value) {
          if (onChanged != null) {
            onChanged!(value);
          }
          if (errorText != null && value.isNotEmpty) {
            accessibilityService.announceToScreenReader('Error cleared');
          }
        },
        onTap: onTap == null
            ? null
            : () {
                accessibilityService.provideHapticFeedback();
                onTap!();
              },
      ),
    );
  }
}

/// Enhanced list tile with accessibility features
class AccessibleListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final String? semanticLabel;
  final String? hint;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isHeader;

  const AccessibleListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.semanticLabel,
    this.hint,
    this.onTap,
    this.isSelected = false,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;

    return Semantics(
      label: semanticLabel,
      hint: hint,
      button: onTap != null,
      selected: isSelected,
      header: isHeader,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        selected: isSelected,
        onTap: onTap == null
            ? null
            : () {
                accessibilityService.provideHapticFeedback();
                accessibilityService.announceToScreenReader(
                  '$semanticLabel ${isSelected ? 'selected' : 'activated'}',
                );
                onTap!();
              },
      ),
    );
  }
}

/// Enhanced switch with accessibility features
class AccessibleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? semanticLabel;
  final String? hint;

  const AccessibleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.semanticLabel,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;

    return Semantics(
      label: semanticLabel ?? label,
      hint: hint,
      toggled: value,
      child: SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged == null
            ? null
            : (newValue) {
                accessibilityService.provideHapticFeedback();
                accessibilityService.announceToScreenReader(
                  '$label ${newValue ? 'enabled' : 'disabled'}',
                );
                onChanged!(newValue);
              },
      ),
    );
  }
}

/// Enhanced slider with accessibility features
class AccessibleSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String label;
  final String? semanticLabel;
  final String Function(double)? semanticFormatter;

  const AccessibleSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.divisions,
    required this.label,
    this.semanticLabel,
    this.semanticFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Semantics(
          label: semanticLabel ?? label,
          value: semanticFormatter?.call(value) ?? value.toString(),
          slider: true,
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged == null
                ? null
                : (newValue) {
                    accessibilityService.provideHapticFeedback();
                    onChanged!(newValue);
                  },
            onChangeEnd: (newValue) {
              accessibilityService.announceToScreenReader(
                '${semanticLabel ?? label} set to ${semanticFormatter?.call(newValue) ?? newValue.toString()}',
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Enhanced navigation item with accessibility features
class AccessibleNavigationItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final String? semanticLabel;
  final String? hint;
  final VoidCallback? onTap;
  final bool isSelected;
  final int? badgeCount;

  const AccessibleNavigationItem({
    super.key,
    required this.icon,
    required this.label,
    this.semanticLabel,
    this.hint,
    this.onTap,
    this.isSelected = false,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;

    String fullLabel = semanticLabel ?? label;
    if (badgeCount != null && badgeCount! > 0) {
      fullLabel += ', $badgeCount new items';
    }
    if (isSelected) {
      fullLabel += ', selected';
    }

    return Semantics(
      label: fullLabel,
      hint: hint,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                accessibilityService.provideHapticFeedback();
                accessibilityService.announceToScreenReader('$label selected');
                onTap!();
              },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                icon,
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount! > 99 ? '99+' : badgeCount.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced chip with accessibility features
class AccessibleChip extends StatelessWidget {
  final Widget label;
  final String? semanticLabel;
  final String? hint;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final bool isSelected;
  final Widget? avatar;

  const AccessibleChip({
    super.key,
    required this.label,
    this.semanticLabel,
    this.hint,
    this.onPressed,
    this.onDeleted,
    this.isSelected = false,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;

    if (onPressed != null) {
      return Semantics(
        label: semanticLabel,
        hint: hint,
        button: true,
        selected: isSelected,
        child: FilterChip(
          label: label,
          avatar: avatar,
          selected: isSelected,
          onSelected: (selected) {
            accessibilityService.provideHapticFeedback();
            accessibilityService.announceToScreenReader(
              '${semanticLabel ?? 'Chip'} ${selected ? 'selected' : 'deselected'}',
            );
            onPressed!();
          },
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      hint: hint,
      child: Chip(
        label: label,
        avatar: avatar,
        onDeleted: onDeleted == null
            ? null
            : () {
                accessibilityService.provideHapticFeedback();
                accessibilityService.announceToScreenReader(
                  '${semanticLabel ?? 'Chip'} deleted',
                );
                onDeleted!();
              },
      ),
    );
  }
}

/// Widget that announces loading states to screen readers
class AccessibleLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool isLoading;
  final Widget child;

  const AccessibleLoadingIndicator({
    super.key,
    this.message,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;

    if (isLoading) {
      // Announce loading state to screen reader
      WidgetsBinding.instance.addPostFrameCallback((_) {
        accessibilityService.announceToScreenReader(message ?? 'Loading');
      });

      return Semantics(
        label: message ?? 'Loading',
        liveRegion: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!),
            ],
          ],
        ),
      );
    }

    return child;
  }
}

/// Widget that manages focus for screen readers
class AccessibleFocusScope extends StatefulWidget {
  final Widget child;
  final String? label;
  final bool autoFocus;

  const AccessibleFocusScope({
    super.key,
    required this.child,
    this.label,
    this.autoFocus = false,
  });

  @override
  State<AccessibleFocusScope> createState() => _AccessibleFocusScopeState();
}

class _AccessibleFocusScopeState extends State<AccessibleFocusScope> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: Semantics(
        label: widget.label,
        focusable: true,
        focused: _focusNode.hasFocus,
        child: widget.child,
      ),
    );
  }
}
