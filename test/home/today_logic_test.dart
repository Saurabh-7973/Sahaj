import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/home/logic/today_logic.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';

// Thursday 11 June 2026, evening.
final _now = DateTime(2026, 6, 11, 21);

SessionLog _log(DateTime day, {PerceivedDifficulty? difficulty}) => SessionLog(
      id: day.toString(),
      sessionTag: 't',
      startedAt: day,
      completedAt: day,
      completionPct: 1,
      moodBefore: const [],
      perceivedDifficulty: difficulty,
    );

ProgressState _progress({
  int week = 3,
  int day = 4,
  int streak = 6,
  String? last,
}) =>
    ProgressState(
      currentWeek: week,
      currentDay: day,
      streak: streak,
      longestStreak: 9,
      lastCompletedDate: last,
    );

void main() {
  group('kind selection', () {
    test('no plan → empty', () {
      final ctx = buildTodayContext(
        hasPlan: false,
        progress: _progress(),
        logs: const [],
        now: _now,
      );
      expect(ctx.kind, TodayKind.empty);
    });

    test('no logs ever → day 0', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: const ProgressState(),
        logs: const [],
        now: _now,
      );
      expect(ctx.kind, TodayKind.day0);
    });

    test('completed today → done', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: _progress(last: '2026-06-11'),
        logs: [_log(DateTime(2026, 6, 11, 20))],
        now: _now,
      );
      expect(ctx.kind, TodayKind.done);
    });

    test('yesterday completed → standard, streak kept', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: _progress(last: '2026-06-10'),
        logs: [_log(DateTime(2026, 6, 10, 20))],
        now: _now,
      );
      expect(ctx.kind, TodayKind.standard);
      expect(ctx.displayStreak, 6);
    });

    test('gap ≥ threshold → gapReturn with honest zero', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: _progress(last: '2026-06-07'), // 4 days
        logs: [_log(DateTime(2026, 6, 7, 20))],
        now: _now,
      );
      expect(ctx.kind, TodayKind.gapReturn);
      expect(ctx.gapDays, 4);
      expect(ctx.displayStreak, 0);
    });

    test('2-day gap stays standard but streak reads 0', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: _progress(last: '2026-06-09'),
        logs: [_log(DateTime(2026, 6, 9, 20))],
        now: _now,
      );
      expect(ctx.kind, TodayKind.standard);
      expect(ctx.displayStreak, 0);
    });
  });

  group('week dots (Mon-start)', () {
    test('marks completion days and counts the week', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: _progress(last: '2026-06-10'),
        logs: [
          _log(DateTime(2026, 6, 8, 21)), // Mon
          _log(DateTime(2026, 6, 9, 21)), // Tue
          _log(DateTime(2026, 6, 10, 21)), // Wed
          _log(DateTime(2026, 6, 5, 21)), // last week Friday — ignored
        ],
        now: _now,
      );
      expect(ctx.weekCompletions, 3);
      expect(ctx.dayDots, [true, true, true, false, false, false, false]);
    });
  });

  group('why-line', () {
    test('day 0 line', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: const ProgressState(),
        logs: const [],
        now: _now,
      );
      expect(
        whyLine(ctx, week: 1, phase: 'Foundation'),
        'No payment, no signup — just your first seven minutes.',
      );
    });

    test('gap line spells the count and mentions the gap once', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: _progress(last: '2026-06-07'),
        logs: [_log(DateTime(2026, 6, 7))],
        now: _now,
      );
      expect(
        whyLine(ctx, week: 5, phase: 'Integration'),
        'Four days away — tonight restarts a notch gentler. '
        'The plan moved with you.',
      );
    });

    test('milestone day beats week-start and harder', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: _progress(week: 4, day: 7, last: '2026-06-10'),
        logs: [
          _log(DateTime(2026, 6, 10), difficulty: PerceivedDifficulty.harder),
        ],
        now: _now,
      );
      expect(ctx.whyCase, WhyLineCase.milestoneDay);
      expect(
        whyLine(ctx, week: 4, phase: 'Foundation'),
        "Week 4's last session — the check-in unlocks after.",
      );
    });

    test('week start line', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: _progress(week: 5, day: 1, last: '2026-06-10'),
        logs: [_log(DateTime(2026, 6, 10))],
        now: _now,
      );
      expect(
        whyLine(ctx, week: 5, phase: 'Integration'),
        'Week 5 opens Integration work — everything so far was for this.',
      );
    });

    test('harder yesterday steadies tonight', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: _progress(last: '2026-06-10'),
        logs: [
          _log(DateTime(2026, 6, 10), difficulty: PerceivedDifficulty.harder),
        ],
        now: _now,
      );
      expect(ctx.whyCase, WhyLineCase.afterHarder);
    });

    test('harder two days ago does NOT trigger the steady line', () {
      final ctx = buildTodayContext(
        hasPlan: true,
        progress: _progress(last: '2026-06-09'),
        logs: [
          _log(DateTime(2026, 6, 9), difficulty: PerceivedDifficulty.harder),
        ],
        now: _now,
      );
      expect(ctx.whyCase, WhyLineCase.normal);
    });
  });

  test('greeting bands (spec literal — no cleverness at 2 AM)', () {
    expect(greeting(DateTime(2026, 6, 11, 2)), 'Good morning.');
    expect(greeting(DateTime(2026, 6, 11, 9)), 'Good morning.');
    expect(greeting(DateTime(2026, 6, 11, 13)), 'Good afternoon.');
    expect(greeting(DateTime(2026, 6, 11, 19)), 'Good evening.');
  });

  test('date eyebrow matches the mock format', () {
    expect(dateEyebrow(DateTime(2026, 6, 11)), 'Thursday · 11 June');
  });
}
