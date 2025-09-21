import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/controllers/trip_planning_controller.dart';

/// Arguments to prefill Plan Trip from other screens
class PlanTripArgs {
  final String? ideaId;
  final String? title;
  final Set<String>? tags;
  const PlanTripArgs({this.ideaId, this.title, this.tags});
}

/// Plan trip screen with proper state management
class PlanTripScreen extends StatefulWidget {
  final PlanTripArgs? args;
  const PlanTripScreen({super.key, this.args});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  late TripPlanningController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TripPlanningController();
    
    // Initialize with args and load draft
    _initializeController();
  }

  Future<void> _initializeController() async {
    final args = widget.args;
    if (args != null) {
      _controller.initializeFromArgs(
        ideaId: args.ideaId,
        title: args.title,
        tags: args.tags,
      );
    }
    
    await _controller.loadDraft();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            final shouldPop = await _controller.handleBackNavigation();
            if (shouldPop && context.mounted) {
              context.pop();
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Plan Trip'),
            actions: [
              Consumer<TripPlanningController>(
                builder: (context, controller, child) {
                  return TextButton(
                    onPressed: controller.isLoading ? null : () async {
                      await controller.clearDraft();
                      if (context.mounted) {
                        context.pop();
                      }
                    },
                    child: const Text('Cancel'),
                  );
                },
              ),
            ],
          ),
          body: Consumer<TripPlanningController>(
            builder: (context, controller, child) {
              return Column(
                children: [
                  if (controller.isLoading)
                    const LinearProgressIndicator(),
                  if (controller.errorMessage != null)
                    Container(
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.errorContainer,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        controller.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  Expanded(
                    child: _buildForm(controller),
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: Consumer<TripPlanningController>(
            builder: (context, controller, child) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: controller.isLoading ? null : () async {
                      final tripId = await controller.generateTrip(
                        fallbackTitle: widget.args?.title,
                      );
                      
                      if (tripId != null && context.mounted) {
                        context.pushNamed('trip_details', pathParameters: {'id': tripId});
                      }
                    },
                    child: controller.isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Trip'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(TripPlanningController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Title
          TextField(
            controller: controller.titleController,
            decoration: const InputDecoration(
              labelText: 'Trip Title',
              hintText: 'Amazing adventure to...',
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => controller.markDirty(),
          ),
          Gaps.h16,

          // Origin
          TextField(
            controller: controller.originController,
            decoration: const InputDecoration(
              labelText: 'Starting From',
              hintText: 'Your city',
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => controller.markDirty(),
          ),
          Gaps.h16,

          // Destinations
          _buildDestinationsSection(controller),
          Gaps.h16,

          // Dates & Duration
          _buildDatesSection(controller),
          Gaps.h16,

          // Budget
          _buildBudgetSection(controller),
          Gaps.h16,

          // Travel Details
          _buildTravelDetailsSection(controller),
          Gaps.h16,

          // Interests
          _buildInterestsSection(controller),
          Gaps.h16,

          // Notes
          TextField(
            controller: controller.notesController,
            decoration: const InputDecoration(
              labelText: 'Additional Notes',
              hintText: 'Any special requirements or preferences...',
            ),
            maxLines: 3,
            onChanged: (value) => controller.setNotes(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationsSection(TripPlanningController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Destinations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addDestination(controller),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (controller.destinations.isEmpty)
              const Text('No destinations added yet')
            else
              Wrap(
                spacing: 8,
                children: controller.destinations.map((dest) {
                  return Chip(
                    label: Text(dest),
                    onDeleted: () => controller.removeDestination(dest),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection(TripPlanningController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dates & Duration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.h8,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDates(controller),
                    child: Text(
                      controller.dates != null
                          ? '${_formatDate(controller.dates!.start)} - ${_formatDate(controller.dates!.end)}'
                          : 'Select dates',
                    ),
                  ),
                ),
                Gaps.w8,
                Text(
                  controller.durationDays != null 
                      ? '${controller.durationDays} days'
                      : '- days',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            Gaps.h8,
            Wrap(
              spacing: 8,
              children: TripPlanningController.durationOptions.map((days) {
                final isSelected = controller.durationDays == days;
                return FilterChip(
                  label: Text('$days days'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      controller.setDuration(days);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection(TripPlanningController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.h8,
            SegmentedButton<Budget>(
              segments: const [
                ButtonSegment<Budget>(
                  value: Budget.low,
                  label: Text('Budget'),
                ),
                ButtonSegment<Budget>(
                  value: Budget.medium,
                  label: Text('Moderate'),
                ),
                ButtonSegment<Budget>(
                  value: Budget.high,
                  label: Text('Luxury'),
                ),
              ],
              selected: {controller.budget},
              onSelectionChanged: (Set<Budget> selection) {
                controller.setBudget(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelDetailsSection(TripPlanningController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Travel Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.h16,
            _buildDropdown(
              'Travel Party',
              controller.travelParty,
              ['Solo', 'Couple', 'Family', 'Friends', 'Group'],
              controller.setTravelParty,
            ),
            Gaps.h8,
            _buildDropdown(
              'Travel Pace',
              controller.pace,
              ['Relaxed', 'Balanced', 'Packed'],
              controller.setPace,
            ),
            Gaps.h8,
            _buildDropdown(
              'Accommodation',
              controller.stayType,
              ['Hotel', 'Hostel', 'Vacation Rental', 'Resort', 'Camping'],
              controller.setStayType,
            ),
            Gaps.h8,
            SwitchListTile(
              title: const Text('Prefer surface travel'),
              subtitle: const Text('Trains, buses, and road trips'),
              value: controller.preferSurface,
              onChanged: controller.setPreferSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsSection(TripPlanningController controller) {
    const availableInterests = [
      'Adventure', 'Culture', 'Food', 'Nature', 'Beach', 'Mountains',
      'History', 'Art', 'Music', 'Shopping', 'Photography', 'Wildlife',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.h8,
            Wrap(
              spacing: 8,
              children: availableInterests.map((interest) {
                final isSelected = controller.interests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      controller.addInterest(interest);
                    } else {
                      controller.removeInterest(interest);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String initialValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      initialValue: initialValue,
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  Future<void> _addDestination(TripPlanningController controller) async {
    final textController = TextEditingController();
    final destination = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Destination'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'City or place',
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(textController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (destination?.isNotEmpty == true) {
      controller.addDestination(destination!);
    }
  }

  Future<void> _pickDates(TripPlanningController controller) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDateRange: controller.dates,
    );

    if (range != null) {
      controller.setDates(range);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}