import 'package:flutter/material.dart';
import 'package:travel_wizards/src/app/settings_controller.dart';
import 'package:travel_wizards/src/services/translation_service.dart';
import 'package:travel_wizards/src/l10n/app_localizations.dart';

/// A widget that automatically translates text when using non-native languages
/// Falls back to native localization when available
class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? sourceLanguage;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.sourceLanguage = 'en', // Default source is English
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? _translatedText;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _translateIfNeeded();
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _translateIfNeeded();
    }
  }

  Future<void> _translateIfNeeded() async {
    final currentLocale = AppSettings.instance.locale;

    // If using native language or system default, don't translate
    if (TranslationService.isNativeLanguage(currentLocale)) {
      setState(() {
        _translatedText = widget.text;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    // If translation is needed
    if (currentLocale != null &&
        TranslationService.requiresTranslation(currentLocale)) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      try {
        final translated = await TranslationService.instance.translateText(
          widget.text,
          currentLocale.languageCode,
          sourceLanguage: widget.sourceLanguage ?? 'en',
        );

        if (mounted) {
          setState(() {
            _translatedText = translated;
            _isLoading = false;
            _hasError = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _translatedText = widget.text; // Fallback to original
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } else {
      setState(() {
        _translatedText = widget.text;
        _isLoading = false;
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.style?.fontSize ?? 14,
        child: const LinearProgressIndicator(),
      );
    }

    return Text(
      _translatedText ?? widget.text,
      style: widget.style?.copyWith(
        color: _hasError
            ? Theme.of(context).colorScheme.error.withOpacity(0.7)
            : widget.style?.color,
      ),
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

/// A helper mixin that provides translation capabilities to widgets
mixin TranslationMixin<T extends StatefulWidget> on State<T> {
  /// Translate text if current language requires Google Translate
  Future<String> translateIfNeeded(
    String text, {
    String sourceLanguage = 'en',
  }) async {
    final currentLocale = AppSettings.instance.locale;

    if (currentLocale != null &&
        TranslationService.requiresTranslation(currentLocale)) {
      try {
        return await TranslationService.instance.translateText(
          text,
          currentLocale.languageCode,
          sourceLanguage: sourceLanguage,
        );
      } catch (e) {
        debugPrint('Translation failed: $e');
        return text; // Fallback to original
      }
    }

    return text;
  }

  /// Get translated app localizations with fallback support
  String getLocalizedText(String Function(AppLocalizations) textSelector) {
    try {
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        return textSelector(localizations);
      }
    } catch (e) {
      debugPrint('Localization failed: $e');
    }

    // Fallback - this would need to be handled case by case
    return 'Text not available';
  }

  /// Check if current language is natively supported
  bool get isNativeLanguage =>
      TranslationService.isNativeLanguage(AppSettings.instance.locale);

  /// Check if current language requires translation
  bool get requiresTranslation =>
      TranslationService.requiresTranslation(AppSettings.instance.locale);
}

/// Extension to easily get translated text
extension StringTranslation on String {
  /// Get a TranslatedText widget for this string
  TranslatedText translated({
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    String sourceLanguage = 'en',
  }) {
    return TranslatedText(
      this,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      sourceLanguage: sourceLanguage,
    );
  }
}
