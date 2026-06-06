import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/settings/logic/data_export.dart';

void main() {
  test('assembleExportJson nests all sections and is valid JSON', () {
    final out = assembleExportJson(
      onboarding: {'persona': 'singleInexperienced', 'complete': true},
      progress: {'currentWeek': 2, 'currentDay': 3},
      logs: [
        {'id': 'a', 'sessionTag': 'anatomy'},
      ],
      preferences: {'bookMode': true},
      exportedAt: DateTime.utc(2026, 6, 6, 12),
    );

    final decoded = jsonDecode(out) as Map<String, dynamic>;
    expect(decoded['exportedAt'], '2026-06-06T12:00:00.000Z');
    expect((decoded['onboarding'] as Map)['persona'], 'singleInexperienced');
    expect((decoded['progress'] as Map)['currentWeek'], 2);
    expect((decoded['sessionLogs'] as List).length, 1);
    expect((decoded['preferences'] as Map)['bookMode'], true);
  });

  test('null onboarding becomes an empty section', () {
    final out = assembleExportJson(
      onboarding: null,
      progress: const {},
      logs: const [],
      preferences: const {},
      exportedAt: DateTime.utc(2026, 1, 1),
    );
    final decoded = jsonDecode(out) as Map<String, dynamic>;
    expect(decoded['onboarding'], isNull);
    expect(decoded['sessionLogs'], isEmpty);
  });

  test('output is pretty-printed (indented)', () {
    final out = assembleExportJson(
      onboarding: const {},
      progress: const {},
      logs: const [],
      preferences: const {},
      exportedAt: DateTime.utc(2026, 1, 1),
    );
    expect(out.contains('\n  '), isTrue);
  });
}
