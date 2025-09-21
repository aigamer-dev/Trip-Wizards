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
}
