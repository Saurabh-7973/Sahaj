import '../health_questions.dart' show HealthQuestion;
import 'models/onboarding_models.dart';

/// The two screening packs the safety layer adds to onboarding (safety pack
/// §2 + §3 carve-out). Both reuse [HealthQuestion] / the question-screen
/// template; answers are option indices, with index 0 = "No".
///
/// Nothing here is diagnosis. The questions are plain and non-diagnostic; the
/// app only routes conservatively (urgent care, a doctor, or the safer
/// training path), it never tells the user what is wrong.

// ── Emergency carve-out (safety pack §3) ─────────────────────────────────────
//
// Asked after the health check, before the ordinary red-flag triage. Any "yes"
// routes to the urgent-care screen and takes priority over everything else.
const kEmergencyQuestions = <HealthQuestion>[
  HealthQuestion(
    id: 'em_priapism',
    prompt:
        "An erection that won't go down, or has lasted for hours and is "
        'painful?',
    options: ['No', 'Yes'],
  ),
  HealthQuestion(
    id: 'em_saddle',
    prompt:
        'New numbness in the genitals or the saddle area, or new weakness or '
        'numbness in your legs?',
    options: ['No', 'Yes'],
  ),
];

/// Maps an emergency question id to the flag it raises.
const _emergencyFlagById = <String, EmergencyFlag>{
  'em_priapism': EmergencyFlag.priapism,
  'em_saddle': EmergencyFlag.neuroSaddle,
};

/// Why-strip per emergency item (warmth around the question, never in it).
const kEmergencyWhyLines = <String, String>{
  'em_priapism':
      'A long, painful erection can be a medical emergency — the rare case '
          'we check for first.',
  'em_saddle':
      'New numbness or leg weakness can be a nerve emergency. Quick to ask, '
          'important to catch.',
};

/// Any "yes" (index ≥ 1) on the emergency questions raises its flag.
Set<EmergencyFlag> evaluateEmergency(Map<String, int> answers) {
  final flags = <EmergencyFlag>{};
  _emergencyFlagById.forEach((id, flag) {
    if ((answers[id] ?? 0) >= 1) flags.add(flag);
  });
  return flags;
}

// ── Hypertonic / tension screening (safety pack §2) ──────────────────────────
//
// Asked after the red-flag triage, before plan generation. Catches the man
// whose floor is over-tight rather than weak, for whom strengthen-first is the
// wrong start. Two or more "yes" → route to the down-training-first advisory.
const kTensionQuestions = <HealthQuestion>[
  HealthQuestion(
    id: 'tn_tension_not_weak',
    prompt:
        'Would you describe your main issue as tension, clenching, or pain — '
        'rather than weakness?',
    options: ['No', 'Yes'],
  ),
  HealthQuestion(
    id: 'tn_pelvic_pressure',
    prompt:
        'Pain or pressure in the pelvis, the perineum, or the genitals — for '
        'example when sitting?',
    options: ['No', 'Yes'],
  ),
  HealthQuestion(
    id: 'tn_pain_sex',
    prompt: 'Pain during or after sex or ejaculation?',
    options: ['No', 'Yes'],
  ),
  HealthQuestion(
    id: 'tn_urinary',
    prompt:
        'Urinary urgency or frequency, trouble starting your stream, or a '
        "feeling you can't fully empty — with no diagnosed cause?",
    options: ['No', 'Yes'],
  ),
  HealthQuestion(
    id: 'tn_body_tension',
    prompt:
        'Do you carry a lot of physical tension (jaw, shoulders) or live with '
        'chronic stress?',
    options: ['No', 'Yes'],
  ),
];

/// How many "yes" answers route to the tight-floor advisory (safety pack §2:
/// "two or more").
const int kTensionTightThreshold = 2;

/// Counts "yes" answers (index ≥ 1); [kTensionTightThreshold]+ → likelyTight.
PelvicFloorPattern evaluateTension(Map<String, int> answers) {
  var yes = 0;
  for (final q in kTensionQuestions) {
    if ((answers[q.id] ?? 0) >= 1) yes++;
  }
  return yes >= kTensionTightThreshold
      ? PelvicFloorPattern.likelyTight
      : PelvicFloorPattern.likelyWeak;
}
