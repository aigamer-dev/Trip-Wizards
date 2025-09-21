import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/data/ideas_repository.dart';
import 'package:travel_wizards/src/controllers/explore_controller.dart';
import 'package:travel_wizards/src/l10n/app_localizations.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/screens/trip/plan_trip_screen.dart';

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
      separatorBuilder: (_, __) => Gaps.h8,
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
        childAspectRatio: 16 / 5,
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

    return Semantics(
      label: t.ideaLabel(widget.idea.title),
      button: true,
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.explore_outlined),
          title: Text(widget.idea.title),
          subtitle: Text(widget.idea.subtitle),
          onTap: () => _navigateToPlanning(),
          trailing: Wrap(
            spacing: 8,
            children: [
              Semantics(
                button: true,
                label: t.open,
                hint: 'Open idea and prefill Plan Trip',
                child: FilledButton.tonal(
                  onPressed: () => _navigateToPlanning(),
                  child: Text(t.open),
                ),
              ),
              Semantics(
                label: _isSaved ? t.unsaveIdea : t.saveIdea,
                hint: _isSaved ? 'Remove idea from saved' : 'Save idea',
                button: true,
                child: IconButton(
                  tooltip: _isSaved ? t.unsave : t.save,
                  icon: Icon(
                    _isSaved
                        ? Icons.bookmark_added_rounded
                        : Icons.bookmark_add_rounded,
                  ),
                  onPressed: _toggleSaved,
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
}
