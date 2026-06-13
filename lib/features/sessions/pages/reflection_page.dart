import 'package:flutter/material.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/models/session_models.dart';

/// Result of the reflection. [difficulty] is null when skipped — the session
/// still logs; reflection is never required.
class ReflectionResult {
  const ReflectionResult({this.difficulty, this.note});
  final PerceivedDifficulty? difficulty;
  final String? note;
}

/// M1·5 — progressive-overload calibration disguised as closure. ≤10 seconds.
/// Effort glyphs, no mood faces; "Harder" gets the same gold as any answer.
class ReflectionPage extends StatefulWidget {
  const ReflectionPage({
    super.key,
    required this.sessionTitle,
    this.sessionNumber,
  });

  final String sessionTitle;

  /// 1-based count including this session ("Session 14").
  final int? sessionNumber;

  @override
  State<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends State<ReflectionPage> {
  PerceivedDifficulty? _difficulty;
  final _noteController = TextEditingController();

  static const _labels = {
    PerceivedDifficulty.easier: 'Easier',
    PerceivedDifficulty.same: 'Same',
    PerceivedDifficulty.harder: 'Harder',
  };

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _pop({required bool skipped}) {
    Navigator.of(context).pop(
      ReflectionResult(
        difficulty: skipped ? null : _difficulty,
        note: skipped || _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final eyebrow = widget.sessionNumber != null
        ? 'Session ${widget.sessionNumber} · ${widget.sessionTitle}'
        : widget.sessionTitle;

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          eyebrow,
                          style: AppTypography.eyebrow(
                            lamp.ochre.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'How did that feel?',
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            for (final d in PerceivedDifficulty.values) ...[
                              if (d != PerceivedDifficulty.values.first)
                                const SizedBox(width: 10),
                              Expanded(
                                child: _EffortCard(
                                  label: _labels[d]!,
                                  difficulty: d,
                                  selected: _difficulty == d,
                                  lamp: lamp,
                                  onTap: () =>
                                      setState(() => _difficulty = d),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Harder converts from confession to data — the line
                        // appears only for Harder (M1·5).
                        AnimatedSwitcher(
                          duration: AppMotion.quick,
                          child: _difficulty == PerceivedDifficulty.harder
                              ? Padding(
                                  key: const ValueKey('harder'),
                                  padding:
                                      const EdgeInsets.only(top: 10),
                                  child: Center(
                                    child: Text(
                                      'Harder is useful — tomorrow adjusts to it.',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 10),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _noteController,
                          hint:
                              'Anything to note? Only you will ever see this.',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Done',
                  onPressed: _difficulty == null
                      ? null
                      : () => _pop(skipped: false),
                ),
                AppButton(
                  label: 'Skip',
                  variant: AppButtonVariant.text,
                  onPressed: () => _pop(skipped: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EffortCard extends StatelessWidget {
  const _EffortCard({
    required this.label,
    required this.difficulty,
    required this.selected,
    required this.lamp,
    required this.onTap,
  });

  final String label;
  final PerceivedDifficulty difficulty;
  final bool selected;
  final LamplightTokens lamp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3A2D14), Color(0xFF27200F)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF272019), Color(0xFF1F1A14)],
                  ),
            border: Border.all(
              color: selected
                  ? lamp.gold.withValues(alpha: 0.6)
                  : lamp.ink.withValues(alpha: 0.09),
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? lamp.ochre.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.6),
                blurRadius: selected ? 32 : 26,
                spreadRadius: -14,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: selected
                        ? [
                            lamp.ochre.withValues(alpha: 0.18),
                            lamp.ochre.withValues(alpha: 0.07),
                          ]
                        : [
                            lamp.sand.withValues(alpha: 0.14),
                            lamp.sand.withValues(alpha: 0.05),
                          ],
                  ),
                  border: Border.all(
                    color: selected
                        ? lamp.ochre.withValues(alpha: 0.26)
                        : lamp.sand.withValues(alpha: 0.24),
                  ),
                ),
                child: CustomPaint(
                  painter: _SlopeGlyphPainter(
                    difficulty: difficulty,
                    color: selected ? lamp.gold : lamp.sand,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? lamp.gold : lamp.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Effort slope, not a mood face: down-slope = easier, level = same,
/// up-slope = harder, each with a dot at the leading end.
class _SlopeGlyphPainter extends CustomPainter {
  _SlopeGlyphPainter({required this.difficulty, required this.color});

  final PerceivedDifficulty difficulty;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 22;
    Offset p(double x, double y) =>
        Offset(x * s + (size.width - size.shortestSide) / 2, y * s);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9 * s
      ..strokeCap = StrokeCap.round
      ..color = color;

    final (start, end) = switch (difficulty) {
      PerceivedDifficulty.easier => (p(4, 7), p(17, 15)),
      PerceivedDifficulty.same => (p(4, 11), p(17, 11)),
      PerceivedDifficulty.harder => (p(4, 15), p(17, 7)),
    };
    canvas.drawLine(start, end, paint);
    canvas.drawCircle(end, 1.9 * s, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SlopeGlyphPainter old) =>
      old.difficulty != difficulty || old.color != color;
}
