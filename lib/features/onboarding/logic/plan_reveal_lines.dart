import '../onboarding_controller.dart' show Goal;

/// C10 personalized lines (M4 spec §1 / decision #2). Each line ties to a
/// real goal the user picked — `Because you chose "X", …`. Generated from
/// goals only; we show at most two and never pad. Order follows the goal
/// enum so the output is stable.
// DECISION #5 (resolved) + reconcile B: the handoff's six lines are keyed to
// the goal taxonomy now adopted in [Goal] (control/erections/anxiety/
// confidence/foundation/partner), so each maps 1:1. The honesty frame
// (`Because you chose "X", …`) still ties every line to a pick the user
// actually made; the warmer handoff copy lives in the effect clause.
const Map<Goal, ({String choice, String effect})> _lineByGoal = {
  Goal.control: (
    choice: 'more control',
    effect: 'we build control the way it actually holds — steady reps you '
        'own, not a trick you have to keep pulling off.',
  ),
  Goal.erections: (
    choice: 'more reliable erections',
    effect: 'we start with the foundations an erection rests on — '
        'steadiness, calm, a body you trust — at the pace of real change.',
  ),
  Goal.anxiety: (
    choice: 'less anxiety around sex',
    effect: 'we take the pressure down first, not up — get calm, and the '
        'rest comes easier.',
  ),
  Goal.confidence: (
    choice: 'more confidence',
    effect: "it isn't bravado — it's knowing your own body and trusting it, "
        'built quietly, one session at a time.',
  ),
  Goal.foundation: (
    choice: 'a healthy foundation',
    effect: "nothing here needs fixing — you're building a strong base on "
        'your own terms, the best place anyone can start.',
  ),
  Goal.partner: (
    choice: 'to reconnect with a partner',
    effect: 'this is about ease as much as anything physical — the kind of '
        'steadiness that lets closeness feel unforced.',
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
