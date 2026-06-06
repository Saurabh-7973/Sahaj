import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/step_clock.dart';

void main() {
  const durations = [3, 2]; // total 5 seconds, 2 steps

  test('tick counts down within a step', () {
    final t = StepClock.tick(durations, 0, 3);
    expect(t.step, 0);
    expect(t.secondsLeft, 2);
    expect(t.finished, isFalse);
  });

  test('tick at end of a non-last step advances to next step', () {
    final t = StepClock.tick(durations, 0, 1);
    expect(t.step, 1);
    expect(t.secondsLeft, 2); // next step full duration
    expect(t.finished, isFalse);
  });

  test('tick at end of the last step finishes', () {
    final t = StepClock.tick(durations, 1, 1);
    expect(t.finished, isTrue);
    expect(t.step, 1);
    expect(t.secondsLeft, 0);
  });

  test('fraction is elapsed-over-total', () {
    expect(StepClock.fraction(durations, 0, 3), 0.0);
    expect(StepClock.fraction(durations, 0, 1), closeTo(2 / 5, 1e-9));
    expect(StepClock.fraction(durations, 1, 0), 1.0);
  });
}
