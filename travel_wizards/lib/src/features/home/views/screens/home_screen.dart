import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:travel_wizards/src/shared/widgets/async_builder.dart';
import 'package:travel_wizards/src/core/l10n/app_localizations.dart';
import 'package:travel_wizards/src/shared/models/trip.dart';
import 'package:travel_wizards/src/shared/widgets/calendar_event_badge.dart';
import 'package:travel_wizards/src/shared/services/home_data_service.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _localeName;
  late DateFormat _monthDayFormatter;
  Set<_HomeFocusSegment> _focusSelection = {_HomeFocusSegment.upcoming};
  final Set<String> _activeRecommendationTags = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    _localeName = locale.toLanguageTag();
    _monthDayFormatter = DateFormat('MMM d', _localeName);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 720;
    final isWide = mediaQuery.size.width >= 1180;

    return AsyncBuilder<TripCategorization>(
      future: () => HomeDataService.instance.getTrips(),
      context: 'home_screen_trips',
      builder: (context, data) {
        final focusTrips = _resolveFocusTrips(data);
        final upcomingTrips = _collectUpcomingTrips(data);
        final recommendationSource = data.suggestedTrips.isNotEmpty
            ? data.suggestedTrips
            : [...data.completedTrips, ...data.plannedTrips];
        final recommendations = _filterRecommendations(recommendationSource);
        final tags = _collectRecommendationTags(recommendationSource);

        final hero = data.hasAnyTrips
            ? _buildHero(context, t, data, focusTrips, upcomingTrips)
            : _buildEmptyHero(context, t);

        return ModernPageScaffold(
          showBackButton: false,
          hero: hero,
          sidePanel: isWide
              ? _HomeSidePanel(
                  categorization: data,
                  formatter: _monthDayFormatter,
                )
              : null,
          sections: [
            ModernSection(
              title: 'Stay in flow',
              subtitle:
                  'Jump back into planning, brainstorming, or coordination.',
              icon: Icons.bolt_rounded,
              child: _buildQuickActions(context, isCompact),
            ),
            ModernSection(
              title: 'Up next',
              subtitle: 'Keep an eye on your upcoming adventures.',
              icon: Icons.calendar_month_rounded,
              highlights: true,
              actions: [
                if (upcomingTrips.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: () => context.goNamed('bookings'),
                    icon: const Icon(Icons.playlist_add_check_rounded),
                    label: const Text('Manage bookings'),
                  ),
              ],
              child: _buildUpcomingTray(context, upcomingTrips, isCompact),
            ),
            ModernSection(
              title: 'Suggested for you',
              subtitle:
                  'Curated recommendations based on your vibe and history.',
              icon: Icons.auto_awesome_rounded,
              tags: tags,
              selectedTags: _activeRecommendationTags,
              onTagSelected: _handleTagSelection,
              badgeLabel: _activeRecommendationTags.isEmpty
                  ? null
                  : '${_activeRecommendationTags.length} filters applied',
              actions: [
                if (_activeRecommendationTags.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _activeRecommendationTags.clear();
                      });
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
              child: _buildRecommendedGrid(context, recommendations, isCompact),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHero(
    BuildContext context,
    AppLocalizations t,
    TripCategorization data,
    List<Trip> focusTrips,
    List<Trip> upcoming,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final focus = _focusSelection.first;

    final heroPool = focusTrips.isNotEmpty ? focusTrips : upcoming;
    final spotlight = _selectSpotlightTrip(heroPool, data);

    final hasSpotlight = spotlight != null;
    final title = spotlight?.title ?? _focusTitle(focus);
    final subtitle = spotlight != null
        ? _formatDateRange(spotlight.startDate, spotlight.endDate)
        : _focusSubtitle(focus);
    final destination = spotlight != null && spotlight.destinations.isNotEmpty
        ? spotlight.destinations.first
        : _focusDestinationFallback(focus);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: scheme.primaryContainer.withValues(alpha: 0.4),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primaryContainer,
                    scheme.primaryContainer.withValues(alpha: 0.85),
                    scheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 36),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 720;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<_HomeFocusSegment>(
                      segments: const [
                        ButtonSegment(
                          value: _HomeFocusSegment.upcoming,
                          icon: Icon(Icons.flight_takeoff_rounded),
                          label: Text('Upcoming'),
                        ),
                        ButtonSegment(
                          value: _HomeFocusSegment.planning,
                          icon: Icon(Icons.edit_calendar_rounded),
                          label: Text('Planning'),
                        ),
                        ButtonSegment(
                          value: _HomeFocusSegment.memories,
                          icon: Icon(Icons.auto_stories_rounded),
                          label: Text('Memories'),
                        ),
                      ],
                      selected: _focusSelection,
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.comfortable,
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? scheme.onPrimaryContainer.withValues(
                                  alpha: 0.12,
                                )
                              : scheme.onPrimaryContainer.withValues(
                                  alpha: 0.08,
                                ),
                        ),
                      ),
                      onSelectionChanged: (value) {
                        setState(() {
                          _focusSelection = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildFocusBadge(
                      context,
                      focus: focus,
                      hasSpotlight: hasSpotlight,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (destination != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        destination,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(
                            alpha: 0.82,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.76,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.onPrimaryContainer,
                            foregroundColor: scheme.primaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 16,
                            ),
                          ),
                          onPressed: hasSpotlight
                              ? () {
                                  final trip = spotlight;
                                  context.push('/trips/${trip.id}');
                                }
                              : () => context.pushNamed('plan'),
                          icon: Icon(
                            hasSpotlight
                                ? Icons.arrow_outward_rounded
                                : Icons.auto_awesome_rounded,
                          ),
                          label: Text(
                            hasSpotlight
                                ? 'Open trip board'
                                : 'Plan a new trip',
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.onPrimaryContainer,
                            side: BorderSide(
                              color: scheme.onPrimaryContainer.withValues(
                                alpha: 0.32,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onPressed: () => context.goNamed('explore'),
                          icon: const Icon(Icons.explore_rounded),
                          label: const Text('Explore ideas'),
                        ),
                        if (!isNarrow)
                          TextButton.icon(
                            onPressed: () => context.goNamed('brainstorm'),
                            icon: const Icon(Icons.auto_fix_high_rounded),
                            label: const Text('Spark brainstorm'),
                          ),
                      ],
                    ),
                    if (spotlight != null && spotlight.destinations.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(Icons.place_rounded, size: 18),
                            Text(
                              spotlight.destinations.join('  •  '),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onPrimaryContainer.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusBadge(
    BuildContext context, {
    required _HomeFocusSegment focus,
    required bool hasSpotlight,
  }) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = hasSpotlight ? 'Trip spotlight' : _focusChipLabel(focus);
    final icon = hasSpotlight
        ? Icons.auto_awesome_rounded
        : _focusIconForSegment(focus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.onPrimaryContainer.withValues(
          alpha: hasSpotlight ? 0.18 : 0.12,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  IconData _focusIconForSegment(_HomeFocusSegment focus) {
    switch (focus) {
      case _HomeFocusSegment.upcoming:
        return Icons.flight_takeoff_rounded;
      case _HomeFocusSegment.planning:
        return Icons.edit_calendar_rounded;
      case _HomeFocusSegment.memories:
        return Icons.auto_stories_rounded;
    }
  }

  Widget _buildEmptyHero(BuildContext context, AppLocalizations t) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: scheme.primaryContainer.withValues(alpha: 0.4),
      child: Container(
        padding: const EdgeInsets.all(48.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.3),
              scheme.secondaryContainer.withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              t.welcomeToTravelWizards,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Spin up your first adventure with AI-powered planning or browse curated inspiration.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => context.pushNamed('plan'),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Start planning your next trip'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    textStyle: theme.textTheme.titleSmall,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.goNamed('explore'),
                  icon: const Icon(Icons.lightbulb_rounded),
                  label: const Text('Discover new ideas'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    textStyle: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleTagSelection(String tag, bool selected) {
    setState(() {
      final normalized = tag.toLowerCase();
      if (selected) {
        _activeRecommendationTags.add(normalized);
      } else {
        _activeRecommendationTags.remove(normalized);
      }
    });
  }

  List<Trip> _resolveFocusTrips(TripCategorization data) {
    final focus = _focusSelection.first;
    switch (focus) {
      case _HomeFocusSegment.upcoming:
        return _collectUpcomingTrips(data);
      case _HomeFocusSegment.planning:
        return [...data.plannedTrips]
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
      case _HomeFocusSegment.memories:
        return [...data.completedTrips]
          ..sort((a, b) => b.endDate.compareTo(a.endDate));
    }
  }

  List<Trip> _collectUpcomingTrips(TripCategorization data) {
    final upcoming = <Trip>[...data.ongoingTrips, ...data.plannedTrips];
    upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
    return upcoming;
  }

  Trip? _selectSpotlightTrip(List<Trip> candidates, TripCategorization data) {
    // Filter out unmarked calendar trips from candidates
    final filtered = candidates
        .where((t) => t.source != 'calendar')
        .toList();
    
    if (filtered.isEmpty) {
      final historical = [...data.completedTrips, ...data.plannedTrips]
          .where((t) => t.source != 'calendar')
          .toList();
      if (historical.isEmpty) return null;
      historical.sort((a, b) => b.endDate.compareTo(a.endDate));
      return historical.first;
    }
    return filtered.first;
  }

  List<Trip> _filterRecommendations(List<Trip> candidates) {
    if (_activeRecommendationTags.isEmpty || candidates.isEmpty) {
      return candidates;
    }

    return candidates.where((trip) {
      final tags = _deriveTagsForTrip(
        trip,
      ).map((tag) => tag.toLowerCase()).toSet();
      return _activeRecommendationTags.every(tags.contains);
    }).toList();
  }

  List<String> _collectRecommendationTags(List<Trip> trips) {
    if (trips.isEmpty) return const [];

    final mapped = <String, String>{};
    for (final trip in trips) {
      for (final tag in _deriveTagsForTrip(trip)) {
        mapped.putIfAbsent(tag.toLowerCase(), () => tag);
      }
    }
    final tags = mapped.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return tags;
  }

  Set<String> _deriveTagsForTrip(Trip trip) {
    final tags = <String>{};
    final duration = trip.endDate.difference(trip.startDate).inDays + 1;
    if (duration <= 3) tags.add('Weekend');
    if (duration >= 7) tags.add('Extended');

    final titleLower = trip.title.toLowerCase();
    if (titleLower.contains('romantic')) tags.add('Romantic');
    if (titleLower.contains('family')) tags.add('Family');
    if (titleLower.contains('solo')) tags.add('Solo');
    if (titleLower.contains('adventure') || titleLower.contains('trek')) {
      tags.add('Adventure');
    }
    if (titleLower.contains('food')) tags.add('Foodie');

    final destinationLowers = trip.destinations
        .map((d) => d.toLowerCase())
        .toList(growable: false);
    if (destinationLowers.any(
      (d) => d.contains('beach') || d.contains('island'),
    )) {
      tags.add('Beach');
    }
    if (destinationLowers.any((d) => d.contains('mount'))) {
      tags.add('Mountains');
    }
    if (destinationLowers.any((d) => d.contains('city'))) {
      tags.add('City');
    }

    if (trip.destinations.isNotEmpty) {
      tags.add(_titleCase(trip.destinations.first));
    }

    return tags;
  }

  String? _focusDestinationFallback(_HomeFocusSegment focus) {
    return switch (focus) {
      _HomeFocusSegment.upcoming => 'Next on your itinerary',
      _HomeFocusSegment.planning => 'Planning in progress',
      _HomeFocusSegment.memories => 'Recent memories',
    };
  }

  String _focusTitle(_HomeFocusSegment focus) {
    return switch (focus) {
      _HomeFocusSegment.upcoming => 'Your next adventure awaits',
      _HomeFocusSegment.planning => 'Plan with confidence',
      _HomeFocusSegment.memories => 'Relive your favourite journeys',
    };
  }

  String _focusSubtitle(_HomeFocusSegment focus) {
    return switch (focus) {
      _HomeFocusSegment.upcoming =>
        'Review details and make sure everything is ready to go.',
      _HomeFocusSegment.planning =>
        'Triage tasks, assign buddies, and polish the itinerary.',
      _HomeFocusSegment.memories =>
        'Look back at highlights and gather inspiration.',
    };
  }

  String _focusChipLabel(_HomeFocusSegment focus) {
    return switch (focus) {
      _HomeFocusSegment.upcoming => 'Staying trip-ready',
      _HomeFocusSegment.planning => 'Fine-tuning plans',
      _HomeFocusSegment.memories => 'Remembering moments',
    };
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Widget _buildUpcomingTray(
    BuildContext context,
    List<Trip> trips,
    bool isMobile,
  ) {
    if (trips.isEmpty) {
      return _buildPlaceholder(
        context,
        icon: Icons.event_busy_rounded,
        title: 'No upcoming trips',
        message: 'Start a plan to see it appear here.',
      );
    }

    final itemWidth = isMobile ? 320.0 : 280.0;
    final visibleTrips = trips.take(8).toList(growable: false);

    return SizedBox(
      height: isMobile ? 270 : 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleTrips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final trip = visibleTrips[index];
          return SizedBox(
            width: itemWidth,
            child: _TripSpotlightCard(
              trip: trip,
              dateLabel: _formatDateRange(trip.startDate, trip.endDate),
              onTap: () => context.push('/trips/${trip.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isMobile) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.add_location_alt_rounded,
        label: 'Plan trip',
        description: 'Use AI to assemble a complete itinerary.',
        onTap: () => context.pushNamed('plan'),
      ),
      _QuickAction(
        icon: Icons.auto_awesome_rounded,
        label: 'Brainstorm',
        description: 'Spark new getaway ideas instantly.',
        onTap: () => context.goNamed('brainstorm'),
      ),
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'Manage bookings',
        description: 'Keep flights, stays, and activities aligned.',
        onTap: () => context.goNamed('bookings_shell'),
      ),
      _QuickAction(
        icon: Icons.people_alt_rounded,
        label: 'Travel buddies',
        description: 'Coordinate plans and shared expenses.',
        onTap: () => context.goNamed('travel_buddies'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 600 ? 2 : 1;
        final childAspectRatio = constraints.maxWidth >= 600 ? 4.0 : 4.2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _QuickActionCard(action: actions[index]);
          },
        );
      },
    );
  }

  Widget _buildRecommendedGrid(
    BuildContext context,
    List<Trip> trips,
    bool isMobile,
  ) {
    if (trips.isEmpty) {
      return _buildPlaceholder(
        context,
        icon: Icons.auto_awesome_outlined,
        title: 'We\'re learning your vibe',
        message: 'As you plan and explore, fresh suggestions will appear here.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1040
            ? 3
            : constraints.maxWidth >= 680
            ? 2
            : 1;
        final gutter = 16 * (crossAxisCount - 1);
        final tileWidth = (constraints.maxWidth - gutter) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final trip in trips.take(6))
              SizedBox(
                width: tileWidth,
                child: _TripRecommendationCard(
                  trip: trip,
                  dateLabel: _formatDateRange(trip.startDate, trip.endDate),
                  onTap: () => context.push('/trips/${trip.id}'),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startLabel = _monthDayFormatter.format(start);
    final sameMonth = start.month == end.month && start.year == end.year;
    final endFormatter = sameMonth
        ? DateFormat('d', _localeName)
        : _monthDayFormatter;
    final endLabel = endFormatter.format(end);
    return '$startLabel – $endLabel';
  }
}

class _HomeSidePanel extends StatelessWidget {
  const _HomeSidePanel({required this.categorization, required this.formatter});

  final TripCategorization categorization;
  final DateFormat formatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final metrics = [
      _HomeMetric(
        icon: Icons.flight_takeoff_rounded,
        label: 'Active trips',
        value: categorization.ongoingTrips.length.toString(),
      ),
      _HomeMetric(
        icon: Icons.event_available_rounded,
        label: 'Planned trips',
        value: categorization.plannedTrips.length.toString(),
      ),
      _HomeMetric(
        icon: Icons.auto_awesome_rounded,
        label: 'Suggestions',
        value: categorization.suggestedTrips.length.toString(),
      ),
      _HomeMetric(
        icon: Icons.flag_rounded,
        label: 'Completed',
        value: categorization.completedTrips.length.toString(),
      ),
    ];

    final upcoming = <Trip>[
      ...categorization.ongoingTrips,
      ...categorization.plannedTrips,
    ]..sort((a, b) => a.startDate.compareTo(b.startDate));

    return Column(
      children: [
        Card.filled(
          color: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip health',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    for (final metric in metrics) _MetricTile(metric: metric),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card.filled(
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next check-ins',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (upcoming.isEmpty)
                  Text(
                    'Add a trip to see reminders here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final trip in upcoming.take(3))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ProfileAvatar(
                            size: 40,
                            backgroundColor: scheme.primaryContainer.withValues(
                              alpha: 0.4,
                            ),
                            icon: Icons.location_on_rounded,
                          ),
                          title: Text(trip.title),
                          subtitle: Text(
                            trip.destinations.isNotEmpty
                                ? trip.destinations.join(', ')
                                : 'No destinations',
                          ),
                          trailing: Text(
                            formatter.format(trip.startDate),
                            style: theme.textTheme.labelLarge,
                          ),
                          onTap: () => context.push('/trips/${trip.id}'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ), // Reduced padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced padding
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12), // Smaller radius
                ),
                child: Icon(
                  action.icon,
                  color: scheme.onPrimaryContainer,
                  size: 20, // Smaller icon
                ),
              ),
              const SizedBox(width: 12), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  mainAxisSize: MainAxisSize.min, // Use minimum space
                  children: [
                    Text(
                      action.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12, // Smaller font size
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24), // Reduced spacing
                    Text(
                      action.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9, // Smaller font size
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8), // Reduced spacing
              Icon(
                Icons.arrow_forward_rounded,
                color: scheme.onSurfaceVariant,
                size: 16, // Smaller icon
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripSpotlightCard extends StatelessWidget {
  const _TripSpotlightCard({
    required this.trip,
    required this.dateLabel,
    required this.onTap,
  });

  final Trip trip;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final destination = trip.destinations.isNotEmpty
        ? trip.destinations.join(', ')
        : 'TBD destination';

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                label: Text(
                  _statusLabel(trip),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: scheme.primaryContainer.withValues(
                  alpha: 0.35,
                ),
                side: BorderSide.none,
              ),
              const SizedBox(height: 12),
              Text(
                trip.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(dateLabel, style: theme.textTheme.labelLarge),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(Trip trip) {
    final now = DateTime.now();
    if (trip.endDate.isBefore(now)) return 'Completed';
    if (trip.startDate.isAfter(now)) return 'Coming up';
    return 'In progress';
  }
}

class _TripRecommendationCard extends StatelessWidget {
  const _TripRecommendationCard({
    required this.trip,
    required this.dateLabel,
    required this.onTap,
  });

  final Trip trip;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final destination = trip.destinations.isNotEmpty
        ? trip.destinations.join(', ')
        : 'Discover new spots';

    return Card.filled(
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.light_mode_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      trip.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (trip.source == 'calendar')
                ...[
                  const CalendarEventBadge(
                    fontSize: 12.0,
                  ),
                  const SizedBox(height: 8),
                ],
              Text(
                destination,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(dateLabel, style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                label: const Text('Open trip board'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMetric {
  const _HomeMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _HomeMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(metric.icon, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(metric.label, style: theme.textTheme.bodyLarge)),
          Text(
            metric.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _HomeFocusSegment { upcoming, planning, memories }
