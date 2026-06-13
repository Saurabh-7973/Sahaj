// Renders the four M2 Today states at 390×844@3x with real fonts and writes
// PNGs into docs/ui_review/. Review artifacts, not goldens.
//
//   flutter test test/ui_review/m2_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/home/tabs/today_page.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';
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

SessionLog _log(DateTime day) => SessionLog(
      id: day.toString(),
      sessionTag: 't',
      startedAt: day,
      completedAt: day,
      completionPct: 1,
      moodBefore: const [],
    );

SessionDef _kegel(String tag, String title, {int minutes = 8}) => SessionDef(
      tag: tag,
      title: title,
      type: SessionType.kegel,
      steps: [
        SessionStep(
          title: 'Holds',
          seconds: minutes * 60,
          guidance: 'g',
          pattern: const HoldReleasePattern(holdSeconds: 4, releaseSeconds: 4),
        ),
      ],
    );

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
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

Future<void> _pumpToday(
  WidgetTester tester, {
  required ProgressState progress,
  required List<SessionLog> logs,
  required Map<String, SessionDef> catalog,
  bool hideStreak = false,
  bool pro = false,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final onboarding = OnboardingController()
    ..setPersona(Persona.singleInexperienced)
    ..finish();
  final subscription =
      SubscriptionController(const NoopSubscriptionRepository())..isPro = pro;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingControllerProvider.overrideWith((ref) => onboarding),
        progressControllerProvider
            .overrideWith((ref) => _FakeProgress(progress, logs)),
        sessionCatalogProvider.overrideWithValue(SessionCatalog(catalog)),
        subscriptionControllerProvider.overrideWith((ref) => subscription),
        preferencesControllerProvider.overrideWith(
          (ref) => PreferencesController()..hideStreak = hideStreak,
        ),
      ],
      child: RepaintBoundary(
        key: _boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const TodayPage(),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = _boundaryKey.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;
  late final ByteData bytes;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
    bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  });
  File('$_outDir/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $_outDir/$name.png');
}

String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  setUpAll(_loadFonts);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(Duration(days: now.weekday - 1));
  final yesterday = today.subtract(const Duration(days: 1));

  testWidgets('m2_01 default + hidden-streak variant', (tester) async {
    final logs = [
      for (var d = monday;
          d.isBefore(today);
          d = d.add(const Duration(days: 1)))
        _log(d.add(const Duration(hours: 21))),
    ];
    await _pumpToday(
      tester,
      progress: ProgressState(
        currentWeek: 3,
        currentDay: 4,
        streak: 6,
        longestStreak: 9,
        lastCompletedDate: _key(yesterday),
      ),
      logs: logs.isEmpty ? [_log(yesterday)] : logs,
      catalog: {'pfmt_identify': _kegel('pfmt_identify', 'Long holds, easy breath')},
    );
    await _capture(tester, 'm2_01a_today_default');

    await _pumpToday(
      tester,
      progress: ProgressState(
        currentWeek: 3,
        currentDay: 4,
        streak: 6,
        longestStreak: 9,
        lastCompletedDate: _key(yesterday),
      ),
      logs: logs.isEmpty ? [_log(yesterday)] : logs,
      catalog: {'pfmt_identify': _kegel('pfmt_identify', 'Long holds, easy breath')},
      hideStreak: true,
    );
    await _capture(tester, 'm2_01b_today_streak_hidden');
  });

  testWidgets('m2_02 done', (tester) async {
    await _pumpToday(
      tester,
      progress: ProgressState(
        currentWeek: 3,
        currentDay: 5,
        streak: 7,
        longestStreak: 9,
        lastCompletedDate: _key(today),
      ),
      logs: [
        for (var d = monday;
            !d.isAfter(today);
            d = d.add(const Duration(days: 1)))
          _log(d.add(const Duration(hours: 21))),
      ],
      catalog: {
        'pfmt_identify': _kegel('pfmt_identify', 'Stop-start', minutes: 9),
      },
    );
    await _capture(tester, 'm2_02_today_done');
  });

  testWidgets('m2_03 day 0', (tester) async {
    await _pumpToday(
      tester,
      progress: const ProgressState(),
      logs: const [],
      catalog: {
        'breathwork_basics': const SessionDef(
          tag: 'breathwork_basics',
          title: 'Breathe, and find the muscle',
          type: SessionType.breathwork,
          steps: [
            SessionStep(title: 'Breath', seconds: 420, guidance: 'g'),
          ],
        ),
      },
    );
    await _capture(tester, 'm2_03_today_day0');
  });

  testWidgets('m2_04 gap return', (tester) async {
    final fourDaysAgo = today.subtract(const Duration(days: 4));
    await _pumpToday(
      tester,
      progress: ProgressState(
        currentWeek: 5,
        currentDay: 1,
        streak: 4,
        longestStreak: 9,
        lastCompletedDate: _key(fourDaysAgo),
      ),
      logs: [_log(fourDaysAgo.add(const Duration(hours: 21)))],
      catalog: {
        'kegel_reverse_combined':
            _kegel('kegel_reverse_combined', 'Easy holds, long exhale', minutes: 7),
      },
      pro: true, // week 5 is a Pro week; the lock is M7's screen, not this one
    );
    await _capture(tester, 'm2_04_today_gap_return');
  });
}
