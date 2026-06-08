import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/notifications/logic/reminder_schedule.dart';

void main() {
  test('returns today at the target time when it is still in the future', () {
    final now = DateTime(2026, 6, 8, 14, 30);
    final next = nextReminderTime(hour: 20, minute: 0, now: now);
    expect(next, DateTime(2026, 6, 8, 20, 0));
  });

  test('rolls to tomorrow when the target time has already passed', () {
    final now = DateTime(2026, 6, 8, 21, 0);
    final next = nextReminderTime(hour: 20, minute: 0, now: now);
    expect(next, DateTime(2026, 6, 9, 20, 0));
  });

  test('rolls to tomorrow when now is exactly the target time (avoid firing in the past)', () {
    final now = DateTime(2026, 6, 8, 20, 0, 0);
    final next = nextReminderTime(hour: 20, minute: 0, now: now);
    expect(next, DateTime(2026, 6, 9, 20, 0));
  });

  test('handles a minute component', () {
    final now = DateTime(2026, 6, 8, 9, 0);
    final next = nextReminderTime(hour: 9, minute: 30, now: now);
    expect(next, DateTime(2026, 6, 8, 9, 30));
  });
}
