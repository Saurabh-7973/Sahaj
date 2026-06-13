import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// B2 `WeekDots` — the this-week row on Today. Done = moss fill, today =
/// ochre ring, upcoming = faint outline. Missed days are simply unfilled —
/// never struck through, never marked.
class WeekDots extends StatelessWidget {
  const WeekDots({
    super.key,
    required this.done,
    required this.todayIndex,
  });

  /// Mon..Sun completion flags.
  final List<bool> done;

  /// 0 = Monday … 6 = Sunday.
  final int todayIndex;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
      'Sunday',
    ];

    return Semantics(
      label: '${done.where((d) => d).length} sessions done this week. '
          'Today is ${dayNames[todayIndex]}.',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 7; i++)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: done[i]
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF9CB48E), Color(0xFF71895F)],
                            )
                          : null,
                      border: done[i]
                          ? null
                          : Border.all(
                              color: i == todayIndex
                                  ? lamp.gold
                                  : lamp.sand.withValues(alpha: 0.25),
                              width: i == todayIndex ? 2.5 : 1.5,
                            ),
                      boxShadow: done[i]
                          ? [
                              BoxShadow(
                                color: lamp.moss.withValues(alpha: 0.4),
                                blurRadius: 9,
                              ),
                            ]
                          : i == todayIndex
                              ? [
                                  BoxShadow(
                                    color:
                                        lamp.ochre.withValues(alpha: 0.45),
                                    blurRadius: 9,
                                  ),
                                ]
                              : null,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _letters[i],
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.75,
                      color: lamp.faint,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
