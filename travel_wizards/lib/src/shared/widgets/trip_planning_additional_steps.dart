import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/features/trip_planning/views/controllers/trip_planning_wizard_controller.dart';
import 'package:travel_wizards/src/shared/widgets/trip_planning_steps.dart';

/// Step 2: Preferences (Travel party, pace, budget, stay type)
class PreferencesStepWidget extends TripPlanningStepWidget {
  const PreferencesStepWidget({super.key, required super.controller});

  @override
  TripPlanningStep get step => TripPlanningStep.preferences;

  @override
  String get stepTitle => 'Travel Preferences';

  @override
  String get stepDescription =>
      'Tell us about your travel style and preferences';

  @override
  Widget buildStepContent(BuildContext context) {
    return ListView(
      padding: Insets.allMd,
      children: [
        // Travel Party
        _PreferenceSection(
          icon: Icons.group_rounded,
          title: 'Who\'s traveling?',
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Solo', label: Text('Solo')),
              ButtonSegment(value: 'Couple', label: Text('Couple')),
              ButtonSegment(value: 'Family', label: Text('Family')),
              ButtonSegment(value: 'Friends', label: Text('Friends')),
            ],
            selected: {controller.travelParty},
            onSelectionChanged: (selection) {
              controller.updateTravelParty(selection.first);
            },
          ),
        ),

        Gaps.h16,

        // Trip Pace
        _PreferenceSection(
          icon: Icons.speed_rounded,
          title: 'What\'s your preferred pace?',
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Relaxed', label: Text('Relaxed')),
                  ButtonSegment(value: 'Balanced', label: Text('Balanced')),
                  ButtonSegment(value: 'Packed', label: Text('Packed')),
                ],
                selected: {controller.pace},
                onSelectionChanged: (selection) {
                  controller.updatePace(selection.first);
                },
              ),
              Gaps.h8,
              _buildPaceDescription(context),
            ],
          ),
        ),

        Gaps.h16,

        // Budget
        _PreferenceSection(
          icon: Icons.payments_rounded,
          title: 'What\'s your budget range?',
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'low', label: Text('Budget')),
                  ButtonSegment(value: 'medium', label: Text('Moderate')),
                  ButtonSegment(value: 'high', label: Text('Premium')),
                ],
                selected: {controller.budget},
                onSelectionChanged: (selection) {
                  controller.updateBudget(selection.first);
                },
              ),
              Gaps.h8,
              _buildBudgetDescription(context),
            ],
          ),
        ),

        Gaps.h16,

        // Stay Type
        _PreferenceSection(
          icon: Icons.hotel_rounded,
          title: 'Where do you prefer to stay?',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final stayType in ['Hotel', 'Homestay', 'Hostel', 'Resort'])
                FilterChip(
                  label: Text(stayType),
                  selected: controller.stayType == stayType,
                  onSelected: (selected) {
                    if (selected) {
                      controller.updateStayType(stayType);
                    }
                  },
                ),
            ],
          ),
        ),

        Gaps.h16,

        // Transportation Preference
        _PreferenceSection(
          icon: Icons.directions_car_filled_rounded,
          title: 'Transportation',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Prefer trains & road trips'),
            subtitle: const Text(
              'Choose scenic routes over flights when possible',
            ),
            value: controller.preferSurface,
            onChanged: controller.updatePreferSurface,
          ),
        ),

        Gaps.h32,

        // Preference Summary
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
                    Icons.summarize_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  Gaps.w8,
                  Text(
                    'Your Travel Style',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Gaps.h8,
              Text(
                'A ${controller.pace.toLowerCase()} ${controller.budget} trip for ${controller.travelParty.toLowerCase()}, '
                'staying in ${controller.stayType.toLowerCase()}s'
                '${controller.preferSurface ? ' with scenic transportation' : ''}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaceDescription(BuildContext context) {
    final descriptions = {
      'Relaxed': 'Slow travel, plenty of rest time, fewer activities',
      'Balanced': 'Mix of activities and relaxation, moderate schedule',
      'Packed': 'Action-packed, see and do as much as possible',
    };

    return Container(
      width: double.infinity,
      padding: Insets.allSm,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        descriptions[controller.pace] ?? '',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBudgetDescription(BuildContext context) {
    final descriptions = {
      'low': 'Budget-friendly options, local experiences',
      'medium': 'Good balance of comfort and value',
      'high': 'Premium experiences, luxury accommodations',
    };

    return Container(
      width: double.infinity,
      padding: Insets.allSm,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        descriptions[controller.budget] ?? '',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Step 3: Details (Origin, interests, notes)
class DetailsStepWidget extends TripPlanningStepWidget {
  const DetailsStepWidget({super.key, required super.controller});

  @override
  TripPlanningStep get step => TripPlanningStep.details;

  @override
  String get stepTitle => 'Additional Details';

  @override
  String get stepDescription => 'Add more details to personalize your trip';

  @override
  Widget buildStepContent(BuildContext context) {
    return ListView(
      padding: Insets.allMd,
      children: [
        // Origin
        _PreferenceSection(
          icon: Icons.flight_takeoff_rounded,
          title: 'Where are you traveling from?',
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'e.g., Mumbai, Delhi, Your city',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            onChanged: controller.updateOrigin,
            controller: TextEditingController()..text = controller.origin,
          ),
        ),

        Gaps.h16,

        // Interests
        _PreferenceSection(
          icon: Icons.interests_rounded,
          title: 'What are you interested in?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final interest in const [
                    'Nature',
                    'Culture',
                    'Food',
                    'Adventure',
                    'Shopping',
                    'Relaxation',
                    'Photography',
                    'History',
                    'Nightlife',
                    'Local Life',
                  ])
                    FilterChip(
                      label: Text(interest),
                      selected: controller.interests.contains(interest),
                      onSelected: (selected) {
                        controller.toggleInterest(interest);
                      },
                    ),
                ],
              ),
              if (controller.interests.isNotEmpty) ...[
                Gaps.h8,
                Container(
                  width: double.infinity,
                  padding: Insets.allSm,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Selected: ${controller.interests.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        Gaps.h16,

        // Notes
        _PreferenceSection(
          icon: Icons.notes_rounded,
          title: 'Special requests or notes',
          child: TextField(
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Dietary restrictions, accessibility needs, special occasions, etc.',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
            onChanged: controller.updateNotes,
            controller: TextEditingController()..text = controller.notes,
          ),
        ),

        Gaps.h32,

        // Tips for better planning
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
                    Icons.tips_and_updates_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  Gaps.w8,
                  Text(
                    'Helpful Tips',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Gaps.h8,
              Text(
                '• Your origin helps us suggest transportation options\n'
                '• Interests help create personalized itineraries\n'
                '• Mention any celebrations or special occasions\n'
                '• Include accessibility or dietary requirements',
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
}

/// Step 4: Review and confirmation
class ReviewStepWidget extends TripPlanningStepWidget {
  const ReviewStepWidget({super.key, required super.controller});

  @override
  TripPlanningStep get step => TripPlanningStep.review;

  @override
  String get stepTitle => 'Review Your Trip';

  @override
  String get stepDescription => 'Check all details before creating your trip';

  @override
  Widget buildStepContent(BuildContext context) {
    return ListView(
      padding: Insets.allMd,
      children: [
        // Trip Overview
        Card(
          child: Padding(
            padding: Insets.allMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.summarize_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Gaps.w8,
                    Text(
                      'Trip Overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Gaps.h16,

                // Trip title
                _ReviewItem(
                  icon: Icons.title_rounded,
                  label: 'Trip Name',
                  value: controller.title.isNotEmpty
                      ? controller.title
                      : 'New Trip',
                ),

                // Destinations
                _ReviewItem(
                  icon: Icons.place_rounded,
                  label: 'Destinations',
                  value: controller.destinations.isNotEmpty
                      ? controller.destinations.join(', ')
                      : 'No destinations',
                ),

                // Dates/Duration
                _ReviewItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Duration',
                  value: _getDurationText(),
                ),

                if (controller.dates != null)
                  _ReviewItem(
                    icon: Icons.event_rounded,
                    label: 'Dates',
                    value: _formatDateRange(controller.dates!),
                  ),
              ],
            ),
          ),
        ),

        Gaps.h16,

        // Preferences
        Card(
          child: Padding(
            padding: Insets.allMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Gaps.w8,
                    Text(
                      'Preferences',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Gaps.h16,

                _ReviewItem(
                  icon: Icons.group_rounded,
                  label: 'Travel Party',
                  value: controller.travelParty,
                ),

                _ReviewItem(
                  icon: Icons.speed_rounded,
                  label: 'Pace',
                  value: controller.pace,
                ),

                _ReviewItem(
                  icon: Icons.payments_rounded,
                  label: 'Budget',
                  value: controller.budget,
                ),

                _ReviewItem(
                  icon: Icons.hotel_rounded,
                  label: 'Stay Type',
                  value: controller.stayType,
                ),

                _ReviewItem(
                  icon: Icons.directions_car_filled_rounded,
                  label: 'Transportation',
                  value: controller.preferSurface
                      ? 'Prefers trains & road trips'
                      : 'No preference',
                ),
              ],
            ),
          ),
        ),

        if (controller.origin.isNotEmpty ||
            controller.interests.isNotEmpty ||
            controller.notes.isNotEmpty) ...[
          Gaps.h16,

          // Additional Details
          Card(
            child: Padding(
              padding: Insets.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Gaps.w8,
                      Text(
                        'Additional Details',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  Gaps.h16,

                  if (controller.origin.isNotEmpty)
                    _ReviewItem(
                      icon: Icons.flight_takeoff_rounded,
                      label: 'Origin',
                      value: controller.origin,
                    ),

                  if (controller.interests.isNotEmpty)
                    _ReviewItem(
                      icon: Icons.interests_rounded,
                      label: 'Interests',
                      value: controller.interests.join(', '),
                    ),

                  if (controller.notes.isNotEmpty)
                    _ReviewItem(
                      icon: Icons.notes_rounded,
                      label: 'Notes',
                      value: controller.notes,
                      isMultiline: true,
                    ),
                ],
              ),
            ),
          ),
        ],

        Gaps.h32,

        // Next steps info
        Container(
          padding: Insets.allMd,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  Gaps.w8,
                  Text(
                    'What happens next?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Gaps.h8,
              Text(
                'After creating your trip, you can:\n'
                '• Add detailed itinerary items\n'
                '• Get AI-powered suggestions\n'
                '• Share with travel companions\n'
                '• Track expenses and bookings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  String _formatDateRange(DateTimeRange range) {
    return '${range.start.day}/${range.start.month}/${range.start.year} → ${range.end.day}/${range.end.month}/${range.end.year}';
  }
}

/// Reusable preference section widget
class _PreferenceSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _PreferenceSection({
    required this.icon,
    required this.title,
    required this.child,
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
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

/// Review item widget
class _ReviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMultiline;

  const _ReviewItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          Gaps.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
