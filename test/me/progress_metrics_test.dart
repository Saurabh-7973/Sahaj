import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/me/logic/progress_metrics.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';

SessionLog _log({
  required String id,
  required DateTime completedAt,
  PerceivedDifficulty? difficulty,
}) =>
    SessionLog(
      id: id,
      sessionTag: 'anatomy',
      startedAt: completedAt,
      completedAt: completedAt,
      completionPct: 1.0,
      moodBefore: const ['calm'],
      perceivedDifficulty: difficulty,
    );

void main() {
  final now = DateTime(2026, 6, 6, 12);
  const progress = ProgressState(
    currentWeek: 3,
    currentDay: 2,
    streak: 4,
    longestStreak: 6,
  );

  test('no logs -> hasData false, zero counts', () {
    final m = computeMetrics(
      logs: const [],
      progress: progress,
      phase: 'Integration',
      now: now,
    );
    expect(m.hasData, isFalse);
    expect(m.totalSessions, 0);
    expect(m.thisWeekCount, 0);
  });

  test('totals, streak passthrough, phase', () {
    final m = computeMetrics(
      logs: [
        _log(id: 'a', completedAt: now.subtract(const Duration(days: 1))),
        _log(id: 'b', completedAt: now.subtract(const Duration(days: 2))),
      ],
      progress: progress,
      phase: 'Integration',
      now: now,
    );
    expect(m.hasData, isTrue);
    expect(m.totalSessions, 2);
    expect(m.currentStreak, 4);
    expect(m.longestStreak, 6);
    expect(m.currentWeek, 3);
    expect(m.phase, 'Integration');
  });

  test('thisWeekCount counts last 7 days, excludes older and future', () {
    final m = computeMetrics(
      logs: [
        _log(id: 'recent', completedAt: now.subtract(const Duration(days: 3))),
        _log(id: 'edge_in', completedAt: now.subtract(const Duration(days: 6, hours: 23))),
        _log(id: 'too_old', completedAt: now.subtract(const Duration(days: 8))),
        _log(id: 'future', completedAt: now.add(const Duration(days: 1))),
      ],
      progress: progress,
      phase: 'x',
      now: now,
    );
    expect(m.thisWeekCount, 2);
    expect(m.totalSessions, 4);
  });

  test('difficulty tallies', () {
    final m = computeMetrics(
      logs: [
        _log(id: 'a', completedAt: now, difficulty: PerceivedDifficulty.easier),
        _log(id: 'b', completedAt: now, difficulty: PerceivedDifficulty.easier),
        _log(id: 'c', completedAt: now, difficulty: PerceivedDifficulty.same),
        _log(id: 'd', completedAt: now, difficulty: PerceivedDifficulty.harder),
        _log(id: 'e', completedAt: now),
      ],
      progress: progress,
      phase: 'x',
      now: now,
    );
    expect(m.easierCount, 2);
    expect(m.sameCount, 1);
    expect(m.harderCount, 1);
  });
}
