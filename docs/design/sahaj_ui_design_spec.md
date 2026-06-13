# Sahaj — UI/UX Design Specification

v1.0 · June 2026 · Companion to `docs/synthesis.md` and `docs/solo_dev_roadmap.md`.
Drop into `docs/` as the source of truth for the UI pass. Written to be executed by
Claude Code section-by-section without re-litigating decisions. Anything marked
`[confirm]` should be diffed against built enums/copy before implementation; do not
ask, just reconcile toward what exists in code.

---

## Part A — Art direction: **"Lamplight"**

### A1. Concept

A private study by warm light. The user trains alone, usually at night, often in the
only private ten minutes his day has. The app should feel like that room: low warm
light, paper, a steady hand. Two layers:

1. **Lamplight** — the atmosphere. Deep warm brown darkness (not grey-black), ochre
   as lamplight, generous space, slow exhale motion. Calm ≠ empty: warmth comes from
   color temperature and rhythm, not decoration.
2. **Manuscript** — the lineage (per §10 of the brief). Quiet nods to the Indian
   textual tradition: pothi rule dividers, faint paper grain, line illustration
   derived from public-domain anatomical plates, Fraunces set like typeset ink.
   Manuscript warmth, never temple kitsch: no mandalas, no gold filigree, no deity
   imagery, no Sanskrit-as-wallpaper.

**Honest self-calibration:** "warm palette + serif display" is currently the most
generic wellness look in existence. What keeps Lamplight from being that template:
(a) dark-default, brown-not-cream; (b) the **breathing ring** as the signature
interaction (A6) — the progress ring is a breath pacer, not a timer skin; (c) a
**haptic cue language** that makes sessions followable with the phone face-down
(A6); (d) the pothi rule as the only ornament; (e) copy that is unusually plain and
honest (A8). Spend boldness on the ring; keep everything else quiet.

### A2. Color

Reconcile these targets with `lib/core/theme/` tokens — adjust hexes toward what
exists; the *roles* are the spec.

**Dark theme (default)**

| Role | Target | Notes |
|---|---|---|
| `bg` | `#191511` | Deep warm brown-black. Never pure black, never cool grey. |
| `surface` | `#221D17` | Cards, sheets. |
| `surfaceRaised` | `#2B241C` | Elevated cards, bottom sheets. |
| `ink` (primary text) | `#EDE3D2` | Warm sand-white. ≥ 12:1 on bg. |
| `inkMuted` | `#B5A892` | Secondary text. ≥ 4.6:1 on bg — AA body. |
| `ochre` (primary) | `#C9913F` | Lamplight. CTAs, active states, current-week. Large text/UI only on bg (≈5.9:1). |
| `moss` | `#8FA882` | Done, success, doctor-reviewed, consistency dots. The only "good" color — never bright green. |
| `sand` | `#D9C9A8` | Chips, outlines, tertiary accents. |
| `turmeric` | `#D8A03D` | Attention without alarm: validation, "review pending", triage. **There is no red anywhere, including errors** — attention is carried by turmeric outline + explicit copy, never by hue panic. |
| `grain` | 2% noise overlay | 64px tiled PNG on `bg` only. Static. Skip below API perf floor. |

**Light theme** (exists; secondary): paper `#F6EFE3`, ink `#2A211A`, ochre deepened
to `#A06F26` (AA on paper), moss `#6E8A60`, surfaces `#FFFBF3`. Light theme *is* the
manuscript page; dark theme is its night negative.

**Session-type tints** (ring stroke + type chip only — nothing else):
kegel `ochre` · reverse-kegel `sand` · breathwork `moss` · sensate `#B59B7E` taupe ·
education `turmeric` · mindset `#A89A85` wheat. All warm family.

**Banned:** red, crimson, any hue 345°–15°; countdown-urgency color shifts; pure
black; cool blues/violets anywhere except the Book Mode cover (G3 — deliberate).

### A3. Typography

| Role | Face | Spec |
|---|---|---|
| Display numerals (timer, big stats) | Fraunces | 64–72, Light, `FontFeature.tabularFigures()` so live countdowns don't jitter; if Fraunces tnum misbehaves in Flutter, fall back to Manrope SemiBold for *ticking* numerals only. |
| H1 | Fraunces | 28/34 SemiBold, soft optical, -0.5 tracking |
| H2 | Fraunces | 22/28 Medium |
| Title | Manrope | 18/24 SemiBold |
| Body | Manrope | 16/24 Regular |
| Reader body | Manrope | 17/27 — article screens only |
| Label | Manrope | 13/16 Medium, +0.2 tracking, sentence case (never ALL CAPS — caps read institutional) |
| Caption | Manrope | 12/16, `inkMuted` |

Fraunces appears only at H2 and above plus display numerals and pull-quotes. Body
and UI are entirely Manrope. Hindi (Phase 2): reserve +30% string room everywhere;
Fraunces has no Devanagari — plan Martel or Yatra One as display fallback, Mukta for
body. Don't build layouts that break at +30%.

### A4. Texture & ornament

Exactly two ornaments exist in the entire app:

1. **Grain** — A2 above. Atmosphere only.
2. **Pothi rule** — `RuleDivider`: two 1px lines, `ochre` at 24%, 2px apart, with a
   2×2px rotated square at center. The manuscript nod. Appears *only*: under the
   plan-reveal title, between article sections, on the completion moment, and as
   the paywall header underline. Nowhere else. Scarcity is what keeps it special.

No gradients except a single 8% ochre radial glow behind the session ring. No
shadows heavier than `0 2 8 rgba(0,0,0,0.25)`. No glassmorphism.

### A5. Illustration direction — "calm contour"

For the three education slides, empty states, and triage/care screens.

- **Style:** single-weight 2px line, `sand` stroke on dark, flat `moss`/`ochre`
  fills at 16–20% opacity, no outlines closed unnecessarily, no faces with
  expressions (avoids cartoon shame-comedy). Composition floats on `bg` — no frames.
- **Anatomy slides:** metaphor-first, then real. Slide 1 opens with a literal
  hammock slung between two posts; slide 2 morphs the same curve into a simplified
  male pelvis side cross-section — stylized, line-only, clinically honest but with
  zero photorealism and no rendered genitalia detail beyond the schematic;
  slide 3 is three small vignettes (support / control / blood flow) in the same line.
- **₹0 production pipeline:** Gray's Anatomy plates are public domain — trace the
  pelvic floor plates in Figma, reduce to the 2px contour style, recolor to tokens.
  This is free, accurate, and quietly *is* the manuscript lineage (Victorian plates,
  same era as the Burton translations). One style file, export SVG → flutter_svg.
- **What illustration is for:** education, care, and emptiness. Never decoration on
  data screens — the dashboard's honesty (Part F) reads stronger undecorated.

### A6. Motion & haptics

Map to existing tokens 100/200/400/700ms:

- **100** press feedback (scale 0.98) · **200** chips, toggles, selection ·
  **400** screen transitions — fade-through (Material 3), no slides, no overshoot
  ever · **700** ceremonial only: ring close, lotus bloom, plan-reveal stagger.
- **The signature — breathing ring.** `AppProgressRing` gains three modes:
  - `countdown`: standard sweep, calm.
  - `breath`: ring scales 0.86 ↔ 1.00 on a sine curve matched to the step's
    inhale/exhale timing. The ring **is** the pacer; guidance text crossfades
    ("In through the nose… 2… 3… 4"). This is the one place the app moves on its own.
  - `holdPulse`: for kegels — ring fills during hold, drains during release, with a
    soft tick at each transition.
- **Haptic cue language** (discretion feature — sessions followable with the phone
  face-down on the chest, silent, lights off):
  single light tick = squeeze/begin · double tick = release · medium thump =
  phase change · soft long buzz = session done. Document in a one-time tooltip on
  first session ("You can feel the cues — try it with the screen off").
- **Reduced-motion:** breath mode swaps scale for opacity pulse 70↔100%; lotus
  bloom becomes a fade; everything else already static-friendly.

### A7. Iconography — app icon & disguise

**App icon — three concepts, recommend A:**

- **A. Open bud (recommended):** three nested line arcs forming an abstract lotus
  bud opening, `ochre` 3px stroke on `#221D17` circle, tiny `sand` dot at base.
  Continuity with the existing white-lotus notification icon. Reads as generic
  meditation/wellness from a meter away — gives nothing away, but is *ours*.
- **B. Breath ring:** an open double circle with a deliberate gap and center dot.
  Maximum neutrality, minimum identity.
- **C. स monogram:** single calligraphic Devanagari *sa* stroke, ochre on sand.
  Beautiful, but reads "Indian-language app" — slightly more identifiable; hold for
  brand maturity.

**Disguise identity (Book Mode alias) — the pairing rule:** launcher icon, launcher
label, and cover screen (G3) must form *one coherent boring app*. Recommended pair:

- Icon: grey-blue pencil-on-card glyph in default-Material style (deliberately off
  palette — it must look like a different developer's app). Label: **"My Notes"**
  (generic, but won't collide with the system Notes app — `[user decision]`).
  Alternatives: "Calculator+" (grid glyph) or "Reader" (book glyph) — only if the
  cover screen is rebuilt to match. Ship one pair, not a picker of half-built covers.

### A8. Voice & microcopy rules

Register: a knowledgeable friend who happens to have read the citations. Plain
verbs, sentence case, second person, no exclamation marks, no emoji in UI copy.

- **Banned vocabulary** (QUITTR test): destroy, ruin, damage, last chance, before
  it's too late, X% of men fail, addiction-brain, poison, real men, beast/alpha,
  any countdown framed as loss.
- **Allowed honesty:** "This takes weeks. That's normal." · "Training can't fix
  what this might be, and we won't pretend otherwise." · "We never estimate —
  every number here is something you did or told us."
- Buttons say what happens: "Start session", "Call 14416", "Erase everything" —
  never "Submit", "OK", "Continue" where a specific verb exists.
- Failure and emptiness give direction, not mood: explain what happened and the
  next step; errors never apologize and are never vague.
- Sacred-text content (Part E): quote selectively, modernize framing, always tag
  the translation era ("Burton translation, 1883 — language of its time"), never a
  health claim sourced from scripture. Cultural heritage register, not religious
  instruction.

---

## Part B — Component system

### B1. Upgrades to existing widgets

- **AppProgressRing** → three modes per A6 (`countdown` / `breath` / `holdPulse`),
  center slot keeps Fraunces numeral, add 8% ochre radial glow behind, stroke takes
  session-type tint.
- **AppMoodSelector** → replace literal emoji with five custom "calm contour" mood
  glyphs (A5 style): heavy / low / level / open / charged `[confirm labels against
  built enum]`. Sand line idle → ochre fill + 1.06 scale selected (200ms). Multi-
  select up to 3.
- **AppButton** → press scale 0.98 @100ms; destructive variant = `outlined` in
  `ink` with explicit verb, never a hue change.
- **AppChip** → variants: type-tint chip (session type), `LockChip` ("Pro", sand
  outline, no padlock glyph), duration chip.
- **AppCard** → optional `RuleDivider` slot; pressed state lifts to `surfaceRaised`.

### B2. New components

| Component | Purpose | Key spec |
|---|---|---|
| `JourneySpine` | 12-week path on plan reveal + Me tab | Vertical (reveal) / horizontal (Me). 12 segments in 3 phase groups; lotus nodes at wk 4/8/12; current week glows ochre; past = moss fill, future = sand 24% outline. |
| `WeekDots` | This-week row on Today | 7 dots: done = moss fill, today = ochre ring, upcoming = sand 24%. Missed days are simply unfilled — never struck through. |
| `ConsistencyGrid` | Me tab, 4×7 | Moss at 3 intensities by sessions/day. Source tag below (F2). |
| `VolumeBars` | Me tab practice volume | 6 weekly bars, sand; current week ochre. |
| `CheckinChart` | Me tab instruments | Dots at wk 0/4/8/12; line connects only real data; future check-ins = faint outlined circles with dates. |
| `StatTile` | Me tab counters | Fraunces numeral 40 + Manrope label. |
| `StepDots` | Onboarding + health questions | Tiny progress dots, never "3/9" numerals (numbers create test anxiety). |
| `GuidanceText` | Session player | 18/26 centered, max 3 lines, 400ms crossfade between steps. |
| `HoldToConfirm` | Destructive actions | Press-and-hold 3s; reuses ring fill as the meter. Releasing early resets, no penalty copy. |
| `TierCard` | Paywall | Price (Fraunces 28) + one-line meaning + radio. Selected = ochre 2px border. Equal height all tiers. |
| `PreviewSheet` | Locked library rows | Bottom sheet: what the session does, duration, "Included in Pro" + [See Pro] [Maybe later]. |
| `DoctorBadge` | Articles | moss tick + "Doctor-reviewed" / turmeric dot + "Review pending" — both states honest, both shippable. |
| `SourcesBlock` | Article end | Collapsed "Sources (n)" → expands to citation list, caption type. |
| `PullQuote` | Heritage articles | Fraunces 22 italic, pothi rules above/below, era tag caption. |
| `DialCard` | Crisis screen | Full-width, 64dp min height, phone glyph, name + availability + tap-to-dial. Largest tap targets in the app. |
| `RuleDivider` | A4 ornament | As specced; four placements only. |
| `CoverNotes` | Book Mode cover | See G3 — intentionally raw Material. |

Accessibility floor for every component: 48dp targets, AA contrast (A2 is
pre-checked), TalkBack labels (ring announces "2 minutes 10 seconds remaining"),
reduced-motion variants per A6.

---

## Part C — Onboarding (12 screens, ~3–4 min)

### C0. The emotional arc

Warmth curve to design against — each screen states its position:

arrive (quiet) → **learn (first lift)** → identify (agency) → screen (calm clinical
plateau) → *care (warmest, if reached)* → baseline (momentum) → **plan reveal
(peak)** → privacy (grounded) → first session (action).

Shared scaffold: `bg` + grain, StepDots top-center, back chevron always present,
one H1, one decision per screen. No screen scrolls except 3, 7, 7b, 10.

### C1. Welcome

- Layout: lotus mark small top · H1 Fraunces 32 "Train steady." · body: "Most
  sexual function problems respond to training. Sahaj is that training — five to
  fifteen minutes a day, built on exercise and evidence, not pills or promises." ·
  [Begin] full-width ochre.
- Motion: mark draws in (700ms line animation), text fades up staggered. The only
  splash flourish in the app.

### C2. The promise

- H1: "Before we start". Three rows (glyph + line, calm contour glyphs):
  "About 3 minutes of questions" · "No payment until you decide it's worth paying
  for" · "Everything stays on this phone. No account, no cloud."
- CTA: [Sounds fair]. This screen is the trust contract — give it air (32 spacing).

### C3. Education (3 slides)

- Horizontal pager, dots, swipe + [Next]. Each: illustration (top 45%, A5 style) ·
  H2 · ≤2 body sentences.
- S1 "Meet your pelvic floor" — hammock illustration. "A hammock of muscle slung
  inside your pelvis. It holds everything up — and it does more than that."
- S2 "You already know it" — hammock morphs to pelvis cross-section (the one
  honest anatomy moment). "Between your sit bones, front to back. You've used it
  every time you've stopped midstream or held a sneeze."
- S3 "Why training works" — three vignettes. "It times ejaculation, supports
  erection rigidity, and strengthens like any other muscle. That's the whole idea —
  and it's why this is exercise, not therapy."
- The "feel smarter five screens in" beat lands here. No quiz, no test.

### C4. Persona routing

- H1: "Which sounds most like you right now?" Five full-width selectable cards,
  one column `[confirm option text against built enum]`:
  "I finish sooner than I want to" · "Erections are unreliable" · "Porn has dulled
  real-life response" · **"I haven't been sexually active yet — I want to be
  ready"** · "Nothing's wrong — I'm here to get better".
- Persona Zero's card carries zero special styling — first-class by being ordinary.
  Order: place it 4th, never last (last reads as afterthought).

### C5. Goals

- Multi-select chips-as-cards, 6 options, ≥1 to continue `[confirm against enum]`.
  "Last longer" · "More reliable erections" · "Rebuild sensitivity" · "Calmer
  before and during sex" · "First-time ready" · "General control and fitness".
- Caption: "Weeks 5–12 of your plan adapt to these."

### C6. Health screening (9 single-question screens)

- Template: StepDots · **why-line first** (caption, inkMuted) · H2 question ·
  full-width answer cards (Yes / No / Sometimes / Prefer not to say where
  clinically acceptable) · back.
- Why-line examples: morning erections — "Morning erections are a sign blood flow
  and nerves are working. Good news if yes." · thirst/weight — "These can point to
  things a doctor should check first — that's the only reason we ask."
- Intro screen before Q1: "A quick health check — nine questions. Some conditions
  need a doctor before training helps, and we'd rather tell you than sell you."
- **PHQ-2/GAD-2 items keep their validated wording verbatim** — warmth lives in
  the framing around them, never in rewording the instrument (see Part K, flag 1).

### C7. Red-flag triage (conditional)

- Illustration: small calm contour lamp/door. H1: "One thing first."
- Body: "A couple of your answers suggest seeing a doctor before training — not
  instead of it. [reason chips: e.g. 'blood-flow signs', 'medication check']
  Training can't fix what these might be, and we won't pretend otherwise."
- CTAs: [How to bring this up with a doctor] (article) · [Continue with the free
  program]. Turmeric accents only; zero alarm styling.

### C7b. Crisis screen (conditional — highest-care screen in the app)

- Largest type and padding in the app; `surfaceRaised` warm panel; no StepDots, no
  decoration, no illustration.
- H1: "Pause the questionnaire — this matters more." Body: "You mentioned thoughts
  of harming yourself. You deserve real support from a person, today."
- Three `DialCard`s: Tele-MANAS (free, 24/7, Hindi & English) · iCall · AASRA —
  numbers as implemented in code. Tap-to-dial is the entire job of this screen.
- Footer caption: "Sahaj will be here whenever you come back." Quiet [Continue]
  text-button below — present, never competing with the dial cards.

### C8. Function baseline

- Same template as C6; persona-calibrated battery (PEDT / IIEF-5-adapted / solo).
  Intro line: "No right answers — this is your week-0 mark. You'll re-take it at
  weeks 4, 8 and 12, and that comparison is yours."
- This framing pre-sells the dashboard (Part F) before it exists.

### C9. Mind/body baseline

- 5 quick screens (stress, sleep, exercise, alcohol, porn frequency), same
  template, lighter why-lines. Porn item phrased neutrally: "How often do you
  watch porn in a typical week?" — frequencies only, zero judgment language.

### C10. Plan reveal — the conversion moment of onboarding

- Scrolling screen. Stagger-reveal (700ms total): H1 "Your 12 weeks" · RuleDivider
  · vertical `JourneySpine` with three phase blocks:
  Foundation wk 1–4 "find it, feel it, breathe" · Integration wk 5–8 "combine,
  stop-start, sensate" · Mastery wk 9–12 "functional control, rehearsal, readiness"
  · lotus milestone nodes at 4/8/12 labeled "check-in — measured, not guessed".
- Two personalized lines pulled from answers, ochre text: "Because you chose
  'first-time ready', weeks 5–12 build readiness, not repair." etc.
- Commitment chip row: "5–15 min/day" · "12 weeks" · "free to finish".
- CTA: [Looks right — set up privacy]. No price, no paywall shadow on this screen.

### C11. Privacy setup

- H1: "Make it yours alone." Three setting rows with live previews:
  Book Mode toggle (+ disguise pair preview exactly as the launcher will show it) ·
  biometric lock toggle (fires system prompt) · caption: "Change any of this later
  in Settings."
- CTA: [Done]. If Book Mode enabled, a one-time coach line: "Double-tap the cover
  screen to open Sahaj."

### C12. First session ready

- H1: "Your first session is ready." Body: "Seven minutes — breathing, and finding
  the muscle. No payment, no signup, nothing to create."
- [Start now] ochre · [This evening] outlined (schedules the daily reminder and
  exits to Today). Both choices are wins; neither is styled as the loser.

---

## Part D — The daily loop (the heart)

### D1. Today tab

- Layout top→bottom: greeting (time-aware, **no name** — privacy default: "Good
  evening." is enough) · week banner "Week 3 of 12 · Integration" (sand caption) ·
  **session hero card** (~55% of first viewport): session-type chip + duration chip
  · H2 session title · one why-line ("Builds on yesterday's hold work — slightly
  longer holds, same breath.") · [Start] full-width · `WeekDots` · streak tile
  ("Steady days · 6", moss numeral) — when hidden in settings it is simply absent,
  no gap, no placeholder.
- **Done state:** hero card swaps to moss-tinted "Done for today" with small lotus
  tick · line: "Rhythm beats intensity — see you tomorrow." · text-link "Free
  practice in the Library" .
- **Empty state (no plan yet / fresh install):** calm contour lamp illustration ·
  "Your plan starts with one session." · [Begin].
- **Mood not yet checked:** Start opens the mood sheet first (D2) — the card's why-
  line reads "Today's session adjusts to how you arrive."

### D2. Mood check-in sheet

- Bottom sheet, drag handle, `surfaceRaised`. H2: "How are you arriving today?"
- `AppMoodSelector` glyph row (B1), pick 1–3 · caption "This tunes today's session
  — nothing is logged anywhere but this phone." · [Get today's session].
- No skip-shame: a quiet "Skip" text-button gives the default session.

### D3. Session player — used 84+ times; the most designed screen

- Layout: top — session title (Label size, inkMuted) + step name (Title) + thin
  step-segment bar (not numerals) · center — `AppProgressRing` 260dp, mode per
  step type (A6), Fraunces tabular countdown inside, 8% ochre glow behind ·
  below ring — `GuidanceText` (≤3 lines, crossfade) · bottom third — [prev]
  44dp · **[pause/play] 72dp ochre** · [next] 44dp. All controls one-thumb
  reachable.
- **Audio mode:** identical layout; voice plays under the stepper. Add: small
  speaker toggle top-right (state persists) · first-audio-session prompt: "Voice
  guidance — best with earphones. You can also mute and follow the haptics." ·
  **default = ask once, remember** (shared-wall reality; see Part K, flag 5).
- **Haptics on by default** (A6 cue language) — the discretion superpower:
  screen-off, silent, face-down followable.
- **Pause state:** everything dims 20%, ring stroke desaturates, line: "Paused —
  take your time." No timer pressure, no auto-resume.
- Keep-awake during sessions; brightness never flashes; interruption (call/lock)
  resumes at the paused step with "Pick up where you left off."
- Per-type ring tint (A2). Breath steps: the ring breathes and the countdown
  hides (numbers fight breathing); guidance text carries the pace words.

### D4. Reflection page

- H2: "How did that feel?" Three large cards in a row: Easier / About the same /
  Harder (calm contour glyphs: down-slope, level, up-slope — *effort* glyphs, not
  mood faces; "Harder" is data, not failure).
- Optional `AppTextField` journal: placeholder "Anything to note? Only you will
  ever see this." · [Done] · "Skip" text-button. Whole screen ≤10 seconds.

### D5. Completion moment

- Full-screen, `bg`. The ring closes → strokes bloom outward into the lotus mark
  (700ms line-draw, A6) → settles small above text.
- H1: "Done." · dynamic line (Fraunces 22): "Session 14 · third this week." ·
  caption: "Tomorrow: Stop-start, 9 minutes." · RuleDivider · [Finish].
- Rotating quiet acknowledgments (one per day max, no stacking): "Steady." ·
  "Same time tomorrow." · "That's the work." Never confetti, never sound, never
  share buttons. If a milestone week completed: one extra line "Week 4 done —
  your first check-in is ready." with [Take check-in] [Tomorrow].

---

## Part E — Library & reading

### E1. Library tab

- Two sections under one scroll. **Read** first (6 article cards): Fraunces title,
  reading-time caption, `DoctorBadge` state, thumbnail = calm contour spot
  illustration (one per article, same style file).
- **Practice**: 6 collapsible type groups (type glyph + name + count). Rows =
  `AppListTile`: title · duration chip · trailing `LockChip` if Pro.
- **Locked treatment:** row at full color (not ghosted — ghosting reads as
  punishment), `LockChip` "Pro" only, tap opens `PreviewSheet` (B2) which sells
  by describing, never by blocking mid-task. **Free items sort first within every
  group** — the free tier must visually dominate (principle 2).
- Empty search/filter state (if filters exist): "Nothing here — try fewer filters."

### E2. Article reader

- Reading scale: Reader body 17/27, max-width = screen − 24dp gutters, Fraunces
  H2 section heads, thin ochre reading-progress bar at very top.
- Header block: title · `DoctorBadge` · reading time · RuleDivider.
- `PullQuote` for heritage pieces (Kama Sutra / Ananga Ranga series): Fraunces
  italic between pothi rules + era caption ("Ananga Ranga, Burton tr., 1885 —
  language of its time"). Heritage register per A8: knowledge frame, anti-shame
  ("your culture treated this as knowledge for millennia"), zero health claims
  from scripture, doctor-gate untouched.
- Footer: `SourcesBlock` collapsed · "Reviewed by Dr. ___" line when applicable ·
  next-article card.

---

## Part F — Me tab & the progress dashboard (principle 12 — the conversion lever)

### F1. Structure

Top→bottom: H1 "Your progress" · horizontal `JourneySpine` (same artifact the user
met at plan reveal — continuity is the trick: the promise made in onboarding is
visibly being kept) · `StatTile` row: Sessions · Steady days (hideable) · Longest ·
`ConsistencyGrid` · `VolumeBars` · `CheckinChart` · reflection trend strip
(last 7 easier/same/harder glyphs) · tiles: Privacy → Settings · Subscription ·
About.

### F2. The honesty system — what makes this dashboard convert

Every chart carries a **source tag** (caption, inkMuted, right-aligned):
"from your session logs" (ConsistencyGrid, VolumeBars, StatTiles) ·
"from your check-ins" (CheckinChart). And the dashboard footer line, set small:

> "We never estimate. Every number here is something you did or told us."

- **ConsistencyGrid:** misses are unfilled, never marked. A break in moss is
  visible truth, not a broken-streak graphic.
- **VolumeBars:** practice volume = minutes + total hold-seconds. Labeled as what
  you *did* — never dressed up as a "strength score" the data can't support.
- **CheckinChart:** plots only completed instruments (wk 0/4/8/12). Future
  check-ins are faint outlined circles with dates. Empty state: "Your week-4
  check-in unlocks this chart — measured, not guessed."
- **The dashboard is entirely free.** The lever is real visible progress creating
  the wish to go deeper (full library, audio, adaptive weeks) — not a paywalled
  mirror. Pro never gates the user's own data.

### F3. States

Fresh install: spine at week 1, tiles at 0 with "your week-0 baseline is set" ·
streak hidden: tile absent, grid remains (consistency ≠ streak) · returning after
a gap: nothing changes color; the why-line on Today says "Pick up at week 5 —
the plan adjusted." (blameless resets, principle 8).

---

## Part G — Settings, privacy, cover, gate

### G1. Settings page

Sections in order: **Privacy** (Book Mode toggle + disguise pair preview ·
biometric toggle) · **Daily rhythm** (reminder toggle + themed time picker · hide
streak toggle) · **Your data** ([Export everything] → system share sheet, caption
"Your data, yours to take — one JSON file." · [Erase everything] — outlined,
separated by 32dp) · **About** (version, doctor-review policy, licenses).

**Erase everything** → full-screen confirm (never a dialog): H1 "Erase everything"
· body "This deletes your plan, history, journal and settings from this phone.
There is no cloud copy — gone is gone." · `HoldToConfirm` 3s ("Hold to erase") ·
[Keep my data] text-button. Afterward: clean return to Welcome. No red at any
point — deliberateness comes from friction and plain words (A8).

### G2. Biometric gate

Minimal: lotus mark · system biometric prompt auto-fires · "Use PIN" fallback
text-button · nothing else on screen. **Order with Book Mode on:** cover →
double-tap → gate → app. The gate itself stays neutral (mark only, no app name) —
it may be glimpsed.

### G3. Book Mode cover — must pass the glance test

The one screen that deliberately breaks every rule in this document:

- A fake notes app in **stock Material light theme**: Roboto, default blue
  `#1A73E8`, white background, default elevation. Using the Sahaj palette here
  would defeat the disguise — flagged as the sanctioned exception to the
  "no raw Material widgets" convention (Part K, flag 4).
- Content: top bar "My Notes" + search stub · 6–8 seeded mundane notes ("Grocery —
  Saturday", "Books to read", "Meeting notes — Tue", "Ideas", with plausible
  timestamps) · FAB pencil. Notes open to one level of fake content — a
  glance-tester who taps once must see a real-looking note, not a dead end.
- Double-tap anywhere → gate/app. No hint text on screen, ever (the C11 coach
  line is the only place the gesture is taught).
- **Recents privacy (implementation note):** the task-switcher thumbnail must show
  the cover, not the last Sahaj screen — show cover on `onPause` when Book Mode is
  on (or FLAG_SECURE as fallback, accepting the blank thumbnail).
- Notifications while disguised use the alias name and the neutral copy bank (I1).

---

## Part H — Monetisation

### H1. Paywall — the most honest screen in Indian app-dom

- Top: X (top-right, always) · H1 "Pick what's reasonable for you" · RuleDivider ·
  sub: "Same Sahaj Pro at every price. The scale exists because incomes differ —
  choose what's fair for you and we're square."
- Four `TierCard`s, vertical stack, equal height `[confirm sliding-scale = identical
  features against synthesis.md]`:
  ₹0 — "Keep training free. The core program is yours either way." ·
  ₹499/yr — "A fair price on a tight budget." ·
  **₹999/yr — moss chip "Recommended" — "The fair price."** ·
  ₹1499/yr — "Covers you, and quietly covers someone's ₹499." *(pay-it-forward
  framing — copy suggestion, cut if it overpromises an actual mechanism)*.
- **Nothing pre-selected.** Recommended is labeled, not chosen for the user —
  pre-selection is where honest pricing quietly turns into a dark pattern
  (Part K, flag 6). Tapping ₹0 simply closes the wall with "Good — train on."
- Below cards: "Every paid tier starts with 7 days free." · single CTA [Start
  7 days free] (disabled until a paid tier is tapped) · "Maybe later" text-button ·
  tiny-print set legibly at caption size, not grey-on-grey: yearly via Google Play
  · cancel anytime in Play · price never changes mid-subscription.
- What Pro includes (4 plain rows above the cards): full 54-session library ·
  voice-guided audio · weeks 5–12 fully adapted to your goals · all articles
  `[confirm list against synthesis.md]`.
- No timers, no "X people joined today", no decoy tiers, no guilt copy on dismiss.

### H2. Subscription page

Current tier card · "Manage in Google Play" (deep link) · [Restore purchases] ·
caption: "Subscriptions are handled by Play — we never see your card." Free-tier
state: "You're on Free. It stays free." + quiet [See Pro] link.

---

## Part I — System

### I1. Notifications

- Daily reminder, channel name "Daily reminder", white lotus small icon (exists).
- Copy bank (rotating, all shoulder-surf safe, no purpose leak): "Your 7 minutes
  are ready." · "Calm breathing — when you're ready." · "Today's session is short.
  Take it when it suits." · Session titles in any notification are always the
  neutral form ("Calm breathing", never technique names).
- While Book Mode is on, the notification app-name follows the alias (G3).

### I2. App icon & adaptive details

Concept A (A7) as adaptive icon: bud centered at 66% safe zone, `#221D17`
background layer, monochrome layer = bud line for themed icons. Disguise alias
ships its own adaptive set in stock-Material grey-blue.

---

## Part J — State matrix (quick reference)

| Surface | Empty | Done | Locked | Error/edge |
|---|---|---|---|---|
| Today | "Your plan starts with one session." + Begin | Moss done-card + free-practice link | — | Plan gap → blameless "plan adjusted" line |
| Library row | — | moss tick trailing (completed sessions) | LockChip → PreviewSheet | — |
| Article | — | — | Pro articles use same LockChip pattern | Load fail: "Couldn't open this — it's stored on-device, try again." |
| Dashboard charts | Source-tagged empty lines (F2/F3) | — | never locked | — |
| Session player | — | → completion moment | — | Interruption → resume at paused step |
| Paywall | — | — | — | Play billing fail: "Google Play couldn't complete this. Nothing was charged." + [Try again] |
| Forms (journal, time picker) | placeholder copy per A8 | — | — | Validation = turmeric outline + specific line under field; never red, never a snackbar |

Global: no snackbar errors anywhere — inline, specific, fixable (carried over from
the field-validation lesson).

---

## Part K — Flagged conflicts & resolutions (per §11 of the brief)

1. **"Calm framing" vs validated instruments.** PHQ-2/GAD-2 (and PEDT/IIEF items)
   lose validity if reworded. Resolution: item text verbatim; warmth lives in the
   why-lines and layout around them. Principle 4 survives; the science does too.
2. **Brief says "5-point emoji" moods; palette says emoji clash.** Literal emoji
   (system yellow) break A2 and read flippant. Resolution: custom calm-contour
   glyphs, same 5-point semantics, same built logic. Refinement, not a break.
3. **"Streak" language vs principle 8.** A streak is a fuse; agency-first naming is
   "Steady days." UI copy uses Steady days everywhere; code identifiers stay
   `streak`. Hideable as built.
4. **Book Mode cover vs "no raw Material widgets" convention.** Intentional,
   sanctioned exception (G3) — the disguise must look like someone else's default
   app. Document the exception in code comments so future-you doesn't "fix" it.
5. **Voice guidance vs joint-family discretion.** Audio is a flagship feature and
   an exposure risk. Resolution: ask-once-and-remember audio default, prominent
   mute, earphone prompt, and the haptic cue language as the fully-silent first-
   class path — not a degraded fallback.
6. **₹999 "Recommended" + pre-selection vs principle 7.** Labeling a fair price is
   honest; pre-selecting it is a nudge dressed as a default. Resolution: label,
   don't pre-select; ₹0 gets equal visual weight and a warm dismissal line.
7. **Conversion lever vs free-tier wholeness.** Tension resolved by direction:
   the dashboard (the lever) is 100% free; Pro sells depth (library, audio,
   adaptive weeks), never the user's own progress data back to him.
8. **Sacred-text content vs "no health claims from scripture."** Heritage articles
   are culture/anti-shame pieces with era-tagged quotes; anything physiological
   routes to the doctor-gated evidence articles. The two registers never mix in
   one paragraph.

---

## Part L — Implementation order for the UI pass (Claude Code)

Daily loop first — it's used 84+ times; onboarding is used once.

1. **Token calibration** — reconcile A2/A3 targets with `lib/core/theme/`; add
   session-type tints, turmeric, grain asset, motion constants.
2. **Component upgrades + new primitives** (Part B) — ring modes, mood glyphs,
   RuleDivider, StepDots, HoldToConfirm, source-tag caption.
3. **Session player + reflection + completion** (D3–D5) — the heart, including
   haptic cue engine and reduced-motion paths.
4. **Today tab** (D1–D2) with all states.
5. **Onboarding arc** (Part C) — scaffold template first, then the 12 screens;
   illustration slots can ship with placeholder line-art and be swapped.
6. **Me tab dashboard** (Part F) — spine, grid, bars, check-in chart, source tags.
7. **Library + reader** (Part E) — lock treatment, PreviewSheet, heritage
   PullQuote.
8. **Settings, gate, Book Mode cover** (Part G) — including recents-thumbnail
   privacy.
9. **Paywall + subscription** (Part H).
10. **Icons + notification polish** (A7, I1–I2) — needs the disguise-identity
    decision (user TODO) before the alias ships.

Definition of done per screen: tokens only (no literal colors), all states from
Part J present, TalkBack pass, reduced-motion pass, +30% string room, one
screenshot into `docs/ui_review/` for the device pass.
