import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/shared/repositories/ideas_repository.dart';
import 'package:travel_wizards/src/features/explore/views/controllers/explore_controller.dart';
import 'package:travel_wizards/src/core/l10n/app_localizations.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/plan_trip_screen.dart';

/// Optimized filter chips widget that minimizes rebuilds
class OptimizedFilterChips extends StatefulWidget {
  const OptimizedFilterChips({
    super.key,
    required this.controller,
    required this.useRemote,
    this.onFilterChanged,
  });

  final ExploreController controller;
  final bool useRemote;
  final VoidCallback? onFilterChanged;

  @override
  State<OptimizedFilterChips> createState() => _OptimizedFilterChipsState();
}

class _OptimizedFilterChipsState extends State<OptimizedFilterChips> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Semantics(
          container: true,
          header: true,
          label: t.filters,
          child: Material(
            type: MaterialType.transparency,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildTagChip(
                  t.tagWeekend,
                  'Weekend',
                  widget.controller.selectedTags.contains('Weekend'),
                ),
                _buildTagChip(
                  t.tagAdventure,
                  'Adventure',
                  widget.controller.selectedTags.contains('Adventure'),
                ),
                _buildTagChip(
                  t.tagBudget,
                  'Budget',
                  widget.controller.selectedTags.contains('Budget'),
                ),
                _buildBudgetChip(t.budgetLow, 'low'),
                _buildBudgetChip(t.budgetMedium, 'medium'),
                _buildBudgetChip(t.budgetHigh, 'high'),
                _buildDurationChip(t.duration2to3, '2-3'),
                _buildDurationChip(t.duration4to5, '4-5'),
                _buildDurationChip(t.duration6plus, '6+'),
                _buildClearButton(t),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagChip(String label, String tag, bool selected) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => _onTagToggled(tag),
        ),
      ),
    );
  }

  Widget _buildBudgetChip(String label, String budget) {
    final selected = widget.controller.filterBudget == budget;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => _onBudgetChanged(budget),
        ),
      ),
    );
  }

  Widget _buildDurationChip(String label, String duration) {
    final selected = widget.controller.filterDuration == duration;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => _onDurationChanged(duration),
        ),
      ),
    );
  }

  Widget _buildClearButton(AppLocalizations t) {
    return Tooltip(
      message: t.clearFilters,
      child: Semantics(
        button: true,
        label: t.clearFilters,
        child: TextButton(
          onPressed: () => _onClearFilters(),
          child: Text(t.clearFilters),
        ),
      ),
    );
  }

  void _onTagToggled(String tag) {
    widget.controller.toggleTag(tag);
    widget.onFilterChanged?.call();
  }

  void _onBudgetChanged(String budget) {
    final newBudget = widget.controller.filterBudget == budget ? null : budget;
    widget.controller.setFilterBudget(newBudget);
    widget.onFilterChanged?.call();
  }

  void _onDurationChanged(String duration) {
    final newDuration = widget.controller.filterDuration == duration
        ? null
        : duration;
    widget.controller.setFilterDuration(newDuration);
    widget.onFilterChanged?.call();
  }

  void _onClearFilters() {
    widget.controller.clearFilters(useRemote: widget.useRemote);
    widget.onFilterChanged?.call();
  }
}

/// Optimized ideas list with pagination support
class OptimizedIdeasList extends StatefulWidget {
  const OptimizedIdeasList({
    super.key,
    required this.controller,
    required this.useRemote,
  });

  final ExploreController controller;
  final bool useRemote;

  @override
  State<OptimizedIdeasList> createState() => _OptimizedIdeasListState();
}

class _OptimizedIdeasListState extends State<OptimizedIdeasList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load next page when near bottom
      widget.controller.loadNextPage(useRemote: widget.useRemote);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;

        if (widget.controller.isLoading && widget.controller.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (widget.controller.isEmpty && !widget.controller.isLoading) {
          return _buildEmptyState(t);
        }

        if (widget.controller.error != null && widget.controller.isEmpty) {
          return _buildErrorState(t);
        }

        return _buildIdeasLayout(context, widget.controller.currentResults, t);
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          Gaps.h16,
          Text(
            'No ideas found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Gaps.h8,
          Text(
            'Try different filters or search terms',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          Gaps.h16,
          Text(
            widget.controller.error!,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          Gaps.h16,
          FilledButton(
            onPressed: () =>
                widget.controller.refresh(useRemote: widget.useRemote),
            child: Text(t.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeasLayout(
    BuildContext context,
    List<TravelIdea> ideas,
    AppLocalizations t,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width <= Breakpoints.tablet) {
          return _buildListView(ideas, t);
        } else {
          return _buildGridView(ideas, t, width);
        }
      },
    );
  }

  Widget _buildListView(List<TravelIdea> ideas, AppLocalizations t) {
    return ListView.separated(
      controller: _scrollController,
      itemCount: ideas.length + (widget.controller.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index >= ideas.length) {
          return _buildLoadingIndicator();
        }
        return _OptimizedIdeaCard(
          key: ValueKey(ideas[index].id),
          idea: ideas[index],
          controller: widget.controller,
        );
      },
    );
  }

  Widget _buildGridView(
    List<TravelIdea> ideas,
    AppLocalizations t,
    double width,
  ) {
    int columns;
    if (width >= 1400) {
      columns = 4;
    } else if (width >= 1200) {
      columns = 3;
    } else {
      columns = 2;
    }

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: ideas.length + (widget.controller.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= ideas.length) {
          return _buildLoadingIndicator();
        }
        return _OptimizedIdeaCard(
          key: ValueKey(ideas[index].id),
          idea: ideas[index],
          controller: widget.controller,
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    if (widget.controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return const SizedBox.shrink();
    }
  }
}

/// Optimized idea card with minimal rebuilds
class _OptimizedIdeaCard extends StatefulWidget {
  const _OptimizedIdeaCard({
    super.key,
    required this.idea,
    required this.controller,
  });

  final TravelIdea idea;
  final ExploreController controller;

  @override
  State<_OptimizedIdeaCard> createState() => _OptimizedIdeaCardState();
}

class _OptimizedIdeaCardState extends State<_OptimizedIdeaCard> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.controller.isSaved(widget.idea.id);
  }

  void _toggleSaved() {
    setState(() {
      _isSaved = !_isSaved;
    });
    widget.controller.toggleSaved(widget.idea.id);

    final t = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? t.savedToYourIdeas : t.removedFromYourIdeas),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _accentColorForIdea(scheme);
    final tags = widget.idea.tags.take(3).toList(growable: false);

    return Semantics(
      label: t.ideaLabel(widget.idea.title),
      button: true,
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: InkWell(
          onTap: _navigateToPlanning,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.18),
                      accent.withValues(alpha: 0.55),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      left: 16,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(_iconForIdea(), color: accent, size: 26),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Semantics(
                        label: _isSaved ? t.unsaveIdea : t.saveIdea,
                        button: true,
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: scheme.surface.withValues(
                              alpha: 0.7,
                            ),
                            foregroundColor: accent,
                          ),
                          tooltip: _isSaved ? t.unsave : t.save,
                          icon: Icon(
                            _isSaved
                                ? Icons.bookmark_added
                                : Icons.bookmark_add,
                          ),
                          onPressed: _toggleSaved,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final tag in tags)
                            Chip(
                              label: Text(tag),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              visualDensity: VisualDensity.compact,
                              labelStyle: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: scheme.secondaryContainer,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.idea.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.idea.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    _buildInfoPill(
                      context,
                      icon: Icons.timelapse,
                      label: '${widget.idea.durationDays}-day plan',
                    ),
                    const SizedBox(width: 8),
                    _buildInfoPill(
                      context,
                      icon: Icons.account_balance_wallet,
                      label: _budgetLabel(widget.idea.budget),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      hint: 'Open idea and prefill Plan Trip',
                      child: FilledButton.tonal(
                        onPressed: _navigateToPlanning,
                        child: Text(t.open),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPlanning() {
    context.pushNamed(
      'plan',
      extra: PlanTripArgs(
        ideaId: widget.idea.id,
        title: widget.idea.title,
        tags: widget.idea.tags,
      ),
    );
  }

  Color _accentColorForIdea(ColorScheme scheme) {
    final tags = widget.idea.tags.map((e) => e.toLowerCase()).toSet();
    if (tags.contains('adventure') || tags.contains('trek')) {
      return scheme.primary;
    }
    if (tags.contains('relax') || tags.contains('wellness')) {
      return scheme.tertiary;
    }
    if (tags.contains('heritage') || tags.contains('culture')) {
      return scheme.secondary;
    }
    if (tags.contains('beach')) {
      return scheme.primaryContainer;
    }
    return scheme.secondaryContainer;
  }

  IconData _iconForIdea() {
    final tags = widget.idea.tags.map((e) => e.toLowerCase()).toSet();
    if (tags.contains('adventure')) return Icons.hiking;
    if (tags.contains('relax')) return Icons.spa;
    if (tags.contains('heritage')) return Icons.account_balance;
    if (tags.contains('beach')) return Icons.beach_access;
    if (tags.contains('mountains')) return Icons.terrain;
    return Icons.explore;
  }

  Widget _buildInfoPill(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _budgetLabel(String budget) {
    switch (budget) {
      case 'low':
        return 'Budget friendly';
      case 'medium':
        return 'Balanced spend';
      case 'high':
        return 'Premium stay';
      default:
        return 'Flexible';
    }
  }
}
