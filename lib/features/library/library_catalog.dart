import '../sessions/logic/models/session_models.dart';
import '../sessions/session_catalog.dart';

/// A labelled, ordered group of sessions for the Library tab.
class LibraryGroup {
  const LibraryGroup(this.label, this.sessions);
  final String label;
  final List<SessionDef> sessions;
}

const _order = <(String, List<SessionType>)>[
  ('Exercises', [SessionType.kegel, SessionType.reverseKegel]),
  ('Breathwork', [SessionType.breathwork]),
  ('Practice', [SessionType.mindset, SessionType.sensate]),
  ('Learn', [SessionType.education]),
];

/// Groups the catalog's sessions into display categories (empty groups omitted),
/// each group's sessions sorted by title for stable ordering.
List<LibraryGroup> groupLibrary(SessionCatalog catalog) {
  final all = catalog.byTag.values.toList()
    ..sort((a, b) => a.title.compareTo(b.title));
  final groups = <LibraryGroup>[];
  for (final (label, types) in _order) {
    final sessions =
        all.where((d) => types.contains(d.type)).toList(growable: false);
    if (sessions.isNotEmpty) groups.add(LibraryGroup(label, sessions));
  }
  return groups;
}
