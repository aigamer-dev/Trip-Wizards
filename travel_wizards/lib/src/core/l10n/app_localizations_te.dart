// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'ట్రావెల్ విజార్డ్స్';

  @override
  String get searchPlaceholder => 'ట్రావెల్ విజార్డ్స్';

  @override
  String get menu => 'మెను';

  @override
  String get open => 'తెరవండి';

  @override
  String get explore => 'ఎక్స్ప్లోర్';

  @override
  String get home => 'హోమ్';

  @override
  String get settings => 'సెట్టింగ్స్';

  @override
  String get generationInProgress => 'జనరేషన్ ప్రోగ్రెస్‌లో ఉంది';

  @override
  String get ongoingTrips => 'జరుగుతున్న ప్రయాణాలు';

  @override
  String get plannedTrips => 'ప్లాన్ చేసిన ప్రయాణాలు';

  @override
  String get suggestedTrips => 'సూచించిన ప్రయాణాలు';

  @override
  String get addTrip => 'ప్రయాణాన్ని జోడించండి';

  @override
  String get themeMode => 'థీమ్ మోడ్';

  @override
  String get language => 'భాష';

  @override
  String get systemDefault => 'సిస్టమ్ డిఫాల్ట్';

  @override
  String get light => 'లైట్';

  @override
  String get dark => 'డార్క్';

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
  String get resultsFor => 'ఫలితాలు';

  @override
  String get filters => 'ఫిల్టర్లు';

  @override
  String get clearFilters => 'ఫిల్టర్‌లు క్లియర్ చేయండి';

  @override
  String get tagWeekend => 'వీకెండ్';

  @override
  String get tagAdventure => 'అడ్వెంచర్';

  @override
  String get tagBudget => 'బడ్జెట్';

  @override
  String get budgetLow => 'తక్కువ బడ్జెట్';

  @override
  String get budgetMedium => 'మధ్యస్థ బడ్జెట్';

  @override
  String get budgetHigh => 'అధిక బడ్జెట్';

  @override
  String get duration2to3 => '2–3 రోజులు';

  @override
  String get duration4to5 => '4–5 రోజులు';

  @override
  String get duration6plus => '6+ రోజులు';

  @override
  String get save => 'సేవ్ చేయండి';

  @override
  String get unsave => 'సేవ్ తొలగించండి';

  @override
  String get saveIdea => 'ఐడియాను సేవ్ చేయండి';

  @override
  String get unsaveIdea => 'ఐడియా సేవ్ తొలగించండి';

  @override
  String get savedToYourIdeas => 'మీ ఐడియాస్‌లో సేవ్ అయింది';

  @override
  String get removedFromYourIdeas => 'మీ ఐడియాస్ నుండి తొలగించబడింది';

  @override
  String get idea => 'ఐడియా';

  @override
  String ideaLabel(String title) {
    return 'ఐడియా: $title';
  }

  @override
  String get ideasFallbackToLocal =>
      'నెట్‌వర్క్ సమస్య: స్థానిక ఐడియాలు చూపిస్తున్నాం';

  @override
  String get retry => 'మళ్ళీ ప్రయత్నించండి';

  @override
  String get skip => 'దాటవేయండి';

  @override
  String stepProgress(int current, int total) {
    return 'మొత్తం $totalలో దశ $current';
  }

  @override
  String get welcomeToTravelWizards => 'ట్రావెల్ విజార్డ్స్‌కి స్వాగతం!';

  @override
  String get personalizeExperience =>
      'మీ అభిరుచులకు అనుగుణంగా మీ ప్రయాణ అనుభవాన్ని వ్యక్తిగతీకరిద్దాం.';

  @override
  String get aiPoweredTripPlanning => 'ఏఐ ఆధారిత ప్రయాణ ప్రణాళిక';

  @override
  String get personalizedRecommendations => 'వ్యక్తిగత సిఫార్సులు';

  @override
  String get collaborativeTripPlanning => 'సహకార ప్రయాణ ప్రణాళిక';

  @override
  String errorCompletingOnboarding(String error) {
    return 'ఆన్‌బోర్డింగ్ పూర్తి చేయడంలో లోపం: $error';
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
