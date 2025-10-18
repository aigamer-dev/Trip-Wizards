// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appTitle => 'ട്രാവൽ വിസാർഡ്സ്';

  @override
  String get searchPlaceholder => 'ട്രാവൽ വിസാർഡ്സ്';

  @override
  String get menu => 'മെനു';

  @override
  String get open => 'തുറക്കുക';

  @override
  String get explore => 'എക്‌സ്‌പ്ലോർ';

  @override
  String get home => 'ഹോം';

  @override
  String get settings => 'ക്രമീകരണങ്ങൾ';

  @override
  String get generationInProgress => 'ജനറേഷൻ പുരോഗമിക്കുന്നു';

  @override
  String get ongoingTrips => 'ഓൺഗോയിംഗ് യാത്രകൾ';

  @override
  String get plannedTrips => 'പ്ലാൻ ചെയ്ത യാത്രകൾ';

  @override
  String get suggestedTrips => 'ശുപാർശ ചെയ്യുന്ന യാത്രകൾ';

  @override
  String get addTrip => 'യാത്ര ചേർക്കുക';

  @override
  String get themeMode => 'തീം മോഡ്';

  @override
  String get language => 'ഭാഷ';

  @override
  String get systemDefault => 'സിസ്റ്റം ഡീഫോൾട്ട്';

  @override
  String get light => 'ലൈറ്റ്';

  @override
  String get dark => 'ഡാർക്ക്';

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
  String get resultsFor => 'ഫലം';

  @override
  String get filters => 'ഫിൽറ്ററുകൾ';

  @override
  String get clearFilters => 'ഫിൽറ്ററുകൾ നീക്കംചെയ്യുക';

  @override
  String get tagWeekend => 'വീക്കൻഡ്';

  @override
  String get tagAdventure => 'അഡ്വെഞ്ചർ';

  @override
  String get tagBudget => 'ബജറ്റ്';

  @override
  String get budgetLow => 'കുറഞ്ഞ ബജറ്റ്';

  @override
  String get budgetMedium => 'ഇടത്തരം ബജറ്റ്';

  @override
  String get budgetHigh => 'ഉയർന്ന ബജറ്റ്';

  @override
  String get duration2to3 => '2–3 ദിവസം';

  @override
  String get duration4to5 => '4–5 ദിവസം';

  @override
  String get duration6plus => '6+ ദിവസം';

  @override
  String get save => 'സേവ് ചെയ്യുക';

  @override
  String get unsave => 'സേവ് നീക്കംചെയ്യുക';

  @override
  String get saveIdea => 'ഐഡിയ സേവ് ചെയ്യുക';

  @override
  String get unsaveIdea => 'ഐഡിയ സേവ് നീക്കംചെയ്യുക';

  @override
  String get savedToYourIdeas => 'നിങ്ങളുടെ ഐഡിയാസിൽ സേവ് ചെയ്തു';

  @override
  String get removedFromYourIdeas => 'നിങ്ങളുടെ ഐഡിയാസിൽ നിന്ന് നീക്കം ചെയ്തു';

  @override
  String get idea => 'ഐഡിയ';

  @override
  String ideaLabel(String title) {
    return 'ഐഡിയ: $title';
  }

  @override
  String get ideasFallbackToLocal =>
      'നെറ്റ്‌വർക്ക് പ്രശ്നം: പ്രാദേശിക ആശയങ്ങൾ കാണിക്കുന്നു';

  @override
  String get retry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get skip => 'സ്കിപ്പ് ചെയ്യുക';

  @override
  String stepProgress(int current, int total) {
    return 'ആകെ $total ഘട്ടങ്ങളിൽ $currentാം ഘട്ടം';
  }

  @override
  String get welcomeToTravelWizards => 'ട്രാവൽ വിസാർഡ്സിലേക്ക് സ്വാഗതം!';

  @override
  String get personalizeExperience =>
      'നിങ്ങളുടെ ഇഷ്ടങ്ങളെ അടിസ്ഥാനമാക്കി നിങ്ങളുടെ യാത്രാനുഭവം വ്യക്തിഗതമാക്കാം.';

  @override
  String get aiPoweredTripPlanning => 'എ.ഐ. അധിഷ്ഠിത യാത്രാ പദ്ധതിയിടൽ';

  @override
  String get personalizedRecommendations => 'വ്യക്തിഗത നിർദ്ദേശങ്ങൾ';

  @override
  String get collaborativeTripPlanning => 'സഹകരിച്ചുള്ള യാത്രാ പദ്ധതിയിടൽ';

  @override
  String errorCompletingOnboarding(String error) {
    return 'ഓൺബോർഡിംഗ് പൂർത്തിയാക്കുമ്പോൾ പിശക്: $error';
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
