import 'package:flutter/material.dart';
import 'package:travel_wizards/src/core/app/settings_controller.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/core/l10n/app_localizations.dart';
import 'package:travel_wizards/src/shared/services/navigation_service.dart';
import 'package:travel_wizards/src/shared/services/translation_service.dart';
import 'package:travel_wizards/src/shared/widgets/translated_text.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen>
    with TranslationMixin<LanguageSettingsScreen> {
  String _searchQuery = '';
  String _searchHint = 'Search languages';
  String _languageIntro =
      'Choose your preferred app language. Native Indian languages are localised while others use Google Translate instantly.';
  String _emptyStateMessage = 'No languages match your search yet.';
  Locale? _lastResolvedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLocalizedCopy();
  }

  Future<void> _loadLocalizedCopy() async {
    final currentLocale = AppSettings.instance.locale;
    if (_lastResolvedLocale != null && _lastResolvedLocale == currentLocale) {
      return;
    }
    _lastResolvedLocale = currentLocale;

    final localizations = AppLocalizations.of(context);

    final introBase =
        localizations?.languageSelectionIntro ??
        'Choose your preferred app language. Native Indian languages are localised while others use Google Translate instantly.';
    final hintBase = localizations?.languageSearchHint ?? 'Search languages';
    final emptyBase =
        localizations?.languageEmptyState ??
        'No languages match your search yet.';

    final translatedIntro = await translateIfNeeded(introBase);
    final translatedHint = await translateIfNeeded(hintBase);
    final translatedEmpty = await translateIfNeeded(emptyBase);

    if (!mounted) return;
    setState(() {
      _languageIntro = translatedIntro;
      _searchHint = translatedHint;
      _emptyStateMessage = translatedEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(t.language),
            leading: const NavigationBackButton(),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search bar
              Padding(
                padding: Insets.allMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _languageIntro,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Gaps.h16,
                    SearchBar(
                      hintText: _searchHint,
                      leading: const Icon(Icons.search),
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query.toLowerCase();
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildLanguageList(settings, theme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageList(AppSettings settings, ThemeData theme) {
    final entries = TranslationService.languagesByRegion.entries
        .map(
          (entry) => MapEntry(
            entry.key,
            entry.value.where((lang) => _matchesSearch(lang)).toList(),
          ),
        )
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: Insets.allMd,
          child: Text(
            _emptyStateMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: Insets.allMd,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final regionName = entry.key;
        final languages = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TranslatedText(
                regionName,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...languages.map((language) {
              final selected = _isSelectedLanguage(settings, language);
              return _buildLanguageTile(
                language,
                selected,
                settings,
                theme,
                showTranslateIcon:
                    !language.isNative && language.locale != null,
              );
            }),
            if (index != entries.length - 1) const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  bool _isSelectedLanguage(AppSettings settings, LanguageItem language) {
    final currentLocale = settings.locale;
    if (language.locale == null) {
      return currentLocale == null;
    }
    if (currentLocale == null) return false;
    return currentLocale.languageCode == language.locale?.languageCode;
  }

  Widget _buildLanguageTile(
    LanguageItem language,
    bool selected,
    AppSettings settings,
    ThemeData theme, {
    bool showTranslateIcon = false,
  }) {
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              language.displayName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (showTranslateIcon) ...[
            const SizedBox(width: 8),
            Icon(Icons.translate, size: 16, color: theme.colorScheme.outline),
          ],
        ],
      ),
      subtitle: language.isNative
          ? null
          : Text(
              language.englishName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      onTap: () => _selectLanguage(language, settings),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : Icon(Icons.circle_outlined, color: theme.colorScheme.outline),
    );
  }

  bool _matchesSearch(LanguageItem language) {
    if (_searchQuery.isEmpty) return true;

    return language.nativeName.toLowerCase().contains(_searchQuery) ||
        language.englishName.toLowerCase().contains(_searchQuery) ||
        language.languageCode.toLowerCase().contains(_searchQuery);
  }

  Future<void> _selectLanguage(
    LanguageItem language,
    AppSettings settings,
  ) async {
    // Show loading for non-native languages
    if (!language.isNative && language.locale != null) {
      final baseSetupMessage =
          AppLocalizations.of(
            context,
          )?.languageSetupMessage(language.englishName) ??
          'Setting up ${language.englishName}...';
      final setupMessage = await translateIfNeeded(baseSetupMessage);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(setupMessage)),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Set the locale
    await settings.setLocale(language.locale);

    if (mounted) {
      final baseMessage = language.isNative
          ? AppLocalizations.of(
                  context,
                )?.languageChangedNative(language.displayName) ??
                'Language changed to ${language.displayName}'
          : AppLocalizations.of(
                  context,
                )?.languageChangedTranslated(language.displayName) ??
                'Language changed to ${language.displayName} (Google Translate)';
      final message = await translateIfNeeded(baseMessage);
      final baseDone = AppLocalizations.of(context)?.done ?? 'Done';
      final doneLabel = await translateIfNeeded(baseDone);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: doneLabel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
  }
}
