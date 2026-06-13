import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The pothi rule (design spec A4) — the manuscript nod and one of exactly two
/// ornaments in the app. Two hairline ochre fades with a rotated square at
/// center. Sanctioned placements only: plan-reveal title, article sections,
/// the completion moment, the paywall header. Nowhere else.
class RuleDivider extends StatelessWidget {
  const RuleDivider({super.key, this.width});

  /// Constrain (e.g. 180 on the completion moment); null = full width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final lamp = context.lamp;
    final line = Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _fadeLine(lamp.ochre.withValues(alpha: 0.55)),
          const SizedBox(height: 2),
          _fadeLine(lamp.ochre.withValues(alpha: 0.30)),
        ],
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            line,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Transform.rotate(
                angle: 0.785398, // 45°
                child: Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    color: lamp.ochre,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: lamp.ochre.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            line,
          ],
        ),
      ),
    );
  }

  Widget _fadeLine(Color color) => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color,
          color.withValues(alpha: 0),
        ],
      ),
    ),
  );
}
