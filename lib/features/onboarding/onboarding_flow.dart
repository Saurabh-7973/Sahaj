import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/events.dart';
import 'baseline_questions.dart';
import 'health_questions.dart';
import 'logic/triage.dart';
import 'onboarding_controller.dart';
import 'onboarding_pages.dart';
import 'pages/crisis_screen.dart';
import 'pages/plan_reveal_screen.dart';
import 'pages/resume_screen.dart';

/// One screen in the linear flow, with the metadata the orchestrator needs
/// to route, label the resume screen, and skip the conditional triage.
class _Screen {
  const _Screen(this.build, {this.isTriage = false, this.resumeLabel});
  final Widget Function() build;
  final bool isTriage;
  final String? resumeLabel;
}

/// The onboarding flow (M4). One route; self-contained Lamplight screens;
/// every answer persists immediately; killable and resumable at the exact
/// pending screen.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _index = 0;
  bool _showingCrisis = false;
  bool _showingResume = false;

  @override
  void initState() {
    super.initState();
    final c = ref.read(onboardingControllerProvider);
    _index = c.lastStep;
    _showingResume = c.lastStep > 0; // returning mid-flow → resume first
  }

  List<_Screen> _screens(OnboardingController c) {
    final track = c.track ?? Track.solo;
    final baseline = baselineBatteryFor(track);

    final screens = <_Screen>[
      _Screen(
        () => WelcomeScreen(onBegin: _next),
        resumeLabel: 'You were just getting started.',
      ),
      _Screen(
        () => PromiseScreen(onNext: _next, onBack: _back),
        resumeLabel: 'You were reading the promises.',
      ),
      _Screen(
        () => EducationScreen(onDone: _next, onBack: _back),
        resumeLabel: 'You were learning the basics.',
      ),
      _Screen(
        () => PersonaScreen(onNext: _next, onBack: _back),
        resumeLabel: 'You were telling us where you\'re at.',
      ),
      _Screen(
        () => GoalsScreen(onNext: _next, onBack: _back),
        resumeLabel: 'You were choosing what to work on.',
      ),
      _Screen(
        () => HealthIntroScreen(onNext: _next, onBack: _back),
        resumeLabel: 'You were on the health check.',
      ),
      // 10 health questions — auto-advance.
      for (var i = 0; i < kHealthQuestions.length; i++)
        _Screen(
          () {
            final q = kHealthQuestions[i];
            return HealthQuestionScreen(
              question: q,
              value: c.healthAnswers[q.id],
              stepIndex: i,
              stepCount: kHealthQuestions.length,
              onBack: _back,
              onAnswer: (v) {
                c.setHealthAnswer(q.id, v);
                if (q.id == kCrisisItemId && v > 0) {
                  setState(() => _showingCrisis = true);
                  return;
                }
                _next();
              },
            );
          },
          resumeLabel: 'You were on the health check.',
        ),
      _Screen(
        () => TriageScreen(
          onArticle: _next, // TODO(M5): open the doctor-conversation article
          onContinue: () {
            ref
                .read(onboardingControllerProvider)
                .setMedicalClearance(MedicalClearance.proceedAnyway);
            _next();
          },
          onBack: _back,
        ),
        isTriage: true,
        resumeLabel: 'You were on a quick care note.',
      ),
      // Function baseline (C8).
      for (var i = 0; i < baseline.length; i++)
        _Screen(
          () {
            final q = baseline[i];
            return HealthQuestionScreen(
              question: q,
              value: c.baselineRaw[q.id],
              stepIndex: i,
              stepCount: baseline.length,
              onBack: _back,
              onAnswer: (v) {
                c.setBaselineAnswer(q.id, v);
                _next();
              },
            );
          },
          resumeLabel: 'You were setting your week-0 baseline.',
        ),
      // Mind/body baseline (C9).
      for (var i = 0; i < mindBodyQuestions.length; i++)
        _Screen(
          () {
            final q = mindBodyQuestions[i];
            return HealthQuestionScreen(
              question: q,
              value: c.mindBodyRaw[q.id],
              stepIndex: i,
              stepCount: mindBodyQuestions.length,
              onBack: _back,
              onAnswer: (v) {
                c.setMindBodyAnswer(q.id, v);
                _next();
              },
            );
          },
          resumeLabel: 'You were answering a few lifestyle questions.',
        ),
      _Screen(
        () => PlanRevealScreen(onNext: _next, onBack: _back),
        resumeLabel: 'Your plan was ready to see.',
      ),
      _Screen(
        () => PrivacyScreen(onDone: _next, onBack: _back),
        resumeLabel: 'You were setting up privacy.',
      ),
      _Screen(
        () => FirstSessionScreen(
          onStartNow: _finish,
          onThisEvening: _finish,
        ),
        resumeLabel: 'Your first session was ready.',
      ),
    ];
    return screens;
  }

  bool _triageHasFlags() =>
      evaluate(ref.read(onboardingControllerProvider).healthAnswers).hasFlags;

  void _next() {
    final screens = _screens(ref.read(onboardingControllerProvider));
    var target = _index + 1;
    // Skip the triage screen when no red flags fired.
    if (target < screens.length &&
        screens[target].isTriage &&
        !_triageHasFlags()) {
      target += 1;
    }
    if (target >= screens.length) {
      _finish();
      return;
    }
    setState(() => _index = target);
    ref.read(onboardingControllerProvider).setLastStep(target);
  }

  void _back() {
    if (_index == 0) return;
    final screens = _screens(ref.read(onboardingControllerProvider));
    var target = _index - 1;
    if (target >= 0 && screens[target].isTriage && !_triageHasFlags()) {
      target -= 1;
    }
    if (target < 0) return;
    setState(() => _index = target);
    ref.read(onboardingControllerProvider).setLastStep(target);
  }

  void _finish() {
    final controller = ref.read(onboardingControllerProvider);
    controller.finish();
    final events = ref.read(appEventsProvider);
    final persona = controller.persona?.name ?? 'unknown';
    if (controller.persona != null) events.personaSelected(persona);
    events.goalSelected(controller.goals.map((g) => g.name).toList());
    events.planGenerated(persona, controller.goals.length);
    for (final cat
        in controller.triage?.categories ?? const <TriageCategory>{}) {
      events.redFlagFired(cat.name);
    }
    events.onboardingCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(onboardingControllerProvider);
    final screens = _screens(c);
    final index = _index.clamp(0, screens.length - 1);

    if (_showingResume) {
      final label =
          screens[index].resumeLabel ?? 'Picking up where you left off.';
      String? orientation;
      // Health questions carry "Question N of M" orientation (only numeral).
      const healthStart = 6;
      if (index >= healthStart &&
          index < healthStart + kHealthQuestions.length) {
        orientation =
            'Question ${index - healthStart + 1} of ${kHealthQuestions.length}';
      }
      return ResumeScreen(
        whereLine: label,
        orientation: orientation,
        onContinue: () => setState(() => _showingResume = false),
        onStartOver: () {
          ref.read(onboardingControllerProvider).reset();
          setState(() {
            _showingResume = false;
            _index = 0;
          });
        },
      );
    }

    if (_showingCrisis) {
      return CrisisScreen(
        onContinue: () {
          setState(() => _showingCrisis = false);
          _next();
        },
      );
    }

    return screens[index].build();
  }
}
