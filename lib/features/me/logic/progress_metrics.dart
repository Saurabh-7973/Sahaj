import '../../sessions/logic/models/session_models.dart';

/// Honest progress numbers computed from real session logs + plan position.
class ProgressMetrics {
  const ProgressMetrics({
    required this.totalSessions,
    required this.currentStreak,
    required this.longestStreak,
    required this.thisWeekCount,
    required this.currentWeek,
    required this.phase,
    required this.easierCount,
    required this.sameCount,
    required this.harderCount,
  });

  final int totalSessions;
  final int currentStreak;
  final int longestStreak;
  final int thisWeekCount;
  final int currentWeek;
  final String phase;
  final int easierCount;
  final int sameCount;
  final int harderCount;

  bool get hasData => totalSessions > 0;
}

/// Computes [ProgressMetrics]. Streak comes straight from [progress] (Phase 4
/// is the single source of truth); the rest derive from [logs]. Clock injected.
ProgressMetrics computeMetrics({
  required List<SessionLog> logs,
  required ProgressState progress,
  required String phase,
  required DateTime now,
}) {
  final cutoff = now.subtract(const Duration(days: 7));
  var thisWeek = 0;
  var easier = 0;
  var same = 0;
  var harder = 0;
  for (final l in logs) {
    if (l.completedAt.isAfter(cutoff) && !l.completedAt.isAfter(now)) {
      thisWeek += 1;
    }
    switch (l.perceivedDifficulty) {
      case PerceivedDifficulty.easier:
        easier += 1;
      case PerceivedDifficulty.same:
        same += 1;
      case PerceivedDifficulty.harder:
        harder += 1;
      case null:
        break;
    }
  }
  return ProgressMetrics(
    totalSessions: logs.length,
    currentStreak: progress.streak,
    longestStreak: progress.longestStreak,
    thisWeekCount: thisWeek,
    currentWeek: progress.currentWeek,
    phase: phase,
    easierCount: easier,
    sameCount: same,
    harderCount: harder,
  );
}
