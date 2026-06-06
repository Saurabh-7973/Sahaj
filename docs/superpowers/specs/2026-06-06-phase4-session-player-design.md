# Phase 4 — Lean Session Player slice (design)

**Date:** 2026-06-06
**Status:** Approved (brainstorming) — pending implementation plan

## Goal

Deliver a usable daily training loop on the existing Hive stack:

> Today → mood check-in → guided stepper session (text + timer, **no audio**) → reflection → progress advances.

No Firestore, no audio streaming, no Drift. This slice turns the Phase 3 plan (per-week `moduleTags`) into something the user can actually *do* every day.

## Scope decisions (from brainstorming)

| Decision | Choice |
|----------|--------|
| Phase 4 scope | Lean player slice (text/timer), defer audio + content-sync infra |
| Session content source | JSON asset bundled in app (`assets/content/sessions.json`) |
| Today's-session derivation | Computed at runtime from the current week's `moduleTags` (no plan-model change) |
| Progression | One session per **calendar day**; completion advances; streak = consecutive days, gap resets |
| Player | Stepper: ordered steps, per-step countdown, auto-advance, play/pause, prev/next |

## Non-goals (deferred to later phases)

- Real audio + lock-screen controls (`audio_service`, `just_audio`)
- Firestore content sync + `content_pack_v` cache invalidation
- Drift / SQLCipher migration (stay on Hive)
- Articles / Library tab
- Analytics instrumentation (Firebase present but not wired; **no** `session_*` events this slice)

## Architecture

Pure-Dart logic layer (unit-testable, no Flutter imports) + Hive persistence + Flutter pages. Mirrors the Phase 3 structure (`logic/` pure functions over plain immutable models, stores under `lib/data/`).

### 1. Content catalog (JSON asset)

`assets/content/sessions.json` — object keyed by `moduleTag`:

```json
{
  "pfmt_identify": {
    "title": "Finding the muscles",
    "type": "kegel",
    "steps": [
      { "title": "Settle", "seconds": 30, "guidance": "Sit or lie comfortably. Breathe slowly and let your body relax." },
      { "title": "Locate", "seconds": 60, "guidance": "Gently try to stop the flow of urine in your imagination — those are the muscles." },
      { "title": "Gentle holds", "seconds": 90, "guidance": "Squeeze for 3 seconds, release for 3. Keep your stomach and thighs relaxed." }
    ]
  }
}
```

- Registered under `flutter: assets:` in `pubspec.yaml`.
- `type` reuses a small enum (kegel / reverseKegel / breathwork / sensate / education / mindset) for the card label/icon.
- Every `moduleTag` emitted by the Phase 3 plan generator must have a catalog entry, **except** pure content tags that aren't sessions (e.g. `solo`/`partnered` track tags). The catalog is the source of truth for what is a playable session; the scheduler filters to catalog hits.

### Models (`lib/features/sessions/logic/models/session_models.dart`)

```text
SessionType { kegel, reverseKegel, breathwork, sensate, education, mindset }

SessionStep   { String title; int seconds; String guidance }
SessionDef    { String tag; String title; SessionType type; List<SessionStep> steps }
  - int get totalSeconds  => sum of step.seconds
  - factory SessionDef.fromJson(String tag, Map json)

PerceivedDifficulty { easier, same, harder }

SessionLog {
  String id; String sessionTag;
  DateTime startedAt; DateTime completedAt;
  double completionPct;                 // 0.0–1.0
  List<String> moodBefore;              // mood keys
  PerceivedDifficulty? perceivedDifficulty;
  String? journalNote;
  Map<String,dynamic> toJson(); factory SessionLog.fromJson(Map);
}

ProgressState {
  int currentWeek;       // 1–12
  int currentDay;        // 1–7
  int streak;
  int longestStreak;
  String? lastCompletedDate;   // 'YYYY-MM-DD' (local date)
  ... toJson / fromJson / copyWith
}
```

### 2. Catalog loader (`session_catalog.dart`)

- `SessionCatalog.load()` — reads the asset via `rootBundle`, parses into `Map<String, SessionDef>`.
- **Loaded once at startup in `main()`** (alongside the Hive stores) and injected via a Riverpod provider override — same pattern as the onboarding store. Not a `FutureProvider`; the catalog is ready before `runApp`.

### 3. Scheduler (pure, TDD) — `lib/features/sessions/logic/scheduler.dart`

```text
SessionDef? todaysSession({
  required Plan plan,
  required int week,           // 1–12
  required int day,            // 1–7
  required Map<String, SessionDef> catalog,
});
```

Logic:
- Find the `PlanWeek` whose `number == week`.
- Take its `moduleTags`, keep only tags present in `catalog` (drops `solo`/`partnered`/non-session tags).
- Pick by day: `playable[(day - 1) % playable.length]`.
- Return `null` if no playable tag (defensive; UI shows a friendly empty state).

Deterministic: same (plan, week, day, catalog) → same session.

### 4. Progress (Hive + pure advance, TDD)

**Store** — `lib/data/progress_store.dart` (Hive box `progress`, single JSON map; mirrors `OnboardingStore`): `load()`, `save(json)`, `clear()`.

**Pure advance** — `lib/features/sessions/logic/progress_logic.dart`:

```text
ProgressState advanceAfterCompletion(ProgressState s, DateTime now);
bool isDoneToday(ProgressState s, DateTime now);
```

- `isDoneToday`: `s.lastCompletedDate == dateKey(now)`.
- `advanceAfterCompletion`:
  - If already done today → return `s` unchanged (idempotent guard).
  - Streak: if `lastCompletedDate == yesterday(now)` → `streak + 1`; else → `streak = 1` (first/after-gap). `longestStreak = max(longestStreak, streak)`.
  - Advance position: `currentDay + 1`; if `> 7` → `currentDay = 1`, `currentWeek + 1` (cap at 12 — at week 12 day 7, stay/flag "plan complete").
  - Set `lastCompletedDate = dateKey(now)`.
- `dateKey(d)` = local `YYYY-MM-DD`. Clock injected (param), never read internally → unit-testable.

**Controller** — `lib/features/sessions/progress_controller.dart` (Riverpod ChangeNotifier, takes `ProgressStore?`):
- Loads `ProgressState` on init (defaults: week 1, day 1, streak 0).
- `isDoneToday`, current position getters.
- `completeToday(SessionLog log)` → append log to `SessionLogStore`, apply `advanceAfterCompletion(state, DateTime.now())`, persist, notify.
- `reset()` for the dev reset path (clears box; align with Phase 3 reset on Me tab).

### 5. SessionLog store — `lib/data/session_log_store.dart`

Hive box `session_logs`: `append(SessionLog)`, `all() → List<SessionLog>`. Plain JSON list. Used for history/streak audit; minimal surface this slice.

### 6. UI flow (Navigator pushes, not go_router routes)

Linear: Today → (mood sheet) → player → reflection → Today. To keep the go_router shell simple, this flow uses **imperative Navigator pushes**, not declarative routes: mood = `showModalBottomSheet`; player and reflection = `Navigator.push(MaterialPageRoute(...))`. The router/`routes.dart` are **not** modified. (Listed under "Modified" below only as a note that they were considered and left unchanged.)

- **Mood check-in sheet** — `pages/mood_checkin_sheet.dart`: bottom sheet, multi-select 1–3 from the fixed list (anxious, hopeful, restless, disappointed, calm, distracted, motivated, low). Returns selected mood keys; cancel = abort start (no log).
- **Session player** — `pages/session_player_page.dart`: stepper.
  - Shows step `title`, `guidance`, per-step countdown ring/bar, overall progress (step k of n).
  - A `Timer.periodic(1s)` ticks; on step end auto-advances; on last step end → reflection.
  - Controls: play/pause (pauses timer), prev step, next step.
  - Background gradient may shift subtly with progress (design-system tokens; optional polish).
  - Carries `startedAt`. `completionPct` = summed seconds of completed steps / `totalSeconds`. Since reflection is only reached on full completion, logged sessions are `1.0` this slice; the field is kept for future partial-log support.
  - Abandon (back out) → no guilt, **no log written** this slice (matching roadmap "no shame"). Progress does not advance on abandon.
  - Step-progression logic (current step, elapsed, advance, isLast, completionPct) extracted to a small pure controller/class and **unit-tested**; the `Timer` stays in the widget.
- **Reflection** — `pages/reflection_page.dart`: "How did that feel?" → easier/same/harder; optional note (`TextField`, blurred by default for privacy, tap to reveal); tomorrow preview (next day's session title via scheduler). On confirm → build `SessionLog{ moodBefore, perceivedDifficulty, journalNote, startedAt, completedAt, completionPct }`, call `progressController.completeToday(log)`, pop to Today.

### 7. Today tab (`lib/features/home/tabs/today_page.dart`, modify)

Already a `ConsumerWidget` reading the plan (Phase 3). Extend:
- Read `progressController` + `catalog`.
- Compute `todaysSession(plan, week, day, catalog)`.
- States:
  - **plan == null** → "Finish onboarding" prompt (existing-ish).
  - **isDoneToday** → "Done for today — back tomorrow", show streak.
  - **session available** → card (title, type icon, `~N min`) + "Start" button → mood sheet flow.
  - **no playable session** (scheduler null) → calm rest-day/empty state.
- Show streak + "Week W of 12 — phase".

## Testing

TDD (failing test first) on all pure logic:
- `session_catalog` parse (fixture JSON → models; `totalSeconds`).
- `scheduler.todaysSession` (picks by day, filters non-catalog tags, null when none, deterministic).
- `progress_logic` (`isDoneToday`; streak increment / reset-on-gap / longest; day→week rollover; week-12 cap; idempotent same-day).
- stepper progression class (advance, isLast, completionPct, pause neutral to logic).

Hive round-trip tests:
- `ProgressState` toJson/fromJson + store save/load.
- `SessionLog` toJson/fromJson + store append/all.

Widget smoke (keep deterministic, mirror Phase 3 flow tests):
- Today renders today's session card from a stubbed plan + catalog.
- Reflection confirm writes a log + advances progress (controller-level; avoid driving real timers).

Player timer behavior is **not** unit-tested (needs fake-async/device); the extracted progression logic is.

## File structure

Created:
- `assets/content/sessions.json`
- `lib/features/sessions/logic/models/session_models.dart`
- `lib/features/sessions/logic/scheduler.dart`
- `lib/features/sessions/logic/progress_logic.dart`
- `lib/features/sessions/session_catalog.dart`
- `lib/features/sessions/progress_controller.dart`
- `lib/data/progress_store.dart`
- `lib/data/session_log_store.dart`
- `lib/features/sessions/pages/mood_checkin_sheet.dart`
- `lib/features/sessions/pages/session_player_page.dart`
- `lib/features/sessions/pages/reflection_page.dart`
- Tests under `test/sessions/` + `test/` for stores.

Modified:
- `pubspec.yaml` (asset registration)
- `lib/main.dart` (open progress + session-log boxes, hydrate progress controller via override — same pattern as onboarding store)
- `lib/features/home/tabs/today_page.dart` (session card + start flow; hosts the Navigator pushes — router/routes unchanged)
- `lib/features/home/tabs/me_page.dart` (extend dev reset to also clear progress + logs)
- `docs/CHANGELOG.md` (Phase 4 entry)

## Open defaults (locked unless changed)

- Mood list = the 8 above.
- Reflection = easier/same/harder + optional blurred note + tomorrow preview.
- No analytics events this slice.
- No log written on mid-session abandon.
