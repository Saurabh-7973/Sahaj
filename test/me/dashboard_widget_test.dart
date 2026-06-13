import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/data/progress_store.dart';
import 'package:sahaj/data/session_log_store.dart';
import 'package:sahaj/features/me/me_dashboard.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';

Widget _app(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: SingleChildScrollView(child: ProgressDashboard())),
      ),
    );

OnboardingController _onboarding() => OnboardingController()
  ..setPersona(Persona.singleInexperienced)
  ..setBaselineAnswer('arousal_control', 1)
  ..setBaselineAnswer('rehearsal_comfort', 1)
  ..setBaselineAnswer('future_anxiety', 1)
  ..finish();

void main() {
  testWidgets('spine + honesty footer render even before the first session',
      (tester) async {
    await tester.pumpWidget(_app([
      progressControllerProvider.overrideWith((ref) => ProgressController()),
      onboardingControllerProvider.overrideWith((ref) => _onboarding()),
    ]));
    await tester.pumpAndSettle();
    // Honesty footer ships on every state.
    expect(find.textContaining('We never estimate'), findsOneWidget);
    // Check-ins card is always present (the wk-0 promise).
    expect(find.text('Check-ins'), findsOneWidget);
    // No stat tiles before the first session (cards earn existence).
    expect(find.text('SESSIONS'), findsNothing);
  });

  group('with Hive store', () {
    late Directory tempDir;
    late ProgressController controller;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sahaj_dash_test');
      Hive.init(tempDir.path);
      controller = ProgressController(
        await ProgressStore.open(),
        await SessionLogStore.open(),
      )..completeToday(SessionLog(
          id: 's1',
          sessionTag: 'anatomy',
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
          completionPct: 1.0,
          moodBefore: const ['calm'],
        ));
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    testWidgets('shows stat tiles after a logged session', (tester) async {
      await tester.pumpWidget(_app([
        progressControllerProvider.overrideWith((ref) => controller),
        onboardingControllerProvider.overrideWith((ref) => _onboarding()),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('SESSIONS'), findsOneWidget);
      expect(find.text('STEADY DAYS'), findsOneWidget);
      expect(find.text('Consistency'), findsOneWidget);
    });

    testWidgets('hides the steady-days stat when hideStreak is on',
        (tester) async {
      await tester.pumpWidget(_app([
        progressControllerProvider.overrideWith((ref) => controller),
        onboardingControllerProvider.overrideWith((ref) => _onboarding()),
        preferencesControllerProvider.overrideWith(
            (ref) => PreferencesController()..setHideStreak(true)),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('SESSIONS'), findsOneWidget);
      expect(find.text('STEADY DAYS'), findsNothing);
    });
  });
}
