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
}
