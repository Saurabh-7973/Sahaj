import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/logic/models/onboarding_models.dart';
import 'package:sahaj/features/onboarding/logic/safety_screening.dart';

void main() {
  group('emergency carve-out', () {
    test('no answers → no emergency flags', () {
      expect(evaluateEmergency({}), isEmpty);
    });

    test('all "No" → no flags', () {
      expect(
        evaluateEmergency({'em_priapism': 0, 'em_saddle': 0}),
        isEmpty,
      );
    });

    test('priapism "Yes" fires its flag', () {
      expect(
        evaluateEmergency({'em_priapism': 1}),
        contains(EmergencyFlag.priapism),
      );
    });

    test('saddle "Yes" fires the neuro flag', () {
      expect(
        evaluateEmergency({'em_saddle': 1}),
        {EmergencyFlag.neuroSaddle},
      );
    });

    test('both fire together', () {
      expect(
        evaluateEmergency({'em_priapism': 1, 'em_saddle': 1}),
        {EmergencyFlag.priapism, EmergencyFlag.neuroSaddle},
      );
    });
  });

  group('hypertonic / tension screen', () {
    test('no answers → likely weak (default strengthen-first)', () {
      expect(evaluateTension({}), PelvicFloorPattern.likelyWeak);
    });

    test('one "yes" stays weak — below the threshold', () {
      expect(
        evaluateTension({'tn_pain_sex': 1}),
        PelvicFloorPattern.likelyWeak,
      );
    });

    test('two "yes" routes to likely tight', () {
      expect(
        evaluateTension({'tn_tension_not_weak': 1, 'tn_pelvic_pressure': 1}),
        PelvicFloorPattern.likelyTight,
      );
    });

    test('all five "yes" → likely tight', () {
      final all = {for (final q in kTensionQuestions) q.id: 1};
      expect(evaluateTension(all), PelvicFloorPattern.likelyTight);
    });

    test('threshold is exactly two', () {
      expect(kTensionTightThreshold, 2);
    });
  });

  test('disclaimer version is set for the must-accept gate', () {
    expect(kDisclaimerVersion, isNotEmpty);
  });
}
