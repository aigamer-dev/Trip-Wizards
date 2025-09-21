import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/common/widgets/async_builder.dart';
import 'package:travel_wizards/src/l10n/app_localizations.dart';
import 'package:travel_wizards/src/models/trip.dart';
import 'package:travel_wizards/src/services/home_data_service.dart';
import 'package:travel_wizards/src/widgets/travel_components/trip_card.dart';

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
        final crossAxisCount = isMobile ? 1 : (isDesktop ? 3 : 2);
        final padding = isDesktop ? Insets.allXl : Insets.allMd;

        return AsyncBuilder<TripCategorization>(
          future: () => HomeDataService.instance.getTrips(),
          builder: (context, categorization) {
            // Check if user has any trips
            final hasAnyTrips =
                categorization.ongoingTrips.isNotEmpty ||
                categorization.plannedTrips.isNotEmpty ||
                categorization.suggestedTrips.isNotEmpty ||
                categorization.completedTrips.isNotEmpty;

            if (!hasAnyTrips) {
              return _buildEmptyState(context, t);
            }

            // Collect all trips to display as cards
            final List<Trip> allTrips = [
              ...categorization.ongoingTrips,
              ...categorization.plannedTrips,
              ...categorization.suggestedTrips,
              ...categorization.completedTrips,
            ];

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: isMobile ? 0.8 : 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              padding: padding,
              itemCount: allTrips.length,
              itemBuilder: (context, index) {
                final trip = allTrips[index];
                return _buildTripCard(context, trip);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations t) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: Insets.allXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.luggage_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            Gaps.h16,
            Text(
              'No Trips planned yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Gaps.h8,
            Text(
              'Add trip to continue',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Gaps.h24,
            FilledButton.icon(
              onPressed: () => context.push('/plan-trip'),
              icon: const Icon(Icons.add),
              label: const Text('Plan New Trip'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    // Determine trip status based on dates
    final now = DateTime.now();
    final isOngoing = trip.startDate.isBefore(now) && trip.endDate.isAfter(now);
    final isPast = trip.endDate.isBefore(now);
    final status = isPast ? 'completed' : (isOngoing ? 'ongoing' : 'planned');

    return TripCard(
      title: trip.title,
      destination: trip.destinations.isNotEmpty
          ? trip.destinations.join(', ')
          : 'No destinations',
      startDate: trip.startDate,
      endDate: trip.endDate,
      status: status,
      description: trip.notes,
      onTap: () => context.push('/trips/${trip.id}'),
      showActions: false, // Don't show favorite button on home screen
    );
  }
}
