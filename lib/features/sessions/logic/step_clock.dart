/// Result of advancing the session timer by one second.
class StepTick {
  const StepTick({
    required this.step,
    required this.secondsLeft,
    required this.finished,
  });

  final int step;
  final int secondsLeft;
  final bool finished;
}

/// Pure timekeeping for the stepper player. The widget owns the real Timer;
/// this maps (step, secondsLeft) one second forward.
class StepClock {
  const StepClock._();

  /// Advance one second. When the current step's last second elapses, move to
  /// the next step (reset to its full duration), or finish on the last step.
  static StepTick tick(List<int> durations, int step, int secondsLeft) {
    if (secondsLeft > 1) {
      return StepTick(
        step: step,
        secondsLeft: secondsLeft - 1,
        finished: false,
      );
    }
    if (step < durations.length - 1) {
      final next = step + 1;
      return StepTick(
        step: next,
        secondsLeft: durations[next],
        finished: false,
      );
    }
    return StepTick(step: step, secondsLeft: 0, finished: true);
  }

  /// Elapsed-over-total fraction for the overall progress ring (0..1).
  static double fraction(List<int> durations, int step, int secondsLeft) {
    final total = durations.fold<int>(0, (a, b) => a + b);
    if (total == 0) return 1.0;
    var elapsed = 0;
    for (var i = 0; i < step; i++) {
      elapsed += durations[i];
    }
    elapsed += durations[step] - secondsLeft;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
