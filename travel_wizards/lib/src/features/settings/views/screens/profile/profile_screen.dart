import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/core/app/settings_controller.dart';
import 'package:travel_wizards/src/core/l10n/app_localizations.dart';
import 'package:travel_wizards/src/shared/models/profile_store.dart';
import 'package:travel_wizards/src/shared/models/user_profile.dart';
import 'package:travel_wizards/src/shared/services/offline_service.dart';
import 'package:travel_wizards/src/shared/services/navigation_service.dart';
import 'package:travel_wizards/src/shared/services/user_profile_service.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/widgets/translated_text.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _photoController = TextEditingController();
  final _dobController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _foodPrefController = TextEditingController();
  final _allergiesController = TextEditingController();

  late final List<TextEditingController> _allControllers;
  final _formKey = GlobalKey<FormState>();
  Timer? _autoSaveTimer;
  static const _autoSaveDelay = Duration(seconds: 2);
  DateTime? _lastSavedAt;
  bool _hasChanges = false;
  bool _hasValidationError = false;
  bool _updatingControllers = false;
  UserProfile? _loadedProfile;
  bool _uploadingPhoto = false;
  bool _canEditPhoto = true;
  bool _isGoogleAccount = false;
  bool _basicDetailsEditable = true;

  bool _loading = true;
  bool _saving = false;
  bool _isOffline = false;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _allControllers = [
      _nameController,
      _emailController,
      _usernameController,
      _photoController,
      _dobController,
      _stateController,
      _cityController,
      _countryController,
      _foodPrefController,
      _allergiesController,
    ];
    _updateEditingCapabilities();
    _registerControllerListeners();
    _initialize();
  }

  Future<void> _initialize() async {
    final offlineService = OfflineService.instance;
    await offlineService.initialize();
    await ProfileStore.instance.load();
    final profile = await UserProfileService.instance.loadProfile();
    if (!mounted) return;
    _loadedProfile = profile;
    _populateControllers(profile);
    _updateEditingCapabilities();
    setState(() {
      _isOffline = offlineService.isOffline;
      _loading = false;
      _hasChanges = false;
      _lastSavedAt = profile?.lastUpdated;
      // _updateEditingCapabilities already adjusted stateful fields.
    });
  }

  void _populateControllers(UserProfile? profile) {
    _updatingControllers = true;
    final store = ProfileStore.instance;
    _nameController.text = profile?.name ?? store.name;
    _emailController.text = profile?.email ?? store.email;
    _usernameController.text = profile?.username ?? store.username;
    final photoFallback = store.photoUrl.isNotEmpty
        ? store.photoUrl
        : (FirebaseAuth.instance.currentUser?.photoURL ?? '');
    _photoController.text = profile?.photoUrl ?? photoFallback;
    _dobController.text = profile?.dob != null
        ? DateFormat('yyyy-MM-dd').format(profile!.dob!)
        : store.dob;
    _stateController.text = profile?.state ?? store.state;
    _cityController.text = profile?.city ?? store.city;
    _countryController.text = profile?.country ?? store.country;
    _foodPrefController.text = profile?.foodPreferences.isNotEmpty == true
        ? profile!.foodPreferences.join(', ')
        : store.foodPref;
    _allergiesController.text = profile?.allergies ?? store.allergies;
    _selectedGender =
        profile?.gender ?? (store.gender.isEmpty ? null : store.gender);
    _updatingControllers = false;
  }

  void _registerControllerListeners() {
    for (final controller in _allControllers) {
      controller.addListener(_handleFormChanged);
    }
  }

  void _removeControllerListeners() {
    for (final controller in _allControllers) {
      controller.removeListener(_handleFormChanged);
    }
  }

  bool _usesGoogleSignIn() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') {
        return true;
      }
    }
    return false;
  }

  bool _hasUnsetBasicDetails() {
    final missingText = [
      _nameController.text,
      _emailController.text,
      _dobController.text,
      _countryController.text,
      _stateController.text,
      _cityController.text,
    ].any((value) => value.trim().isEmpty);
    final missingGender = (_selectedGender ?? '').trim().isEmpty;
    return missingText || missingGender;
  }

  void _updateEditingCapabilities() {
    _isGoogleAccount = _usesGoogleSignIn();
    _canEditPhoto = !_isGoogleAccount;
    _basicDetailsEditable = !_isGoogleAccount || _hasUnsetBasicDetails();
  }

  void _handleFormChanged() {
    if (_updatingControllers) return;
    final form = _formKey.currentState;
    final hasErrors = form != null && !form.validate();
    if (!_hasChanges || _hasValidationError != hasErrors) {
      setState(() {
        _hasChanges = true;
        _hasValidationError = hasErrors;
      });
    }
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (!_hasChanges) return;
    _autoSaveTimer?.cancel();
    if (_hasValidationError || _saving || _uploadingPhoto) {
      return;
    }
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      _autoSaveTimer = null;
      if (!mounted) return;
      _saveProfile(triggeredByAutoSave: true);
    });
  }

  void _resetToLoadedProfile() {
    if (_loadedProfile == null) return;
    _populateControllers(_loadedProfile);
    _updateEditingCapabilities();
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    setState(() {
      _hasChanges = false;
      _hasValidationError = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.profileRevertedChangesMessage ??
              'Reverted unsaved changes.',
        ),
      ),
    );
  }

  String? _validateRequired(
    BuildContext context,
    String? value, {
    required String fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      final l10n = AppLocalizations.of(context);
      return l10n?.profileFieldRequired(fieldName) ?? '$fieldName is required';
    }
    return null;
  }

  String? _validateUsername(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      final l10n = AppLocalizations.of(context);
      return l10n?.profileUsernameTooShort ?? 'At least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_\.\-]+$').hasMatch(trimmed)) {
      final l10n = AppLocalizations.of(context);
      return l10n?.profileUsernameInvalid ??
          'Only letters, numbers, underscores or dots';
    }
    return null;
  }

  String? _validateEmail(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmed)) {
      final l10n = AppLocalizations.of(context);
      return l10n?.profileEmailInvalid ?? 'Enter a valid email address';
    }
    return null;
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _removeControllerListeners();
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _photoController.dispose();
    _dobController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _foodPrefController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final manageLanguageTitle =
        l10n?.languageManageTitle ?? 'Manage your app language globally';
    final manageLanguageDescription =
        l10n?.languageManageDescription ??
        'Choose your preferred language from Settings → Language and we\'ll apply it everywhere.';
    final manageLanguageCta =
        l10n?.languageManageCta ?? 'Open language settings';
    final strings = _ProfileStrings(l10n);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ModernPageScaffold(
      showBackButton: true,
      pageTitle: _nameController.text.isEmpty
          ? strings.pageTitle
          : _nameController.text,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Tooltip(
                    message: _hasChanges
                        ? strings.saveTooltipPending
                        : strings.saveTooltipSaved,
                    key: ValueKey(_hasChanges),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                      ),
                      onPressed: _hasChanges ? _saveProfile : null,
                      icon: const Icon(Symbols.save),
                      label: Text(l10n?.save ?? 'Save'),
                    ),
                  ),
          ),
        ),
      ],
      hero: _ProfileBackdrop(
        photoUrl: _photoController.text,
        name: _nameController.text,
        email: _emailController.text,
        onUseGooglePhoto: _applyGooglePhoto,
        isOffline: _isOffline,
        canEditPhoto: _canEditPhoto,
        strings: strings,
      ),
      sections: [
        if (_isOffline)
          Container(
            key: const ValueKey('offline-banner'),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withAlpha(
                (0.35 * 255).toInt(),
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.error.withAlpha((0.35 * 255).toInt()),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Symbols.wifi_off, color: theme.colorScheme.error),
                    const HGap(Insets.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.offlineTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const VGap(Insets.xs),
                          Text(
                            strings.offlineDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_hasChanges) ...[
                  const VGap(Insets.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _hasChanges ? _resetToLoadedProfile : null,
                      icon: const Icon(Symbols.restart_alt),
                      label: Text(strings.discardEditsLabel),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ModernSection(
          title: strings.accountBasicsTitle,
          subtitle: strings.accountBasicsSubtitle,
          children: [
            TextFormField(
              controller: _nameController,
              enabled: _basicDetailsEditable,
              decoration: InputDecoration(
                labelText: strings.fullNameLabel,
                prefixIcon: const Icon(Symbols.badge),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _validateRequired(
                context,
                value,
                fieldName: strings.fullNameLabel,
              ),
            ),
            const VGap(Insets.md),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: strings.usernameLabel,
                helperText: strings.usernameHelper,
                prefixIcon: const Icon(Symbols.alternate_email),
              ),
              validator: (value) => _validateUsername(context, value),
            ),
            const VGap(Insets.md),
            TextFormField(
              controller: _emailController,
              enabled: _basicDetailsEditable,
              decoration: InputDecoration(
                labelText: strings.emailLabel,
                prefixIcon: const Icon(Symbols.mail),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => _validateEmail(context, value),
            ),
            const VGap(Insets.md),
            DropdownButtonFormField<String?>(
              key: ValueKey(_selectedGender ?? 'none'),
              initialValue: _selectedGender,
              onChanged: _basicDetailsEditable
                  ? (value) {
                      setState(() {
                        _selectedGender = value;
                        _hasChanges = true;
                      });
                      _scheduleAutoSave();
                    }
                  : null,
              disabledHint: _selectedGender == null
                  ? Text(strings.genderOptionPreferNot)
                  : Text(
                      _selectedGender! == 'male'
                          ? strings.genderOptionMale
                          : _selectedGender == 'female'
                          ? strings.genderOptionFemale
                          : _selectedGender == 'other'
                          ? strings.genderOptionOther
                          : strings.genderOptionPreferNot,
                    ),
              decoration: InputDecoration(
                labelText: strings.genderLabel,
                prefixIcon: const Icon(Symbols.wc),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(strings.genderOptionPreferNot),
                ),
                DropdownMenuItem(
                  value: 'male',
                  child: Text(strings.genderOptionMale),
                ),
                DropdownMenuItem(
                  value: 'female',
                  child: Text(strings.genderOptionFemale),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text(strings.genderOptionOther),
                ),
              ],
            ),
            const VGap(Insets.md),
            TextFormField(
              controller: _dobController,
              readOnly: true,
              enabled: _basicDetailsEditable,
              decoration: InputDecoration(
                labelText: strings.dobLabel,
                hintText: strings.dobHint,
                prefixIcon: const Icon(Symbols.cake),
                suffixIcon: const Icon(Symbols.calendar_today),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null;
                }
                return DateTime.tryParse(value.trim()) == null
                    ? strings.dobFormatError
                    : null;
              },
              onTap: _basicDetailsEditable
                  ? () async {
                      final now = DateTime.now();
                      final initialDate = _dobController.text.isNotEmpty
                          ? DateTime.tryParse(_dobController.text) ??
                                DateTime(now.year - 20, now.month, now.day)
                          : DateTime(now.year - 20, now.month, now.day);
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1900),
                        lastDate: now,
                        initialDate: initialDate,
                      );
                      if (picked != null) {
                        _dobController.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(picked);
                      }
                    }
                  : null,
            ),
            const VGap(Insets.lg),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                  (0.35 * 255).toInt(),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    manageLanguageTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const VGap(Insets.sm),
                  TranslatedText(
                    manageLanguageDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const VGap(Insets.md),
                  FilledButton.tonalIcon(
                    onPressed: () => NavigationService.instance.router
                        ?.pushNamed('language_settings'),
                    icon: const Icon(Symbols.open_in_new),
                    label: TranslatedText(
                      manageLanguageCta,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isGoogleAccount && !_basicDetailsEditable) ...[
              const VGap(Insets.sm),
              Text(
                strings.googleManagedNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        ModernSection(
          title: strings.homeTitle,
          subtitle: strings.homeSubtitle,
          children: [
            TextFormField(
              controller: _countryController,
              enabled: _basicDetailsEditable,
              decoration: InputDecoration(
                labelText: strings.countryLabel,
                prefixIcon: const Icon(Symbols.public),
              ),
            ),
            const VGap(Insets.md),
            TextFormField(
              controller: _stateController,
              enabled: _basicDetailsEditable,
              decoration: InputDecoration(
                labelText: strings.stateLabel,
                prefixIcon: const Icon(Symbols.map),
              ),
            ),
            const VGap(Insets.md),
            TextFormField(
              controller: _cityController,
              enabled: _basicDetailsEditable,
              decoration: InputDecoration(
                labelText: strings.cityLabel,
                prefixIcon: const Icon(Symbols.location_city),
              ),
            ),
          ],
        ),
        ModernSection(
          title: strings.tasteTitle,
          subtitle: strings.tasteSubtitle,
          children: [
            TextFormField(
              controller: _foodPrefController,
              decoration: InputDecoration(
                labelText: strings.foodPrefsLabel,
                helperText: strings.foodPrefsHelper,
                prefixIcon: const Icon(Symbols.restaurant),
              ),
            ),
            const VGap(Insets.md),
            TextFormField(
              controller: _allergiesController,
              decoration: InputDecoration(
                labelText: strings.allergiesLabel,
                prefixIcon: const Icon(Symbols.health_and_safety),
              ),
              maxLines: 3,
            ),
          ],
        ),
        ModernSection(
          title: strings.photoSectionTitle,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ProfileAvatar(
                      photoUrl: _photoController.text,
                      size: 64,
                      icon: Symbols.person,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      iconColor: theme.colorScheme.onSurface,
                      semanticLabel: strings.photoSectionTitle,
                    ),
                    if (_uploadingPhoto)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surface.withAlpha(
                            (0.75 * 255).toInt(),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                  ],
                ),
                const HGap(Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.photoGuidance,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const VGap(Insets.sm),
                      if (_canEditPhoto) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _uploadingPhoto || _isOffline
                                  ? null
                                  : _pickAndUploadPhoto,
                              icon: const Icon(Symbols.upload_file),
                              label: Text(strings.uploadPhotoButton),
                            ),
                            OutlinedButton.icon(
                              onPressed: _uploadingPhoto
                                  ? null
                                  : _applyGooglePhoto,
                              icon: const Icon(Symbols.cloud_download),
                              label: Text(strings.useGooglePhotoButton),
                            ),
                            if (_photoController.text.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: _uploadingPhoto
                                    ? null
                                    : _removePhoto,
                                icon: const Icon(Symbols.delete),
                                label: Text(strings.removePhotoButton),
                              ),
                          ],
                        ),
                        if (_isOffline) ...[
                          const VGap(Insets.sm),
                          Text(
                            strings.offlinePhotoWarning,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          strings.photoManagedNotice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _hasChanges
              ? Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _resetToLoadedProfile,
                    icon: const Icon(Symbols.restart_alt),
                    label: Text(strings.discardChangesLabel),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (_lastSavedAt != null) ...[
          Text(
            strings.lastSavedAt(
              DateFormat.jm().format(_lastSavedAt!.toLocal()),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const VGap(Insets.sm),
        ],
        Text(
          strings.cacheMessage,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    if (!_canEditPhoto || _uploadingPhoto) return;
    final messenger = ScaffoldMessenger.of(context);
    final strings = _ProfileStrings(AppLocalizations.of(context));
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.signedInToUploadError)),
      );
      return;
    }
    if (_isOffline) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.reconnectToUploadError)),
      );
      return;
    }

    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        messenger.showSnackBar(SnackBar(content: Text(strings.readFileError)));
        return;
      }

      const maxBytes = 5 * 1024 * 1024; // 5 MB
      if (bytes.lengthInBytes > maxBytes) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.fileTooLargeError)),
        );
        return;
      }

      setState(() => _uploadingPhoto = true);

      final extension = (file.extension ?? 'jpg').toLowerCase();
      final metadata = SettableMetadata(
        contentType: _contentTypeForExtension(extension),
        cacheControl: 'public,max-age=604800',
      );
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}/avatar.$extension');

      final snapshot = await storageRef.putData(bytes, metadata);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (!mounted) return;
      setState(() {
        _photoController.text = downloadUrl;
        _uploadingPhoto = false;
        _hasChanges = true;
      });
      _scheduleAutoSave();
      messenger.showSnackBar(
        SnackBar(content: Text(strings.photoUpdatedMessage)),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            strings.photoUploadFailedMessage((e.message ?? e.code).trim()),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      messenger.showSnackBar(
        SnackBar(content: Text(strings.photoUploadFailedMessage('$e'))),
      );
    }
  }

  void _removePhoto() {
    if (!_canEditPhoto || _uploadingPhoto) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    setState(() {
      _photoController.clear();
      _hasChanges = true;
    });
    _scheduleAutoSave();
  }

  void _applyGooglePhoto() {
    if (!_canEditPhoto || _uploadingPhoto) return;
    final googlePhoto = FirebaseAuth.instance.currentUser?.photoURL;
    if (googlePhoto != null && googlePhoto.isNotEmpty) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = null;
      setState(() => _photoController.text = googlePhoto);
      _scheduleAutoSave();
    }
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _saveProfile({bool triggeredByAutoSave = false}) async {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    if (triggeredByAutoSave && !_hasChanges) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final strings = _ProfileStrings(AppLocalizations.of(context));
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!triggeredByAutoSave) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.signedInToSaveError)),
        );
      }
      return;
    }

    final form = _formKey.currentState;
    final hasErrors = form != null && !form.validate();
    if (hasErrors) {
      if (!_hasValidationError) {
        setState(() => _hasValidationError = true);
      }
      if (!triggeredByAutoSave) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.fixHighlightedFieldsError)),
        );
      }
      return;
    } else if (_hasValidationError) {
      setState(() => _hasValidationError = false);
    }

    if (!triggeredByAutoSave) {
      FocusScope.of(context).unfocus();
    }

    DateTime? dob;
    if (_dobController.text.isNotEmpty) {
      dob = DateTime.tryParse(_dobController.text);
      if (dob == null) {
        if (!triggeredByAutoSave) {
          messenger.showSnackBar(
            SnackBar(content: Text(strings.dobFormatError)),
          );
        }
        return;
      }
    }

    if (_saving) {
      return;
    }

    setState(() => _saving = true);

    try {
      final selectedLocale = AppSettings.instance.locale;
      final selectedLanguageCode = selectedLocale?.toLanguageTag();
      final foodPrefs = _foodPrefController.text
          .split(',')
          .map((e) => e.trim())
          .where((element) => element.isNotEmpty)
          .toList();

      final now = DateTime.now();
      final profile = UserProfile(
        uid: user.uid,
        email: _emailController.text.trim().isEmpty
            ? user.email
            : _emailController.text.trim(),
        name: _nameController.text.trim(),
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        photoUrl: _photoController.text.trim().isEmpty
            ? user.photoURL
            : _photoController.text.trim(),
        languageCode: selectedLanguageCode,
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        gender: _selectedGender,
        dob: dob,
        foodPreferences: foodPrefs,
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        lastUpdated: now,
      );

      final savedOnline = await UserProfileService.instance.saveProfile(
        profile,
      );
      if (!mounted) return;
      _updateEditingCapabilities();
      setState(() {
        _saving = false;
        _isOffline = OfflineService.instance.isOffline;
        _hasChanges = false;
        _loadedProfile = profile;
        _lastSavedAt = now;
      });
      if (!triggeredByAutoSave) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              savedOnline
                  ? strings.syncSuccessMessage
                  : strings.syncOfflineMessage,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            triggeredByAutoSave
                ? strings.autoSaveFailedMessage('$e')
                : strings.saveFailedMessage('$e'),
          ),
        ),
      );
    }
  }
}

class _ProfileStrings {
  const _ProfileStrings(this._l10n);

  final AppLocalizations? _l10n;

  String get offlineTitle => _l10n?.profileOfflineTitle ?? 'Offline mode';

  String get offlineDescription =>
      _l10n?.profileOfflineDescription ??
      'We\'ll sync your changes as soon as you reconnect. You can keep editing safely.';

  String get discardEditsLabel =>
      _l10n?.profileDiscardEditsLabel ?? 'Discard edits';

  String get accountBasicsTitle =>
      _l10n?.profileAccountBasicsTitle ?? 'Account basics';

  String get accountBasicsSubtitle =>
      _l10n?.profileAccountBasicsSubtitle ??
      'These details power personalised suggestions and shared trip experiences.';

  String get fullNameLabel => _l10n?.profileFullNameLabel ?? 'Full name';

  String get usernameLabel => _l10n?.profileUsernameLabel ?? 'Username';

  String get usernameHelper =>
      _l10n?.profileUsernameHelper ??
      'Used for public sharing links and concierge assistance';

  String get emailLabel => _l10n?.profileEmailLabel ?? 'Email';

  String get genderLabel => _l10n?.profileGenderLabel ?? 'Gender';

  String get genderOptionPreferNot =>
      _l10n?.profileGenderOptionPreferNot ?? 'Prefer not to say';

  String get genderOptionMale => _l10n?.profileGenderOptionMale ?? 'Male';

  String get genderOptionFemale => _l10n?.profileGenderOptionFemale ?? 'Female';

  String get genderOptionOther => _l10n?.profileGenderOptionOther ?? 'Other';

  String get dobLabel => _l10n?.profileDobLabel ?? 'Date of birth';

  String get dobHint => _l10n?.profileDobHint ?? 'YYYY-MM-DD';

  String get dobFormatError =>
      _l10n?.profileDobFormatError ?? 'Use the format YYYY-MM-DD';

  String get googleManagedNotice =>
      _l10n?.profileGoogleManagedNotice ??
      'These details come from your Google account. Email support@travelwizards.com if they need updating.';

  String get homeTitle => _l10n?.profileHomeTitle ?? 'Where you call home';

  String get homeSubtitle =>
      _l10n?.profileHomeSubtitle ??
      'Let us tailor weather alerts and concierge tips around your go-to destinations.';

  String get countryLabel => _l10n?.profileCountryLabel ?? 'Country';

  String get stateLabel => _l10n?.profileStateLabel ?? 'State / Region';

  String get cityLabel => _l10n?.profileCityLabel ?? 'City';

  String get tasteTitle => _l10n?.profileTasteTitle ?? 'Taste & care';

  String get tasteSubtitle =>
      _l10n?.profileTasteSubtitle ??
      'We use this to highlight dining you\'ll love and avoid things you can\'t have.';

  String get foodPrefsLabel =>
      _l10n?.profileFoodPrefsLabel ?? 'Food preferences';

  String get foodPrefsHelper =>
      _l10n?.profileFoodPrefsHelper ??
      'Comma-separated (e.g. Vegan, Nut-free, Farm-to-table)';

  String get allergiesLabel =>
      _l10n?.profileAllergiesLabel ?? 'Allergies / notes';

  String get photoSectionTitle =>
      _l10n?.profilePhotoSectionTitle ?? 'Profile photo';

  String get photoGuidance =>
      _l10n?.profilePhotoGuidance ??
      'Use a high-quality square image for best results.';

  String get uploadPhotoButton =>
      _l10n?.profileUploadPhotoButton ?? 'Upload new photo';

  String get useGooglePhotoButton =>
      _l10n?.profileUseGooglePhotoButton ?? 'Use Google photo';

  String get removePhotoButton =>
      _l10n?.profileRemovePhotoButton ?? 'Remove photo';

  String get offlinePhotoWarning =>
      _l10n?.profileOfflinePhotoWarning ??
      'You\'re offline. Reconnect to upload a new photo.';

  String get photoManagedNotice =>
      _l10n?.profilePhotoManagedNotice ??
      'Profile photos for Google sign-ins must be updated from your Google Account. We\'ll mirror updates automatically.';

  String get discardChangesLabel =>
      _l10n?.profileDiscardChangesLabel ?? 'Discard changes';

  String lastSavedAt(String time) =>
      _l10n?.profileLastSavedAtLabel(time) ?? 'Last saved at $time';

  String get cacheMessage =>
      _l10n?.profileCacheMessage ??
      'Your profile is cached for offline access and synchronises as soon as you reconnect.';

  String get saveTooltipPending =>
      _l10n?.profileSaveTooltipPending ?? 'Save profile updates';

  String get saveTooltipSaved =>
      _l10n?.profileSaveTooltipSaved ?? 'All changes saved';

  String get pageTitle => _l10n?.profilePageTitle ?? 'Profile';

  String get backdropDefaultName =>
      _l10n?.profileBackdropDefaultName ?? 'Your profile';

  String get managedByGoogleBadge =>
      _l10n?.profileManagedByGoogleBadge ?? 'Managed by Google';

  String get offlineBadge => _l10n?.profileOfflineBadge ?? 'Offline';

  String get signedInToUploadError =>
      _l10n?.profileSignedInToUploadError ??
      'You need to be signed in to upload.';

  String get reconnectToUploadError =>
      _l10n?.profileReconnectToUploadError ??
      'Reconnect to upload a new photo.';

  String get readFileError =>
      _l10n?.profileReadFileError ?? 'Could not read the selected file.';

  String get fileTooLargeError =>
      _l10n?.profileFileTooLargeError ?? 'Please choose an image under 5 MB.';

  String get photoUpdatedMessage =>
      _l10n?.profilePhotoUpdatedMessage ??
      'Photo updated. Changes will auto-save.';

  String photoUploadFailedMessage(String error) =>
      _l10n?.profilePhotoUploadFailedMessage(error) ??
      'Photo upload failed: $error';

  String get signedInToSaveError =>
      _l10n?.profileSignedInToSaveError ?? 'You need to be signed in to save.';

  String get fixHighlightedFieldsError =>
      _l10n?.profileFixHighlightedFieldsError ??
      'Please fix the highlighted fields.';

  String get syncSuccessMessage =>
      _l10n?.profileSyncSuccessMessage ?? 'Profile synced across your devices.';

  String get syncOfflineMessage =>
      _l10n?.profileSyncOfflineMessage ??
      'Offline for now. We\'ll sync your profile when you reconnect.';

  String autoSaveFailedMessage(String error) =>
      _l10n?.profileAutoSaveFailedMessage(error) ?? 'Auto-save failed: $error';

  String saveFailedMessage(String error) =>
      _l10n?.profileSaveFailedMessage(error) ??
      'Failed to save profile: $error';
}

class _ProfileBackdrop extends StatelessWidget {
  const _ProfileBackdrop({
    required this.photoUrl,
    required this.name,
    required this.email,
    required this.onUseGooglePhoto,
    required this.isOffline,
    required this.canEditPhoto,
    required this.strings,
  });

  final String photoUrl;
  final String name;
  final String email;
  final VoidCallback onUseGooglePhoto;
  final bool isOffline;
  final bool canEditPhoto;
  final _ProfileStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ],
            ),
          ),
        ),
        if (photoUrl.isNotEmpty)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.primary.withValues(alpha: 0.25),
                  BlendMode.srcOver,
                ),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileAvatar(
                      photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
                      size: 84,
                      icon: Icons.person_rounded,
                      backgroundColor: theme.colorScheme.onPrimary.withValues(
                        alpha: 0.2,
                      ),
                      iconColor: theme.colorScheme.onPrimary,
                      borderColor: theme.colorScheme.onPrimary.withValues(
                        alpha: 0.45,
                      ),
                      borderWidth: 1.5,
                      semanticLabel: '$name profile avatar',
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? strings.backdropDefaultName : name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: canEditPhoto
                                    ? onUseGooglePhoto
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.surface
                                      .withValues(alpha: 0.9),
                                  foregroundColor:
                                      theme.colorScheme.onSurfaceVariant,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.cloud_download_rounded),
                                label: Text(strings.useGooglePhotoButton),
                              ),
                              if (!canEditPhoto)
                                Text(
                                  strings.managedByGoogleBadge,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              if (isOffline)
                                Chip(
                                  backgroundColor: theme.colorScheme.error,
                                  label: Text(
                                    strings.offlineBadge,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.onError,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  avatar: Icon(
                                    Icons.wifi_off_rounded,
                                    size: 18,
                                    color: theme.colorScheme.onError,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
