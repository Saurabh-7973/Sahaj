import '../../sessions/logic/models/session_models.dart';
import '../../sessions/session_catalog.dart';
import '../../subscription/logic/feature_gate.dart';

/// A practice session as the library renders it: the def plus its derived
/// marks (done-before ✓, Pro lock) and a one-line context.
class LibraryRow {
  const LibraryRow({
    required this.session,
    required this.locked,
    required this.doneBefore,
    required this.context,
  });

  final SessionDef session;
  final bool locked;
  final bool doneBefore;

  /// "kegel · timing control" — type + a short descriptor.
  final String context;

  int get minutes => (session.totalSeconds / 60).ceil();
}

/// A collapsible practice group keyed by session type (mock `14`).
class LibraryGroup {
  const LibraryGroup({required this.type, required this.rows});
  final SessionType type;
  final List<LibraryRow> rows;

  String get label => libraryTypeLabel(type);
  int get count => rows.length;
}

String libraryTypeLabel(SessionType type) => switch (type) {
      SessionType.kegel => 'Kegel',
      SessionType.reverseKegel => 'Reverse kegel',
      SessionType.breathwork => 'Breathwork',
      SessionType.sensate => 'Sensate',
      SessionType.education => 'Learn',
      SessionType.mindset => 'Mindset',
    };

/// Group order on the tab (kegel first — the core technique).
const _typeOrder = <SessionType>[
  SessionType.kegel,
  SessionType.breathwork,
  SessionType.reverseKegel,
  SessionType.sensate,
  SessionType.mindset,
  SessionType.education,
];

/// A short context line for a session row (mock: "kegel · week 3").
String sessionContext(SessionDef s) {
  final type = s.type.name;
  // Use the most descriptive step title as the hint (real content, no spin).
  const skip = {'Settle', 'Warm up', 'Cool down', 'Close', 'Rest', 'Set up'};
  for (final st in s.steps) {
    if (st.title.isNotEmpty && !skip.contains(st.title)) {
      return '$type · ${st.title.toLowerCase()}';
    }
  }
  return type;
}

/// Builds the practice groups. Free rows sort first within every group
/// (principle 2 — the free tier must visually dominate); within free/locked,
/// titles sort alphabetically for stability.
List<LibraryGroup> buildGroups({
  required SessionCatalog catalog,
  required bool isPro,
  required Set<String> doneTags,
}) {
  final byType = <SessionType, List<LibraryRow>>{};
  for (final s in catalog.byTag.values) {
    final locked = isSessionLocked(s.tag, isPro: isPro);
    byType.putIfAbsent(s.type, () => []).add(LibraryRow(
          session: s,
          locked: locked,
          doneBefore: doneTags.contains(s.tag),
          context: sessionContext(s),
        ));
  }
  final groups = <LibraryGroup>[];
  for (final type in _typeOrder) {
    final rows = byType[type];
    if (rows == null || rows.isEmpty) continue;
    rows.sort((a, b) {
      if (a.locked != b.locked) return a.locked ? 1 : -1; // free first
      return a.session.title.compareTo(b.session.title);
    });
    groups.add(LibraryGroup(type: type, rows: rows));
  }
  return groups;
}

/// Total session count across all groups (header "Practice · 54 sessions").
int totalSessions(List<LibraryGroup> groups) =>
    groups.fold(0, (n, g) => n + g.count);

/// A search match within the library — a row plus the highlight span of the
/// query inside its title.
class SearchMatch {
  const SearchMatch({required this.row, required this.start, required this.end});
  final LibraryRow row;
  final int start;
  final int end;
}

/// Title-only, case-insensitive substring search (M5 §2 / decision #4).
/// Returns matches in the same group order; empty groups simply don't appear.
List<SearchMatch> searchLibrary(List<LibraryGroup> groups, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final out = <SearchMatch>[];
  for (final g in groups) {
    for (final row in g.rows) {
      final i = row.session.title.toLowerCase().indexOf(q);
      if (i >= 0) {
        out.add(SearchMatch(row: row, start: i, end: i + q.length));
      }
    }
  }
  return out;
}

/// Tags of sessions completed at least once (for the faint ✓ "redo what
/// worked" mark).
Set<String> completedTags(List<SessionLog> logs) =>
    logs.map((l) => l.sessionTag).toSet();
