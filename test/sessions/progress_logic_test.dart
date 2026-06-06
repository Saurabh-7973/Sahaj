import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/logic/progress_logic.dart';

void main() {
  final now = DateTime(2026, 6, 6, 9); // a Saturday morning

  test('dateKey formats local Y-M-D zero-padded', () {
    expect(dateKey(DateTime(2026, 1, 3)), '2026-01-03');
    expect(dateKey(DateTime(2026, 12, 30)), '2026-12-30');
  });

  test('isDoneToday true only when lastCompletedDate is today', () {
    expect(isDoneToday(const ProgressState(), now), isFalse);
    expect(
        isDoneToday(
            const ProgressState(lastCompletedDate: '2026-06-06'), now),
        isTrue);
    expect(
        isDoneToday(
            const ProgressState(lastCompletedDate: '2026-06-05'), now),
        isFalse);
  });

  test('first completion sets streak 1, advances day, stamps date', () {
    final s = advanceAfterCompletion(const ProgressState(), now);
    expect(s.streak, 1);
    expect(s.longestStreak, 1);
    expect(s.currentDay, 2);
    expect(s.currentWeek, 1);
    expect(s.lastCompletedDate, '2026-06-06');
  });

  test('completing on consecutive day increments streak', () {
    const yesterday = ProgressState(
      currentWeek: 1,
      currentDay: 2,
      streak: 1,
      longestStreak: 1,
      lastCompletedDate: '2026-06-05',
    );
    final s = advanceAfterCompletion(yesterday, now);
    expect(s.streak, 2);
    expect(s.longestStreak, 2);
    expect(s.currentDay, 3);
  });

  test('a gap resets streak to 1 but keeps longestStreak', () {
    const stale = ProgressState(
      currentWeek: 1,
      currentDay: 4,
      streak: 3,
      longestStreak: 5,
      lastCompletedDate: '2026-06-03', // 3 days ago
    );
    final s = advanceAfterCompletion(stale, now);
    expect(s.streak, 1);
    expect(s.longestStreak, 5);
  });

  test('completing again the same day is a no-op (idempotent)', () {
    final once = advanceAfterCompletion(const ProgressState(), now);
    final twice = advanceAfterCompletion(once, now);
    expect(twice.currentDay, once.currentDay);
    expect(twice.streak, once.streak);
    expect(twice.lastCompletedDate, once.lastCompletedDate);
  });

  test('day 7 rolls over to next week day 1', () {
    const d7 = ProgressState(
      currentWeek: 1,
      currentDay: 7,
      streak: 6,
      longestStreak: 6,
      lastCompletedDate: '2026-06-05',
    );
    final s = advanceAfterCompletion(d7, now);
    expect(s.currentWeek, 2);
    expect(s.currentDay, 1);
  });

  test('week 12 day 7 stays put (plan complete)', () {
    const last = ProgressState(
      currentWeek: 12,
      currentDay: 7,
      streak: 10,
      longestStreak: 10,
      lastCompletedDate: '2026-06-05',
    );
    final s = advanceAfterCompletion(last, now);
    expect(s.currentWeek, 12);
    expect(s.currentDay, 7);
    expect(s.lastCompletedDate, '2026-06-06');
  });
}
