import 'package:flutter/material.dart';
import 'package:travel_wizards/src/app/settings_controller.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/l10n/app_localizations.dart';
import 'package:travel_wizards/src/services/translation_service.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _searchQuery = '';
  bool _showAllLanguages = false;

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
            actions: [
              IconButton(
                icon: Icon(
                  _showAllLanguages ? Icons.language : Icons.translate,
                ),
                onPressed: () {
                  setState(() {
                    _showAllLanguages = !_showAllLanguages;
                  });
                },
                tooltip: _showAllLanguages
                    ? 'Show native languages only'
                    : 'Show all languages (Google Translate)',
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: Insets.allMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showAllLanguages
                          ? 'Choose from 50+ languages (includes Google Translate)'
                          : 'Choose your preferred app language',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Gaps.h16,
                    SearchBar(
                      hintText: 'Search languages...',
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

              // Language list
              Expanded(child: _buildLanguageList(settings, theme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageList(AppSettings settings, ThemeData theme) {
    if (_showAllLanguages) {
      return _buildGroupedLanguageList(settings, theme);
    } else {
      return _buildNativeLanguageList(settings, theme);
    }
  }

  Widget _buildNativeLanguageList(AppSettings settings, ThemeData theme) {
    final nativeLanguages = TranslationService.nativeLanguages
        .where((lang) => _matchesSearch(lang))
        .toList();

    return ListView.builder(
      padding: Insets.allMd,
      itemCount: nativeLanguages.length,
      itemBuilder: (context, index) {
        final language = nativeLanguages[index];
        final selected = settings.locale?.languageCode == language.languageCode;

        return _buildLanguageTile(language, selected, settings, theme);
      },
    );
  }

  Widget _buildGroupedLanguageList(AppSettings settings, ThemeData theme) {
    final languagesByRegion = TranslationService.languagesByRegion;

    return ListView(
      padding: Insets.allMd,
      children: languagesByRegion.entries.expand((entry) {
        final regionName = entry.key;
        final languages = entry.value
            .where((lang) => _matchesSearch(lang))
            .toList();

        if (languages.isEmpty) return <Widget>[];

        return [
          // Region header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              regionName,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Languages in this region
          ...languages.map((language) {
            final selected =
                settings.locale?.languageCode == language.languageCode;
            return _buildLanguageTile(
              language,
              selected,
              settings,
              theme,
              showTranslateIcon: !language.isNative,
            );
          }),

          Gaps.h8,
        ];
      }).toList(),
    );
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
              Text('Setting up ${language.englishName}...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Set the locale
    await settings.setLocale(language.locale);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            language.isNative
                ? 'Language changed to ${language.displayName}'
                : 'Language changed to ${language.displayName} (Google Translate)',
          ),
          action: SnackBarAction(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
  }
}
