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
// DECISION #5 (resolved): the handoff's six new lines were keyed to goal
// *labels* (Control/Erections/Confidence/Calm/Foundation/Partner) that don't
// exist in [Goal]. Rather than break the honesty frame (`Because you chose
// "X", …` ties each line to a pick the user actually made) or orphan the
// themes with no goal home, we keep the frame + enum mapping and lift the new
// copy's warmer tone into the effect clause. Confidence/Calm fold into the
// erections + control lines; the partner line is dropped (the program is
// persona-agnostic — no partnered goal exists).
const Map<Goal, ({String choice, String effect})> _lineByGoal = {
  Goal.finishTooQuick: (
    choice: 'finish sooner than you want',
    effect: 'we build control the way it actually holds — steady reps you '
        'own, not a trick you have to keep pulling off.',
  ),
  Goal.hardness: (
    choice: 'unreliable erections',
    effect: 'we start with the foundations an erection rests on — '
        'steadiness, calm, a body you trust — at the pace of real change.',
  ),
  Goal.firstTimeOrGap: (
    choice: 'first-time ready',
    effect: "you're building a strong base on your own terms — readiness, "
        'not repair.',
  ),
  Goal.pornRelationship: (
    choice: 'real-life response',
    effect: 'the plan rewires toward real arousal — ease over intensity, '
        'from week 5.',
  ),
  Goal.lastLongerOptimize: (
    choice: 'general control and fitness',
    effect: 'Mastery weeks sharpen advanced control — we take the pressure '
        'down first, not up.',
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
