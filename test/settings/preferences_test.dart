import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';

void main() {
  test('defaults are private-safe (everything off / none)', () {
    final c = PreferencesController();
    expect(c.bookMode, isFalse);
    expect(c.disguiseName, DisguiseName.none);
    expect(c.notificationsEnabled, isFalse);
    expect(c.hideStreak, isFalse);
    expect(c.reminderHour, 21);
    expect(c.reminderMinute, 30);
  });

  test('setters update and toJson/loadFrom round-trips', () {
    final a = PreferencesController()
      ..setBookMode(true)
      ..setDisguiseName(DisguiseName.calendar)
      ..setNotificationsEnabled(true)
      ..setHideStreak(true)
      ..setReminderTime(7, 15);

    final b = PreferencesController()..loadFrom(a.toJson());
    expect(b.bookMode, isTrue);
    expect(b.disguiseName, DisguiseName.calendar);
    expect(b.notificationsEnabled, isTrue);
    expect(b.hideStreak, isTrue);
    expect(b.reminderHour, 7);
    expect(b.reminderMinute, 15);
  });

  test('reset returns to defaults', () {
    final c = PreferencesController()
      ..setBookMode(true)
      ..setDisguiseName(DisguiseName.notes)
      ..setHideStreak(true);
    c.reset();
    expect(c.bookMode, isFalse);
    expect(c.disguiseName, DisguiseName.none);
    expect(c.hideStreak, isFalse);
  });

  test('loadFrom tolerates an unknown disguise name', () {
    final c = PreferencesController()..loadFrom({'disguiseName': 'bogus'});
    expect(c.disguiseName, DisguiseName.none);
  });
}
