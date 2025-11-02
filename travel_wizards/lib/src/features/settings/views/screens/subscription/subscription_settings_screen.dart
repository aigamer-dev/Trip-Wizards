import 'package:flutter/material.dart';
import 'package:travel_wizards/src/core/app/settings_controller.dart';
import 'package:travel_wizards/src/shared/services/iap_service.dart';
import 'dart:io' show Platform;
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/services/payments_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SubscriptionSettingsScreen extends StatelessWidget {
  const SubscriptionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final theme = Theme.of(context);

    Widget billingBanner() {
      if (!Platform.isAndroid) {
        return const SizedBox.shrink();
      }
      return FutureBuilder<bool>(
        future: IAPService.instance.isAvailable(),
        builder: (context, snap) {
          final available = snap.data ?? false;
          if (available) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.onErrorContainer,
                ),
                title: Text(
                  'Google Play Billing unavailable',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                subtitle: Text(
                  'Ensure you are signed into Play Store, use an internal testing account, and that product SKUs exist.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    Widget planCard({
      required String tier,
      required String title,
      required String price,
      String? subPrice,
      required List<String> features,
      bool recommended = false,
    }) {
      final isSelected = settings.subscriptionTier == tier;
      return Card.filled(
        elevation: isSelected ? 2 : 0,
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSelected
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: Insets.allMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(title, style: theme.textTheme.titleLarge),
                            if (recommended) ...[
                              Gaps.w8,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Popular',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              price,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (subPrice != null) ...[
                              Gaps.w8,
                              Text(
                                subPrice,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      Gaps.w8,
                      Expanded(
                        child: Text(f, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
              Gaps.h8,
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: isSelected
                      ? null
                      : () async {
                          // Google Play subscriptions (Android only)
                          if (!Platform.isAndroid) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Subscriptions are available on Android via Google Play.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          final ok = await IAPService.instance.init();
                          if (!ok) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Billing not available'),
                                ),
                              );
                            }
                            return;
                          }
                          final sku = tier == 'pro'
                              ? IAPService.skuProMonthly
                              : (tier == 'enterprise'
                                    ? IAPService.skuEnterpriseMonthly
                                    : null);
                          if (sku == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invalid plan')),
                              );
                            }
                            return;
                          }
                          final product = await IAPService.instance.getProduct(
                            sku,
                          );
                          if (product == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Product not found. Check Play Console product IDs and use a test account.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          // Show simple progress dialog
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final success = await IAPService.instance
                              .buySubscriptionWithResult(product);
                          if (context.mounted) Navigator.of(context).pop();
                          if (success) {
                            await settings.setSubscriptionTier(tier);
                            // Log payment entry
                            final amountCents = tier == 'pro'
                                ? 500
                                : (tier == 'enterprise' ? 1000 : 0);
                            if (amountCents > 0) {
                              await PaymentsRepository.instance.logPayment(
                                type: 'subscription',
                                title: title,
                                amountCents: amountCents,
                                currency: 'USD',
                                status: 'success',
                                productId: product.id,
                                platform: 'google_play',
                              );
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Subscribed to $title')),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Purchase failed or canceled'),
                                ),
                              );
                            }
                          }
                        },
                  child: Text(isSelected ? 'Selected' : 'Choose'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return ListView(
          padding: Insets.allMd,
          children: [
            billingBanner(),
            Text('Choose a plan', style: theme.textTheme.titleLarge),
            Gaps.h8,
            Text(
              'Upgrade anytime. Downgrade takes effect next billing cycle.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (Platform.isAndroid) ...[
              Gaps.h8,
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.manage_accounts_rounded),
                  label: const Text('Manage on Google Play'),
                  onPressed: () async {
                    try {
                      final info = await PackageInfo.fromPlatform();
                      final pkg = info.packageName;
                      final uri = Uri.parse(
                        'https://play.google.com/store/account/subscriptions?package=$pkg',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot open Play subscriptions'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
              ),
            ],
            Gaps.h16,
            planCard(
              tier: 'free',
              title: 'Free',
              price: '\$0',
              features: const [
                '1 AI plan/day',
                'Basic itinerary builder',
                'Community templates',
              ],
            ),
            const SizedBox(height: 12),
            planCard(
              tier: 'pro',
              title: 'Pro',
              price: '\$5/mo',
              features: const [
                'Up to 5 AI plans/day',
                'Smart budget suggestions',
                'Offline access on mobile',
                'Priority support',
              ],
              recommended: true,
            ),
            const SizedBox(height: 12),
            planCard(
              tier: 'enterprise',
              title: 'Enterprise',
              price: '\$10/mo',
              subPrice: '+ \$4 per additional user',
              features: const [
                'Team workspaces & sharing',
                'Admin controls & SSO',
                'Unlimited AI plans/day',
                'Dedicated support SLAs',
              ],
            ),
            Gaps.h16,
            Text(
              'Note: Pricing is illustrative for this demo and not a real offer.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
