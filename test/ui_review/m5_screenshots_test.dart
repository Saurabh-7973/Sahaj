// Renders key M5 library + reader screens at 390×844@3x with real fonts →
// docs/ui_review/. Review artifacts, not goldens.
//
//   flutter test test/ui_review/m5_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/home/tabs/library_page.dart';
import 'package:sahaj/features/library/article_catalog.dart';
import 'package:sahaj/features/library/logic/article.dart';
import 'package:sahaj/features/library/pages/article_reader_page.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';

const _outDir = 'docs/ui_review';
final _boundaryKey = GlobalKey();

SessionDef _s(String tag, String title, SessionType type,
        {int min = 8}) =>
    SessionDef(
      tag: tag,
      title: title,
      type: type,
      steps: [
        const SessionStep(title: 'Settle', seconds: 30, guidance: 'g'),
        SessionStep(
            title: 'Long holds', seconds: min * 60 - 30, guidance: 'g'),
      ],
    );

SessionCatalog _catalog() => SessionCatalog({
      'pfmt_identify': _s('pfmt_identify', 'Find the muscle', SessionType.kegel, min: 5),
      'pfmt_identify_v2':
          _s('pfmt_identify_v2', 'Cleaner contractions', SessionType.kegel),
      'pfmt_functional': _s('pfmt_functional', 'Wave holds', SessionType.kegel, min: 10),
      'advanced_control':
          _s('advanced_control', 'Hold-release ladders', SessionType.kegel, min: 9),
      'breathwork_basics':
          _s('breathwork_basics', 'Calm breathing', SessionType.breathwork, min: 7),
      'sensate_solo': _s('sensate_solo', 'Sensate focus', SessionType.sensate),
    });

const _evidence = Article(
  slug: 'pelvic-floor',
  title: 'Your pelvic floor runs erection control',
  category: 'Anatomy',
  readMinutes: 6,
  register: ArticleRegister.evidence,
  reviewState: ReviewState.reviewed,
  reviewedDate: 'May 2026',
  sources: [
    Citation(
      name: 'Dorey et al., 2005 — BJU International',
      finding: 'randomised trial: pelvic floor exercises for erectile dysfunction',
    ),
    Citation(
      name: 'Rosen et al., 1997 — Urology',
      finding: "the IIEF instrument this app's check-ins adapt",
    ),
    Citation(
      name: 'Symonds et al., 2007 — European Urology',
      finding: 'PEDT — the premature ejaculation diagnostic tool',
    ),
  ],
  body: 'During erection, two pelvic-floor muscles do quiet, decisive work: '
      'they compress the veins that would otherwise let blood drain back out. '
      'Stronger, better-timed contractions mean better trapping — which is why '
      'pelvic floor muscle training shows up in the clinical evidence for both '
      'erectile function and ejaculatory control.\n\n'
      'That makes this exercise, not mystery. The same logic as any rehab '
      'protocol applies: find the muscle, isolate it, load it progressively.',
);

const _heritage = Article(
  slug: 'ananga-ranga',
  title: 'What the Ananga Ranga says about pacing',
  category: 'Heritage',
  readMinutes: 8,
  register: ArticleRegister.heritage,
  eraTag: 'Ananga Ranga · Burton tr., 1885 — language of its time',
  body: 'Centuries before Western sexology existed, Indian manuals treated '
      'pacing as a craft to be studied — openly, without embarrassment. Your '
      'culture has handled this as knowledge for millennia.\n\n'
      '> A measured pace is itself a discipline of the art.\n\n'
      'What the old text frames as artistry, modern training frames as '
      'arousal regulation — the stop-start work in weeks 5–8 of your plan.',
);

Future<void> _loadFonts() async {
  Future<void> load(String f, List<String> a) async {
    final l = FontLoader(f);
    for (final p in a) {
      l.addFont(rootBundle.load(p));
    }
    await l.load();
  }

  await load('Fraunces', [
    'assets/fonts/Fraunces-300.ttf',
    'assets/fonts/Fraunces-400Italic.ttf',
    'assets/fonts/Fraunces-500.ttf',
    'assets/fonts/Fraunces-600.ttf',
  ]);
  await load('Manrope', [
    'assets/fonts/Manrope-400.ttf',
    'assets/fonts/Manrope-500.ttf',
    'assets/fonts/Manrope-600.ttf',
    'assets/fonts/Manrope-700.ttf',
    'assets/fonts/Manrope-800.ttf',
  ]);

  // Real Material icons instead of test boxes, when the SDK cache has them.
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final f = File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (f.existsSync()) {
      await (FontLoader('MaterialIcons')
            ..addFont(Future.value(f.readAsBytesSync().buffer.asByteData())))
          .load();
    }
  }
}

Future<void> _pump(WidgetTester tester, Widget home,
    {List<Override> overrides = const []}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: home,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = _boundaryKey.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;
  late final ByteData bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  });
  File('$_outDir/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $_outDir/$name.png');
}

List<Override> get _libOverrides => [
      sessionCatalogProvider.overrideWithValue(_catalog()),
      articleCatalogProvider
          .overrideWithValue(const ArticleCatalog([_evidence, _heritage])),
      progressControllerProvider.overrideWith((ref) => ProgressController()),
    ];

void main() {
  setUpAll(_loadFonts);

  testWidgets('m5 library browse', (tester) async {
    await _pump(tester, const LibraryPage(), overrides: _libOverrides);
    // Expand the Kegel group.
    await tester.tap(find.text('Kegel'));
    await tester.pumpAndSettle();
    await _capture(tester, 'm5_14_library');
  });

  testWidgets('m5_01 search', (tester) async {
    await _pump(tester, const LibraryPage(), overrides: _libOverrides);
    await tester.enterText(find.byType(TextField), 'hold');
    await tester.pumpAndSettle();
    await _capture(tester, 'm5_01_library_search');
  });

  testWidgets('m5 reader — evidence', (tester) async {
    await _pump(tester,
        const ArticleReaderPage(article: _evidence, nextArticle: _heritage));
    await _capture(tester, 'm5_20_reader_evidence');
  });

  testWidgets('m5_02 reader — heritage', (tester) async {
    await _pump(tester,
        const ArticleReaderPage(article: _heritage, nextArticle: _evidence));
    await _capture(tester, 'm5_02_reader_heritage');
  });
}
