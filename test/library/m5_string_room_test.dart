// +30% string room: M5 library + reader at 1.3 text scale, no overflow
// (drop cap + meta row are the risky bits).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/home/tabs/library_page.dart';
import 'package:sahaj/features/library/article_catalog.dart';
import 'package:sahaj/features/library/logic/article.dart';
import 'package:sahaj/features/library/pages/article_reader_page.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';

SessionDef _s(String tag, String title, SessionType type) => SessionDef(
      tag: tag,
      title: title,
      type: type,
      steps: const [
        SessionStep(title: 'Settle', seconds: 30, guidance: 'g'),
        SessionStep(title: 'Long holds', seconds: 120, guidance: 'g'),
      ],
    );

const _evidence = Article(
  slug: 'e',
  title: 'Your pelvic floor runs erection control',
  category: 'Anatomy',
  readMinutes: 6,
  reviewState: ReviewState.reviewed,
  reviewedDate: 'May 2026',
  sources: [
    Citation(name: 'Dorey et al., 2005 — BJU International', finding: 'rct'),
  ],
  body: 'During erection, two pelvic-floor muscles do quiet, decisive work.\n\n'
      'That makes this exercise, not mystery.',
);

Future<void> _pump(WidgetTester tester, Widget home,
    {List<Override> overrides = const []}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('library browse at 1.3', (tester) async {
    await _pump(
      tester,
      const LibraryPage(),
      overrides: [
        sessionCatalogProvider.overrideWithValue(SessionCatalog({
          'pfmt_identify': _s('pfmt_identify', 'Find the muscle', SessionType.kegel),
          'pfmt_functional': _s('pfmt_functional', 'Wave holds', SessionType.kegel),
        })),
        articleCatalogProvider
            .overrideWithValue(const ArticleCatalog([_evidence])),
        progressControllerProvider.overrideWith((ref) => ProgressController()),
      ],
    );
    await tester.tap(find.text('Kegel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('evidence reader at 1.3 (drop cap)', (tester) async {
    await _pump(tester, const ArticleReaderPage(article: _evidence));
    expect(tester.takeException(), isNull);
  });
}
