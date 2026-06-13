import '../../sessions/logic/models/session_models.dart';
import '../../sessions/logic/progress_logic.dart';

/// DECISION #2 (handoff): the missed-days count that triggers the adjusted
/// plan. Nothing in the plan engine or docs defines it yet — 3 is a working
/// default between the spec's own candidates (2? 3?). Change here only.
const kGapThresholdDays = 3;

/// Which doorway Today shows (M2 spec states, priority order).
enum TodayKind {
  /// Data wiped / no plan — the only true empty.
  empty,

  /// First open after onboarding; no session ever completed.
  day0,

  /// ≥ [kGapThresholdDays] missed days — the blameless-reset proof screen.
  gapReturn,

  /// Session already completed today.
  done,

  standard,
}

/// Why-line selection within the standard state (spec §1 table, priority:
/// milestone > week start > after-harder > normal).
enum WhyLineCase { normal, afterHarder, weekStart, milestoneDay }

/// Everything Today needs, derived once from plan position + logs + clock.
/// Today writes nothing; this is a pure read of the day.
class TodayContext {
  const TodayContext({
    required this.kind,
    required this.whyCase,
    required this.gapDays,
    required this.displayStreak,
    required this.weekCompletions,
    required this.dayDots,
  });

  final TodayKind kind;
  final WhyLineCase whyCase;

  /// Whole days since the last completion (0 when none/today).
  final int gapDays;

  /// Streak as shown: the stored streak only survives if the last completion
  /// was today or yesterday — otherwise it reads 0 (honest, never stale).
  final int displayStreak;

  /// Completions in the current calendar week (Mon–Sun).
  final int weekCompletions;

  /// Mon..Sun: true = a session completed that day.
  final List<bool> dayDots;
}

int _daysBetween(DateTime a, DateTime b) =>
    DateTime(b.year, b.month, b.day)
        .difference(DateTime(a.year, a.month, a.day))
        .inDays;

DateTime? _parseDateKey(String? key) =>
    key == null ? null : DateTime.tryParse(key);

/// Build the day's context. [hasPlan] false → the true-empty edge case.
TodayContext buildTodayContext({
  required bool hasPlan,
  required ProgressState progress,
  required List<SessionLog> logs,
  required DateTime now,
}) {
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  final dots = List<bool>.filled(7, false);
  var weekCompletions = 0;
  for (final log in logs) {
    final d = _daysBetween(monday, log.completedAt);
    if (d >= 0 && d < 7) {
      if (!dots[d]) weekCompletions++;
      dots[d] = true;
    }
  }

  final last = _parseDateKey(progress.lastCompletedDate);
  final gapDays = last == null ? 0 : _daysBetween(last, now);
  final displayStreak = (last != null && gapDays <= 1) ? progress.streak : 0;

  final TodayKind kind;
  if (!hasPlan) {
    kind = TodayKind.empty;
  } else if (logs.isEmpty) {
    kind = TodayKind.day0;
  } else if (isDoneToday(progress, now)) {
    kind = TodayKind.done;
  } else if (gapDays >= kGapThresholdDays) {
    kind = TodayKind.gapReturn;
  } else {
    kind = TodayKind.standard;
  }

  // Why-line case for the standard state.
  WhyLineCase whyCase;
  final isMilestoneDay = progress.currentDay == 7 &&
      const {4, 8, 12}.contains(progress.currentWeek);
  final harderYesterday = logs.isNotEmpty &&
      logs.last.perceivedDifficulty == PerceivedDifficulty.harder &&
      _daysBetween(logs.last.completedAt, now) == 1;
  if (isMilestoneDay) {
    whyCase = WhyLineCase.milestoneDay;
  } else if (progress.currentDay == 1) {
    whyCase = WhyLineCase.weekStart;
  } else if (harderYesterday) {
    whyCase = WhyLineCase.afterHarder;
  } else {
    whyCase = WhyLineCase.normal;
  }

  return TodayContext(
    kind: kind,
    whyCase: whyCase,
    gapDays: gapDays,
    displayStreak: displayStreak,
    weekCompletions: weekCompletions,
    dayDots: dots,
  );
}

/// The coach voice (spec §1 — table copy verbatim; facts only, never
/// motivational filler, the gap mentioned exactly once on the return day).
String whyLine(TodayContext ctx, {required int week, required String phase}) {
  switch (ctx.kind) {
    case TodayKind.day0:
      return 'No payment, no signup — just your first seven minutes.';
    case TodayKind.gapReturn:
      final n = ctx.gapDays;
      final days = switch (n) {
        2 => 'Two',
        3 => 'Three',
        4 => 'Four',
        5 => 'Five',
        6 => 'Six',
        _ => '$n',
      };
      return '$days days away — tonight restarts a notch gentler. '
          'The plan moved with you.';
    case TodayKind.empty:
    case TodayKind.done:
    case TodayKind.standard:
      break;
  }
  return switch (ctx.whyCase) {
    WhyLineCase.milestoneDay =>
      "Week $week's last session — the check-in unlocks after.",
    WhyLineCase.weekStart =>
      'Week $week opens $phase work — everything so far was for this.',
    WhyLineCase.afterHarder =>
      'Yesterday ran harder — tonight holds steady instead of adding.',
    WhyLineCase.normal =>
      "Builds on yesterday's holds — slightly longer, same breath.",
  };
}

/// Time-aware greeting (spec §0: no cleverness at 2 AM).
String greeting(DateTime now) {
  if (now.hour < 12) return 'Good morning.';
  if (now.hour < 17) return 'Good afternoon.';
  return 'Good evening.';
}

/// `Thursday · 11 June` — DECISION #3 (l10n format) pending; English
/// hardcoded to the mock until the app-wide l10n approach lands.
String dateEyebrow(DateTime now) {
  const weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
    'Sunday',
  ];
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];
  return '${weekdays[now.weekday - 1]} · ${now.day} ${months[now.month - 1]}';
}
