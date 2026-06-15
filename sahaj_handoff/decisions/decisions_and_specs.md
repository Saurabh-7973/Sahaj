# Sahaj — Product Decisions & Specs (for Claude Code)

> The 16 decisions (with in-code defaults and Saurabh-facing recommendations), then the two that have full content specs: #1 (mood calibration) and #5 (plan-reveal lines).
>
> **Default behaviour:** every decision already ships on a sensible default. Apply the changes marked "CHANGE" below; leave the rest as-is unless Saurabh says otherwise.

---

## The 16 decisions

| # | Decision | Current default (in code) | Recommendation | File to change |
|---|----------|---------------------------|----------------|----------------|
| 1 | Mood→calibration for low/open | run unchanged (only heavy/level/charged calibrate) | **CHANGE** — implement deltas (see spec below) | `session_calibration.dart` |
| 2 | Gap-return threshold | `kGapThresholdDays = 3` | **CHANGE** — set to `4` | `today_logic.dart` |
| 3 | Per-persona check-in domains | derived from baseline (Control/Confidence/Calm; +Staying-power) | keep | `dashboard_logic.dart` |
| 4 | Delta display granularity | relative-only | keep | M3 |
| 5 | Plan-reveal lines | 6 mappings (2 spec, 4 new) | **CHANGE** — use the 6 lines below | `plan_reveal_lines.dart` |
| 6 | Free-session scope | Foundation base + variants free; rest Pro | keep (verify Foundation alone is a complete arc) | `feature_gate.dart` |
| 7 | Search scope | titles-only | keep | M5 |
| 8 | PIN length + lockout | 4 digits, no lockout | **CHANGE** — `kPinLength = 6`, keep no-lockout | `lock_controller.dart` |
| 9 | Panic gesture (two-finger → cover) | not adopted | keep deferred (v1.1; adopt only if cheap) | — |
| 10 | ₹1499 pay-it-forward line | ships as written | **CHANGE** — cut the ₹1499 tier + its copy unless a real grant mechanism exists | `pricing_tier.dart` |
| 11 | Trial length / eligibility | 7-day local trial, once granted | keep; mirror in Play config | Play config |
| 12 | Default reminder time | 21:30 | keep 21:30 — **but reconcile the 21:30 vs 20:00 spec/code discrepancy first** | `preferences_controller.dart` |
| 13 | "You can stop any time" clause | shown on holds 1–2 then drops | keep; confirm tone on a real read | M1 |
| 14 | Disguise alias label | "My Notes" | **CHANGE** — collides with stock Samsung/Xiaomi Notes; pick a non-colliding label | `strings.xml` |
| 15 | Heritage doctor-gate | outside medical gate, no badge | keep, conditional on heritage staying strictly claim-free | M5 policy |
| 16 | Related-session footer (read→do) | not adopted (needs a content field) | **CHANGE** — adopt, and add the content field **before seeding** | content model + seed |

Design confirms still open with Saurabh (not blocking; ship defaults): partnered track (scripts are persona-agnostic), free boundary (= end of Foundation, Week 4), localization (English-only at launch unless told otherwise).

---

## #1 — Mood calibration spec (`session_calibration.dart`)

The energy reads (heavy/level/charged) already flex *how much* the user does. `low`/`open` flex *framing and pressure*, not workload — so they don't double-count when a user lands on both.

- **`low` → soften, don't shrink.** Use the gentlest copy variant; suppress any "push / go further" prompts; open with a low-stakes line ("showing up is the whole win today"); cut the reflection to one light question. **Same exercises**, lower stakes.
- **`open` → offer, don't escalate.** Core session exactly as planned, then **one clearly-optional "go further" add-on** at the end (easy to skip) plus the fuller reflection prompt. **Never** auto-extend or raise difficulty.

**Caveat for the implementer:** this assumes mood is a separate axis from energy (energy: heavy/level/charged · mood: low/open), so they compose. If mood is actually a single scale, collapse the rule accordingly and confirm with Saurabh.

---

## #5 — Plan-reveal lines (`plan_reveal_lines.dart`)

Six lines keyed to goal. **Goal labels below are inferred** — map each to the actual goal enum key; if the keys differ, realign with Saurabh.

1. **[Control / last longer]** — "We build control the way it actually holds — steady reps you own, not a trick you have to keep pulling off."
2. **[Erections]** — "We start with the foundations an erection actually rests on — steadiness, calm, a body you trust — and move at the pace of real change, never pressure."
3. **[Confidence]** — "Confidence here isn't bravado; it's knowing your own body and trusting it. We build that quietly, one session at a time."
4. **[Calm / anxiety]** — "We take the pressure down first, not up. Get calm, and the rest comes easier."
5. **[Foundation / Persona Zero]** — "Nothing here needs fixing — you're building a strong base on your own terms, and honestly that's the best place anyone can start."
6. **[Partner / connection]** — "This is about ease as much as anything physical — the kind of steadiness that lets closeness feel unforced."
