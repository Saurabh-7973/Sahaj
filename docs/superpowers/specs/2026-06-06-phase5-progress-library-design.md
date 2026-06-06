# Phase 5 — Progress dashboard + Library (design)

**Date:** 2026-06-06
**Status:** Approved-by-delegation (user asked me to choose the best scope) — pending spec review

## Goal

Ship the two highest-value, buildable-now pieces of roadmap Phase 5 using only data and content that already exist:

1. **Me progress dashboard** — the conversion lever (synthesis §12). Honest metrics computed from the `SessionLog`s and `ProgressState` that Phase 4 already persists.
2. **Library** — browse the 13 catalog sessions by type and practise any of them freely (reuses the Phase 4 player flow).

No new content authoring, no backend, no Drift. Stays on the current Hive + Riverpod stack.

## Why this scope

- **Synthesis §12:** "Progress visualization is the conversion lever… users won't pay without seeing progress." The dashboard is the single highest-leverage screen for the product, and we already store the data to build it honestly.
- **Library from existing content:** the Phase 4 catalog has 13 session modules. Surfacing them as a browseable, free-practice library is immediately useful and needs zero new content.
- **Agency over shame (synthesis §8):** streak is collapsible and never the largest element; metrics degrade gracefully to "no data yet".

## Non-goals (deferred)

- Article / education **text** content (none authored) — the Library "Education" grouping shows the education-type sessions (anatomy, partner_communication), not articles.
- Strength-score / IELT / hold-time **sparklines** — we don't capture per-session quantitative scores yet; showing fake trends would violate "honest metrics".
- Settings depth, discreet / Book mode, subscription card, About screen, search, notifications, i18n.
- Greeting by `firstName` (not collected in onboarding).

## Architecture

Pure-Dart metrics layer (testable) over the existing `SessionLogStore` + `ProgressController`, plus two Flutter tabs. Reuses Phase 1 design-system widgets and the Phase 4 player flow.

### 1. Session-log access

The Phase 4 `ProgressController` writes logs to `SessionLogStore` but exposes no read API. Add a read path so the dashboard can compute metrics:

- `SessionLogStore.all()` already returns `List<Map>`. Add `ProgressController.logs()` → `List<SessionLog>` (decode via `SessionLog.fromJson`), reading from the injected `_logStore` (empty list when null). Controller already imports the model.
- Because metrics must be unit-testable without Hive, the **computation** takes a `List<SessionLog>` + `ProgressState` + `now` as plain inputs (see §2). The controller just supplies the list.

### 2. Metrics (pure, TDD) — `lib/features/me/logic/progress_metrics.dart`

```text
class ProgressMetrics {
  final int totalSessions;
  final int currentStreak;
  final int longestStreak;
  final int thisWeekCount;          // sessions completed in the last 7 calendar days
  final int currentWeek;            // 1..12 (from ProgressState)
  final String phase;               // phase label for currentWeek (from Plan)
  final int easierCount;
  final int sameCount;
  final int harderCount;
  bool get hasData => totalSessions > 0;
}

ProgressMetrics computeMetrics({
  required List<SessionLog> logs,
  required ProgressState progress,
  required String phase,            // caller resolves Plan.weeks[week-1].phase
  required DateTime now,
});
```

Rules:
- `totalSessions` = `logs.length`.
- `thisWeekCount` = logs whose `completedAt` is within the last 7 days (`now.difference(completedAt) < 7 days`, and not in the future).
- `currentStreak` / `longestStreak` come straight from `progress` (already maintained by Phase 4 logic — single source of truth, no recompute).
- difficulty tallies = counts of `perceivedDifficulty` across logs.
- `hasData` gates the "no data yet" empty state.

### 3. Me dashboard UI — `lib/features/me/me_dashboard.dart` (widgets used by the Me tab)

A `ProgressDashboard` `ConsumerWidget` that reads `progressControllerProvider` + `onboardingControllerProvider` (for the plan/phase), builds `ProgressMetrics`, and renders:
- **Week status** card: "Week N of 12 — {phase}".
- **This week** consistency: 7 dots, `thisWeekCount` filled (capped at 7).
- **Streak** card: collapsible (collapsed by default via a local `expanded` bool); shows current + longest when expanded. Never the largest element.
- **Totals**: total sessions; difficulty split (easier/same/harder) as a simple labelled row.
- **Empty state**: when `!hasData`, a single calm card — "Your progress appears here after your first session." — instead of the metric cards.

The existing `lib/features/home/tabs/me_page.dart` keeps its dev/settings tiles (showcase, reset, privacy placeholder) and gains the dashboard **above** those tiles.

### 4. Library — `lib/features/library/`

- `library_catalog.dart` — pure grouping: `Map<SessionType, List<SessionDef>> groupByType(SessionCatalog)` ordered for display (kegel+reverseKegel → "Exercises", breathwork → "Breathwork", mindset+sensate → "Practice", education → "Learn"). Group labels defined here.
- `library_page.dart` — a `ConsumerWidget` for the Library tab: reads `sessionCatalogProvider`, lists grouped sessions as `AppCard`s (title, type, `~N min`), each tap → launches the **existing** player via `Navigator.push(SessionPlayerPage(session, onComplete))`. Free practice: completion here writes a `SessionLog` (so practice counts toward totals/metrics) but does **not** advance plan position (`currentDay`) — i.e. it logs without `advanceAfterCompletion`. Add `ProgressController.logPractice(SessionLog)` that appends to the log store + notifies, without touching `state`.
  - Rationale: practice should count as activity (and feed the dashboard) but must not consume a plan day. Keeps the daily-loop gating intact.
- Library uses no mood check-in or reflection (free practice = just play). After the player pops, show a brief "Nice work" snackbar.

### 5. Navigation

The app already has a 3-tab shell (Today / Library / Me) from Phase 2 (`home_shell.dart` with `StatefulShellRoute`). Confirm the Library tab currently renders a stub; replace that stub's body with `LibraryPage`, and ensure the Me tab renders the dashboard + existing tiles. No router structure change expected — verify the shell already has the three branches; if the Library tab stub is a separate widget, point it at `LibraryPage`.

## Testing

TDD on pure logic:
- `progress_metrics` — totals, this-week window (boundary at exactly 7 days, future-dated ignored), difficulty tallies, streak passthrough, `hasData` false at zero logs.
- `library_catalog.groupByType` — correct grouping + ordering, empty groups omitted, non-session tags absent (catalog already excludes them).

Widget smokes (deterministic, override providers; no real timers):
- Me dashboard renders "no data yet" with an empty log store, and renders metric cards when given a controller with logs.
- Library renders grouped session cards from a stubbed catalog.

Controller:
- `ProgressController.logs()` returns decoded logs from a real temp-Hive `SessionLogStore`.
- `ProgressController.logPractice(log)` appends a log WITHOUT changing `state` (assert `currentDay` unchanged, `logStore.all()` grew).

Player timer behaviour remains un-unit-tested (device pass).

## File structure

Created:
- `lib/features/me/logic/progress_metrics.dart`
- `lib/features/me/me_dashboard.dart`
- `lib/features/library/library_catalog.dart`
- `lib/features/library/library_page.dart`
- Tests: `test/me/progress_metrics_test.dart`, `test/me/dashboard_widget_test.dart`, `test/library/library_catalog_test.dart`, `test/library/library_widget_test.dart`, plus `logs()`/`logPractice()` cases added to the sessions controller tests.

Modified:
- `lib/features/sessions/progress_controller.dart` — add `logs()` + `logPractice(SessionLog)`.
- `lib/features/home/tabs/me_page.dart` — mount `ProgressDashboard` above existing tiles.
- The Library tab host (the Phase 2 shell's Library branch / stub) — render `LibraryPage`.
- `docs/CHANGELOG.md` — Phase 5 entry.

## Open defaults (locked unless changed)

- Group labels: Exercises / Breathwork / Practice / Learn.
- Practice sessions log but do not advance plan day.
- Streak collapsed by default.
- "No data yet" under 1 completed session (not 7 days) — simpler and honest; the roadmap's 7-day threshold applies to multi-point trends we're deferring.
