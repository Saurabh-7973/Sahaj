import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/onboarding/health_questions.dart';
import 'package:sahaj/features/onboarding/logic/safety_screening.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/onboarding_flow.dart';
import 'package:sahaj/features/onboarding/pages/safety_screens.dart';
import 'package:sahaj/features/onboarding/widgets/selectable_option.dart';

const _emergencyHeadline = 'This is worth a doctor today — not later.';
const _tensionFirstPrompt =
    'Would you describe your main issue as tension, clenching, or pain — '
    'rather than weakness?';
const _advisoryHeadline = 'A gentler starting point';

void main() {
  /// Drives Welcome → the first emergency question, tapping the first (benign)
  /// option on every health item. The first option is benign on all ten, so no
  /// red flags fire and the triage screen is skipped.
  Future<void> driveToEmergency(WidgetTester tester) async {
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
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SelectableOption).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SelectableOption).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start the check'));
    await tester.pumpAndSettle();
    // All ten health questions — first (benign) option each.
    for (var i = 0; i < kHealthQuestions.length; i++) {
      await tester.tap(find.byType(SelectableOption).first);
      await tester.pumpAndSettle();
    }
  }

  /// Continues from the first emergency question (both "No") into the tension
  /// screen, landing on its first question.
  Future<void> driveToTension(WidgetTester tester) async {
    await driveToEmergency(tester);
    for (var i = 0; i < kEmergencyQuestions.length; i++) {
      await tester.tap(find.byType(SelectableOption).first); // "No"
      await tester.pumpAndSettle();
    }
  }

  testWidgets('emergency "Yes" raises the urgent-care interrupt', (tester) async {
    await driveToEmergency(tester);
    expect(find.text(kEmergencyQuestions.first.prompt), findsOneWidget);

    await tester.tap(find.byType(SelectableOption).at(1)); // "Yes"
    await tester.pumpAndSettle();

    expect(find.text(_emergencyHeadline), findsOneWidget);
    expect(find.textContaining('112'), findsWidgets);
  });

  testWidgets('emergency "No" advances without the interrupt', (tester) async {
    await driveToEmergency(tester);
    await tester.tap(find.byType(SelectableOption).first); // "No"
    await tester.pumpAndSettle();

    expect(find.text(_emergencyHeadline), findsNothing);
  });

  testWidgets('two tension "Yes" routes to the down-training advisory',
      (tester) async {
    await driveToTension(tester);
    expect(find.text(_tensionFirstPrompt), findsOneWidget);

    // Answer "Yes" on the first two tension items, "No" on the rest → tight.
    for (var i = 0; i < kTensionQuestions.length; i++) {
      final idx = i < 2 ? 1 : 0;
      await tester.tap(find.byType(SelectableOption).at(idx));
      await tester.pumpAndSettle();
    }

    expect(find.text(_advisoryHeadline), findsOneWidget);
  });

  testWidgets('all tension "No" skips the advisory', (tester) async {
    await driveToTension(tester);
    for (var i = 0; i < kTensionQuestions.length; i++) {
      await tester.tap(find.byType(SelectableOption).first); // "No"
      await tester.pumpAndSettle();
    }
    expect(find.text(_advisoryHeadline), findsNothing);
  });

  testWidgets('disclaimer "Begin" is gated until the box is ticked',
      (tester) async {
    var accepted = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: DisclaimerScreen(onAccept: () => accepted = true, onBack: () {}),
    ));
    await tester.pumpAndSettle();

    // Begin is present but disabled — tapping does nothing.
    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();
    expect(accepted, isFalse);

    // Tick the single acknowledgement, then Begin accepts.
    await tester.tap(find.text('I understand and agree.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();
    expect(accepted, isTrue);
  });
}
