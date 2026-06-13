import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// B2 `StepDots` — onboarding + health-question progress. Never numerals
/// (numbers read as a test / create anxiety). Done = ochre 50%, current =
/// wide gold bar, upcoming = faint.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    return Semantics(
      label: 'Step ${current + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == current ? 19 : 6.5,
                height: 6.5,
                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: i == current
                      ? LinearGradient(
                          colors: [lamp.gold, const Color(0xFFBA8030)],
                        )
                      : null,
                  color: i == current
                      ? null
                      : i < current
                          ? lamp.ochre.withValues(alpha: 0.5)
                          : lamp.sand.withValues(alpha: 0.18),
                  boxShadow: i == current
                      ? [
                          BoxShadow(
                            color: lamp.ochre.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
