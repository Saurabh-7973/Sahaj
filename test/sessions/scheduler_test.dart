import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/logic/models/onboarding_models.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/logic/scheduler.dart';

SessionDef _def(String tag) => SessionDef(
      tag: tag,
      title: tag,
      type: SessionType.education,
      steps: const [SessionStep(title: 's', seconds: 60, guidance: 'g')],
    );

Plan _planWith(List<String> week1Tags) => Plan(
      weeks: [
        PlanWeek(number: 1, phase: 'Foundation', moduleTags: week1Tags),
      ],
      track: Track.solo,
      emphasis: const {},
      startDifficulty: Difficulty.standard,
    );

void main() {
  final catalog = {
    'anatomy': _def('anatomy'),
    'pfmt_identify': _def('pfmt_identify'),
  };

  test('picks a session from the week tags by day, ignoring non-catalog tags',
      () {
    final plan = _planWith(['anatomy', 'pfmt_identify', 'solo']);
    expect(todaysSession(plan: plan, week: 1, day: 1, catalog: catalog)!.tag,
        'anatomy');
    expect(todaysSession(plan: plan, week: 1, day: 2, catalog: catalog)!.tag,
        'pfmt_identify');
    expect(todaysSession(plan: plan, week: 1, day: 3, catalog: catalog)!.tag,
        'anatomy');
  });

  test('returns null when the week has no catalog-backed tags', () {
    final plan = _planWith(['solo', 'partnered']);
    expect(todaysSession(plan: plan, week: 1, day: 1, catalog: catalog), isNull);
  });

  test('returns null when the requested week is missing', () {
    final plan = _planWith(['anatomy']);
    expect(todaysSession(plan: plan, week: 5, day: 1, catalog: catalog), isNull);
  });

  test('is deterministic for the same inputs', () {
    final plan = _planWith(['anatomy', 'pfmt_identify']);
    final a = todaysSession(plan: plan, week: 1, day: 2, catalog: catalog);
    final b = todaysSession(plan: plan, week: 1, day: 2, catalog: catalog);
    expect(a!.tag, b!.tag);
  });
}
