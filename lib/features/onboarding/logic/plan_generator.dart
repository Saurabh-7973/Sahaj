import '../onboarding_controller.dart' show Goal;
import 'models/onboarding_models.dart';

/// Rule-based 12-week plan (synthesis §7). One spine + modifiers:
/// persona→track content tags, goals→emphasis, baseline band→start difficulty.
Plan generatePlan({
  required Track track,
  required Set<Goal> goals,
  required Baseline baseline,
  required Map<String, Band> mindBody,
}) {
  final trackTag = track == Track.partnered ? 'partnered' : 'solo';

  // §7 spine.
  final spine = <PlanWeek>[
    for (var w = 1; w <= 4; w++)
      PlanWeek(number: w, phase: 'Foundation', moduleTags: [
        'anatomy',
        'pfmt_identify',
        'reverse_kegel_intro',
        'breathwork_basics',
        trackTag,
      ]),
    for (var w = 5; w <= 8; w++)
      PlanWeek(number: w, phase: 'Integration', moduleTags: [
        'kegel_reverse_combined',
        'stop_start',
        'sensate_$trackTag',
        'mindset_dopamine',
        trackTag,
      ]),
    for (var w = 9; w <= 12; w++)
      PlanWeek(number: w, phase: 'Mastery', moduleTags: [
        'pfmt_functional',
        'mental_rehearsal',
        track == Track.partnered ? 'partner_communication' : 'first_encounter_readiness',
        trackTag,
      ]),
  ];

  // Goal → emphasis tags.
  final emphasis = <String>{};
  for (final g in goals) {
    switch (g) {
      case Goal.finishTooQuick:
        emphasis.addAll(['stop_start', 'reverse_kegel']);
      case Goal.hardness:
        emphasis.add('arousal_confidence');
      case Goal.firstTimeOrGap:
        emphasis.add('readiness');
      case Goal.pornRelationship:
        emphasis.add('dopamine_rewire');
      case Goal.lastLongerOptimize:
        emphasis.add('advanced_control');
      case Goal.exploring:
        break;
    }
  }

  // Baseline band → difficulty: any low band → gentle ramp.
  final hasLow = baseline.bands.values.any((b) => b == Band.low);
  final difficulty = hasLow ? Difficulty.gentle : Difficulty.standard;

  return Plan(
    weeks: spine,
    track: track,
    emphasis: emphasis,
    startDifficulty: difficulty,
  );
}
