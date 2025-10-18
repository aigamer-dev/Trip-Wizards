import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/services/navigation_service.dart';

class ModernPageScaffold extends StatefulWidget {
  const ModernPageScaffold({
    super.key,
    this.hero,
    this.body,
    this.sections,
    this.slivers,
    this.sidePanel,
    this.bottomPadding = 32,
    this.controller,
    this.showBackButton = true,
    this.backButtonColor,
    this.floatingActionButton,
    this.pageTitle,
    this.actions,
  });

  final Widget? hero;
  final Widget? body;
  final List<Widget>? sections;
  final List<Widget>? slivers;
  final Widget? sidePanel;
  final double bottomPadding;
  final ScrollController? controller;
  final bool showBackButton;
  final Color? backButtonColor;
  final Widget? floatingActionButton;
  final String? pageTitle;
  final List<Widget>? actions;

  @override
  State<ModernPageScaffold> createState() => _ModernPageScaffoldState();
}

class _ModernPageScaffoldState extends State<ModernPageScaffold> {
  ScrollController? _internalController;

  ScrollController get _controller =>
      widget.controller ?? (_internalController ??= ScrollController());

  bool get _ownsController => widget.controller == null;

  @override
  void dispose() {
    if (_ownsController) {
      _internalController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1180;

          final animatedHero = widget.hero == null
              ? const SizedBox.shrink()
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCirc,
                  switchOutCurve: Curves.easeInCirc,
                  child: Padding(
                    key: ValueKey(widget.hero.runtimeType),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: widget.hero,
                  ),
                );

          if (widget.body != null) {
            return Stack(children: [widget.body!, _buildAppBar(colorScheme)]);
          }

          final bodySections = List<Widget>.generate(
            widget.sections?.length ?? 0,
            (index) {
              final section = widget.sections![index];
              return TweenAnimationBuilder<double>(
                key: ValueKey('section-$index'),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 280 + (index * 70)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - value) * 24),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: section,
              );
            },
          );

          final content = CustomScrollView(
            controller: _controller,
            slivers: [
              SliverToBoxAdapter(child: animatedHero),
              if (widget.sections != null)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => bodySections[index],
                    childCount: bodySections.length,
                  ),
                ),
              if (widget.slivers != null) ...widget.slivers!,
              SliverToBoxAdapter(child: SizedBox(height: widget.bottomPadding)),
            ],
          );

          final backButton = widget.showBackButton
              ? NavigationBackButton(color: widget.backButtonColor)
              : const SizedBox.shrink();

          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ColoredBox(
                    color: colorScheme.surface,
                    child: Stack(
                      children: [
                        content,
                        Positioned(top: 24, left: 24, child: backButton),
                        if (widget.pageTitle != null)
                          Positioned(
                            top: 24,
                            left: 72,
                            right: 72,
                            child: Text(
                              widget.pageTitle!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (widget.actions != null)
                          Positioned(
                            top: 16,
                            right: 24,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.actions!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Material(elevation: 12, child: widget.sidePanel),
                ),
              ],
            );
          }

          return ColoredBox(
            color: colorScheme.surface,
            child: Stack(
              children: [
                content,
                Positioned(top: 24, left: 24, child: backButton),
                if (widget.pageTitle != null)
                  Positioned(
                    top: 24,
                    left: 72,
                    right: 72,
                    child: Text(
                      widget.pageTitle!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (widget.actions != null)
                  Positioned(
                    top: 16,
                    right: 24,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.actions!,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    final backButton = widget.showBackButton
        ? NavigationBackButton(color: widget.backButtonColor)
        : const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      color: colorScheme.surface,
      child: SafeArea(
        child: Row(
          children: [
            backButton,
            if (widget.pageTitle != null)
              Expanded(
                child: Text(
                  widget.pageTitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            if (widget.actions != null)
              Row(mainAxisSize: MainAxisSize.min, children: widget.actions!),
          ],
        ),
      ),
    );
  }
}
