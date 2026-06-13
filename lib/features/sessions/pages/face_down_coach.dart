import 'package:flutter/material.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';

/// M1·4a — the cue language, taught once (first session only; relearnable
/// from Settings → Daily rhythm). Pops true when the user chooses to try
/// face-down, false on "Maybe later".
class FaceDownCoachPage extends StatelessWidget {
  const FaceDownCoachPage({super.key, this.firstSession = true});

  /// From Settings the eyebrow drops the "first session" framing.
  final bool firstSession;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final theme = Theme.of(context);

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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: Text(
                            firstSession
                                ? 'First session · one-time'
                                : 'The haptic cues',
                            style: AppTypography.eyebrow(
                              lamp.ochre.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'You can do this with the screen off.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontSize: 25),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: CustomPaint(
                            size: const Size(320, 110),
                            painter: _RecliningFigurePainter(
                              line: lamp.sand,
                              accent: lamp.gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          child: Column(
                            children: [
                              _cueRow(theme, lamp, const [false],
                                  'One tick', 'squeeze — begin the hold'),
                              _divider(lamp),
                              _cueRow(theme, lamp, const [false, false],
                                  'Double tick', 'release — let go fully'),
                              _divider(lamp),
                              _cueRow(theme, lamp, const [true],
                                  'Long pulse', 'phase change — breath next'),
                              _divider(lamp),
                              _cueRow(
                                  theme,
                                  lamp,
                                  const [false, false, false],
                                  'Three soft taps',
                                  'done for tonight'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Try it face-down',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                AppButton(
                  label: 'Maybe later',
                  variant: AppButtonVariant.text,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(LamplightTokens lamp) =>
      Container(height: 1, color: lamp.hairline);

  Widget _cueRow(
    ThemeData theme,
    LamplightTokens lamp,
    List<bool> dots, // true = long pulse pill
    String title,
    String sub,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Row(
              children: [
                for (final long in dots)
                  Container(
                    width: long ? 24 : 9,
                    height: 9,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [lamp.gold, const Color(0xFFBA8030)],
                      ),
                      borderRadius: BorderRadius.circular(long ? 5 : 9),
                      boxShadow: [
                        BoxShadow(
                          color: lamp.ochre.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(sub, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Calm-contour line drawing: figure reclined, phone face-down on the chest,
/// haptic arcs rising (mock m1_04a).
class _RecliningFigurePainter extends CustomPainter {
  _RecliningFigurePainter({required this.line, required this.accent});

  final Color line;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 260;
    final sy = size.height / 110;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final body = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = line.withValues(alpha: 0.8);

    // Reclined body line.
    final torso = Path()
      ..moveTo(p(16, 86).dx, p(16, 86).dy
      )
      ..cubicTo(p(50, 64).dx, p(50, 64).dy, p(86, 60).dx, p(86, 60).dy,
          p(122, 66).dx, p(122, 66).dy)
      ..cubicTo(p(170, 74).dx, p(170, 74).dy, p(214, 74).dx, p(214, 74).dy,
          p(244, 64).dx, p(244, 64).dy);
    canvas.drawPath(torso, body);

    // Ground.
    canvas.drawLine(
      p(16, 96),
      p(244, 96),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = line.withValues(alpha: 0.3),
    );

    // Phone on the chest.
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(p(104, 46).dx, p(104, 46).dy, 40 * sx, 20 * sy),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      phoneRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );
    canvas.drawLine(
      p(112, 62),
      p(136, 62),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.6),
    );

    // Haptic arcs rising from the phone.
    final arcs = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.5);
    final a1 = Path()
      ..moveTo(p(118, 36).dx, p(118, 36).dy)
      ..cubicTo(p(120, 33).dx, p(120, 33).dy, p(124, 33).dx, p(124, 33).dy,
          p(126, 36).dx, p(126, 36).dy);
    final a2 = Path()
      ..moveTo(p(115, 28).dx, p(115, 28).dy)
      ..cubicTo(p(119, 23).dx, p(119, 23).dy, p(127, 23).dx, p(127, 23).dy,
          p(131, 28).dx, p(131, 28).dy);
    canvas.drawPath(a1, arcs);
    canvas.drawPath(a2, arcs);
  }

  @override
  bool shouldRepaint(_RecliningFigurePainter old) =>
      old.line != line || old.accent != accent;
}
