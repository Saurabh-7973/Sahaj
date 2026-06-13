import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/logic/player_phases.dart';

void main() {
  group('phaseAt — holdRelease', () {
    const step = SessionStep(
      title: 'Gentle holds',
      seconds: 120,
      guidance: 'Squeeze for 3 seconds, release for 3.',
      pattern: HoldReleasePattern(holdSeconds: 3, releaseSeconds: 3),
    );

    test('derives reps from seconds', () {
      expect(step.reps, 20);
    });

    test('starts in squeeze, full phase seconds', () {
      final s = phaseAt(step, 120);
      expect(s.phase, PlayerPhase.squeeze);
      expect(s.phaseSecondsLeft, 3);
      expect(s.rep, 1);
      expect(s.repsTotal, 20);
    });

    test('crosses into release after the hold', () {
      final s = phaseAt(step, 117); // elapsed 3
      expect(s.phase, PlayerPhase.release);
      expect(s.phaseSecondsLeft, 3);
      expect(s.rep, 1);
    });

    test('second rep begins after a full cycle', () {
      final s = phaseAt(step, 114); // elapsed 6
      expect(s.phase, PlayerPhase.squeeze);
      expect(s.rep, 2);
    });

    test('squeeze counts its own seconds down', () {
      expect(phaseAt(step, 119).phaseSecondsLeft, 2); // elapsed 1
      expect(phaseAt(step, 118).phaseSecondsLeft, 1);
    });

    test('tail seconds ride out as release, never an extra squeeze', () {
      const odd = SessionStep(
        title: 'Holds',
        seconds: 150, // 37 cycles of 4 + 2s tail
        guidance: '',
        pattern: HoldReleasePattern(holdSeconds: 2, releaseSeconds: 2),
      );
      final s = phaseAt(odd, 1); // elapsed 149, beyond 37*4=148
      expect(s.phase, PlayerPhase.release);
      expect(s.rep, 37);
    });
  });

  group('phaseAt — breath', () {
    const box = SessionStep(
      title: 'Box breath',
      seconds: 180,
      guidance: 'Inhale 4, hold 4, exhale 4, hold 4.',
      pattern: BreathPattern(
        inhaleSeconds: 4,
        holdInSeconds: 4,
        exhaleSeconds: 4,
        holdOutSeconds: 4,
      ),
    );

    test('walks the four phases of a round', () {
      expect(phaseAt(box, 180).phase, PlayerPhase.inhale);
      expect(phaseAt(box, 176).phase, PlayerPhase.holdIn); // elapsed 4
      expect(phaseAt(box, 172).phase, PlayerPhase.exhale); // elapsed 8
      expect(phaseAt(box, 168).phase, PlayerPhase.holdOut); // elapsed 12
      expect(phaseAt(box, 164).phase, PlayerPhase.inhale); // round 2
      expect(phaseAt(box, 164).rep, 2);
    });

    test('skips zero-length holds', () {
      const simple = SessionStep(
        title: 'Long exhale',
        seconds: 150,
        guidance: '',
        pattern: BreathPattern(inhaleSeconds: 4, exhaleSeconds: 6),
      );
      expect(simple.reps, 15);
      expect(phaseAt(simple, 146).phase, PlayerPhase.exhale); // elapsed 4
      expect(phaseAt(simple, 146).phaseSecondsTotal, 6);
    });
  });

  test('un-patterned step is plain countdown', () {
    const step = SessionStep(title: 'Settle', seconds: 30, guidance: 'Relax.');
    final s = phaseAt(step, 12);
    expect(s.phase, PlayerPhase.plain);
    expect(s.phaseSecondsLeft, 12);
    expect(s.rep, 0);
  });

  test('guidance: form-correction lines on patterned phases, catalog line otherwise',
      () {
    const step = SessionStep(title: 'Holds', seconds: 60, guidance: 'Own line.');
    expect(guidanceFor(step, PlayerPhase.squeeze), contains('thighs loose'));
    expect(guidanceFor(step, PlayerPhase.release), contains('half the rep'));
    expect(guidanceFor(step, PlayerPhase.plain), 'Own line.');
    expect(guidanceFor(step, PlayerPhase.exhale), 'Own line.');
  });

  test('formatTimeLeft pads seconds', () {
    expect(formatTimeLeft(260), '4:20');
    expect(formatTimeLeft(61), '1:01');
    expect(formatTimeLeft(0), '0:00');
  });
}
