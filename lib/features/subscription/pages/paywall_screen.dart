import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/events.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/pricing_tier.dart';
import '../subscription_controller.dart';

/// Pay-what-you-can paywall (synthesis §8). Soft by design — the close button
/// is always present, "Maybe later" is always available, no countdowns, no
/// fake urgency, no red. The price is a price.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.source = 'unknown'});

  /// Where the paywall was opened from (analytics).
  final String source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PricingTier _selected = PricingTier.standard;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appEventsProvider).paywallViewed(widget.source);
    });
  }

  Future<void> _continue() async {
    final events = ref.read(appEventsProvider);
    events.paywallTierSelected(_selected.name);
    setState(() => _busy = true);
    final ok = await ref.read(subscriptionControllerProvider).choose(_selected);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      events.subscriptionStarted(_selected.name);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pro unlocked. Welcome.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("That didn't complete. No charge was made."),
        ),
      );
    }
  }

  String get _ctaLabel => _selected.requiresPurchase
      ? 'Continue with ₹${_selected.rupees} / year'
      : 'Continue free';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Pro',
      leading: const CloseButton(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pro unlocks the full 12-week protocol',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pick what is reasonable for you. Money should not be the reason '
            'you do not get better. Same access at every price.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final tier in PricingTier.values) ...[
            _TierCard(
              tier: tier,
              selected: _selected == tier,
              onTap: () => setState(() => _selected = tier),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: _ctaLabel,
            loading: _busy,
            onPressed: _busy ? null : _continue,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Maybe later'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Annual subscription. Cancel anytime in Google Play; refunds per '
            'Play policy. The ₹0 tier is for those who genuinely cannot afford '
            'it and unlocks the same content.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.selected,
    required this.onTap,
  });

  final PricingTier tier;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final priceText = tier.rupees == 0 ? '₹0' : '₹${tier.rupees}';

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('$priceText / year',
                            style: theme.textTheme.titleMedium),
                        if (tier.isRecommended) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text('Recommended',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onPrimary,
                                )),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(tier.label, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
