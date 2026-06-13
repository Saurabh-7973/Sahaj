import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/onboarding_flow.dart';

void main() {
  test('lastStep round-trips through toJson/loadFrom', () {
    final c = OnboardingController()..setLastStep(7);
    final restored = OnboardingController()..loadFrom(c.toJson());
    expect(restored.lastStep, 7);
  });

  testWidgets('returning mid-flow shows the resume screen, not Welcome',
      (tester) async {
    // lastStep 6 = first health question (orientation "Question 1 of 10").
    final controller = OnboardingController()..setLastStep(6);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const OnboardingFlow()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Picking up'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Start over'), findsOneWidget);
    expect(find.textContaining('Question 1 of 10'), findsOneWidget);

    // Continue lands on the pending screen, not Welcome.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Picking up'), findsNothing);
    expect(find.text('Health check'), findsOneWidget);
  });

  testWidgets('Start over wipes onboarding answers and returns to Welcome',
      (tester) async {
    final controller = OnboardingController()
      ..setPersona(Persona.singleInexperienced)
      ..setLastStep(6);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const OnboardingFlow()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start over'));
    await tester.pumpAndSettle();

    expect(controller.persona, isNull);
    expect(controller.lastStep, 0);
    expect(find.text('Train steady.'), findsOneWidget);
  });
}
