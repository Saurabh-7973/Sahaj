// +30% string room (Part A3): every M1 screen must survive a 1.3 text scale
// without overflow errors — Hindi runs longer than English.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/theme/app_theme.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/pages/completion_page.dart';
import 'package:sahaj/features/sessions/pages/face_down_coach.dart';
import 'package:sahaj/features/sessions/pages/mood_checkin_sheet.dart';
import 'package:sahaj/features/sessions/pages/reflection_page.dart';
import 'package:sahaj/features/sessions/pages/session_player_page.dart';

const _session = SessionDef(
  tag: 't',
  title: 'Gentle holds, long exhale',
  type: SessionType.kegel,
  steps: [
    SessionStep(
      title: 'Gentle holds',
      seconds: 120,
      guidance: 'Squeeze for 3 seconds, release for 3.',
      pattern: HoldReleasePattern(holdSeconds: 3, releaseSeconds: 3),
    ),
  ],
);

Future<void> _pumpScaled(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: home,
    ),
  );
}

void main() {
  testWidgets('player at 1.3 text scale', (tester) async {
    await _pumpScaled(
      tester,
      SessionPlayerPage(session: _session, onComplete: (_) {}),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mood sheet + echo at 1.3 text scale', (tester) async {
    await _pumpScaled(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showMoodCheckin(context, session: _session),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Heavy'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('session').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('coach, reflection, completion at 1.3 text scale',
      (tester) async {
    await _pumpScaled(tester, const FaceDownCoachPage());
    await tester.pump();
    expect(tester.takeException(), isNull);

    await _pumpScaled(
      tester,
      const ReflectionPage(sessionTitle: 'Gentle holds', sessionNumber: 14),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await _pumpScaled(
      tester,
      const CompletionPage(
        sessionNumber: 14,
        nthThisWeek: 3,
        tomorrowTitle: 'Stop-start',
        tomorrowMinutes: 9,
        milestoneWeek: 4,
        currentWeek: 4,
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));
    expect(tester.takeException(), isNull);
  });
}
