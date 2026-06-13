import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/home/tabs/library_page.dart';
import 'package:sahaj/features/library/article_catalog.dart';
import 'package:sahaj/features/library/logic/article.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';

SessionDef _def(String tag, String title, SessionType type) => SessionDef(
      tag: tag,
      title: title,
      type: type,
      steps: const [SessionStep(title: 'Hold', seconds: 60, guidance: 'g')],
    );

Widget _app() {
  final catalog = SessionCatalog({
    'pfmt_identify':
        _def('pfmt_identify', 'Finding the muscles', SessionType.kegel),
    'pfmt_functional': _def('pfmt_functional', 'Wave holds', SessionType.kegel),
    'breathwork_basics':
        _def('breathwork_basics', 'Calm breathing', SessionType.breathwork),
  });
  return ProviderScope(
    overrides: [
      sessionCatalogProvider.overrideWithValue(catalog),
      articleCatalogProvider.overrideWithValue(
        const ArticleCatalog([
          Article(
            slug: 'a',
            title: 'How your pelvic floor works',
            category: 'Anatomy',
            readMinutes: 3,
            body: 'body',
          ),
        ]),
      ),
    ],
    child: MaterialApp(theme: AppTheme.dark(), home: const LibraryPage()),
  );
}

void main() {
  testWidgets('reading first, then collapsed practice groups', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('How your pelvic floor works'), findsOneWidget);
    // Group headers by type; rows hidden until expanded.
    expect(find.text('Kegel'), findsOneWidget);
    expect(find.text('Breathwork'), findsOneWidget);
    expect(find.text('Finding the muscles'), findsNothing);
  });

  testWidgets('expanding a group reveals rows, free before Pro', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kegel'));
    await tester.pumpAndSettle();

    expect(find.text('Finding the muscles'), findsOneWidget); // free
    expect(find.text('Wave holds'), findsOneWidget); // Pro (locked)
    expect(find.text('Pro'), findsWidgets);
  });

  testWidgets('search filters to title matches', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'wave');
    await tester.pumpAndSettle();

    expect(find.text('1 match'), findsOneWidget);
    expect(find.text('Wave holds'), findsOneWidget);
    expect(find.text('Calm breathing'), findsNothing);
  });
}
