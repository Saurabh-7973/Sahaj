import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/me/checkin_controller.dart';
import 'package:sahaj/features/me/pages/checkin_flow.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/widgets/selectable_option.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';

OnboardingController _onboarding() => OnboardingController()
  ..setPersona(Persona.singleInexperienced)
  ..setBaselineAnswer('arousal_control', 1)
  ..setBaselineAnswer('rehearsal_comfort', 1)
  ..setBaselineAnswer('future_anxiety', 1)
  ..finish();

Future<void> _pump(WidgetTester tester, CheckinController checkins) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingControllerProvider.overrideWith((ref) => _onboarding()),
        checkinControllerProvider.overrideWith((ref) => checkins),
        progressControllerProvider.overrideWith((ref) => ProgressController()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const CheckinFlow(week: 4),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('intro → answer all → result records the check-in',
      (tester) async {
    final checkins = CheckinController();
    await _pump(tester, checkins);

    // Intro.
    expect(find.text('Same questions as week 0.'), findsOneWidget);
    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();

    // Answer the solo battery (3 questions). Pick the first option each time.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(SelectableOption).first);
      await tester.pumpAndSettle();
    }

    // Result screen.
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('What you put in'), findsOneWidget);
    expect(checkins.records.length, 1);
    expect(checkins.records.first.week, 4);
  });

  testWidgets('Tomorrow defers — pending week set, no record', (tester) async {
    final checkins = CheckinController();
    await _pump(tester, checkins);

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();

    expect(checkins.pendingWeek, 4);
    expect(checkins.records, isEmpty);
  });
}
