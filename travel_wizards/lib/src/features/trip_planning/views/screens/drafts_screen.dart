import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/features/trip_planning/data/plan_trip_store.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  // A key to force the FutureBuilder to re-run when the draft is cleared.
  var _futureKey = UniqueKey();

  void _clearDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Draft?'),
        content: const Text(
          'This will permanently delete your saved trip draft.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await PlanTripStore.instance.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft cleared successfully')),
        );
        // Change the key to trigger a rebuild of the FutureBuilder
        setState(() {
          _futureKey = UniqueKey();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernPageScaffold(
      sections: [
        ModernSection(
          title: 'Saved Trip Draft',
          child: FutureBuilder<void>(
            key: _futureKey,
            future: PlanTripStore.instance.load(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final store = PlanTripStore.instance;
              final hasDraft =
                  store.durationDays != null ||
                  (store.budget != null && store.budget!.isNotEmpty) ||
                  (store.notes != null && store.notes!.isNotEmpty);

              if (!hasDraft) {
                return const _EmptyDrafts(
                  icon: Symbols.edit_note,
                  message:
                      'No saved draft found.\nStart planning a trip to create one!',
                );
              }

              return _DraftCard(
                duration: store.durationDays,
                budget: store.budget,
                notes: store.notes,
                onClear: _clearDraft,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    this.duration,
    this.budget,
    this.notes,
    required this.onClear,
  });

  final int? duration;
  final String? budget;
  final String? notes;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Current Plan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(Symbols.delete_outline, color: colorScheme.error),
                  onPressed: onClear,
                  tooltip: 'Clear Draft',
                ),
              ],
            ),
            const Divider(height: 32),
            if (duration != null) ...[
              _InfoRow(
                icon: Symbols.calendar_month,
                label: 'Duration',
                value: '$duration days',
              ),
              Gaps.h16,
            ],
            if (budget != null && budget!.isNotEmpty) ...[
              _InfoRow(
                icon: Symbols.account_balance_wallet,
                label: 'Budget',
                value: budget!,
              ),
              Gaps.h16,
            ],
            if (notes != null && notes!.isNotEmpty) ...[
              _InfoRow(
                icon: Symbols.notes,
                label: 'Notes',
                value: notes!,
                isMultiline: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isMultiline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 28),
        Gaps.w16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Gaps.h8,
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyDrafts extends StatelessWidget {
  const _EmptyDrafts({required this.icon, required this.message});
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
            Gaps.h24,
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
