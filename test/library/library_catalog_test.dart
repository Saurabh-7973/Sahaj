import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/library/library_catalog.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';

SessionDef _def(String tag, SessionType type) => SessionDef(
      tag: tag,
      title: tag,
      type: type,
      steps: const [SessionStep(title: 's', seconds: 60, guidance: 'g')],
    );

void main() {
  test('groups by display category, omits empty groups, ordered', () {
    final catalog = SessionCatalog({
      'pfmt_identify': _def('pfmt_identify', SessionType.kegel),
      'reverse_kegel_intro': _def('reverse_kegel_intro', SessionType.reverseKegel),
      'breathwork_basics': _def('breathwork_basics', SessionType.breathwork),
      'stop_start': _def('stop_start', SessionType.mindset),
      'anatomy': _def('anatomy', SessionType.education),
    });

    final groups = groupLibrary(catalog);
    final labels = groups.map((g) => g.label).toList();
    expect(labels, ['Exercises', 'Breathwork', 'Practice', 'Learn']);

    final exercises = groups.first;
    expect(exercises.sessions.length, 2);
  });

  test('omits a group with no sessions', () {
    final catalog = SessionCatalog({
      'breathwork_basics': _def('breathwork_basics', SessionType.breathwork),
    });
    final groups = groupLibrary(catalog);
    expect(groups.map((g) => g.label), ['Breathwork']);
  });
}
