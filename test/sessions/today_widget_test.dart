import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sahaj/data/progress_store.dart';
import 'package:sahaj/data/session_log_store.dart';
import 'package:sahaj/features/home/tabs/today_page.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';

void main() {
  testWidgets('Today shows the session card from plan + catalog', (tester) async {
    final controller = OnboardingController()
      ..setPersona(Persona.singleInexperienced)
      ..finish(); // builds a solo plan; week 1 tags include 'anatomy'

    final catalog = SessionCatalog({
      'anatomy': const SessionDef(
        tag: 'anatomy',
        title: 'Know the ground',
        type: SessionType.education,
        steps: [SessionStep(title: 's', seconds: 60, guidance: 'g')],
      ),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider.overrideWith((ref) => controller),
          sessionCatalogProvider.overrideWithValue(catalog),
        ],
        child: const MaterialApp(home: TodayPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Know the ground'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    // No logs ever → day 0: the ok-chip's only appearance on Today, and the
    // steady tile doesn't exist yet.
    expect(find.text('first session'), findsOneWidget);
    expect(find.text('Steady days'), findsNothing);
  });

  group('streak header respects hideStreak', () {
    late Directory tempDir;
    late ProgressController progress;
    late OnboardingController onboarding;
    late SessionCatalog catalog;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sahaj_today_test');
      Hive.init(tempDir.path);
      progress = ProgressController(
        await ProgressStore.open(),
        await SessionLogStore.open(),
      )..completeToday(SessionLog(
          id: 's1',
          sessionTag: 'anatomy',
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
          completionPct: 1.0,
          moodBefore: const ['calm'],
        )); // streak -> 1
      await Future<void>.delayed(Duration.zero);

      onboarding = OnboardingController()
        ..setPersona(Persona.singleInexperienced)
        ..finish();
      catalog = SessionCatalog({
        'anatomy': const SessionDef(
          tag: 'anatomy',
          title: 'Know the ground',
          type: SessionType.education,
          steps: [SessionStep(title: 's', seconds: 60, guidance: 'g')],
        ),
      });
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    Future<void> pump(WidgetTester tester, {required bool hide}) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingControllerProvider.overrideWith((ref) => onboarding),
            progressControllerProvider.overrideWith((ref) => progress),
            sessionCatalogProvider.overrideWithValue(catalog),
            preferencesControllerProvider.overrideWith(
                (ref) => PreferencesController()..setHideStreak(hide)),
          ],
          child: const MaterialApp(home: TodayPage()),
        ),
      );
    }

    testWidgets('shows the steady tile when not hidden', (tester) async {
      await pump(tester, hide: false);
      await tester.pumpAndSettle();
      // Completed today → done state + the steady tile.
      expect(find.text('Done for today'), findsOneWidget);
      expect(find.text('Steady days'), findsOneWidget);
    });

    testWidgets('hides the steady tile when hideStreak is on', (tester) async {
      await pump(tester, hide: true);
      await tester.pumpAndSettle();
      // Absent — no gap, no placeholder, no "hidden" label.
      expect(find.text('Steady days'), findsNothing);
      expect(find.text('Done for today'), findsOneWidget);
    });
  });
}
