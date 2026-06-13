/// Notification doctrine (M8 §0). One channel, DEFAULT importance, never a
/// heads-up. Copy is lock-screen safe: no emoji, no name, no session-type
/// words, no streak-risk framing, and — restating M7 law — notifications
/// never sell.
const kReminderCopyBank = <String>[
  'Your 7 minutes are ready.',
  "Calm breathing — when you're ready.",
  'Today\'s session is short. Take it when it suits.',
  'Eight minutes tonight — whenever works.',
  "Your session's waiting. No rush.",
  'A quiet ten minutes, when you get them.',
];

/// Deterministic daily rotation through the bank (by day-of-year), so the
/// same day always renders the same line and consecutive days vary.
String reminderLine(DateTime day) {
  final dayOfYear =
      day.difference(DateTime(day.year)).inDays; // 0-based
  return kReminderCopyBank[dayOfYear % kReminderCopyBank.length];
}

/// Suppression (M8 §0): never remind a man who already trained today, and
/// never while a session is active. Max one per day at the chosen time.
bool shouldRemind({required bool doneToday, required bool sessionActive}) =>
    !doneToday && !sessionActive;
