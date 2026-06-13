// Renders key M4 onboarding screens at 390×844@3x with real fonts →
// docs/ui_review/. Review artifacts, not goldens.
//
//   flutter test test/ui_review/m4_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/onboarding/health_questions.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/onboarding_pages.dart';
import 'package:sahaj/features/onboarding/pages/crisis_screen.dart';
import 'package:sahaj/features/onboarding/pages/plan_reveal_screen.dart';
import 'package:sahaj/features/onboarding/pages/resume_screen.dart';

const _outDir = 'docs/ui_review';
final _boundaryKey = GlobalKey();

OnboardingController _onboarding() => OnboardingController()
  ..setPersona(Persona.singleInexperienced)
  ..toggleGoal(Goal.firstTimeOrGap)
  ..toggleGoal(Goal.lastLongerOptimize);

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
}

Future<void> _pump(WidgetTester tester, Widget home,
    {List<Override> overrides = const [], bool reducedMotion = false}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: RepaintBoundary(
          key: _boundaryKey,
          child: reducedMotion
              ? Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(disableAnimations: true),
                    child: home,
                  ),
                )
              : home,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 800));
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

Override _ob() =>
    onboardingControllerProvider.overrideWith((ref) => _onboarding());

void main() {
  setUpAll(_loadFonts);

  testWidgets('m4 welcome', (tester) async {
    await _pump(tester, WelcomeScreen(onBegin: () {}));
    await _capture(tester, 'm4_c1_welcome');
  });

  testWidgets('m4 education slide 1', (tester) async {
    await _pump(tester, EducationScreen(onDone: () {}, onBack: () {}));
    await _capture(tester, 'm4_c3_education');
  });

  testWidgets('m4 persona', (tester) async {
    await _pump(tester, PersonaScreen(onNext: () {}, onBack: () {}),
        overrides: [_ob()]);
    await _capture(tester, 'm4_c4_persona');
  });

  testWidgets('m4_01 PHQ instrument item', (tester) async {
    final phq = kHealthQuestions.firstWhere((q) => q.id == 'mood_down');
    await _pump(
      tester,
      HealthQuestionScreen(
        question: phq,
        value: null,
        stepIndex: 7,
        stepCount: kHealthQuestions.length,
        onBack: () {},
        onAnswer: (_) {},
      ),
      overrides: [_ob()],
    );
    await _capture(tester, 'm4_01_phq_item');
  });

  testWidgets('m4 health why-strip item', (tester) async {
    final q = kHealthQuestions.firstWhere((q) => q.id == 'morning_erections');
    await _pump(
      tester,
      HealthQuestionScreen(
        question: q,
        value: null,
        stepIndex: 0,
        stepCount: kHealthQuestions.length,
        onBack: () {},
        onAnswer: (_) {},
      ),
      overrides: [_ob()],
    );
    await _capture(tester, 'm4_c6_health_item');
  });

  testWidgets('m4_02 plan reveal', (tester) async {
    await _pump(tester, PlanRevealScreen(onNext: () {}, onBack: () {}),
        overrides: [_ob()], reducedMotion: true);
    await _capture(tester, 'm4_02_plan_reveal');
  });

  testWidgets('m4 first session', (tester) async {
    await _pump(
        tester, FirstSessionScreen(onStartNow: () {}, onThisEvening: () {}));
    await _capture(tester, 'm4_c12_first_session');
  });

  testWidgets('m4 crisis', (tester) async {
    await _pump(tester, CrisisScreen(onContinue: () {}));
    await _capture(tester, 'm4_c7b_crisis');
  });

  testWidgets('m4_03 resume', (tester) async {
    await _pump(
      tester,
      ResumeScreen(
        whereLine: 'You were on the health check.',
        orientation: 'Question 4 of 10',
        onContinue: () {},
        onStartOver: () {},
      ),
    );
    await _capture(tester, 'm4_03_resume');
  });
}
