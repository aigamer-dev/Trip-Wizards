// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'ट्रॅव्हल विझार्ड्स';

  @override
  String get searchPlaceholder => 'ट्रॅव्हल विझार्ड्स';

  @override
  String get menu => 'मेनू';

  @override
  String get open => 'उघडा';

  @override
  String get explore => 'एक्सप्लोर';

  @override
  String get home => 'होम';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get generationInProgress => 'जनरेशन प्रोग्रेसमध्ये';

  @override
  String get ongoingTrips => 'सुरू असलेली ट्रिप्स';

  @override
  String get plannedTrips => 'नियोजित ट्रिप्स';

  @override
  String get suggestedTrips => 'सूचित ट्रिप्स';

  @override
  String get addTrip => 'ट्रिप जोडा';

  @override
  String get themeMode => 'थीम मोड';

  @override
  String get language => 'भाषा';

  @override
  String get systemDefault => 'सिस्टम डिफॉल्ट';

  @override
  String get light => 'लाइट';

  @override
  String get dark => 'डार्क';

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
  String get resultsFor => 'यांचे परिणाम';

  @override
  String get filters => 'फिल्टर्स';

  @override
  String get clearFilters => 'फिल्टर्स साफ करा';

  @override
  String get tagWeekend => 'वीकेंड';

  @override
  String get tagAdventure => 'अ‍ॅडव्हेंचर';

  @override
  String get tagBudget => 'बजेट';

  @override
  String get budgetLow => 'कमी बजेट';

  @override
  String get budgetMedium => 'मध्यम बजेट';

  @override
  String get budgetHigh => 'जास्त बजेट';

  @override
  String get duration2to3 => '२–३ दिवस';

  @override
  String get duration4to5 => '४–५ दिवस';

  @override
  String get duration6plus => '६+ दिवस';

  @override
  String get save => 'सेव्ह करा';

  @override
  String get unsave => 'सेव्ह काढा';

  @override
  String get saveIdea => 'आयडिया सेव्ह करा';

  @override
  String get unsaveIdea => 'आयडिया सेव्ह काढा';

  @override
  String get savedToYourIdeas => 'तुमच्या आयडियात सेव्ह केले';

  @override
  String get removedFromYourIdeas => 'तुमच्या आयडियातून काढले';

  @override
  String get idea => 'आयडिया';

  @override
  String ideaLabel(String title) {
    return 'आयडिया: $title';
  }

  @override
  String get ideasFallbackToLocal =>
      'नेटवर्क समस्या: स्थानिक आयडिया दाखवत आहोत';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get skip => 'वगळा';

  @override
  String stepProgress(int current, int total) {
    return 'एकूण $total पैकी टप्पा $current';
  }

  @override
  String get welcomeToTravelWizards =>
      'ट्रॅव्हल विजार्ड्समध्ये आपले स्वागत आहे!';

  @override
  String get personalizeExperience =>
      'चला, तुमच्या आवडीनुसार तुमचा प्रवास अनुभव वैयक्तिक बनवूया.';

  @override
  String get aiPoweredTripPlanning => 'एआय-संचालित प्रवास नियोजन';

  @override
  String get personalizedRecommendations => 'वैयक्तिक शिफारसी';

  @override
  String get collaborativeTripPlanning => 'सहकार्याने प्रवास नियोजन';

  @override
  String errorCompletingOnboarding(String error) {
    return 'ऑनबोर्डिंग पूर्ण करताना त्रुटी: $error';
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
