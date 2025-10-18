import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

class ModernSection extends StatelessWidget {
  const ModernSection({
    super.key,
    required this.title,
    this.child,
    this.children,
    this.subtitle,
    this.actions,
    this.icon,
    this.padding,
    this.contentPadding,
    this.badgeLabel,
    this.highlights = false,
    this.tags,
    this.selectedTags,
    this.onTagSelected,
  }) : assert(
         child == null || children == null,
         'Cannot provide both a child and children.',
       );

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? child;
  final List<Widget>? children;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;
  final String? badgeLabel;
  final bool highlights;
  final List<String>? tags;
  final Set<String>? selectedTags;
  final void Function(String tag, bool selected)? onTagSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final basePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final cardContentPadding =
        contentPadding ?? const EdgeInsets.fromLTRB(20, 20, 20, 20);

    return Padding(
      padding: basePadding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: highlights
                ? scheme.secondaryContainer.withValues(alpha: 0.3)
                : scheme.surfaceContainerHigh,
            border: highlights
                ? Border.all(
                    color: scheme.secondary.withValues(alpha: 0.2),
                    width: 1,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: cardContentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(icon, color: scheme.primary, size: 24),
                        ),
                      if (icon != null) const HGap(Insets.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const VGap(Insets.sm),
                              Text(
                                subtitle!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (actions != null) ...[
                        const HGap(Insets.md),
                        Row(mainAxisSize: MainAxisSize.min, children: actions!),
                      ],
                    ],
                  ),
                  if (tags != null && tags!.isNotEmpty)
                    _buildFilterChips(theme),
                  if (child != null ||
                      (children != null && children!.isNotEmpty))
                    const SizedBox(height: 16),
                  if (child != null)
                    child!
                  else if (children != null)
                    ...children!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tag in tags!)
              FilterChip(
                label: Text(tag),
                selected: selectedTags?.contains(tag.toLowerCase()) ?? false,
                onSelected: (selected) => onTagSelected?.call(tag, selected),
              ),
          ],
        ),
      ],
    );
  }
}
