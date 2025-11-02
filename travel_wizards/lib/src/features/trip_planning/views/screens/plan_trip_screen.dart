import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travel_wizards/src/shared/widgets/location_autocomplete_field.dart';
import 'package:travel_wizards/src/shared/services/adk_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_wizards/src/features/trip_planning/views/controllers/trip_planning_controller.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

/// Arguments to prefill Plan Trip from other screens
class PlanTripArgs {
  final String? tripId; // Add tripId for editing
  final String? ideaId;
  final String? title;
  final Set<String>? tags;
  const PlanTripArgs({this.tripId, this.ideaId, this.title, this.tags});
}

/// Plan trip screen with multi-step wizard
class PlanTripScreen extends StatefulWidget {
  final PlanTripArgs? args;
  final TripPlanningController? controller;
  const PlanTripScreen({super.key, this.args, this.controller});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  late final TripPlanningController _controller;
  late final bool _ownsController;
  String? _validationError;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TripPlanningController();

    // Initialize with args and load draft
    if (_ownsController) {
      _initializeController();
    }
  }

  Future<void> _initializeController() async {
    final args = widget.args;
    if (args != null) {
      // If tripId is provided, load the existing trip for editing
      if (args.tripId != null) {
        await _controller.loadTripForEditing(args.tripId!);
      } else {
        // Otherwise initialize from args and try to load existing draft
        _controller.initializeFromArgs(
          ideaId: args.ideaId,
          title: args.title,
          tags: args.tags,
        );
        await _controller.loadDraft();
      }
    } else {
      // No args provided, try to load existing draft
      await _controller.loadDraft();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plan A Trip'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBackPressed(context),
          ),
        ),
        body: Consumer<TripPlanningController>(
          builder: (context, controller, child) {
            return Column(
              children: [
                // Step indicator
                _buildStepIndicator(controller),
                // Validation error
                if (_validationError != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const HGap(8),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Step content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: _buildStepContent(controller),
                  ),
                ),
                // Navigation buttons
                _buildNavigationButtons(controller),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepIndicator(TripPlanningController controller) {
    final steps = TripPlanningStep.values;
    final currentIndex = steps.indexOf(controller.currentStep);
    final progress = (currentIndex + 1) / steps.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentIndex + 1} of ${steps.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const VGap(8),
          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              tween: Tween(begin: 0, end: progress),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          const VGap(16),
          // Step circles
          Row(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                _buildStepCircleWithSemantics(
                  stepNumber: index + 1,
                  step: steps[index],
                  isActive: index == currentIndex,
                  isCompleted: index < currentIndex,
                ),
                if (index != steps.length - 1) _buildStepLine(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircleWithSemantics({
    required int stepNumber,
    required TripPlanningStep step,
    required bool isActive,
    required bool isCompleted,
  }) {
    final totalSteps = TripPlanningStep.values.length;
    final semanticsValue = isActive
        ? 'Current step'
        : (isCompleted ? 'Completed step' : 'Upcoming step');

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'Step $stepNumber of $totalSteps: ${_stepTitle(step)}',
      value: semanticsValue,
      child: _buildStepCircle(stepNumber, isActive),
    );
  }

  Widget _buildStepCircle(int stepNumber, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withAlpha(153),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: isActive
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
          child: Text(stepNumber.toString()),
        ),
      ),
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(height: 2, color: Theme.of(context).colorScheme.outline),
    );
  }

  String _stepTitle(TripPlanningStep step) {
    switch (step) {
      case TripPlanningStep.style:
        return 'Trip style';
      case TripPlanningStep.details:
        return 'Trip details';
      case TripPlanningStep.stayActivities:
        return 'Stay and activities';
      case TripPlanningStep.review:
        return 'Review and generate';
    }
  }

  Widget _buildStepContent(TripPlanningController controller) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        // Slide and fade transition
        final offsetAnimation =
            Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(controller.currentStep),
        child: _buildCurrentStep(controller),
      ),
    );
  }

  Widget _buildCurrentStep(TripPlanningController controller) {
    switch (controller.currentStep) {
      case TripPlanningStep.style:
        return _buildStep1TripStyle(controller);
      case TripPlanningStep.details:
        return _buildStep2TripDetails(controller);
      case TripPlanningStep.stayActivities:
        return _buildStep3StayActivities(controller);
      case TripPlanningStep.review:
        return _buildStep4Review(controller);
    }
  }

  Widget _buildStep1TripStyle(TripPlanningController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Trip Style',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const VGap(24),
          _buildTripStyleCard(
            'Solo',
            'Travel alone for personal exploration',
            Icons.person,
            controller.tripStyle == 'Solo',
            () => controller.setTripStyle('Solo'),
          ),
          const VGap(16),
          _buildTripStyleCard(
            'Couple',
            'Romantic getaway for two',
            Icons.favorite,
            controller.tripStyle == 'Couple',
            () => controller.setTripStyle('Couple'),
          ),
          const VGap(16),
          _buildTripStyleCard(
            'Family',
            'Family vacation with kids',
            Icons.family_restroom,
            controller.tripStyle == 'Family',
            () => controller.setTripStyle('Family'),
          ),
          const VGap(16),
          _buildTripStyleCard(
            'Group',
            'Friends or group adventure',
            Icons.group,
            controller.tripStyle == 'Group',
            () => controller.setTripStyle('Group'),
          ),
          const VGap(16),
          _buildTripStyleCard(
            'Business',
            'Corporate travel or meetings',
            Icons.business,
            controller.tripStyle == 'Business',
            () => controller.setTripStyle('Business'),
          ),
          const VGap(32),
          // Conditional fields based on trip style
          if (controller.tripStyle == 'Business') ...[
            Text(
              'Business Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const VGap(16),
            TextField(
              controller: controller.companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
            ),
            const VGap(16),
            TextField(
              controller: controller.businessPurposeController,
              decoration: const InputDecoration(
                labelText: 'Business Purpose',
                border: OutlineInputBorder(),
              ),
            ),
            const VGap(16),
            TextField(
              controller: controller.businessRequirementsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Special Requirements',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (controller.tripStyle == 'Family') ...[
            Text(
              'Family Members',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const VGap(16),
            Row(
              children: [
                Expanded(
                  child: _buildCounterField(
                    'Adults',
                    controller.adultsCount,
                    () => controller.setAdultsCount(controller.adultsCount - 1),
                    () => controller.setAdultsCount(controller.adultsCount + 1),
                  ),
                ),
                const HGap(16),
                Expanded(
                  child: _buildCounterField(
                    'Teenagers',
                    controller.teenagersCount,
                    () => controller.setTeenagersCount(
                      controller.teenagersCount - 1,
                    ),
                    () => controller.setTeenagersCount(
                      controller.teenagersCount + 1,
                    ),
                  ),
                ),
              ],
            ),
            const VGap(16),
            Row(
              children: [
                Expanded(
                  child: _buildCounterField(
                    'Children',
                    controller.childrenCount,
                    () => controller.setChildrenCount(
                      controller.childrenCount - 1,
                    ),
                    () => controller.setChildrenCount(
                      controller.childrenCount + 1,
                    ),
                  ),
                ),
                const HGap(16),
                Expanded(
                  child: _buildCounterField(
                    'Toddlers',
                    controller.toddlersCount,
                    () => controller.setToddlersCount(
                      controller.toddlersCount - 1,
                    ),
                    () => controller.setToddlersCount(
                      controller.toddlersCount + 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripStyleCard(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const HGap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterField(
    String label,
    int count,
    VoidCallback onDecrement,
    VoidCallback onIncrement,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const VGap(8),
        Row(
          children: [
            IconButton(
              onPressed: count > 0 ? onDecrement : null,
              icon: const Icon(Icons.remove),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(count.toString()),
            ),
            IconButton(onPressed: onIncrement, icon: const Icon(Icons.add)),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2TripDetails(TripPlanningController controller) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Travel Preferences
          Text(
            'Travel Preferences',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VGap(12),
          _buildTravelPreferenceSelector(controller),
          VGap(24),

          // Origin & Destination
          Text(
            'Origin & Destination',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VGap(12),
          _buildOriginDestinationFields(controller),
          VGap(24),

          // Dates
          Text(
            'Travel Dates',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VGap(12),
          _buildDateRangePicker(controller),
          VGap(24),

          // Buddies
          Text(
            'Travel Buddies',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VGap(12),
          _buildBuddiesSection(controller),
          VGap(24),

          // Special Requirements
          Text(
            'Special Requirements',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VGap(12),
          _buildSpecialRequirementsField(controller),
        ],
      ),
    );
  }

  Widget _buildStep3StayActivities(TripPlanningController controller) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accommodation Type
          Text(
            'Accommodation',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VGap(12),
          _buildAccommodationSelector(controller),
          VGap(24),

          // Activities
          Text(
            'Activities & Interests',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VGap(12),
          _buildActivitiesSelector(controller),
          VGap(24),

          // Budget
          Text(
            'Budget Range',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VGap(12),
          _buildBudgetSelector(controller),
          VGap(24),

          // Itinerary Type
          Text(
            'Itinerary Style',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VGap(12),
          _buildItinerarySelector(controller),
        ],
      ),
    );
  }

  Widget _buildStep4Review(TripPlanningController controller) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Review Your Trip Plan',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VGap(8),
          Text(
            'Review all your selections and generate your personalized trip itinerary',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          VGap(24),

          // Summary Cards
          _buildReviewCard(
            controller,
            'Trip Style',
            _getTripStyleSummary(controller),
            TripPlanningStep.style,
            Icons.people,
          ),
          VGap(16),

          _buildReviewCard(
            controller,
            'Trip Details',
            _getTripDetailsSummary(controller),
            TripPlanningStep.details,
            Icons.flight,
          ),
          VGap(16),

          _buildReviewCard(
            controller,
            'Stay & Activities',
            _getStayActivitiesSummary(controller),
            TripPlanningStep.stayActivities,
            Icons.hotel,
          ),

          if (controller.errorMessage != null) ...[
            VGap(16),
            VGap(16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  HGap(12),
                  Expanded(
                    child: Text(
                      controller.errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
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

  Widget _buildNavigationButtons(TripPlanningController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Row(
        children: [
          if (controller.currentStep != TripPlanningStep.style)
            Expanded(
              child: OutlinedButton(
                onPressed: () => controller.previousStep(),
                child: const Text('Back'),
              ),
            ),
          if (controller.currentStep != TripPlanningStep.style) const HGap(16),
          Expanded(
            child: FilledButton(
              onPressed: controller.currentStep == TripPlanningStep.review
                  ? () => _handleGenerateTrip(context, controller)
                  : () => _handleNextPressed(controller),
              child: Text(
                controller.currentStep == TripPlanningStep.review
                    ? 'Generate Trip'
                    : 'Next',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextPressed(TripPlanningController controller) {
    final validationError = controller.validateCurrentStep();
    if (validationError != null) {
      setState(() {
        _validationError = validationError;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // Smooth scroll to top for error visibility
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() {
        _validationError = null;
      });
      // Auto-save draft before proceeding
      controller.saveDraft();
      controller.nextStep();
    }
  }

  void _handleBackPressed(BuildContext context) {
    if (_controller.isDirty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save Draft?'),
          content: const Text(
            'Would you like to save your progress as a draft?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop();
              },
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                _controller.saveDraft();
                Navigator.of(context).pop();
                context.pop();
              },
              child: const Text('Save Draft'),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  void _handleGenerateTrip(
    BuildContext context,
    TripPlanningController controller,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Validate all required fields before generating
    if (controller.destinations.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please add at least one destination')),
      );
      return;
    }

    if (controller.dates == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please select travel dates')),
      );
      return;
    }

    // Show enhanced loading dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GeneratingTripDialog(),
    );

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please sign in to generate trips')),
        );
        return;
      }

      String? tripId;
      bool usedAdk = false;

      // Try to use ADK service if available
      try {
        final backendAvailable = AdkService.instance.backendBaseUrl != null;

        if (backendAvailable) {
          // Create ADK session
          final sessionData = await AdkService.instance.createSession(
            userId: user.uid,
            sessionId: 'trip_planning_${DateTime.now().millisecondsSinceEpoch}',
          );

          final sessionId = sessionData['sessionId'] as String;

          // Build trip planning message for the ADK planning agent
          final tripMessage = _buildTripPlanningMessage(controller);

          // Stream responses from ADK
          final responses = <String>[];
          await for (final chunk in AdkService.instance.runSse(
            userId: user.uid,
            sessionId: sessionId,
            text: tripMessage,
          )) {
            responses.add(chunk);
            debugPrint('ADK Response: $chunk');
          }

          // Process the responses and generate trip with AI itinerary
          tripId = await controller.generateTripFromAdkResponse(responses);
          usedAdk = true;
        } else {
          throw Exception('Backend not configured');
        }
      } catch (adkError) {
        debugPrint('ADK service unavailable, creating basic trip: $adkError');
        // Fallback: Create basic trip without AI-generated itinerary
        tripId = await controller.generateTrip();
        usedAdk = false;
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (tripId != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              usedAdk
                  ? 'Trip with AI itinerary created successfully!'
                  : 'Trip created successfully!',
            ),
          ),
        );

        // Navigate to trip details
        if (context.mounted) {
          context.go('/trips/$tripId');
        }
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to create trip. Please try again.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Trip creation failed: $e');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Trip creation failed: ${e.toString()}')),
      );
    }
  }

  String _buildTripPlanningMessage(TripPlanningController controller) {
    final buffer = StringBuffer();

    // Basic trip information
    buffer.writeln(
      'Please plan a complete trip itinerary for me with the following details:',
    );

    // Destination and dates
    if (controller.destinations.isNotEmpty) {
      buffer.writeln('Destination: ${controller.destinations.join(", ")}');
    }

    if (controller.dates != null) {
      final startDate = controller.dates!.start.toString().split(' ')[0];
      final endDate = controller.dates!.end.toString().split(' ')[0];
      buffer.writeln('Dates: $startDate to $endDate');
    }

    // Travel details
    buffer.writeln('Travel preference: ${controller.travelPreference}');
    if (controller.originController.text.isNotEmpty) {
      buffer.writeln('Origin: ${controller.originController.text}');
    }

    // Trip style and travelers
    buffer.writeln('Trip style: ${controller.tripStyle}');
    if (controller.tripStyle == 'Family') {
      buffer.writeln(
        'Travelers: ${controller.adultsCount} adults, ${controller.teenagersCount} teenagers, ${controller.childrenCount} children, ${controller.toddlersCount} toddlers',
      );
    }

    // Accommodation and activities
    buffer.writeln('Accommodation: ${controller.accommodationType}');
    if (controller.starRating != null) {
      buffer.writeln('Star rating: ${controller.starRating} stars');
    }

    if (controller.selectedActivities.isNotEmpty) {
      buffer.writeln('Activities: ${controller.selectedActivities.join(", ")}');
    }

    buffer.writeln('Budget: ${controller.budget.name}');
    buffer.writeln('Itinerary type: ${controller.itineraryType}');

    // Special requirements
    if (controller.specialRequirements.isNotEmpty) {
      buffer.writeln('Special requirements: ${controller.specialRequirements}');
    }

    // Notes
    if (controller.notesController.text.isNotEmpty) {
      buffer.writeln('Additional notes: ${controller.notesController.text}');
    }

    buffer.writeln(
      '\nPlease provide a complete itinerary including flight recommendations, hotel suggestions, and daily activities.',
    );

    return buffer.toString();
  }

  // Step 2 Helper Methods
  Widget _buildTravelPreferenceSelector(TripPlanningController controller) {
    final theme = Theme.of(context);
    final preferences = ['Flight', 'Train', 'Bus', 'Car'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferred mode of transport',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          VGap(12),
          SegmentedButton<String>(
            segments: preferences.map((pref) {
              return ButtonSegment<String>(
                value: pref,
                label: Text(
                  pref,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                icon: Icon(_getTransportIcon(pref)),
              );
            }).toList(),
            selected: {controller.travelPreference},
            onSelectionChanged: (Set<String> selection) {
              if (selection.isNotEmpty) {
                controller.setTravelPreference(selection.first);
              }
            },
            multiSelectionEnabled: false,
          ),
        ],
      ),
    );
  }

  IconData _getTransportIcon(String preference) {
    switch (preference) {
      case 'Flight':
        return Icons.flight;
      case 'Train':
        return Icons.train;
      case 'Bus':
        return Icons.directions_bus;
      case 'Car':
        return Icons.directions_car;
      default:
        return Icons.directions_walk;
    }
  }

  Widget _buildOriginDestinationFields(TripPlanningController controller) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Origin (FREE - No API key needed!)
          LocationAutocompleteField(
            controller: controller.originController,
            labelText: 'From (Origin)',
            hintText: 'Enter departure city',
            prefixIcon: const Icon(Icons.location_on),
            onPlaceSelected: (location) {
              // Handle place selection with free OpenStreetMap data
              controller.originController.text = location.description;
            },
          ),
          VGap(16),
          // Destination (FREE - No API key needed!)
          Row(
            children: [
              Expanded(
                child: LocationAutocompleteField(
                  controller: controller.destinationController,
                  labelText: 'To (Destination)',
                  hintText: 'Enter destination city',
                  prefixIcon: const Icon(Icons.flag),
                  onPlaceSelected: (location) {
                    // Handle place selection with free OpenStreetMap data
                    controller.destinationController.text =
                        location.description;
                    // Automatically add to destinations list
                    controller.addDestination(location.description);
                    // Clear the input for next destination
                    controller.destinationController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final destination = controller.destinationController.text
                      .trim();
                  if (destination.isNotEmpty) {
                    controller.addDestination(destination);
                    controller.destinationController.clear();
                  }
                },
                icon: const Icon(Icons.add),
                tooltip: 'Add destination',
              ),
            ],
          ),
          if (controller.destinations.isNotEmpty) ...[
            VGap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.destinations.map((destination) {
                return Chip(
                  label: Text(
                    destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  onDeleted: () {
                    controller.removeDestination(destination);
                  },
                  deleteIcon: const Icon(Icons.close, size: 16),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateRangePicker(TripPlanningController controller) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: controller.dates,
              );
              if (picked != null) {
                controller.setDates(picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  HGap(12),
                  Expanded(
                    child: Text(
                      controller.dates != null
                          ? '${_formatDate(controller.dates!.start)} - ${_formatDate(controller.dates!.end)}'
                          : 'Select travel dates',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (controller.dates != null) ...[
            VGap(12),
            Text(
              '${controller.dates!.duration.inDays + 1} days trip',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBuddiesSection(TripPlanningController controller) {
    final theme = Theme.of(context);
    final TextEditingController _buddySearchController =
        TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Autocomplete<Map<String, String>>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.length < 2) {
                      return const Iterable<Map<String, String>>.empty();
                    }
                    try {
                      final querySnapshot = await FirebaseFirestore.instance
                          .collection('users')
                          .where(
                            'email',
                            isGreaterThanOrEqualTo: textEditingValue.text
                                .toLowerCase(),
                          )
                          .where(
                            'email',
                            isLessThan:
                                '${textEditingValue.text.toLowerCase()}z',
                          )
                          .limit(10)
                          .get();

                      return querySnapshot.docs
                          .map(
                            (doc) => {
                              'email': doc.data()['email'] as String? ?? '',
                              'name':
                                  doc.data()['displayName'] as String? ?? '',
                            },
                          )
                          .where((user) => user['email']!.isNotEmpty)
                          .toList();
                    } catch (e) {
                      return const Iterable<Map<String, String>>.empty();
                    }
                  },
                  displayStringForOption: (Map<String, String> option) =>
                      option['name']!.isNotEmpty
                      ? '${option['name']} (${option['email']})'
                      : option['email']!,
                  onSelected: (Map<String, String> selection) {
                    final email = selection['email']!;
                    if (!controller.buddies.contains(email)) {
                      controller.addBuddy(email);
                    }
                    _buddySearchController.clear();
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Add travel buddy',
                            hintText: 'Start typing to search users...',
                            helperText: 'Type at least 2 characters to search',
                            prefixIcon: const Icon(Icons.person_add),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            _buddySearchController.text = value;
                          },
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(
                                  option['name']!.isNotEmpty
                                      ? option['name']!
                                      : option['email']!,
                                ),
                                subtitle: option['name']!.isNotEmpty
                                    ? Text(option['email']!)
                                    : null,
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (controller.buddies.isNotEmpty) ...[
            VGap(16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.buddies.map((buddy) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      buddy[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  label: Text(
                    buddy,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  onDeleted: () {
                    controller.removeBuddy(buddy);
                  },
                  deleteIcon: const Icon(Icons.close, size: 16),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialRequirementsField(TripPlanningController controller) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: controller.specialRequirementsController,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Special Requirements',
          hintText:
              'Any dietary restrictions, accessibility needs, or special requests...',
          alignLabelWithHint: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Step 3 Helper Methods
  Widget _buildAccommodationSelector(TripPlanningController controller) {
    final theme = Theme.of(context);
    final accommodationTypes = ['Hotel', 'Airbnb', 'Hostel', 'Resort', 'Villa'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferred accommodation type',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          VGap(12),
          SegmentedButton<String>(
            segments: accommodationTypes.map((type) {
              return ButtonSegment<String>(
                value: type,
                label: Text(
                  type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                icon: Icon(_getAccommodationIcon(type)),
              );
            }).toList(),
            selected: {controller.accommodationType},
            onSelectionChanged: (Set<String> selection) {
              if (selection.isNotEmpty) {
                controller.setAccommodationType(selection.first);
              }
            },
            multiSelectionEnabled: false,
          ),
          VGap(16),
          // Star rating for hotels
          if (controller.accommodationType == 'Hotel') ...[
            Text(
              'Minimum star rating',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            VGap(8),
            Row(
              children: List.generate(5, (index) {
                final starRating = index + 1;
                return IconButton(
                  onPressed: () => controller.setStarRating(starRating),
                  icon: Icon(
                    starRating <= (controller.starRating ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: starRating <= (controller.starRating ?? 0)
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getAccommodationIcon(String type) {
    switch (type) {
      case 'Hotel':
        return Icons.hotel;
      case 'Airbnb':
        return Icons.home;
      case 'Hostel':
        return Icons.bed;
      case 'Resort':
        return Icons.pool;
      case 'Villa':
        return Icons.villa;
      default:
        return Icons.home;
    }
  }

  Widget _buildActivitiesSelector(TripPlanningController controller) {
    final theme = Theme.of(context);
    final activities = [
      'Sightseeing',
      'Adventure',
      'Cultural',
      'Food & Drink',
      'Shopping',
      'Relaxation',
      'Nightlife',
      'Sports',
      'Nature',
      'Photography',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select activities you\'re interested in',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          VGap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activities.map((activity) {
              final isSelected = controller.selectedActivities.contains(
                activity,
              );
              return FilterChip(
                label: Text(
                  activity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.addSelectedActivity(activity);
                  } else {
                    controller.removeSelectedActivity(activity);
                  }
                },
                avatar: Icon(
                  _getActivityIcon(activity),
                  size: 18,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String activity) {
    switch (activity) {
      case 'Sightseeing':
        return Icons.visibility;
      case 'Adventure':
        return Icons.terrain;
      case 'Cultural':
        return Icons.museum;
      case 'Food & Drink':
        return Icons.restaurant;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Relaxation':
        return Icons.spa;
      case 'Nightlife':
        return Icons.nightlife;
      case 'Sports':
        return Icons.sports_soccer;
      case 'Nature':
        return Icons.nature;
      case 'Photography':
        return Icons.camera_alt;
      default:
        return Icons.star;
    }
  }

  Widget _buildBudgetSelector(TripPlanningController controller) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget preference per person per day',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          VGap(12),
          SegmentedButton<Budget>(
            segments: [
              ButtonSegment<Budget>(
                value: Budget.low,
                label: const Text(
                  'Budget',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                icon: const Icon(Icons.attach_money),
              ),
              ButtonSegment<Budget>(
                value: Budget.medium,
                label: const Text(
                  'Standard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                icon: const Icon(Icons.attach_money),
              ),
              ButtonSegment<Budget>(
                value: Budget.high,
                label: const Text(
                  'Luxury',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                icon: const Icon(Icons.attach_money),
              ),
            ],
            selected: {controller.budget},
            onSelectionChanged: (Set<Budget> selection) {
              if (selection.isNotEmpty) {
                controller.setBudget(selection.first);
              }
            },
            multiSelectionEnabled: false,
          ),
          VGap(12),
          Text(
            _getBudgetDescription(controller.budget),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getBudgetDescription(Budget budget) {
    switch (budget) {
      case Budget.low:
        return 'Hostels, street food, public transport (~\$50-100/day)';
      case Budget.medium:
        return 'Mid-range hotels, local restaurants, occasional taxis (~\$100-200/day)';
      case Budget.high:
        return 'Luxury hotels, fine dining, private transport (~\$200+/day)';
    }
  }

  Widget _buildItinerarySelector(TripPlanningController controller) {
    final theme = Theme.of(context);
    final itineraryTypes = ['Flexible', 'Structured'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Itinerary preference',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          VGap(12),
          SegmentedButton<String>(
            segments: itineraryTypes.map((type) {
              return ButtonSegment<String>(
                value: type,
                label: Text(
                  type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                icon: Icon(_getItineraryIcon(type)),
              );
            }).toList(),
            selected: {controller.itineraryType},
            onSelectionChanged: (Set<String> selection) {
              if (selection.isNotEmpty) {
                controller.setItineraryType(selection.first);
              }
            },
            multiSelectionEnabled: false,
          ),
          VGap(12),
          Text(
            controller.itineraryType == 'Flexible'
                ? 'Go with the flow - spontaneous activities and flexible timing'
                : 'Structured schedule - planned activities with set times',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getItineraryIcon(String type) {
    switch (type) {
      case 'Flexible':
        return Icons.shuffle;
      case 'Structured':
        return Icons.schedule;
      default:
        return Icons.calendar_today;
    }
  }

  // Step 4 Helper Methods
  Widget _buildReviewCard(
    TripPlanningController controller,
    String title,
    String summary,
    TripPlanningStep step,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                HGap(12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => controller.goToStep(step),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            VGap(12),
            Text(
              summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTripStyleSummary(TripPlanningController controller) {
    final style = controller.tripStyle;
    final parts = [style];

    if (style == 'Business') {
      if (controller.companyName.isNotEmpty) {
        parts.add('at ${controller.companyName}');
      }
    } else if (style == 'Family') {
      final totalMembers =
          controller.adultsCount +
          controller.teenagersCount +
          controller.childrenCount +
          controller.toddlersCount;
      parts.add('with $totalMembers members');
    }

    return parts.join(' ');
  }

  String _getTripDetailsSummary(TripPlanningController controller) {
    final parts = <String>[];

    // Travel preference
    parts.add('Travel by ${controller.travelPreference.toLowerCase()}');

    // Destinations
    if (controller.destinations.isNotEmpty) {
      if (controller.destinations.length == 1) {
        parts.add('to ${controller.destinations.first}');
      } else {
        parts.add('to ${controller.destinations.length} destinations');
      }
    }

    // Dates
    if (controller.dates != null) {
      final duration = controller.dates!.duration.inDays + 1;
      parts.add('for $duration days');
    }

    // Buddies
    if (controller.buddies.isNotEmpty) {
      if (controller.buddies.length == 1) {
        parts.add('with ${controller.buddies.first}');
      } else {
        parts.add('with ${controller.buddies.length} travel buddies');
      }
    }

    return parts.isEmpty ? 'No details specified' : parts.join(', ');
  }

  String _getStayActivitiesSummary(TripPlanningController controller) {
    final parts = <String>[];

    // Accommodation
    parts.add('Stay in ${controller.accommodationType.toLowerCase()}');
    if (controller.starRating != null &&
        controller.accommodationType == 'Hotel') {
      parts.add('(${controller.starRating}-star minimum)');
    }

    // Activities
    if (controller.selectedActivities.isNotEmpty) {
      final activities = controller.selectedActivities.take(3).join(', ');
      final remaining = controller.selectedActivities.length - 3;
      final activityText = remaining > 0
          ? '$activities +$remaining more'
          : activities;
      parts.add('Activities: $activityText');
    }

    // Budget
    final budgetText =
        controller.budget.name[0].toUpperCase() +
        controller.budget.name.substring(1);
    parts.add('$budgetText budget');

    // Itinerary
    parts.add('${controller.itineraryType.toLowerCase()} itinerary');

    return parts.join(' • ');
  }
}

/// Enhanced loading dialog for trip generation
class _GeneratingTripDialog extends StatefulWidget {
  @override
  State<_GeneratingTripDialog> createState() => _GeneratingTripDialogState();
}

class _GeneratingTripDialogState extends State<_GeneratingTripDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _loadingMessages = [
    'Analyzing your preferences...',
    'Finding the best destinations...',
    'Planning your itinerary...',
    'Calculating optimal routes...',
    'Adding local experiences...',
    'Finalizing your perfect trip...',
  ];

  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Cycle through messages
    _cycleMessages();
  }

  void _cycleMessages() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
        _cycleMessages();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Icon(
                  Icons.flight_takeoff_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const VGap(24),
            // Title
            Text(
              'Creating Your Trip',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const VGap(16),
            // Animated message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _loadingMessages[_currentMessageIndex],
                key: ValueKey(_currentMessageIndex),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const VGap(24),
            // Progress indicator
            SizedBox(
              width: double.infinity,
              child: LinearProgressIndicator(
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
