import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';
import 'health_questions.dart';
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
              'have used the app and decided it’s worth it. Your data never '
              'leaves your phone unless you turn on cloud sync.',
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

// ── Screen 7: Red-flag triage (shown unconditionally in shell) ───────────
class RedFlagPage extends StatelessWidget {
  const RedFlagPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnbBody(
      children: [
        const OnbHeader(
          title: 'A quick note on health',
          body:
              'Some things are worth checking with a doctor before training. '
              'We’re not a medical service, and we want you to be well first.',
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('If anything you shared was new or unexplained',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'A short visit to a doctor or a telehealth service (such as '
                'Practo or a local clinic) is a good first step. We’ll be '
                'here when you’re ready.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Screen 8: Function baseline (placeholder shell) ──────────────────────
class BaselinePage extends StatelessWidget {
  const BaselinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnbBody(
      children: [
        OnbHeader(
          title: 'Where you’re starting from',
          body:
              'Next, a few calibrated questions about arousal control. This '
              'gives us an honest baseline to measure your progress against. '
              'The full battery arrives in the next build.',
        ),
      ],
    );
  }
}

// ── Screen 9: Mind/body baseline (placeholder shell) ─────────────────────
class MindBodyPage extends StatelessWidget {
  const MindBodyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnbBody(
      children: [
        OnbHeader(
          title: 'Sleep, stress, and habits',
          body:
              'Five quick questions on sleep, stress, exercise, and habits '
              'help us tune your plan. Coming in the next build.',
        ),
      ],
    );
  }
}

// ── Screen 10: Plan reveal ───────────────────────────────────────────────
class PlanRevealPage extends StatelessWidget {
  const PlanRevealPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnbBody(
      children: [
        const OnbHeader(
          title: 'Your 12-week plan',
          body: 'Based on what you shared, here’s the shape of it.',
        ),
        const SizedBox(height: AppSpacing.xl),
        _milestone(context, 'Weeks 1–4', 'Foundation',
            'Find the muscles, learn to relax them, build basic strength.'),
        _milestone(context, 'Weeks 5–8', 'Integration',
            'Connect breath, body, and arousal awareness.'),
        _milestone(context, 'Weeks 9–12', 'Mastery',
            'Apply the trained capacity to real situations.'),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Roughly 65–80% of users see meaningful improvement by week 12 if '
          'they train 5+ days per week. 5–15 minutes a day.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _milestone(
      BuildContext context, String weeks, String title, String body) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(weeks, style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            )),
            const SizedBox(height: AppSpacing.xs),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ── Screen 11: Privacy & discreet mode ───────────────────────────────────
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _biometric = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnbBody(
      children: [
        const OnbHeader(
          title: 'Yours, and private',
          body:
              'Your data lives on this device. Cloud sync is optional and '
              'encrypted. You can disguise the app — rename the icon and '
              'choose Book Mode — anytime.',
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
                value: _biometric,
                onChanged: (v) => setState(() => _biometric = v),
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
