import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/preferences_store.dart';

/// In-app disguise label (drives the native icon/name swap, deferred).
enum DisguiseName { none, calendar, notes, wellness }

DisguiseName _disguiseByName(String? name) {
  for (final d in DisguiseName.values) {
    if (d.name == name) return d;
  }
  return DisguiseName.none;
}

/// Holds + persists privacy/disguise/notification preferences.
class PreferencesController extends ChangeNotifier {
  PreferencesController([this._store]);

  final PreferencesStore? _store;

  bool bookMode = false;
  DisguiseName disguiseName = DisguiseName.none;
  bool notificationsEnabled = false;

  /// Hide the streak counter from the progress dashboard (agency over shame —
  /// synthesis section 8: streak must never become a pressure lever).
  bool hideStreak = false;

  /// Daily reminder time. Default 20:00 (calm evening nudge); user-adjustable.
  int reminderHour = 20;
  int reminderMinute = 0;

  /// Haptic cue language in the player — on by default (the discretion
  /// feature: sessions followable face-down, silent, lights off).
  bool hapticsEnabled = true;

  /// Voice guidance toggle state — asked once on the first audio session,
  /// then remembered (shared-wall reality; spec Part K flag 5).
  bool voiceEnabled = true;

  /// One-time coach marks.
  bool faceDownCoachSeen = false;
  bool earphonePromptSeen = false;

  void setBookMode(bool v) {
    bookMode = v;
    _persist();
  }

  void setDisguiseName(DisguiseName v) {
    disguiseName = v;
    _persist();
  }

  void setNotificationsEnabled(bool v) {
    notificationsEnabled = v;
    _persist();
  }

  void setHideStreak(bool v) {
    hideStreak = v;
    _persist();
  }

  void setReminderTime(int hour, int minute) {
    reminderHour = hour;
    reminderMinute = minute;
    _persist();
  }

  void setHapticsEnabled(bool v) {
    hapticsEnabled = v;
    _persist();
  }

  void setVoiceEnabled(bool v) {
    voiceEnabled = v;
    _persist();
  }

  void markFaceDownCoachSeen() {
    faceDownCoachSeen = true;
    _persist();
  }

  void markEarphonePromptSeen() {
    earphonePromptSeen = true;
    _persist();
  }

  void reset() {
    bookMode = false;
    disguiseName = DisguiseName.none;
    notificationsEnabled = false;
    hideStreak = false;
    reminderHour = 20;
    reminderMinute = 0;
    hapticsEnabled = true;
    voiceEnabled = true;
    faceDownCoachSeen = false;
    earphonePromptSeen = false;
    _store?.clear();
    notifyListeners();
  }

  void _persist() {
    _store?.save(toJson());
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'bookMode': bookMode,
        'disguiseName': disguiseName.name,
        'notificationsEnabled': notificationsEnabled,
        'hideStreak': hideStreak,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'hapticsEnabled': hapticsEnabled,
        'voiceEnabled': voiceEnabled,
        'faceDownCoachSeen': faceDownCoachSeen,
        'earphonePromptSeen': earphonePromptSeen,
      };

  void loadFrom(Map<String, dynamic> json) {
    bookMode = (json['bookMode'] as bool?) ?? false;
    disguiseName = _disguiseByName(json['disguiseName'] as String?);
    notificationsEnabled = (json['notificationsEnabled'] as bool?) ?? false;
    hideStreak = (json['hideStreak'] as bool?) ?? false;
    reminderHour = (json['reminderHour'] as int?) ?? 20;
    reminderMinute = (json['reminderMinute'] as int?) ?? 0;
    hapticsEnabled = (json['hapticsEnabled'] as bool?) ?? true;
    voiceEnabled = (json['voiceEnabled'] as bool?) ?? true;
    faceDownCoachSeen = (json['faceDownCoachSeen'] as bool?) ?? false;
    earphonePromptSeen = (json['earphonePromptSeen'] as bool?) ?? false;
    notifyListeners();
  }
}

/// Overridden in main() with the persisted controller.
final preferencesControllerProvider =
    ChangeNotifierProvider<PreferencesController>(
  (ref) => PreferencesController(),
);
