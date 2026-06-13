// +30% string room: key M4 screens at 1.3 text scale, no overflow.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/onboarding/health_questions.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/onboarding_pages.dart';
import 'package:sahaj/features/onboarding/pages/crisis_screen.dart';
import 'package:sahaj/features/onboarding/pages/plan_reveal_screen.dart';

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
  await tester.pump(const Duration(milliseconds: 800));
}

OnboardingController _ob() => OnboardingController()
  ..setPersona(Persona.singleInexperienced)
  ..toggleGoal(Goal.firstTimeOrGap)
  ..toggleGoal(Goal.lastLongerOptimize);

void main() {
  testWidgets('welcome at 1.3', (tester) async {
    await _pump(tester, WelcomeScreen(onBegin: () {}));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PHQ item at 1.3', (tester) async {
    final q = kHealthQuestions.firstWhere((q) => q.id == 'mood_down');
    await _pump(
      tester,
      HealthQuestionScreen(
        question: q,
        value: null,
        stepIndex: 7,
        stepCount: kHealthQuestions.length,
        onBack: () {},
        onAnswer: (_) {},
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan reveal at 1.3', (tester) async {
    await _pump(
      tester,
      PlanRevealScreen(onNext: () {}, onBack: () {}),
      overrides: [
        onboardingControllerProvider.overrideWith((ref) => _ob()),
      ],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('crisis at 1.3', (tester) async {
    await _pump(tester, CrisisScreen(onContinue: () {}));
    expect(tester.takeException(), isNull);
  });

  testWidgets('first session at 1.3', (tester) async {
    await _pump(
        tester, FirstSessionScreen(onStartNow: () {}, onThisEvening: () {}));
    expect(tester.takeException(), isNull);
  });
}
