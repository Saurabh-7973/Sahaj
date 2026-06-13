import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';

/// How the ring behaves (design spec A6).
enum RingMode {
  /// Standard sweep, calm. The default everywhere outside the player.
  countdown,

  /// Kegels: fills during squeeze (glow on), drains during release (glow off).
  /// The caller drives [AppProgressRing.value] per phase.
  holdPulse,

  /// The signature: the whole ring scales 0.86↔1.00 on a sine matched to the
  /// step's pacing. Arc is full; the fixed tick dial stays still outside the
  /// scaling group. Reduced motion: opacity pulse 70↔100% instead of scale.
  breath,
}

/// Lamplight progress ring — breath pacer first, timer skin second.
///
/// Anatomy (mock m1_02/03, 272dp): fixed tick dial · faint track · tinted
/// gradient arc with optional blur-glow pass · inner hairline circle · radial
/// halo behind · center slot.
class AppProgressRing extends StatefulWidget {
  const AppProgressRing({
    super.key,
    required this.value,
    this.mode = RingMode.countdown,
    this.size = 120,
    this.strokeWidth,
    this.center,
    this.tint,
    this.glow = true,
    this.dimmed = false,
    this.breathPeriod = const Duration(seconds: 6),
    this.animationDuration,
    this.semanticsLabel,
  });

  /// Arc sweep 0..1. Ignored in [RingMode.breath] (arc is always full).
  final double value;

  final RingMode mode;
  final double size;

  /// Defaults to size/27 (≈10 at 272dp), matching the mock proportions.
  final double? strokeWidth;

  final Widget? center;

  /// Session-type tint (A2). Defaults to the theme ochre.
  final Color? tint;

  /// Blur-glow pass behind the arc + radial halo. Off during release/dim.
  final bool glow;

  /// Paused state: stroke desaturates to grey-sand, glow off.
  final bool dimmed;

  /// Full inhale+exhale cycle length in breath mode.
  final Duration breathPeriod;

  /// How long a [value] change tweens. Pass 1s from a ticking player for a
  /// continuous fill; defaults to AppMotion.calm.
  final Duration? animationDuration;

  /// TalkBack line, e.g. "Squeeze, six seconds".
  final String? semanticsLabel;

  @override
  State<AppProgressRing> createState() => _AppProgressRingState();
}

class _AppProgressRingState extends State<AppProgressRing>
    with SingleTickerProviderStateMixin {
  AnimationController? _breath;

  @override
  void initState() {
    super.initState();
    _syncBreath();
  }

  @override
  void didUpdateWidget(AppProgressRing old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode ||
        old.breathPeriod != widget.breathPeriod ||
        old.dimmed != widget.dimmed) {
      _syncBreath();
    }
  }

  void _syncBreath() {
    if (widget.mode == RingMode.breath && !widget.dimmed) {
      _breath ??= AnimationController(vsync: this);
      _breath!
        ..duration = widget.breathPeriod
        ..repeat();
    } else {
      _breath?.stop();
    }
  }

  @override
  void dispose() {
    _breath?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final tint = widget.dimmed
        ? lamp.inkMuted
        : (widget.tint ?? Theme.of(context).colorScheme.primary);
    final glowOn = widget.glow && !widget.dimmed;
    final stroke = widget.strokeWidth ?? widget.size / 27;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget arcLayer(double breathT) {
      // Sine 0..1 over the cycle: 0 at rest (exhaled), 1 fully inhaled.
      final wave = 0.5 - 0.5 * math.cos(2 * math.pi * breathT);
      final scale = widget.mode == RingMode.breath && !reduceMotion
          ? AppMotion.breathScaleMin +
              (AppMotion.breathScaleMax - AppMotion.breathScaleMin) * wave
          : 1.0;
      final opacity = widget.mode == RingMode.breath && reduceMotion
          ? AppMotion.breathOpacityMin +
              (AppMotion.breathOpacityMax - AppMotion.breathOpacityMin) * wave
          : 1.0;

      final arc = TweenAnimationBuilder<double>(
        tween: Tween(
          begin: 0,
          end: widget.mode == RingMode.breath
              ? 1.0
              : widget.value.clamp(0.0, 1.0),
        ),
        duration: widget.animationDuration ?? AppMotion.calm,
        curve: widget.animationDuration == null
            ? AppMotion.transition
            : Curves.linear,
        builder: (context, v, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _RingPainter(
            value: v,
            strokeWidth: stroke,
            tint: tint,
            trackColor: lamp.ink.withValues(alpha: 0.07),
            innerHairline: lamp.ink.withValues(alpha: 0.07),
            glow: glowOn,
            flat: widget.dimmed,
          ),
        ),
      );

      return Transform.scale(
        scale: scale,
        child: Opacity(opacity: opacity, child: arc),
      );
    }

    final ring = Stack(
      alignment: Alignment.center,
      children: [
        // Radial halo (8% tint) — the lamp glow behind the ring.
        if (glowOn)
          IgnorePointer(
            child: Container(
              width: widget.size * 1.35,
              height: widget.size * 1.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tint.withValues(alpha: 0.13),
                    tint.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.62],
                ),
              ),
            ),
          ),
        // Fixed tick dial — never scales, even while the ring breathes.
        CustomPaint(
          size: Size.square(widget.size),
          painter: _TickDialPainter(
            color: (widget.mode == RingMode.breath
                    ? tint
                    : lamp.ink)
                .withValues(alpha: widget.mode == RingMode.breath ? 0.13 : 0.10),
            strokeWidth: stroke * 0.45,
          ),
        ),
        if (_breath != null && widget.mode == RingMode.breath && !widget.dimmed)
          AnimatedBuilder(
            animation: _breath!,
            builder: (context, _) => arcLayer(_breath!.value),
          )
        else
          arcLayer(0),
        if (widget.center != null) widget.center!,
      ],
    );

    return Semantics(
      label: widget.semanticsLabel,
      child: SizedBox(
        // Halo paints within the stack but layout stays at [size].
        width: widget.size,
        height: widget.size,
        child: OverflowBox(
          maxWidth: widget.size * 1.35,
          maxHeight: widget.size * 1.35,
          child: ring,
        ),
      ),
    );
  }
}

/// Track + gradient arc + glow pass + inner hairline (radii per the mock's
/// 240-viewBox: arc r=100/120, hairline r=84/120).
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.tint,
    required this.trackColor,
    required this.innerHairline,
    required this.glow,
    required this.flat,
  });

  final double value;
  final double strokeWidth;
  final Color tint;
  final Color trackColor;
  final Color innerHairline;
  final bool glow;

  /// Dimmed/paused: flat desaturated stroke, no gradient.
  final bool flat;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 * (100 / 120);
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    if (value > 0) {
      final sweep = 2 * math.pi * value;
      final hsl = HSLColor.fromColor(tint);
      final light =
          hsl.withLightness((hsl.lightness + 0.10).clamp(0.0, 1.0)).toColor();
      final dark =
          hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();

      Paint arcPaint({double? blur, double opacity = 1}) {
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        if (flat) {
          p.color = tint.withValues(alpha: 0.5 * opacity);
        } else {
          p.shader = ui.Gradient.linear(
            rect.topLeft,
            rect.bottomRight,
            [
              light.withValues(alpha: opacity),
              dark.withValues(alpha: opacity),
            ],
          );
        }
        if (blur != null) {
          p.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
        }
        return p;
      }

      if (glow && !flat) {
        canvas.drawArc(
            rect, -math.pi / 2, sweep, false, arcPaint(blur: 5, opacity: 0.55));
      }
      canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint());
    }

    canvas.drawCircle(
      center,
      size.shortestSide / 2 * (84 / 120),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = innerHairline,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.tint != tint ||
      old.glow != glow ||
      old.flat != flat ||
      old.strokeWidth != strokeWidth;
}

/// The fixed outer dial: short dashes around r=113/120 (mock dasharray 1.5/10.4).
class _TickDialPainter extends CustomPainter {
  _TickDialPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 * (113 / 120);
    final circumference = 2 * math.pi * radius;
    final ticks = (circumference / 11.9).round(); // dash 1.5 + gap 10.4
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    for (var i = 0; i < ticks; i++) {
      final angle = 2 * math.pi * i / ticks - math.pi / 2;
      final dashAngle = 1.5 / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickDialPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
