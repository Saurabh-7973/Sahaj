// +30% string room: M3 dashboard + check-in screens at 1.3 text scale,
// no overflow.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/home/tabs/me_page.dart';
import 'package:sahaj/features/me/checkin_controller.dart';
import 'package:sahaj/features/me/pages/checkin_flow.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';
import 'package:sahaj/features/subscription/subscription_controller.dart';
import 'package:sahaj/features/subscription/subscription_repository.dart';

class _FakeProgress extends ProgressController {
  _FakeProgress(ProgressState s, this._logs) {
    state = s;
  }
  final List<SessionLog> _logs;
  @override
  List<SessionLog> logs() => _logs;
}

SessionLog _log(DateTime d) => SessionLog(
      id: d.toString(),
      sessionTag: 't',
      startedAt: d,
      completedAt: d.add(const Duration(minutes: 8)),
      completionPct: 1,
      moodBefore: const [],
      holdSeconds: 40,
    );

OnboardingController _onboarding() => OnboardingController()
  ..setPersona(Persona.singleInexperienced)
  ..setBaselineAnswer('arousal_control', 1)
  ..setBaselineAnswer('rehearsal_comfort', 1)
  ..setBaselineAnswer('future_anxiety', 1)
  ..finish();

Future<void> _pump(WidgetTester tester, Widget home, List<Override> o) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: o,
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
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  final now = DateTime(2026, 6, 11, 21);
  final logs = [for (var d = 0; d < 12; d++) _log(now.subtract(Duration(days: d)))];

  testWidgets('dashboard with comparison at 1.3 scale', (tester) async {
    final checkins = CheckinController()
      ..complete(CheckinRecord(
        week: 4,
        scores: const {
          'arousal_control': 3,
          'rehearsal_comfort': 2,
          'future_anxiety': 1,
        },
        completedAt: now,
      ));
    await _pump(tester, const MePage(), [
      onboardingControllerProvider.overrideWith((ref) => _onboarding()),
      progressControllerProvider.overrideWith(
        (ref) => _FakeProgress(
          const ProgressState(currentWeek: 5, currentDay: 2, streak: 4, longestStreak: 11),
          logs,
        ),
      ),
      checkinControllerProvider.overrideWith((ref) => checkins),
      subscriptionControllerProvider.overrideWith(
        (ref) => SubscriptionController(const NoopSubscriptionRepository()),
      ),
    ]);
    expect(tester.takeException(), isNull);
    expect(find.text('Check-ins'), findsOneWidget);
  });

  testWidgets('check-in intro at 1.3 scale', (tester) async {
    await _pump(tester, const CheckinFlow(week: 4), [
      onboardingControllerProvider.overrideWith((ref) => _onboarding()),
      checkinControllerProvider.overrideWith((ref) => CheckinController()),
      progressControllerProvider.overrideWith((ref) => ProgressController()),
    ]);
    expect(tester.takeException(), isNull);
    expect(find.text('Same questions as week 0.'), findsOneWidget);
  });
}
