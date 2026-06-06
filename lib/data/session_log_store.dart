import 'package:hive_ce_flutter/hive_flutter.dart';

/// Append-only store of session logs (JSON maps under one list key).
class SessionLogStore {
  SessionLogStore(this._box);

  static const _boxName = 'session_logs';
  static const _key = 'logs';

  final Box _box;

  static Future<SessionLogStore> open() async {
    final box = await Hive.openBox(_boxName);
    return SessionLogStore(box);
  }

  List<Map<String, dynamic>> all() {
    final raw = _box.get(_key);
    if (raw == null) return [];
    return (raw as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> append(Map<String, dynamic> json) async {
    final logs = all()..add(json);
    await _box.put(_key, logs);
  }

  Future<void> clear() => _box.delete(_key);
}
