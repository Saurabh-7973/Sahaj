import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/notifications/logic/reminder_copy.dart';

void main() {
  group('copy bank', () {
    test('every line is lock-screen safe — no banned words', () {
      final banned = [
        "don't lose",
        "don't break",
        'streak',
        'pro',
        'kegel',
        'erection',
      ];
      for (final line in kReminderCopyBank) {
        final lower = line.toLowerCase();
        for (final b in banned) {
          expect(lower.contains(b), isFalse, reason: '"$line" contains "$b"');
        }
        // No emoji (ASCII-ish + punctuation only).
        expect(line.runes.every((r) => r < 0x2000 || r == 0x2014 /* — */), isTrue,
            reason: line);
      }
    });

    test('rotation is deterministic per day and cycles', () {
      final a = reminderLine(DateTime(2026, 6, 11));
      expect(reminderLine(DateTime(2026, 6, 11)), a); // stable
      // Six-line bank cycles every six days.
      expect(reminderLine(DateTime(2026, 6, 11)),
          reminderLine(DateTime(2026, 6, 17)));
      // Consecutive days differ.
      expect(reminderLine(DateTime(2026, 6, 11)),
          isNot(reminderLine(DateTime(2026, 6, 12))));
    });
  });

  group('suppression', () {
    test('reminds only when not done and no active session', () {
      expect(shouldRemind(doneToday: false, sessionActive: false), isTrue);
      expect(shouldRemind(doneToday: true, sessionActive: false), isFalse);
      expect(shouldRemind(doneToday: false, sessionActive: true), isFalse);
      expect(shouldRemind(doneToday: true, sessionActive: true), isFalse);
    });
  });
}
