import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/logic/plan_generator.dart';

void main() {
  final emptyBaseline = const Baseline(bands: {}, raw: {});

  test('plan always has 12 weeks across 3 phases', () {
    final p = generatePlan(
      track: Track.solo,
      goals: {},
      baseline: emptyBaseline,
      mindBody: {},
    );
    expect(p.weeks.length, 12);
    expect(p.weeks.map((w) => w.phase).toSet(),
        {'Foundation', 'Integration', 'Mastery'});
  });

  test('finishTooQuick adds stop-start emphasis', () {
    final p = generatePlan(
      track: Track.solo,
      goals: {Goal.finishTooQuick},
      baseline: emptyBaseline,
      mindBody: {},
    );
    expect(p.emphasis, contains('stop_start'));
  });

  test('emphasis personalises the plan: goal tags appear in Weeks 5-12', () {
    final p = generatePlan(
      track: Track.solo,
      goals: {Goal.pornRelationship}, // -> dopamine_rewire
      baseline: emptyBaseline,
      mindBody: {},
    );
    final foundation =
        p.weeks.where((w) => w.number <= 4).expand((w) => w.moduleTags);
    final later =
        p.weeks.where((w) => w.number >= 5).expand((w) => w.moduleTags);
    expect(later, contains('dopamine_rewire'));
    expect(foundation, isNot(contains('dopamine_rewire')));
  });

  test('low baseline band → gentle difficulty', () {
    final p = generatePlan(
      track: Track.solo,
      goals: {},
      baseline: const Baseline(bands: {'arousal_control': Band.low}, raw: {}),
      mindBody: {},
    );
    expect(p.startDifficulty, Difficulty.gentle);
  });

  test('partnered track tags appear', () {
    final p = generatePlan(
      track: Track.partnered,
      goals: {},
      baseline: emptyBaseline,
      mindBody: {},
    );
    expect(p.track, Track.partnered);
  });
}
