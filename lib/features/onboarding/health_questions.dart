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

/// The validated-instrument items (PHQ-2 / GAD-2). Their stem + wording is
/// shown verbatim with the "standard wording, unchanged" framing (M4·01).
const kInstrumentItems = {'mood_down', 'mood_anxious', 'self_harm'};

/// Self-harm-indicating item: any answer above index 0 routes to the crisis
/// screen (M4 decision #1 — confirmed against this built question + threshold).
const kCrisisItemId = 'self_harm';

/// "Over the last 2 weeks, how often have you been bothered by:" — the shared
/// PHQ/GAD stem, shown above the verbatim item.
const kInstrumentStem =
    'Over the last 2 weeks, how often have you been bothered by:';

/// Why-strip per item (the warmth lives around the question, never in it).
const kHealthWhyLines = <String, String>{
  'morning_erections':
      'Morning erections are a sign blood flow and nerves are working. '
          'Good news if yes.',
  'pelvic_pain':
      'Pain or numbness is worth ruling out before any physical training.',
  'weight_loss':
      'Unexplained weight loss can point to something a doctor should check '
          'first — that\'s the only reason we ask.',
  'thirst_urination':
      'Constant thirst or frequent urination can flag something treatable.',
  'chest_breath':
      'Anything heart-related is worth a check before exercise of any kind.',
  'tremors_heart':
      'These can have simple causes, but a doctor should rule out the rest.',
  'prescriptions':
      'Some medications affect function directly — knowing helps us be honest '
          'about what training can and can\'t do.',
};

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
