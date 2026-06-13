import '../../../shared/widgets/app_mood_selector.dart';
import 'models/session_models.dart';

/// Tonight's session after the mood check-in, plus the words that prove the
/// pick changed something (M1·2 — the prescription echo).
///
/// The echo rule: `You arrived {mood} — {concrete change} tonight.` and we
/// NEVER fabricate an adjustment. If nothing changed, say so honestly.
class CalibratedSession {
  const CalibratedSession({
    required this.session,
    required this.drivingMood,
    required this.echoLine,
    this.deltaLine,
    this.gentler = false,
    this.calibratedUp = false,
  });

  final SessionDef session;

  /// Mood that drove the calibration (named in the echo); null on skip path.
  final ArrivalMood? drivingMood;

  /// Null only on the skip path (echo omitted entirely).
  final String? echoLine;

  /// Concrete numbers under the session card ("5 holds instead of 8 · …").
  final String? deltaLine;

  /// Shows the `gentler tonight` chip.
  final bool gentler;

  final bool calibratedUp;

  bool get changed => gentler || calibratedUp;
}

/// Mood → adjustment table.
///
/// Spec-given rows (m1_01b, M1 spec §2):
///   heavy   → fewer holds (8→5 ratio) + doubled exhale  ("calibrated-down")
///   charged → one extra hold                             ("calibrated-up")
///   level   → unchanged, said honestly
///
/// DECISION #1 (handoff): rows for `low` and `open` are not defined anywhere
/// in code or docs — they run unchanged until the plan-engine table lands.
/// Do not add rows here without that decision.
///
/// Precedence when several moods are picked (mock m1_01b shows Heavy+Low →
/// the heavy echo): calibrate-down beats calibrate-up beats unchanged.
CalibratedSession calibrateSession({
  required SessionDef session,
  required List<ArrivalMood> moods,
  bool tonight = true,
}) {
  final when = tonight ? 'tonight' : 'today';

  if (moods.isEmpty) {
    // Skip path — default session, no echo line at all.
    return CalibratedSession(
      session: session,
      drivingMood: null,
      echoLine: null,
    );
  }

  final driver = moods.contains(ArrivalMood.heavy)
      ? ArrivalMood.heavy
      : moods.contains(ArrivalMood.charged)
          ? ArrivalMood.charged
          : moods.first;

  switch (driver) {
    case ArrivalMood.heavy:
      final result = _calibrateDown(session);
      if (result == null) break;
      return CalibratedSession(
        session: result.session,
        drivingMood: driver,
        echoLine:
            'You arrived heavy — shorter holds, longer breath $when.',
        deltaLine: result.deltaLine,
        gentler: true,
      );

    case ArrivalMood.charged:
      final result = _calibrateUp(session);
      if (result == null) break;
      return CalibratedSession(
        session: result.session,
        drivingMood: driver,
        echoLine: 'You arrived charged — one extra hold $when.',
        deltaLine: result.deltaLine,
        calibratedUp: true,
      );

    case ArrivalMood.low:
    case ArrivalMood.level:
    case ArrivalMood.open:
      break;
  }

  // Unchanged — honest about it.
  return CalibratedSession(
    session: session,
    drivingMood: driver,
    echoLine: 'You arrived ${driver.name} — $when runs as planned.',
  );
}

class _Adjusted {
  const _Adjusted(this.session, this.deltaLine);
  final SessionDef session;
  final String deltaLine;
}

/// Heavy: hold-release reps scaled by 5/8 (the spec's 8→5), breath exhale
/// doubled. Returns null when the session has nothing calibratable.
_Adjusted? _calibrateDown(SessionDef session) {
  int? fromReps;
  int? toReps;
  var exhaleDoubled = false;

  final steps = session.steps.map((step) {
    switch (step.pattern) {
      case HoldReleasePattern p:
        final reps = step.reps;
        if (reps < 2) return step;
        final newReps = (reps * 5 / 8).round().clamp(1, reps - 1);
        fromReps = (fromReps ?? 0) + reps;
        toReps = (toReps ?? 0) + newReps;
        return step.copyWith(seconds: newReps * p.cycleSeconds);
      case BreathPattern p:
        final rounds = step.reps;
        if (rounds < 1) return step;
        final newPattern = BreathPattern(
          inhaleSeconds: p.inhaleSeconds,
          holdInSeconds: p.holdInSeconds,
          exhaleSeconds: p.exhaleSeconds * 2,
          holdOutSeconds: p.holdOutSeconds,
        );
        exhaleDoubled = true;
        return step.copyWith(
          seconds: rounds * newPattern.cycleSeconds,
          pattern: newPattern,
        );
      case null:
        return step;
    }
  }).toList();

  if (fromReps == null && !exhaleDoubled) return null;

  final parts = <String>[
    if (fromReps != null) '$toReps holds instead of $fromReps',
    if (exhaleDoubled) 'exhale doubled',
    'same muscle, kinder load',
  ];
  return _Adjusted(session.copyWith(steps: steps), parts.join(' · '));
}

/// Charged: one extra hold on the main rep step.
_Adjusted? _calibrateUp(SessionDef session) {
  var added = false;
  int? fromReps;
  int? toReps;

  final steps = session.steps.map((step) {
    if (added) return step;
    if (step.pattern case HoldReleasePattern p) {
      final reps = step.reps;
      if (reps < 1) return step;
      added = true;
      fromReps = reps;
      toReps = reps + 1;
      return step.copyWith(seconds: (reps + 1) * p.cycleSeconds);
    }
    return step;
  }).toList();

  if (!added) return null;
  return _Adjusted(
    session.copyWith(steps: steps),
    '$toReps holds instead of $fromReps',
  );
}
