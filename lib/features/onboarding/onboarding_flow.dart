import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/events.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';
import 'health_questions.dart';
import 'logic/triage.dart';
import 'onboarding_controller.dart';
import 'onboarding_pages.dart';
import 'pages/crisis_screen.dart';

class _Step {
  const _Step(this.body, {this.cta = 'Continue'});
  final Widget body;
  final String cta;
}

/// The onboarding flow — one route, a controlled PageView (no swipe; advance
/// via the Continue button for a calm, deliberate pace). State for all answers
/// lives in [OnboardingController]; this widget only drives navigation.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _pageController = PageController();
  int _index = 0;
  bool _showingCrisis = false;

  late final List<_Step> _steps = [
    const _Step(WelcomePage(), cta: 'Begin'),
    const _Step(PromisePage()),
    const _Step(EducationPage()),
    const _Step(PersonaPage()),
    const _Step(GoalsPage()),
    for (final q in kHealthQuestions) _Step(HealthQuestionPage(question: q)),
    const _Step(RedFlagPage()),
    const _Step(BaselinePage()),
    const _Step(MindBodyPage()),
    const _Step(PlanRevealPage()),
    const _Step(PrivacyPage()),
    const _Step(FirstSessionPage(), cta: 'Start now'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    // Safety gate: intercept self-harm question with a positive answer.
    final body = _steps[_index].body;
    if (!_showingCrisis &&
        body is HealthQuestionPage &&
        body.question.id == 'self_harm') {
      final a =
          ref.read(onboardingControllerProvider).healthAnswers['self_harm'];
      if (a != null && a > 0) {
        setState(() => _showingCrisis = true);
        return;
      }
    }

    if (_index >= _steps.length - 1) {
      final controller = ref.read(onboardingControllerProvider);
      controller.finish();
      final events = ref.read(appEventsProvider);
      final persona = controller.persona?.name ?? 'unknown';
      if (controller.persona != null) events.personaSelected(persona);
      events.goalSelected(controller.goals.map((g) => g.name).toList());
      events.planGenerated(persona, controller.goals.length);
      for (final cat in controller.triage?.categories ?? const <TriageCategory>{}) {
        events.redFlagFired(cat.name);
      }
      events.onboardingCompleted();
      return;
    }
    var target = _index + 1;
    final controller = ref.read(onboardingControllerProvider);
    if (_steps[target].body is RedFlagPage &&
        !evaluate(controller.healthAnswers).hasFlags) {
      target += 1; // skip red-flag page when triage has no flags
    }
    _pageController.animateToPage(
      target,
      duration: AppMotion.settle,
      curve: AppMotion.transition,
    );
  }

  void _back() {
    if (_index == 0) return;
    _pageController.previousPage(
      duration: AppMotion.settle,
      curve: AppMotion.transition,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_index + 1) / _steps.length;

    return Stack(
      children: [
        _buildFlow(progress),
        if (_showingCrisis)
          Positioned.fill(
            child: CrisisScreen(
              onContinue: () {
                setState(() => _showingCrisis = false);
                _pageController.nextPage(
                  duration: AppMotion.settle,
                  curve: AppMotion.transition,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFlow(double progress) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: back + progress.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xl,
                0,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: _index == 0
                        ? null
                        : IconButton(
                            onPressed: _back,
                            icon: const Icon(Icons.arrow_back),
                          ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: AppMotion.quick,
                        curve: AppMotion.transition,
                        builder: (context, v, _) =>
                            LinearProgressIndicator(value: v, minHeight: 6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _steps.length,
                itemBuilder: (context, i) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _steps[i].body,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: AppButton(label: _steps[_index].cta, onPressed: _next),
            ),
          ],
        ),
      ),
    );
  }
}
