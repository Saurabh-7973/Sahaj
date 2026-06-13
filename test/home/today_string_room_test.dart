// +30% string room: Today's states at 1.3 text scale, no overflow, and
// Start stays above the fold (M2 acceptance criteria).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/home/tabs/today_page.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';

class _FakeProgress extends ProgressController {
  _FakeProgress(ProgressState s, this._logs) {
    state = s;
  }

  final List<SessionLog> _logs;

  @override
  List<SessionLog> logs() => _logs;
}

SessionLog _log(DateTime day) => SessionLog(
      id: day.toString(),
      sessionTag: 't',
      startedAt: day,
      completedAt: day,
      completionPct: 1,
      moodBefore: const [],
    );

Future<void> _pump(
  WidgetTester tester, {
  required ProgressState progress,
  required List<SessionLog> logs,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final onboarding = OnboardingController()
    ..setPersona(Persona.singleInexperienced)
    ..finish();
  final catalog = SessionCatalog({
    'pfmt_identify': const SessionDef(
      tag: 'pfmt_identify',
      title: 'Long holds, easy breath',
      type: SessionType.kegel,
      steps: [
        SessionStep(
          title: 'Holds',
          seconds: 480,
          guidance: 'g',
          pattern: HoldReleasePattern(holdSeconds: 4, releaseSeconds: 4),
        ),
      ],
    ),
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingControllerProvider.overrideWith((ref) => onboarding),
        progressControllerProvider
            .overrideWith((ref) => _FakeProgress(progress, logs)),
        sessionCatalogProvider.overrideWithValue(catalog),
        preferencesControllerProvider
            .overrideWith((ref) => PreferencesController()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: const TodayPage(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  String key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  testWidgets('default state: no overflow, Start above the fold',
      (tester) async {
    final yesterday = today.subtract(const Duration(days: 1));
    await _pump(
      tester,
      progress: ProgressState(
        currentWeek: 3,
        currentDay: 4,
        streak: 6,
        longestStreak: 9,
        lastCompletedDate: key(yesterday),
      ),
      logs: [_log(yesterday.add(const Duration(hours: 21)))],
    );
    expect(tester.takeException(), isNull);

    // Start above the fold even at +30%.
    final start = tester.getBottomLeft(find.text('Start'));
    expect(start.dy, lessThan(844));
  });

  testWidgets('gap return at 1.3 scale: no overflow', (tester) async {
    final old = today.subtract(const Duration(days: 10));
    await _pump(
      tester,
      progress: ProgressState(
        currentWeek: 3,
        currentDay: 4,
        streak: 4,
        longestStreak: 9,
        lastCompletedDate: key(old),
      ),
      logs: [_log(old)],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('adjusted'), findsOneWidget);
  });

  testWidgets('day 0 at 1.3 scale: no overflow, no steady tile',
      (tester) async {
    await _pump(tester, progress: const ProgressState(), logs: const []);
    expect(tester.takeException(), isNull);
    expect(find.text('Steady days'), findsNothing);
  });
}
