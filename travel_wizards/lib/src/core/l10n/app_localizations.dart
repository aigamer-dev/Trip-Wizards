import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('bn'),
    Locale('te'),
    Locale('mr'),
    Locale('ta'),
    Locale('ur'),
    Locale('gu'),
    Locale('ml'),
    Locale('kn'),
    Locale('or'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Wizards'**
  String get appTitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Travel Wizards'**
  String get searchPlaceholder;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @generationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Generation In Progress'**
  String get generationInProgress;

  /// No description provided for @ongoingTrips.
  ///
  /// In en, this message translates to:
  /// **'Ongoing Trips'**
  String get ongoingTrips;

  /// No description provided for @plannedTrips.
  ///
  /// In en, this message translates to:
  /// **'Planned Trips'**
  String get plannedTrips;

  /// No description provided for @suggestedTrips.
  ///
  /// In en, this message translates to:
  /// **'Suggested Trips'**
  String get suggestedTrips;

  /// No description provided for @addTrip.
  ///
  /// In en, this message translates to:
  /// **'Add Trip'**
  String get addTrip;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @languageSelectionIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred app language. Native Indian languages are localised while others use Google Translate instantly.'**
  String get languageSelectionIntro;

  /// No description provided for @languageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get languageSearchHint;

  /// No description provided for @languageEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No languages match your search yet.'**
  String get languageEmptyState;

  /// No description provided for @languageSetupMessage.
  ///
  /// In en, this message translates to:
  /// **'Setting up {languageName}...'**
  String languageSetupMessage(String languageName);

  /// No description provided for @languageChangedNative.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {languageName}'**
  String languageChangedNative(String languageName);

  /// No description provided for @languageChangedTranslated.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {languageName} (Google Translate)'**
  String languageChangedTranslated(String languageName);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @languageManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your app language globally'**
  String get languageManageTitle;

  /// No description provided for @languageManageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language from Settings → Language and we\'ll apply it everywhere.'**
  String get languageManageDescription;

  /// No description provided for @languageManageCta.
  ///
  /// In en, this message translates to:
  /// **'Open language settings'**
  String get languageManageCta;

  /// No description provided for @resultsFor.
  ///
  /// In en, this message translates to:
  /// **'Results for'**
  String get resultsFor;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @tagWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get tagWeekend;

  /// No description provided for @tagAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get tagAdventure;

  /// No description provided for @tagBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get tagBudget;

  /// No description provided for @budgetLow.
  ///
  /// In en, this message translates to:
  /// **'Low budget'**
  String get budgetLow;

  /// No description provided for @budgetMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium budget'**
  String get budgetMedium;

  /// No description provided for @budgetHigh.
  ///
  /// In en, this message translates to:
  /// **'High budget'**
  String get budgetHigh;

  /// No description provided for @duration2to3.
  ///
  /// In en, this message translates to:
  /// **'2–3 days'**
  String get duration2to3;

  /// No description provided for @duration4to5.
  ///
  /// In en, this message translates to:
  /// **'4–5 days'**
  String get duration4to5;

  /// No description provided for @duration6plus.
  ///
  /// In en, this message translates to:
  /// **'6+ days'**
  String get duration6plus;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @unsave.
  ///
  /// In en, this message translates to:
  /// **'Unsave'**
  String get unsave;

  /// No description provided for @saveIdea.
  ///
  /// In en, this message translates to:
  /// **'Save idea'**
  String get saveIdea;

  /// No description provided for @unsaveIdea.
  ///
  /// In en, this message translates to:
  /// **'Unsave idea'**
  String get unsaveIdea;

  /// No description provided for @savedToYourIdeas.
  ///
  /// In en, this message translates to:
  /// **'Saved to your ideas'**
  String get savedToYourIdeas;

  /// No description provided for @removedFromYourIdeas.
  ///
  /// In en, this message translates to:
  /// **'Removed from your ideas'**
  String get removedFromYourIdeas;

  /// No description provided for @idea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get idea;

  /// No description provided for @ideaLabel.
  ///
  /// In en, this message translates to:
  /// **'Idea: {title}'**
  String ideaLabel(String title);

  /// No description provided for @ideasFallbackToLocal.
  ///
  /// In en, this message translates to:
  /// **'Network issue: showing local ideas'**
  String get ideasFallbackToLocal;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepProgress(int current, int total);

  /// No description provided for @welcomeToTravelWizards.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Travel Wizards!'**
  String get welcomeToTravelWizards;

  /// No description provided for @personalizeExperience.
  ///
  /// In en, this message translates to:
  /// **'Let\'s personalize your travel experience by learning about your preferences.'**
  String get personalizeExperience;

  /// No description provided for @aiPoweredTripPlanning.
  ///
  /// In en, this message translates to:
  /// **'AI-powered trip planning'**
  String get aiPoweredTripPlanning;

  /// No description provided for @personalizedRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Personalized recommendations'**
  String get personalizedRecommendations;

  /// No description provided for @collaborativeTripPlanning.
  ///
  /// In en, this message translates to:
  /// **'Collaborative trip planning'**
  String get collaborativeTripPlanning;

  /// No description provided for @errorCompletingOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Error completing onboarding: {error}'**
  String errorCompletingOnboarding(String error);

  /// No description provided for @profileOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get profileOfflineTitle;

  /// No description provided for @profileOfflineDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll sync your changes as soon as you reconnect. You can keep editing safely.'**
  String get profileOfflineDescription;

  /// No description provided for @profileDiscardEditsLabel.
  ///
  /// In en, this message translates to:
  /// **'Discard edits'**
  String get profileDiscardEditsLabel;

  /// No description provided for @profileAccountBasicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account basics'**
  String get profileAccountBasicsTitle;

  /// No description provided for @profileAccountBasicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These details power personalised suggestions and shared trip experiences.'**
  String get profileAccountBasicsSubtitle;

  /// No description provided for @profileFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullNameLabel;

  /// No description provided for @profileUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileUsernameLabel;

  /// No description provided for @profileUsernameHelper.
  ///
  /// In en, this message translates to:
  /// **'Used for public sharing links and concierge assistance'**
  String get profileUsernameHelper;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGenderLabel;

  /// No description provided for @profileGenderOptionPreferNot.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get profileGenderOptionPreferNot;

  /// No description provided for @profileGenderOptionMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profileGenderOptionMale;

  /// No description provided for @profileGenderOptionFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profileGenderOptionFemale;

  /// No description provided for @profileGenderOptionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileGenderOptionOther;

  /// No description provided for @profileDobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileDobLabel;

  /// No description provided for @profileDobHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get profileDobHint;

  /// No description provided for @profileDobFormatError.
  ///
  /// In en, this message translates to:
  /// **'Use the format YYYY-MM-DD'**
  String get profileDobFormatError;

  /// No description provided for @profileGoogleManagedNotice.
  ///
  /// In en, this message translates to:
  /// **'These details come from your Google account. Email support@travelwizards.com if they need updating.'**
  String get profileGoogleManagedNotice;

  /// No description provided for @profileHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Where you call home'**
  String get profileHomeTitle;

  /// No description provided for @profileHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let us tailor weather alerts and concierge tips around your go-to destinations.'**
  String get profileHomeSubtitle;

  /// No description provided for @profileCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get profileCountryLabel;

  /// No description provided for @profileStateLabel.
  ///
  /// In en, this message translates to:
  /// **'State / Region'**
  String get profileStateLabel;

  /// No description provided for @profileCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCityLabel;

  /// No description provided for @profileTasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Taste & care'**
  String get profileTasteTitle;

  /// No description provided for @profileTasteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use this to highlight dining you\'ll love and avoid things you can\'t have.'**
  String get profileTasteSubtitle;

  /// No description provided for @profileFoodPrefsLabel.
  ///
  /// In en, this message translates to:
  /// **'Food preferences'**
  String get profileFoodPrefsLabel;

  /// No description provided for @profileFoodPrefsHelper.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated (e.g. Vegan, Nut-free, Farm-to-table)'**
  String get profileFoodPrefsHelper;

  /// No description provided for @profileAllergiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allergies / notes'**
  String get profileAllergiesLabel;

  /// No description provided for @profilePhotoSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhotoSectionTitle;

  /// No description provided for @profilePhotoGuidance.
  ///
  /// In en, this message translates to:
  /// **'Use a high-quality square image for best results.'**
  String get profilePhotoGuidance;

  /// No description provided for @profileUploadPhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Upload new photo'**
  String get profileUploadPhotoButton;

  /// No description provided for @profileUseGooglePhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Use Google photo'**
  String get profileUseGooglePhotoButton;

  /// No description provided for @profileRemovePhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profileRemovePhotoButton;

  /// No description provided for @profileOfflinePhotoWarning.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Reconnect to upload a new photo.'**
  String get profileOfflinePhotoWarning;

  /// No description provided for @profilePhotoManagedNotice.
  ///
  /// In en, this message translates to:
  /// **'Profile photos for Google sign-ins must be updated from your Google Account. We\'ll mirror updates automatically.'**
  String get profilePhotoManagedNotice;

  /// No description provided for @profileDiscardChangesLabel.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get profileDiscardChangesLabel;

  /// No description provided for @profileLastSavedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Last saved at {time}'**
  String profileLastSavedAtLabel(String time);

  /// No description provided for @profileCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'Your profile is cached for offline access and synchronises as soon as you reconnect.'**
  String get profileCacheMessage;

  /// No description provided for @profileSaveTooltipPending.
  ///
  /// In en, this message translates to:
  /// **'Save profile updates'**
  String get profileSaveTooltipPending;

  /// No description provided for @profileSaveTooltipSaved.
  ///
  /// In en, this message translates to:
  /// **'All changes saved'**
  String get profileSaveTooltipSaved;

  /// No description provided for @profilePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profilePageTitle;

  /// No description provided for @profileBackdropDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileBackdropDefaultName;

  /// No description provided for @profileManagedByGoogleBadge.
  ///
  /// In en, this message translates to:
  /// **'Managed by Google'**
  String get profileManagedByGoogleBadge;

  /// No description provided for @profileOfflineBadge.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get profileOfflineBadge;

  /// No description provided for @profileSignedInToUploadError.
  ///
  /// In en, this message translates to:
  /// **'You need to be signed in to upload.'**
  String get profileSignedInToUploadError;

  /// No description provided for @profileReconnectToUploadError.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to upload a new photo.'**
  String get profileReconnectToUploadError;

  /// No description provided for @profileReadFileError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected file.'**
  String get profileReadFileError;

  /// No description provided for @profileFileTooLargeError.
  ///
  /// In en, this message translates to:
  /// **'Please choose an image under 5 MB.'**
  String get profileFileTooLargeError;

  /// No description provided for @profilePhotoUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Photo updated. Changes will auto-save.'**
  String get profilePhotoUpdatedMessage;

  /// No description provided for @profilePhotoUploadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed: {error}'**
  String profilePhotoUploadFailedMessage(String error);

  /// No description provided for @profileSignedInToSaveError.
  ///
  /// In en, this message translates to:
  /// **'You need to be signed in to save.'**
  String get profileSignedInToSaveError;

  /// No description provided for @profileFixHighlightedFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields.'**
  String get profileFixHighlightedFieldsError;

  /// No description provided for @profileSyncSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile synced across your devices.'**
  String get profileSyncSuccessMessage;

  /// No description provided for @profileSyncOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Offline for now. We\'ll sync your profile when you reconnect.'**
  String get profileSyncOfflineMessage;

  /// No description provided for @profileAutoSaveFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Auto-save failed: {error}'**
  String profileAutoSaveFailedMessage(String error);

  /// No description provided for @profileSaveFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile: {error}'**
  String profileSaveFailedMessage(String error);

  /// No description provided for @profileRevertedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Reverted unsaved changes.'**
  String get profileRevertedChangesMessage;

  /// No description provided for @profileFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is required'**
  String profileFieldRequired(String fieldName);

  /// No description provided for @profileUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters'**
  String get profileUsernameTooShort;

  /// No description provided for @profileUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, underscores or dots'**
  String get profileUsernameInvalid;

  /// No description provided for @profileEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get profileEmailInvalid;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'gu',
    'hi',
    'kn',
    'ml',
    'mr',
    'or',
    'ta',
    'te',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
