import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/app/settings_controller.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/config/env.dart';
import 'package:travel_wizards/src/l10n/app_localizations.dart';
import 'package:travel_wizards/src/services/auth_service.dart';
import 'package:travel_wizards/src/services/stripe_service.dart';
import 'package:travel_wizards/src/data/profile_store.dart';
// Notifications controls moved to Privacy & Notifications screen.

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final settings = AppSettings.instance;
    // Ensure profile data is loaded for the top card
    ProfileStore.instance.load();
    return Scaffold(
      body: ListView(
        padding: Insets.allMd,
        children: [
          Text(t.settings, style: Theme.of(context).textTheme.titleLarge),
          Gaps.h16,
          // Profile card at top
          AnimatedBuilder(
            animation: ProfileStore.instance,
            builder: (context, _) {
              final name = ProfileStore.instance.name;
              final email = ProfileStore.instance.email;
              final photoUrl = ProfileStore.instance.photoUrl;
              return Card(
                child: Padding(
                  padding: Insets.allMd,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? const Icon(Icons.person_rounded)
                            : null,
                      ),
                      Gaps.w16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isNotEmpty ? name : 'Your name',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email.isNotEmpty ? email : 'Add email',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.pushNamed('profile'),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Gaps.h24,
          // Payments backend status
          StatefulBuilder(
            builder: (ctx, setState) {
              final backend = StripeService.instance.backendBaseUrl;
              return ListTile(
                leading: const Icon(Icons.cloud_rounded),
                title: const Text('Payments backend'),
                subtitle: Text(
                  backend ??
                      'No backend configured (STRIPE_BACKEND_URL/BACKEND_BASE_URL)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: backend == null
                    ? const Chip(label: Text('Not set'))
                    : FilledButton.tonal(
                        onPressed: () async {
                          final ok = await StripeService.instance.pingBackend();
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Backend reachable'
                                      : 'Backend not reachable',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Ping'),
                      ),
                onTap: backend == null
                    ? null
                    : () async {
                        final ok = await StripeService.instance.pingBackend();
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Backend reachable'
                                    : 'Backend not reachable',
                              ),
                            ),
                          );
                        }
                      },
              );
            },
          ),
          Gaps.h24,
          if (kUseRemoteIdeas) ...[
            Text('Data Source'),
            Gaps.h8,
            Semantics(
              container: true,
              label: 'Use remote ideas (toggle)',
              child: SwitchListTile(
                value: settings.remoteIdeasEnabled,
                title: const Text('Fetch Explore ideas from backend'),
                subtitle: const Text('Falls back to local data on errors'),
                onChanged: (v) => settings.setRemoteIdeasEnabled(v),
              ),
            ),
            Gaps.h24,
          ],
          // Removed Login/Sign up button: sign-in is mandatory and handled globally.
          ListTile(
            leading: const Icon(Icons.map_rounded),
            title: const Text('Map Demo'),
            subtitle: const Text('Verify Google Maps key'),
            onTap: () => context.pushNamed('map_demo'),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded),
            title: const Text('Concierge (ADK)'),
            subtitle: const Text('Chat and stream results via /adk/run_sse'),
            onTap: () => context.pushNamed('concierge'),
          ),
          Gaps.h24,
          ListTile(
            leading: const Icon(Symbols.lock_open_right_rounded),
            title: const Text('Privacy & notifications'),
            subtitle: const Text('Manage privacy and notification preferences'),
            onTap: () => context.pushNamed('privacy_settings'),
          ),
          Gaps.h24,
          Text('Payments & subscription'),
          Gaps.h8,
          // Payment options and history
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded),
            title: const Text('Payment options'),
            subtitle: const Text(
              'Cards, UPI, Google Pay, etc. (on-device only)',
            ),
            onTap: () => context.pushNamed('payment_options'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_rounded),
            title: const Text('Payment history'),
            onTap: () => context.pushNamed('payment_history'),
          ),
          // Payments backend status (moved under this section)
          StatefulBuilder(
            builder: (ctx, setState) {
              final backend = StripeService.instance.backendBaseUrl;
              return ListTile(
                leading: const Icon(Icons.cloud_rounded),
                title: const Text('Payments backend'),
                subtitle: Text(
                  backend ??
                      'No backend configured (STRIPE_BACKEND_URL/BACKEND_BASE_URL)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: backend == null
                    ? const Chip(label: Text('Not set'))
                    : FilledButton.tonal(
                        onPressed: () async {
                          final ok = await StripeService.instance.pingBackend();
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Backend reachable'
                                      : 'Backend not reachable',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Ping'),
                      ),
                onTap: backend == null
                    ? null
                    : () async {
                        final ok = await StripeService.instance.pingBackend();
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Backend reachable'
                                    : 'Backend not reachable',
                              ),
                            ),
                          );
                        }
                      },
              );
            },
          ),
          Gaps.h8,
          ListTile(
            leading: const Icon(Icons.workspace_premium_rounded),
            title: const Text('Manage subscription'),
            subtitle: Text('Current: ${settings.subscriptionTier}'),
            onTap: () => context.pushNamed('subscription_settings'),
          ),
          Gaps.h24,
          Text(t.language),
          Gaps.h8,
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('App language'),
            subtitle: Text(
              settings.locale?.languageCode.toUpperCase() ?? t.systemDefault,
            ),
            onTap: () => context.pushNamed('language_settings'),
          ),
          Gaps.h24,
          Text('Permissions'),
          Gaps.h8,
          ListTile(
            leading: const Icon(Symbols.shield_lock_rounded),
            title: const Text('Manage Permissions'),
            subtitle: const Text('Allow or revoke app permissions'),
            onTap: () => context.pushNamed('permissions'),
          ),
          const Divider(height: 24),
          Text('Info & Support'),
          Gaps.h8,
          ListTile(
            leading: const Icon(Symbols.info_rounded),
            title: const Text('About'),
            onTap: () => context.pushNamed('about'),
          ),
          ListTile(
            leading: const Icon(Symbols.gavel_rounded),
            title: const Text('Legal'),
            onTap: () => context.pushNamed('legal'),
          ),
          ListTile(
            leading: const Icon(Symbols.help_rounded),
            title: const Text('Help'),
            onTap: () => context.pushNamed('help'),
          ),
          ListTile(
            leading: const Icon(Symbols.quiz_rounded),
            title: const Text('FAQ'),
            onTap: () => context.pushNamed('faq'),
          ),
          ListTile(
            leading: const Icon(Symbols.school_rounded),
            title: const Text('Tutorials'),
            onTap: () => context.pushNamed('tutorials'),
          ),
          ListTile(
            leading: const Icon(Symbols.feedback_rounded),
            title: const Text('Feedback'),
            onTap: () => context.pushNamed('feedback'),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () async {
              await AuthService.instance.signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
      // Bottom navigation is provided by the NavShell.
    );
  }
}
