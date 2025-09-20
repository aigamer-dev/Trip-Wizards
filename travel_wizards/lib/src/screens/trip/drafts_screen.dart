import 'package:flutter/material.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/data/plan_trip_store.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  int? _duration;
  String? _budget;
  String? _notes;

  @override
  void initState() {
    super.initState();
    PlanTripStore.instance.load().then((_) {
      if (!mounted) return;
      setState(() {
        _duration = PlanTripStore.instance.durationDays;
        _budget = PlanTripStore.instance.budget;
        _notes = PlanTripStore.instance.notes;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDraft =
        _duration != null ||
        (_budget != null && _budget!.isNotEmpty) ||
        (_notes != null && _notes!.isNotEmpty);
    if (!hasDraft) {
      return const Center(
        child: Padding(
          padding: Insets.allMd,
          child: Text('No saved draft. Start planning a trip to create one.'),
        ),
      );
    }
    return ListView(
      padding: Insets.allMd,
      children: [
        Text('Saved Trip Draft', style: Theme.of(context).textTheme.titleLarge),
        Gaps.h8,
        if (_duration != null) Text('Duration: $_duration days'),
        if (_budget != null && _budget!.isNotEmpty) Text('Budget: $_budget'),
        if (_notes != null && _notes!.isNotEmpty) ...[
          Text('Notes:', style: Theme.of(context).textTheme.labelLarge),
          Gaps.h8,
          Text(_notes!),
        ],
        Gaps.h16,
        Row(
          children: [
            FilledButton.tonal(
              onPressed: () async {
                await PlanTripStore.instance.clear();
                if (!mounted) return;
                setState(() {
                  _duration = null;
                  _budget = null;
                  _notes = null;
                });
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Draft cleared')));
              },
              child: const Text('Clear Draft'),
            ),
          ],
        ),
      ],
    );
  }
}
