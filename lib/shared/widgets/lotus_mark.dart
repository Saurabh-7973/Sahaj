import 'package:flutter/material.dart';

/// The Sahaj lotus mark as a static line drawing (the watermark on hero
/// cards and the small medal glyph). Stroke-only, no fills.
class LotusMark extends StatelessWidget {
  const LotusMark({
    super.key,
    required this.size,
    required this.color,
    this.strokeWidth = 2,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _LotusPainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _LotusPainter extends CustomPainter {
  _LotusPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    Path petal(List<List<double>> pts) {
      final path = Path()..moveTo(p(pts[0][0], pts[0][1]).dx, p(pts[0][0], pts[0][1]).dy);
      for (var i = 1; i + 2 < pts.length; i += 3) {
        path.cubicTo(
          p(pts[i][0], pts[i][1]).dx, p(pts[i][0], pts[i][1]).dy,
          p(pts[i + 1][0], pts[i + 1][1]).dx, p(pts[i + 1][0], pts[i + 1][1]).dy,
          p(pts[i + 2][0], pts[i + 2][1]).dx, p(pts[i + 2][0], pts[i + 2][1]).dy,
        );
      }
      return path;
    }

    // Mock watermark paths (100-unit viewBox).
    canvas.drawPath(
      petal([
        [50, 18], [40, 34], [40, 52], [50, 66], [60, 52], [60, 34], [50, 18],
      ]),
      paint,
    );
    canvas.drawPath(
      petal([
        [24, 38], [28, 56], [37, 65], [50, 66],
      ]),
      paint,
    );
    canvas.drawPath(
      petal([
        [76, 38], [72, 56], [63, 65], [50, 66],
      ]),
      paint,
    );
    canvas.drawPath(
      petal([
        [14, 50], [20, 64], [33, 71], [50, 71],
      ]),
      paint,
    );
    canvas.drawPath(
      petal([
        [86, 50], [80, 64], [67, 71], [50, 71],
      ]),
      paint,
    );
  }

  @override
  bool shouldRepaint(_LotusPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
