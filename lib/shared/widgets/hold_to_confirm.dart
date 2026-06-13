
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// B2 `HoldToConfirm` — press-and-hold [duration] to fire [onConfirm]. The
/// ring fill is the meter (reuses the session ring's language). Releasing
/// early resets with no penalty copy. Used for destructive actions.
class HoldToConfirm extends StatefulWidget {
  const HoldToConfirm({
    super.key,
    required this.label,
    required this.onConfirm,
    this.duration = const Duration(seconds: 3),
  });

  final String label;
  final VoidCallback onConfirm;
  final Duration duration;

  @override
  State<HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<HoldToConfirm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onConfirm();
        _c.value = 0;
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _start([_]) => _c.forward();
  void _cancel([_]) {
    if (_c.status != AnimationStatus.completed) _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '${widget.label}. Press and hold three seconds.',
      child: GestureDetector(
        onTapDown: _start,
        onTapUp: _cancel,
        onTapCancel: _cancel,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: lamp.ink.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: lamp.sand.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => SizedBox(
                  width: 26,
                  height: 26,
                  child: CustomPaint(
                    painter: _MeterPainter(
                      value: _c.value,
                      track: lamp.ink.withValues(alpha: 0.12),
                      gold: lamp.gold,
                      goldDeep: const Color(0xFFBA8030),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Text(widget.label,
                  style: theme.textTheme.labelLarge?.copyWith(color: lamp.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({
    required this.value,
    required this.track,
    required this.gold,
    required this.goldDeep,
  });

  final double value;
  final Color track;
  final Color gold;
  final Color goldDeep;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1.5;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = track,
    );
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -1.5708,
        6.2832 * value,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(colors: [gold, goldDeep])
              .createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_MeterPainter old) => old.value != value;
}
