import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/onboarding/health_questions.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/onboarding_flow.dart';
import 'package:sahaj/features/onboarding/widgets/selectable_option.dart';

const _selfHarmPrompt =
    'Over the last 2 weeks, how often have you had thoughts that you '
    'would be better off dead, or of hurting yourself?';

void main() {
  testWidgets('persona routing sets solo track for single user',
      (tester) async {
    final c = OnboardingController()..setPersona(Persona.singleInexperienced);
    expect(c.track, Track.solo);
  });

  /// Drives the new auto-advancing flow from Welcome to the self_harm
  /// question, tapping the first (benign) option on every health item before
  /// it. Returns nothing — the self_harm prompt is on screen when done.
  Future<void> driveToSelfHarm(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider
              .overrideWith((ref) => OnboardingController()),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const OnboardingFlow()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sounds fair'));
    await tester.pumpAndSettle();
    // Education: Next, Next, Got it.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    // Persona: pick + Continue.
    await tester.tap(find.byType(SelectableOption).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // Goals: pick + Continue.
    await tester.tap(find.byType(SelectableOption).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // Health intro.
    await tester.tap(find.text('Start the check'));
    await tester.pumpAndSettle();
    // 9 health questions before self_harm — tap the first (benign) option.
    final before = kHealthQuestions.length - 1; // self_harm is last
    for (var i = 0; i < before; i++) {
      await tester.tap(find.byType(SelectableOption).first);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('self_harm answer above "Not at all" shows the crisis screen',
      (tester) async {
    await driveToSelfHarm(tester);
    expect(find.text(_selfHarmPrompt), findsOneWidget);

    // "Several days" (index 1) → crisis.
    await tester.tap(find.byType(SelectableOption).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Pause the questionnaire — this matters more.'),
        findsOneWidget);
    expect(find.textContaining('Tele-MANAS'), findsOneWidget);
  });

  testWidgets('"Not at all" on self_harm does NOT show the crisis screen',
      (tester) async {
    await driveToSelfHarm(tester);
    expect(find.text(_selfHarmPrompt), findsOneWidget);

    // "Not at all" (index 0) → advances, no crisis.
    await tester.tap(find.byType(SelectableOption).first);
    await tester.pumpAndSettle();

    expect(find.text('Pause the questionnaire — this matters more.'),
        findsNothing);
    expect(find.text(_selfHarmPrompt), findsNothing);
  });
}
