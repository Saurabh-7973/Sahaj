# Screen Spec — Module 1: The Session Loop

> **Build order:** #1 (this module sets the design language everything else inherits)
> **Mockup files (ground truth for visuals):** `m1_01_mood_checkin.html` · `m1_02_player_hold.html` · `m1_03_player_breath_paused.html` · `m1_04_player_facedown.html` · `m1_05_reflection.html` · `m1_06_completion.html`
> **Routes:** `/session/mood`, `/session/player`, `/session/reflect`, `/session/done`
> **State:** Riverpod — `moodCheckinProvider`, `sessionPlayerProvider`, `reflectionProvider`. Persistence: Hive, local only.
> **Rule:** when the mockup and this spec disagree on visuals, the mockup wins. When behavior is undefined, list it under Decisions Needed and stop — do not invent.

---

## 0. Module-wide rules

- **The deep room.** Player and completion screens use the darker `deep` background (mock: `.phone.deep`). The ring is the brightest object on screen; no surface exceeds it. The mood sheet and reflection use the standard background.
- **Semantic layering (player):** step bar = the session · "Hold 3 of 5" = the set · the ring = this rep. The ring's numeral counts the *phase's own seconds*, never clock time. Session time-remaining lives in the tiny `4:20 LEFT` line and nowhere else.
- **Phase color grammar:** ochre = effort (squeeze, active breath round), sand = rest/release, moss = breathwork sessions, grey-sand = paused. These are the only state colors in the loop.
- **Haptic cue language (global, on by default):**

| Pattern | Meaning | Fires |
|---|---|---|
| 1 tick | squeeze — begin hold | phase start |
| 2 ticks | release — let go | hold→rest transition |
| 1 long pulse | phase change | step boundary |
| 3 soft taps | session done | last step end |

- **Motion tokens:** phase crossfades 400ms; ring fill/drain continuous; breath scale 0.86↔1.00 sine matched to the step's pacing; completion bloom 700ms line-draw. Reduced-motion: breath scale → opacity pulse 70↔100%; bloom → fade.
- **Audio:** voice plays under the stepper when enabled; speaker toggle top-right persists per user. First audio session shows the earphones prompt once. Muting never breaks pacing (ring + haptics carry it).
- **Acceptance criteria, every screen in this module:** passes the shoulder-surf, Persona Zero, face-down, and QUITTR tests; TalkBack announces phase + seconds ("Squeeze, six seconds"); tabular numerals (no jitter); AA contrast on the deep background; keep-awake during play; interruption (call/lock) returns to the paused state exactly where it stopped.

---

## 1. Mood check-in (bottom sheet) — `m1_01`, phone A

**Purpose.** The threshold ritual. Two taps from Today into a calibrated session.

**Layout (top→bottom):** scrim over Today (Today content at 40% opacity) → sheet: drag handle → eyebrow `CHECK-IN` → H2 "How are you arriving tonight?" (time-aware: today/tonight) → 5 mood glyphs (Heavy · Low · Level · Open · Charged), multi-select max 3, selected = ochre-gradient fill + 1.1 scale → caption "Up to three. Nothing is logged anywhere but this phone." → `[Get tonight's session]` → ghost `Skip`.

**States.** Default (none selected → CTA disabled at 42% opacity) · 1–3 selected · Skip → default session, sheet dismisses.

**Data persisted.** `mood_log: {date, moods[]}` — feeds session calibration + nothing else.

**Don'ts.** No emoji. No "why do you feel this way" follow-ups. Never block Start behind mood — Skip always works.

## 2. Prescription echo — `m1_01`, phone B

**Purpose.** Close the loop: prove the mood pick changed something, in words.

**Layout.** Same sheet, content swaps (400ms crossfade): eyebrow `TONIGHT'S SESSION` → echo line, Fraunces italic, ochre: "You arrived heavy — shorter holds, longer breath tonight." → mini session card: chips (type · duration · `gentler tonight` when calibrated down) + session title + one delta line ("5 holds instead of 8 · exhale doubled") → `[Start]` → ghost `Change how I arrived`.

**Rule.** The echo line template is `You arrived {mood} — {concrete change} tonight.` If calibration produced no change, say so honestly: "You arrived level — tonight runs as planned." Never fabricate an adjustment.

**States.** Calibrated-down · calibrated-up (Charged → "one extra hold") · unchanged · skip-path (echo line omitted entirely).

## 3. Session player — `m1_02`, `m1_03`

**Purpose.** The external feedback loop for an invisible muscle. Pace me, correct my form, don't expose me.

**Layout (top→bottom):** audio toggle (top-right, 38dp) → eyebrow: session title → Title: "Hold 3 of 5" → step-segment bar (done = ochre 50%, active = gradient + glow, upcoming = sand 14%) → `4:20 LEFT · YOU CAN STOP ANY TIME` (tiny; the reassurance clause appears on holds 1–2 only, then drops) → ring 272dp centered in remaining space → guidance line (18.5/27, max 2 lines, crossfade per phase) → controls: prev 48dp · play/pause 84dp gradient · next 48dp → status chips (`haptics on` · `voice on/off`).

**Ring modes.**
- `holdPulse` (kegel/reverse-kegel): fills during squeeze (ochre gradient + blur glow pass), drains during release (sand, no glow). Center: phase word (11px, 0.34em tracking) over phase-seconds numeral (74px Fraunces light, tabular).
- `breath`: whole ring scales on the sine; stroke moss gradient; tick dial stays fixed (outside the scaling group). Center: breath word in Fraunces italic + dot-count caption. **No numerals in breath mode.**
- Guidance copy is form-correction, not cheerleading: "thighs loose, breath still moving" / "the release is half the rep."

**States.** squeeze · release · breath · **paused** (all chrome and ring to 42% opacity + grey-sand stroke; play button full warmth; copy "Paused — take your time." + "It picks up exactly here."; haptics suspended; no auto-resume) · resumed-after-interruption (= paused state on return).

**Data persisted.** Per-step completion timestamps, total hold-seconds, pause count (for volume metrics only — never surfaced as judgment).

**Don'ts.** No clock-time in the ring. No red, ever, including low-battery adaptations. No sound effects — voice or silence. No "don't quit" copy on pause or back.

## 4. Face-down mode — `m1_04`

**Purpose.** The moat: full sessions with the screen unseen. Coach once, then Ember.

**Coach screen (first session only):** eyebrow `FIRST SESSION · ONE-TIME` → H2 "You can do this with the screen off." → line illustration (figure reclined, phone face-down on chest, haptic arcs) → cue-legend card (4 rows: the haptic table above, dot pictograms) → `[Try it face-down]` → ghost `Maybe later`. Re-accessible from Settings → Daily rhythm.

**Ember screen:** near-black ground (`#0B0907`), status bar at 22% → centered: 12px ember (4s opacity/scale pulse, synced to nothing — it is presence, not pacing) inside a 7%-opacity progress arc (the only session readout) → bottom: "double-tap to wake" at 32% opacity. Total luminous area under ~2% of screen.

**Triggers.** Enter: device flipped face-down (proximity/orientation) OR the coach CTA. Exit: double-tap, or flipping face-up (returns to the live player in its current phase). Haptics continue uninterrupted across transitions.

**Don'ts.** Nothing else may appear on Ember — no title, no controls, no brand. If the OS kills the screen entirely, the session continues on haptics alone; Ember is the *peek* state, not a requirement.

## 5. Reflection — `m1_05`

**Purpose.** Progressive-overload calibration disguised as closure. ≤10 seconds.

**Layout.** Eyebrow `SESSION 14 · GENTLE HOLDS` → H2 "How did that feel?" → three equal cards (Easier / Same / Harder; slope glyphs in medallions; selected = same gold treatment regardless of answer) → one line under selection, only for Harder: "Harder is useful — tomorrow adjusts to it." → optional journal field ("Anything to note? Only you will ever see this.") → `[Done]` → ghost `Skip`.

**Data.** `reflection: {sessionId, effort, note?}` — effort feeds next-day calibration; note is never analyzed, never synced, export-only.

**Don'ts.** No mood faces. No streak mention. Journal never required, never prompted twice.

## 6. Completion — `m1_06`

**Purpose.** The feeling after riyaz. Reward = information + one moment of beauty.

**Standard:** ring closes → strokes bloom into the lotus (700ms line-draw) inside two faint ray rings → settles → `Done.` (54 Fraunces light) → info line "Session 14 · third this week." → chips: `Tomorrow · Stop-start` + `9 min` → pothi rule (180px, one of its four sanctioned placements) → `[Finish]` → returns to Today's done state.

**Milestone (weeks 4/8/12):** eyebrow `MILESTONE` → `Week 4, done.` → "Foundation complete — your first check-in is ready." → chips `2 minutes` + `measured, not guessed` → journey spine with the milestone diamond lit → `[Take the check-in]` + ghost `Tomorrow`. The check-in waits indefinitely; "Tomorrow" re-surfaces it on the next completion only.

**Don'ts.** No confetti, no sound, no share, no stacked acknowledgments, no streak-count theatrics. One screen, one breath, out.

---

## Decisions needed (flagged, not invented)

1. **Haptic primitives:** map the four cues to Android `VibrationEffect` compositions vs Flutter `HapticFeedback` presets — needs a device test for distinguishability at "in-pocket" intensity; patterns must read through a mattress.
2. **Face-down detection:** proximity sensor vs accelerometer-orientation vs both; fallback for devices without proximity = manual Ember button in the player overflow. Confirm sensor access doesn't require extra permissions on target API.
3. **Calibration deltas:** the exact mood→session adjustment table (which moods shorten holds, lengthen exhale, add a round) lives in the plan engine — confirm against `solo_dev_roadmap.md` before wiring echo copy.
4. **"YOU CAN STOP ANY TIME" clause:** shown on first two holds then dropped — confirm tone with one real-user read; cut entirely if it reads as permission-seeking rather than reassurance.
