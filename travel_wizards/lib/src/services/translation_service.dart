import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

/// Service for handling both built-in localization and Google Translate API
/// for additional languages not covered by the app's native l10n files
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  static TranslationService get instance => _instance;
  TranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();

  /// Comprehensive list of supported languages
  /// Includes both natively supported (with .arb files) and Google Translate supported
  static const List<LanguageItem> supportedLanguages = [
    // System default
    LanguageItem(null, 'System Default', 'System', true),

    // Native Indian languages (have .arb files)
    LanguageItem(Locale('en'), 'English', 'English', true),
    LanguageItem(Locale('hi'), 'हिन्दी', 'Hindi', true),
    LanguageItem(Locale('bn'), 'বাংলা', 'Bengali', true),
    LanguageItem(Locale('te'), 'తెలుగు', 'Telugu', true),
    LanguageItem(Locale('mr'), 'मराठी', 'Marathi', true),
    LanguageItem(Locale('ta'), 'தமிழ்', 'Tamil', true),
    LanguageItem(Locale('ur'), 'اردو', 'Urdu', true),
    LanguageItem(Locale('gu'), 'ગુજરાતી', 'Gujarati', true),
    LanguageItem(Locale('ml'), 'മലയാളം', 'Malayalam', true),
    LanguageItem(Locale('kn'), 'ಕನ್ನಡ', 'Kannada', true),
    LanguageItem(Locale('or'), 'ଓଡିଆ', 'Odia', true),

    // Additional Indian languages via Google Translate
    LanguageItem(Locale('as'), 'অসমীয়া', 'Assamese', false),
    LanguageItem(Locale('pa'), 'ਪੰਜਾਬੀ', 'Punjabi', false),
    LanguageItem(Locale('sd'), 'سنڌي', 'Sindhi', false),
    LanguageItem(Locale('ne'), 'नेपाली', 'Nepali', false),
    LanguageItem(Locale('si'), 'සිංහල', 'Sinhala', false),

    // Major international languages via Google Translate
    LanguageItem(Locale('es'), 'Español', 'Spanish', false),
    LanguageItem(Locale('fr'), 'Français', 'French', false),
    LanguageItem(Locale('de'), 'Deutsch', 'German', false),
    LanguageItem(Locale('it'), 'Italiano', 'Italian', false),
    LanguageItem(Locale('pt'), 'Português', 'Portuguese', false),
    LanguageItem(Locale('ru'), 'Русский', 'Russian', false),
    LanguageItem(Locale('ja'), '日本語', 'Japanese', false),
    LanguageItem(Locale('ko'), '한국어', 'Korean', false),
    LanguageItem(Locale('zh'), '中文', 'Chinese', false),
    LanguageItem(Locale('ar'), 'العربية', 'Arabic', false),
    LanguageItem(Locale('tr'), 'Türkçe', 'Turkish', false),
    LanguageItem(Locale('nl'), 'Nederlands', 'Dutch', false),
    LanguageItem(Locale('sv'), 'Svenska', 'Swedish', false),
    LanguageItem(Locale('no'), 'Norsk', 'Norwegian', false),
    LanguageItem(Locale('da'), 'Dansk', 'Danish', false),
    LanguageItem(Locale('fi'), 'Suomi', 'Finnish', false),
    LanguageItem(Locale('pl'), 'Polski', 'Polish', false),
    LanguageItem(Locale('cs'), 'Čeština', 'Czech', false),
    LanguageItem(Locale('hu'), 'Magyar', 'Hungarian', false),
    LanguageItem(Locale('ro'), 'Română', 'Romanian', false),
    LanguageItem(Locale('bg'), 'Български', 'Bulgarian', false),
    LanguageItem(Locale('hr'), 'Hrvatski', 'Croatian', false),
    LanguageItem(Locale('sk'), 'Slovenčina', 'Slovak', false),
    LanguageItem(Locale('sl'), 'Slovenščina', 'Slovenian', false),
    LanguageItem(Locale('et'), 'Eesti', 'Estonian', false),
    LanguageItem(Locale('lv'), 'Latviešu', 'Latvian', false),
    LanguageItem(Locale('lt'), 'Lietuvių', 'Lithuanian', false),
    LanguageItem(Locale('el'), 'Ελληνικά', 'Greek', false),
    LanguageItem(Locale('he'), 'עברית', 'Hebrew', false),
    LanguageItem(Locale('th'), 'ไทย', 'Thai', false),
    LanguageItem(Locale('vi'), 'Tiếng Việt', 'Vietnamese', false),
    LanguageItem(Locale('id'), 'Bahasa Indonesia', 'Indonesian', false),
    LanguageItem(Locale('ms'), 'Bahasa Melayu', 'Malay', false),
    LanguageItem(Locale('tl'), 'Filipino', 'Filipino', false),
    LanguageItem(Locale('sw'), 'Kiswahili', 'Swahili', false),
    LanguageItem(Locale('af'), 'Afrikaans', 'Afrikaans', false),
    LanguageItem(Locale('am'), 'አማርኛ', 'Amharic', false),
    LanguageItem(Locale('eu'), 'Euskera', 'Basque', false),
    LanguageItem(Locale('ca'), 'Català', 'Catalan', false),
    LanguageItem(Locale('cy'), 'Cymraeg', 'Welsh', false),
    LanguageItem(Locale('ga'), 'Gaeilge', 'Irish', false),
    LanguageItem(Locale('is'), 'Íslenska', 'Icelandic', false),
    LanguageItem(Locale('mt'), 'Malti', 'Maltese', false),
    LanguageItem(Locale('sq'), 'Shqip', 'Albanian', false),
    LanguageItem(Locale('mk'), 'Македонски', 'Macedonian', false),
    LanguageItem(Locale('sr'), 'Српски', 'Serbian', false),
    LanguageItem(Locale('bs'), 'Bosanski', 'Bosnian', false),
    LanguageItem(Locale('me'), 'Crnogorski', 'Montenegrin', false),
  ];

  /// Get list of natively supported languages (have .arb files)
  static List<LanguageItem> get nativeLanguages =>
      supportedLanguages.where((lang) => lang.isNative).toList();

  /// Get list of Google Translate supported languages
  static List<LanguageItem> get translateLanguages =>
      supportedLanguages.where((lang) => !lang.isNative).toList();

  /// Get all languages grouped by region/type
  static Map<String, List<LanguageItem>> get languagesByRegion => {
    'System': [supportedLanguages.first], // System Default
    'Indian Languages (Native)': supportedLanguages
        .where(
          (lang) =>
              lang.isNative &&
              lang.locale != null &&
              [
                'hi',
                'bn',
                'te',
                'mr',
                'ta',
                'ur',
                'gu',
                'ml',
                'kn',
                'or',
              ].contains(lang.locale!.languageCode),
        )
        .toList(),
    'Indian Languages (Extended)': supportedLanguages
        .where(
          (lang) =>
              !lang.isNative &&
              [
                'as',
                'pa',
                'sd',
                'ne',
                'si',
              ].contains(lang.locale?.languageCode),
        )
        .toList(),
    'European Languages': supportedLanguages
        .where(
          (lang) =>
              !lang.isNative &&
              [
                'es',
                'fr',
                'de',
                'it',
                'pt',
                'ru',
                'nl',
                'sv',
                'no',
                'da',
                'fi',
                'pl',
                'cs',
                'hu',
                'ro',
                'bg',
                'hr',
                'sk',
                'sl',
                'et',
                'lv',
                'lt',
                'el',
                'eu',
                'ca',
                'cy',
                'ga',
                'is',
                'mt',
                'sq',
                'mk',
                'sr',
                'bs',
                'me',
              ].contains(lang.locale?.languageCode),
        )
        .toList(),
    'Asian Languages': supportedLanguages
        .where(
          (lang) =>
              !lang.isNative &&
              [
                'ja',
                'ko',
                'zh',
                'th',
                'vi',
                'id',
                'ms',
                'tl',
              ].contains(lang.locale?.languageCode),
        )
        .toList(),
    'Middle Eastern Languages': supportedLanguages
        .where(
          (lang) =>
              !lang.isNative &&
              ['ar', 'tr', 'he'].contains(lang.locale?.languageCode),
        )
        .toList(),
    'African Languages': supportedLanguages
        .where(
          (lang) =>
              !lang.isNative &&
              ['sw', 'af', 'am'].contains(lang.locale?.languageCode),
        )
        .toList(),
    'English': supportedLanguages
        .where((lang) => lang.locale?.languageCode == 'en')
        .toList(),
  };

  /// Translate text using Google Translate API
  /// Returns original text if translation fails
  Future<String> translateText(
    String text,
    String targetLanguage, {
    String sourceLanguage = 'auto',
  }) async {
    try {
      if (text.isEmpty || targetLanguage.isEmpty) return text;

      final translation = await _translator.translate(
        text,
        from: sourceLanguage,
        to: targetLanguage,
      );

      return translation.text;
    } catch (e) {
      // If translation fails, return original text
      debugPrint('Translation failed: $e');
      return text;
    }
  }

  /// Translate multiple texts in batch
  Future<Map<String, String>> translateTexts(
    Map<String, String> texts,
    String targetLanguage, {
    String sourceLanguage = 'auto',
  }) async {
    final results = <String, String>{};

    for (final entry in texts.entries) {
      results[entry.key] = await translateText(
        entry.value,
        targetLanguage,
        sourceLanguage: sourceLanguage,
      );
    }

    return results;
  }

  /// Check if a language is natively supported
  static bool isNativeLanguage(Locale? locale) {
    if (locale == null) return true; // System default
    return nativeLanguages.any(
      (lang) => lang.locale?.languageCode == locale.languageCode,
    );
  }

  /// Get language item by locale
  static LanguageItem? getLanguageItem(Locale? locale) {
    return supportedLanguages.firstWhere(
      (lang) => lang.locale?.languageCode == locale?.languageCode,
      orElse: () => supportedLanguages.first, // Default to system
    );
  }

  /// Check if Google Translate is needed for this locale
  static bool requiresTranslation(Locale? locale) {
    return locale != null && !isNativeLanguage(locale);
  }
}

/// Data class for language information
class LanguageItem {
  final Locale? locale;
  final String nativeName;
  final String englishName;
  final bool isNative;

  const LanguageItem(
    this.locale,
    this.nativeName,
    this.englishName,
    this.isNative,
  );

  String get displayName => nativeName;
  String get languageCode => locale?.languageCode ?? 'system';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageItem &&
          runtimeType == other.runtimeType &&
          locale == other.locale;

  @override
  int get hashCode => locale.hashCode;

  @override
  String toString() =>
      'LanguageItem($nativeName, $englishName, native: $isNative)';
}
