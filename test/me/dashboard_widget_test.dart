import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sahaj/data/progress_store.dart';
import 'package:sahaj/data/session_log_store.dart';
import 'package:sahaj/features/me/me_dashboard.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';

void main() {
  testWidgets('shows empty state with no sessions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressControllerProvider.overrideWith((ref) => ProgressController()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProgressDashboard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('appears here after your first session'),
        findsOneWidget);
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

    testWidgets('shows metrics after a logged session', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProgressDashboard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('sessions completed'), findsOneWidget);
    });
  });
}
