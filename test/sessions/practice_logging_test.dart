import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sahaj/data/progress_store.dart';
import 'package:sahaj/data/session_log_store.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';

SessionLog _log(String id) => SessionLog(
      id: id,
      sessionTag: 'anatomy',
      startedAt: DateTime(2026, 6, 6, 8),
      completedAt: DateTime(2026, 6, 6, 8, 7),
      completionPct: 1.0,
      moodBefore: const ['calm'],
    );

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sahaj_practice_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('logs() decodes stored logs', () async {
    final c = ProgressController(
      await ProgressStore.open(),
      await SessionLogStore.open(),
    );
    expect(c.logs(), isEmpty);
    c.completeToday(_log('a'));
    await Future<void>.delayed(Duration.zero);
    final logs = c.logs();
    expect(logs.length, 1);
    expect(logs.single.id, 'a');
  });

  test('logPractice appends a log WITHOUT advancing the plan day', () async {
    final c = ProgressController(
      await ProgressStore.open(),
      await SessionLogStore.open(),
    );
    final dayBefore = c.state.currentDay;
    c.logPractice(_log('p'));
    await Future<void>.delayed(Duration.zero);
    expect(c.state.currentDay, dayBefore);
    expect(c.isDoneToday, isFalse);
    expect(c.logs().length, 1);
  });
}
