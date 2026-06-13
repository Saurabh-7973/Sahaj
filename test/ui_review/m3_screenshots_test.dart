// Renders the M3 dashboard states + check-in screens at 390×844@3x with real
// fonts → docs/ui_review/. Review artifacts, not goldens.
//
//   flutter test test/ui_review/m3_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/home/tabs/me_page.dart';
import 'package:sahaj/features/me/checkin_controller.dart';
import 'package:sahaj/features/me/pages/checkin_flow.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/widgets/selectable_option.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';
import 'package:sahaj/features/subscription/subscription_controller.dart';
import 'package:sahaj/features/subscription/subscription_repository.dart';

const _outDir = 'docs/ui_review';
final _boundaryKey = GlobalKey();

class _FakeProgress extends ProgressController {
  _FakeProgress(ProgressState s, this._logs) {
    state = s;
  }
  final List<SessionLog> _logs;
  @override
  List<SessionLog> logs() => _logs;
}

SessionLog _log(DateTime d, {int minutes = 8, int holdSeconds = 40}) =>
    SessionLog(
      id: d.toString(),
      sessionTag: 't',
      startedAt: d,
      completedAt: d.add(Duration(minutes: minutes)),
      completionPct: 1,
      moodBefore: const [],
      holdSeconds: holdSeconds,
    );

OnboardingController _onboarding() => OnboardingController()
  ..setPersona(Persona.singleInexperienced)
  ..setBaselineAnswer('arousal_control', 1)
  ..setBaselineAnswer('rehearsal_comfort', 1)
  ..setBaselineAnswer('future_anxiety', 2)
  ..finish();

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

Future<void> _pump(WidgetTester tester, Widget home, List<Override> overrides) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: home,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
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

List<SessionLog> _weeksOfLogs(DateTime now, int weeks) {
  final logs = <SessionLog>[];
  for (var w = 0; w < weeks; w++) {
    for (var d = 0; d < 5; d++) {
      logs.add(_log(now.subtract(Duration(days: 7 * w + d, hours: 2))));
    }
  }
  return logs;
}

List<Override> _meOverrides({
  required ProgressState progress,
  required List<SessionLog> logs,
  required CheckinController checkins,
}) =>
    [
      onboardingControllerProvider.overrideWith((ref) => _onboarding()),
      progressControllerProvider
          .overrideWith((ref) => _FakeProgress(progress, logs)),
      checkinControllerProvider.overrideWith((ref) => checkins),
      subscriptionControllerProvider.overrideWith(
        (ref) => SubscriptionController(const NoopSubscriptionRepository()),
      ),
    ];

void main() {
  setUpAll(_loadFonts);
  final now = DateTime(2026, 6, 11, 21);

  testWidgets('m3_03 dashboard week 1', (tester) async {
    await _pump(
      tester,
      const MePage(),
      _meOverrides(
        progress: const ProgressState(
            currentWeek: 1, currentDay: 2, streak: 2, longestStreak: 2),
        logs: [
          _log(now.subtract(const Duration(days: 1))),
          _log(now),
        ],
        checkins: CheckinController(),
      ),
    );
    await _capture(tester, 'm3_03_dashboard_wk1');
  });

  testWidgets('m3_01 dashboard week 3', (tester) async {
    await _pump(
      tester,
      const MePage(),
      _meOverrides(
        progress: const ProgressState(
            currentWeek: 3, currentDay: 4, streak: 6, longestStreak: 9),
        logs: _weeksOfLogs(now, 3),
        checkins: CheckinController(),
      ),
    );
    await _capture(tester, 'm3_01_dashboard_wk3');
  });

  testWidgets('m3_02 dashboard week 5 (post check-in)', (tester) async {
    final checkins = CheckinController()
      ..complete(CheckinRecord(
        week: 4,
        scores: const {
          'arousal_control': 3,
          'rehearsal_comfort': 2,
          'future_anxiety': 2,
        },
        completedAt: now,
      ));
    await _pump(
      tester,
      const MePage(),
      _meOverrides(
        progress: const ProgressState(
            currentWeek: 5, currentDay: 2, streak: 4, longestStreak: 11),
        logs: _weeksOfLogs(now, 4),
        checkins: checkins,
      ),
    );
    await _capture(tester, 'm3_02_dashboard_wk5');
  });

  testWidgets('m3_04 check-in intro + result', (tester) async {
    await _pump(
      tester,
      const CheckinFlow(week: 4),
      [
        onboardingControllerProvider.overrideWith((ref) => _onboarding()),
        checkinControllerProvider.overrideWith((ref) => CheckinController()),
        progressControllerProvider.overrideWith(
          (ref) => _FakeProgress(
            const ProgressState(currentWeek: 4, currentDay: 7),
            _weeksOfLogs(now, 4),
          ),
        ),
      ],
    );
    await _capture(tester, 'm3_04a_checkin_intro');

    // Walk to the result by answering each question.
    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(SelectableOption).at(1));
      await tester.pumpAndSettle();
    }
    await tester.pump(const Duration(milliseconds: 500));
    await _capture(tester, 'm3_04b_checkin_result');
  });
}
