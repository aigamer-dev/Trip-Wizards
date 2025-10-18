import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/core/app/settings_controller.dart';
import 'package:travel_wizards/src/core/config/env.dart';
import 'package:travel_wizards/src/shared/models/profile_store.dart';
import 'package:travel_wizards/src/shared/services/auth_service.dart';
import 'package:travel_wizards/src/shared/services/stripe_service.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppSettings _settings = AppSettings.instance;

  @override
  void initState() {
    super.initState();
    ProfileStore.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return ModernPageScaffold(
      pageTitle: 'Settings',
      sections: [
        _buildProfileSection(context),
        ModernSection(
          title: 'General',
          icon: Symbols.tune,
          children: [
            _buildSettingsTile(
              context,
              icon: Symbols.palette,
              title: 'Appearance',
              subtitle: 'Theme, colors, and more',
              onTap: () => context.pushNamed('theme_settings'),
            ),
            _buildSettingsTile(
              context,
              icon: Symbols.translate,
              title: 'Language',
              subtitle:
                  _settings.locale?.languageCode.toUpperCase() ??
                  'System Default',
              onTap: () => context.pushNamed('language_settings'),
            ),
            _buildSettingsTile(
              context,
              icon: Symbols.notifications,
              title: 'Notifications',
              onTap: () => context.pushNamed('notification_settings'),
            ),
          ],
        ),
        ModernSection(
          title: 'Account & Data',
          icon: Symbols.security,
          children: [
            _buildSettingsTile(
              context,
              icon: Symbols.shield_lock,
              title: 'Privacy & Security',
              onTap: () => context.pushNamed('privacy_settings'),
            ),
            _buildSettingsTile(
              context,
              icon: Symbols.cloud_sync,
              title: 'Sync & Backup',
              subtitle: 'Control how data flows across devices',
              onTap: () {}, // Placeholder
            ),
            if (kUseRemoteIdeas) _buildRemoteIdeasToggle(),
          ],
        ),
        ModernSection(
          title: 'Payments & Subscription',
          icon: Symbols.credit_card,
          children: [
            _buildSettingsTile(
              context,
              icon: Symbols.credit_card,
              title: 'Payment Methods',
              onTap: () => context.pushNamed('payment_options'),
            ),
            _buildSettingsTile(
              context,
              icon: Symbols.receipt_long,
              title: 'Transaction History',
              onTap: () => context.pushNamed('payment_history'),
            ),
            _buildSettingsTile(
              context,
              icon: Symbols.workspace_premium,
              title: 'Manage Subscription',
              subtitle: 'Current: ${_settings.subscriptionTier}',
              onTap: () => context.pushNamed('subscription_settings'),
            ),
            _buildPaymentsBackendTile(context),
          ],
        ),
        ModernSection(
          title: 'Support & About',
          icon: Symbols.help,
          children: [
            _buildSettingsTile(
              context,
              icon: Symbols.help,
              title: 'Help & FAQ',
              onTap: () => context.pushNamed('faq'),
            ),
            _buildSettingsTile(
              context,
              icon: Symbols.feedback,
              title: 'Send Feedback',
              onTap: () => context.pushNamed('feedback'),
            ),
            _buildSettingsTile(
              context,
              icon: Symbols.info,
              title: 'About Travel Wizards',
              onTap: () => context.pushNamed('about'),
            ),
            _buildSettingsTile(
              context,
              icon: Symbols.gavel,
              title: 'Legal & Privacy Policy',
              onTap: () => context.pushNamed('legal'),
            ),
          ],
        ),
        ModernSection(
          title: 'Account',
          icon: Symbols.account_circle,
          child: Center(
            child: FilledButton.tonalIcon(
              onPressed: () async {
                await AuthService.instance.signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Symbols.logout),
              label: const Text('Sign Out'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ModernSection(
      title: 'Profile',
      icon: Symbols.person,
      actions: [
        IconButton(
          icon: const Icon(Symbols.edit),
          onPressed: () => context.pushNamed('profile'),
        ),
      ],
      child: AnimatedBuilder(
        animation: ProfileStore.instance,
        builder: (context, _) {
          final profile = ProfileStore.instance;
          final name = profile.name.isNotEmpty ? profile.name : 'Wanderer';
          final email = profile.email.isNotEmpty
              ? profile.email
              : 'No email provided';

          return Row(
            children: [
              ProfileAvatar(
                photoUrl: profile.photoUrl.isNotEmpty ? profile.photoUrl : null,
                size: 64,
                icon: Symbols.person,
                backgroundColor: scheme.primaryContainer,
                iconColor: scheme.onPrimaryContainer,
              ),
              const HGap(Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const VGap(Insets.xs),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRemoteIdeasToggle() {
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        return SwitchListTile(
          value: _settings.remoteIdeasEnabled,
          onChanged: (value) => _settings.setRemoteIdeasEnabled(value),
          title: const Text('Fetch Explore Ideas from Backend'),
          subtitle: const Text('Falls back to local catalogue on errors'),
          secondary: const Icon(Symbols.public),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        );
      },
    );
  }

  Widget _buildPaymentsBackendTile(BuildContext context) {
    final backend = StripeService.instance.backendBaseUrl;
    return _buildSettingsTile(
      context,
      icon: Symbols.dns,
      title: 'Payments Backend',
      subtitle: backend ?? 'Not configured',
      trailing: backend == null
          ? null
          : IconButton(
              icon: const Icon(Symbols.wifi_tethering),
              onPressed: () => _pingBackend(context),
              tooltip: 'Ping Backend',
            ),
    );
  }

  Future<void> _pingBackend(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await StripeService.instance.pingBackend();
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Backend is reachable' : 'Backend not reachable'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: subtitle != null
          ? Text(subtitle, style: theme.textTheme.bodySmall)
          : null,
      trailing:
          trailing ?? const Icon(Symbols.arrow_forward_ios_rounded, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
