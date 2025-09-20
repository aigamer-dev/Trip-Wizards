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
}
