import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/logic/plan_reveal_lines.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';

void main() {
  test('no goals → no lines (never pad)', () {
    expect(planRevealLines({}), isEmpty);
  });

  test('one goal → exactly one line, tied to the choice', () {
    final lines = planRevealLines({Goal.firstTimeOrGap});
    expect(lines, hasLength(1));
    expect(lines.first, contains('first-time ready'));
    expect(lines.first, startsWith('Because you chose'));
  });

  test('caps at two lines even with many goals', () {
    final lines = planRevealLines({
      Goal.finishTooQuick,
      Goal.hardness,
      Goal.pornRelationship,
      Goal.exploring,
    });
    expect(lines, hasLength(2));
  });

  test('order follows the goal enum, stable', () {
    final a = planRevealLines({Goal.hardness, Goal.finishTooQuick});
    final b = planRevealLines({Goal.finishTooQuick, Goal.hardness});
    expect(a, b);
    // finishTooQuick precedes hardness in the enum.
    expect(a.first, contains('finish sooner'));
  });
}
