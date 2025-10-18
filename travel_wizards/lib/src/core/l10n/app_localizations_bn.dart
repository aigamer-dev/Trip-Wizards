// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'ট্রাভেল উইজার্ডস';

  @override
  String get searchPlaceholder => 'ট্রাভেল উইজার্ডস';

  @override
  String get menu => 'মেনু';

  @override
  String get open => 'খুলুন';

  @override
  String get explore => 'এক্সপ্লোর';

  @override
  String get home => 'হোম';

  @override
  String get settings => 'সেটিংস';

  @override
  String get generationInProgress => 'জেনারেশন প্রগ্রেসে';

  @override
  String get ongoingTrips => 'চলমান ভ্রমণ';

  @override
  String get plannedTrips => 'পরিকল্পিত ভ্রমণ';

  @override
  String get suggestedTrips => 'প্রস্তাবিত ভ্রমণ';

  @override
  String get addTrip => 'ভ্রমণ যোগ করুন';

  @override
  String get themeMode => 'থিম মোড';

  @override
  String get language => 'ভাষা';

  @override
  String get systemDefault => 'সিস্টেম ডিফল্ট';

  @override
  String get light => 'লাইট';

  @override
  String get dark => 'ডার্ক';

  @override
  String get languageSelectionIntro =>
      'অ্যাপের জন্য আপনার পছন্দের ভাষা বেছে নিন। দেশীয় ভারতীয় ভাষাগুলি স্থানীয়ভাবে উপলব্ধ, অন্যগুলি সঙ্গে সঙ্গেই Google Translate থেকে অনুবাদ হয়।';

  @override
  String get languageSearchHint => 'ভাষা অনুসন্ধান করুন';

  @override
  String get languageEmptyState =>
      'আপনার অনুসন্ধানের সঙ্গে এখনও কোনো ভাষা মেলেনি।';

  @override
  String languageSetupMessage(String languageName) {
    return '$languageName সেটআপ করা হচ্ছে...';
  }

  @override
  String languageChangedNative(String languageName) {
    return 'ভাষা $languageName এ পরিবর্তিত হয়েছে';
  }

  @override
  String languageChangedTranslated(String languageName) {
    return 'ভাষা $languageName এ পরিবর্তিত হয়েছে (Google Translate)';
  }

  @override
  String get done => 'সম্পন্ন';

  @override
  String get languageManageTitle => 'অ্যাপের ভাষা সর্বত্র নিয়ন্ত্রণ করুন';

  @override
  String get languageManageDescription =>
      'Settings → Language থেকে আপনার পছন্দের ভাষা বেছে নিন, আমরা সেটি সর্বত্র প্রয়োগ করব।';

  @override
  String get languageManageCta => 'ভাষা সেটিংস খুলুন';

  @override
  String get resultsFor => 'এর ফলাফল';

  @override
  String get filters => 'ফিল্টার';

  @override
  String get clearFilters => 'ফিল্টার মুছুন';

  @override
  String get tagWeekend => 'সপ্তাহান্ত';

  @override
  String get tagAdventure => 'রোমাঞ্চ';

  @override
  String get tagBudget => 'বাজেট';

  @override
  String get budgetLow => 'কম বাজেট';

  @override
  String get budgetMedium => 'মাঝারি বাজেট';

  @override
  String get budgetHigh => 'উচ্চ বাজেট';

  @override
  String get duration2to3 => '২–৩ দিন';

  @override
  String get duration4to5 => '৪–৫ দিন';

  @override
  String get duration6plus => '৬+ দিন';

  @override
  String get save => 'সেভ করুন';

  @override
  String get unsave => 'সেভ বাতিল';

  @override
  String get saveIdea => 'আইডিয়া সেভ করুন';

  @override
  String get unsaveIdea => 'আইডিয়া সেভ বাতিল';

  @override
  String get savedToYourIdeas => 'আপনার আইডিয়াতে সেভ হয়েছে';

  @override
  String get removedFromYourIdeas => 'আপনার আইডিয়া থেকে সরানো হয়েছে';

  @override
  String get idea => 'আইডিয়া';

  @override
  String ideaLabel(String title) {
    return 'আইডিয়া: $title';
  }

  @override
  String get ideasFallbackToLocal =>
      'নেটওয়ার্ক সমস্যা: স্থানীয় আইডিয়া দেখানো হচ্ছে';

  @override
  String get retry => 'পুনরায় চেষ্টা করুন';

  @override
  String get skip => 'এড়িয়ে যান';

  @override
  String stepProgress(int current, int total) {
    return 'ধাপ $current এর মধ্যে $total';
  }

  @override
  String get welcomeToTravelWizards => 'Travel Wizards-এ স্বাগতম!';

  @override
  String get personalizeExperience =>
      'চলুন আপনার পছন্দের ভিত্তিতে ভ্রমণ অভিজ্ঞতা ব্যক্তিগত করি।';

  @override
  String get aiPoweredTripPlanning => 'এআই ভিত্তিক ভ্রমণ পরিকল্পনা';

  @override
  String get personalizedRecommendations => 'ব্যক্তিগতকৃত সুপারিশ';

  @override
  String get collaborativeTripPlanning => 'সমষ্টিগত ভ্রমণ পরিকল্পনা';

  @override
  String errorCompletingOnboarding(String error) {
    return 'অনবোর্ডিং সম্পূর্ণ করতে ত্রুটি: $error';
  }

  @override
  String get profileOfflineTitle => 'অফলাইনে মোড';

  @override
  String get profileOfflineDescription =>
      'আপনি পুনরায় সংযুক্ত হলেই আমরা আপনার পরিবর্তন সিঙ্ক করব। নিশ্চিন্তে সম্পাদনা চালিয়ে যান।';

  @override
  String get profileDiscardEditsLabel => 'সম্পাদনা বাতিল করুন';

  @override
  String get profileAccountBasicsTitle => 'অ্যাকাউন্টের প্রাথমিক তথ্য';

  @override
  String get profileAccountBasicsSubtitle =>
      'এই তথ্যগুলো ব্যক্তিগতকৃত প্রস্তাব ও ভাগ করা ভ্রমণ অভিজ্ঞতাকে সমৃদ্ধ করে।';

  @override
  String get profileFullNameLabel => 'পূর্ণ নাম';

  @override
  String get profileUsernameLabel => 'ব্যবহারকারীর নাম';

  @override
  String get profileUsernameHelper =>
      'পাবলিক শেয়ার লিঙ্ক ও কনসিয়ার্জ সহায়তার জন্য ব্যবহৃত';

  @override
  String get profileEmailLabel => 'ইমেল';

  @override
  String get profileGenderLabel => 'লিঙ্গ';

  @override
  String get profileGenderOptionPreferNot => 'বলতে অনিচ্ছুক';

  @override
  String get profileGenderOptionMale => 'পুরুষ';

  @override
  String get profileGenderOptionFemale => 'মহিলা';

  @override
  String get profileGenderOptionOther => 'অন্যান্য';

  @override
  String get profileDobLabel => 'জন্মতারিখ';

  @override
  String get profileDobHint => 'YYYY-MM-DD';

  @override
  String get profileDobFormatError =>
      'দয়া করে YYYY-MM-DD বিন্যাস ব্যবহার করুন';

  @override
  String get profileGoogleManagedNotice =>
      'এই তথ্যগুলো আপনার Google অ্যাকাউন্ট থেকে এসেছে। আপডেট প্রয়োজন হলে support@travelwizards.com এ ইমেল করুন।';

  @override
  String get profileHomeTitle => 'আপনার ঘর কোথায়';

  @override
  String get profileHomeSubtitle =>
      'আপনার প্রিয় গন্তব্য অনুযায়ী আবহাওয়া সতর্কতা ও কনসিয়ার্জ টিপস আমরা সাজিয়ে দেব।';

  @override
  String get profileCountryLabel => 'দেশ';

  @override
  String get profileStateLabel => 'রাজ্য / অঞ্চল';

  @override
  String get profileCityLabel => 'শহর';

  @override
  String get profileTasteTitle => 'রুচি ও যত্ন';

  @override
  String get profileTasteSubtitle =>
      'আপনি যেসব খাবার পছন্দ করেন তা দেখাতে এবং যেগুলো এড়ানো উচিত সেগুলো বাদ দিতে আমরা এটি ব্যবহার করি।';

  @override
  String get profileFoodPrefsLabel => 'খাবারের পছন্দ';

  @override
  String get profileFoodPrefsHelper =>
      'কমা দিয়ে আলাদা করুন (যেমন ভেগান, বাদাম-মুক্ত, ফার্ম-টু-টেবিল)';

  @override
  String get profileAllergiesLabel => 'এলার্জি / নোট';

  @override
  String get profilePhotoSectionTitle => 'প্রোফাইল ছবি';

  @override
  String get profilePhotoGuidance =>
      'সেরা ফলের জন্য উচ্চ মানের বর্গাকার ছবি ব্যবহার করুন।';

  @override
  String get profileUploadPhotoButton => 'নতুন ছবি আপলোড করুন';

  @override
  String get profileUseGooglePhotoButton => 'Google ছবিটি ব্যবহার করুন';

  @override
  String get profileRemovePhotoButton => 'ছবি সরান';

  @override
  String get profileOfflinePhotoWarning =>
      'আপনি অফলাইনে আছেন। নতুন ছবি আপলোড করতে সংযোগ করুন।';

  @override
  String get profilePhotoManagedNotice =>
      'Google সাইন-ইনের জন্য প্রোফাইল ছবি আপনার Google অ্যাকাউন্ট থেকেই আপডেট করতে হবে। আমরা পরিবর্তন স্বয়ংক্রিয়ভাবে আনব।';

  @override
  String get profileDiscardChangesLabel => 'পরিবর্তন বাতিল করুন';

  @override
  String profileLastSavedAtLabel(String time) {
    return 'শেষবার $time এ সেভ হয়েছে';
  }

  @override
  String get profileCacheMessage =>
      'আপনার প্রোফাইল অফলাইন অ্যাক্সেসের জন্য সংরক্ষিত আছে এবং আপনি পুনরায় সংযুক্ত হলেই সিঙ্ক হবে।';

  @override
  String get profileSaveTooltipPending => 'প্রোফাইল আপডেট সেভ করুন';

  @override
  String get profileSaveTooltipSaved => 'সব পরিবর্তন সেভ হয়েছে';

  @override
  String get profilePageTitle => 'প্রোফাইল';

  @override
  String get profileBackdropDefaultName => 'আপনার প্রোফাইল';

  @override
  String get profileManagedByGoogleBadge => 'Google দ্বারা পরিচালিত';

  @override
  String get profileOfflineBadge => 'অফলাইন';

  @override
  String get profileSignedInToUploadError => 'আপলোড করতে লগ ইন থাকা প্রয়োজন।';

  @override
  String get profileReconnectToUploadError =>
      'নতুন ছবি আপলোড করতে পুনরায় সংযোগ করুন।';

  @override
  String get profileReadFileError => 'নির্বাচিত ফাইলটি পড়া যায়নি।';

  @override
  String get profileFileTooLargeError =>
      '৫ এমবি-র কম সাইজের ছবি নির্বাচন করুন।';

  @override
  String get profilePhotoUpdatedMessage =>
      'ছবি আপডেট হয়েছে। পরিবর্তন স্বয়ংক্রিয়ভাবে সেভ হবে।';

  @override
  String profilePhotoUploadFailedMessage(String error) {
    return 'ছবি আপলোড ব্যর্থ: $error';
  }

  @override
  String get profileSignedInToSaveError => 'সেভ করতে লগ ইন থাকা প্রয়োজন।';

  @override
  String get profileFixHighlightedFieldsError =>
      'অনুগ্রহ করে হাইলাইট করা ঘরগুলো ঠিক করুন।';

  @override
  String get profileSyncSuccessMessage =>
      'প্রোফাইল আপনার সব ডিভাইসে সিঙ্ক হয়েছে।';

  @override
  String get profileSyncOfflineMessage =>
      'এখন অফলাইনে। আপনি সংযুক্ত হলেই প্রোফাইল সিঙ্ক করব।';

  @override
  String profileAutoSaveFailedMessage(String error) {
    return 'অটো-সেভ ব্যর্থ: $error';
  }

  @override
  String profileSaveFailedMessage(String error) {
    return 'প্রোফাইল সেভ করা যায়নি: $error';
  }

  @override
  String get profileRevertedChangesMessage =>
      'অসম্পাদিত পরিবর্তন ফিরিয়ে নেওয়া হয়েছে।';

  @override
  String profileFieldRequired(String fieldName) {
    return '$fieldName আবশ্যক';
  }

  @override
  String get profileUsernameTooShort => 'কমপক্ষে ৩ টি অক্ষর';

  @override
  String get profileUsernameInvalid =>
      'শুধু অক্ষর, সংখ্যা, আন্ডারস্কোর বা ডট ব্যবহার করা যাবে';

  @override
  String get profileEmailInvalid => 'বৈধ ইমেল ঠিকানা লিখুন';
}
