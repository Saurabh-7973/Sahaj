import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Calm-contour education illustrations (A5): single-weight line, gradient
/// accent, no faces. Slide 0 = hammock, 1 = pelvis cross-section, 2 = three
/// vignettes (support / control / blood flow).
class EducationIllustration extends StatelessWidget {
  const EducationIllustration({super.key, required this.slide});
  final int slide;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return CustomPaint(
      size: const Size(320, 180),
      painter: switch (slide) {
        0 => _HammockPainter(lamp),
        1 => _PelvisPainter(lamp),
        _ => _VignettesPainter(lamp),
      },
    );
  }
}

class _HammockPainter extends CustomPainter {
  _HammockPainter(this.lamp);
  final LamplightTokens lamp;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 240, sy = size.height / 170;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = lamp.sand;

    // Two posts + ground.
    canvas.drawLine(p(38, 28), p(38, 132), line);
    canvas.drawLine(p(202, 28), p(202, 132), line);
    canvas.drawLine(
      p(16, 138),
      p(224, 138),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = lamp.sand.withValues(alpha: 0.5),
    );

    // Hammock curve — moss fill, ochre stroke.
    final curve = Path()
      ..moveTo(p(38, 56).dx, p(38, 56).dy)
      ..cubicTo(p(92, 118).dx, p(92, 118).dy, p(148, 118).dx, p(148, 118).dy,
          p(202, 56).dx, p(202, 56).dy);
    canvas.drawPath(
      Path.from(curve)
        ..lineTo(p(202, 56).dx, p(56, 56).dy)
        ..close(),
      Paint()..color = lamp.moss.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [lamp.gold, lamp.ochre, lamp.gold],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_HammockPainter old) => old.lamp != lamp;
}

class _PelvisPainter extends CustomPainter {
  _PelvisPainter(this.lamp);
  final LamplightTokens lamp;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 240, sy = size.height / 180;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = lamp.sand.withValues(alpha: 0.85);

    // A pelvis cross-section is bilaterally symmetric, so the right wall and
    // anchor are exact mirrors of the left about the centre axis (cx) — the
    // walls used to be hand-drawn independently and drifted several units apart.
    const cx = 120.0;
    double mx(double x) => 2 * cx - x; // mirror an x across the centre

    // Left pelvic wall (top → floor), then the same path mirrored as the right.
    canvas.drawPath(
      Path()
        ..moveTo(p(78, 16).dx, p(78, 16).dy)
        ..cubicTo(p(56, 48).dx, p(56, 48).dy, p(50, 86).dx, p(50, 86).dy,
            p(58, 118).dx, p(58, 118).dy)
        ..cubicTo(p(64, 142).dx, p(64, 142).dy, p(82, 158).dx, p(82, 158).dy,
            p(106, 164).dx, p(106, 164).dy),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(p(mx(78), 16).dx, p(mx(78), 16).dy)
        ..cubicTo(p(mx(56), 48).dx, p(mx(56), 48).dy, p(mx(50), 86).dx,
            p(mx(50), 86).dy, p(mx(58), 118).dx, p(mx(58), 118).dy)
        ..cubicTo(p(mx(64), 142).dx, p(mx(64), 142).dy, p(mx(82), 158).dx,
            p(mx(82), 158).dy, p(mx(106), 164).dx, p(mx(106), 164).dy),
      line,
    );

    // Anchor points — mirrored pair at the same height.
    final anchor = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = lamp.sand;
    canvas.drawCircle(p(72, 126), 8 * sx, anchor);
    canvas.drawCircle(p(mx(72), 126), 8 * sx, anchor);

    // The floor curve recurs — glowing ochre, symmetric about cx.
    canvas.drawPath(
      Path()
        ..moveTo(p(72, 126).dx, p(72, 126).dy)
        ..cubicTo(p(96, 156).dx, p(96, 156).dy, p(mx(96), 156).dx,
            p(mx(96), 156).dy, p(mx(72), 126).dx, p(mx(72), 126).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [lamp.gold, const Color(0xFFB97F2E)])
            .createShader(Offset.zero & size),
    );
    canvas.drawCircle(p(cx, 150), 2.4 * sx, Paint()..color = lamp.gold);
  }

  @override
  bool shouldRepaint(_PelvisPainter old) => old.lamp != lamp;
}

class _VignettesPainter extends CustomPainter {
  _VignettesPainter(this.lamp);
  final LamplightTokens lamp;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 260, sy = size.height / 150;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    void medallion(double cx, Color tint) {
      canvas.drawCircle(
        p(cx, 62),
        34 * sx,
        Paint()..color = tint.withValues(alpha: 0.08),
      );
      canvas.drawCircle(
        p(cx, 62),
        34 * sx,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = tint.withValues(alpha: 0.3),
      );
    }

    medallion(56, lamp.ochre);
    medallion(130, lamp.sand);
    medallion(204, lamp.moss);

    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = lamp.sand;

    // support — a smile-curve under a dot.
    canvas.drawCircle(p(56, 56), 8.5 * sx, ink);
    canvas.drawPath(
      Path()
        ..moveTo(p(40, 68).dx, p(40, 68).dy)
        ..cubicTo(p(48, 80).dx, p(48, 80).dy, p(64, 80).dx, p(64, 80).dy,
            p(72, 68).dx, p(72, 68).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [lamp.gold, const Color(0xFFB97F2E)])
            .createShader(Offset.zero & size),
    );

    // control — a wave + up-tick, centred on the medallion (x=130).
    canvas.drawPath(
      Path()
        ..moveTo(p(116, 66).dx, p(116, 66).dy)
        ..cubicTo(p(121, 58).dx, p(121, 58).dy, p(125, 74).dx, p(125, 74).dy,
            p(130, 66).dx, p(130, 66).dy)
        ..cubicTo(p(135, 58).dx, p(135, 58).dy, p(139, 74).dx, p(139, 74).dy,
            p(144, 66).dx, p(144, 66).dy),
      ink,
    );
    canvas.drawLine(p(130, 46), p(130, 56),
        Paint()..strokeWidth = 2.6..strokeCap = StrokeCap.round..color = lamp.mossBright);

    // blood flow — a small lotus + down-arrow.
    canvas.drawPath(
      Path()
        ..moveTo(p(204, 44).dx, p(204, 44).dy)
        ..cubicTo(p(196, 56).dx, p(196, 56).dy, p(196, 66).dx, p(196, 66).dy,
            p(204, 74).dx, p(204, 74).dy)
        ..cubicTo(p(212, 66).dx, p(212, 66).dy, p(212, 56).dx, p(212, 56).dy,
            p(204, 44).dx, p(204, 44).dy),
      ink,
    );
    final arrow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = lamp.mossBright;
    canvas.drawLine(p(204, 78), p(204, 90), arrow);
    canvas.drawLine(p(198, 86), p(204, 92), arrow);
    canvas.drawLine(p(210, 86), p(204, 92), arrow);

    // Labels.
    void label(String t, double cx) {
      final tp = TextPainter(
        text: TextSpan(
          text: t,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: lamp.inkMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p(cx, 0).dx - tp.width / 2, p(0, 116).dy));
    }

    label('SUPPORT', 56);
    label('CONTROL', 130);
    label('BLOOD FLOW', 204);
  }

  @override
  bool shouldRepaint(_VignettesPainter old) => old.lamp != lamp;
}
