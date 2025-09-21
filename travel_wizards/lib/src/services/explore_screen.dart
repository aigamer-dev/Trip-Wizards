import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/app/settings_controller.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/config/env.dart';
import 'package:travel_wizards/src/data/explore_store.dart';
import 'package:travel_wizards/src/data/ideas_remote_repository.dart';
import 'package:travel_wizards/src/data/ideas_repository.dart';
import 'package:travel_wizards/src/l10n/app_localizations.dart';
import 'package:travel_wizards/src/screens/trip/plan_trip_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ExploreStore _store = ExploreStore.instance;
  final IdeasRepository _repo = IdeasRepository.instance;
  final IdeasRemoteRepository _remote = IdeasRemoteRepository.instance;
  Future<List<TravelIdea>>? _future;
  String? _lastQuery;

  @override
  void initState() {
    super.initState();
    // Load persisted explore state once and rebuild when done.
    _store.load().then((_) => mounted ? setState(() {}) : null);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final uri = GoRouterState.of(context).uri;
    final q = uri.queryParameters['q'];
    final useRemote =
        kUseRemoteIdeas && AppSettings.instance.remoteIdeasEnabled;
    if (useRemote) {
      // If query changed, refresh.
      if (_lastQuery != q) {
        _lastQuery = q;
        _future = _loadIdeas(q);
      }
    }
    _future ??= _loadIdeas(q);
    return Scaffold(
      appBar: AppBar(title: Text(t.explore)),
      body: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (q != null && q.isNotEmpty)
              Text(
                '${t.resultsFor}: "$q"',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            if (q != null && q.isNotEmpty) Gaps.h16,
            // Compact filters row
            Semantics(
              container: true,
              header: true,
              label: t.filters,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Tag filters
                  Tooltip(
                    message: t.tagWeekend,
                    child: Semantics(
                      button: true,
                      selected: _store.selectedTags.contains('Weekend'),
                      label: t.tagWeekend,
                      child: FilterChip(
                        label: Text(t.tagWeekend),
                        selected: _store.selectedTags.contains('Weekend'),
                        onSelected: (_) => setState(() {
                          _store.toggleTag('Weekend');
                          if (useRemote) _future = _loadIdeas(q);
                        }),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: t.tagAdventure,
                    child: Semantics(
                      button: true,
                      selected: _store.selectedTags.contains('Adventure'),
                      label: t.tagAdventure,
                      child: FilterChip(
                        label: Text(t.tagAdventure),
                        selected: _store.selectedTags.contains('Adventure'),
                        onSelected: (_) => setState(() {
                          _store.toggleTag('Adventure');
                          if (useRemote) _future = _loadIdeas(q);
                        }),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: t.tagBudget,
                    child: Semantics(
                      button: true,
                      selected: _store.selectedTags.contains('Budget'),
                      label: t.tagBudget,
                      child: FilterChip(
                        label: Text(t.tagBudget),
                        selected: _store.selectedTags.contains('Budget'),
                        onSelected: (_) => setState(() {
                          _store.toggleTag('Budget');
                          if (useRemote) _future = _loadIdeas(q);
                        }),
                      ),
                    ),
                  ),
                  // Budget filter (exclusive)
                  Tooltip(
                    message: t.budgetLow,
                    child: Semantics(
                      button: true,
                      selected: _store.filterBudget == 'low',
                      label: t.budgetLow,
                      child: ChoiceChip(
                        label: Text(t.budgetLow),
                        selected: _store.filterBudget == 'low',
                        onSelected: (_) => setState(() {
                          _store.setFilterBudget(
                            _store.filterBudget == 'low' ? null : 'low',
                          );
                          if (useRemote) _future = _loadIdeas(q);
                        }),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: t.budgetMedium,
                    child: Semantics(
                      button: true,
                      selected: _store.filterBudget == 'medium',
                      label: t.budgetMedium,
                      child: ChoiceChip(
                        label: Text(t.budgetMedium),
                        selected: _store.filterBudget == 'medium',
                        onSelected: (_) => setState(() {
                          _store.setFilterBudget(
                            _store.filterBudget == 'medium' ? null : 'medium',
                          );
                          if (useRemote) _future = _loadIdeas(q);
                        }),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: t.budgetHigh,
                    child: Semantics(
                      button: true,
                      selected: _store.filterBudget == 'high',
                      label: t.budgetHigh,
                      child: ChoiceChip(
                        label: Text(t.budgetHigh),
                        selected: _store.filterBudget == 'high',
                        onSelected: (_) => setState(() {
                          _store.setFilterBudget(
                            _store.filterBudget == 'high' ? null : 'high',
                          );
                          if (useRemote) _future = _loadIdeas(q);
                        }),
                      ),
                    ),
                  ),
                  // Duration filter (exclusive)
                  Tooltip(
                    message: t.duration2to3,
                    child: Semantics(
                      button: true,
                      selected: _store.filterDuration == '2-3',
                      label: t.duration2to3,
                      child: ChoiceChip(
                        label: Text(t.duration2to3),
                        selected: _store.filterDuration == '2-3',
                        onSelected: (_) => setState(() {
                          _store.setFilterDuration(
                            _store.filterDuration == '2-3' ? null : '2-3',
                          );
                          if (useRemote) _future = _loadIdeas(q);
                        }),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: t.duration4to5,
                    child: Semantics(
                      button: true,
                      selected: _store.filterDuration == '4-5',
                      label: t.duration4to5,
                      child: ChoiceChip(
                        label: Text(t.duration4to5),
                        selected: _store.filterDuration == '4-5',
                        onSelected: (_) => setState(() {
                          _store.setFilterDuration(
                            _store.filterDuration == '4-5' ? null : '4-5',
                          );
                          if (kUseRemoteIdeas) _future = _loadIdeas(q);
                        }),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: t.duration6plus,
                    child: Semantics(
                      button: true,
                      selected: _store.filterDuration == '6+',
                      label: t.duration6plus,
                      child: ChoiceChip(
                        label: Text(t.duration6plus),
                        selected: _store.filterDuration == '6+',
                        onSelected: (_) => setState(() {
                          _store.setFilterDuration(
                            _store.filterDuration == '6+' ? null : '6+',
                          );
                          if (kUseRemoteIdeas) _future = _loadIdeas(q);
                        }),
                      ),
                    ),
                  ),
                  // Clear Filters action
                  Tooltip(
                    message: t.clearFilters,
                    child: Semantics(
                      button: true,
                      label: t.clearFilters,
                      child: TextButton(
                        onPressed: () => setState(() {
                          // Reset all filters
                          _store.setTags({});
                          _store.setFilterBudget(null);
                          _store.setFilterDuration(null);
                          if (kUseRemoteIdeas) _future = _loadIdeas(q);
                        }),
                        child: Text(t.clearFilters),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Gaps.h8,
            Expanded(
              child: useRemote
                  ? FutureBuilder<List<TravelIdea>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        List<TravelIdea> ideas;
                        if (snapshot.hasError) {
                          // Notify user that we're falling back to local ideas.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(t.ideasFallbackToLocal),
                                action: SnackBarAction(
                                  label: t.retry,
                                  onPressed: () {
                                    setState(() {
                                      _future = _loadIdeas(q);
                                    });
                                  },
                                ),
                              ),
                            );
                          });
                          // Fallback to local repository if remote fails.
                          ideas = _repo.search(
                            query: q,
                            tags: _store.selectedTags,
                            budget: _store.filterBudget,
                            durationBucket: _store.filterDuration,
                          );
                        } else {
                          ideas = snapshot.data ?? const <TravelIdea>[];
                        }
                        return _buildIdeasLayout(context, ideas, t);
                      },
                    )
                  : _buildIdeasLayout(
                      context,
                      _repo.search(
                        query: q,
                        tags: _store.selectedTags,
                        budget: _store.filterBudget,
                        durationBucket: _store.filterDuration,
                      ),
                      t,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<TravelIdea>> _loadIdeas(String? q) async {
    final useRemote =
        kUseRemoteIdeas && AppSettings.instance.remoteIdeasEnabled;
    if (useRemote) {
      try {
        return await _remote.search(
          query: q,
          tags: _store.selectedTags,
          budget: _store.filterBudget,
          durationBucket: _store.filterDuration,
        );
      } catch (_) {
        // Let FutureBuilder handle the error by returning an error state.
        rethrow;
      }
    }
    // Local repository (default)
    return _repo.search(
      query: q,
      tags: _store.selectedTags,
      budget: _store.filterBudget,
      durationBucket: _store.filterDuration,
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

        Widget buildIdeaCard(int index) {
          final item = ideas[index];
          final saved = _store.isSaved(item.id);
          return Semantics(
            label: t.ideaLabel(item.title),
            button: true,
            child: Card(
              child: ListTile(
                leading: Icon(Icons.explore_outlined),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                onTap: () => context.pushNamed(
                  'plan',
                  extra: PlanTripArgs(
                    ideaId: item.id,
                    title: item.title,
                    tags: item.tags,
                  ),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    Semantics(
                      button: true,
                      label: t.open,
                      hint: 'Open idea and prefill Plan Trip',
                      child: FilledButton.tonal(
                        onPressed: () => context.pushNamed(
                          'plan',
                          extra: PlanTripArgs(
                            ideaId: item.id,
                            title: item.title,
                            tags: item.tags,
                          ),
                        ),
                        child: Text(t.open),
                      ),
                    ),
                    Semantics(
                      label: saved ? t.unsaveIdea : t.saveIdea,
                      hint: saved ? 'Remove idea from saved' : 'Save idea',
                      button: true,
                      child: IconButton(
                        tooltip: saved ? t.unsave : t.save,
                        icon: Icon(
                          saved
                              ? Icons.bookmark_added_rounded
                              : Icons.bookmark_add_rounded,
                        ),
                        onPressed: () {
                          setState(() {
                            _store.toggleSaved(item.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                saved
                                    ? t.removedFromYourIdeas
                                    : t.savedToYourIdeas,
                              ),
                              duration: const Duration(milliseconds: 1200),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Keep list on mobile/tablet; grid on wide web/desktop
        if (width <= Breakpoints.tablet) {
          return ListView.separated(
            itemCount: ideas.length,
            separatorBuilder: (_, __) => Gaps.h8,
            itemBuilder: (context, index) => buildIdeaCard(index),
          );
        }

        // Desktop/web: grid with adaptive columns
        int columns;
        if (width >= 1400) {
          columns = 4;
        } else if (width >= 1200) {
          columns = 3;
        } else {
          columns = 2; // just above tablet
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 16 / 5,
          ),
          itemCount: ideas.length,
          itemBuilder: (context, index) => buildIdeaCard(index),
        );
      },
    );
  }
}
