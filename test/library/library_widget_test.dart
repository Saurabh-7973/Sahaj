import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/home/tabs/library_page.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';

SessionDef _def(String tag, String title, SessionType type) => SessionDef(
      tag: tag,
      title: title,
      type: type,
      steps: const [SessionStep(title: 's', seconds: 60, guidance: 'g')],
    );

void main() {
  testWidgets('renders grouped session cards from the catalog', (tester) async {
    final catalog = SessionCatalog({
      'pfmt_identify': _def('pfmt_identify', 'Finding the muscles', SessionType.kegel),
      'breathwork_basics': _def('breathwork_basics', 'Calm breathing', SessionType.breathwork),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionCatalogProvider.overrideWithValue(catalog),
        ],
        child: const MaterialApp(home: LibraryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('Breathwork'), findsOneWidget);
    expect(find.text('Finding the muscles'), findsOneWidget);
    expect(find.text('Calm breathing'), findsOneWidget);
  });
}
