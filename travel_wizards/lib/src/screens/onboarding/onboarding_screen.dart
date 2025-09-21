import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/services/auth_service.dart';
import 'package:travel_wizards/src/services/translation_service.dart';
import '../../services/error_handling_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0..4

  // Step 1
  Locale? _selectedLocale;

  // Step 2
  final _nameController = TextEditingController();
  DateTime? _dob;
  String? _gender;
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // Step 3
  final Set<String> _foodPrefs = <String>{};
  final _allergiesController = TextEditingController();

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _prefillFromAuth();
  }

  Future<void> _prefillFromAuth() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
      }
      final profile = await AuthService.instance.fetchPeopleProfile();
      if (!mounted) return;
      if (profile != null) {
        setState(() {
          _nameController.text = profile['name'] ?? _nameController.text;
          _gender = profile['gender'] as String? ?? _gender;
          final dobMap = profile['dob'] as Map<String, int?>?;
          if (dobMap != null) {
            final year = dobMap['year'] ?? 2000;
            final month = dobMap['month'] ?? 1;
            final day = dobMap['day'] ?? 1;
            _dob = DateTime(year, month, day);
          }
        });
      }
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'OnboardingScreen: Load existing profile data',
        showToUser: false,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  bool get _isValidForStep {
    switch (_step) {
      case 0:
        return true; // welcome page
      case 1:
        return _nameController.text.trim().isNotEmpty;
      case 2:
        return _foodPrefs.isNotEmpty || _allergiesController.text.isNotEmpty;
      case 3:
        return true; // review always possible
      case 4:
        return true;
      default:
        return false;
    }
  }

  Future<void> _next() async {
    if (_step < 4) {
      setState(() => _step += 1);
      return;
    }
    // Step 5 CTA -> persist and go home
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      final users = FirebaseFirestore.instance.collection('users');
      await users.doc(user.uid).set({
        'hasOnboarded': true,
        'profile': {
          'name': _nameController.text.trim(),
          'dob': _dob?.toIso8601String(),
          'gender': _gender,
          'state': _stateController.text.trim(),
          'city': _cityController.text.trim(),
          'foodPrefs': _foodPrefs.toList(),
          'allergies': _allergiesController.text.trim(),
          'locale': _selectedLocale?.toLanguageTag(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      GoRouter.of(context).go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save onboarding: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    final steps = <Widget>[
      _buildWelcome(theme),
      _buildProfile(theme, locales),
      _buildFoodPreferences(theme),
      _buildReview(theme),
      _buildCelebrate(theme),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: (_step + 1) / 5),
                  Gaps.h8,
                  Text(
                    'Step ${_step + 1} of 5',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: _step > 0
            ? IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back))
            : null,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = Breakpoints.isDesktop(width);
            final isTablet = Breakpoints.isTablet(width);
            final maxWidth = isDesktop
                ? 640.0
                : (isTablet ? 560.0 : double.infinity);
            final padding = isDesktop
                ? Insets.allXl
                : (isTablet ? Insets.allLg : Insets.allMd);

            return Padding(
              padding: padding,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: steps[_step],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = Breakpoints.isDesktop(width);
            final isTablet = Breakpoints.isTablet(width);
            final padding = isDesktop
                ? Insets.allXl
                : (isTablet ? Insets.allLg : Insets.allMd);

            return Padding(
              padding: padding,
              child: Row(
                children: [
                  TextButton(
                    onPressed: _step == 0 ? null : _back,
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _isValidForStep && !_busy ? _next : null,
                    child: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_step == 4 ? 'Finish' : 'Next'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcome(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome!', style: theme.textTheme.headlineSmall),
        Gaps.h8,
        Text('Let\'s get to know you to tailor your travel experience.'),
      ],
    );
  }

  Widget _buildProfile(ThemeData theme, List<Locale> locales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Locale>(
          initialValue: _selectedLocale,
          items: TranslationService.supportedLanguages
              .where((lang) => lang.locale != null) // Exclude system default
              .map(
                (lang) => DropdownMenuItem(
                  value: lang.locale,
                  child: Row(
                    children: [
                      Expanded(child: Text(lang.displayName)),
                      if (!lang.isNative) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.translate,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ],
                    ],
                  ),
                ),
              )
              .toList(),
          decoration: const InputDecoration(
            labelText: 'Preferred Language',
            helperText: 'Choose from 50+ languages including Google Translate',
          ),
          onChanged: (v) => setState(() => _selectedLocale = v),
        ),
        Gaps.h16,
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          textCapitalization: TextCapitalization.words,
        ),
        Gaps.h16,
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _gender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                  DropdownMenuItem(
                    value: 'prefer_not_say',
                    child: Text('Prefer not to say'),
                  ),
                ],
                decoration: const InputDecoration(labelText: 'Gender'),
                onChanged: (v) => setState(() => _gender = v),
              ),
            ),
            Gaps.w16,
            Expanded(
              child: InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final initial = _dob ?? DateTime(now.year - 25, 1, 1);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(1900),
                    lastDate: now,
                  );
                  if (picked != null) setState(() => _dob = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
                  child: Text(
                    _dob == null
                        ? 'Select date'
                        : _dob!.toIso8601String().substring(0, 10),
                  ),
                ),
              ),
            ),
          ],
        ),
        Gaps.h16,
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State'),
              ),
            ),
            Gaps.w16,
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFoodPreferences(ThemeData theme) {
    final options = const [
      'Vegetarian',
      'Vegan',
      'Non-Vegetarian',
      'Jain',
      'Halal',
      'Gluten-free',
      'Dairy-free',
      'Keto',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Food Preferences', style: theme.textTheme.titleLarge),
        Gaps.h8,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(o),
                selected: _foodPrefs.contains(o),
                onSelected: (v) => setState(() {
                  if (v) {
                    _foodPrefs.add(o);
                  } else {
                    _foodPrefs.remove(o);
                  }
                }),
              ),
          ],
        ),
        Gaps.h16,
        TextField(
          controller: _allergiesController,
          decoration: const InputDecoration(
            labelText: 'Allergies or other notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildReview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review', style: theme.textTheme.titleLarge),
        Gaps.h8,
        Text('Name: ${_nameController.text}'),
        Text('Gender: ${_gender ?? '-'}'),
        Text('DOB: ${_dob?.toIso8601String().substring(0, 10) ?? '-'}'),
        Text('State: ${_stateController.text}'),
        Text('City: ${_cityController.text}'),
        Text('Food: ${_foodPrefs.join(', ')}'),
        Text('Allergies: ${_allergiesController.text}'),
        Text('Language: ${_selectedLocale?.toLanguageTag() ?? '-'}'),
      ],
    );
  }

  Widget _buildCelebrate(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.celebration_rounded,
          size: 96,
          color: theme.colorScheme.primary,
        ),
        Gaps.h16,
        Text('All set!', style: theme.textTheme.headlineSmall),
        Gaps.h8,
        const Text('You can change these anytime in Settings.'),
      ],
    );
  }
}
