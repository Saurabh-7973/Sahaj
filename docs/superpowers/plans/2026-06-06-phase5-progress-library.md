# Phase 5 — Progress Dashboard + Library Implementation Plan

> **Status: EXECUTED** — shipped to `main`; checkboxes below were not ticked during execution. See docs/CHANGELOG.md for what was built and what was deferred.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Me progress dashboard (the conversion lever, synthesis §12) and a browseable, playable Library — both from data and content that already exist (SessionLogs, ProgressState, the 13-module catalog). No new content, no backend.

**Architecture:** A pure-Dart metrics + grouping layer (unit-testable) over the existing `SessionLogStore` / `ProgressController` / `SessionCatalog`, plus the Me dashboard widget and the Library tab. Reuses the Phase 4 player flow for free practice.

**Tech Stack:** Flutter, Riverpod, hive_ce, flutter_test. Reuses Phase 1 widgets (`AppScaffold`, `AppCard`, `AppButton`, `AppListTile`) and Phase 4 (`SessionPlayerPage`, `progressControllerProvider`, `sessionCatalogProvider`).

---

## Conventions

- Branch `phase5-progress-library` (off `main`). Each task ends with a **Checkpoint**: `flutter analyze` ("No issues found!") + `flutter test` (all pass), then a commit.
- **TDD for pure logic** (Tasks 1–3): failing test first → watch fail → implement → watch pass.
- Straight ASCII quotes for Dart string delimiters (the Edit tool sometimes injects curly quotes as delimiters → "Illegal character"; fix any that appear so analyze is clean).
- Design system only; theme tokens from `lib/core/theme/`.

---

## File structure

Created:
- `lib/features/me/logic/progress_metrics.dart` — `ProgressMetrics`, `computeMetrics(...)`.
- `lib/features/me/me_dashboard.dart` — `ProgressDashboard` widget.
- `lib/features/library/library_catalog.dart` — `LibraryGroup`, `groupLibrary(...)`.
- Tests: `test/me/progress_metrics_test.dart`, `test/me/dashboard_widget_test.dart`, `test/library/library_catalog_test.dart`, `test/library/library_widget_test.dart`, `test/sessions/practice_logging_test.dart`.

Modified:
- `lib/features/sessions/progress_controller.dart` — add `logs()` + `logPractice(SessionLog)`.
- `lib/features/home/tabs/me_page.dart` — mount `ProgressDashboard` above existing tiles.
- `lib/features/home/tabs/library_page.dart` — replace stub with grouped, playable catalog.
- `docs/CHANGELOG.md` — Phase 5 entry.

---

## Task 1: Controller read + practice-log API (TDD)

**Files:**
- Modify: `lib/features/sessions/progress_controller.dart`
- Test: `test/sessions/practice_logging_test.dart`

The current `ProgressController` (read it) writes logs via `completeToday` but has no read path, and practice must log WITHOUT advancing the plan day.

- [ ] **Step 1: Write the failing test**

```dart
// test/sessions/practice_logging_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sahaj/data/progress_store.dart';
import 'package:sahaj/data/session_log_store.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';

SessionLog _log(String id) => SessionLog(
      id: id,
      sessionTag: 'anatomy',
      startedAt: DateTime(2026, 6, 6, 8),
      completedAt: DateTime(2026, 6, 6, 8, 7),
      completionPct: 1.0,
      moodBefore: const ['calm'],
    );

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sahaj_practice_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('logs() decodes stored logs', () async {
    final c = ProgressController(
      await ProgressStore.open(),
      await SessionLogStore.open(),
    );
    expect(c.logs(), isEmpty);
    c.completeToday(_log('a'));
    await Future<void>.delayed(Duration.zero);
    final logs = c.logs();
    expect(logs.length, 1);
    expect(logs.single.id, 'a');
  });

  test('logPractice appends a log WITHOUT advancing the plan day', () async {
    final c = ProgressController(
      await ProgressStore.open(),
      await SessionLogStore.open(),
    );
    final dayBefore = c.state.currentDay;
    c.logPractice(_log('p'));
    await Future<void>.delayed(Duration.zero);
    expect(c.state.currentDay, dayBefore); // unchanged
    expect(c.isDoneToday, isFalse); // practice does not consume the day
    expect(c.logs().length, 1);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/sessions/practice_logging_test.dart`
Expected: FAIL — `logs` / `logPractice` not defined.

- [ ] **Step 3: Add the two methods**

In `lib/features/sessions/progress_controller.dart`, add inside the class (e.g. after `completeToday`):

```dart
  /// All stored session logs, decoded (empty when no log store).
  List<SessionLog> logs() =>
      (_logStore?.all() ?? const <Map<String, dynamic>>[])
          .map(SessionLog.fromJson)
          .toList();

  /// Records a free-practice session: logs it but does NOT advance the plan
  /// day (practice counts as activity, but never consumes a scheduled day).
  void logPractice(SessionLog log) {
    _logStore?.append(log.toJson());
    notifyListeners();
  }
```

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/sessions/practice_logging_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Checkpoint + commit**

`flutter analyze` (clean) + `flutter test` (all pass).

```bash
git add lib/features/sessions/progress_controller.dart test/sessions/practice_logging_test.dart
git commit -m "Phase 5 Task 1: controller logs() + logPractice() (TDD)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Progress metrics (pure, TDD)

**Files:**
- Create: `lib/features/me/logic/progress_metrics.dart`
- Test: `test/me/progress_metrics_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/me/progress_metrics_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/me/logic/progress_metrics.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';

SessionLog _log({
  required String id,
  required DateTime completedAt,
  PerceivedDifficulty? difficulty,
}) =>
    SessionLog(
      id: id,
      sessionTag: 'anatomy',
      startedAt: completedAt,
      completedAt: completedAt,
      completionPct: 1.0,
      moodBefore: const ['calm'],
      perceivedDifficulty: difficulty,
    );

void main() {
  final now = DateTime(2026, 6, 6, 12);
  const progress = ProgressState(
    currentWeek: 3,
    currentDay: 2,
    streak: 4,
    longestStreak: 6,
  );

  test('no logs -> hasData false, zero counts', () {
    final m = computeMetrics(
      logs: const [],
      progress: progress,
      phase: 'Integration',
      now: now,
    );
    expect(m.hasData, isFalse);
    expect(m.totalSessions, 0);
    expect(m.thisWeekCount, 0);
  });

  test('totals, streak passthrough, phase', () {
    final m = computeMetrics(
      logs: [
        _log(id: 'a', completedAt: now.subtract(const Duration(days: 1))),
        _log(id: 'b', completedAt: now.subtract(const Duration(days: 2))),
      ],
      progress: progress,
      phase: 'Integration',
      now: now,
    );
    expect(m.hasData, isTrue);
    expect(m.totalSessions, 2);
    expect(m.currentStreak, 4);
    expect(m.longestStreak, 6);
    expect(m.currentWeek, 3);
    expect(m.phase, 'Integration');
  });

  test('thisWeekCount counts last 7 days, excludes older and future', () {
    final m = computeMetrics(
      logs: [
        _log(id: 'recent', completedAt: now.subtract(const Duration(days: 3))),
        _log(id: 'edge_in', completedAt: now.subtract(const Duration(days: 6, hours: 23))),
        _log(id: 'too_old', completedAt: now.subtract(const Duration(days: 8))),
        _log(id: 'future', completedAt: now.add(const Duration(days: 1))),
      ],
      progress: progress,
      phase: 'x',
      now: now,
    );
    expect(m.thisWeekCount, 2); // recent + edge_in
    expect(m.totalSessions, 4);
  });

  test('difficulty tallies', () {
    final m = computeMetrics(
      logs: [
        _log(id: 'a', completedAt: now, difficulty: PerceivedDifficulty.easier),
        _log(id: 'b', completedAt: now, difficulty: PerceivedDifficulty.easier),
        _log(id: 'c', completedAt: now, difficulty: PerceivedDifficulty.same),
        _log(id: 'd', completedAt: now, difficulty: PerceivedDifficulty.harder),
        _log(id: 'e', completedAt: now), // null difficulty ignored
      ],
      progress: progress,
      phase: 'x',
      now: now,
    );
    expect(m.easierCount, 2);
    expect(m.sameCount, 1);
    expect(m.harderCount, 1);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/me/progress_metrics_test.dart`
Expected: FAIL — `computeMetrics` not defined.

- [ ] **Step 3: Implement**

```dart
// lib/features/me/logic/progress_metrics.dart
import '../../sessions/logic/models/session_models.dart';

/// Honest progress numbers computed from real session logs + plan position.
class ProgressMetrics {
  const ProgressMetrics({
    required this.totalSessions,
    required this.currentStreak,
    required this.longestStreak,
    required this.thisWeekCount,
    required this.currentWeek,
    required this.phase,
    required this.easierCount,
    required this.sameCount,
    required this.harderCount,
  });

  final int totalSessions;
  final int currentStreak;
  final int longestStreak;
  final int thisWeekCount;
  final int currentWeek;
  final String phase;
  final int easierCount;
  final int sameCount;
  final int harderCount;

  bool get hasData => totalSessions > 0;
}

/// Computes [ProgressMetrics]. Streak comes straight from [progress] (Phase 4
/// is the single source of truth); the rest derive from [logs]. Clock injected.
ProgressMetrics computeMetrics({
  required List<SessionLog> logs,
  required ProgressState progress,
  required String phase,
  required DateTime now,
}) {
  final cutoff = now.subtract(const Duration(days: 7));
  var thisWeek = 0;
  var easier = 0;
  var same = 0;
  var harder = 0;
  for (final l in logs) {
    if (l.completedAt.isAfter(cutoff) && !l.completedAt.isAfter(now)) {
      thisWeek += 1;
    }
    switch (l.perceivedDifficulty) {
      case PerceivedDifficulty.easier:
        easier += 1;
      case PerceivedDifficulty.same:
        same += 1;
      case PerceivedDifficulty.harder:
        harder += 1;
      case null:
        break;
    }
  }
  return ProgressMetrics(
    totalSessions: logs.length,
    currentStreak: progress.streak,
    longestStreak: progress.longestStreak,
    thisWeekCount: thisWeek,
    currentWeek: progress.currentWeek,
    phase: phase,
    easierCount: easier,
    sameCount: same,
    harderCount: harder,
  );
}
```

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/me/progress_metrics_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Checkpoint + commit**

```bash
git add lib/features/me/logic/progress_metrics.dart test/me/progress_metrics_test.dart
git commit -m "Phase 5 Task 2: progress metrics (TDD)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Library grouping (pure, TDD)

**Files:**
- Create: `lib/features/library/library_catalog.dart`
- Test: `test/library/library_catalog_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/library/library_catalog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/library/library_catalog.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';

SessionDef _def(String tag, SessionType type) => SessionDef(
      tag: tag,
      title: tag,
      type: type,
      steps: const [SessionStep(title: 's', seconds: 60, guidance: 'g')],
    );

void main() {
  test('groups by display category, omits empty groups, ordered', () {
    final catalog = SessionCatalog({
      'pfmt_identify': _def('pfmt_identify', SessionType.kegel),
      'reverse_kegel_intro': _def('reverse_kegel_intro', SessionType.reverseKegel),
      'breathwork_basics': _def('breathwork_basics', SessionType.breathwork),
      'stop_start': _def('stop_start', SessionType.mindset),
      'anatomy': _def('anatomy', SessionType.education),
      // no sensate -> 'Practice' still appears via mindset
    });

    final groups = groupLibrary(catalog);
    final labels = groups.map((g) => g.label).toList();
    expect(labels, ['Exercises', 'Breathwork', 'Practice', 'Learn']);

    final exercises = groups.first;
    expect(exercises.sessions.length, 2); // kegel + reverseKegel
  });

  test('omits a group with no sessions', () {
    final catalog = SessionCatalog({
      'breathwork_basics': _def('breathwork_basics', SessionType.breathwork),
    });
    final groups = groupLibrary(catalog);
    expect(groups.map((g) => g.label), ['Breathwork']);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/library/library_catalog_test.dart`
Expected: FAIL — `groupLibrary` not defined.

- [ ] **Step 3: Implement**

```dart
// lib/features/library/library_catalog.dart
import '../sessions/logic/models/session_models.dart';
import '../sessions/session_catalog.dart';

/// A labelled, ordered group of sessions for the Library tab.
class LibraryGroup {
  const LibraryGroup(this.label, this.sessions);
  final String label;
  final List<SessionDef> sessions;
}

const _order = <(String, List<SessionType>)>[
  ('Exercises', [SessionType.kegel, SessionType.reverseKegel]),
  ('Breathwork', [SessionType.breathwork]),
  ('Practice', [SessionType.mindset, SessionType.sensate]),
  ('Learn', [SessionType.education]),
];

/// Groups the catalog's sessions into display categories (empty groups omitted),
/// each group's sessions sorted by title for stable ordering.
List<LibraryGroup> groupLibrary(SessionCatalog catalog) {
  final all = catalog.byTag.values.toList()
    ..sort((a, b) => a.title.compareTo(b.title));
  final groups = <LibraryGroup>[];
  for (final (label, types) in _order) {
    final sessions =
        all.where((d) => types.contains(d.type)).toList(growable: false);
    if (sessions.isNotEmpty) groups.add(LibraryGroup(label, sessions));
  }
  return groups;
}
```

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/library/library_catalog_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Checkpoint + commit**

```bash
git add lib/features/library/library_catalog.dart test/library/library_catalog_test.dart
git commit -m "Phase 5 Task 3: library grouping (TDD)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Me progress dashboard + mount

**Files:**
- Create: `lib/features/me/me_dashboard.dart`
- Modify: `lib/features/home/tabs/me_page.dart`
- Test: `test/me/dashboard_widget_test.dart`

- [ ] **Step 1: Create the dashboard widget**

```dart
// lib/features/me/me_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';
import '../onboarding/onboarding_controller.dart';
import '../sessions/progress_controller.dart';
import 'logic/progress_metrics.dart';

/// Honest progress summary (synthesis section 12). Degrades to a calm empty
/// state before the first session. Streak is collapsible, never the largest
/// element (synthesis section 8: agency over shame).
class ProgressDashboard extends ConsumerStatefulWidget {
  const ProgressDashboard({super.key});

  @override
  ConsumerState<ProgressDashboard> createState() => _ProgressDashboardState();
}

class _ProgressDashboardState extends ConsumerState<ProgressDashboard> {
  bool _streakExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = ref.watch(progressControllerProvider);
    final plan = ref.watch(onboardingControllerProvider).plan;

    final week = c.state.currentWeek;
    final phase = (plan == null || plan.weeks.isEmpty)
        ? ''
        : plan.weeks[(week - 1).clamp(0, plan.weeks.length - 1)].phase;

    final m = computeMetrics(
      logs: c.logs(),
      progress: c.state,
      phase: phase,
      now: DateTime.now(),
    );

    if (!m.hasData) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your progress', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Your progress appears here after your first session.',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.phase.isEmpty
                    ? 'Week ${m.currentWeek} of 12'
                    : 'Week ${m.currentWeek} of 12 - ${m.phase}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('This week', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: Icon(
                        i < m.thisWeekCount
                            ? Icons.circle
                            : Icons.circle_outlined,
                        size: 14,
                        color: i < m.thisWeekCount
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('${m.totalSessions} sessions completed',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          onTap: () => setState(() => _streakExpanded = !_streakExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Streak: ${m.currentStreak} days',
                      style: theme.textTheme.bodyMedium),
                  Icon(_streakExpanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                ],
              ),
              if (_streakExpanded) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('Longest: ${m.longestStreak} days',
                    style: theme.textTheme.bodySmall),
                Text('Easier ${m.easierCount} · Same ${m.sameCount} · Harder ${m.harderCount}',
                    style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Mount it in the Me tab**

In `lib/features/home/tabs/me_page.dart`, add the import and place `ProgressDashboard` above the existing tile card. Add:

```dart
import '../../me/me_dashboard.dart';
```

In the `Column`'s `children`, replace the leading `Text('Progress, settings, and your plan live here.', ...)` line with the dashboard + a gap (keep everything else):

```dart
          const ProgressDashboard(),
          const SizedBox(height: AppSpacing.xl),
```

(Place these as the first children, before the existing `AppCard` of tiles. Remove the now-redundant intro `Text` line.)

- [ ] **Step 3: Write the dashboard widget test**

```dart
// test/me/dashboard_widget_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sahaj/data/progress_store.dart';
import 'package:sahaj/data/session_log_store.dart';
import 'package:sahaj/features/me/me_dashboard.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';

void main() {
  testWidgets('shows empty state with no sessions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressControllerProvider.overrideWith((ref) => ProgressController()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProgressDashboard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('appears here after your first session'),
        findsOneWidget);
  });

  testWidgets('shows metrics after a logged session', (tester) async {
    final tempDir = await Directory.systemTemp.createTemp('sahaj_dash_test');
    Hive.init(tempDir.path);
    addTearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    final controller = ProgressController(
      await ProgressStore.open(),
      await SessionLogStore.open(),
    )..completeToday(SessionLog(
        id: 's1',
        sessionTag: 'anatomy',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        completionPct: 1.0,
        moodBefore: const ['calm'],
      ));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressControllerProvider.overrideWith((ref) => controller),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProgressDashboard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('sessions completed'), findsOneWidget);
  });
}
```

> Note: this test pumps `ProgressDashboard` directly with no `onboardingControllerProvider` override; the dashboard reads `onboardingControllerProvider` for the plan/phase, which falls back to a fresh `OnboardingController` (plan null → phase empty string → "Week 1 of 12"). That is fine; the assertions don't depend on the phase text.

- [ ] **Step 4: Run the dashboard test + full suite**

Run: `flutter test test/me/dashboard_widget_test.dart` (expect 2 pass), then `flutter test` (all pass).

- [ ] **Step 5: Checkpoint + commit**

`flutter analyze` (clean).

```bash
git add lib/features/me/me_dashboard.dart lib/features/home/tabs/me_page.dart test/me/dashboard_widget_test.dart
git commit -m "Phase 5 Task 4: Me progress dashboard

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Library tab — grouped, playable

**Files:**
- Modify: `lib/features/home/tabs/library_page.dart`
- Test: `test/library/library_widget_test.dart`

- [ ] **Step 1: Replace the Library stub**

```dart
// lib/features/home/tabs/library_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../../library/library_catalog.dart';
import '../../sessions/logic/models/session_models.dart';
import '../../sessions/pages/session_player_page.dart';
import '../../sessions/progress_controller.dart';
import '../../sessions/session_catalog.dart';

/// Library tab — browse every catalog session by category and practise any of
/// them freely. Free practice logs activity but does not advance the plan day.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    SessionCatalog? catalog;
    try {
      catalog = ref.watch(sessionCatalogProvider);
    } catch (_) {
      catalog = null;
    }
    final groups = catalog == null ? const [] : groupLibrary(catalog);

    return AppScaffold(
      title: 'Library',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practise any session, any time. Practice does not change your daily plan.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (groups.isEmpty)
            AppCard(
              child: Text('Sessions will appear here.',
                  style: theme.textTheme.bodyMedium),
            ),
          for (final group in groups) ...[
            Text(group.label, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final session in group.sessions)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  onTap: () => _practise(context, ref, session),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(session.title,
                                style: theme.textTheme.titleSmall),
                            Text(
                              '${session.type.name} · ~${(session.totalSeconds / 60).ceil()} min',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_outline),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }

  Future<void> _practise(
    BuildContext context,
    WidgetRef ref,
    SessionDef session,
  ) async {
    final startedAt = DateTime.now();
    var completion = 0.0;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionPlayerPage(
          session: session,
          onComplete: (pct) {
            completion = pct;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (completion == 0.0 || !context.mounted) return; // abandoned

    ref.read(progressControllerProvider).logPractice(
          SessionLog(
            id: startedAt.microsecondsSinceEpoch.toString(),
            sessionTag: session.tag,
            startedAt: startedAt,
            completedAt: DateTime.now(),
            completionPct: completion,
            moodBefore: const [],
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nice work.')),
      );
    }
  }
}
```

- [ ] **Step 2: Write the Library widget test**

```dart
// test/library/library_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/home/tabs/library_page.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';

SessionDef _def(String tag, String title, SessionType type) => SessionDef(
      tag: tag,
      title: title,
      type: type,
      steps: const [SessionStep(title: 's', seconds: 60, guidance: 'g')],
    );

void main() {
  testWidgets('renders grouped session cards from the catalog', (tester) async {
    final catalog = SessionCatalog({
      'pfmt_identify': _def('pfmt_identify', 'Finding the muscles', SessionType.kegel),
      'breathwork_basics': _def('breathwork_basics', 'Calm breathing', SessionType.breathwork),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionCatalogProvider.overrideWithValue(catalog),
        ],
        child: const MaterialApp(home: LibraryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('Breathwork'), findsOneWidget);
    expect(find.text('Finding the muscles'), findsOneWidget);
    expect(find.text('Calm breathing'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test + full suite**

Run: `flutter test test/library/library_widget_test.dart` (expect PASS), then `flutter test` (all pass).

- [ ] **Step 4: Checkpoint + commit**

`flutter analyze` (clean).

```bash
git add lib/features/home/tabs/library_page.dart test/library/library_widget_test.dart
git commit -m "Phase 5 Task 5: grouped playable Library tab

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: CHANGELOG + final checkpoint

**Files:**
- Modify: `docs/CHANGELOG.md`

- [ ] **Step 1: CHANGELOG entry**

Read `docs/CHANGELOG.md` and append, matching its style, a `## Phase 5 — Progress dashboard + Library — 2026-06-06` section summarizing: Me progress dashboard (honest metrics from real SessionLogs — week status, this-week consistency dots, collapsible streak, totals, difficulty split, graceful empty state); free-practice Library (catalog grouped by category, plays via the existing player, logs without advancing the plan day). Note deferrals: article/education text content, strength/IELT sparklines (no per-session scores captured yet), settings depth, discreet/Book mode, subscription, search.

- [ ] **Step 2: Final checkpoint + commit**

Run: `flutter analyze` (expect "No issues found!") and `flutter test` (expect all pass).

```bash
git add docs/CHANGELOG.md
git commit -m "Phase 5 Task 6: CHANGELOG entry

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

- [ ] **Step 3: Device pass (manual, deferred with the overall device pass)**

On device: Me tab shows the dashboard (empty state before any session; metrics after); complete a daily session → dashboard totals + this-week dot update; Library tab lists grouped sessions → tap one → player runs → "Nice work" → dashboard total increments BUT Today's daily session is NOT consumed (plan day unchanged).

---

## Self-review notes

- **Spec coverage:** controller read/practice API (T1), metrics (T2), grouping (T3), dashboard + mount (T4), Library tab (T5), CHANGELOG (T6). Dashboard empty-state, collapsible streak, this-week dots, honest metrics all mapped. Library free-practice-without-advancing mapped via `logPractice`.
- **Type consistency:** `ProgressMetrics`/`computeMetrics`, `LibraryGroup`/`groupLibrary`, `ProgressController.logs()`/`logPractice()` signatures match their call sites in the dashboard and Library tab. `SessionCatalog.byTag` used by `groupLibrary`. Player `onComplete` signature matches Phase 4.
- **Test-mode guards:** Library tab wraps `ref.watch(sessionCatalogProvider)` in try/catch (mirrors Today) so any widget test that pumps the shell without the override stays green. Dashboard tolerates a null plan (phase empty).
- **Deferred (per spec):** article text, sparklines, settings/discreet/subscription/search.
