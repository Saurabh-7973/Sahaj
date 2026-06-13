import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../logic/dashboard_logic.dart';

/// Card chrome used across the dashboard (mock `.card`, 13/16 padding).
class DashCard extends StatelessWidget {
  const DashCard({super.key, required this.child, this.warm = false});

  final Widget child;

  /// Post-check-in warm border (ochre 30%).
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2419), Color(0xFF221C15)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: warm
              ? lamp.ochre.withValues(alpha: 0.3)
              : lamp.hairline,
        ),
      ),
      child: child,
    );
  }
}

/// Right-aligned source tag — mandatory on every chart (doctrine §0.1).
class SourceTag extends StatelessWidget {
  const SourceTag(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppTypography.body,
            fontSize: 10.5,
            letterSpacing: 0.4,
            color: lamp.faint,
          ),
        ),
      ),
    );
  }
}

/// Tiny tracked-out section eyebrow inside cards (mock `.tiny` uppercase).
class CardKicker extends StatelessWidget {
  const CardKicker(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: AppTypography.body,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color ?? lamp.faint,
      ),
    );
  }
}

/// Horizontal 12-week journey spine with phase diamonds at 4/8/12. Past =
/// moss, current week = ochre glow, future = faint. The same artifact the
/// user met at plan reveal (continuity is the trick).
class JourneySpine extends StatelessWidget {
  const JourneySpine({super.key, required this.currentWeek});

  final int currentWeek;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final children = <Widget>[];
    for (var week = 1; week <= 12; week++) {
      children.add(Expanded(
        child: Container(
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: week < currentWeek
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF9CB48E), Color(0xFF71895F)],
                  )
                : week == currentWeek
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [lamp.gold, const Color(0xFFBA8030)],
                      )
                    : null,
            color: week > currentWeek
                ? lamp.ink.withValues(alpha: 0.07)
                : null,
            border: week > currentWeek
                ? Border.all(color: lamp.ink.withValues(alpha: 0.07))
                : null,
            boxShadow: week == currentWeek
                ? [
                    BoxShadow(
                      color: lamp.ochre.withValues(alpha: 0.65),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        ),
      ));
      if (week % 4 == 0) {
        final passed = week < currentWeek;
        final isLast = week == 12;
        children.add(Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: passed
                  ? lamp.mossBright
                  : isLast
                      ? lamp.gold
                      : lamp.sand.withValues(alpha: 0.45),
              boxShadow: passed
                  ? [
                      BoxShadow(
                        color: lamp.moss.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : isLast
                      ? [
                          BoxShadow(
                            color: lamp.ochre.withValues(alpha: 0.6),
                            blurRadius: 9,
                          ),
                        ]
                      : null,
            ),
          ),
        ));
      }
    }
    return Semantics(
      label: 'Journey: week $currentWeek of 12',
      child: ExcludeSemantics(child: Row(children: children)),
    );
  }
}

/// One stat tile — Fraunces numeral + Manrope label (mock `.card` center).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.moss = false,
  });

  final int value;
  final String label;
  final bool moss;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Expanded(
      child: Semantics(
        label: '$value $label',
        child: ExcludeSemantics(
          child: DashCard(
            child: Column(
              children: [
                Text(
                  '$value',
                  style: AppTypography.numeral(
                    26,
                    moss ? lamp.mossBright : lamp.ink,
                  ),
                ),
                const SizedBox(height: 6),
                CardKicker(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 7-column consistency grid, moss at three intensities. Misses are simply
/// unfilled — never marked.
class ConsistencyGrid extends StatelessWidget {
  const ConsistencyGrid({super.key, required this.grid});

  /// Rows of 7 intensities (0–3).
  final List<List<int>> grid;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    Color cell(int i) => switch (i) {
          1 => lamp.moss.withValues(alpha: 0.3),
          2 => lamp.moss.withValues(alpha: 0.6),
          3 => lamp.mossBright,
          _ => lamp.ink.withValues(alpha: 0.06),
        };
    final active = grid.fold(0, (n, row) => n + row.where((i) => i > 0).length);

    return Semantics(
      label: '$active active days across ${grid.length} weeks',
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (final row in grid)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    for (final i in row)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 17,
                            height: 17,
                            decoration: BoxDecoration(
                              color: cell(i),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: i == 3
                                  ? [
                                      BoxShadow(
                                        color:
                                            lamp.moss.withValues(alpha: 0.45),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Weekly practice-volume bars (sand; current week ochre).
class VolumeBars extends StatelessWidget {
  const VolumeBars({super.key, required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final max = values.isEmpty ? 1.0 : values.reduce(math.max);
    return Semantics(
      label: 'Practice volume across ${values.length} weeks',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 58,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++) ...[
                if (i > 0) const SizedBox(width: 13),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: max == 0 ? 0 : values[i] / max,
                    ),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : AppMotion.settle,
                    curve: AppMotion.enter,
                    builder: (context, t, _) => Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: math.max(6, 58 * t),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                            bottom: Radius.circular(4),
                          ),
                          gradient: i == values.length - 1
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [lamp.gold, const Color(0xFFA9742B)],
                                )
                              : LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    lamp.sand.withValues(alpha: 0.5),
                                    lamp.sand.withValues(alpha: 0.16),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The check-ins chart: baseline + lit measured dots joined by a gradient
/// line, dashed future circles at 0/4/8/12. Animates the line draw 400ms.
class CheckinChart extends StatelessWidget {
  const CheckinChart({super.key, required this.series, this.enlarged = false});

  final CheckinSeries series;
  final bool enlarged;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final h = enlarged ? 78.0 : 64.0;

    // TalkBack as a sentence (acceptance criteria).
    final sentence = StringBuffer('Check-ins: ');
    for (final p in series.points) {
      sentence.write('week ${p.week} set; ');
    }
    if (series.hasComparison && series.deltas.isNotEmpty) {
      final ups = series.deltas.where((d) => d.up);
      if (ups.isNotEmpty) {
        sentence.write(ups.map((d) => '${d.label} up ${d.delta}').join(', '));
        sentence.write(', on your own scale');
      }
    }

    return Semantics(
      label: sentence.toString(),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.settle,
          curve: AppMotion.enter,
          builder: (context, t, _) => CustomPaint(
            size: Size(double.infinity, h),
            painter: _CheckinChartPainter(
              series: series,
              lamp: lamp,
              progress: t,
              enlarged: enlarged,
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckinChartPainter extends CustomPainter {
  _CheckinChartPainter({
    required this.series,
    required this.lamp,
    required this.progress,
    required this.enlarged,
  });

  final CheckinSeries series;
  final LamplightTokens lamp;
  final double progress;
  final bool enlarged;

  @override
  void paint(Canvas canvas, Size size) {
    const weeks = [0, 4, 8, 12];
    final baseY = size.height - 14;
    final topY = enlarged ? 14.0 : 22.0;
    double xFor(int week) =>
        16 + (size.width - 32) * (week / 12);

    // Baseline.
    canvas.drawLine(
      Offset(14, baseY),
      Offset(size.width - 14, baseY),
      Paint()
        ..color = lamp.ink.withValues(alpha: 0.1)
        ..strokeWidth = 1.5,
    );

    // Measured points: height grows with the relative total.
    final maxTotal = series.points.isEmpty
        ? 1
        : series.points.map((p) => p.total).fold(1, math.max);
    double yFor(int total) =>
        baseY - (baseY - topY) * (maxTotal == 0 ? 0 : total / maxTotal);

    final measuredWeeks = series.points.map((p) => p.week).toSet();

    // Future dashed circles.
    final dashed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = lamp.sand.withValues(alpha: 0.32);
    for (final w in weeks) {
      if (measuredWeeks.contains(w)) continue;
      _dashedCircle(canvas, Offset(xFor(w), baseY), 5.5, dashed);
    }

    // Connecting gradient line (drawn to progress).
    if (series.points.length >= 2) {
      final pts = series.points
          .map((p) => Offset(xFor(p.week), yFor(p.total)))
          .toList();
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [const Color(0xFFB97F2E), lamp.gold],
        ).createShader(Rect.fromPoints(pts.first, pts.last));
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final from = pts[i - 1];
        final to = pts[i];
        path.lineTo(
          from.dx + (to.dx - from.dx) * progress,
          from.dy + (to.dy - from.dy) * progress,
        );
      }
      canvas.drawPath(path, line);
    }

    // Lit measured dots + halo on the latest.
    for (var i = 0; i < series.points.length; i++) {
      final p = series.points[i];
      final c = Offset(xFor(p.week), yFor(p.total));
      final isLatest = i == series.points.length - 1;
      canvas.drawCircle(
        c,
        6,
        Paint()
          ..shader = LinearGradient(
            colors: [lamp.gold, const Color(0xFFB97F2E)],
          ).createShader(Rect.fromCircle(center: c, radius: 6)),
      );
      if (isLatest) {
        canvas.drawCircle(
          c,
          10,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = lamp.ochre.withValues(alpha: 0.3),
        );
      }
    }

    // Week labels.
    for (final w in weeks) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'WK $w',
          style: TextStyle(
            fontFamily: AppTypography.body,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: lamp.faint,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xFor(w) - tp.width / 2, size.height - 12));
    }
  }

  void _dashedCircle(Canvas canvas, Offset c, double r, Paint paint) {
    const segments = 8;
    for (var i = 0; i < segments; i++) {
      final start = (2 * math.pi / segments) * i;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        math.pi / segments,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckinChartPainter old) =>
      old.progress != progress || old.series != series;
}
