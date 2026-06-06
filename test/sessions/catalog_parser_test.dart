import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/catalog_parser.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';

const _json = '''
{
  "pfmt_identify": {
    "title": "Finding the muscles",
    "type": "kegel",
    "steps": [
      {"title": "Settle", "seconds": 30, "guidance": "Relax."},
      {"title": "Locate", "seconds": 60, "guidance": "Find them."}
    ]
  },
  "breathwork_basics": {
    "title": "Calm breathing",
    "type": "breathwork",
    "steps": [
      {"title": "Inhale", "seconds": 120, "guidance": "Slow breaths."}
    ]
  }
}
''';

void main() {
  test('parseCatalog builds a tag-keyed map of SessionDefs', () {
    final catalog = parseCatalog(_json);
    expect(catalog.keys, containsAll(['pfmt_identify', 'breathwork_basics']));
    expect(catalog['pfmt_identify']!.type, SessionType.kegel);
    expect(catalog['pfmt_identify']!.totalSeconds, 90);
    expect(catalog['breathwork_basics']!.steps.single.title, 'Inhale');
  });
}
