import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/plan_reveal_lines.dart';
import '../onboarding_controller.dart';
import '../widgets/onb_chrome.dart';

/// C10 — the plan reveal. The only "wow": an eight-beat stagger over ~700ms,
/// top to bottom. Reduced-motion renders instantly, fully formed.
class PlanRevealScreen extends ConsumerWidget {
  const PlanRevealScreen({super.key, required this.onNext, required this.onBack});
  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _phases = [
    ('Foundation', 'wk 1–4', 'Find it, feel it, breathe.'),
    ('Integration', 'wk 5–8', 'Combine, stop-start, sensate.'),
    ('Mastery', 'wk 9–12', 'Functional control, rehearsal, readiness.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final lines = planRevealLines(ref.read(onboardingControllerProvider).goals);

    var beat = 0;
    Widget stagger(Widget child) =>
        _Beat(index: beat++, reduced: reduced, child: child);

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: Column(
              children: [
                OnbTopBar(onBack: onBack),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        stagger(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const OnbEyebrow('Built from your answers'),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Your 12 weeks',
                                style: theme.textTheme.displaySmall
                                    ?.copyWith(fontSize: 33)),
                          ],
                        )),
                        stagger(const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: RuleDivider(),
                        )),
                        // Phase rail.
                        for (var i = 0; i < _phases.length; i++) ...[
                          stagger(_PhaseCard(
                            title: _phases[i].$1,
                            range: _phases[i].$2,
                            blurb: _phases[i].$3,
                            lamp: lamp,
                          )),
                          stagger(Padding(
                            padding:
                                const EdgeInsets.fromLTRB(4, 8, 0, 8),
                            child: Text(
                              switch (i) {
                                0 => 'Week 4 — check-in · measured, not guessed',
                                1 => 'Week 8 — check-in',
                                _ => 'Week 12 — your comparison, week 0 vs now',
                              },
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: i == 2 ? lamp.gold : lamp.faint,
                              ),
                            ),
                          )),
                        ],
                        if (lines.isNotEmpty)
                          stagger(_PersonalizedCard(lines: lines, lamp: lamp)),
                        stagger(const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              AppChip(label: '5–15 min/day'),
                              AppChip(label: '12 weeks'),
                              AppChip(
                                  label: 'free to finish',
                                  variant: AppChipVariant.ok),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                stagger(AppButton(
                  label: 'Looks right — set up privacy',
                  onPressed: onNext,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade + rise, staggered by index (~90ms apart, ~700ms total). Instant under
/// reduced motion.
class _Beat extends StatefulWidget {
  const _Beat({required this.index, required this.reduced, required this.child});
  final int index;
  final bool reduced;
  final Widget child;

  @override
  State<_Beat> createState() => _BeatState();
}

class _BeatState extends State<_Beat> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.settle,
  );

  @override
  void initState() {
    super.initState();
    if (widget.reduced) {
      _c.value = 1;
    } else {
      Future<void>.delayed(
        Duration(milliseconds: 80 * widget.index),
        () {
          if (mounted) _c.forward();
        },
      );
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = AppMotion.enter.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.title,
    required this.range,
    required this.blurb,
    required this.lamp,
  });
  final String title;
  final String range;
  final String blurb;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 16)),
              AppChip(label: range),
            ],
          ),
          const SizedBox(height: 6),
          Text(blurb, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PersonalizedCard extends StatelessWidget {
  const _PersonalizedCard({required this.lines, required this.lamp});
  final List<String> lines;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF332915), Color(0xFF251E14)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: lamp.ochre.withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              bottom: -44,
              child: LotusMark(
                size: 150,
                color: lamp.ochre.withValues(alpha: 0.13),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  Text(
                    lines[i],
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 19 / 13,
                      color: lamp.gold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
