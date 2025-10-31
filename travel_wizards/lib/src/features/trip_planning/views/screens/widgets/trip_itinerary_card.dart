import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/services/error_handling_service.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'add_itinerary_dialog.dart';

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Itinerary', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Symbols.add_circle_outline),
              onPressed: () => _showAddItineraryDialog(context),
              tooltip: 'Add itinerary item',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'No itinerary items yet. Tap + to add your first activity.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showAddItineraryDialog(context),
          icon: const Icon(Symbols.add_rounded),
          label: const Text('Add Activity'),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Itinerary', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Symbols.add_circle_outline),
              onPressed: () => _showAddItineraryDialog(context),
              tooltip: 'Add itinerary item',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...docs.map((doc) => _buildItineraryItem(context, doc)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showAddItineraryDialog(context),
          icon: const Icon(Symbols.add_rounded),
          label: const Text('Add More'),
        ),
      ],
    );
  }

  Widget _buildItineraryItem(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final title = (data['title'] as String?) ?? 'Activity';
    final when = _parseDate(data['start']);
    final location = (data['location'] as String?) ?? '';
    final category = (data['category'] as String?) ?? 'Activity';

    final subtitle = [
      if (when != null) _fmtDate(when),
      if (location.isNotEmpty) location,
    ].join(' • ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_getCategoryIcon(category)),
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Symbols.delete_outline, size: 20),
        onPressed: () => _deleteItineraryItem(context, doc.id),
        tooltip: 'Delete',
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Transportation':
        return Symbols.directions_car_rounded;
      case 'Accommodation':
        return Symbols.hotel_rounded;
      case 'Dining':
        return Symbols.restaurant_rounded;
      case 'Sightseeing':
        return Symbols.photo_camera_rounded;
      case 'Shopping':
        return Symbols.shopping_bag_rounded;
      case 'Entertainment':
        return Symbols.celebration_rounded;
      default:
        return Symbols.schedule_rounded;
    }
  }

  void _showAddItineraryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddItineraryDialog(tripId: tripId),
    );
  }

  Future<void> _deleteItineraryItem(BuildContext context, String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this itinerary item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(tripId)
          .collection('itinerary')
          .doc(itemId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary item deleted')),
        );
      }
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'Delete itinerary item',
        showToUser: true,
      );
    }
  }

  String _fmtDate(DateTime d) => d.toLocal().toString().split(' ').first;

  DateTime? _parseDate(dynamic v) {
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (e) {
        ErrorHandlingService.instance.handleError(
          e,
          context: 'TripItineraryCard: Parse date from string',
          showToUser: false,
        );
      }
    }
    return null;
  }
}
