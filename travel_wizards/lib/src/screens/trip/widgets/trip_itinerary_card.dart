import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';

/// A card widget that displays the trip itinerary.
///
/// Shows scheduled activities and events with their dates and locations.
/// Displays up to 10 recent itinerary items ordered by start time.
class TripItineraryCard extends StatelessWidget {
  const TripItineraryCard({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId)
        .collection('itinerary');

    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: col.orderBy('start', descending: false).limit(10).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState(context);
            }

            final docs = snapshot.data?.docs ?? const [];
            if (docs.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildItineraryList(context, docs);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Itinerary'),
        SizedBox(height: 8),
        LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Itinerary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Itinerary not added yet. You can manage your day-wise plan here later.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildItineraryList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Itinerary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...docs.map((doc) => _buildItineraryItem(doc)),
      ],
    );
  }

  Widget _buildItineraryItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final title = (data['title'] as String?) ?? 'Activity';
    final when = _parseDate(data['start']);
    final location = (data['location'] as String?) ?? '';

    final subtitle = [
      if (when != null) _fmtDate(when),
      if (location.isNotEmpty) location,
    ].join(' • ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Symbols.schedule_rounded),
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
    );
  }

  String _fmtDate(DateTime d) => d.toLocal().toString().split(' ').first;

  DateTime? _parseDate(dynamic v) {
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return null;
  }
}
