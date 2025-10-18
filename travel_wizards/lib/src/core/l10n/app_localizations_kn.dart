// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get appTitle => 'ಟ್ರಾವೆಲ್ ವಿಜಾರ್ಡ್ಸ್';

  @override
  String get searchPlaceholder => 'ಟ್ರಾವೆಲ್ ವಿಜಾರ್ಡ್ಸ್';

  @override
  String get menu => 'ಮೆನು';

  @override
  String get open => 'ತೆರೆಯಿರಿ';

  @override
  String get explore => 'ಎಕ್ಸ್‌ಪ್ಲೋರ್';

  @override
  String get home => 'ಮನೆ';

  @override
  String get settings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get generationInProgress => 'ಜನರೇಷನ್ ಪ್ರಗತಿಯಲ್ಲಿ';

  @override
  String get ongoingTrips => 'ನಡೆಯುತ್ತಿರುವ ಪ್ರಯಾಣಗಳು';

  @override
  String get plannedTrips => 'ಯೋಜಿತ ಪ್ರಯಾಣಗಳು';

  @override
  String get suggestedTrips => 'ಸೂಚಿಸಲಾದ ಪ್ರಯಾಣಗಳು';

  @override
  String get addTrip => 'ಪ್ರಯಾಣವನ್ನು ಸೇರಿಸಿ';

  @override
  String get themeMode => 'ಥೀಮ್ ಮೋಡ್';

  @override
  String get language => 'ಭಾಷೆ';

  @override
  String get systemDefault => 'ಸಿಸ್ಟಮ್ ಡೀಫಾಲ್ಟ್';

  @override
  String get light => 'ಲೈಟ್';

  @override
  String get dark => 'ಡಾರ್ಕ್';

  @override
  String get languageSelectionIntro =>
      'Choose your preferred app language. Native Indian languages are localised while others use Google Translate instantly.';

  @override
  String get languageSearchHint => 'Search languages';

  @override
  String get languageEmptyState => 'No languages match your search yet.';

  @override
  String languageSetupMessage(String languageName) {
    return 'Setting up $languageName...';
  }

  @override
  String languageChangedNative(String languageName) {
    return 'Language changed to $languageName';
  }

  @override
  String languageChangedTranslated(String languageName) {
    return 'Language changed to $languageName (Google Translate)';
  }

  @override
  String get done => 'Done';

  @override
  String get languageManageTitle => 'Manage your app language globally';

  @override
  String get languageManageDescription =>
      'Choose your preferred language from Settings → Language and we\'ll apply it everywhere.';

  @override
  String get languageManageCta => 'Open language settings';

  @override
  String get resultsFor => 'ಫಲಿತಾಂಶಗಳು';

  @override
  String get filters => 'ಫಿಲ್ಟರ್‌ಗಳು';

  @override
  String get clearFilters => 'ಫಿಲ್ಟರ್‌ಗಳನ್ನು ತೆರವುಗೊಳಿಸಿ';

  @override
  String get tagWeekend => 'ವೀಕೆಂಡ್';

  @override
  String get tagAdventure => 'ಸಾಹಸ';

  @override
  String get tagBudget => 'ಬಜೆಟ್';

  @override
  String get budgetLow => 'ಕಡಿಮೆ ಬಜೆಟ್';

  @override
  String get budgetMedium => 'ಮಧ್ಯಮ ಬಜೆಟ್';

  @override
  String get budgetHigh => 'ಹೆಚ್ಚು ಬಜೆಟ್';

  @override
  String get duration2to3 => '2–3 ದಿನಗಳು';

  @override
  String get duration4to5 => '4–5 ದಿನಗಳು';

  @override
  String get duration6plus => '6+ ದಿನಗಳು';

  @override
  String get save => 'ಸೇವ್ ಮಾಡಿ';

  @override
  String get unsave => 'ಸೇವ್ ತೆಗೆದುಹಾಕಿ';

  @override
  String get saveIdea => 'ಆಲೋಚನೆಯನ್ನು ಸೇವ್ ಮಾಡಿ';

  @override
  String get unsaveIdea => 'ಆಲೋಚನೆ ಸೇವ್ ತೆಗೆದುಹಾಕಿ';

  @override
  String get savedToYourIdeas => 'ನಿಮ್ಮ ಆಲೋಚನೆಗಳಲ್ಲಿ ಸೇವ್ ಮಾಡಲಾಗಿದೆ';

  @override
  String get removedFromYourIdeas => 'ನಿಮ್ಮ ಆಲೋಚನೆಗಳಿಂದ ತೆಗೆದುಹಾಕಲಾಗಿದೆ';

  @override
  String get idea => 'ಆಲೋಚನೆ';

  @override
  String ideaLabel(String title) {
    return 'ಆಲೋಚನೆ: $title';
  }

  @override
  String get ideasFallbackToLocal =>
      'ನೆಟ್‌ವರ್ಕ್ ಸಮಸ್ಯೆ: ಸ್ಥಳೀಯ ಆಲೋಚನೆಗಳನ್ನು ತೋರಿಸಲಾಗುತ್ತಿದೆ';

  @override
  String get retry => 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ';

  @override
  String get skip => 'ಬಿಟ್ಟುಬಿಡಿ';

  @override
  String stepProgress(int current, int total) {
    return 'ಒಟ್ಟು $totalರಲ್ಲಿ ಹಂತ $current';
  }

  @override
  String get welcomeToTravelWizards => 'ಟ್ರಾವೆಲ್ ವಿಸರ್ಡ್ಸ್‌ಗೆ ಸ್ವಾಗತ!';

  @override
  String get personalizeExperience =>
      'ನಿಮ್ಮ ಆಯ್ಕೆಗಳ ಆಧಾರದ ಮೇಲೆ ನಿಮ್ಮ ಪ್ರವಾಸ ಅನುಭವವನ್ನು ವೈಯಕ್ತಿಕಗೊಳಿಸೋಣ.';

  @override
  String get aiPoweredTripPlanning => 'ಎಐ ಚಾಲಿತ ಪ್ರವಾಸ ಯೋಜನೆ';

  @override
  String get personalizedRecommendations => 'ವೈಯಕ್ತಿಕ ಶಿಫಾರಸುಗಳು';

  @override
  String get collaborativeTripPlanning => 'ಸಹಯೋಗದ ಪ್ರವಾಸ ಯೋಜನೆ';

  @override
  String errorCompletingOnboarding(String error) {
    return 'ಆನ್‌ಬೋರ್ಡಿಂಗ್ ಪೂರ್ಣಗೊಳಿಸುವಲ್ಲಿ ದೋಷ: $error';
  }

  @override
  String get profileOfflineTitle => 'Offline mode';

  @override
  String get profileOfflineDescription =>
      'We\'ll sync your changes as soon as you reconnect. You can keep editing safely.';

  @override
  String get profileDiscardEditsLabel => 'Discard edits';

  @override
  String get profileAccountBasicsTitle => 'Account basics';

  @override
  String get profileAccountBasicsSubtitle =>
      'These details power personalised suggestions and shared trip experiences.';

  @override
  String get profileFullNameLabel => 'Full name';

  @override
  String get profileUsernameLabel => 'Username';

  @override
  String get profileUsernameHelper =>
      'Used for public sharing links and concierge assistance';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileGenderLabel => 'Gender';

  @override
  String get profileGenderOptionPreferNot => 'Prefer not to say';

  @override
  String get profileGenderOptionMale => 'Male';

  @override
  String get profileGenderOptionFemale => 'Female';

  @override
  String get profileGenderOptionOther => 'Other';

  @override
  String get profileDobLabel => 'Date of birth';

  @override
  String get profileDobHint => 'YYYY-MM-DD';

  @override
  String get profileDobFormatError => 'Use the format YYYY-MM-DD';

  @override
  String get profileGoogleManagedNotice =>
      'These details come from your Google account. Email support@travelwizards.com if they need updating.';

  @override
  String get profileHomeTitle => 'Where you call home';

  @override
  String get profileHomeSubtitle =>
      'Let us tailor weather alerts and concierge tips around your go-to destinations.';

  @override
  String get profileCountryLabel => 'Country';

  @override
  String get profileStateLabel => 'State / Region';

  @override
  String get profileCityLabel => 'City';

  @override
  String get profileTasteTitle => 'Taste & care';

  @override
  String get profileTasteSubtitle =>
      'We use this to highlight dining you\'ll love and avoid things you can\'t have.';

  @override
  String get profileFoodPrefsLabel => 'Food preferences';

  @override
  String get profileFoodPrefsHelper =>
      'Comma-separated (e.g. Vegan, Nut-free, Farm-to-table)';

  @override
  String get profileAllergiesLabel => 'Allergies / notes';

  @override
  String get profilePhotoSectionTitle => 'Profile photo';

  @override
  String get profilePhotoGuidance =>
      'Use a high-quality square image for best results.';

  @override
  String get profileUploadPhotoButton => 'Upload new photo';

  @override
  String get profileUseGooglePhotoButton => 'Use Google photo';

  @override
  String get profileRemovePhotoButton => 'Remove photo';

  @override
  String get profileOfflinePhotoWarning =>
      'You\'re offline. Reconnect to upload a new photo.';

  @override
  String get profilePhotoManagedNotice =>
      'Profile photos for Google sign-ins must be updated from your Google Account. We\'ll mirror updates automatically.';

  @override
  String get profileDiscardChangesLabel => 'Discard changes';

  @override
  String profileLastSavedAtLabel(String time) {
    return 'Last saved at $time';
  }

  @override
  String get profileCacheMessage =>
      'Your profile is cached for offline access and synchronises as soon as you reconnect.';

  @override
  String get profileSaveTooltipPending => 'Save profile updates';

  @override
  String get profileSaveTooltipSaved => 'All changes saved';

  @override
  String get profilePageTitle => 'Profile';

  @override
  String get profileBackdropDefaultName => 'Your profile';

  @override
  String get profileManagedByGoogleBadge => 'Managed by Google';

  @override
  String get profileOfflineBadge => 'Offline';

  @override
  String get profileSignedInToUploadError =>
      'You need to be signed in to upload.';

  @override
  String get profileReconnectToUploadError =>
      'Reconnect to upload a new photo.';

  @override
  String get profileReadFileError => 'Could not read the selected file.';

  @override
  String get profileFileTooLargeError => 'Please choose an image under 5 MB.';

  @override
  String get profilePhotoUpdatedMessage =>
      'Photo updated. Changes will auto-save.';

  @override
  String profilePhotoUploadFailedMessage(String error) {
    return 'Photo upload failed: $error';
  }

  @override
  String get profileSignedInToSaveError => 'You need to be signed in to save.';

  @override
  String get profileFixHighlightedFieldsError =>
      'Please fix the highlighted fields.';

  @override
  String get profileSyncSuccessMessage => 'Profile synced across your devices.';

  @override
  String get profileSyncOfflineMessage =>
      'Offline for now. We\'ll sync your profile when you reconnect.';

  @override
  String profileAutoSaveFailedMessage(String error) {
    return 'Auto-save failed: $error';
  }

  @override
  String profileSaveFailedMessage(String error) {
    return 'Failed to save profile: $error';
  }

  @override
  String get profileRevertedChangesMessage => 'Reverted unsaved changes.';

  @override
  String profileFieldRequired(String fieldName) {
    return '$fieldName is required';
  }

  @override
  String get profileUsernameTooShort => 'At least 3 characters';

  @override
  String get profileUsernameInvalid =>
      'Only letters, numbers, underscores or dots';

  @override
  String get profileEmailInvalid => 'Enter a valid email address';
}
