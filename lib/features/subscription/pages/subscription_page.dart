import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/events.dart';
import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import '../subscription_controller.dart';
import 'paywall_screen.dart';

/// M7 §2 — subscription management. Calm, value-restating, dates not
/// countdowns. Free users see "It stays free" + a quiet See Pro; trial and
/// active users see their plan and dates, plus Play manage + restore.
class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  static const _playSubsUrl =
      'https://play.google.com/store/account/subscriptions';
  String? _restoreResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final sub = ref.watch(subscriptionControllerProvider);

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.chevron_left, color: lamp.inkMuted),
                    ),
                    Text('Subscription', style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!sub.isPro)
                          _FreeCard(lamp: lamp, theme: theme, onSeePro: _openPaywall)
                        else
                          _ProCard(sub: sub, lamp: lamp, theme: theme),
                        const SizedBox(height: AppSpacing.md),
                        if (sub.isPro)
                          _ManageCard(
                            lamp: lamp,
                            theme: theme,
                            onManage: _openPlay,
                            onRestore: _restore,
                          )
                        else
                          AppButton(
                            label: 'Restore purchases',
                            variant: AppButtonVariant.outlined,
                            onPressed: _restore,
                          ),
                        if (_restoreResult != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(_restoreResult!,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: lamp.faint)),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _Strip(
                          'Subscriptions are handled by Play — we never see '
                          'your card.',
                          lamp: lamp,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PaywallScreen(source: 'subscription_page'),
      ),
    );
  }

  Future<void> _restore() async {
    final ok = await ref.read(subscriptionControllerProvider).restore();
    if (ok) ref.read(appEventsProvider).subscriptionRestored();
    if (!mounted) return;
    setState(() =>
        _restoreResult = ok ? 'Pro restored.' : 'No purchases to restore.');
  }

  Future<void> _openPlay() async {
    try {
      await launchUrl(Uri.parse(_playSubsUrl),
          mode: LaunchMode.externalApplication);
    } catch (_) {/* best effort */}
  }
}

class _FreeCard extends StatelessWidget {
  const _FreeCard({
    required this.lamp,
    required this.theme,
    required this.onSeePro,
  });
  final LamplightTokens lamp;
  final ThemeData theme;
  final VoidCallback onSeePro;

  @override
  Widget build(BuildContext context) {
    return _HeroCard(
      lamp: lamp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current plan',
              style: AppTypography.eyebrow(lamp.inkMuted.withValues(alpha: 0.72))),
          const SizedBox(height: AppSpacing.sm),
          Text("You're on Free", style: theme.textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text('It stays free.',
              style: theme.textTheme.bodySmall?.copyWith(color: lamp.inkMuted)),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: 'See Pro', onPressed: onSeePro),
        ],
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.sub, required this.lamp, required this.theme});
  final SubscriptionController sub;
  final LamplightTokens lamp;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final price = sub.tier?.priceLabel ?? '₹0';
    final paid = sub.tier?.requiresPurchase ?? false;

    return _HeroCard(
      lamp: lamp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current plan',
              style: AppTypography.eyebrow(lamp.inkMuted.withValues(alpha: 0.72))),
          const SizedBox(height: AppSpacing.sm),
          Text('Sahaj Pro', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              AppChip(label: paid ? '$price · paid once' : 'granted at ₹0'),
              const AppChip(label: 'yours forever', variant: AppChipVariant.ok),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            paid
                ? 'Paid once, kept forever — no renewal, nothing to cancel.'
                : 'Pro, granted at ₹0. The full protocol is yours.',
            style: theme.textTheme.bodySmall?.copyWith(color: lamp.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.lamp, required this.child});
  final LamplightTokens lamp;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF332915), Color(0xFF251E14)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: lamp.ochre.withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              bottom: -44,
              child: LotusMark(
                  size: 150, color: lamp.ochre.withValues(alpha: 0.13)),
            ),
            Padding(padding: const EdgeInsets.all(22), child: child),
          ],
        ),
      ),
    );
  }
}

class _ManageCard extends StatelessWidget {
  const _ManageCard({
    required this.lamp,
    required this.theme,
    required this.onManage,
    required this.onRestore,
  });
  final LamplightTokens lamp;
  final ThemeData theme;
  final VoidCallback onManage;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, Color tint, String label, VoidCallback onTap) =>
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: tint.withValues(alpha: 0.12),
                    border: Border.all(color: tint.withValues(alpha: 0.26)),
                  ),
                  child: Icon(icon, size: 18, color: tint),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(label,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Icon(Icons.chevron_right, color: lamp.faint),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2419), Color(0xFF221C15)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: lamp.hairline),
      ),
      child: Column(
        children: [
          tile(Icons.play_arrow, lamp.gold, 'Manage in Google Play', onManage),
          Divider(height: 1, color: lamp.hairline),
          tile(Icons.refresh, lamp.sand, 'Restore purchases', onRestore),
        ],
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip(this.text, {required this.lamp, required this.theme});
  final String text;
  final LamplightTokens lamp;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: lamp.ochre.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: lamp.ochre.withValues(alpha: 0.55), width: 2.5),
        ),
      ),
      child: Text(text,
          style: theme.textTheme.bodySmall?.copyWith(color: lamp.inkMuted)),
    );
  }
}
