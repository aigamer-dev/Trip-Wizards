import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/core/l10n/app_localizations.dart';

/// Enhanced onboarding screen with travel-focused preferences and skip options
class EnhancedOnboardingScreen extends StatefulWidget {
  const EnhancedOnboardingScreen({super.key});

  @override
  State<EnhancedOnboardingScreen> createState() =>
      _EnhancedOnboardingScreenState();
}

class _EnhancedOnboardingScreenState extends State<EnhancedOnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  final int _totalSteps = 5;

  // Onboarding data
  String? _travelStyle;
  final Set<String> _interests = {};
  String? _budgetRange;
  String? _accommodationType;
  bool _needsVisaAssistance = false;
  bool _wantsInsurance = false;
  final Map<String, int> _travelFrequency = {};

  final bool _isExperiencedTraveler = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    try {
      // Save onboarding preferences
      await _savePreferences();

      // Mark onboarding as complete in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'hasOnboarded': true,
        }, SetOptions(merge: true));
      }

      // Navigate to home
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing onboarding: $e')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final preferences = {
      'travelStyle': _travelStyle,
      'interests': _interests.toList(),
      'budgetRange': _budgetRange,
      'accommodationType': _accommodationType,
      'needsVisaAssistance': _needsVisaAssistance,
      'wantsInsurance': _wantsInsurance,
      'travelFrequency': _travelFrequency,
      'isExperiencedTraveler': _isExperiencedTraveler,
      'onboardingCompleted': true,
      'onboardingCompletedAt': FieldValue.serverTimestamp(),
    };

    // Save to Firestore
    debugPrint('Saving onboarding preferences: $preferences');
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'onboardingData': preferences,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(theme, t),

            // Skip button
            if (_currentStep < _totalSteps - 1)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _skipToEnd,
                    child: Text(
                      t.skip,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildWelcomeStep(theme, t),
                  _buildTravelStyleStep(theme, t),
                  _buildInterestsStep(theme, t),
                  _buildPreferencesStep(theme, t),
                  _buildFinalStep(theme, t),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(theme, t),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme, AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            t.stepProgress(_currentStep + 1, _totalSteps),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep(ThemeData theme, AppLocalizations t) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: Insets.allLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              t.welcomeToTravelWizards,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              t.personalizeExperience,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.aiPoweredTripPlanning)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.personalizedRecommendations)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.collaborativeTripPlanning)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelStyleStep(ThemeData theme, AppLocalizations t) {
    final styles = [
      {
        'title': 'Adventure Seeker',
        'desc': 'Thrilling activities and outdoor experiences',
        'icon': Icons.hiking,
      },
      {
        'title': 'Cultural Explorer',
        'desc': 'Museums, history, and local traditions',
        'icon': Icons.museum,
      },
      {
        'title': 'Relaxation Focused',
        'desc': 'Beaches, spas, and peaceful retreats',
        'icon': Icons.spa,
      },
      {
        'title': 'Food & Drink',
        'desc': 'Culinary tours and local cuisine',
        'icon': Icons.restaurant,
      },
      {
        'title': 'Business Traveler',
        'desc': 'Efficient, comfortable business trips',
        'icon': Icons.business_center,
      },
      {
        'title': 'Family Fun',
        'desc': 'Kid-friendly activities and family bonding',
        'icon': Icons.family_restroom,
      },
    ];

    return Padding(
      padding: Insets.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your travel style?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us recommend trips that match your personality.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: styles.length,
              itemBuilder: (context, index) {
                final style = styles[index];
                final isSelected = _travelStyle == style['title'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 4 : 1,
                  child: ListTile(
                    leading: Icon(
                      style['icon'] as IconData,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                    title: Text(
                      style['title'] as String,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(style['desc'] as String),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _travelStyle = style['title'] as String;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsStep(ThemeData theme, AppLocalizations t) {
    final interests = [
      'Adventure Sports',
      'Beaches',
      'Mountains',
      'Cities',
      'Wildlife',
      'Photography',
      'Shopping',
      'Nightlife',
      'Art & Culture',
      'Food Tours',
      'Festivals',
      'Architecture',
      'Wellness & Spa',
      'Road Trips',
      'Cruises',
      'Backpacking',
    ];

    return Padding(
      padding: Insets.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What interests you most?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply to get better recommendations.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                final isSelected = _interests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _interests.add(interest);
                      } else {
                        _interests.remove(interest);
                      }
                    });
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                  checkmarkColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep(ThemeData theme, AppLocalizations t) {
    return Padding(
      padding: Insets.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Travel Preferences',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us plan trips that fit your budget and style.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreferenceSection(
                    'Budget Range',
                    ['Budget-friendly', 'Mid-range', 'Luxury', 'Ultra-luxury'],
                    _budgetRange,
                    (value) => setState(() => _budgetRange = value),
                    theme,
                  ),
                  const SizedBox(height: 24),
                  _buildPreferenceSection(
                    'Accommodation Type',
                    [
                      'Hotels',
                      'Hostels',
                      'Vacation Rentals',
                      'Resorts',
                      'Camping',
                    ],
                    _accommodationType,
                    (value) => setState(() => _accommodationType = value),
                    theme,
                  ),
                  const SizedBox(height: 24),
                  _buildSwitchPreference(
                    'I need visa assistance',
                    _needsVisaAssistance,
                    (value) => setState(() => _needsVisaAssistance = value),
                    theme,
                  ),
                  _buildSwitchPreference(
                    'I want travel insurance recommendations',
                    _wantsInsurance,
                    (value) => setState(() => _wantsInsurance = value),
                    theme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalStep(ThemeData theme, AppLocalizations t) {
    return Padding(
      padding: Insets.allLg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'You\'re all set!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Based on your preferences, we\'ll recommend personalized trips and experiences just for you.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Your Profile Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_travelStyle != null) ...[
                  _buildSummaryRow('Travel Style', _travelStyle!, theme),
                  const SizedBox(height: 4),
                ],
                if (_interests.isNotEmpty) ...[
                  _buildSummaryRow(
                    'Interests',
                    '${_interests.length} selected',
                    theme,
                  ),
                  const SizedBox(height: 4),
                ],
                if (_budgetRange != null) ...[
                  _buildSummaryRow('Budget', _budgetRange!, theme),
                  const SizedBox(height: 4),
                ],
                if (_accommodationType != null)
                  _buildSummaryRow('Accommodation', _accommodationType!, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSection(
    String title,
    List<String> options,
    String? selectedValue,
    Function(String) onSelected,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onSelected(option);
              },
              selectedColor: theme.colorScheme.primaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSwitchPreference(
    String title,
    bool value,
    Function(bool) onChanged,
    ThemeData theme,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeThumbColor: theme.colorScheme.primary,
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }

  Widget _buildNavigationButtons(ThemeData theme, AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _currentStep == _totalSteps - 1
                  ? _completeOnboarding
                  : _nextStep,
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Get Started!' : 'Next',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
