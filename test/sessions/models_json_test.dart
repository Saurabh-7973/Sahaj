import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';

void main() {
  test('SessionDef.fromJson parses steps and totalSeconds', () {
    final def = SessionDef.fromJson('pfmt_identify', {
      'title': 'Finding the muscles',
      'type': 'kegel',
      'steps': [
        {'title': 'Settle', 'seconds': 30, 'guidance': 'Relax.'},
        {'title': 'Locate', 'seconds': 60, 'guidance': 'Find them.'},
      ],
    });
    expect(def.tag, 'pfmt_identify');
    expect(def.type, SessionType.kegel);
    expect(def.steps.length, 2);
    expect(def.steps.first.title, 'Settle');
    expect(def.totalSeconds, 90);
  });

  test('SessionDef.fromJson falls back to education for unknown type', () {
    final def = SessionDef.fromJson('x', {
      'title': 'X',
      'type': 'not_a_type',
      'steps': <dynamic>[],
    });
    expect(def.type, SessionType.education);
  });

  test('SessionLog round-trips through json', () {
    final log = SessionLog(
      id: 'a1',
      sessionTag: 'stop_start',
      startedAt: DateTime.utc(2026, 6, 6, 8),
      completedAt: DateTime.utc(2026, 6, 6, 8, 7),
      completionPct: 1.0,
      moodBefore: const ['anxious', 'hopeful'],
      perceivedDifficulty: PerceivedDifficulty.same,
      journalNote: 'felt ok',
    );
    final back = SessionLog.fromJson(log.toJson());
    expect(back.id, 'a1');
    expect(back.sessionTag, 'stop_start');
    expect(back.startedAt, log.startedAt);
    expect(back.completedAt, log.completedAt);
    expect(back.completionPct, 1.0);
    expect(back.moodBefore, ['anxious', 'hopeful']);
    expect(back.perceivedDifficulty, PerceivedDifficulty.same);
    expect(back.journalNote, 'felt ok');
  });

  test('ProgressState round-trips and copyWith works', () {
    const s = ProgressState(
      currentWeek: 2,
      currentDay: 3,
      streak: 4,
      longestStreak: 5,
      lastCompletedDate: '2026-06-05',
    );
    final back = ProgressState.fromJson(s.toJson());
    expect(back.currentWeek, 2);
    expect(back.currentDay, 3);
    expect(back.streak, 4);
    expect(back.longestStreak, 5);
    expect(back.lastCompletedDate, '2026-06-05');
    expect(s.copyWith(streak: 9).streak, 9);
    expect(s.copyWith(streak: 9).currentWeek, 2);
  });
}
