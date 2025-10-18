// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'டிராவல் விசார்ட்ஸ்';

  @override
  String get searchPlaceholder => 'டிராவல் விசார்ட்ஸ்';

  @override
  String get menu => 'மெனு';

  @override
  String get open => 'திறக்க';

  @override
  String get explore => 'எக்ஸ்ப்ளோர்';

  @override
  String get home => 'முகப்பு';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get generationInProgress => 'தொகுப்பு நடைபெற்று கொண்டிருக்கிறது';

  @override
  String get ongoingTrips => 'நடைபெறும் பயணங்கள்';

  @override
  String get plannedTrips => 'திட்டமிட்ட பயணங்கள்';

  @override
  String get suggestedTrips => 'பரிந்துரைக்கப்பட்ட பயணங்கள்';

  @override
  String get addTrip => 'பயணத்தைச் சேர்க்கவும்';

  @override
  String get themeMode => 'தீம் முறை';

  @override
  String get language => 'மொழி';

  @override
  String get systemDefault => 'கணினி இயல்புநிலை';

  @override
  String get light => 'லைட்';

  @override
  String get dark => 'டார்க்';

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
  String get resultsFor => 'இதற்கான முடிவுகள்';

  @override
  String get filters => 'வடிப்பான்கள்';

  @override
  String get clearFilters => 'வடிப்பான்களை அழிக்கவும்';

  @override
  String get tagWeekend => 'வீக்கெண்ட்';

  @override
  String get tagAdventure => 'சாகசம்';

  @override
  String get tagBudget => 'பட்ஜெட்';

  @override
  String get budgetLow => 'குறைந்த பட்ஜெட்';

  @override
  String get budgetMedium => 'நடுத்தர பட்ஜெட்';

  @override
  String get budgetHigh => 'அதிக பட்ஜெட்';

  @override
  String get duration2to3 => '2–3 நாட்கள்';

  @override
  String get duration4to5 => '4–5 நாட்கள்';

  @override
  String get duration6plus => '6+ நாட்கள்';

  @override
  String get save => 'சேமிக்கவும்';

  @override
  String get unsave => 'சேமிப்பை நீக்கு';

  @override
  String get saveIdea => 'யோசனையை சேமிக்கவும்';

  @override
  String get unsaveIdea => 'யோசனை சேமிப்பை நீக்கு';

  @override
  String get savedToYourIdeas => 'உங்கள் யோசனைகளில் சேமிக்கப்பட்டது';

  @override
  String get removedFromYourIdeas => 'உங்கள் யோசனைகளில் இருந்து நீக்கப்பட்டது';

  @override
  String get idea => 'யோசனை';

  @override
  String ideaLabel(String title) {
    return 'யோசனை: $title';
  }

  @override
  String get ideasFallbackToLocal =>
      'நெட்வொர்க் சிக்கல்: உள்ளூர் யோசனைகள் காட்டப்படுகின்றன';

  @override
  String get retry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get skip => 'தவிர்';

  @override
  String stepProgress(int current, int total) {
    return 'மொத்தம் $total இல் படி $current';
  }

  @override
  String get welcomeToTravelWizards => 'ட்ராவல் விஸார்ட்ஸில் வரவேற்கிறோம்!';

  @override
  String get personalizeExperience =>
      'உங்கள் விருப்பங்களுக்கு ஏற்ப உங்கள் பயண அனுபவத்தை தனிப்பயனாக்கலாம்.';

  @override
  String get aiPoweredTripPlanning => 'ஏஐ இயக்கப்படும் பயண திட்டமிடல்';

  @override
  String get personalizedRecommendations => 'தனிப்பயன் பரிந்துரைகள்';

  @override
  String get collaborativeTripPlanning => 'குழுவோடு பயண திட்டமிடல்';

  @override
  String errorCompletingOnboarding(String error) {
    return 'ஆன்போர்டிங்கை முடிக்கும்போது பிழை: $error';
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
