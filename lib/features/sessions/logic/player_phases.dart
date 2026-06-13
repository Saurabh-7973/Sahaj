import 'models/session_models.dart';

/// What the ring is asking for right now.
enum PlayerPhase { squeeze, release, inhale, holdIn, exhale, holdOut, plain }

extension PlayerPhaseWords on PlayerPhase {
  /// Ring center word (mock: SQUEEZE / RELEASE / Inhale / Exhale).
  String get word => switch (this) {
    PlayerPhase.squeeze => 'Squeeze',
    PlayerPhase.release => 'Release',
    PlayerPhase.inhale => 'Inhale',
    PlayerPhase.holdIn || PlayerPhase.holdOut => 'Hold',
    PlayerPhase.exhale => 'Exhale',
    PlayerPhase.plain => '',
  };

  bool get isEffort => this == PlayerPhase.squeeze;
  bool get isBreath =>
      this == PlayerPhase.inhale ||
      this == PlayerPhase.holdIn ||
      this == PlayerPhase.exhale ||
      this == PlayerPhase.holdOut;
}

/// Everything the player UI needs about the current second, derived purely
/// from (step, secondsLeft) so it is trivially testable and survives
/// interruption/resume without hidden state.
class PhaseSnapshot {
  const PhaseSnapshot({
    required this.phase,
    required this.phaseSecondsLeft,
    required this.phaseSecondsTotal,
    required this.rep,
    required this.repsTotal,
  });

  final PlayerPhase phase;

  /// Whole seconds remaining in this phase — the ring's numeral. The ring
  /// counts the phase's own seconds, never clock time (M1 rule).
  final int phaseSecondsLeft;

  final int phaseSecondsTotal;

  /// 1-based rep/round number; 0 when the step has no pattern.
  final int rep;
  final int repsTotal;

  /// Fill fraction of the phase elapsed (holdPulse drives fill on squeeze
  /// with this, drain on release with its inverse).
  double get phaseProgress => phaseSecondsTotal == 0
      ? 0
      : (phaseSecondsTotal - phaseSecondsLeft) / phaseSecondsTotal;
}

/// Derive the live phase for [step] given [secondsLeft] on its clock.
///
/// Tail seconds that don't fit a whole cycle (e.g. 150s of 4s cycles) play
/// as a final release/exhale — winding down, never an extra squeeze.
PhaseSnapshot phaseAt(SessionStep step, int secondsLeft) {
  final pattern = step.pattern;
  final elapsed = (step.seconds - secondsLeft).clamp(0, step.seconds);

  switch (pattern) {
    case null:
      return PhaseSnapshot(
        phase: PlayerPhase.plain,
        phaseSecondsLeft: secondsLeft,
        phaseSecondsTotal: step.seconds,
        rep: 0,
        repsTotal: 0,
      );

    case HoldReleasePattern p:
      final cycle = p.cycleSeconds;
      final repsTotal = step.reps;
      final rep = (elapsed ~/ cycle) + 1;
      if (rep > repsTotal) {
        // Tail: ride out the remainder as release.
        return PhaseSnapshot(
          phase: PlayerPhase.release,
          phaseSecondsLeft: secondsLeft,
          phaseSecondsTotal: step.seconds - repsTotal * cycle,
          rep: repsTotal,
          repsTotal: repsTotal,
        );
      }
      final inCycle = elapsed % cycle;
      final squeezing = inCycle < p.holdSeconds;
      return PhaseSnapshot(
        phase: squeezing ? PlayerPhase.squeeze : PlayerPhase.release,
        phaseSecondsLeft:
            squeezing ? p.holdSeconds - inCycle : cycle - inCycle,
        phaseSecondsTotal: squeezing ? p.holdSeconds : p.releaseSeconds,
        rep: rep,
        repsTotal: repsTotal,
      );

    case BreathPattern p:
      final cycle = p.cycleSeconds;
      final roundsTotal = step.reps;
      final round = (elapsed ~/ cycle) + 1;
      if (round > roundsTotal) {
        return PhaseSnapshot(
          phase: PlayerPhase.exhale,
          phaseSecondsLeft: secondsLeft,
          phaseSecondsTotal: step.seconds - roundsTotal * cycle,
          rep: roundsTotal,
          repsTotal: roundsTotal,
        );
      }
      var inCycle = elapsed % cycle;
      for (final (phase, span) in [
        (PlayerPhase.inhale, p.inhaleSeconds),
        (PlayerPhase.holdIn, p.holdInSeconds),
        (PlayerPhase.exhale, p.exhaleSeconds),
        (PlayerPhase.holdOut, p.holdOutSeconds),
      ]) {
        if (span > 0 && inCycle < span) {
          return PhaseSnapshot(
            phase: phase,
            phaseSecondsLeft: span - inCycle,
            phaseSecondsTotal: span,
            rep: round,
            repsTotal: roundsTotal,
          );
        }
        inCycle -= span;
      }
      // Unreachable for a well-formed pattern; treat as exhale wind-down.
      return PhaseSnapshot(
        phase: PlayerPhase.exhale,
        phaseSecondsLeft: secondsLeft,
        phaseSecondsTotal: cycle,
        rep: round,
        repsTotal: roundsTotal,
      );
  }
}

/// Default form-correction lines for patterned phases (M1 spec §3 copy).
/// Un-patterned steps show their own guidance from the catalog.
String guidanceFor(SessionStep step, PlayerPhase phase) => switch (phase) {
  PlayerPhase.squeeze =>
    'Lift and hold — thighs loose, breath still moving.',
  PlayerPhase.release => 'Let go fully — the release is half the rep.',
  _ => step.guidance,
};

/// "4:20 LEFT" — total session seconds remaining, formatted m:ss.
String formatTimeLeft(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
