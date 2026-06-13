import '../onboarding_controller.dart' show Goal;

/// C10 personalized lines (M4 spec §1 / decision #2). Each line ties to a
/// real goal the user picked — `Because you chose "X", …`. Generated from
/// goals only; we show at most two and never pad. Order follows the goal
/// enum so the output is stable.
///
/// The two tone examples in the spec/mock are `firstTimeOrGap` and a
/// "calmer before and during" goal; the remaining lines are written to the
/// plan engine's actual week-5–12 adaptations (stop_start / reverse_kegel,
/// arousal_confidence, dopamine_rewire, advanced_control).
const Map<Goal, ({String choice, String effect})> _lineByGoal = {
  Goal.finishTooQuick: (
    choice: 'finish sooner than you want',
    effect: 'weeks 5–8 lead with stop-start and release work.',
  ),
  Goal.hardness: (
    choice: 'unreliable erections',
    effect: 'arousal-confidence drills run through Integration.',
  ),
  Goal.firstTimeOrGap: (
    choice: 'first-time ready',
    effect: 'weeks 5–12 build readiness, not repair.',
  ),
  Goal.pornRelationship: (
    choice: 'real-life response',
    effect: 'the plan adds dopamine-rewiring sessions from week 5.',
  ),
  Goal.lastLongerOptimize: (
    choice: 'general control and fitness',
    effect: 'Mastery weeks sharpen advanced control.',
  ),
  Goal.exploring: (
    choice: 'to get better',
    effect: 'the plan stays broad and adapts as you go.',
  ),
};

/// Up to two `Because you chose "…", …` lines for the plan reveal.
List<String> planRevealLines(Set<Goal> goals) {
  final lines = <String>[];
  for (final goal in Goal.values) {
    if (lines.length >= 2) break;
    if (!goals.contains(goal)) continue;
    final entry = _lineByGoal[goal];
    if (entry == null) continue;
    lines.add('Because you chose "${entry.choice}", ${entry.effect}');
  }
  return lines;
}
