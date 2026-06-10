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

  Plan planWeeks(List<int> numbers, List<String> tags) => Plan(
        weeks: [
          for (final n in numbers)
            PlanWeek(number: n, phase: 'P', moduleTags: tags),
        ],
        track: Track.solo,
        emphasis: const {},
        startDifficulty: Difficulty.standard,
      );

  test('rotates tag variants week over week for freshness', () {
    final varied = {
      'breathwork_basics': _def('breathwork_basics'),
      'breathwork_basics_v2': _def('breathwork_basics_v2'),
      'breathwork_basics_v3': _def('breathwork_basics_v3'),
    };
    final plan = planWeeks([1, 2, 3, 4], ['breathwork_basics']);
    String tagFor(int week) =>
        todaysSession(plan: plan, week: week, day: 1, catalog: varied)!.tag;
    // Same plan, same day — different session each week, wrapping at 3.
    expect(tagFor(1), 'breathwork_basics');
    expect(tagFor(2), 'breathwork_basics_v2');
    expect(tagFor(3), 'breathwork_basics_v3');
    expect(tagFor(4), 'breathwork_basics'); // wraps
  });

  test('a tag with no variants stays stable across weeks', () {
    final plan = planWeeks([1, 9], ['anatomy']);
    expect(todaysSession(plan: plan, week: 1, day: 1, catalog: catalog)!.tag,
        'anatomy');
    expect(todaysSession(plan: plan, week: 9, day: 1, catalog: catalog)!.tag,
        'anatomy');
  });
}
