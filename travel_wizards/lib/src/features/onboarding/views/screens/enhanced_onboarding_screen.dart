import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_wizards/src/core/l10n/app_localizations.dart';
import 'package:travel_wizards/src/shared/services/auth_service.dart';
import 'package:travel_wizards/src/shared/widgets/travel_components/travel_components.dart';

/// Enhanced onboarding screen with travel-focused preferences and skip options
class EnhancedOnboardingScreen extends StatefulWidget {
  /// When true, the screen will skip loading the user profile from Firebase.
  ///
  /// This is useful for widget tests that don't initialize Firebase plugins.
  const EnhancedOnboardingScreen({
    super.key,
    this.skipProfileLoad = false,
    this.initialStep = 0,
  });

  final bool skipProfileLoad;

  /// Optional initial step for the onboarding flow. Useful for widget tests.
  final int initialStep;

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
  final int _totalSteps = 6; // Increased from 5 to 6 for profile step

  // Profile data (Step 2)
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  String? _dateOfBirth;
  String? _gender;
  String? _state;
  bool _isGoogleUser = false;
  bool _isLoadingProfile = false;

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
    _pageController = PageController(initialPage: widget.initialStep);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // Initialize current step from widget (testability)
    _currentStep = widget.initialStep;

    // Start animation
    _animationController.forward();
    if (!widget.skipProfileLoad) {
      _loadUserProfile();
    }

    // Add listener to name controller to trigger validation
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() {
        _isLoadingProfile = true;
      });

      // Check if user signed in with Google
      final isGoogle = user.providerData.any(
        (info) => info.providerId == 'google.com',
      );
      _isGoogleUser = isGoogle;

      // Pre-fill name from Firebase user
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _nameController.text = user.displayName!;
      }

      // If Google user, try to fetch additional profile data from People API
      if (isGoogle) {
        final profileData = await AuthService.instance.fetchPeopleProfile();
        if (profileData != null && mounted) {
          // Update name if available and not already set
          if (profileData['name'] != null && _nameController.text.isEmpty) {
            _nameController.text = profileData['name'] as String;
          }

          // Set gender
          if (profileData['gender'] != null) {
            final gender = profileData['gender'] as String;
            _gender = gender == 'male'
                ? 'Male'
                : (gender == 'female' ? 'Female' : 'Other');
          }

          // Set date of birth
          if (profileData['dob'] != null) {
            final dob = profileData['dob'] as Map<String, dynamic>;
            final year = dob['year'] as int?;
            final month = dob['month'] as int?;
            final day = dob['day'] as int?;
            if (year != null && month != null && day != null) {
              _dateOfBirth =
                  '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  // Validation methods for each step
  bool _isStepValid() {
    switch (_currentStep) {
      case 0: // Welcome step
        return true; // Always valid
      case 1: // Profile step
        return _isProfileStepValid();
      case 2: // Travel style step
        return _travelStyle != null && _travelStyle!.isNotEmpty;
      case 3: // Interests step
        return _interests.isNotEmpty;
      case 4: // Preferences step
        return _budgetRange != null && _accommodationType != null;
      case 5: // Final/Review step
        return true;
      default:
        return false;
    }
  }

  bool _isProfileStepValid() {
    // Name is required and must be at least 2 characters
    if (_nameController.text.trim().isEmpty ||
        _nameController.text.trim().length < 2) {
      return false;
    }
    // Date of birth is required
    if (_dateOfBirth == null || _dateOfBirth!.isEmpty) {
      return false;
    }
    // Gender is required
    if (_gender == null || _gender!.isEmpty) {
      return false;
    }
    // State is required
    if (_state == null || _state!.isEmpty) {
      return false;
    }
    // City is optional but if provided must be at least 2 characters
    if (_cityController.text.isNotEmpty &&
        _cityController.text.trim().length < 2) {
      return false;
    }
    return true;
  }

  String? _getValidationMessage() {
    switch (_currentStep) {
      case 1: // Profile step
        if (_nameController.text.trim().isEmpty) {
          return 'Please enter your name';
        }
        if (_nameController.text.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        if (_dateOfBirth == null || _dateOfBirth!.isEmpty) {
          return 'Please select your date of birth';
        }
        if (_gender == null || _gender!.isEmpty) {
          return 'Please select your gender';
        }
        if (_state == null || _state!.isEmpty) {
          return 'Please select your state';
        }
        if (_cityController.text.isNotEmpty &&
            _cityController.text.trim().length < 2) {
          return 'City must be at least 2 characters';
        }
        return null;
      case 2: // Travel style
        if (_travelStyle == null || _travelStyle!.isEmpty) {
          return 'Please select your travel style';
        }
        return null;
      case 3: // Interests
        if (_interests.isEmpty) {
          return 'Please select at least one interest';
        }
        return null;
      case 4: // Preferences
        if (_budgetRange == null) {
          return 'Please select your budget range';
        }
        if (_accommodationType == null) {
          return 'Please select your accommodation preference';
        }
        return null;
      default:
        return null;
    }
  }

  void _nextStep() {
    // Validate before proceeding
    if (!_isStepValid()) {
      final message = _getValidationMessage();
      if (message != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

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
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Validate required profile fields
    if (_nameController.text.trim().isEmpty) {
      throw Exception('Name is required');
    }
    if (_dateOfBirth == null || _dateOfBirth!.isEmpty) {
      throw Exception('Date of birth is required');
    }
    if (_gender == null || _gender!.isEmpty) {
      throw Exception('Gender is required');
    }
    if (_state == null || _state!.isEmpty) {
      throw Exception('State is required');
    }

    // Prepare profile data with validation
    final profileData = {
      'name': _nameController.text.trim(),
      'dateOfBirth': _dateOfBirth!,
      'gender': _gender!,
      'state': _state!,
      if (_cityController.text.trim().isNotEmpty)
        'city': _cityController.text.trim(),
      'profileCompletedAt': FieldValue.serverTimestamp(),
      'isGoogleUser': _isGoogleUser,
    };

    // Prepare onboarding preferences
    final preferences = {
      if (_travelStyle != null) 'travelStyle': _travelStyle,
      'interests': _interests.toList(),
      if (_budgetRange != null) 'budgetRange': _budgetRange,
      if (_accommodationType != null) 'accommodationType': _accommodationType,
      'needsVisaAssistance': _needsVisaAssistance,
      'wantsInsurance': _wantsInsurance,
      'travelFrequency': _travelFrequency,
      'isExperiencedTraveler': _isExperiencedTraveler,
      'onboardingCompleted': true,
      'onboardingCompletedAt': FieldValue.serverTimestamp(),
      'onboardingVersion': '1.0', // Version for future migrations
    };

    // Save to Firestore with proper structure
    debugPrint('Saving profile data: $profileData');
    debugPrint('Saving onboarding preferences: $preferences');

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      // Profile data at root level
      ...profileData,
      // Onboarding preferences in nested object
      'onboardingData': preferences,
      // Metadata
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('Successfully saved user data to Firestore');
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
                  _buildProfileStep(theme, t),
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
    return SingleChildScrollView(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: Insets.allLg,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height *
                  0.6, // Ensure minimum height
            ),
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
        ),
      ),
    );
  }

  Widget _buildProfileStep(ThemeData theme, AppLocalizations t) {
    final indianStates = [
      'Andhra Pradesh',
      'Arunachal Pradesh',
      'Assam',
      'Bihar',
      'Chhattisgarh',
      'Goa',
      'Gujarat',
      'Haryana',
      'Himachal Pradesh',
      'Jharkhand',
      'Karnataka',
      'Kerala',
      'Madhya Pradesh',
      'Maharashtra',
      'Manipur',
      'Meghalaya',
      'Mizoram',
      'Nagaland',
      'Odisha',
      'Punjab',
      'Rajasthan',
      'Sikkim',
      'Tamil Nadu',
      'Telangana',
      'Tripura',
      'Uttar Pradesh',
      'Uttarakhand',
      'West Bengal',
    ];

    return SingleChildScrollView(
      padding: Insets.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Profile',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (_isGoogleUser)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Profile data fetched from your Google account',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Name field
          TravelTextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person),
            ),
            enabled: !_isLoadingProfile,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Date of Birth
          Semantics(
            label: 'Date of birth selector',
            hint: 'Double tap to open date picker and select your birth date',
            button: true,
            child: InkWell(
              onTap: _isLoadingProfile
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateOfBirth != null
                            ? DateTime.parse(_dateOfBirth!)
                            : DateTime.now().subtract(
                                const Duration(days: 365 * 25),
                              ),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateOfBirth = picked.toIso8601String().split('T')[0];
                        });
                      }
                    },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.cake),
                  enabled: !_isLoadingProfile,
                ),
                child: Text(
                  _dateOfBirth ?? 'Select date',
                  style: _dateOfBirth == null
                      ? theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.5 * 255).toInt(),
                          ),
                        )
                      : theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gender
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: ['Male', 'Female', 'Other', 'Prefer not to say']
                .map(
                  (gender) =>
                      DropdownMenuItem(value: gender, child: Text(gender)),
                )
                .toList(),
            onChanged: _isLoadingProfile
                ? null
                : (value) {
                    setState(() {
                      _gender = value;
                    });
                  },
          ),
          const SizedBox(height: 16),

          // State
          DropdownButtonFormField<String>(
            initialValue: _state,
            decoration: const InputDecoration(
              labelText: 'State',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            items: indianStates
                .map(
                  (state) => DropdownMenuItem(value: state, child: Text(state)),
                )
                .toList(),
            onChanged: _isLoadingProfile
                ? null
                : (value) {
                    setState(() {
                      _state = value;
                      _cityController.clear(); // Reset city when state changes
                    });
                  },
          ),
          const SizedBox(height: 16),

          // City
          TravelTextField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'City',
              prefixIcon: const Icon(Icons.location_city),
            ),
            enabled: !_isLoadingProfile,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          if (_isLoadingProfile)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    'Loading your profile...',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
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
              child: SecondaryButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: PrimaryButton(
              onPressed: _isStepValid()
                  ? (_currentStep == _totalSteps - 1
                        ? _completeOnboarding
                        : _nextStep)
                  : null, // Disabled when step is invalid
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
