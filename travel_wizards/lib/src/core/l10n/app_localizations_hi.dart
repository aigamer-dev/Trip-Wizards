// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'ट्रैवल विज़ार्ड्स';

  @override
  String get searchPlaceholder => 'ट्रैवल विज़ार्ड्स';

  @override
  String get menu => 'मेनू';

  @override
  String get open => 'खोलें';

  @override
  String get explore => 'एक्सप्लोर';

  @override
  String get home => 'होम';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get generationInProgress => 'जनरेशन प्रगति पर';

  @override
  String get ongoingTrips => 'चल रही यात्राएँ';

  @override
  String get plannedTrips => 'योजनाबद्ध यात्राएँ';

  @override
  String get suggestedTrips => 'सुझाई गई यात्राएँ';

  @override
  String get addTrip => 'यात्रा जोड़ें';

  @override
  String get themeMode => 'थीम मोड';

  @override
  String get language => 'भाषा';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get light => 'लाइट';

  @override
  String get dark => 'डार्क';

  @override
  String get languageSelectionIntro =>
      'अपनी पसंदीदा ऐप भाषा चुनें। देशी भारतीय भाषाएँ पूरी तरह स्थानीयकृत हैं जबकि अन्य भाषाएँ तुरंत Google Translate से सक्षम होती हैं।';

  @override
  String get languageSearchHint => 'भाषाएँ खोजें';

  @override
  String get languageEmptyState =>
      'आपकी खोज से मेल खाने वाली कोई भाषा नहीं मिली।';

  @override
  String languageSetupMessage(String languageName) {
    return '$languageName सेट किया जा रहा है...';
  }

  @override
  String languageChangedNative(String languageName) {
    return 'भाषा $languageName में बदल दी गई';
  }

  @override
  String languageChangedTranslated(String languageName) {
    return 'भाषा $languageName में बदल दी गई (Google Translate)';
  }

  @override
  String get done => 'हो गया';

  @override
  String get languageManageTitle =>
      'अपनी ऐप की भाषा को वैश्विक रूप से प्रबंधित करें';

  @override
  String get languageManageDescription =>
      'सेटिंग्स → भाषा में अपनी पसंदीदा भाषा चुनें और हम इसे हर जगह लागू करेंगे।';

  @override
  String get languageManageCta => 'भाषा सेटिंग्स खोलें';

  @override
  String get resultsFor => 'इनके लिए परिणाम';

  @override
  String get filters => 'फ़िल्टर';

  @override
  String get clearFilters => 'फ़िल्टर साफ़ करें';

  @override
  String get tagWeekend => 'सप्ताहांत';

  @override
  String get tagAdventure => 'रोमांच';

  @override
  String get tagBudget => 'बजट';

  @override
  String get budgetLow => 'कम बजट';

  @override
  String get budgetMedium => 'मध्यम बजट';

  @override
  String get budgetHigh => 'उच्च बजट';

  @override
  String get duration2to3 => '2–3 दिन';

  @override
  String get duration4to5 => '4–5 दिन';

  @override
  String get duration6plus => '6+ दिन';

  @override
  String get save => 'सहेजें';

  @override
  String get unsave => 'सहेजा हटाएं';

  @override
  String get saveIdea => 'विचार सहेजें';

  @override
  String get unsaveIdea => 'विचार सहेजा हटाएं';

  @override
  String get savedToYourIdeas => 'आपके विचारों में सहेजा गया';

  @override
  String get removedFromYourIdeas => 'आपके विचारों से हटाया गया';

  @override
  String get idea => 'विचार';

  @override
  String ideaLabel(String title) {
    return 'विचार: $title';
  }

  @override
  String get ideasFallbackToLocal =>
      'नेटवर्क समस्या: स्थानीय विचार दिखाए जा रहे हैं';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get skip => 'छोड़ें';

  @override
  String stepProgress(int current, int total) {
    return 'चरण $current में से $total';
  }

  @override
  String get welcomeToTravelWizards => 'Travel Wizards में आपका स्वागत है!';

  @override
  String get personalizeExperience =>
      'आइए आपकी यात्राओं को आपकी पसंद के अनुसार व्यक्तिगत बनाते हैं।';

  @override
  String get aiPoweredTripPlanning => 'एआई संचालित यात्रा योजना';

  @override
  String get personalizedRecommendations => 'व्यक्तिगत अनुशंसाएँ';

  @override
  String get collaborativeTripPlanning => 'सह-यात्रा योजना';

  @override
  String errorCompletingOnboarding(String error) {
    return 'ऑनबोर्डिंग पूरा करने में त्रुटि: $error';
  }

  @override
  String get profileOfflineTitle => 'ऑफ़लाइन मोड';

  @override
  String get profileOfflineDescription =>
      'जैसे ही आप दोबारा ऑनलाइन होंगे, हम आपके परिवर्तन सिंक कर देंगे। आप सुरक्षित रूप से संपादन जारी रख सकते हैं।';

  @override
  String get profileDiscardEditsLabel => 'संपादन रद्द करें';

  @override
  String get profileAccountBasicsTitle => 'खाते की मूल जानकारी';

  @override
  String get profileAccountBasicsSubtitle =>
      'ये विवरण व्यक्तिगत सुझावों और साझा यात्रा अनुभवों को बेहतर बनाते हैं।';

  @override
  String get profileFullNameLabel => 'पूरा नाम';

  @override
  String get profileUsernameLabel => 'उपयोगकर्ता नाम';

  @override
  String get profileUsernameHelper =>
      'सार्वजनिक लिंक और कंसीयर्ज सहायता के लिए उपयोग किया जाता है';

  @override
  String get profileEmailLabel => 'ईमेल';

  @override
  String get profileGenderLabel => 'लिंग';

  @override
  String get profileGenderOptionPreferNot => 'बताने से परहेज़';

  @override
  String get profileGenderOptionMale => 'पुरुष';

  @override
  String get profileGenderOptionFemale => 'महिला';

  @override
  String get profileGenderOptionOther => 'अन्य';

  @override
  String get profileDobLabel => 'जन्म तिथि';

  @override
  String get profileDobHint => 'YYYY-MM-DD';

  @override
  String get profileDobFormatError => 'कृपया YYYY-MM-DD प्रारूप का उपयोग करें';

  @override
  String get profileGoogleManagedNotice =>
      'ये विवरण आपके Google खाते से आते हैं। बदलाव की आवश्यकता हो तो support@travelwizards.com पर ईमेल करें।';

  @override
  String get profileHomeTitle => 'आप कहाँ रहते हैं';

  @override
  String get profileHomeSubtitle =>
      'हम आपके पसंदीदा गंतव्यों के लिए मौसम अलर्ट और कंसीयर्ज सुझाव अनुकूल करेंगे।';

  @override
  String get profileCountryLabel => 'देश';

  @override
  String get profileStateLabel => 'राज्य / क्षेत्र';

  @override
  String get profileCityLabel => 'शहर';

  @override
  String get profileTasteTitle => 'स्वाद और देखभाल';

  @override
  String get profileTasteSubtitle =>
      'हम इन्हें आपके पसंदीदा भोजन दिखाने और जिनसे आपको समस्या है उनसे बचने के लिए उपयोग करते हैं।';

  @override
  String get profileFoodPrefsLabel => 'भोजन संबंधी पसंद';

  @override
  String get profileFoodPrefsHelper =>
      'कॉमा से अलग करें (जैसे वीगन, नट-फ़्री, फार्म-टू-टेबल)';

  @override
  String get profileAllergiesLabel => 'एलर्जी / नोट्स';

  @override
  String get profilePhotoSectionTitle => 'प्रोफ़ाइल फोटो';

  @override
  String get profilePhotoGuidance =>
      'सर्वश्रेष्ठ परिणामों के लिए उच्च गुणवत्ता वाली चौकोर छवि का उपयोग करें।';

  @override
  String get profileUploadPhotoButton => 'नई फोटो अपलोड करें';

  @override
  String get profileUseGooglePhotoButton => 'Google फोटो का उपयोग करें';

  @override
  String get profileRemovePhotoButton => 'फोटो हटाएँ';

  @override
  String get profileOfflinePhotoWarning =>
      'आप ऑफ़लाइन हैं। नई फोटो अपलोड करने के लिए कनेक्ट करें।';

  @override
  String get profilePhotoManagedNotice =>
      'Google साइन-इन के लिए प्रोफ़ाइल फोटो आपके Google खाते से ही अपडेट की जा सकती है। हम बदलाव खुद-ब-खुद ले आएँगे।';

  @override
  String get profileDiscardChangesLabel => 'परिवर्तन रद्द करें';

  @override
  String profileLastSavedAtLabel(String time) {
    return 'अंतिम बार $time पर सहेजा गया';
  }

  @override
  String get profileCacheMessage =>
      'आपकी प्रोफ़ाइल ऑफ़लाइन एक्सेस के लिए कैश की गई है और दोबारा जुड़ते ही सिंक हो जाएगी।';

  @override
  String get profileSaveTooltipPending => 'प्रोफ़ाइल अपडेट सहेजें';

  @override
  String get profileSaveTooltipSaved => 'सभी परिवर्तन सहेजे गए';

  @override
  String get profilePageTitle => 'प्रोफ़ाइल';

  @override
  String get profileBackdropDefaultName => 'आपकी प्रोफ़ाइल';

  @override
  String get profileManagedByGoogleBadge => 'Google द्वारा प्रबंधित';

  @override
  String get profileOfflineBadge => 'ऑफ़लाइन';

  @override
  String get profileSignedInToUploadError =>
      'अपलोड करने के लिए आपको लॉग इन रहना होगा।';

  @override
  String get profileReconnectToUploadError =>
      'नई फोटो अपलोड करने के लिए दोबारा कनेक्ट करें।';

  @override
  String get profileReadFileError => 'चयनित फ़ाइल पढ़ी नहीं जा सकी।';

  @override
  String get profileFileTooLargeError => 'कृपया 5 MB से छोटी छवि चुनें।';

  @override
  String get profilePhotoUpdatedMessage =>
      'फोटो अपडेट कर दी गई। बदलाव स्वतः सहेजे जाएँगे।';

  @override
  String profilePhotoUploadFailedMessage(String error) {
    return 'फोटो अपलोड विफल: $error';
  }

  @override
  String get profileSignedInToSaveError =>
      'सहेजने के लिए आपको लॉग इन रहना होगा।';

  @override
  String get profileFixHighlightedFieldsError =>
      'कृपया हाइलाइट किए गए फ़ील्ड ठीक करें।';

  @override
  String get profileSyncSuccessMessage =>
      'प्रोफ़ाइल सभी उपकरणों पर सिंक हो गई।';

  @override
  String get profileSyncOfflineMessage =>
      'अभी ऑफ़लाइन हैं। जैसे ही आप कनेक्ट होंगे हम प्रोफ़ाइल सिंक कर देंगे।';

  @override
  String profileAutoSaveFailedMessage(String error) {
    return 'ऑटो-सेव विफल रहा: $error';
  }

  @override
  String profileSaveFailedMessage(String error) {
    return 'प्रोफ़ाइल सहेजी नहीं जा सकी: $error';
  }

  @override
  String get profileRevertedChangesMessage => 'अनसहेजे बदलाव वापस ले लिए गए।';

  @override
  String profileFieldRequired(String fieldName) {
    return '$fieldName आवश्यक है';
  }

  @override
  String get profileUsernameTooShort => 'कम से कम 3 अक्षर';

  @override
  String get profileUsernameInvalid =>
      'केवल अक्षर, अंक, अंडरस्कोर या डॉट की अनुमति है';

  @override
  String get profileEmailInvalid => 'मान्य ईमेल पता दर्ज करें';
}
