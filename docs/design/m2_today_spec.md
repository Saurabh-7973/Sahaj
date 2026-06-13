# Screen Spec — Module 2: Today

> **Build order:** #2 (consumes Module 1's language; the daily front door)
> **Mockup files (ground truth for visuals):** `m2_01_today_default.html` · `m2_02_today_done.html` · `m2_03_today_day0.html` · `m2_04_today_gap_return.html`
> **Route:** `/today` (default tab)
> **State:** Riverpod — `todayProvider` (reads plan engine + session logs + settings). Today writes nothing; it is a pure read of the day.
> **Rule:** mockup wins on visuals; undefined behavior goes to Decisions Needed — never invent.

---

## 0. Module-wide rules — the doorway doctrine

- **One hero.** The session card is the only element with CTA energy. Everything else whispers. No second button competes with Start, ever.
- **The spine is cut.** Today carries no 12-week spine — it was a second progress readout competing with the week dots, and dashboards live in Me. (m1_01 backgrounds updated to match.) Week position survives only as the top-right chip: `WK 3 · Integration`.
- **Two-tap rule.** Open → Start → (mood sheet) → training. Start sits above the fold, in the thumb arc, on every state that has it.
- **No dashboard creep.** No charts, no stats beyond the steady tile, no check-in cards (check-ins surface at completion only, per M1 spec), no tab badges or red dots — the reminder notification is the only summons this app ever sends.
- **Greeting logic:** before 12:00 "Good morning." · 12:00–17:00 "Good afternoon." · after 17:00 "Good evening." No cleverness at 2 AM — the man training at 2 AM doesn't need commentary. Never a name (privacy default).
- **Date eyebrow:** `THURSDAY · 11 JUNE` (weekday + day + month; confirm locale format under Decisions).

## 1. The why-line grammar — the coach voice

One sentence, ≤90 characters, plan-context only (mood context lives in the M1 prescription echo, never duplicated here). Templates:

| Day | Why-line |
|---|---|
| Normal progression | "Builds on yesterday's holds — slightly longer, same breath." |
| After a Harder reflection | "Yesterday ran harder — tonight holds steady instead of adding." |
| Week start | "Week 5 opens stop-start work — everything so far was for this." |
| Milestone day (wk 4/8/12 last session) | "Week 4's last session — the check-in unlocks after." |
| Day 0 | "No payment, no signup — just your first seven minutes." |
| Gap return | "{N} days away — tonight restarts a notch gentler. The plan moved with you." |

Rules: states facts the plan engine actually did; never motivational filler ("You've got this!" is banned); never references the gap after the return day itself.

## 2. Default state — `m2_01a`

**Layout (top→bottom):** date eyebrow + week chip → greeting H1 → hero card (lotus watermark · chips: type / duration / `day N` · H2 session title · why-line · mood micro-row "adjusts to how you arrive" with the open-mood glyph · Start 52dp) → This-week card (label + `N done` + 7 lettered dots: done=moss, today=ochre ring, upcoming=faint) → Steady-days card (lotus medal · label · `longest N` · numeral in moss) → nav.

**Behavior.** Start opens the M1 mood sheet (then echo → player). The mood micro-row exists only pre-check-in; after a skip-mood start it never reproaches.

## 3. Hidden-streak variant — `m2_01b`

Settings → Hide steady days: the tile is **absent** — no gap, no placeholder, no "hidden" label, layout simply reflows. The week card is unaffected (consistency ≠ streak). The app never comments on the user's privacy choices.

## 4. Done state — `m2_02`

Hero swaps to the moss card: lotus-tick medal (glow) · "Done for today" · "Rhythm beats intensity — see you tomorrow." · **tomorrow chips** (`Tomorrow · Stop-start` + `9 min` — so a second open that day still answers a question) · quiet link "Free practice in the Library ›". Today's dot turns moss; steady numeral ticks up without animation fanfare (a single 200ms count-up, nothing more). No CTA energy anywhere.

## 5. Day 0 — `m2_03`

First open after onboarding. Same card grammar as any day — the first session is ordinary *on purpose* (chips: `breathwork · 7 min · first session`, the ok-chip's only appearance on Today). Week card reads `starts tonight` with all dots empty + today ringed. **No steady-days tile: it is earned into existence by the first completed session.** A zero with no history isn't honesty, it's just cold. The lamp empty-state illustration survives only for the true-empty edge case (data wiped, no plan) — never for day 0.

## 6. Gap return — `m2_04` (principle 8's proof screen)

After ≥N missed days (threshold from plan engine — Decisions #2), the plan recalibrates and Today shows it: week chip gains `plan adjusted`, hero chip `adjusted`, why-line states the gap as a fact and the adjustment as something done *for* him. Steady tile shows **0 in faint** (honest — never red, never moss, never "broken") with `longest 9` kept as the dignity anchor. Week card: `starts tonight`. No "welcome back!" theatre; the register never changes. The gap is mentioned exactly once — tomorrow's why-line returns to normal progression.

---

## Data read (never written)

`plan.todaySession` (type, duration, title, dayN, calibrationFlag) · `logs.weekCompletions` · `logs.steadyDays` + `logs.longestStreak` · `settings.hideStreak` · `plan.weekN/phase`.

## Don'ts

No name in the greeting. No spine. No second CTA. No guilt vocabulary in any state (QUITTR test). No partner or problem assumptions in any session title or why-line surfaced here (Persona Zero test — "hold work" yes, "last longer tonight" no). No badges on the tab bar. No pull-to-refresh (nothing to refresh; the day is the day).

## Acceptance criteria

The five global tests, plus: Start above the fold at 100% font scale and at +30% string length (Hindi room) · two taps from open to mood sheet · TalkBack order: greeting → session title → why-line → Start · done-state numeral count-up respects reduced-motion (instant) · gap-state colors AA (faint zero ≥ 4.5:1 on surface).

## Decisions needed (flagged, not invented)

1. **Weekly denominator.** Mock shows `3 done` (no denominator). If the protocol prescribes < 7 sessions/week in any phase, confirm whether to show `3 of 5` — needs the plan engine's weekly structure.
2. **Gap threshold.** How many missed days trigger recalibration + the `adjusted` state (2? 3?) — plan-engine constant; the copy template takes `{N} days away`.
3. **Date format.** `Thursday · 11 June` vs locale-driven — confirm against app-wide l10n approach before hardcoding.
4. **Free-practice link placement.** Currently done-state only. Confirm it should *not* appear pre-completion (it competes with Start) — recommendation: done-only, as mocked.
