import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// The five arrival moods (design spec B1 / M1·1). Calm-contour glyphs,
/// never emoji — system yellow breaks the palette and reads flippant.
enum ArrivalMood { heavy, low, level, open, charged }

extension ArrivalMoodLabel on ArrivalMood {
  String get label => switch (this) {
    ArrivalMood.heavy => 'Heavy',
    ArrivalMood.low => 'Low',
    ArrivalMood.level => 'Level',
    ArrivalMood.open => 'Open',
    ArrivalMood.charged => 'Charged',
  };
}

/// Horizontal 5-glyph mood row, multi-select up to [max].
/// Idle: sand line. Selected: ochre-gradient fill + 1.1 scale (200ms).
class AppMoodSelector extends StatelessWidget {
  const AppMoodSelector({
    super.key,
    required this.selected,
    required this.onToggle,
    this.max = 3,
    this.glyphSize = 54,
  });

  final Set<ArrivalMood> selected;
  final ValueChanged<ArrivalMood> onToggle;
  final int max;
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final mood in ArrivalMood.values)
          Flexible(
            child: _MoodOption(
              mood: mood,
              isSelected: selected.contains(mood),
              // Tapping an unselected glyph at the cap quietly does nothing —
              // no error state in the threshold ritual.
              enabled: selected.contains(mood) || selected.length < max,
              glyphSize: glyphSize,
              lamp: lamp,
              onTap: () => onToggle(mood),
            ),
          ),
      ],
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({
    required this.mood,
    required this.isSelected,
    required this.enabled,
    required this.glyphSize,
    required this.lamp,
    required this.onTap,
  });

  final ArrivalMood mood;
  final bool isSelected;
  final bool enabled;
  final double glyphSize;
  final LamplightTokens lamp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: mood.label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // Keeps the tap target ≥48dp even at small glyph sizes.
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? AppMotion.selectedScale : 1.0,
                duration: AppMotion.quick,
                curve: AppMotion.enter,
                child: AnimatedContainer(
                  duration: AppMotion.quick,
                  width: glyphSize,
                  height: glyphSize,
                  decoration: isSelected
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: lamp.ochre.withValues(alpha: 0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        )
                      : const BoxDecoration(shape: BoxShape.circle),
                  child: CustomPaint(
                    painter: _MoodGlyphPainter(
                      mood: mood,
                      stroke: isSelected
                          ? lamp.onOchre
                          : lamp.sand,
                      fillTop: isSelected ? lamp.gold : null,
                      fillBottom: isSelected
                          ? const Color(0xFFBA8030)
                          : null,
                      idleFill:
                          lamp.sand.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              // Scale down rather than overflow at large text sizes.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mood.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppTypography.body,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? lamp.gold
                        : lamp.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Calm-contour mood faces from the mock SVGs (52-unit viewBox): circle,
/// two eye strokes, a mouth curve; Charged adds two spark strokes.
class _MoodGlyphPainter extends CustomPainter {
  _MoodGlyphPainter({
    required this.mood,
    required this.stroke,
    required this.idleFill,
    this.fillTop,
    this.fillBottom,
  });

  final ArrivalMood mood;
  final Color stroke;
  final Color idleFill;
  final Color? fillTop;
  final Color? fillBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 52;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final face = Rect.fromCircle(center: p(26, 26), radius: 20 * s);

    // Face fill — gradient circle when selected, faint sand idle.
    final fill = Paint()..style = PaintingStyle.fill;
    if (fillTop != null) {
      fill.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [fillTop!, fillBottom!],
      ).createShader(face);
    } else {
      fill.color = idleFill;
    }
    canvas.drawCircle(p(26, 26), 20 * s, fill);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..color = stroke;

    canvas.drawCircle(p(26, 26), 20 * s, line);
    canvas.drawLine(p(19, 21), p(19, 25), line);
    canvas.drawLine(p(33, 21), p(33, 25), line);

    final mouth = Path();
    switch (mood) {
      case ArrivalMood.heavy:
        mouth
          ..moveTo(18 * s, 36 * s)
          ..quadraticBezierTo(26 * s, 29 * s, 34 * s, 36 * s);
      case ArrivalMood.low:
        mouth
          ..moveTo(19 * s, 34 * s)
          ..quadraticBezierTo(26 * s, 30.5 * s, 33 * s, 34 * s);
      case ArrivalMood.level:
        mouth
          ..moveTo(19 * s, 33 * s)
          ..lineTo(33 * s, 33 * s);
      case ArrivalMood.open:
        mouth
          ..moveTo(19 * s, 32 * s)
          ..quadraticBezierTo(26 * s, 36.5 * s, 33 * s, 32 * s);
      case ArrivalMood.charged:
        mouth
          ..moveTo(18 * s, 31 * s)
          ..quadraticBezierTo(26 * s, 37 * s, 34 * s, 31 * s);
        canvas.drawLine(p(12, 7), p(16, 12), line);
        canvas.drawLine(p(40, 7), p(36, 12), line);
    }
    canvas.drawPath(mouth, line);
  }

  @override
  bool shouldRepaint(_MoodGlyphPainter old) =>
      old.mood != mood ||
      old.stroke != stroke ||
      old.fillTop != fillTop ||
      old.idleFill != idleFill;
}
