# Screen Spec — Module 3: Me / Progress & Check-ins

> **Build order:** #3
> **Mockup files (ground truth):** `m3_01_dashboard_wk3.html` · `m3_02_dashboard_wk5.html` · `m3_03_dashboard_wk1.html` · `m3_04_checkin.html`
> **Routes:** `/me` (tab) · `/checkin` (intro → questions → result) — question screens reuse the C6/C8 single-question template verbatim; no new question UI exists in this module.
> **State:** Riverpod — `progressProvider` (pure read of logs + check-in store), `checkinProvider` (instrument flow + write).
> **Rule:** mockup wins on visuals; undefined behavior → Decisions Needed; never invent.

---

## 0. The honesty doctrine (module law)

1. **Source tags are mandatory.** Every chart carries `from your session logs` / `from your sessions` / `from your check-ins`, right-aligned caption. No untagged data anywhere on this tab.
2. **No projections, no derived scores.** Nothing is extrapolated, predicted, or composited into a "strength score." If it wasn't logged or answered, it doesn't render.
3. **Outcomes never appear without inputs.** Any delta display is accompanied by the behavioral recap that drove it (sessions · minutes · days), source-tagged.
4. **Down or flat is never alarm.** Flat = faint em-dash + "no change — one measurement, not a verdict." A dip uses the same faint treatment with "dipped this round — one measurement, not a verdict." Never red, never ▼ in color, never explanation-spin (no invented clinical reasons — see Decisions #3).
5. **The footer line ships on every dashboard state:** *"We never estimate. Every number here is something you did or told us."* Fraunces italic, sand.

## 1. The growth rule — cards earn existence

| Element | Appears when | Sparse behavior |
|---|---|---|
| Journey spine | always (plan exists) | wk-1 caption: "your week-0 mark is set" |
| Stat tiles | after first session | values may equal each other early; fine |
| Consistency grid | after first session | starts as **one row (this week)**, grows a row per week to 4, then slides; growth caption shown until row 2 exists |
| Practice volume | after first session | a single bar stands alone, no apology copy |
| Check-ins card | **always** | the wk-0 dot is lit from onboarding — the chart is never a void, it's a promise with its first point placed |
| Privacy / Subscription tiles | always | — |

Card order: spine → stats → consistency → volume → check-ins, **except** once outcome data exists (first check-in complete), check-ins moves above volume (m3_02). The one reorder the tab ever does.

**Cut:** the reflection-trend strip. Effort data feeds Today's why-line (M2 grammar) instead of decorating a chart.

## 2. Dashboard states

- **Week 1, day 2 (`m3_03`):** sparse-never-empty. Spine seg 1 lit; grid = one row; one bar; wk-0 dot lit with caption "Week 0 is already on the board — you set it during setup."
- **Weeks 1–4 / silent weeks (`m3_01`):** behavioral truth leads; check-in card shows lit wk-0 + dashed futures + "Your week-4 check-in unlocks the first comparison — measured, not guessed."
- **Post-check-in (`m3_02`):** two points joined by a gradient line; passed milestone diamond turns moss; phase label gains `✓`; card border warms (ochre 30%) + `first comparison` chip; delta caption format: `Control +2 · Confidence +1 — on your own week-0 scale. Small movements, really measured.`
- **Gap weeks:** nothing changes color; missed days are simply unfilled (already the grid's nature). No annotations.

## 3. Check-in flow (`m3_04`)

**Entry:** milestone completion CTA (M1) only; deferred check-ins re-surface at the next completion. Never on Today, never via notification.

**Intro:** diamond medallion (the spine's milestone glyph, made large — measurement as ceremony) → eyebrow `WEEK 4 CHECK-IN` → H1 "Same questions as week 0." → body: "Two minutes. Answer how it is — not how you hope. The comparison only works if both ends are honest." → chips `2 min · 6 questions · just you` → `[Begin]` + ghost `Tomorrow`.

**Questions:** C6/C8 template, persona-calibrated battery, identical item wording to week 0 (validated-instrument rule from Part K stands).

**Result (deep background — a ceremony, like completion):** eyebrow `WEEK 4 · MEASURED` → enlarged two-point chart card → domain rows (name + delta in Fraunces numerals; up = gold ▲, flat/dip = faint per doctrine §0.4) → **input recap card** (moss-tinted): "What you put in" + chips `24 sessions · 96 minutes · 18 of 28 days`, source-tagged → honesty line → `[Done]` → returns to dashboard scrolled to the check-ins card (now reordered).

**Data:** `checkin: {week, domainScores{}, completedAt}` — domain scores stored raw; deltas computed at render, never stored.

## 4. Don'ts

No percentile or other-user comparison (local-only anyway; never fake social proof). No "strength score." No red anywhere including dips. No celebratory copy on good deltas beyond the standing format — the numbers are the celebration. No locking any chart behind Pro (Part K flag 7: the dashboard is 100% free, forever). Persona Zero test: domain names must read clean for solo trainees ("Control", "Confidence" — never partner-implying labels on shared surfaces).

## 5. Acceptance criteria

Five global tests, plus: every chart TalkBack-readable as a sentence ("Check-ins: week 0 score set, week 4 up two, on your own scale") · grid AA at all three moss intensities · count-up/line-draw animations 400ms, instant under reduced-motion · dashboard renders correctly at every week 1–12 with zero, partial, and full data (golden tests per state) · result screen reachable only via milestone completion.

## 6. Decisions needed (flagged, not invented)

1. **Delta display granularity.** Mock shows `+2` with "on your own week-0 scale" — confirm whether to expose the instrument's actual scale range, or keep relative-only (recommended: relative-only; raw clinical scores medicalize).
2. **Domain set per persona.** "Control / Confidence / Morning signs" shown for the partnered-PE persona — confirm the per-persona domain mapping from the plan engine (Persona Zero battery likely swaps "Morning signs" placement).
3. **Dip/flat explanatory copy.** Doctrine bans invented clinical reasons. If `synthesis.md` contains an evidence-backed line about week-4 awareness-before-control effects, it may be used verbatim with that grounding; otherwise the generic "one measurement, not a verdict" stands.
4. **Subscription tile content.** Plain label (as mocked) vs current-tier display — confirm against Module 7 before wiring.
