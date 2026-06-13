/// Billing facts render as dates, never countdowns (M7 §2). "18 June" within
/// the current year, "14 June 2027" when the year differs from [now].
String billingDate(DateTime date, {DateTime? now}) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];
  final ref = now ?? DateTime.now();
  final base = '${date.day} ${months[date.month - 1]}';
  return date.year == ref.year ? base : '$base ${date.year}';
}
