// Renders every M1 screen/state at 390×844@3x with the real bundled fonts and
// writes PNGs into docs/ui_review/ for the visual pass. Run:
//
//   flutter test test/ui_review/m1_screenshots_test.dart
//
// These are review artifacts, not goldens — they never fail on pixels.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/pages/completion_page.dart';
import 'package:sahaj/features/sessions/pages/face_down_coach.dart';
import 'package:sahaj/features/sessions/pages/mood_checkin_sheet.dart';
import 'package:sahaj/features/sessions/pages/reflection_page.dart';
import 'package:sahaj/features/sessions/pages/session_player_page.dart';
import 'package:sahaj/shared/widgets/widgets.dart';

const _outDir = 'docs/ui_review';
final _boundaryKey = GlobalKey();

SessionDef get _kegelSession => const SessionDef(
      tag: 'pfmt_identify',
      title: 'Gentle holds, long exhale',
      type: SessionType.kegel,
      steps: [
        SessionStep(title: 'Settle', seconds: 30, guidance: 'Breathe slowly.'),
        SessionStep(title: 'Locate', seconds: 60, guidance: 'Find the muscle.'),
        SessionStep(
          title: 'Gentle holds',
          seconds: 120,
          guidance: 'Squeeze for 6, release for 8.',
          pattern: HoldReleasePattern(holdSeconds: 6, releaseSeconds: 8),
        ),
        SessionStep(title: 'Slow it down', seconds: 60, guidance: 'Ease off.'),
        SessionStep(title: 'Close', seconds: 30, guidance: 'Rest.'),
      ],
    );

SessionDef get _breathSession => const SessionDef(
      tag: 'breathwork_basics_v2',
      title: 'Gentle holds, long exhale',
      type: SessionType.breathwork,
      steps: [
        SessionStep(title: 'Settle', seconds: 30, guidance: 'Sit tall but easy.'),
        SessionStep(
          title: 'Long exhale',
          seconds: 150,
          guidance: 'Out through the mouth, twice as long as in.',
          pattern: BreathPattern(inhaleSeconds: 3, exhaleSeconds: 6),
        ),
        SessionStep(title: 'Rest', seconds: 30, guidance: 'Normal breath.'),
        SessionStep(title: 'Close', seconds: 30, guidance: 'Done.'),
      ],
    );

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
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
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(icons.readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
  }
}

Future<void> _pumpApp(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: home,
      ),
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = _boundaryKey.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;
  late final ByteData bytes;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
    bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  });
  final file = File('$_outDir/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote ${file.path}');
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('m1_01 mood check-in + prescription echo', (tester) async {
    await _pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  showMoodCheckin(context, session: _kegelSession),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Heavy'));
    await tester.tap(find.text('Low'));
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'm1_01a_mood_checkin');

    await tester.tap(find.textContaining('session', findRichText: false).last);
    await tester.pump(const Duration(milliseconds: 500));
    await _capture(tester, 'm1_01b_prescription_echo');
  });

  testWidgets('m1_02 player — squeeze and release', (tester) async {
    await _pumpApp(
      tester,
      SessionPlayerPage(session: _kegelSession, onComplete: (_) {}),
    );
    // Skip to the patterned step (Gentle holds).
    await tester.tap(find.bySemanticsLabel('Next step'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Next step'));
    await tester.pump();
    // 2s into hold 1: squeeze, numeral 4 of 6.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    await _capture(tester, 'm1_02a_player_squeeze');

    // 8s in: release phase of hold 1.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 400));
    await _capture(tester, 'm1_02b_player_release');
  });

  testWidgets('m1_03 player — breath and paused', (tester) async {
    await _pumpApp(
      tester,
      SessionPlayerPage(session: _breathSession, onComplete: (_) {}),
    );
    await tester.tap(find.bySemanticsLabel('Next step'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4)); // exhale of round 1
    await tester.pump(const Duration(milliseconds: 200));
    await _capture(tester, 'm1_03a_player_breath');

    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'm1_03b_player_paused');
  });

  testWidgets('m1_04 face-down coach + ember', (tester) async {
    await _pumpApp(tester, const FaceDownCoachPage());
    await tester.pump(const Duration(milliseconds: 100));
    await _capture(tester, 'm1_04a_facedown_coach');

    await _pumpApp(
      tester,
      SessionPlayerPage(
        session: _kegelSession,
        onComplete: (_) {},
        startInEmber: true,
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await _capture(tester, 'm1_04b_ember');
  });

  testWidgets('m1_05 reflection — harder selected', (tester) async {
    await _pumpApp(
      tester,
      const ReflectionPage(
        sessionTitle: 'Gentle holds',
        sessionNumber: 14,
      ),
    );
    await tester.tap(find.text('Harder'));
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'm1_05_reflection');
  });

  testWidgets('m1_06 completion — standard and milestone', (tester) async {
    await _pumpApp(
      tester,
      const CompletionPage(
        sessionNumber: 14,
        nthThisWeek: 3,
        tomorrowTitle: 'Stop-start',
        tomorrowMinutes: 9,
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));
    await _capture(tester, 'm1_06a_completion');

    await _pumpApp(
      tester,
      const CompletionPage(
        sessionNumber: 28,
        nthThisWeek: 7,
        milestoneWeek: 4,
        currentWeek: 4,
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));
    await _capture(tester, 'm1_06b_completion_milestone');
  });

  testWidgets('m1 widgets — mood glyph row reference', (tester) async {
    await _pumpApp(
      tester,
      Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppMoodSelector(
              selected: const {ArrivalMood.heavy, ArrivalMood.low},
              onToggle: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'm1_ref_mood_glyphs');
  });
}
