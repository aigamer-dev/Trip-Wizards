import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/models/trip.dart';
import 'package:travel_wizards/src/services/trips_repository.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Padding(
          padding: Insets.allMd,
          child: Text('Sign in to view your trip history.'),
        ),
      );
    }
    return StreamBuilder<List<Trip>>(
      stream: TripsRepository.instance.watchTrips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final trips = snapshot.data ?? const <Trip>[];
        if (trips.isEmpty) {
          return const Center(
            child: Padding(
              padding: Insets.allMd,
              child: Text('No trips yet. Plan a trip to get started!'),
            ),
          );
        }
        return ListView.separated(
          padding: Insets.allMd,
          itemCount: trips.length,
          separatorBuilder: (_, __) => Gaps.h8,
          itemBuilder: (context, index) {
            final t = trips[index];
            return Dismissible(
              key: ValueKey(t.id),
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
              secondaryBackground: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
              confirmDismiss: (dir) async {
                return await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete trip?'),
                        content: Text(
                          'This will remove "${t.title}" and its local data.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
              },
              onDismissed: (_) async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                await TripsRepository.instance.deleteTrip(t.id);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Deleted ${t.title}')),
                );
              },
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                title: Text(t.title),
                subtitle: Text(
                  '${t.startDate.toLocal().toString().split(' ').first} → ${t.endDate.toLocal().toString().split(' ').first}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.pushNamed(
                  'trip_details',
                  pathParameters: {'id': t.id},
                ),
              ),
            );
          },
        );
      },
    );
  }
}
