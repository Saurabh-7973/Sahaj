import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/logic/plan_reveal_lines.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';

void main() {
  test('no goals → no lines (never pad)', () {
    expect(planRevealLines({}), isEmpty);
  });

  test('one goal → exactly one line, tied to the choice', () {
    final lines = planRevealLines({Goal.foundation});
    expect(lines, hasLength(1));
    expect(lines.first, contains('a healthy foundation'));
    expect(lines.first, startsWith('Because you chose'));
  });

  test('caps at two lines even with many goals', () {
    final lines = planRevealLines({
      Goal.control,
      Goal.erections,
      Goal.anxiety,
      Goal.partner,
    });
    expect(lines, hasLength(2));
  });

  test('order follows the goal enum, stable', () {
    final a = planRevealLines({Goal.erections, Goal.control});
    final b = planRevealLines({Goal.control, Goal.erections});
    expect(a, b);
    // control precedes erections in the enum.
    expect(a.first, contains('more control'));
  });
}
