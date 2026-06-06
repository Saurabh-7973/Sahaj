import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';

void main() {
  test('defaults are private-safe (everything off / none)', () {
    final c = PreferencesController();
    expect(c.bookMode, isFalse);
    expect(c.disguiseName, DisguiseName.none);
    expect(c.notificationsEnabled, isFalse);
  });

  test('setters update and toJson/loadFrom round-trips', () {
    final a = PreferencesController()
      ..setBookMode(true)
      ..setDisguiseName(DisguiseName.calendar)
      ..setNotificationsEnabled(true);

    final b = PreferencesController()..loadFrom(a.toJson());
    expect(b.bookMode, isTrue);
    expect(b.disguiseName, DisguiseName.calendar);
    expect(b.notificationsEnabled, isTrue);
  });

  test('reset returns to defaults', () {
    final c = PreferencesController()
      ..setBookMode(true)
      ..setDisguiseName(DisguiseName.notes);
    c.reset();
    expect(c.bookMode, isFalse);
    expect(c.disguiseName, DisguiseName.none);
  });

  test('loadFrom tolerates an unknown disguise name', () {
    final c = PreferencesController()..loadFrom({'disguiseName': 'bogus'});
    expect(c.disguiseName, DisguiseName.none);
  });
}
