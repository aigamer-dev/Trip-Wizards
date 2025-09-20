import 'package:flutter/material.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/common/widgets/async_builder.dart';
import 'package:travel_wizards/src/l10n/app_localizations.dart';
import 'package:travel_wizards/src/services/home_data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = Breakpoints.isMobile(width);
        final isDesktop = Breakpoints.isDesktop(width);
        final crossAxisCount = isMobile ? 1 : (isDesktop ? 2 : 2);
        final padding = isDesktop ? Insets.allXl : Insets.allMd;

        return AsyncBuilder<TripCategorization>(
          future: () => HomeDataService.instance.getTrips(),
          builder: (context, categorization) {
            return GridView.count(
              crossAxisCount: crossAxisCount,
              // Make tiles taller to avoid overflow in tests and small screens.
              childAspectRatio: isDesktop ? 1.8 : (isMobile ? 1.3 : 1.2),
              padding: padding,
              children: [
                _HomeCard(
                  title: t.generationInProgress,
                  count: 0, // TODO: Add generation progress tracking
                  subtitle: 'No generations in progress',
                ),
                _HomeCard(
                  title: t.ongoingTrips,
                  count: categorization.ongoingTrips.length,
                  subtitle: categorization.hasOngoingTrips
                      ? '${categorization.ongoingTrips.length} trip${categorization.ongoingTrips.length != 1 ? 's' : ''} in progress'
                      : 'No ongoing trips',
                ),
                _HomeCard(
                  title: t.plannedTrips,
                  count: categorization.plannedTrips.length,
                  subtitle: categorization.hasPlannedTrips
                      ? '${categorization.plannedTrips.length} trip${categorization.plannedTrips.length != 1 ? 's' : ''} planned'
                      : 'No planned trips yet',
                ),
                _HomeCard(
                  title: t.suggestedTrips,
                  count: categorization.suggestedTrips.length,
                  subtitle: categorization.hasSuggestedTrips
                      ? '${categorization.suggestedTrips.length} suggestion${categorization.suggestedTrips.length != 1 ? 's' : ''} available'
                      : 'No suggestions available',
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.title,
    required this.count,
    required this.subtitle,
  });

  final String title;
  final int count;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (count > 0) ...[
              Text(
                count.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
