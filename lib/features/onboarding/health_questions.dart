/// Health-screen questions (synthesis §6 screen 6 — Mojo-style intake).
/// One question per screen, calm framing. Phase 2 = collect answers only;
/// red-flag triage scoring is Weeks 3-4, NOT here.
class HealthQuestion {
  const HealthQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String prompt;
  final List<String> options;
}

const kHealthQuestions = <HealthQuestion>[
  HealthQuestion(
    id: 'morning_erections',
    prompt: 'Do you wake up with morning erections?',
    options: ['Yes, regularly', 'Sometimes', 'No, rarely or never'],
  ),
  HealthQuestion(
    id: 'pelvic_pain',
    prompt: 'Any pain or numbness in your pelvic area?',
    options: ['No', 'Sometimes', 'Yes, often'],
  ),
  HealthQuestion(
    id: 'weight_loss',
    prompt: 'Lost more than 5kg recently without trying?',
    options: ['No', 'Yes'],
  ),
  HealthQuestion(
    id: 'thirst_urination',
    prompt: 'Persistent thirst or frequent urination?',
    options: ['No', 'Sometimes', 'Yes, often'],
  ),
  HealthQuestion(
    id: 'chest_breath',
    prompt: 'Chest pain or breathlessness during exertion?',
    options: ['No', 'Sometimes', 'Yes'],
  ),
  HealthQuestion(
    id: 'tremors_heart',
    prompt: 'Tremors, or a heart rate that stays high?',
    options: ['No', 'Sometimes', 'Yes'],
  ),
  HealthQuestion(
    id: 'prescriptions',
    prompt: 'Are you currently taking any prescription medication?',
    options: ['No', 'Yes'],
  ),
  // Short PHQ-2 + GAD-2 mood read.
  HealthQuestion(
    id: 'mood_down',
    prompt:
        'Over the last 2 weeks, how often have you felt down, or had little '
        'interest in things?',
    options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
  ),
  HealthQuestion(
    id: 'mood_anxious',
    prompt:
        'Over the last 2 weeks, how often have you felt nervous, anxious, or '
        'on edge?',
    options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
  ),
  HealthQuestion(
    id: 'self_harm',
    prompt:
        'Over the last 2 weeks, how often have you had thoughts that you '
        'would be better off dead, or of hurting yourself?',
    options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
  ),
];
