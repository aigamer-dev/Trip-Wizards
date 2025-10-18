import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/models/trip.dart';
import 'package:travel_wizards/src/shared/services/trips_repository.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ModernPageScaffold(
      pageTitle: 'Trip History',
      sections: [
        ModernSection(
          title: 'Your Past Adventures',
          child: user == null
              ? const _EmptyHistory(
                  icon: Symbols.login,
                  message: 'Sign in to view your trip history.',
                )
              : StreamBuilder<List<Trip>>(
                  stream: TripsRepository.instance.watchTrips(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _EmptyHistory(
                        icon: Symbols.error,
                        message: 'Error loading trips: ${snapshot.error}',
                      );
                    }
                    final trips = snapshot.data ?? [];
                    if (trips.isEmpty) {
                      return const _EmptyHistory(
                        icon: Symbols.luggage,
                        message:
                            'No past trips found.\nPlan a new adventure to get started!',
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return _TripHistoryCard(trip: trip);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  const _TripHistoryCard({required this.trip});

  final Trip trip;

  Future<bool> _confirmDismiss(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Trip?'),
            content: Text(
              'This will permanently remove "${trip.title}" and all its associated data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: ValueKey(trip.id),
      confirmDismiss: (_) => _confirmDismiss(context),
      onDismissed: (_) async {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        await TripsRepository.instance.deleteTrip(trip.id);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Deleted "${trip.title}"')),
        );
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: Icon(Symbols.delete, color: colorScheme.onErrorContainer),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Symbols.delete, color: colorScheme.onErrorContainer),
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.pushNamed(
            'trip_details',
            pathParameters: {'id': trip.id},
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Symbols.history, size: 40, color: colorScheme.secondary),
                const HGap(Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const VGap(Insets.xs),
                      Text(
                        '${trip.startDate.toLocal().toString().split(' ').first} → ${trip.endDate.toLocal().toString().split(' ').first}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const HGap(Insets.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.secondary.withAlpha((0.7 * 255).toInt()),
            ),
            const VGap(Insets.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
