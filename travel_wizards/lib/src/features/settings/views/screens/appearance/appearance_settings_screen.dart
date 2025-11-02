import 'package:flutter/material.dart';
import 'package:travel_wizards/src/core/app/settings_controller.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final theme = Theme.of(context);

    return ModernPageScaffold(
      hero: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Make it yours',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how Travel Wizards adapts to light or dark environments.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      sections: [
        ModernSection(
          title: 'Theme mode',
          subtitle: 'Switch between system, light, or dark styles.',
          icon: Icons.dark_mode_outlined,
          child: SegmentedButton<ThemeMode>(
            selected: <ThemeMode>{settings.themeMode},
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.settings_suggest_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            onSelectionChanged: (selection) {
              final mode = selection.firstOrNull ?? ThemeMode.system;
              settings.setThemeMode(mode);
            },
          ),
        ),
      ],
    );
  }
}
