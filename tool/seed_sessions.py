#!/usr/bin/env python3
"""Seed assets/content/sessions.json with the real 12-week pelvic-floor
program copy from sahaj_handoff/session_scripts/session_scripts_ALL.md.

Approach (confirmed with Saurabh — "variants by week"):
- The shared **Settle** (2:00) and **Down-regulate** (2:00) blocks are written
  in full in Week 1 and reused verbatim on every session, all weeks.
- Each session = Settle + the week's Core work + Down-regulate.
- The weekly progression rides the scheduler's `_v2/_v3/_v4` variant rotation:
  a phase's headline tag carries that phase's four weeks (base, _v2, _v3, _v4).
- Only the pelvic-floor journey tags are touched here; content domains the
  scripts don't cover (sensate, mindset/dopamine, arousal, etc.) keep their
  existing entries.
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SESSIONS = ROOT / "assets" / "content" / "sessions.json"

# ── Shared blocks (verbatim, Week 1) ─────────────────────────────────────────
SETTLE = {
    "title": "Settle",
    "seconds": 120,
    "guidance": (
        "Sit however you're comfortable — a chair, the edge of a bed. Let "
        "your shoulders drop. Rest one hand on your belly. Breathe in slowly "
        "through your nose, and let the belly rise into your hand — not the "
        "chest. Now let it out, slow and long, like a quiet sigh. Again. In, "
        "the belly rises... out, longer than the in. With each out-breath, "
        "let a little more go — your jaw, your shoulders, the area between "
        "your sit bones."
    ),
    "pattern": {"kind": "breath", "inhale": 4, "exhale": 6},
}

DOWNREG = {
    "title": "Down-regulate",
    "seconds": 120,
    "guidance": (
        "Stop lifting now. Let everything down there go heavy and soft — more "
        "relaxed than when you started. A few more slow breaths, long "
        "out-breaths. Nothing to do here, nothing to achieve. Just sitting, "
        "breathing, calm. That's the session."
    ),
    "pattern": {"kind": "breath", "inhale": 4, "exhale": 6},
}


def hold(h, r):
    return {"kind": "holdRelease", "hold": h, "release": r}


def session(title, type_, *core_steps):
    return {
        "title": title,
        "type": type_,
        "steps": [SETTLE, *core_steps, DOWNREG],
    }


def step(title, seconds, guidance, pattern=None):
    s = {"title": title, "seconds": seconds, "guidance": guidance}
    if pattern:
        s["pattern"] = pattern
    return s


# ── The journey, tag → SessionDef ────────────────────────────────────────────
SEED = {}

# Foundation headline: pfmt_identify (Weeks 1–4)
SEED["pfmt_identify"] = session(
    "Finding the muscles", "kegel",
    step("Locate", 120,
         "We're going to find the pelvic floor. Imagine you badly need to "
         "pass gas and have to hold it in — that small internal lift. Or the "
         "muscles you'd use to stop yourself peeing midstream (only to find "
         "them — don't make a habit of it). That gentle draw up and in — "
         "that's the muscle. Keep it small. We're learning the feeling, not "
         "lifting anything heavy. And keep breathing."),
    step("Gentle holds", 240,
         "On your next out-breath, lift — just a little. On the in-breath, "
         "let it go. All the way, completely soft. Feel that difference: "
         "lifted... and fully let go. The letting-go is half the skill — "
         "maybe the more important half. A few of these, no rush, generous "
         "rest between each. If you can barely feel anything yet, that's "
         "completely normal — it's week one."),
)
SEED["pfmt_identify_v2"] = session(
    "Two gears", "kegel",
    step("Slow holds", 130,
         "First gear — slow holds. On the out-breath, lift small and clean. "
         "Hold gently for about 4 seconds, breathing through the hold. "
         "Release on the in-breath, all the way, and rest about 6 seconds. "
         "Belly, glutes and thighs stay soft — only the floor works. About "
         "six, no rush, full release every time.",
         hold(4, 6)),
    step("Quick flicks", 110,
         "Second gear — quick flicks. Fast: squeeze and let go right away, "
         "like flicking a switch on then off. Don't time these to your "
         "breath — too quick for that. Just keep breathing normally. Even "
         "fast, the let-go has to be complete. Squeeze, full release. About "
         "eight. If it gets muddy after a few, stop there — the fast fibres "
         "tire quickly at first.",
         hold(1, 1)),
)
SEED["pfmt_identify_v3"] = session(
    "The elevator", "kegel",
    step("The elevator", 180,
         "We add control to the slow gear. Think of the lift like an "
         "elevator with a few floors. On the out-breath, lift gently to "
         "floor one — pause. A bit more, floor two — pause. Up to floor "
         "three, your comfortable max, still small, still breathing — hold a "
         "couple of seconds. Now the part that matters most: come back down "
         "in the same steps. Don't drop. Floor two... pause... floor one... "
         "all the way to the bottom, soft. Lowering slowly, in control, is "
         "its own skill — the opposite of gripping.",
         hold(6, 8)),
    step("Quick flicks", 90,
         "Now the fast gear, unchanged. Crisp on, full off, breathing free, "
         "not synced. Two short rounds of about ten. Then try one round "
         "standing — same muscle, it feels a little different upright, and "
         "that's normal.",
         hold(1, 1)),
)
SEED["pfmt_identify_v4"] = session(
    "Your routine + the knack", "kegel",
    step("Your routine", 150,
         "Last week of the foundation. You know these now, so run them at "
         "your own pace: a few elevators — up in steps, slowly down, sitting. "
         "A round of quick flicks. Then the same, standing. Find your own "
         "rhythm. If you've landed on a version that feels right, trust it.",
         hold(5, 6)),
    step("The knack", 150,
         "The knack is timing a contraction to a moment, before it happens, "
         "not after — a gentle lift just before you cough, or as you stand "
         "up. Sit forward. Just before you rise, lift the floor gently. Hold "
         "it as you stand. Let go once you're up. Anticipate... contract... "
         "hold through the moment... release after. Bringing it in ahead of "
         "the moment is what turns this from an exercise into control you can "
         "actually use."),
)

# Foundation supporting tags
SEED["anatomy"] = session(
    "How it works", "education",
    step("The ground rules", 180,
         "A few honest ground rules before any training. Small and gentle "
         "wins — a harder squeeze is not a better one. A pelvic floor that's "
         "always clenched causes more trouble than a weak one, so we train "
         "the release as carefully as the lift. It should never hurt: if "
         "anything causes pain, stop — that's a sign to ease off, or to check "
         "with a doctor. The 'stop your pee' idea is only for finding the "
         "muscles, not an exercise. And every session can be done sitting "
         "still, fully dressed, breathing normally — no one would notice. "
         "That's by design."),
)
SEED["reverse_kegel_intro"] = session(
    "Learning to let go", "reverseKegel",
    step("Full release", 220,
         "This week is as much about letting go as lifting. Lift the floor "
         "small on the out-breath — then, on the in-breath, release it "
         "completely, all the way to soft. The release is the skill. Notice "
         "the difference between a gentle hold and a full, easy let-go. If "
         "the release feels harder than the lift, that's exactly the thing "
         "worth practising. Gentle throughout — never a forceful push."),
)
SEED["breathwork_basics"] = session(
    "The longer exhale", "breathwork",
    step("Lengthen the out-breath", 240,
         "Breathe in slowly through the nose for about four, letting the "
         "belly rise — then out, slow and long, for about six. Longer out "
         "than in. This calms the whole system and softens the pelvic floor "
         "with it. Keep going at your own pace; with each out-breath let a "
         "little more tension go.",
         {"kind": "breath", "inhale": 4, "exhale": 6}),
)

# Build headline: kegel_reverse_combined (Weeks 5–8)
SEED["kegel_reverse_combined"] = session(
    "Longer holds + hold-and-pulse", "kegel",
    step("Endurance holds", 150,
         "Welcome to the build phase — the foundation was real and complete; "
         "now we load it a little. Lift small and hold for about 6 seconds, "
         "breathing the whole way, then lower in control — down in stages, "
         "never a drop. About eight, resting between. If the lift creeps "
         "bigger to keep the hold going, keep it small and let it be a "
         "shorter hold instead.",
         hold(6, 6)),
    step("Hold and pulse", 150,
         "A new pattern. Lift to a comfortable base hold — about half your "
         "max — and keep it steady. On top of it, add a few quick pulses: up "
         "and back to the base, without losing the base. Pulse... pulse... "
         "pulse... the base never drops. Then lower the whole thing slowly. "
         "The base staying put while you pulse is the skill. About four, with "
         "good rests — this one's taxing.",
         hold(2, 4)),
)
SEED["kegel_reverse_combined_v2"] = session(
    "Lengthening + contrast", "reverseKegel",
    step("Keep the strength ticking", 90,
         "A short bit of lifting first to keep what you've built — a few easy "
         "endurance holds, about 5 seconds, lift small, breathe, lower in "
         "control. Just five or six. We're maintaining today, not pushing.",
         hold(5, 5)),
    step("Lengthening — gently", 150,
         "Gentle only — this is a soft letting-go, never a hard push. If "
         "you're straining or bearing down with force, ease right off; it "
         "should feel like more relaxation, not effort. On the in-breath, as "
         "the belly expands, let the floor gently lengthen and soften "
         "downward, as if quietly opening. On the out-breath, return to soft "
         "neutral — not a lift. The feeling is subtle. No pushing, no force. "
         "If anything hurts or feels like pressure, stop."),
    step("The contrast", 120,
         "Now feel the whole range. Gently lift — a small kegel. Back to "
         "neutral. Now gently lengthen and open — down. Back to neutral. "
         "Up... neutral... down... neutral. Smooth, no force in either "
         "direction. Strength without the ability to fully let go isn't the "
         "goal — now your muscle can do both."),
)
SEED["kegel_reverse_combined_v3"] = session(
    "Peak holds + movement", "kegel",
    step("Peak endurance holds", 170,
         "The holds reach their full length this week. Lift small, hold for "
         "about 8 to 10 seconds, breathing the whole way, then lower in "
         "control — never a drop. Rest as long as you held. About eight. The "
         "temptation at this length is to grip harder and hold your breath — "
         "don't. Keep the lift small; if you can't breathe through it, it's "
         "too big, so shorten the hold.",
         hold(9, 9)),
    step("Supple check", 90,
         "Don't lose last week's work. A few gentle lengthens: in-breath, let "
         "the floor lengthen and open; out-breath, neutral. Gentle, no force. "
         "Just three or four, to keep the door open in both directions. Then "
         "out in your day, keep the floor gently present as you walk — "
         "engaged for a stretch, breathing normally, then let it go."),
)
SEED["kegel_reverse_combined_v4"] = session(
    "Your complete routine", "kegel",
    step("The full routine", 220,
         "You have every piece now — today we run them as one routine. A few "
         "full-length endurance holds, 8 to 10 seconds, controlled down — "
         "about five, keeping your strength, not chasing more. Then "
         "hold-and-pulse: steady base, a few pulses on top, slow down — about "
         "three. Then quick flicks, crisp on and full off, about ten. And a "
         "supple check — a few gentle lengthens, in-breath open, out-breath "
         "neutral.",
         hold(9, 9)),
    step("Strong, quick, supple", 120,
         "That's the whole thing — strong, quick, and supple in one short "
         "routine. Two pieces live in your day, not in here: the knack before "
         "a cough or standing up, and keeping the floor gently present as you "
         "move. And one idea that matters: you don't have to do all of this, "
         "all-out, every day to keep it. Steady and sustainable holds far "
         "better than hard and brittle."),
)

# Build supporting / emphasis tags
SEED["advanced_control"] = session(
    "Peak holds", "kegel",
    step("Full-length holds", 200,
         "Strength at its peak: lift small, hold for about 8 to 10 seconds, "
         "breathing the whole way, then lower in control — never a drop, rest "
         "as long as you held. Keep the lift small; if you can't breathe "
         "through it, it's too big. A few rounds, generous rest.",
         hold(9, 9)),
    step("Hold and pulse", 120,
         "Keep the combo sharp: a steady base hold with a few quick pulses on "
         "top, the base never dropping, then a slow controlled descent. About "
         "three, with good rests.",
         hold(2, 4)),
)
SEED["reverse_kegel"] = session(
    "Lengthening", "reverseKegel",
    step("The other direction", 180,
         "Gentle only — a soft letting-go, never a hard push. On the "
         "in-breath, as the belly expands, let the floor lengthen and soften "
         "downward, as if quietly opening. On the out-breath, return to soft "
         "neutral. The feeling is subtle, a gentle downward release. No "
         "pushing, no force, keep breathing. If anything hurts or feels like "
         "pressure, stop."),
    step("Lengthen and rest", 120,
         "Lengthen the floor and stay there for a couple of slow breaths — "
         "resting at the open, soft end of the range. Then ease back to "
         "neutral. This is the half of control most programs skip: being able "
         "to fully let go, on purpose."),
)
SEED["down_training"] = session(
    "Down-training", "reverseKegel",
    step("Gentle lengthening", 200,
         "If your floor runs tight, this is the work that helps most — and "
         "it's gentle by design. Never a forceful bearing-down. On the "
         "in-breath, let the floor lengthen and soften downward, as if "
         "quietly opening; on the out-breath, return to easy neutral. Slow, "
         "breath-led, fully relaxed, long pauses. If you're straining or red "
         "in the face, you've gone too far — ease right off. It should feel "
         "like more relaxation, not effort."),
    step("Lengthen and rest", 140,
         "Let the floor lengthen and stay there for a few slow breaths, "
         "resting at the soft, open end. Next time you notice you're clenched "
         "— jaw, shoulders, or down there — try a conscious lengthen and "
         "release, right then. That's down-training where it actually "
         "matters. Please get this looked at by a doctor or pelvic-floor "
         "physiotherapist when you can."),
)
SEED["down_training_v2"] = session(
    "Lengthen + contrast", "reverseKegel",
    step("Find the whole range", 200,
         "Gentle only, no force in either direction. Gently lift a small "
         "kegel, back to neutral; now gently lengthen and open downward, back "
         "to neutral. Up... neutral... down... neutral, smooth and easy. "
         "Spend most of your time at the lengthening end — that's the side "
         "that needs the practice. Keep breathing; stop if anything hurts."),
)

# Integrate headline: pfmt_functional (Weeks 9–12)
SEED["pfmt_functional"] = session(
    "On demand + presence", "kegel",
    step("On demand — no warm-up", 150,
         "Real moments don't wait for you to get ready. Right now, cold, "
         "engage the floor — gently, cleanly. And release, fully. Again, no "
         "ramp-up. Engage... release. Quick to answer, clean to let go. A few "
         "of these at random intervals, then a couple of flicks and one long "
         "hold just to keep things ticking.",
         hold(2, 4)),
    step("Presence — control without bracing", 150,
         "The skill that counts when it's real. Engage the floor gently — and "
         "at the same time check the rest of you: jaw loose, shoulders down, "
         "breath easy. Control in one place, relaxed everywhere else. That "
         "combination — calm body, gentle control — is worth more than any "
         "strong squeeze. Hold it a moment... and let go. Out in your life, "
         "use it in the moments that matter; the everyday steadiness and the "
         "calm are the whole point."),
)
SEED["pfmt_functional_v2"] = session(
    "Anchors + your plan", "kegel",
    step("The maintenance dose", 130,
         "Keeping what you've built takes far less than building it did. A "
         "short run of the essentials is plenty: a few holds, a round of "
         "flicks, a couple of gentle lengthens. That's enough to hold what "
         "you've got — you don't need the full build phase forever.",
         hold(6, 6)),
    step("Anchoring", 170,
         "The real skill is anchoring: tie a small dose to something you "
         "already do every day, so the cue does the remembering for you. "
         "Quick flicks while you brush your teeth. A couple of holds while "
         "the kettle boils. The knack every time you stand up. A gentle "
         "engage each time you walk through a doorway. Pick one and say it: "
         "'every time I ____, I'll ____.' Over this week, settle on two or "
         "three anchors and the handful of elements you'll keep. That's your "
         "maintenance plan."),
)
SEED["pfmt_functional_v3"] = session(
    "For the hard parts", "kegel",
    step("Keep it ticking", 110,
         "First, a light maintenance run: a few holds, a round of flicks, a "
         "couple of gentle lengthens. Brief is fine — that's the point of "
         "maintenance.",
         hold(6, 6)),
    step("Three honest things", 240,
         "Plateaus are normal — after the early gains, progress slows; that "
         "isn't failing, it's what training does. Don't grind harder; trust "
         "the maintenance. Falling off is recoverable — you'll miss days, "
         "maybe weeks, and that's nothing to feel bad about. When you come "
         "back, drop back a couple of weeks and rebuild gently; the muscle "
         "remembers and returns faster than it took to build. And the honest "
         "one: this helps a lot, but it doesn't fix everything. If you've "
         "practised consistently and something still isn't improving, or "
         "there's pain, or something feels off — that's a doctor, not more "
         "training. Seeing a doctor is the strong move. The warning-signs "
         "article walks through this carefully."),
)
SEED["pfmt_functional_v4"] = session(
    "Yours to run", "kegel",
    step("Run your routine", 240,
         "Last week of the program — not the last week of the practice. I'm "
         "not going to call the parts this time; you don't need me to. "
         "Whatever shape it's become — the full version or your maintenance "
         "plan — run it yourself, start to finish. Take the whole block.",
         hold(8, 8)),
    step("Yours now", 120,
         "That's the thing you'll carry out of here — it's yours now, "
         "completely. The program ends in a few days; the practice doesn't. "
         "You've got your plan, your anchors, your gentle way back if you "
         "ever fall off, and the sense to know when something's a doctor's "
         "job. That's a complete set. You're ready to keep this without a "
         "program telling you to."),
)


def main():
    data = json.loads(SESSIONS.read_text())
    before = len(data)
    data.update(SEED)
    SESSIONS.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    print(f"tags: {before} -> {len(data)} ( +{len(data)-before} new, "
          f"{len(SEED)} seeded )")


if __name__ == "__main__":
    main()
