/// Pure schedule math for the daily reminder. The next wall-clock instant at
/// [hour]:[minute]; if that time today is now or already past, rolls to
/// tomorrow so a reminder is never scheduled in the past.
///
/// Plugin- and timezone-free so it can be unit-tested in isolation; the real
/// service converts the result into the device timezone before scheduling.
DateTime nextReminderTime({
  required int hour,
  required int minute,
  required DateTime now,
}) {
  var candidate = DateTime(now.year, now.month, now.day, hour, minute);
  if (!candidate.isAfter(now)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}
