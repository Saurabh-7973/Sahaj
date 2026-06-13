import '../../shared/widgets/app_mood_selector.dart';

export '../../shared/widgets/app_mood_selector.dart'
    show ArrivalMood, ArrivalMoodLabel;

/// Persisted key for an arrival mood (`SessionLog.moodBefore` strings).
/// Logs written before the 5-mood migration may hold legacy keys
/// (anxious/hopeful/…) — readers must tolerate unknown keys.
String moodKey(ArrivalMood mood) => mood.name;

ArrivalMood? moodFromKey(String key) {
  for (final m in ArrivalMood.values) {
    if (m.name == key) return m;
  }
  return null;
}
