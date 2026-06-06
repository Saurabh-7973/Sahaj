import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sahaj/data/progress_store.dart';
import 'package:sahaj/data/session_log_store.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';

SessionLog _log() => SessionLog(
      id: 'log-1',
      sessionTag: 'anatomy',
      startedAt: DateTime(2026, 6, 6, 8),
      completedAt: DateTime(2026, 6, 6, 8, 7),
      completionPct: 1.0,
      moodBefore: const ['calm', 'hopeful'],
      perceivedDifficulty: PerceivedDifficulty.same,
      journalNote: 'steady',
    );

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sahaj_completion_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('completeToday writes a SessionLog to the store and advances progress',
      () async {
    final progressStore = await ProgressStore.open();
    final logStore = await SessionLogStore.open();
    final c = ProgressController(progressStore, logStore);

    expect(logStore.all(), isEmpty);
    expect(c.state.currentDay, 1);

    c.completeToday(_log());
    // completeToday fires async store writes; let them flush.
    await Future<void>.delayed(Duration.zero);

    // Progress advanced + marked done today.
    expect(c.state.currentDay, 2);
    expect(c.isDoneToday, isTrue);

    // The log was actually persisted.
    final logs = logStore.all();
    expect(logs.length, 1);
    expect(logs.single['id'], 'log-1');
    expect(logs.single['sessionTag'], 'anatomy');
    expect(logs.single['moodBefore'], ['calm', 'hopeful']);

    // Progress state was persisted too.
    final saved = progressStore.load();
    expect(saved, isNotNull);
    expect((saved!['currentDay'] as num).toInt(), 2);
  });
}
