// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oriya (`or`).
class AppLocalizationsOr extends AppLocalizations {
  AppLocalizationsOr([String locale = 'or']) : super(locale);

  @override
  String get appTitle => 'ଟ୍ରାଭେଲ୍ ୱିଜାର୍ଡସ୍';

  @override
  String get searchPlaceholder => 'ଟ୍ରାଭେଲ୍ ୱିଜାର୍ଡସ୍';

  @override
  String get menu => 'ମେନୁ';

  @override
  String get open => 'ଖୋଲନ୍ତୁ';

  @override
  String get explore => 'ଏକ୍ସପ୍ଲୋର୍';

  @override
  String get home => 'ମୂଳ ପୃଷ୍ଠା';

  @override
  String get settings => 'ସେଟିଙ୍ଗ୍ସ';

  @override
  String get generationInProgress => 'ଜେନରେସନ୍ ଚାଲିଛି';

  @override
  String get ongoingTrips => 'ଚାଲୁ ଯାତ୍ରା';

  @override
  String get plannedTrips => 'ଯୋଜିତ ଯାତ୍ରା';

  @override
  String get suggestedTrips => 'ପ୍ରସ୍ତାବିତ ଯାତ୍ରା';

  @override
  String get addTrip => 'ଯାତ୍ରା ଯୋଗ କରନ୍ତୁ';

  @override
  String get themeMode => 'ଥିମ୍ ମୋଡ୍';

  @override
  String get language => 'ଭାଷା';

  @override
  String get systemDefault => 'ସିଷ୍ଟମ୍ ଡିଫଲ୍ଟ';

  @override
  String get light => 'ଲାଇଟ୍';

  @override
  String get dark => 'ଡାର୍କ୍';

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
  String get resultsFor => 'ଫଳାଫଳ';

  @override
  String get filters => 'ଫିଲ୍ଟର୍ସ';

  @override
  String get clearFilters => 'ଫିଲ୍ଟର୍ସ କ୍ଲିୟାର୍ କରନ୍ତୁ';

  @override
  String get tagWeekend => 'ସପ୍ତାହାନ୍ତ';

  @override
  String get tagAdventure => 'ଅଭିଯାନ';

  @override
  String get tagBudget => 'ବଜେଟ୍';

  @override
  String get budgetLow => 'କମ୍ ବଜେଟ୍';

  @override
  String get budgetMedium => 'ମଧ୍ୟମ ବଜେଟ୍';

  @override
  String get budgetHigh => 'ଉଚ୍ଚ ବଜେଟ୍';

  @override
  String get duration2to3 => '2–3 ଦିନ';

  @override
  String get duration4to5 => '4–5 ଦିନ';

  @override
  String get duration6plus => '6+ ଦିନ';

  @override
  String get save => 'ସେଭ୍ କରନ୍ତୁ';

  @override
  String get unsave => 'ସେଭ୍ ହଟାନ୍ତୁ';

  @override
  String get saveIdea => 'ଆଇଡିଆ ସେଭ୍ କରନ୍ତୁ';

  @override
  String get unsaveIdea => 'ଆଇଡିଆ ସେଭ୍ ହଟାନ୍ତୁ';

  @override
  String get savedToYourIdeas => 'ଆପଣଙ୍କ ଆଇଡିଆରେ ସେଭ୍ ହେଲା';

  @override
  String get removedFromYourIdeas => 'ଆପଣଙ୍କ ଆଇଡିଆରୁ ହଟାଯାଇଛି';

  @override
  String get idea => 'ଆଇଡିଆ';

  @override
  String ideaLabel(String title) {
    return 'ଆଇଡିଆ: $title';
  }

  @override
  String get ideasFallbackToLocal => 'ନେଟୱର୍କ ସମସ୍ୟା: ସ୍ଥାନୀୟ ଆଇଡିଆ ଦେଖାଯାଉଛି';

  @override
  String get retry => 'ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ';

  @override
  String get skip => 'ଏଡ଼ାଇବେ';

  @override
  String stepProgress(int current, int total) {
    return 'ମୋଟ $total ମଧ୍ୟରୁ ପଦକ୍ଷେପ $current';
  }

  @override
  String get welcomeToTravelWizards => 'ଟ୍ରାଭେଲ୍ ୱିଜାର୍ଡସ୍‌କୁ ସ୍ୱାଗତ!';

  @override
  String get personalizeExperience =>
      'ଆସନ୍ତୁ, ଆପଣଙ୍କ ପସନ୍ଦ ଅନୁଯାୟୀ ଭ୍ରମଣ ଅନୁଭବକୁ ବ୍ୟକ୍ତିଗତ କରିଦେଉ।';

  @override
  String get aiPoweredTripPlanning => 'ଏଆଇ ଦ୍ୱାରା ସଂଚାଳିତ ଭ୍ରମଣ ଯୋଜନା';

  @override
  String get personalizedRecommendations => 'ବ୍ୟକ୍ତିଗତ ସୁପାରିଶ';

  @override
  String get collaborativeTripPlanning => 'ସହଯୋଗୀ ଭ୍ରମଣ ଯୋଜନା';

  @override
  String errorCompletingOnboarding(String error) {
    return 'ଅନବୋର୍ଡିଙ୍ଗ ପୂରା କରିବା ସମୟରେ ତ୍ରୁଟି: $error';
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
