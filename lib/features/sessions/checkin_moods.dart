/// A check-in mood option (key persisted, label shown).
class CheckinMood {
  const CheckinMood(this.key, this.label);
  final String key;
  final String label;
}

/// Fixed pre-session mood list (multi-select 1-3).
const kCheckinMoods = <CheckinMood>[
  CheckinMood('anxious', 'Anxious'),
  CheckinMood('hopeful', 'Hopeful'),
  CheckinMood('restless', 'Restless'),
  CheckinMood('disappointed', 'Disappointed'),
  CheckinMood('calm', 'Calm'),
  CheckinMood('distracted', 'Distracted'),
  CheckinMood('motivated', 'Motivated'),
  CheckinMood('low', 'Low'),
];
