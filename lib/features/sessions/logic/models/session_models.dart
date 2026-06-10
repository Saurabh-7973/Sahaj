import 'package:flutter/foundation.dart';

/// Kind of training unit (drives the Today card label/icon).
enum SessionType { kegel, reverseKegel, breathwork, sensate, education, mindset }

SessionType _typeFromName(String? name) {
  for (final t in SessionType.values) {
    if (t.name == name) return t;
  }
  return SessionType.education;
}

/// One timed step within a session.
@immutable
class SessionStep {
  const SessionStep({
    required this.title,
    required this.seconds,
    required this.guidance,
  });

  final String title;
  final int seconds;
  final String guidance;

  factory SessionStep.fromJson(Map json) => SessionStep(
        title: json['title'] as String,
        seconds: (json['seconds'] as num).toInt(),
        guidance: json['guidance'] as String,
      );
}

/// A playable session, keyed by the plan's moduleTag.
@immutable
class SessionDef {
  const SessionDef({
    required this.tag,
    required this.title,
    required this.type,
    required this.steps,
    this.audioRef,
  });

  final String tag;
  final String title;
  final SessionType type;
  final List<SessionStep> steps;

  /// Optional per-locale audio (`{'en': 'audio/<tag>_en.m4a', …}`). Null means
  /// the session is text+timer only — true for the whole catalog until audio
  /// content is recorded.
  final Map<String, String>? audioRef;

  int get totalSeconds =>
      steps.fold(0, (sum, s) => sum + s.seconds);

  factory SessionDef.fromJson(String tag, Map json) => SessionDef(
        tag: tag,
        title: json['title'] as String,
        type: _typeFromName(json['type'] as String?),
        steps: ((json['steps'] as List?) ?? const [])
            .map((s) => SessionStep.fromJson(s as Map))
            .toList(),
        audioRef: (json['audioRef'] as Map?)?.map(
          (k, v) => MapEntry(k as String, v as String),
        ),
      );
}

/// Post-session self-report.
enum PerceivedDifficulty { easier, same, harder }

PerceivedDifficulty? _difficultyFromName(String? name) {
  if (name == null) return null;
  for (final d in PerceivedDifficulty.values) {
    if (d.name == name) return d;
  }
  return null;
}

/// A record of a completed (or partial) session.
@immutable
class SessionLog {
  const SessionLog({
    required this.id,
    required this.sessionTag,
    required this.startedAt,
    required this.completedAt,
    required this.completionPct,
    required this.moodBefore,
    this.perceivedDifficulty,
    this.journalNote,
  });

  final String id;
  final String sessionTag;
  final DateTime startedAt;
  final DateTime completedAt;
  final double completionPct;
  final List<String> moodBefore;
  final PerceivedDifficulty? perceivedDifficulty;
  final String? journalNote;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionTag': sessionTag,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'completionPct': completionPct,
        'moodBefore': moodBefore,
        'perceivedDifficulty': perceivedDifficulty?.name,
        'journalNote': journalNote,
      };

  factory SessionLog.fromJson(Map json) => SessionLog(
        id: json['id'] as String,
        sessionTag: json['sessionTag'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: DateTime.parse(json['completedAt'] as String),
        completionPct: (json['completionPct'] as num).toDouble(),
        moodBefore: List<String>.from(json['moodBefore'] as List? ?? const []),
        perceivedDifficulty:
            _difficultyFromName(json['perceivedDifficulty'] as String?),
        journalNote: json['journalNote'] as String?,
      );
}

/// Where the user is in the 12-week plan + streak bookkeeping.
@immutable
class ProgressState {
  const ProgressState({
    this.currentWeek = 1,
    this.currentDay = 1,
    this.streak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
  });

  final int currentWeek; // 1..12
  final int currentDay; // 1..7
  final int streak;
  final int longestStreak;
  final String? lastCompletedDate; // 'YYYY-MM-DD' local

  ProgressState copyWith({
    int? currentWeek,
    int? currentDay,
    int? streak,
    int? longestStreak,
    String? lastCompletedDate,
  }) =>
      ProgressState(
        currentWeek: currentWeek ?? this.currentWeek,
        currentDay: currentDay ?? this.currentDay,
        streak: streak ?? this.streak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      );

  Map<String, dynamic> toJson() => {
        'currentWeek': currentWeek,
        'currentDay': currentDay,
        'streak': streak,
        'longestStreak': longestStreak,
        'lastCompletedDate': lastCompletedDate,
      };

  factory ProgressState.fromJson(Map json) => ProgressState(
        currentWeek: (json['currentWeek'] as num?)?.toInt() ?? 1,
        currentDay: (json['currentDay'] as num?)?.toInt() ?? 1,
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
        lastCompletedDate: json['lastCompletedDate'] as String?,
      );
}
