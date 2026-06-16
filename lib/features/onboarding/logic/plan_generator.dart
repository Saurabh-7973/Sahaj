import '../onboarding_controller.dart' show Goal;
import 'models/onboarding_models.dart';

/// Rule-based 12-week plan (synthesis §7). One spine + modifiers:
/// persona→track content tags, goals→emphasis, baseline band→start difficulty.
Plan generatePlan({
  required Track track,
  required Set<Goal> goals,
  required Baseline baseline,
  required Map<String, Band> mindBody,
  PelvicFloorPattern pelvicFloor = PelvicFloorPattern.likelyWeak,
}) {
  final trackTag = track == Track.partnered ? 'partnered' : 'solo';

  // Goal → emphasis tags (computed first so they can personalise the plan).
  final emphasis = <String>{};
  for (final g in goals) {
    switch (g) {
      case Goal.control:
        emphasis.addAll(['stop_start', 'advanced_control']);
      case Goal.erections:
        emphasis.add('arousal_confidence');
      case Goal.anxiety:
        emphasis.add('down_training');
      case Goal.confidence:
        emphasis.add('arousal_confidence');
      case Goal.foundation:
        emphasis.add('readiness');
      case Goal.partner:
        emphasis.add('readiness');
    }
  }

  // §7 spine. Emphasis sessions personalise Integration + Mastery (Weeks 5-12);
  // the Foundation stays a consistent base for everyone.
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
        'expectations',
        trackTag,
        ...emphasis,
      ]),
    for (var w = 9; w <= 12; w++)
      PlanWeek(number: w, phase: 'Mastery', moduleTags: [
        'pfmt_functional',
        'mental_rehearsal',
        track == Track.partnered ? 'partner_communication' : 'first_encounter_readiness',
        trackTag,
        ...emphasis,
      ]),
  ];

  // Hypertonic (likely-tight) floor → relaxation-first v1 fallback (safety
  // pack §2): lead with down-training rather than strengthening, and always a
  // gentle ramp. The full program reorder (lengthening leads) is deferred to a
  // clinician pass; here we surface down-training early and soften the start.
  final tight = pelvicFloor == PelvicFloorPattern.likelyTight;
  if (tight) emphasis.addAll(['down_training', 'reverse_kegel']);

  // Baseline band → difficulty: any low band → gentle ramp; a tight floor is
  // gentle regardless.
  final hasLow = baseline.bands.values.any((b) => b == Band.low);
  final difficulty =
      (tight || hasLow) ? Difficulty.gentle : Difficulty.standard;

  return Plan(
    weeks: spine,
    track: track,
    emphasis: emphasis,
    startDifficulty: difficulty,
  );
}
