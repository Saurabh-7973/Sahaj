import 'models/session_models.dart';

/// Local calendar-day key 'YYYY-MM-DD'.
String dateKey(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

/// True when today's session has already been completed.
bool isDoneToday(ProgressState s, DateTime now) =>
    s.lastCompletedDate == dateKey(now);

/// Applies a completion: advances position (calendar-gated), updates streak.
///
/// Idempotent within a calendar day. Streak increments only when the previous
/// completion was the day before; any gap resets it to 1. Position advances one
/// day, rolling week at day 7, capped at week 12 day 7 (plan complete).
ProgressState advanceAfterCompletion(ProgressState s, DateTime now) {
  final today = dateKey(now);
  if (s.lastCompletedDate == today) return s; // already done today

  final midnight = DateTime(now.year, now.month, now.day);
  final yesterday = dateKey(midnight.subtract(const Duration(days: 1)));
  final newStreak = (s.lastCompletedDate == yesterday) ? s.streak + 1 : 1;
  final newLongest =
      newStreak > s.longestStreak ? newStreak : s.longestStreak;

  var week = s.currentWeek;
  var day = s.currentDay;
  if (week < 12 || day < 7) {
    day += 1;
    if (day > 7) {
      day = 1;
      week += 1;
    }
  }

  return s.copyWith(
    currentWeek: week,
    currentDay: day,
    streak: newStreak,
    longestStreak: newLongest,
    lastCompletedDate: today,
  );
}
