import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

/// What the user chose on the milestone variant.
enum CompletionAction { finish, takeCheckin, tomorrow }

/// M1·6 — the feeling after riyaz. Reward = information + one moment of
/// beauty: the strokes bloom into the lotus (700ms line-draw; fade under
/// reduced motion). Never confetti, never sound, never share buttons.
class CompletionPage extends StatelessWidget {
  const CompletionPage({
    super.key,
    required this.sessionNumber,
    required this.nthThisWeek,
    this.tomorrowTitle,
    this.tomorrowMinutes,
    this.milestoneWeek,
    this.currentWeek = 1,
  });

  final int sessionNumber;

  /// 1-based count of sessions completed this week (info line).
  final int nthThisWeek;

  final String? tomorrowTitle;
  final int? tomorrowMinutes;

  /// 4, 8 or 12 — switches to the milestone variant (the only ceremony
  /// upgrade: one lit node on the spine, the week-0 promise coming due).
  final int? milestoneWeek;

  /// For the milestone spine.
  final int currentWeek;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final theme = Theme.of(context);
    final milestone = milestoneWeek != null;

    return Scaffold(
      body: LampBackground(
        room: LampRoom.deep,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    // Scrolls instead of clipping at large text sizes.
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: milestone ? 210 : 200,
                            child: Center(
                              child: _LotusBloom(
                                size: milestone ? 230 : 220,
                                crownEmber: milestone,
                              ),
                            ),
                          ),
                          if (milestone) ...[
                            const SizedBox(height: AppSpacing.md),
                            Center(
                              child: Text(
                                'Milestone',
                                style: AppTypography.eyebrow(
                                  lamp.ochre.withValues(alpha: 0.92),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Week $milestoneWeek, done.',
                              textAlign: TextAlign.center,
                              style: AppTypography.numeral(50, lamp.ink),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _milestoneLine(milestoneWeek!),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontSize: 18.5,
                                color: lamp.inkMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: AppSpacing.sm,
                              children: const [
                                AppChip(
                                  label: '2 minutes',
                                  variant: AppChipVariant.ok,
                                ),
                                AppChip(label: 'measured, not guessed'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                              ),
                              child: _JourneySpineRow(
                                currentWeek: currentWeek,
                                litMilestone: milestoneWeek!,
                                lamp: lamp,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Done.',
                              textAlign: TextAlign.center,
                              style: AppTypography.numeral(54, lamp.ink),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Session $sessionNumber · ${_ordinalWeekLine(nthThisWeek)}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: lamp.inkMuted,
                              ),
                            ),
                            if (tomorrowTitle != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: AppSpacing.sm,
                                children: [
                                  AppChip(label: 'Tomorrow · $tomorrowTitle'),
                                  if (tomorrowMinutes != null)
                                    AppChip(label: '$tomorrowMinutes min'),
                                ],
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            // One of the pothi rule's four sanctioned placements (A4).
                            const Center(child: RuleDivider(width: 180)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (milestone) ...[
                  AppButton(
                    label: 'Take the check-in',
                    onPressed: () =>
                        Navigator.of(context).pop(CompletionAction.takeCheckin),
                  ),
                  AppButton(
                    label: 'Tomorrow',
                    variant: AppButtonVariant.text,
                    onPressed: () =>
                        Navigator.of(context).pop(CompletionAction.tomorrow),
                  ),
                ] else
                  AppButton(
                    label: 'Finish',
                    onPressed: () =>
                        Navigator.of(context).pop(CompletionAction.finish),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _milestoneLine(int week) => switch (week) {
    4 => 'Foundation complete — your first check-in is ready.',
    8 => 'Integration complete — your next check-in is ready.',
    _ => 'Mastery complete — your final check-in is ready.',
  };

  String _ordinalWeekLine(int n) => switch (n) {
    1 => 'first this week.',
    2 => 'second this week.',
    3 => 'third this week.',
    4 => 'fourth this week.',
    5 => 'fifth this week.',
    6 => 'sixth this week.',
    _ => 'seventh this week.',
  };
}

/// 12 segments in 3 phase groups with milestone diamonds at weeks 4/8/12
/// (mock m1_06b). Past = moss, current = ochre glow, future = faint.
class _JourneySpineRow extends StatelessWidget {
  const _JourneySpineRow({
    required this.currentWeek,
    required this.litMilestone,
    required this.lamp,
  });

  final int currentWeek;
  final int litMilestone;
  final LamplightTokens lamp;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var week = 1; week <= 12; week++) {
      children.add(
        Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: week <= currentWeek
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF9CB48E), Color(0xFF71895F)],
                    )
                  : null,
              color: week > currentWeek
                  ? lamp.ink.withValues(alpha: 0.07)
                  : null,
              border: week > currentWeek
                  ? Border.all(color: lamp.ink.withValues(alpha: 0.07))
                  : null,
            ),
          ),
        ),
      );
      if (week % 4 == 0) {
        final lit = week == litMilestone;
        children.add(
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: lit ? lamp.gold : lamp.sand.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(2),
                boxShadow: lit
                    ? [
                        BoxShadow(
                          color: lamp.ochre.withValues(alpha: 0.6),
                          blurRadius: 9,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }
    }
    return Semantics(
      label: 'Week $currentWeek of 12',
      child: Row(children: children),
    );
  }
}

/// The lotus mark drawn stroke by stroke inside two faint ray rings.
/// Reduced motion: a simple fade.
class _LotusBloom extends StatefulWidget {
  const _LotusBloom({required this.size, this.crownEmber = false});

  final double size;

  /// Milestone variant: a single ember at the crown of the rays.
  final bool crownEmber;

  @override
  State<_LotusBloom> createState() => _LotusBloomState();
}

class _LotusBloomState extends State<_LotusBloom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: AppMotion.calm,
  )..forward();

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final reduced = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _draw,
      builder: (context, _) {
        final t = reduced ? 1.0 : AppMotion.enter.transform(_draw.value);
        final opacity = reduced ? AppMotion.exit.transform(_draw.value) : 1.0;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _LotusBloomPainter(
              progress: t,
              gold: lamp.gold,
              goldDeep: const Color(0xFFB07A2B),
              ochre: lamp.ochre,
              sand: lamp.sand,
              crownEmber: widget.crownEmber,
            ),
          ),
        );
      },
    );
  }
}

class _LotusBloomPainter extends CustomPainter {
  _LotusBloomPainter({
    required this.progress,
    required this.gold,
    required this.goldDeep,
    required this.ochre,
    required this.sand,
    required this.crownEmber,
  });

  final double progress;
  final Color gold;
  final Color goldDeep;
  final Color ochre;
  final Color sand;
  final bool crownEmber;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    // Ray rings (dashed) fade in with the draw.
    void rayRing(double radius, double alpha, double dash, double gap) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = ochre.withValues(alpha: alpha * progress);
      final circumference = 2 * math.pi * radius;
      final ticks = (circumference / (dash + gap)).round();
      for (var i = 0; i < ticks; i++) {
        final angle = 2 * math.pi * i / ticks - math.pi / 2;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          angle,
          dash / radius,
          false,
          paint,
        );
      }
    }

    rayRing(size.shortestSide * 0.436, 0.16, 2, 15);
    rayRing(size.shortestSide * 0.336, 0.10, 2, 11);

    if (crownEmber && progress > 0.8) {
      canvas.drawCircle(
        Offset(center.dx, center.dy - size.shortestSide * 0.468),
        3.2,
        Paint()..color = gold.withValues(alpha: (progress - 0.8) / 0.2),
      );
    }

    // Lotus strokes in a 100-unit space, ~118px tall at 220 size.
    final lotusSize = size.shortestSide * 0.54;
    final s = lotusSize / 100;
    final origin = Offset(center.dx - lotusSize / 2, center.dy - lotusSize / 2);
    Offset p(double x, double y) =>
        Offset(origin.dx + x * s, origin.dy + y * s);

    final paths = <(Path, double)>[
      // (path, opacity)
      (
        Path()
          ..moveTo(p(50, 18).dx, p(50, 18).dy)
          ..cubicTo(
            p(40, 34).dx,
            p(40, 34).dy,
            p(40, 52).dx,
            p(40, 52).dy,
            p(50, 66).dx,
            p(50, 66).dy,
          )
          ..cubicTo(
            p(60, 52).dx,
            p(60, 52).dy,
            p(60, 34).dx,
            p(60, 34).dy,
            p(50, 18).dx,
            p(50, 18).dy,
          ),
        1.0,
      ),
      (
        Path()
          ..moveTo(p(24, 38).dx, p(24, 38).dy)
          ..cubicTo(
            p(28, 56).dx,
            p(28, 56).dy,
            p(37, 65).dx,
            p(37, 65).dy,
            p(50, 66).dx,
            p(50, 66).dy,
          ),
        1.0,
      ),
      (
        Path()
          ..moveTo(p(76, 38).dx, p(76, 38).dy)
          ..cubicTo(
            p(72, 56).dx,
            p(72, 56).dy,
            p(63, 65).dx,
            p(63, 65).dy,
            p(50, 66).dx,
            p(50, 66).dy,
          ),
        1.0,
      ),
      (
        Path()
          ..moveTo(p(14, 50).dx, p(14, 50).dy)
          ..cubicTo(
            p(20, 64).dx,
            p(20, 64).dy,
            p(33, 71).dx,
            p(33, 71).dy,
            p(50, 71).dx,
            p(50, 71).dy,
          ),
        0.55,
      ),
      (
        Path()
          ..moveTo(p(86, 50).dx, p(86, 50).dy)
          ..cubicTo(
            p(80, 64).dx,
            p(80, 64).dy,
            p(67, 71).dx,
            p(67, 71).dy,
            p(50, 71).dx,
            p(50, 71).dy,
          ),
        0.55,
      ),
    ];

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    for (final (path, alpha) in paths) {
      for (final metric in path.computeMetrics()) {
        final partial = metric.extractPath(
          0,
          metric.length * progress.clamp(0.0, 1.0),
        );
        final shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gold, goldDeep],
        ).createShader(path.getBounds());
        canvas.drawPath(
          partial,
          glowPaint
            ..shader = shader
            ..color = gold.withValues(alpha: 0.45 * alpha),
        );
        canvas.drawPath(
          partial,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round
            ..shader = shader,
        );
      }
    }

    // Sand dot at the base, after the strokes land.
    if (progress > 0.9) {
      canvas.drawCircle(
        p(50, 79),
        2.6 * s,
        Paint()..color = sand.withValues(alpha: (progress - 0.9) / 0.1),
      );
    }
  }

  @override
  bool shouldRepaint(_LotusBloomPainter old) =>
      old.progress != progress || old.crownEmber != crownEmber;
}
