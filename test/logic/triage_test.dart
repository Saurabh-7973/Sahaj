import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/logic/triage.dart';
import 'package:sahaj/features/onboarding/logic/models/onboarding_models.dart';

void main() {
  test('clean answers fire no flags', () {
    final r = evaluate({
      'morning_erections': 0, // Yes regularly
      'pelvic_pain': 0,       // No
      'weight_loss': 0,       // No
      'thirst_urination': 0,  // No
      'chest_breath': 0,      // No
      'tremors_heart': 0,     // No
      'prescriptions': 0,     // No
      'mood_down': 0,
      'mood_anxious': 0,
      'self_harm': 0,
    });
    expect(r.hasFlags, isFalse);
  });

  test('no morning erections fires organicErectile', () {
    final r = evaluate({'morning_erections': 2});
    expect(r.categories, contains(TriageCategory.organicErectile));
  });

  test('weight loss and thirst fire metabolic', () {
    expect(evaluate({'weight_loss': 1}).categories,
        contains(TriageCategory.metabolic));
    expect(evaluate({'thirst_urination': 2}).categories,
        contains(TriageCategory.metabolic));
  });

  test('chest symptoms fire cardiac at "sometimes" (conservative)', () {
    expect(evaluate({'chest_breath': 1}).categories,
        contains(TriageCategory.cardiac));
  });

  test('daily low mood fires mentalHealth', () {
    expect(evaluate({'mood_down': 3}).categories,
        contains(TriageCategory.mentalHealth));
  });

  test('any self-harm fires mentalHealth', () {
    expect(evaluate({'self_harm': 1}).categories,
        contains(TriageCategory.mentalHealth));
  });
}
