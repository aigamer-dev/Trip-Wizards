import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/data/trip_planning_wizard_controller.dart';
import 'package:travel_wizards/src/services/trips_repository.dart';
import 'package:travel_wizards/src/services/error_handling_service.dart';
import 'package:travel_wizards/src/widgets/trip_planning_steps.dart';
import 'package:travel_wizards/src/widgets/trip_planning_additional_steps.dart';

/// Enhanced trip planning screen with step-by-step wizard interface
class ImprovedPlanTripScreen extends StatefulWidget {
  final String? ideaId;
  final String? title;
  final Set<String>? tags;

  const ImprovedPlanTripScreen({super.key, this.ideaId, this.title, this.tags});

  @override
  State<ImprovedPlanTripScreen> createState() => _ImprovedPlanTripScreenState();
}

class _ImprovedPlanTripScreenState extends State<ImprovedPlanTripScreen> {
  late final TripPlanningWizardController _controller;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _controller = TripPlanningWizardController();
    _controller.addListener(_onControllerChanged);

    // Load initial data from args
    _controller.loadFromArgs(title: widget.title, tags: widget.tags);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {
      // Rebuild when controller changes
    });
  }

  Future<void> _createTrip() async {
    if (!_controller.validateCurrentStep().isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final trip = _controller.createTrip();
      await TripsRepository.instance.upsertTrip(trip);

      if (_controller.destinations.isNotEmpty) {
        await TripsRepository.instance.addDestinations(
          trip.id,
          _controller.destinations,
        );
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip "${trip.title}" created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to trip details
      context.pushNamed('trip_details', pathParameters: {'id': trip.id});
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'Creating trip from wizard',
        showToUser: true,
        userContext: context,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Your Trip'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 80),
          child: Container(
            padding: Insets.h(16).add(const EdgeInsets.only(bottom: 8)),
            child: Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: _controller.progress,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                Gaps.h8,

                // Step indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < TripPlanningStep.values.length; i++)
                      _StepIndicator(
                        step: TripPlanningStep.values[i],
                        isActive:
                            _controller.currentStep ==
                            TripPlanningStep.values[i],
                        isCompleted:
                            TripPlanningStep.values.indexOf(
                              _controller.currentStep,
                            ) >
                            i,
                        controller: _controller,
                        onTap: () {
                          if (_controller.goToStep(
                            TripPlanningStep.values[i],
                          )) {
                            setState(() {});
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Main content
          Expanded(child: _buildCurrentStep()),

          // Navigation buttons
          SafeArea(
            child: Container(
              padding: Insets.allMd,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  if (_controller.currentStep != TripPlanningStep.basics)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _controller.goToPreviousStep();
                          setState(() {});
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back'),
                      ),
                    ),

                  if (_controller.currentStep != TripPlanningStep.basics)
                    Gaps.w16,

                  // Next/Create button
                  Expanded(
                    flex: _controller.currentStep == TripPlanningStep.basics
                        ? 1
                        : 2,
                    child: FilledButton.icon(
                      onPressed: _isCreating
                          ? null
                          : _controller.currentStep == TripPlanningStep.review
                          ? _createTrip
                          : _controller.canProceedToNext()
                          ? () {
                              _controller.goToNextStep();
                              setState(() {});
                            }
                          : null,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _controller.currentStep == TripPlanningStep.review
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                      label: Text(
                        _isCreating
                            ? 'Creating...'
                            : _controller.currentStep == TripPlanningStep.review
                            ? 'Create Trip'
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_controller.currentStep) {
      case TripPlanningStep.basics:
        return BasicsStepWidget(controller: _controller);
      case TripPlanningStep.preferences:
        return PreferencesStepWidget(controller: _controller);
      case TripPlanningStep.details:
        return DetailsStepWidget(controller: _controller);
      case TripPlanningStep.review:
        return ReviewStepWidget(controller: _controller);
    }
  }
}

/// Step indicator widget for the progress bar
class _StepIndicator extends StatelessWidget {
  final TripPlanningStep step;
  final bool isActive;
  final bool isCompleted;
  final TripPlanningWizardController controller;
  final VoidCallback onTap;

  const _StepIndicator({
    required this.step,
    required this.isActive,
    required this.isCompleted,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stepNames = {
      TripPlanningStep.basics: 'Basics',
      TripPlanningStep.preferences: 'Preferences',
      TripPlanningStep.details: 'Details',
      TripPlanningStep.review: 'Review',
    };

    final stepIcons = {
      TripPlanningStep.basics: Icons.info_outline_rounded,
      TripPlanningStep.preferences: Icons.tune_rounded,
      TripPlanningStep.details: Icons.edit_note_rounded,
      TripPlanningStep.review: Icons.check_circle_outline_rounded,
    };

    Color getColor() {
      if (isCompleted) {
        return Theme.of(context).colorScheme.primary;
      } else if (isActive) {
        return Theme.of(context).colorScheme.primary;
      } else {
        return Theme.of(context).colorScheme.onSurfaceVariant;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive || isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: isActive && !isCompleted
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : stepIcons[step],
              size: 16,
              color: isActive || isCompleted
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Gaps.h8,
          Text(
            stepNames[step] ?? '',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: getColor(),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
