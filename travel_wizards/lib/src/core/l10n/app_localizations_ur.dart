// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'ٹریول وزارڈز';

  @override
  String get searchPlaceholder => 'ٹریول وزارڈز';

  @override
  String get menu => 'مینیو';

  @override
  String get open => 'کھولیں';

  @override
  String get explore => 'ایکسپلور';

  @override
  String get home => 'ہوم';

  @override
  String get settings => 'سیٹنگز';

  @override
  String get generationInProgress => 'جنریشن جاری ہے';

  @override
  String get ongoingTrips => 'جاری سفر';

  @override
  String get plannedTrips => 'منصوبہ بند سفر';

  @override
  String get suggestedTrips => 'تجویز کردہ سفر';

  @override
  String get addTrip => 'سفر شامل کریں';

  @override
  String get themeMode => 'تھیم موڈ';

  @override
  String get language => 'زبان';

  @override
  String get systemDefault => 'سسٹم ڈیفالٹ';

  @override
  String get light => 'لائٹ';

  @override
  String get dark => 'ڈارک';

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
  String get resultsFor => 'کے نتائج';

  @override
  String get filters => 'فلٹرز';

  @override
  String get clearFilters => 'فلٹرز صاف کریں';

  @override
  String get tagWeekend => 'ویک اینڈ';

  @override
  String get tagAdventure => 'ایڈونچر';

  @override
  String get tagBudget => 'بجٹ';

  @override
  String get budgetLow => 'کم بجٹ';

  @override
  String get budgetMedium => 'درمیانہ بجٹ';

  @override
  String get budgetHigh => 'زیادہ بجٹ';

  @override
  String get duration2to3 => '2–3 دن';

  @override
  String get duration4to5 => '4–5 دن';

  @override
  String get duration6plus => '6+ دن';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get unsave => 'محفوظی ہٹائیں';

  @override
  String get saveIdea => 'آئیڈیا محفوظ کریں';

  @override
  String get unsaveIdea => 'آئیڈیا محفوظی ہٹائیں';

  @override
  String get savedToYourIdeas => 'آپ کے آئیڈیاز میں محفوظ ہوا';

  @override
  String get removedFromYourIdeas => 'آپ کے آئیڈیاز سے ہٹا دیا گیا';

  @override
  String get idea => 'آئیڈیا';

  @override
  String ideaLabel(String title) {
    return 'آئیڈیا: $title';
  }

  @override
  String get ideasFallbackToLocal =>
      'نیٹ ورک مسئلہ: مقامی آئیڈیاز دکھائے جا رہے ہیں';

  @override
  String get retry => 'دوبارہ کوشش کریں';

  @override
  String get skip => 'چھوڑ دیں';

  @override
  String stepProgress(int current, int total) {
    return 'مرحلہ $current از $total';
  }

  @override
  String get welcomeToTravelWizards => 'ٹریول وزارڈز میں خوش آمدید!';

  @override
  String get personalizeExperience =>
      'آئیے آپ کی پسند کے مطابق آپ کے سفر کے تجربے کو ذاتی بنائیں۔';

  @override
  String get aiPoweredTripPlanning => 'اے آئی سے چلنے والی سفر کی منصوبہ بندی';

  @override
  String get personalizedRecommendations => 'ذاتی سفارشات';

  @override
  String get collaborativeTripPlanning => 'مشترکہ سفر کی منصوبہ بندی';

  @override
  String errorCompletingOnboarding(String error) {
    return 'آن بورڈنگ مکمل کرنے میں خرابی: $error';
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
