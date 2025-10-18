import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/models/trip.dart';
import 'package:travel_wizards/src/shared/services/trips_repository.dart';

class AddToTripScreen extends StatefulWidget {
  const AddToTripScreen({super.key});

  @override
  State<AddToTripScreen> createState() => _AddToTripScreenState();
}

class _AddToTripScreenState extends State<AddToTripScreen> {
  String _query = '';
  String? _selectedTripId;
  bool _creating = false;
  final _newTitleController = TextEditingController();
  DateTime _newStart = DateTime.now();
  DateTime _newEnd = DateTime.now().add(const Duration(days: 3));

  @override
  void dispose() {
    _newTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _newStart,
    );
    if (picked != null) setState(() => _newStart = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: _newStart,
      lastDate: DateTime(2100),
      initialDate: _newEnd.isBefore(_newStart)
          ? _newStart.add(const Duration(days: 1))
          : _newEnd,
    );
    if (picked != null) setState(() => _newEnd = picked);
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _createTripAndSelect() async {
    final title = _newTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a trip name')));
      return;
    }

    // Check authentication first
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create trips')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final trip = Trip(
        id: id,
        title: title,
        startDate: _newStart,
        endDate: _newEnd.isBefore(_newStart)
            ? _newStart.add(const Duration(days: 1))
            : _newEnd,
        destinations: const <String>[],
        notes: null,
      );

      debugPrint('Creating trip: ${trip.title} for user: ${user.uid}');
      await TripsRepository.instance.upsertTrip(trip);

      if (!mounted) return;
      setState(() => _selectedTripId = id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trip created')));
    } catch (e) {
      if (!mounted) return;
      debugPrint('Failed to create trip: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create trip: $e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: Insets.allMd,
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search your trips',
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        Gaps.h16,
        Row(
          children: [
            Text(
              'Existing trips',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _creating = !_creating),
              icon: const Icon(Icons.add_rounded),
              label: Text(_creating ? 'Cancel' : 'Create new'),
            ),
          ],
        ),
        if (_creating)
          Card(
            child: Padding(
              padding: Insets.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _newTitleController,
                    decoration: const InputDecoration(labelText: 'Trip name'),
                  ),
                  Gaps.h16,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickStart,
                          icon: const Icon(Icons.calendar_today_rounded),
                          label: Text('Start: ${_fmt(_newStart)}'),
                        ),
                      ),
                      Gaps.w8,
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickEnd,
                          icon: const Icon(Icons.calendar_today_rounded),
                          label: Text('End: ${_fmt(_newEnd)}'),
                        ),
                      ),
                    ],
                  ),
                  Gaps.h16,
                  FilledButton.icon(
                    onPressed: _creating ? null : _createTripAndSelect,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Create & select'),
                  ),
                ],
              ),
            ),
          ),
        StreamBuilder<List<Trip>>(
          stream: TripsRepository.instance.watchTrips(),
          builder: (context, AsyncSnapshot<List<Trip>> snapshot) {
            final trips = snapshot.data ?? const <Trip>[];
            final filtered = _query.isEmpty
                ? trips
                : trips
                      .where((t) => t.title.toLowerCase().contains(_query))
                      .toList(growable: false);
            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    _query.isEmpty
                        ? 'No trips yet. Create a new one.'
                        : 'No trips match your search.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return Column(
              children: [
                RadioGroup<String>(
                  onChanged: (v) => setState(() => _selectedTripId = v),
                  child: Column(
                    children: [
                      for (final t in filtered)
                        RadioListTile<String>(
                          value: t.id,
                          title: Text(t.title),
                          subtitle: Text(
                            '${_fmt(t.startDate)} → ${_fmt(t.endDate)}',
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _selectedTripId == null
                            ? null
                            : () {
                                // Return the chosen trip id to caller (if using sheet)
                                // or navigate accordingly if invoked as a page.
                                final id = _selectedTripId!;
                                if (context.canPop()) {
                                  context.pop(id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Selected trip: $id'),
                                    ),
                                  );
                                }
                              },
                        child: const Text('Add to trip'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
