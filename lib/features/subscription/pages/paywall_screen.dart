import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/events.dart';
import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/pricing_tier.dart';
import '../subscription_controller.dart';

/// M7 — the fair shopkeeper. Pull, never push. Nothing pre-selected; equal
/// dignity at every price; the wall teaches its own exit. No countdowns, no
/// decoys, no nudge for choosing below the recommendation. No red.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.source = 'unknown'});

  final String source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PricingTier? _selected; // nothing pre-selected (M7 §3)
  bool _busy = false;

  // Pro = the guided program past Foundation. Articles are free for everyone
  // (decision #6), so they are never sold here.
  static const _benefits = [
    'the full 12-week program',
    'voice-guided audio',
    'weeks 5–12 adapted to you',
    'the complete session library',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appEventsProvider).paywallViewed(widget.source);
    });
  }

  Future<void> _continue() async {
    final tier = _selected!;
    final events = ref.read(appEventsProvider);
    events.paywallTierSelected(tier.name);

    // ₹0 path: close to the originating screen with a warm toast, logged once.
    if (!tier.requiresPurchase) {
      await ref.read(subscriptionControllerProvider).choose(tier);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(false);
      _showTrainOnToast(messenger, context.lamp);
      return;
    }

    setState(() => _busy = true);
    final ok = await ref.read(subscriptionControllerProvider).choose(tier);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      events.subscriptionStarted(tier.name);
      Navigator.of(context).pop(true);
    } else {
      // Inline, specific, no dialog (Part J — billing fail).
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Google Play couldn't complete this. Nothing was charged."),
        ),
      );
    }
  }

  /// The ₹0 dismissal toast (m7_02): single line, moss tick, fade only.
  void _showTrainOnToast(ScaffoldMessengerState messenger, LamplightTokens lamp) {
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2F2719),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: lamp.moss.withValues(alpha: 0.42)),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 16, color: lamp.mossBright),
            const SizedBox(width: 10),
            Flexible(
              child: Text("Done — the plan's yours. Pay later only if it helps.",
                  style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontWeight: FontWeight.w700,
                      color: lamp.ink)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final selected = _selected;

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sahaj Pro',
                                style: AppTypography.eyebrow(
                                    lamp.ochre.withValues(alpha: 0.92))),
                            _CloseBtn(lamp: lamp),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Pick what\'s reasonable for you',
                            style: theme.textTheme.displaySmall
                                ?.copyWith(fontSize: 25, height: 31 / 25)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 11),
                          child: RuleDivider(),
                        ),
                        Text(
                          'Same Sahaj Pro at every price. The scale exists '
                          'because incomes differ — choose what\'s fair and '
                          'we\'re square.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(height: 18 / 12),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _BenefitGrid(benefits: _benefits, lamp: lamp),
                        const SizedBox(height: AppSpacing.md),
                        for (final tier in PricingTier.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TierCard(
                              tier: tier,
                              selected: _selected == tier,
                              onTap: () => setState(() => _selected = tier),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: selected == null
                      ? 'Unlock forever'
                      : selected.requiresPurchase
                          ? 'Unlock forever'
                          : 'Keep training free',
                  loading: _busy,
                  onPressed: (selected == null || _busy) ? null : _continue,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  selected == null
                      ? 'Nothing is pre-selected — tap a tier first.'
                      : selected.requiresPurchase
                          ? '₹${selected.rupees} once · yours forever · no '
                              'renewal, nothing to cancel.'
                          : 'Free forever — the core program is yours.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(color: lamp.faint),
                ),
                AppButton(
                  label: 'Maybe later',
                  variant: AppButtonVariant.text,
                  onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseBtn extends StatelessWidget {
  const _CloseBtn({required this.lamp});
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: InkWell(
        onTap: () => Navigator.of(context).pop(false),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: lamp.hairline),
          ),
          child: Icon(Icons.close, size: 18, color: lamp.inkMuted),
        ),
      ),
    );
  }
}

class _BenefitGrid extends StatelessWidget {
  const _BenefitGrid({required this.benefits, required this.lamp});
  final List<String> benefits;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(String b) => Row(
          children: [
            Text('✓ ', style: TextStyle(color: lamp.mossBright, fontSize: 12)),
            Expanded(
              child: Text(b,
                  style: theme.textTheme.labelSmall?.copyWith(color: lamp.inkMuted)),
            ),
          ],
        );
    return Column(
      children: [
        for (var i = 0; i < benefits.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(child: row(benefits[i])),
                const SizedBox(width: 14),
                Expanded(
                    child: i + 1 < benefits.length
                        ? row(benefits[i + 1])
                        : const SizedBox.shrink()),
              ],
            ),
          ),
      ],
    );
  }
}

/// B2 `TierCard` — price (Fraunces) + meaning line + radio. Selected = ochre
/// border + filled radio. Equal height/weight at every price; the Recommended
/// chip is a label and never moves.
class TierCard extends StatelessWidget {
  const TierCard({
    super.key,
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
    final lamp = context.lamp;

    return Semantics(
      button: true,
      selected: selected,
      label: '${tier.priceLabel}${tier.requiresPurchase ? ' once' : ''}. '
          '${tier.meaning}${tier.isRecommended ? ' Recommended.' : ''}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [const Color(0xFF3A2D14), const Color(0xFF27200F)]
                  : [const Color(0xFF272019), const Color(0xFF1F1A14)],
            ),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: selected
                  ? lamp.gold.withValues(alpha: 0.6)
                  : tier.isRecommended
                      ? lamp.gold.withValues(alpha: 0.3)
                      : lamp.ink.withValues(alpha: 0.09),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected || tier.isRecommended
                ? [
                    BoxShadow(
                      color: lamp.ochre.withValues(alpha: 0.4),
                      blurRadius: 36,
                      spreadRadius: -16,
                      offset: const Offset(0, 16),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: tier.priceLabel,
                                style: AppTypography.numeral(21, lamp.gold),
                              ),
                              if (tier.requiresPurchase)
                                TextSpan(
                                  text: ' once',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: lamp.gold),
                                ),
                            ],
                          ),
                        ),
                        if (tier.isRecommended) _RecommendedChip(lamp: lamp),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(tier.meaning,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: lamp.faint, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _Radio(selected: selected, lamp: lamp),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedChip extends StatelessWidget {
  const _RecommendedChip({required this.lamp});
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: lamp.moss.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: lamp.moss.withValues(alpha: 0.4)),
      ),
      child: Text('Recommended',
          style: TextStyle(
            fontFamily: AppTypography.body,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: lamp.mossBright,
          )),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.lamp});
  final bool selected;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? lamp.gold : lamp.faint,
          width: selected ? 6 : 2,
        ),
      ),
    );
  }
}
