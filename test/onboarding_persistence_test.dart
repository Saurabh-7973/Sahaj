import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';

void main() {
  test('toJson/loadFrom round-trips answers and completion', () {
    final a = OnboardingController();
    a.setPersona(Persona.singleInexperienced);
    a.toggleGoal(Goal.firstTimeOrGap);
    a.setHealthAnswer('morning_erections', 0);
    a.setBaselineAnswer('arousal_control', 1);
    a.setMindBodyAnswer('sleep', 2);
    a.finish();

    final json = a.toJson();

    final b = OnboardingController();
    b.loadFrom(json);

    expect(b.persona, Persona.singleInexperienced);
    expect(b.goals, contains(Goal.firstTimeOrGap));
    expect(b.complete, isTrue);
    expect(b.track, Track.solo);
    expect(b.plan, isNotNull);
  });
}
