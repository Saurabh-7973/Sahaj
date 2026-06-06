import 'health_questions.dart'; // reuse the HealthQuestion shape

/// Persona-calibrated baseline (synthesis §6 screen 8). Capture only;
/// coarse banding via bandFromIndex. Friendly wording, not clinical.
const partneredBaseline = <HealthQuestion>[
  HealthQuestion(
    id: 'pe_control',
    prompt: "During sex, how much control do you feel over when you finish?",
    options: ['Very little', 'Some', 'A good amount', 'Full control'],
  ),
  HealthQuestion(
    id: 'erection_confidence',
    prompt: 'How confident are you that you can get and keep an erection?',
    options: ['Not confident', 'Slightly', 'Fairly', 'Very confident'],
  ),
  HealthQuestion(
    id: 'erection_maintain',
    prompt: 'How often can you maintain an erection through sex?',
    options: ['Rarely', 'Sometimes', 'Most times', 'Almost always'],
  ),
];

const soloBaseline = <HealthQuestion>[
  HealthQuestion(
    id: 'arousal_control',
    prompt: 'On your own, how much control do you feel over your arousal?',
    options: ['Very little', 'Some', 'A good amount', 'Full control'],
  ),
  HealthQuestion(
    id: 'rehearsal_comfort',
    prompt: 'How comfortable are you imagining a calm, confident encounter?',
    options: ['Not at all', 'A little', 'Fairly', 'Very comfortable'],
  ),
  HealthQuestion(
    id: 'future_anxiety',
    prompt: 'How anxious do you feel about a future first or next encounter?',
    options: ['Very anxious', 'Somewhat', 'A little', 'Not anxious'],
  ),
];

/// Mind/body baseline (synthesis §6 screen 9). 5 questions.
const mindBodyQuestions = <HealthQuestion>[
  HealthQuestion(
    id: 'sleep',
    prompt: 'How would you rate your sleep lately?',
    options: ['Poor', 'Fair', 'Good', 'Great'],
  ),
  HealthQuestion(
    id: 'stress',
    prompt: 'How stressed have you felt recently?',
    options: ['Very stressed', 'Somewhat', 'A little', 'Calm'],
  ),
  HealthQuestion(
    id: 'exercise',
    prompt: 'How often do you exercise?',
    options: ['Rarely', 'Sometimes', 'Often', 'Most days'],
  ),
  HealthQuestion(
    id: 'alcohol',
    prompt: 'How often do you drink alcohol?',
    options: ['Daily', 'Often', 'Sometimes', 'Rarely or never'],
  ),
  HealthQuestion(
    id: 'porn_freq',
    prompt: 'How often do you watch porn?',
    options: ['Daily', 'Often', 'Sometimes', 'Rarely or never'],
  ),
];
