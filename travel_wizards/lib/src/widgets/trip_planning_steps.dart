import 'package:flutter/material.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/data/trip_planning_wizard_controller.dart';

/// Base class for wizard step widgets
abstract class TripPlanningStepWidget extends StatelessWidget {
  final TripPlanningWizardController controller;

  const TripPlanningStepWidget({super.key, required this.controller});

  /// Get the step this widget represents
  TripPlanningStep get step;

  /// Get the step title
  String get stepTitle;

  /// Get the step description
  String get stepDescription;

  /// Build the main content for this step
  Widget buildStepContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step header
        Container(
          width: double.infinity,
          padding: Insets.allMd,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stepTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              if (stepDescription.isNotEmpty) ...[
                Gaps.h8,
                Text(
                  stepDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
        Gaps.h16,

        // Step content
        Expanded(child: buildStepContent(context)),

        // Validation messages
        _buildValidationMessages(context),
      ],
    );
  }

  Widget _buildValidationMessages(BuildContext context) {
    final validation = controller.validateStep(step);

    if (validation.errors.isEmpty && validation.warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: Insets.v(8),
      child: Column(
        children: [
          // Errors
          if (validation.errors.isNotEmpty) ...[
            for (final error in validation.errors)
              Container(
                width: double.infinity,
                padding: Insets.allSm,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    Gaps.w8,
                    Expanded(
                      child: Text(
                        error,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // Warnings
          if (validation.warnings.isNotEmpty) ...[
            for (final warning in validation.warnings)
              Container(
                width: double.infinity,
                padding: Insets.allSm,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    Gaps.w8,
                    Expanded(
                      child: Text(
                        warning,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Step 1: Basics (Title, Destinations, Dates)
class BasicsStepWidget extends TripPlanningStepWidget {
  const BasicsStepWidget({super.key, required super.controller});

  @override
  TripPlanningStep get step => TripPlanningStep.basics;

  @override
  String get stepTitle => 'Trip Basics';

  @override
  String get stepDescription =>
      'Start by adding your trip name, destinations, and dates';

  @override
  Widget buildStepContent(BuildContext context) {
    return ListView(
      padding: Insets.allMd,
      children: [
        // Trip Title
        _SectionCard(
          icon: Icons.title_rounded,
          title: 'Trip Name',
          isRequired: true,
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'e.g., European Adventure, Goa Getaway',
              prefixIcon: Icon(Icons.edit_rounded),
            ),
            onChanged: controller.updateTitle,
            controller: TextEditingController()..text = controller.title,
          ),
        ),

        Gaps.h16,

        // Destinations
        _SectionCard(
          icon: Icons.place_rounded,
          title: 'Destinations',
          isRequired: true,
          trailing: TextButton.icon(
            onPressed: () => _showAddDestinationDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
          child: controller.destinations.isEmpty
              ? Text(
                  'Add cities or places you want to visit',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final destination in controller.destinations)
                      InputChip(
                        label: Text(destination),
                        onDeleted: () =>
                            controller.removeDestination(destination),
                        deleteIcon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
        ),

        Gaps.h16,

        // Dates and Duration
        _SectionCard(
          icon: Icons.calendar_month_rounded,
          title: 'When are you traveling?',
          isRequired: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date picker
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickDates(context),
                  icon: const Icon(Icons.event_rounded),
                  label: Text(
                    controller.dates == null
                        ? 'Select travel dates'
                        : _formatDateRange(controller.dates!),
                  ),
                ),
              ),

              Gaps.h16,

              // Duration selector (if no dates selected)
              if (controller.dates == null) ...[
                Text(
                  'Or choose trip duration:',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Gaps.h8,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final duration in [3, 5, 7, 10, 14, 21])
                      FilterChip(
                        label: Text('$duration days'),
                        selected: controller.durationDays == duration,
                        onSelected: (selected) {
                          controller.updateDuration(selected ? duration : null);
                        },
                      ),
                  ],
                ),
              ],

              // Show selected duration
              if (controller.dates != null ||
                  controller.durationDays != null) ...[
                Gaps.h8,
                Container(
                  padding: Insets.allSm,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      Gaps.w8,
                      Text(
                        'Duration: ${_getDurationText()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        Gaps.h32,

        // Quick tips
        Container(
          padding: Insets.allMd,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  Gaps.w8,
                  Text(
                    'Planning Tips',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Gaps.h8,
              Text(
                '• Choose a memorable name that reflects your trip\n'
                '• Add multiple destinations to create a journey\n'
                '• Consider travel time between destinations\n'
                '• Book 2-8 weeks in advance for best prices',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDestinationDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Destination'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'City or place name',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      this.controller.addDestination(result);
    }
  }

  Future<void> _pickDates(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDateRange: controller.dates,
      helpText: 'Select your travel dates',
    );

    if (range != null) {
      controller.updateDates(range);
    }
  }

  String _formatDateRange(DateTimeRange range) {
    return '${range.start.day}/${range.start.month}/${range.start.year} → ${range.end.day}/${range.end.month}/${range.end.year}';
  }

  String _getDurationText() {
    if (controller.dates != null) {
      final days = controller.dates!.end
          .difference(controller.dates!.start)
          .inDays;
      return '${days > 0 ? days : 1} days';
    }
    return '${controller.durationDays ?? 0} days';
  }
}

/// Reusable section card widget
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool isRequired;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                Gaps.w8,
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (isRequired) ...[
                  Gaps.w8,
                  Text(
                    '*',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            Gaps.h16,
            child,
          ],
        ),
      ),
    );
  }
}
