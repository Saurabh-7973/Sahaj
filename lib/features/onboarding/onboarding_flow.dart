import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';
import 'health_questions.dart';
import 'onboarding_controller.dart';
import 'onboarding_pages.dart';

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
    if (_index >= _steps.length - 1) {
      ref.read(onboardingControllerProvider).finish();
      return;
    }
    _pageController.nextPage(
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
