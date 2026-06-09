import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/events.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../subscription_controller.dart';
import 'paywall_screen.dart';

/// Subscription management (synthesis §8). Calm, value-restating copy — never
/// fear. Free users see an invitation to Pro; Pro users see their tier and a
/// link to manage in Google Play.
class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  static const _playSubsUrl =
      'https://play.google.com/store/account/subscriptions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sub = ref.watch(subscriptionControllerProvider);

    return AppScaffold(
      title: 'Subscription',
      leading: const BackButton(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.isPro ? 'Sahaj Pro' : 'Free tier',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  sub.isPro
                      ? (sub.tier?.rupees == 0
                          ? 'Pro, granted at ₹0. The full protocol is yours.'
                          : 'Thank you for supporting Sahaj. The full protocol is yours.')
                      : 'The free tier works forever — basics, mood check-in, '
                          'discreet mode. Pro adds the full 12-week protocol.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (!sub.isPro) ...[
            AppButton(
              label: 'See Pro options',
              onPressed: () => _openPaywall(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Restore purchases',
              variant: AppButtonVariant.outlined,
              onPressed: () => _restore(context, ref),
            ),
          ] else ...[
            AppButton(
              label: 'Manage in Google Play',
              variant: AppButtonVariant.outlined,
              onPressed: _openPlay,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Why Pro: the full 12-week protocol is the part that builds real, '
            'lasting control. Your support also funds the ₹0 tier for men who '
            "can't pay. No countdowns, no pressure — upgrade when it's right.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaywall(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PaywallScreen(source: 'subscription_page'),
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(subscriptionControllerProvider).restore();
    if (ok) ref.read(appEventsProvider).subscriptionRestored();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Pro restored.' : 'No purchases to restore.'),
      ),
    );
  }

  Future<void> _openPlay() async {
    try {
      await launchUrl(Uri.parse(_playSubsUrl),
          mode: LaunchMode.externalApplication);
    } catch (_) {/* best effort */}
  }
}
