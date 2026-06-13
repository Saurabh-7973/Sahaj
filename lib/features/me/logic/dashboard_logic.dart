import '../../onboarding/logic/models/onboarding_models.dart';
import '../../sessions/logic/models/session_models.dart';
import '../checkin_controller.dart';

/// DECISION #2 (M3): instrument question id → dashboard domain label, per
/// track. Derived 1:1 from the built baseline batteries — labels read clean
/// for solo trainees (Persona Zero test). Confirm against the plan engine
/// before adding domains; never invent a domain without an instrument item.
const Map<String, String> kPartneredDomains = {
  'pe_control': 'Control',
  'erection_confidence': 'Confidence',
  'erection_maintain': 'Staying power',
};

const Map<String, String> kSoloDomains = {
  'arousal_control': 'Control',
  'rehearsal_comfort': 'Confidence',
  'future_anxiety': 'Calm',
};

Map<String, String> domainsForTrack(Track track) =>
    track == Track.partnered ? kPartneredDomains : kSoloDomains;

/// One domain row on the result screen / chart caption. Delta is relative to
/// the week-0 answer index on the same instrument (decision #1: relative
/// only — raw clinical scores medicalize).
class DomainDelta {
  const DomainDelta({required this.label, required this.delta});

  final String label;

  /// Null when either end is missing (item unanswered) — row not rendered.
  final int? delta;

  bool get up => (delta ?? 0) > 0;
  bool get flat => delta == 0;
  bool get dipped => (delta ?? 0) < 0;
}

/// A dot on the check-ins chart.
class CheckinPoint {
  const CheckinPoint({required this.week, required this.total, this.max});

  final int week;

  /// Sum of answer indices — relative height only, never shown as a score.
  final int total;
  final int? max;
}

/// Everything the check-ins card + result screen render.
class CheckinSeries {
  const CheckinSeries({
    required this.points,
    required this.futureWeeks,
    required this.deltas,
  });

  /// Completed measurements (week 0 always present once onboarding ran).
  final List<CheckinPoint> points;

  /// Weeks 4/8/12 not yet measured (dashed circles).
  final List<int> futureWeeks;

  /// Latest check-in vs week 0, in instrument order. Empty before the
  /// first check-in.
  final List<DomainDelta> deltas;

  bool get hasComparison => points.length >= 2;
}

CheckinSeries buildCheckinSeries({
  required Map<String, int> baselineRaw,
  required Track track,
  required List<CheckinRecord> records,
}) {
  final domains = domainsForTrack(track);

  int totalOf(Map<String, int> scores) {
    var t = 0;
    for (final id in domains.keys) {
      t += scores[id] ?? 0;
    }
    return t;
  }

  final sorted = [...records]..sort((a, b) => a.week.compareTo(b.week));
  final points = <CheckinPoint>[
    if (baselineRaw.isNotEmpty) CheckinPoint(week: 0, total: totalOf(baselineRaw)),
    for (final r in sorted) CheckinPoint(week: r.week, total: totalOf(r.scores)),
  ];

  final measured = sorted.map((r) => r.week).toSet();
  final futureWeeks = [4, 8, 12].where((w) => !measured.contains(w)).toList();

  final deltas = <DomainDelta>[];
  if (sorted.isNotEmpty && baselineRaw.isNotEmpty) {
    final latest = sorted.last;
    for (final entry in domains.entries) {
      final before = baselineRaw[entry.key];
      final after = latest.scores[entry.key];
      deltas.add(DomainDelta(
        label: entry.value,
        delta: (before == null || after == null) ? null : after - before,
      ));
    }
  }

  return CheckinSeries(points: points, futureWeeks: futureWeeks, deltas: deltas);
}

/// Delta caption under the check-ins card (m3_02):
/// `Control +2 · Confidence +1 — on your own week-0 scale. Small movements,
/// really measured.` Flat/dipped domains are left out of the headline —
/// they speak on the result screen with the doctrine line.
String? deltaCaption(CheckinSeries series) {
  if (!series.hasComparison) return null;
  final ups = series.deltas.where((d) => d.up).toList();
  if (ups.isEmpty) {
    return 'No change this round — one measurement, not a verdict.';
  }
  final parts = ups.map((d) => '${d.label} +${d.delta}').join(' · ');
  return '$parts — on your own week-0 scale. Small movements, really measured.';
}

/// Doctrine §0.4 line for flat/dipped rows on the result screen.
String verdictLine(DomainDelta d) => d.dipped
    ? 'dipped this round — one measurement, not a verdict'
    : 'no change — one measurement, not a verdict';

// ---- Behavioral charts (session logs) ----

DateTime _monday(DateTime d) =>
    DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

/// Consistency grid: rows of 7 day-intensities (0–3 sessions+), oldest row
/// first. Grows one row per calendar week up to [maxRows], then slides
/// (growth rule). Rows always include the current week.
List<List<int>> consistencyGrid({
  required List<SessionLog> logs,
  required DateTime now,
  int maxRows = 4,
}) {
  final thisMonday = _monday(now);
  // Earliest log bounds the number of rows shown.
  DateTime? earliest;
  for (final l in logs) {
    if (earliest == null || l.completedAt.isBefore(earliest)) {
      earliest = l.completedAt;
    }
  }
  var rows = earliest == null
      ? 1
      : (thisMonday.difference(_monday(earliest)).inDays ~/ 7) + 1;
  rows = rows.clamp(1, maxRows);

  final grid = List.generate(rows, (_) => List<int>.filled(7, 0));
  final firstMonday = thisMonday.subtract(Duration(days: 7 * (rows - 1)));
  for (final l in logs) {
    final days = DateTime(
      l.completedAt.year,
      l.completedAt.month,
      l.completedAt.day,
    ).difference(firstMonday).inDays;
    if (days < 0 || days >= rows * 7) continue;
    final row = days ~/ 7;
    final col = days % 7;
    if (grid[row][col] < 3) grid[row][col]++;
  }
  return grid;
}

/// Weekly practice volume: minutes + hold-seconds-as-minutes, one value per
/// calendar week (oldest first, up to [maxBars], current week last).
List<double> weeklyVolume({
  required List<SessionLog> logs,
  required DateTime now,
  int maxBars = 6,
}) {
  final thisMonday = _monday(now);
  DateTime? earliest;
  for (final l in logs) {
    if (earliest == null || l.completedAt.isBefore(earliest)) {
      earliest = l.completedAt;
    }
  }
  var bars = earliest == null
      ? 1
      : (thisMonday.difference(_monday(earliest)).inDays ~/ 7) + 1;
  bars = bars.clamp(1, maxBars);

  final firstMonday = thisMonday.subtract(Duration(days: 7 * (bars - 1)));
  final volume = List<double>.filled(bars, 0);
  for (final l in logs) {
    final days = DateTime(
      l.completedAt.year,
      l.completedAt.month,
      l.completedAt.day,
    ).difference(firstMonday).inDays;
    if (days < 0 || days >= bars * 7) continue;
    final minutes = l.completedAt.difference(l.startedAt).inSeconds / 60;
    volume[days ~/ 7] += minutes + l.holdSeconds / 60;
  }
  return volume;
}

/// The input recap on the result screen: what he put in since (and incl.)
/// week 0 — sessions · minutes · active days of the window.
class InputRecap {
  const InputRecap({
    required this.sessions,
    required this.minutes,
    required this.activeDays,
    required this.windowDays,
  });

  final int sessions;
  final int minutes;
  final int activeDays;
  final int windowDays;
}

InputRecap inputRecap({
  required List<SessionLog> logs,
  required int sinceWeek,
  required int week,
  required DateTime now,
}) {
  final windowDays = (week - sinceWeek) * 7;
  final start = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: windowDays - 1));
  var sessions = 0;
  var minutes = 0.0;
  final days = <String>{};
  for (final l in logs) {
    if (l.completedAt.isBefore(start)) continue;
    sessions++;
    minutes += l.completedAt.difference(l.startedAt).inSeconds / 60;
    days.add('${l.completedAt.year}-${l.completedAt.month}-${l.completedAt.day}');
  }
  return InputRecap(
    sessions: sessions,
    minutes: minutes.round(),
    activeDays: days.length,
    windowDays: windowDays,
  );
}
