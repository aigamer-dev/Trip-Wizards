// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Travel Wizards';

  @override
  String get searchPlaceholder => 'Travel Wizards';

  @override
  String get menu => 'Menu';

  @override
  String get open => 'Open';

  @override
  String get explore => 'Explore';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get generationInProgress => 'Generation In Progress';

  @override
  String get ongoingTrips => 'Ongoing Trips';

  @override
  String get plannedTrips => 'Planned Trips';

  @override
  String get suggestedTrips => 'Suggested Trips';

  @override
  String get addTrip => 'Add Trip';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get resultsFor => 'Results for';

  @override
  String get filters => 'Filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get tagWeekend => 'Weekend';

  @override
  String get tagAdventure => 'Adventure';

  @override
  String get tagBudget => 'Budget';

  @override
  String get budgetLow => 'Low budget';

  @override
  String get budgetMedium => 'Medium budget';

  @override
  String get budgetHigh => 'High budget';

  @override
  String get duration2to3 => '2–3 days';

  @override
  String get duration4to5 => '4–5 days';

  @override
  String get duration6plus => '6+ days';

  @override
  String get save => 'Save';

  @override
  String get unsave => 'Unsave';

  @override
  String get saveIdea => 'Save idea';

  @override
  String get unsaveIdea => 'Unsave idea';

  @override
  String get savedToYourIdeas => 'Saved to your ideas';

  @override
  String get removedFromYourIdeas => 'Removed from your ideas';

  @override
  String get idea => 'Idea';

  @override
  String ideaLabel(String title) {
    return 'Idea: $title';
  }

  @override
  String get ideasFallbackToLocal => 'Network issue: showing local ideas';

  @override
  String get retry => 'Retry';
}
