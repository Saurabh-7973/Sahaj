import 'package:flutter/material.dart' hide Baseline;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_background.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/widgets.dart';
import 'baseline_questions.dart';
import 'health_questions.dart';
import 'logic/triage.dart';
import 'onboarding_controller.dart';
import 'widgets/onb_chrome.dart';
import 'widgets/onb_illustrations.dart';
import 'widgets/selectable_option.dart';

// ── C1: Welcome ──────────────────────────────────────────────────────────
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onBegin});
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 18),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const OnbEyebrow('Sahaj · सहज', center: true),
                          const SizedBox(height: 20),
                          LotusMark(size: 96, color: lamp.gold, strokeWidth: 2.8),
                          const SizedBox(height: AppSpacing.xl),
                          Text('Train steady.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.displayLarge
                                  ?.copyWith(fontSize: 39)),
                          const SizedBox(height: 10),
                          Text("in one's natural state, with ease",
                              textAlign: TextAlign.center,
                              style: AppTypography.italic(16.5, lamp.sand)),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Most sexual function problems respond to training. '
                            'Sahaj is that training — five to fifteen minutes a '
                            'day, built on exercise and evidence, not pills or '
                            'promises.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: lamp.inkMuted),
                          ),
                          const SizedBox(height: 20),
                          const Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              AppChip(label: 'free forever'),
                              AppChip(label: 'private by design'),
                              AppChip(label: '12 weeks'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(label: 'Begin', onPressed: onBegin),
                const SizedBox(height: AppSpacing.md),
                Text('No account. Everything stays on this phone.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(color: lamp.faint)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── C2: The promise ──────────────────────────────────────────────────────
class PromiseScreen extends StatelessWidget {
  const PromiseScreen({super.key, required this.onNext, required this.onBack});
  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _rows = [
    ('About 3 minutes of questions',
        'Education first — you\'ll feel smarter before we ask anything.'),
    ('No payment until you decide',
        'The free tier is a complete program, not a teaser.'),
    ('Everything stays on this phone',
        'No account, no cloud, exportable any time.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnbScaffold(
      onBack: onBack,
      actions: [AppButton(label: 'Sounds fair', onPressed: onNext)],
      children: [
        const SizedBox(height: AppSpacing.md),
        Text('Three things, up front', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.xl),
        for (final r in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.$1, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(r.$2, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── C3: Education (3 slides) ─────────────────────────────────────────────
class EducationScreen extends StatefulWidget {
  const EducationScreen({
    super.key,
    required this.onDone,
    required this.onBack,
  });
  final VoidCallback onDone;
  final VoidCallback onBack;

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  int _slide = 0;

  static const _slides = [
    (
      'The basics · one of three',
      'Meet your pelvic floor',
      'A hammock of muscle slung inside your pelvis. It holds everything up '
          '— and it does more than that.',
    ),
    (
      'The basics · two of three',
      'You already know it',
      'Between your sit bones, front to back. You\'ve used it every time '
          'you\'ve stopped midstream or held a sneeze.',
    ),
    (
      'The basics · three of three',
      'Why training works',
      'It times ejaculation, supports erection rigidity, and strengthens '
          'like any other muscle. That\'s the whole idea.',
    ),
  ];

  void _advance() {
    if (_slide < 2) {
      setState(() => _slide++);
    } else {
      widget.onDone();
    }
  }

  void _back() {
    if (_slide == 0) {
      widget.onBack();
    } else {
      setState(() => _slide--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final s = _slides[_slide];

    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: Column(
              children: [
                OnbTopBar(onBack: _back, onSkip: widget.onDone),
                const SizedBox(height: AppSpacing.sm),
                OnbEyebrow(s.$1, center: true),
                Expanded(
                  child: Center(
                    child: EducationIllustration(slide: _slide),
                  ),
                ),
                // Slide dots.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      AnimatedContainer(
                        duration: AppMotion.quick,
                        width: i == _slide ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: i == _slide
                              ? LinearGradient(
                                  colors: [lamp.gold, const Color(0xFFBA8030)])
                              : null,
                          color: i == _slide
                              ? null
                              : lamp.sand.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(s.$2, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 25)),
                ),
                const SizedBox(height: 10),
                Text(s.$3,
                    style: theme.textTheme.bodyLarge?.copyWith(color: lamp.inkMuted)),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: _slide < 2 ? 'Next' : 'Got it',
                  onPressed: _advance,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── C4: Persona routing ──────────────────────────────────────────────────
class PersonaScreen extends ConsumerWidget {
  const PersonaScreen({super.key, required this.onNext, required this.onBack});
  final VoidCallback onNext;
  final VoidCallback onBack;

  // Order fixed; Persona Zero (singleInexperienced) is 4th, never last.
  static const _options = [
    (Persona.partneredActive, 'I finish sooner than I want to'),
    (Persona.partneredInactive, 'Erections are unreliable'),
    (Persona.singleExperienced, 'Porn has dulled real-life response'),
    (Persona.singleInexperienced,
        'I haven\'t been sexually active yet — I want to be ready'),
    (Persona.preferNotToSay, 'Nothing\'s wrong — I\'m here to get better'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = ref.watch(onboardingControllerProvider);
    return OnbScaffold(
      onBack: onBack,
      actions: [
        AppButton(
          label: 'Continue',
          onPressed: c.persona == null ? null : onNext,
        ),
      ],
      children: [
        const SizedBox(height: AppSpacing.md),
        Text('Which sounds most like you right now?',
            style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.xl),
        for (final o in _options)
          SelectableOption(
            label: o.$2,
            selected: c.persona == o.$1,
            onTap: () =>
                ref.read(onboardingControllerProvider).setPersona(o.$1),
          ),
      ],
    );
  }
}

// ── C5: Goals (multi) ────────────────────────────────────────────────────
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key, required this.onNext, required this.onBack});
  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _labels = {
    Goal.control: 'More control / lasting longer',
    Goal.erections: 'More reliable erections',
    Goal.anxiety: 'Less anxiety around sex',
    Goal.confidence: 'More confidence',
    Goal.foundation: 'Just building a healthy foundation',
    Goal.partner: 'Reconnecting with a partner',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final c = ref.watch(onboardingControllerProvider);
    return OnbScaffold(
      onBack: onBack,
      actions: [
        AppButton(
          label: 'Continue',
          onPressed: c.goals.isEmpty ? null : onNext,
        ),
      ],
      children: [
        const SizedBox(height: AppSpacing.md),
        Text('What are you here for?', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.sm),
        Text('Pick any that fit — weeks 5–12 of your plan adapt to these.',
            style: theme.textTheme.bodySmall?.copyWith(color: lamp.inkMuted)),
        const SizedBox(height: AppSpacing.xl),
        for (final e in _labels.entries)
          SelectableOption(
            multi: true,
            label: e.value,
            selected: c.goals.contains(e.key),
            onTap: () =>
                ref.read(onboardingControllerProvider).toggleGoal(e.key),
          ),
      ],
    );
  }
}

// ── C6 intro: Health-check entry ─────────────────────────────────────────
class HealthIntroScreen extends StatelessWidget {
  const HealthIntroScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnbScaffold(
      onBack: onBack,
      actions: [AppButton(label: 'Start the check', onPressed: onNext)],
      children: [
        const SizedBox(height: AppSpacing.md),
        Text('First, a quick check', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Some conditions need a doctor before training helps, and we\'d '
          'rather tell you than sell you.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        const OnbStrip(
          'Takes about a minute. Nothing here is stored anywhere but this '
          'phone.',
        ),
      ],
    );
  }
}

// ── C6 / C8 / C9: One health/baseline question ──────────────────────────
class HealthQuestionScreen extends ConsumerWidget {
  const HealthQuestionScreen({
    super.key,
    required this.question,
    required this.value,
    required this.onAnswer,
    required this.onBack,
    required this.stepIndex,
    required this.stepCount,
  });

  final HealthQuestion question;
  final int? value;

  /// Saves the answer index and advances.
  final ValueChanged<int> onAnswer;
  final VoidCallback onBack;
  final int stepIndex;
  final int stepCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final isInstrument = kInstrumentItems.contains(question.id);
    final why = kHealthWhyLines[question.id];

    return OnbScaffold(
      onBack: onBack,
      stepCount: stepCount,
      stepIndex: stepIndex,
      actions: [
        Text(
          isInstrument
              ? 'PHQ-2 · standard wording, unchanged'
              : 'Tap an answer to continue · nothing leaves this phone',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(color: lamp.faint),
        ),
      ],
      children: [
        const SizedBox(height: AppSpacing.sm),
        const OnbEyebrow('Health check'),
        const SizedBox(height: AppSpacing.md),
        if (isInstrument)
          const OnbStrip(
            'Two standard questions every doctor uses — same words '
            'everywhere. Answer honestly, not bravely.',
          )
        else if (why != null)
          OnbStrip(why),
        const SizedBox(height: AppSpacing.lg),
        Text(question.prompt,
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24, height: 31 / 24)),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < question.options.length; i++)
          SelectableOption(
            label: question.options[i],
            selected: value == i,
            onTap: () => onAnswer(i),
          ),
      ],
    );
  }
}

// ── C7: Triage ───────────────────────────────────────────────────────────
class TriageScreen extends ConsumerWidget {
  const TriageScreen({
    super.key,
    required this.onArticle,
    required this.onContinue,
    required this.onBack,
  });
  final VoidCallback onArticle;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  static const _chipLabel = {
    TriageCategory.cardiac: 'heart signs',
    TriageCategory.metabolic: 'blood-flow signs',
    TriageCategory.neuro: 'nerve signs',
    TriageCategory.organicErectile: 'morning-erection signs',
    TriageCategory.mentalHealth: 'mood',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = ref.watch(onboardingControllerProvider);
    final cats = evaluate(c.healthAnswers).categories.take(3).toList();

    return OnbScaffold(
      onBack: onBack,
      actions: [
        AppButton(
          label: 'How to bring this up with a doctor',
          variant: AppButtonVariant.outlined,
          onPressed: onArticle,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'Continue with the free program', onPressed: onContinue),
      ],
      children: [
        const SizedBox(height: AppSpacing.md),
        const OnbEyebrow('Care'),
        const SizedBox(height: 10),
        Text('One thing first', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.lg),
        if (cats.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final cat in cats)
                AppChip(label: _chipLabel[cat] ?? cat.name,
                    variant: AppChipVariant.warn),
            ],
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'A couple of your answers suggest seeing a doctor before training — '
          'not instead of it. Training can\'t fix what these might be, and we '
          'won\'t pretend otherwise.',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

// ── C8 / C9 intro strips wrap the baseline questions, but those reuse the
//    HealthQuestionScreen template; their intro lines live in the flow. ──

// ── C11: Privacy ─────────────────────────────────────────────────────────
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key, required this.onDone, required this.onBack});
  final VoidCallback onDone;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    final c = ref.watch(onboardingControllerProvider);
    return OnbScaffold(
      onBack: onBack,
      actions: [AppButton(label: 'Done', onPressed: onDone)],
      children: [
        const SizedBox(height: AppSpacing.md),
        Text('Make it yours alone', style: theme.textTheme.displaySmall),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Row(
            children: [
              Icon(Icons.fingerprint, color: lamp.gold, size: 26),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biometric lock', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('Require Face or fingerprint to open Sahaj.',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Switch(
                value: c.biometricLock,
                onChanged: (v) =>
                    ref.read(onboardingControllerProvider).setBiometricLock(v),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const OnbStrip(
          'Double-tap the cover screen to open Sahaj. Change any of this later '
          'in Settings.',
        ),
      ],
    );
  }
}

// ── C12: First session ready ─────────────────────────────────────────────
class FirstSessionScreen extends StatelessWidget {
  const FirstSessionScreen({
    super.key,
    required this.onStartNow,
    required this.onThisEvening,
  });
  final VoidCallback onStartNow;
  final VoidCallback onThisEvening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lamp = context.lamp;
    return Scaffold(
      body: LampBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          AppProgressRing(
                            value: 0.15,
                            size: 150,
                            tint: lamp.ochre,
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('7',
                                    style: AppTypography.numeral(36, lamp.ink)),
                                Text('MIN', style: theme.textTheme.labelSmall),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AppSpacing.sm,
                            children: [
                              AppChip.type(
                                  typeName: 'breathwork', label: 'breathwork'),
                              AppChip(label: 'no signup'),
                              AppChip(label: 'no payment'),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text('Your first session is ready',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.displaySmall),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Breathing, and finding the muscle. Nothing to '
                            'create, nothing to pay.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: lamp.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(label: 'Start now', onPressed: onStartNow),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'This evening',
                  variant: AppButtonVariant.outlined,
                  onPressed: onThisEvening,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '"This evening" sets your daily reminder and takes you home.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(color: lamp.faint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper: the baseline batteries flattened to one-question-per-screen, with
/// the C8/C9 intro strip carried on the first item of each.
List<HealthQuestion> baselineBatteryFor(Track track) =>
    track == Track.partnered ? partneredBaseline : soloBaseline;
