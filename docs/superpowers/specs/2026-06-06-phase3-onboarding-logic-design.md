# Phase 3 — Onboarding logic — design

Date: 2026-06-06
Status: approved (design), pending implementation plan
Scope: roadmap Weeks 3-4 — turn the Phase 2 navigation shell into a functioning
intake: triage, persona routing, baseline, plan generation, persistence,
biometric privacy.

Builds on Phase 2 (onboarding shell + go_router). Source of truth for product
behaviour: `docs/synthesis.md` §6, §7. Build plan: `docs/solo_dev_roadmap.md`.

---

## Principles that constrain this phase

- **Health > performance.** Screen before selling. Refer out aggressively.
- **Agency > shame.** Triage is a soft gate, never a hard block to the free tier.
- **No fear-driven copy** (principle 3). Referral copy is calm and specific.
- **Conservative triage.** When unsure, fire the flag. False positives (an
  unnecessary "see a doctor") are acceptable; false negatives are not.
- **Not a medical device.** All thresholds here are pre-clinician-review
  heuristics. Synthesis §10 mandates a doctor review the screening before public
  launch. Code must be written so thresholds are data/table-driven and easy to
  change after that review.

---

## Architecture

- **Pure-Dart logic layer** under `lib/features/onboarding/logic/` — no Flutter
  imports, unit-testable in isolation: `triage.dart`, `plan_generator.dart`,
  `banding.dart`.
- **Models** under `lib/features/onboarding/logic/models/` — plain immutable
  classes (no Freezed codegen): `TriageResult`, `MedicalClearance`, `Baseline`,
  `Plan`. `==`/`hashCode` where needed for tests.
- **Persistence** under `lib/data/`: `onboarding_store.dart` — Hive box, stores
  onboarding state as a single JSON map (no TypeAdapter codegen).
- **Existing pages** (`onboarding_pages.dart`) keep their structure; placeholders
  are replaced and two pages (red-flag, crisis) become conditional.

Each logic unit has one job and a pure function signature, so it can be tested
without the widget tree.

---

## Build order (dependency-sorted)

### 1. Persistence (Hive) — foundation

- `onboarding_store.dart`: open a Hive box `onboarding`; `load() → Map?`,
  `save(Map)`, `clear()`.
- `OnboardingController` gains `toJson()` / `loadFrom(Map)` and writes to the
  store on every mutating call (debounce not needed at this scale) and on
  `finish()`.
- `main.dart`: `Hive.initFlutter()` + open box before `runApp`; hydrate the
  controller's initial state from the store so the router gate (`complete`)
  survives relaunch.
- `clear()` exposed for a dev "reset onboarding" action (added to Me tab dev
  section, next to the showcase link).

### 2. Self-harm safety check — highest priority

- New question appended to the mood block: PHQ-9 item-9 style —
  "Over the last 2 weeks, thoughts that you would be better off dead, or of
  hurting yourself?" options Not at all / Several days / More than half the days
  / Nearly every day.
- Any answer above "Not at all" → a **CrisisScreen** shown immediately on
  leaving that question, *before* the rest of onboarding continues. Content:
  calm, non-clinical, India crisis resources — Tele-MANAS **14416**, iCall
  **9152987821**, AASRA **9820466726** — tap-to-call. A single
  "I'm safe, continue" action returns to the flow; the flag is stored.
- This is a flow interrupt, not a gate: the user can still continue to the free
  tier afterward. We never trap or lecture.

### 3. Red-flag triage

- `triage.dart`: `TriageResult evaluate(Map<String,int> health)`.
- `TriageResult { List<TriageFlag> flags; bool get hasFlags; }`
  `TriageFlag { TriageCategory category; String reason; }`
  `enum TriageCategory { cardiac, metabolic, neuro, organicErectile, mentalHealth }`
- Conservative rule table (heuristic, pre-review):
  - `morning_erections` == "No, rarely or never" → organicErectile
  - `pelvic_pain` == "Yes, often" → neuro/organicErectile
  - `weight_loss` == "Yes" → metabolic
  - `thirst_urination` == "Yes, often" → metabolic
  - `chest_breath` >= "Sometimes" → cardiac
  - `tremors_heart` == "Yes" → neuro/metabolic
  - `mood_down` or `mood_anxious` == "Nearly every day" → mentalHealth
  - self-harm > "Not at all" → mentalHealth (already handled by CrisisScreen;
    also recorded here)
- **RedFlagPage becomes conditional**: rendered only when `hasFlags`. Copy is
  category-specific and calm, ending with a telehealth pointer (Practo / local
  clinic). Borrows Mojo's voice (synthesis principle 6).
- **Soft gate**: stores `MedicalClearance { notSeen, proceedAnyway,
  confirmedDoctor }`. Default `notSeen` when flags fired, else `null`/cleared.
  On the RedFlagPage the user chooses "I'll see a doctor first" → stays
  `notSeen`, or "I understand, continue for now" → `proceedAnyway`. Pro-purchase
  gating reads this flag — **enforcement wired in Phase 6**, here we only store.

### 4. Persona routing

- `partneredActive`, `partneredInactive` → **partnered** track.
- `singleExperienced`, `singleInexperienced`, `preferNotToSay` → **solo**
  (Persona Zero) track.
- Track selects: which baseline battery renders (step 5) and which content
  emphasis tags plan-gen uses (step 7). Stored on the controller as
  `Track track`.

### 5. Baseline battery (persona-calibrated)

- Data-driven, same pattern as `health_questions.dart`:
  `baseline_questions.dart` with `partneredBaseline` and `soloBaseline` lists.
  - **Partnered**: PEDT-style (control, frequency, distress) + IIEF-5-style
    (erection confidence/firmness/maintenance). Friendly wording.
  - **Solo / Persona Zero**: arousal-control duration, masturbation pattern,
    mental-rehearsal comfort, future-encounter anxiety.
- `banding.dart`: `Band band(...)` → `enum Band { low, medium, high }` per area
  (coarse, from answer indices). **No clinical scoring** this phase — exact
  PEDT(0-20)/IIEF-5(5-25) thresholds + diagnostic categories wait for the
  doctor review (synthesis §10).
- `BaselinePage` placeholder replaced by a battery driven by the selected track.
- `Baseline { Map<String, Band> bands; Map<String,int> raw; }` stored.

### 6. Mind/body baseline

- 5 questions: sleep, stress, exercise, alcohol, porn/masturbation frequency
  (synthesis §6 screen 9). Data-driven; banded.
- `MindBodyPage` placeholder replaced. Stored on the controller as a sibling
  `Map<String, Band> mindBody` (separate from `Baseline`), passed into plan-gen.

### 7. Plan generation

- `plan_generator.dart`: `Plan generate({Track track, Set<Goal> goals,
  Baseline baseline, Map<String, Band> mindBody})`.
- **One §7 spine**: weeks 1-4 Foundation, 5-8 Integration, 9-12 Mastery, each
  with its module list from §7.
- **Modifiers** (no combinatorial explosion):
  - `track` → content tags (solo vs partnered variants of sensate/communication
    modules).
  - `goals` → emphasis tags (e.g. `finishTooQuick` emphasises stop-start /
    reverse Kegel; `hardness` emphasises arousal-confidence; `firstTimeOrGap`
    emphasises the readiness module).
  - baseline bands → `startDifficulty` (low band → gentler ramp).
- `Plan { List<PlanWeek> weeks; Track track; Set<String> emphasis;
  Difficulty startDifficulty; }`, `PlanWeek { int number; String phase;
  List<String> moduleTags; }`.
- `PlanRevealPage` renders the **generated** plan (phases + week count +
  honest 65-80% claim from §6 screen 10), replacing the static version.
- On `finish()`: run triage → generate plan → persist all → router redirects to
  `/today`. `/today` reads the stored plan for "Week N of 12 — <phase>".

### 8. Privacy plumbing (scoped)

- Wire **biometric lock** via `local_auth` (already in deps): the Phase 2
  PrivacyPage toggle persists to the store; on app resume/launch, if enabled,
  require `authenticate()` before showing content (a gate widget wrapping the
  router or shell).
- **Deferred to the settings phase** (explicitly out of scope here): full
  discreet-mode disguise — app-icon alias and Book-Mode UI disguise. Noted per
  user direction ("stick to the plan first, pick these later").

---

## Data flow

```
answers (pages) → OnboardingController (+ Hive on each change)
  → finish():
      triage.evaluate(health)        → TriageResult, MedicalClearance
      plan_generator.generate(...)   → Plan
      store.save(controller.toJson())
  → router refresh → redirect /onboarding → /today
/today reads stored Plan
```

Conditional pages inserted/skipped by the flow based on controller state:
- CrisisScreen — shown on self-harm positive (interrupt).
- RedFlagPage — shown only if `triage.hasFlags`.
- Baseline battery — partnered vs solo set by `Track`.

---

## Testing

- **Unit (pure, no widgets):**
  - `triage_test.dart` — rule table: each red-flag input fires the right
    category; clean answers produce no flags; conservative boundaries.
  - `plan_generator_test.dart` — persona→track, goal→emphasis, band→difficulty
    mappings; spine always 12 weeks / 3 phases.
  - `banding_test.dart` — answer index → band boundaries.
- **Widget:**
  - self-harm positive → CrisisScreen renders with crisis numbers.
  - flags fire → RedFlagPage renders; clean → it is skipped.
  - persistence round-trip: complete onboarding, recreate container from store,
    gate stays cleared and plan present.
  - solo vs partnered → correct baseline battery renders.

---

## Out of scope (this phase)

- Full discreet mode (icon alias, Book Mode) — settings phase.
- Pro-purchase enforcement of `MedicalClearance` — Phase 6.
- Exact clinical PEDT/IIEF-5 scoring + diagnostic categories — after clinician
  review (synthesis §10).
- Drift data layer for session/progress history — next after Phase 3.
- Real session content (audio/articles) — content phase.

---

## Notes

- Repo is **not** a git repo — spec is written but not committed (no VCS).
- All triage/baseline thresholds are heuristics flagged for clinician review;
  kept table-driven for easy change.
