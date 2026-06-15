import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';

void main() {
  test('toJson/loadFrom round-trips answers and completion', () {
    final a = OnboardingController();
    a.setPersona(Persona.singleInexperienced);
    a.toggleGoal(Goal.foundation);
    a.setHealthAnswer('morning_erections', 0);
    a.setBaselineAnswer('arousal_control', 1);
    a.setMindBodyAnswer('sleep', 2);
    a.finish();

    final json = a.toJson();

    final b = OnboardingController();
    b.loadFrom(json);

    expect(b.persona, Persona.singleInexperienced);
    expect(b.goals, contains(Goal.foundation));
    expect(b.complete, isTrue);
    expect(b.track, Track.solo);
    expect(b.plan, isNotNull);
  });

  test('round-trips safety answers + disclaimer acceptance', () {
    final a = OnboardingController();
    a.setEmergencyAnswer('em_priapism', 1);
    a.setTensionAnswer('tn_tension_not_weak', 1);
    a.setTensionAnswer('tn_pelvic_pressure', 1);
    a.acceptDisclaimer();

    final b = OnboardingController()..loadFrom(a.toJson());

    expect(b.emergencyFlags, contains(EmergencyFlag.priapism));
    expect(b.pelvicFloorPattern, PelvicFloorPattern.likelyTight);
    expect(b.disclaimerAccepted, isTrue);
    expect(b.disclaimerAcceptedAt, isNotNull);
  });

  test('a likely-tight floor softens the generated plan to a gentle start', () {
    final c = OnboardingController()
      ..setPersona(Persona.singleInexperienced)
      ..setTensionAnswer('tn_tension_not_weak', 1)
      ..setTensionAnswer('tn_pain_sex', 1)
      ..finish();

    expect(c.pelvicFloorPattern, PelvicFloorPattern.likelyTight);
    expect(c.plan!.startDifficulty, Difficulty.gentle);
    expect(c.plan!.emphasis, contains('down_training'));
  });
}
