import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/logic/session_calibration.dart';
import 'package:sahaj/shared/widgets/app_mood_selector.dart';

SessionDef _kegel() => const SessionDef(
      tag: 'pfmt_identify',
      title: 'Finding the muscles',
      type: SessionType.kegel,
      steps: [
        SessionStep(title: 'Settle', seconds: 30, guidance: 'Relax.'),
        SessionStep(
          title: 'Gentle holds',
          seconds: 120, // 20 reps of 3+3
          guidance: 'Squeeze for 3, release for 3.',
          pattern: HoldReleasePattern(holdSeconds: 3, releaseSeconds: 3),
        ),
      ],
    );

SessionDef _breath() => const SessionDef(
      tag: 'breathwork_basics_v2',
      title: 'The longer exhale',
      type: SessionType.breathwork,
      steps: [
        SessionStep(
          title: 'Lengthen the out-breath',
          seconds: 150, // 15 rounds of 4+6
          guidance: 'In four, out six.',
          pattern: BreathPattern(inhaleSeconds: 4, exhaleSeconds: 6),
        ),
      ],
    );

SessionDef _mindset() => const SessionDef(
      tag: 'mindset_x',
      title: 'Mindset',
      type: SessionType.mindset,
      steps: [
        SessionStep(title: 'Reflect', seconds: 120, guidance: 'Think.'),
      ],
    );

void main() {
  test('heavy calibrates down: 5/8 reps and the gentler chip', () {
    final c = calibrateSession(
      session: _kegel(),
      moods: [ArrivalMood.heavy],
    );
    expect(c.gentler, isTrue);
    expect(c.echoLine, 'You arrived heavy — shorter holds, longer breath tonight.');
    // 20 reps → round(20*5/8)=13 → 13*6s
    expect(c.session.steps[1].seconds, 13 * 6);
    expect(c.deltaLine, contains('13 holds instead of 20'));
    expect(c.deltaLine, contains('same muscle, kinder load'));
    // Un-patterned settle step untouched.
    expect(c.session.steps[0].seconds, 30);
  });

  test('heavy doubles the exhale on breath patterns', () {
    final c = calibrateSession(
      session: _breath(),
      moods: [ArrivalMood.heavy],
    );
    final p = c.session.steps[0].pattern as BreathPattern;
    expect(p.exhaleSeconds, 12);
    // Rounds preserved: 15 rounds of (4+12).
    expect(c.session.steps[0].seconds, 15 * 16);
    expect(c.deltaLine, contains('exhale doubled'));
  });

  test('charged calibrates up: one extra hold', () {
    final c = calibrateSession(
      session: _kegel(),
      moods: [ArrivalMood.charged],
    );
    expect(c.calibratedUp, isTrue);
    expect(c.echoLine, 'You arrived charged — one extra hold tonight.');
    expect(c.session.steps[1].seconds, 21 * 6);
    expect(c.deltaLine, '21 holds instead of 20');
  });

  test('level runs as planned — said honestly, nothing fabricated', () {
    final c = calibrateSession(
      session: _kegel(),
      moods: [ArrivalMood.level],
    );
    expect(c.changed, isFalse);
    expect(c.echoLine, 'You arrived level — tonight runs as planned.');
    expect(c.session.totalSeconds, _kegel().totalSeconds);
    expect(c.deltaLine, isNull);
  });

  test('low softens framing only — no workload change, no gentler chip', () {
    final c = calibrateSession(session: _kegel(), moods: [ArrivalMood.low]);
    expect(c.changed, isFalse);
    expect(c.gentler, isFalse);
    expect(c.echoLine, contains('lower stakes'));
    expect(c.session.totalSeconds, _kegel().totalSeconds);
    expect(c.deltaLine, isNull);
  });

  test('open offers without escalating — plan as set, never auto-extended', () {
    final c = calibrateSession(session: _kegel(), moods: [ArrivalMood.open]);
    expect(c.changed, isFalse);
    expect(c.calibratedUp, isFalse);
    expect(c.echoLine, contains('as far as feels right'));
    expect(c.session.totalSeconds, _kegel().totalSeconds);
    expect(c.deltaLine, isNull);
  });

  test('precedence: heavy wins over charged (mock m1_01b shows heavy+low → heavy)',
      () {
    final c = calibrateSession(
      session: _kegel(),
      moods: [ArrivalMood.charged, ArrivalMood.heavy, ArrivalMood.low],
    );
    expect(c.gentler, isTrue);
    expect(c.drivingMood, ArrivalMood.heavy);
  });

  test('skip path: no echo at all, session untouched', () {
    final c = calibrateSession(session: _kegel(), moods: const []);
    expect(c.echoLine, isNull);
    expect(c.changed, isFalse);
  });

  test('uncalibratable session stays honest even when heavy', () {
    final c = calibrateSession(
      session: _mindset(),
      moods: [ArrivalMood.heavy],
    );
    expect(c.changed, isFalse);
    expect(c.echoLine, 'You arrived heavy — tonight runs as planned.');
  });

  test('daytime echo says today', () {
    final c = calibrateSession(
      session: _kegel(),
      moods: [ArrivalMood.heavy],
      tonight: false,
    );
    expect(c.echoLine, contains('today'));
  });
}
