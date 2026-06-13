# Screen Spec — Module 4: Onboarding (the shame-removal machine)

> **Build order:** #4
> **Mockups (ground truth):** v2 screens `01`–`09`, `11`, `12` are **adopted into this module as-is**; `10` is superseded by `m4_02_plan_reveal_live.html`; new states: `m4_01_phq_item.html` (validated instrument) · `m4_03_resume.html` (interrupted onboarding).
> **Routes:** `/onboarding/{step}` — linear, back always available, killable and resumable at any point.
> **State:** Riverpod `onboardingProvider`; answers persist to Hive after every screen (not at the end). This spec is the **canonical source for copy strings** — where a v2 mock and this spec differ on words, the spec wins; mocks win on visuals.
> **Rule:** undefined behavior → Decisions Needed; never invent.

---

## 0. The arc — design temperature per screen

| # | Screen | Job | Temperature |
|---|---|---|---|
| 1 | Welcome | arrival | quiet warmth |
| 2 | Promise | trust contract | plain, spacious |
| 3 | Education ×3 | *he feels smarter* — first lift | bright, illustrated |
| 4 | Persona | normalize — Persona Zero is ordinary | matter-of-fact |
| 5 | Goals | agency | light |
| 6 | Health check ×9 | care, visibly | calm clinical plateau |
| 7 / 7b | Triage / Crisis | the warmest screens, if reached | maximum care, minimum decoration |
| 8–9 | Baselines | momentum; pre-sells the dashboard | brisk |
| 10 | Plan reveal | **the only "wow"** | crescendo (live choreography) |
| 11 | Privacy | grounding | practical |
| 12 | First session | action | confident |

Global mechanics: StepDots never show numerals (numbers read as a test); one decision per screen; every answer saved immediately; back never loses data; total target 3–4 minutes.

## 1. Canonical copy (final strings)

- **C1 Welcome:** eyebrow `SAHAJ · सहज` · H1 "Train steady." · italic "in one's natural state, with ease" · body "Most sexual function problems respond to training. Sahaj is that training — five to fifteen minutes a day, built on exercise and evidence, not pills or promises." · chips `free forever / private by design / 12 weeks` · `[Begin]` · tiny "No account. Everything stays on this phone."
- **C2 Promise:** H1 "Three things, up front" · cards: "About 3 minutes of questions / Education first — you'll feel smarter before we ask anything." · "No payment until you decide / The free tier is a complete program, not a teaser." · "Everything stays on this phone / No account, no cloud, exportable any time." · `[Sounds fair]`
- **C3 Education:** S1 "Meet your pelvic floor" — "A hammock of muscle slung inside your pelvis. It holds everything up — and it does more than that." · S2 "You already know it" — "Between your sit bones, front to back. You've used it every time you've stopped midstream or held a sneeze." · S3 "Why training works" — "It times ejaculation, supports erection rigidity, and strengthens like any other muscle. That's the whole idea." · `skip` visible on all three.
- **C4 Persona:** H1 "Which sounds most like you right now?" · options (order fixed, Persona Zero 4th, never last): "I finish sooner than I want to" / "Erections are unreliable" / "Porn has dulled real-life response" / "I haven't been sexually active yet — I want to be ready" / "Nothing's wrong — I'm here to get better".
- **C5 Goals:** H1 "What are you here for?" · cap "Pick any that fit — weeks 5–12 of your plan adapt to these." · six options as built enum.
- **C6 Health check:** intro H1 "First, a quick check" + body "Some conditions need a doctor before training helps, and we'd rather tell you than sell you." + strip "Takes about a minute. Nothing here is stored anywhere but this phone." · question template = why-strip → question → answer cards → tiny "Tap an answer to continue · nothing leaves this phone". Why-strips per item as drafted in v2 mocks.
- **PHQ-2/GAD-2 items (`m4_01`):** strip "Two standard questions every doctor uses — same words everywhere. Answer honestly, not bravely." · stem + item + options **verbatim, untouched** · tiny "PHQ-2 · standard wording, unchanged". This rule extends to PEDT/IIEF items in C8.
- **C7 Triage:** H1 "One thing first" · reason chips from triage logic · "A couple of your answers suggest seeing a doctor before training — *not instead of it*. Training can't fix what these might be, and we won't pretend otherwise." · `[How to bring this up with a doctor]` (opens article) · `[Continue with the free program]`.
- **C7b Crisis:** "Pause the questionnaire — this matters more." · "You mentioned thoughts of harming yourself. You deserve real support from a person, today." · DialCards (numbers **as implemented in code**) · "Sahaj will be here whenever you come back." · quiet `Continue`. Largest type and padding in the app; nothing decorative.
- **C8 baseline intro strip:** "No right answers. You'll re-take this at weeks 4, 8 and 12 — and that comparison is yours."
- **C9 lifestyle strip:** "Just frequency — it tunes your plan, nothing else."
- **C10 Plan reveal (`m4_02`):** as mocked, including **two** personalized lines, each tied to a real answer ("Because you chose X, …"). Lines are generated from goals only; if one goal selected, show one line — never pad.
- **C11 Privacy:** H1 "Make it yours alone" · Book Mode card with live launcher preview · biometric card · strip "**Double-tap the cover screen** to open Sahaj. Change any of this later in Settings." · `[Done]`.
- **C12 First session:** ring preview at 7-min mark · chips `breathwork / no signup / no payment` · H1 "Your first session is ready" · "Breathing, and finding the muscle. Nothing to create, nothing to pay." · `[Start now]` / `[This evening]` · tiny ""This evening" sets your daily reminder and takes you home."

## 2. Routing & resume

- **Triage trigger:** red-flag mapping **as implemented** in the built triage logic — this spec governs presentation only. Reason chips render the triggered categories, max 3.
- **Crisis trigger:** the self-harm-indicating answer **as implemented** (confirm which item — Decisions #1). Crisis interrupts immediately; on `Continue`, the questionnaire resumes at the next item.
- **Interruption (`m4_03`):** any kill/lock mid-flow → on return, the resume screen: where he was, "your answers are saved on this phone, nowhere else", `[Continue]` / ghost `[Start over]`. Start over requires the standard confirm (wipes onboarding answers only). Resume lands on the exact pending screen.
- After C12, onboarding is unreachable (no re-entry path; baselines re-run only as check-ins).

## 3. Don'ts

No numbered question counters in dots (resume screen's "4 of 9" is orientation, the only numeral allowed). No "diagnosis"-flavored summaries after the health check — answers route silently to triage or pass. No price, tier, or Pro mention anywhere in the flow (the paywall does not exist until the app proper). No skipping the health check while keeping training locked behind it silently — if screening is incomplete, Today's hero says so plainly (one line, no shame). QUITTR + Persona Zero tests on every string above.

## 4. Acceptance criteria

Five global tests, plus: full flow ≤4 min at normal pace · every screen survives +30% string length · back from any screen restores prior answer state · kill at every step resumes correctly (golden test per step) · PHQ/GAD/PEDT item text byte-identical to the instrument source · plan-reveal choreography 700ms total, instant under reduced-motion · crisis DialCards are real `tel:` intents with the implemented numbers.

## 5. Decisions needed (flagged, not invented)

1. **Crisis-trigger item:** PHQ-2 contains no self-harm item — confirm which built question (PHQ-9 item 9 equivalent or a standalone) routes to C7b, and its exact threshold.
2. **Personalized-line table:** the goal→line mapping for C10 (six goals → six lines, tone-matched to the two examples) — draft exists for two; the remaining four should be written against the plan engine's actual adaptations.
3. **"Start over" scope:** wipes onboarding answers only, or full data wipe path reuse (G1)? Recommend onboarding-only.
4. **Screening-incomplete state on Today:** exact one-liner if the user backgrounds out before triage resolution ("Finish the two-minute health check to unlock your plan" — confirm tone).
