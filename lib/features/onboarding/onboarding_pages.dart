import 'package:flutter/material.dart' hide Baseline;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';
import 'baseline_questions.dart';
import 'health_questions.dart';
import 'logic/banding.dart';
import 'logic/plan_generator.dart';
import 'logic/triage.dart';
import 'onboarding_controller.dart';
import 'widgets/selectable_option.dart';

/// Shared header for an onboarding page: big title + supporting body text.
class OnbHeader extends StatelessWidget {
  const OnbHeader({super.key, required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.displaySmall),
        if (body != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(body!, style: theme.textTheme.bodyLarge),
        ],
      ],
    );
  }
}

/// A scrollable column for page content with consistent top spacing.
class OnbBody extends StatelessWidget {
  const OnbBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ── Screen 1: Welcome ────────────────────────────────────────────────────
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnbBody(
      children: [
        Text('Sahaj', style: theme.textTheme.displayLarge),
        const SizedBox(height: AppSpacing.sm),
        Text('Train steady.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'Sahaj helps you train your body and mind for steady, confident '
          'sexual function. Welcome.',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

// ── Screen 2: The promise ────────────────────────────────────────────────
class PromisePage extends StatelessWidget {
  const PromisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnbBody(
      children: [
        OnbHeader(
          title: 'A few promises',
          body:
              'This will take three minutes. There is no payment until you '
              'have used the app and decided it’s worth it. Your answers stay '
              'on this device.',
        ),
      ],
    );
  }
}

// ── Screen 3: Education before assessment ────────────────────────────────
class EducationPage extends StatelessWidget {
  const EducationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnbBody(
      children: [
        const OnbHeader(
          title: 'First, the pelvic floor',
          body:
              'Before we ask you anything, here’s what we’re working with.',
        ),
        const SizedBox(height: AppSpacing.xl),
        _factCard(context, '1', 'What it is',
            'A hammock of muscles at the base of your pelvis.'),
        _factCard(context, '2', 'Where it sits',
            'Between the tailbone and the pubic bone, supporting the bladder and bowel.'),
        _factCard(context, '3', 'What it does',
            'It governs the muscles behind erection and ejaculation. Train it, and you gain control.'),
      ],
    );
  }

  Widget _factCard(
      BuildContext context, String n, String title, String body) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n, style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
            )),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Screen 4: Persona routing ────────────────────────────────────────────
class PersonaPage extends ConsumerWidget {
  const PersonaPage({super.key});

  static const _labels = {
    Persona.partneredActive:
        'I have a partner now and we are sexually active',
    Persona.partneredInactive:
        'I have a partner now and we are not sexually active',
    Persona.singleExperienced:
        'I am single and have been sexually active in the past',
    Persona.singleInexperienced:
        'I am single and have never been sexually active',
    Persona.preferNotToSay: 'I prefer not to say',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(onboardingControllerProvider);
    return OnbBody(
      children: [
        const OnbHeader(title: 'Which describes you right now?'),
        const SizedBox(height: AppSpacing.xl),
        for (final entry in _labels.entries)
          SelectableOption(
            label: entry.value,
            selected: controller.persona == entry.key,
            onTap: () => ref
                .read(onboardingControllerProvider)
                .setPersona(entry.key),
          ),
      ],
    );
  }
}

// ── Screen 5: Goal selection (multi) ─────────────────────────────────────
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  static const _labels = {
    Goal.finishTooQuick: 'I finish too quickly',
    Goal.hardness: 'I struggle to get or stay hard',
    Goal.firstTimeOrGap: 'I’m preparing for my first time or after a long gap',
    Goal.pornRelationship: 'I want to fix my relationship with porn',
    Goal.lastLongerOptimize:
        'I want to last longer and feel more, even though things are okay',
    Goal.exploring: 'I’m not sure yet, I’m exploring',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(onboardingControllerProvider);
    return OnbBody(
      children: [
        const OnbHeader(
          title: 'What brings you here?',
          body: 'Pick all that apply.',
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final entry in _labels.entries)
          SelectableOption(
            multi: true,
            label: entry.value,
            selected: controller.goals.contains(entry.key),
            onTap: () =>
                ref.read(onboardingControllerProvider).toggleGoal(entry.key),
          ),
      ],
    );
  }
}

// ── Screen 6: Health question (one per screen, data-driven) ──────────────
class HealthQuestionPage extends ConsumerWidget {
  const HealthQuestionPage({super.key, required this.question});

  final HealthQuestion question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(onboardingControllerProvider);
    final answer = controller.healthAnswers[question.id];
    return OnbBody(
      children: [
        OnbHeader(title: question.prompt),
        const SizedBox(height: AppSpacing.xl),
        for (var i = 0; i < question.options.length; i++)
          SelectableOption(
            label: question.options[i],
            selected: answer == i,
            onTap: () => ref
                .read(onboardingControllerProvider)
                .setHealthAnswer(question.id, i),
          ),
      ],
    );
  }
}

// ── Screen 7: Red-flag triage (shown when triage has flags) ─────────────
class RedFlagPage extends ConsumerWidget {
  const RedFlagPage({super.key});

  static const _copy = {
    TriageCategory.cardiac:
        "Chest pain or breathlessness is worth a doctor’s check before any physical training.",
    TriageCategory.metabolic:
        'Unexplained weight loss or constant thirst can point to something treatable — a quick blood test is wise.',
    TriageCategory.neuro:
        'Pain, numbness, or tremors are worth ruling out with a doctor first.',
    TriageCategory.organicErectile:
        'A lack of morning erections can have a physical cause. A doctor can check before we train.',
    TriageCategory.mentalHealth:
        "How you’ve been feeling matters. Talking to a doctor or counsellor is a strong first step.",
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = ref.watch(onboardingControllerProvider);
    final result = evaluate(c.healthAnswers);
    final clearance = c.medicalClearance;

    return OnbBody(
      children: [
        const OnbHeader(
          title: 'A quick note on health',
          body:
              "Some things are worth checking with a doctor before training. "
              "We’re not a medical service, and we want you to be well first. "
              'You can still use the free tier today.',
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final cat in result.categories)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Text(_copy[cat]!, style: theme.textTheme.bodyMedium),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        SelectableOption(
          label: "I’ll see a doctor first",
          selected: clearance == MedicalClearance.notSeen,
          onTap: () => ref
              .read(onboardingControllerProvider)
              .setMedicalClearance(MedicalClearance.notSeen),
        ),
        SelectableOption(
          label: 'I understand — continue for now',
          selected: clearance == MedicalClearance.proceedAnyway,
          onTap: () => ref
              .read(onboardingControllerProvider)
              .setMedicalClearance(MedicalClearance.proceedAnyway),
        ),
      ],
    );
  }
}

// ── Screen 8: Function baseline (track-driven battery) ───────────────────
class BaselinePage extends ConsumerWidget {
  const BaselinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(onboardingControllerProvider);
    final questions =
        c.track == Track.partnered ? partneredBaseline : soloBaseline;
    return OnbBody(
      children: [
        const OnbHeader(
          title: "Where you’re starting from",
          body: 'An honest baseline so we can measure your progress.',
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final q in questions) ...[
          Text(q.prompt, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < q.options.length; i++)
            SelectableOption(
              label: q.options[i],
              selected: c.baselineRaw[q.id] == i,
              onTap: () =>
                  ref.read(onboardingControllerProvider).setBaselineAnswer(q.id, i),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

// ── Screen 9: Mind/body baseline (question-driven) ───────────────────────
class MindBodyPage extends ConsumerWidget {
  const MindBodyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(onboardingControllerProvider);
    return OnbBody(
      children: [
        const OnbHeader(
          title: 'Sleep, stress, and habits',
          body: 'A few quick questions to tune your plan.',
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final q in mindBodyQuestions) ...[
          Text(q.prompt, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < q.options.length; i++)
            SelectableOption(
              label: q.options[i],
              selected: c.mindBodyRaw[q.id] == i,
              onTap: () =>
                  ref.read(onboardingControllerProvider).setMindBodyAnswer(q.id, i),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

// ── Screen 10: Plan reveal ───────────────────────────────────────────
class PlanRevealPage extends ConsumerWidget {
  const PlanRevealPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = ref.watch(onboardingControllerProvider);
    final track = c.track ?? Track.solo;
    final preview = generatePlan(
      track: track,
      goals: c.goals,
      baseline: Baseline(
        bands: {for (final e in c.baselineRaw.entries) e.key: bandFromIndex(e.value)},
        raw: c.baselineRaw,
      ),
      mindBody: {for (final e in c.mindBodyRaw.entries) e.key: bandFromIndex(e.value)},
    );
    const phases = ['Foundation', 'Integration', 'Mastery'];
    const blurb = {
      'Foundation': 'Find the muscles, learn to relax them, build basic strength.',
      'Integration': 'Connect breath, body, and arousal awareness.',
      'Mastery': 'Apply the trained capacity to real situations.',
    };

    return OnbBody(
      children: [
        const OnbHeader(
          title: 'Your 12-week plan',
          body: 'Based on what you shared, here\'s the shape of it.',
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final phase in phases)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weeks ${_weekRange(preview, phase)}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(phase, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(blurb[phase]!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Roughly 65–80% of users see meaningful improvement by week 12 if '
          'they train 5+ days per week. 5–15 minutes a day.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _weekRange(Plan p, String phase) {
    final ws = p.weeks.where((w) => w.phase == phase).map((w) => w.number);
    return '${ws.reduce((a, b) => a < b ? a : b)}–${ws.reduce((a, b) => a > b ? a : b)}';
  }
}

// ── Screen 11: Privacy & discreet mode ───────────────────────────────────
class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = ref.watch(onboardingControllerProvider);
    return OnbBody(
      children: [
        const OnbHeader(
          title: 'Yours, and private',
          body:
              'Your answers, plan, and progress stay on this device. You can '
              'disguise the app — rename the icon and choose Book Mode — '
              'anytime.',
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Row(
            children: [
              Icon(Icons.fingerprint, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biometric lock', style: theme.textTheme.titleMedium),
                    Text('Require Face/fingerprint to open Sahaj',
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
      ],
    );
  }
}

// ── Screen 12: First session ready ───────────────────────────────────────
class FirstSessionPage extends StatelessWidget {
  const FirstSessionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnbBody(
      children: [
        OnbHeader(
          title: 'Your first session is ready',
          body:
              'It takes 7 minutes. You can do it now or schedule it. '
              'No payment, no signup wall.',
        ),
      ],
    );
  }
}
