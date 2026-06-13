import 'package:hive_ce_flutter/hive_flutter.dart';

/// Check-in records (week 4/8/12 instrument scores) + the pending-check-in
/// marker. Local only, like everything else.
class CheckinStore {
  CheckinStore(this._box);

  static const _boxName = 'checkins';
  static const _recordsKey = 'records';
  static const _pendingKey = 'pendingWeek';

  final Box _box;

  static Future<CheckinStore> open() async {
    final box = await Hive.openBox(_boxName);
    return CheckinStore(box);
  }

  List<Map<String, dynamic>> records() {
    final raw = _box.get(_recordsKey);
    if (raw == null) return [];
    return (raw as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> append(Map<String, dynamic> json) async {
    final all = records()..add(json);
    await _box.put(_recordsKey, all);
  }

  int? pendingWeek() => _box.get(_pendingKey) as int?;

  Future<void> setPendingWeek(int? week) => week == null
      ? _box.delete(_pendingKey)
      : _box.put(_pendingKey, week);

  Future<void> clear() async {
    await _box.delete(_recordsKey);
    await _box.delete(_pendingKey);
  }
}
