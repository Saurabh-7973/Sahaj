import 'models/onboarding_models.dart';

/// Conservative red-flag evaluation over health-screen answers.
/// Heuristic and pre-clinician-review (synthesis §10). When unsure, fire.
/// Answer ints are option indices from `kHealthQuestions`.
TriageResult evaluate(Map<String, int> a) {
  final flags = <TriageFlag>[];
  void flag(TriageCategory c, String reason) => flags.add(TriageFlag(c, reason));

  // organicErectile: no morning erections (index 2 = "No, rarely or never").
  if (a['morning_erections'] == 2) {
    flag(TriageCategory.organicErectile, 'No morning erections');
  }
  // neuro / organic: frequent pelvic pain (index 2 = "Yes, often").
  if ((a['pelvic_pain'] ?? 0) >= 2) {
    flag(TriageCategory.neuro, 'Frequent pelvic pain or numbness');
  }
  // metabolic: unexplained weight loss (index 1 = "Yes").
  if (a['weight_loss'] == 1) {
    flag(TriageCategory.metabolic, 'Unexplained weight loss');
  }
  // metabolic: thirst/urination (index 2 = "Yes, often").
  if ((a['thirst_urination'] ?? 0) >= 2) {
    flag(TriageCategory.metabolic, 'Persistent thirst or frequent urination');
  }
  // cardiac: chest pain/breathlessness — conservative, fire at "Sometimes" (>=1).
  if ((a['chest_breath'] ?? 0) >= 1) {
    flag(TriageCategory.cardiac, 'Chest pain or breathlessness on exertion');
  }
  // neuro/metabolic: tremors or high heart rate (index 2 = "Yes").
  if ((a['tremors_heart'] ?? 0) >= 2) {
    flag(TriageCategory.neuro, 'Tremors or a persistently high heart rate');
  }
  // mentalHealth: daily low mood or anxiety (index 3 = "Nearly every day").
  if ((a['mood_down'] ?? 0) >= 3 || (a['mood_anxious'] ?? 0) >= 3) {
    flag(TriageCategory.mentalHealth, 'Frequent low mood or anxiety');
  }
  // mentalHealth: any self-harm thought (> "Not at all").
  if ((a['self_harm'] ?? 0) >= 1) {
    flag(TriageCategory.mentalHealth, 'Thoughts of self-harm');
  }
  return TriageResult(flags);
}
