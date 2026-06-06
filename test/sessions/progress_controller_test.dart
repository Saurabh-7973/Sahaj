import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';

SessionLog _log() => SessionLog(
      id: 'x',
      sessionTag: 'anatomy',
      startedAt: DateTime(2026, 6, 6, 8),
      completedAt: DateTime(2026, 6, 6, 8, 7),
      completionPct: 1.0,
      moodBefore: const ['calm'],
    );

void main() {
  test('starts at week 1 day 1 with no store', () {
    final c = ProgressController();
    expect(c.state.currentWeek, 1);
    expect(c.state.currentDay, 1);
    expect(c.isDoneToday, isFalse);
  });

  test('completeToday advances state and marks done today', () {
    final c = ProgressController();
    final before = c.state.currentDay;
    c.completeToday(_log());
    expect(c.state.currentDay, before + 1);
    expect(c.isDoneToday, isTrue);
  });

  test('completeToday twice in a day is idempotent', () {
    final c = ProgressController();
    c.completeToday(_log());
    final dayAfterFirst = c.state.currentDay;
    c.completeToday(_log());
    expect(c.state.currentDay, dayAfterFirst);
  });

  test('loadFrom hydrates state', () {
    final c = ProgressController();
    c.loadFrom(const ProgressState(currentWeek: 3, currentDay: 2).toJson());
    expect(c.state.currentWeek, 3);
    expect(c.state.currentDay, 2);
  });
}
