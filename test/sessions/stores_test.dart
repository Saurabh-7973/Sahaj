import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sahaj/data/progress_store.dart';
import 'package:sahaj/data/session_log_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sahaj_hive_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('ProgressStore saves and loads a state map', () async {
    final store = await ProgressStore.open();
    expect(store.load(), isNull);
    await store.save({'currentWeek': 2, 'currentDay': 3, 'streak': 4});
    expect(store.load(), {'currentWeek': 2, 'currentDay': 3, 'streak': 4});
    await store.clear();
    expect(store.load(), isNull);
  });

  test('SessionLogStore appends logs in order', () async {
    final store = await SessionLogStore.open();
    expect(store.all(), isEmpty);
    await store.append({'id': 'a', 'sessionTag': 'anatomy'});
    await store.append({'id': 'b', 'sessionTag': 'stop_start'});
    final all = store.all();
    expect(all.length, 2);
    expect(all.first['id'], 'a');
    expect(all.last['id'], 'b');
  });
}
