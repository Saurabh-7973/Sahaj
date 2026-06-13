import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/me/checkin_controller.dart';
import 'package:sahaj/features/me/logic/dashboard_logic.dart';
import 'package:sahaj/features/onboarding/logic/models/onboarding_models.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';

final _now = DateTime(2026, 6, 11, 21); // Thursday

SessionLog _log(DateTime started, {int minutes = 8, int holdSeconds = 0}) =>
    SessionLog(
      id: started.toString(),
      sessionTag: 't',
      startedAt: started,
      completedAt: started.add(Duration(minutes: minutes)),
      completionPct: 1,
      moodBefore: const [],
      holdSeconds: holdSeconds,
    );

CheckinRecord _checkin(int week, Map<String, int> scores) =>
    CheckinRecord(week: week, scores: scores, completedAt: _now);

void main() {
  group('check-in series', () {
    const base = {
      'arousal_control': 1,
      'rehearsal_comfort': 1,
      'future_anxiety': 1,
    };

    test('week 0 alone: one lit point, three dashed futures, no deltas', () {
      final s = buildCheckinSeries(
        baselineRaw: base,
        track: Track.solo,
        records: const [],
      );
      expect(s.points.map((p) => p.week), [0]);
      expect(s.futureWeeks, [4, 8, 12]);
      expect(s.hasComparison, isFalse);
      expect(s.deltas, isEmpty);
      expect(deltaCaption(s), isNull);
    });

    test('week 4 done: two points, deltas vs week 0, future loses 4', () {
      final s = buildCheckinSeries(
        baselineRaw: base,
        track: Track.solo,
        records: [
          _checkin(4, {
            'arousal_control': 3, // +2 Control
            'rehearsal_comfort': 2, // +1 Confidence
            'future_anxiety': 1, // flat Calm
          }),
        ],
      );
      expect(s.points.map((p) => p.week), [0, 4]);
      expect(s.futureWeeks, [8, 12]);
      expect(s.hasComparison, isTrue);
      expect(s.deltas[0].label, 'Control');
      expect(s.deltas[0].delta, 2);
      expect(s.deltas[1].delta, 1);
      expect(s.deltas[2].flat, isTrue);
    });

    test('delta caption lists only ups, in the standing format', () {
      final s = buildCheckinSeries(
        baselineRaw: base,
        track: Track.solo,
        records: [
          _checkin(4, {
            'arousal_control': 3,
            'rehearsal_comfort': 2,
            'future_anxiety': 1,
          }),
        ],
      );
      expect(
        deltaCaption(s),
        'Control +2 · Confidence +1 — on your own week-0 scale. '
        'Small movements, really measured.',
      );
    });

    test('all flat: honest no-change caption, never alarm', () {
      final s = buildCheckinSeries(
        baselineRaw: base,
        track: Track.solo,
        records: [_checkin(4, base)],
      );
      expect(deltaCaption(s), 'No change this round — one measurement, not a verdict.');
    });

    test('dip uses the doctrine line, never red/spin', () {
      final d = const DomainDelta(label: 'Control', delta: -1);
      expect(d.dipped, isTrue);
      expect(verdictLine(d), 'dipped this round — one measurement, not a verdict');
    });

    test('partnered track uses partnered domain labels', () {
      final s = buildCheckinSeries(
        baselineRaw: const {
          'pe_control': 1,
          'erection_confidence': 1,
          'erection_maintain': 1,
        },
        track: Track.partnered,
        records: [
          _checkin(4, const {
            'pe_control': 2,
            'erection_confidence': 1,
            'erection_maintain': 1,
          }),
        ],
      );
      expect(s.deltas.map((d) => d.label),
          ['Control', 'Confidence', 'Staying power']);
    });
  });

  group('consistency grid', () {
    test('week 1: a single row of 7', () {
      final grid = consistencyGrid(
        logs: [_log(_now.subtract(const Duration(days: 1)))],
        now: _now,
      );
      expect(grid.length, 1);
      expect(grid[0].length, 7);
    });

    test('intensity caps at 3', () {
      final monday = DateTime(2026, 6, 8, 20);
      final grid = consistencyGrid(
        logs: [for (var i = 0; i < 5; i++) _log(monday)],
        now: _now,
      );
      expect(grid.last[0], 3);
    });

    test('grows a row per week, slides at 4', () {
      final logs = [
        for (var w = 0; w < 6; w++)
          _log(_now.subtract(Duration(days: 7 * w))),
      ];
      final grid = consistencyGrid(logs: logs, now: _now);
      expect(grid.length, 4); // capped
    });
  });

  group('weekly volume', () {
    test('one session → one bar with minutes + hold-seconds', () {
      final v = weeklyVolume(
        logs: [_log(_now, minutes: 8, holdSeconds: 120)],
        now: _now,
      );
      expect(v.length, 1);
      expect(v[0], closeTo(8 + 2, 0.01)); // 8 min + 120s/60
    });
  });

  group('input recap', () {
    test('counts sessions, minutes, active days in the window', () {
      final logs = [
        _log(_now.subtract(const Duration(days: 1)), minutes: 8),
        _log(_now.subtract(const Duration(days: 1, hours: 2)), minutes: 8),
        _log(_now.subtract(const Duration(days: 3)), minutes: 10),
      ];
      final r = inputRecap(logs: logs, sinceWeek: 0, week: 4, now: _now);
      expect(r.sessions, 3);
      expect(r.minutes, 26);
      expect(r.activeDays, 2); // two distinct calendar days
      expect(r.windowDays, 28);
    });
  });
}
