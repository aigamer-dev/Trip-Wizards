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
}
