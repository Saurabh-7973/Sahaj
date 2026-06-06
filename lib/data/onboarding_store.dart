import 'package:hive_ce_flutter/hive_flutter.dart';

/// Persists onboarding state as a single JSON map (no TypeAdapter codegen).
class OnboardingStore {
  OnboardingStore(this._box);

  static const _boxName = 'onboarding';
  static const _key = 'state';

  final Box _box;

  static Future<OnboardingStore> open() async {
    final box = await Hive.openBox(_boxName);
    return OnboardingStore(box);
  }

  Map<String, dynamic>? load() {
    final raw = _box.get(_key);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> save(Map<String, dynamic> json) => _box.put(_key, json);

  Future<void> clear() => _box.delete(_key);
}
