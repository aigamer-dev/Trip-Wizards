import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/features/trip_planning/views/controllers/trip_planning_controller.dart';
import 'package:travel_wizards/src/shared/services/navigation_service.dart';

/// Arguments to prefill Plan Trip from other screens
class PlanTripArgs {
  final String? tripId; // Add tripId for editing
  final String? ideaId;
  final String? title;
  final Set<String>? tags;
  const PlanTripArgs({this.tripId, this.ideaId, this.title, this.tags});
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
      // If tripId is provided, load the existing trip for editing
      if (args.tripId != null) {
        await _controller.loadTripForEditing(args.tripId!);
      } else {
        // Otherwise initialize from args
        _controller.initializeFromArgs(
          ideaId: args.ideaId,
          title: args.title,
          tags: args.tags,
        );
      }
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
    final theme = Theme.of(context);
    final isEditMode = widget.args?.tripId != null;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            final shouldPop = await _controller.handleBackNavigation();
            if (shouldPop && context.mounted) {
              await NavigationService.instance.popOrGoHome(context);
            }
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Scaffold(
              backgroundColor: theme.colorScheme.surface,
              appBar: AppBar(
                title: Text(isEditMode ? 'Edit Trip' : 'Plan New Trip'),
                elevation: 0,
                backgroundColor: theme.colorScheme.surface,
                actions: [
                  Consumer<TripPlanningController>(
                    builder: (context, controller, child) {
                      return TextButton.icon(
                        onPressed: controller.isLoading
                            ? null
                            : () async {
                                await controller.clearDraft();
                                if (context.mounted) {
                                  await NavigationService.instance.popOrGoHome(
                                    context,
                                  );
                                }
                              },
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cancel'),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Consumer<TripPlanningController>(
                builder: (context, controller, child) {
                  return Column(
                    children: [
                      if (controller.isLoading)
                        const LinearProgressIndicator()
                      else
                        const SizedBox(height: 4),
                      if (controller.errorMessage != null)
                        Material(
                          color: theme.colorScheme.errorContainer,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: theme.colorScheme.onErrorContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    controller.errorMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  iconSize: 20,
                                  color: theme.colorScheme.onErrorContainer,
                                  onPressed: () {
                                    // Clear error message
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(child: _buildForm(controller, isMobile)),
                    ],
                  );
                },
              ),
              bottomNavigationBar: Consumer<TripPlanningController>(
                builder: (context, controller, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            if (!isMobile) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: controller.isLoading
                                      ? null
                                      : () => controller.saveDraft(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Save Draft'),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              flex: isMobile ? 1 : 2,
                              child: FilledButton.icon(
                                onPressed: controller.isLoading
                                    ? null
                                    : () async {
                                        final tripId = await controller
                                            .generateTrip(
                                              fallbackTitle: widget.args?.title,
                                            );

                                        if (tripId != null && context.mounted) {
                                          context.pushNamed(
                                            'trip_details',
                                            pathParameters: {'id': tripId},
                                          );
                                        }
                                      },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                icon: controller.isLoading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        isEditMode
                                            ? Icons.check_rounded
                                            : Icons.add_rounded,
                                      ),
                                label: Text(
                                  controller.isLoading
                                      ? 'Creating...'
                                      : isEditMode
                                      ? 'Update Trip'
                                      : 'Create Trip',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(TripPlanningController controller, bool isMobile) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.explore_rounded,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  'Plan Your Adventure',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your dream trip and we\'ll help you plan every detail',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Trip Title
          Text(
            'Trip Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.titleController,
            decoration: InputDecoration(
              labelText: 'Trip Title *',
              hintText: 'e.g., Summer Adventure in Europe',
              prefixIcon: const Icon(Icons.title_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => controller.markDirty(),
          ),
          const SizedBox(height: 16),

          // Origin
          TextField(
            controller: controller.originController,
            decoration: InputDecoration(
              labelText: 'Starting From *',
              hintText: 'e.g., New York',
              prefixIcon: const Icon(Icons.flight_takeoff_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => controller.markDirty(),
          ),
          const SizedBox(height: 24),

          // Destinations
          _buildDestinationsSection(controller),
          const SizedBox(height: 24),

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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Destinations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => _addDestination(controller),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.destinations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add destinations you want to visit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.destinations.map((dest) {
                  return Chip(
                    label: Text(dest),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                    onDeleted: () => controller.removeDestination(dest),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    deleteIconColor: theme.colorScheme.onSecondaryContainer,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection(TripPlanningController controller) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'When & How Long',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _pickDates(controller),
              icon: const Icon(Icons.edit_calendar_rounded),
              label: Text(
                controller.dates != null
                    ? '${_formatDate(controller.dates!.start)} - ${_formatDate(controller.dates!.end)}'
                    : 'Select travel dates',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            if (controller.durationDays != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.durationDays} days',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Quick select duration',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                  showCheckmark: false,
                  backgroundColor: theme.colorScheme.surface,
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection(TripPlanningController controller) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Budget Range',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<Budget>(
              segments: const [
                ButtonSegment<Budget>(
                  value: Budget.low,
                  label: Text('Budget'),
                  icon: Icon(Icons.savings_rounded, size: 18),
                ),
                ButtonSegment<Budget>(
                  value: Budget.medium,
                  label: Text('Moderate'),
                  icon: Icon(Icons.card_travel_rounded, size: 18),
                ),
                ButtonSegment<Budget>(
                  value: Budget.high,
                  label: Text('Luxury'),
                  icon: Icon(Icons.diamond_rounded, size: 18),
                ),
              ],
              selected: {controller.budget},
              onSelectionChanged: (Set<Budget> selection) {
                controller.setBudget(selection.first);
              },
              style: ButtonStyle(visualDensity: VisualDensity.comfortable),
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
            _buildDropdown('Travel Party', controller.travelParty, [
              'Solo',
              'Couple',
              'Family',
              'Friends',
              'Group',
            ], controller.setTravelParty),
            Gaps.h8,
            _buildDropdown('Travel Pace', controller.pace, [
              'Relaxed',
              'Balanced',
              'Packed',
            ], controller.setPace),
            Gaps.h8,
            _buildDropdown('Accommodation', controller.stayType, [
              'Hotel',
              'Hostel',
              'Vacation Rental',
              'Resort',
              'Camping',
            ], controller.setStayType),
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
      'Adventure',
      'Culture',
      'Food',
      'Nature',
      'Beach',
      'Mountains',
      'History',
      'Art',
      'Music',
      'Shopping',
      'Photography',
      'Wildlife',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Interests', style: Theme.of(context).textTheme.titleMedium),
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
        return DropdownMenuItem(value: option, child: Text(option));
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
          decoration: const InputDecoration(hintText: 'City or place'),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(textController.text.trim()),
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
