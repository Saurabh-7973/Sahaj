import '../../onboarding/logic/models/onboarding_models.dart';
import 'models/session_models.dart';

/// Picks today's session from the current week's moduleTags.
///
/// Keeps only tags that have a catalog entry (drops track tags like
/// `solo`/`partnered`), then selects by day-of-week with wraparound.
/// Returns null when the week is missing or has no playable tags.
SessionDef? todaysSession({
  required Plan plan,
  required int week,
  required int day,
  required Map<String, SessionDef> catalog,
}) {
  PlanWeek? planWeek;
  for (final w in plan.weeks) {
    if (w.number == week) {
      planWeek = w;
      break;
    }
  }
  if (planWeek == null) return null;

  final playable =
      planWeek.moduleTags.where(catalog.containsKey).toList(growable: false);
  if (playable.isEmpty) return null;

  final tag = playable[(day - 1) % playable.length];

  // Week-over-week variety: a tag may have variant modules named `${tag}_v2`,
  // `${tag}_v3`, … Rotate through them by week so the same slot doesn't replay
  // the identical session every week. Tags with no variants stay stable.
  final variants = <String>[tag];
  for (var i = 2;; i++) {
    final v = '${tag}_v$i';
    if (catalog.containsKey(v)) {
      variants.add(v);
    } else {
      break;
    }
  }
  final chosen = variants[(week - 1) % variants.length];
  return catalog[chosen];
}
