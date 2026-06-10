# Phase 4 — Lean Session Player Implementation Plan

> **Status: EXECUTED** — shipped to `main`; checkboxes below were not ticked during execution. See docs/CHANGELOG.md for what was built and what was deferred.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Phase 3 plan (`moduleTags` per week) into a usable daily loop — Today → mood check-in → guided stepper session (text + timer, no audio) → reflection → progress advances — all on the existing Hive stack.

**Architecture:** A pure-Dart logic layer (`lib/features/sessions/logic/`) of testable functions (`scheduler`, `progress_logic`, `step_clock`, catalog parsing) over plain immutable models. Session content ships as a JSON asset parsed into a catalog at startup. Progress + session logs persist to Hive (same single-JSON-map pattern as `OnboardingStore`). UI is reached via imperative `Navigator` pushes from the Today tab; the go_router shell is untouched.

**Tech Stack:** Flutter, Riverpod (ChangeNotifierProvider / Provider), hive_ce + hive_ce_flutter, flutter_test. Reuses Phase 1 design-system widgets (`AppScaffold`, `AppCard`, `AppButton`, `AppProgressRing`, `AppTextField`) and Phase 3 models (`Plan`, `PlanWeek`).

---

## Conventions for this plan

- This repo IS a git repo (branch `phase4-session-player`, stacked on Phase 3). Each task ends with a **Checkpoint**: `flutter analyze` (expect "No issues found!") and `flutter test` (expect all pass), then a commit.
- **TDD for pure logic** (Tasks 1 partial, 3, 4, 5, 7): write the failing test first, run it to watch it fail, implement, run to watch it pass.
- **Curly-quote caution:** the Edit tool sometimes injects U+2018/U+2019 (' ') as Dart string DELIMITERS → "Illegal character" parse errors. Use straight ASCII quotes for delimiters; if a string contains a straight `'`, delimit with `"`. After editing, run `flutter analyze` and fix any illegal-character lines. Curly chars INSIDE strings are fine.
- Follow the design system: screens use `AppScaffold` + design-system widgets, theme tokens from `lib/core/theme/`.

---

## File structure

Created:
- `lib/features/sessions/logic/models/session_models.dart` — `SessionType`, `SessionStep`, `SessionDef`, `PerceivedDifficulty`, `SessionLog`, `ProgressState`.
- `lib/features/sessions/logic/catalog_parser.dart` — `parseCatalog(String json)`.
- `lib/features/sessions/logic/scheduler.dart` — `todaysSession(...)`.
- `lib/features/sessions/logic/progress_logic.dart` — `dateKey`, `isDoneToday`, `advanceAfterCompletion`.
- `lib/features/sessions/logic/step_clock.dart` — `StepTick`, `StepClock.tick`, `StepClock.fraction`.
- `lib/features/sessions/session_catalog.dart` — `SessionCatalog` (rootBundle load) + `sessionCatalogProvider`.
- `lib/features/sessions/progress_controller.dart` — `ProgressController` + `progressControllerProvider`.
- `lib/data/progress_store.dart` — Hive wrapper.
- `lib/data/session_log_store.dart` — Hive wrapper.
- `lib/features/sessions/checkin_moods.dart` — the 8 mood options.
- `lib/features/sessions/pages/mood_checkin_sheet.dart` — `showMoodCheckin(...)`.
- `lib/features/sessions/pages/session_player_page.dart` — `SessionPlayerPage`.
- `lib/features/sessions/pages/reflection_page.dart` — `ReflectionPage`.
- `assets/content/sessions.json` — starter catalog.
- Tests: `test/sessions/catalog_parser_test.dart`, `scheduler_test.dart`, `progress_logic_test.dart`, `step_clock_test.dart`, `models_json_test.dart`, `stores_test.dart`.

Modified:
- `pubspec.yaml` — register `assets/content/`.
- `lib/main.dart` — open progress + log boxes, load catalog, hydrate controller via overrides.
- `lib/features/home/tabs/today_page.dart` — session card + start flow.
- `lib/features/home/tabs/me_page.dart` — dev reset also clears progress + logs.
- `docs/CHANGELOG.md` — Phase 4 entry.

---

## Task 1: Session models

**Files:**
- Create: `lib/features/sessions/logic/models/session_models.dart`
- Test: `test/sessions/models_json_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/sessions/models_json_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';

void main() {
  test('SessionDef.fromJson parses steps and totalSeconds', () {
    final def = SessionDef.fromJson('pfmt_identify', {
      'title': 'Finding the muscles',
      'type': 'kegel',
      'steps': [
        {'title': 'Settle', 'seconds': 30, 'guidance': 'Relax.'},
        {'title': 'Locate', 'seconds': 60, 'guidance': 'Find them.'},
      ],
    });
    expect(def.tag, 'pfmt_identify');
    expect(def.type, SessionType.kegel);
    expect(def.steps.length, 2);
    expect(def.steps.first.title, 'Settle');
    expect(def.totalSeconds, 90);
  });

  test('SessionDef.fromJson falls back to education for unknown type', () {
    final def = SessionDef.fromJson('x', {
      'title': 'X',
      'type': 'not_a_type',
      'steps': <dynamic>[],
    });
    expect(def.type, SessionType.education);
  });

  test('SessionLog round-trips through json', () {
    final log = SessionLog(
      id: 'a1',
      sessionTag: 'stop_start',
      startedAt: DateTime.utc(2026, 6, 6, 8),
      completedAt: DateTime.utc(2026, 6, 6, 8, 7),
      completionPct: 1.0,
      moodBefore: const ['anxious', 'hopeful'],
      perceivedDifficulty: PerceivedDifficulty.same,
      journalNote: 'felt ok',
    );
    final back = SessionLog.fromJson(log.toJson());
    expect(back.id, 'a1');
    expect(back.sessionTag, 'stop_start');
    expect(back.startedAt, log.startedAt);
    expect(back.completedAt, log.completedAt);
    expect(back.completionPct, 1.0);
    expect(back.moodBefore, ['anxious', 'hopeful']);
    expect(back.perceivedDifficulty, PerceivedDifficulty.same);
    expect(back.journalNote, 'felt ok');
  });

  test('ProgressState round-trips and copyWith works', () {
    const s = ProgressState(
      currentWeek: 2,
      currentDay: 3,
      streak: 4,
      longestStreak: 5,
      lastCompletedDate: '2026-06-05',
    );
    final back = ProgressState.fromJson(s.toJson());
    expect(back.currentWeek, 2);
    expect(back.currentDay, 3);
    expect(back.streak, 4);
    expect(back.longestStreak, 5);
    expect(back.lastCompletedDate, '2026-06-05');
    expect(s.copyWith(streak: 9).streak, 9);
    expect(s.copyWith(streak: 9).currentWeek, 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/sessions/models_json_test.dart`
Expected: FAIL — `session_models.dart` / `SessionDef` not defined.

- [ ] **Step 3: Implement the models**

```dart
// lib/features/sessions/logic/models/session_models.dart
import 'package:flutter/foundation.dart';

/// Kind of training unit (drives the Today card label/icon).
enum SessionType { kegel, reverseKegel, breathwork, sensate, education, mindset }

SessionType _typeFromName(String? name) {
  for (final t in SessionType.values) {
    if (t.name == name) return t;
  }
  return SessionType.education;
}

/// One timed step within a session.
@immutable
class SessionStep {
  const SessionStep({
    required this.title,
    required this.seconds,
    required this.guidance,
  });

  final String title;
  final int seconds;
  final String guidance;

  factory SessionStep.fromJson(Map json) => SessionStep(
        title: json['title'] as String,
        seconds: (json['seconds'] as num).toInt(),
        guidance: json['guidance'] as String,
      );
}

/// A playable session, keyed by the plan's moduleTag.
@immutable
class SessionDef {
  const SessionDef({
    required this.tag,
    required this.title,
    required this.type,
    required this.steps,
  });

  final String tag;
  final String title;
  final SessionType type;
  final List<SessionStep> steps;

  int get totalSeconds =>
      steps.fold(0, (sum, s) => sum + s.seconds);

  factory SessionDef.fromJson(String tag, Map json) => SessionDef(
        tag: tag,
        title: json['title'] as String,
        type: _typeFromName(json['type'] as String?),
        steps: ((json['steps'] as List?) ?? const [])
            .map((s) => SessionStep.fromJson(s as Map))
            .toList(),
      );
}

/// Post-session self-report.
enum PerceivedDifficulty { easier, same, harder }

PerceivedDifficulty? _difficultyFromName(String? name) {
  if (name == null) return null;
  for (final d in PerceivedDifficulty.values) {
    if (d.name == name) return d;
  }
  return null;
}

/// A record of a completed (or partial) session.
@immutable
class SessionLog {
  const SessionLog({
    required this.id,
    required this.sessionTag,
    required this.startedAt,
    required this.completedAt,
    required this.completionPct,
    required this.moodBefore,
    this.perceivedDifficulty,
    this.journalNote,
  });

  final String id;
  final String sessionTag;
  final DateTime startedAt;
  final DateTime completedAt;
  final double completionPct;
  final List<String> moodBefore;
  final PerceivedDifficulty? perceivedDifficulty;
  final String? journalNote;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionTag': sessionTag,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'completionPct': completionPct,
        'moodBefore': moodBefore,
        'perceivedDifficulty': perceivedDifficulty?.name,
        'journalNote': journalNote,
      };

  factory SessionLog.fromJson(Map json) => SessionLog(
        id: json['id'] as String,
        sessionTag: json['sessionTag'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: DateTime.parse(json['completedAt'] as String),
        completionPct: (json['completionPct'] as num).toDouble(),
        moodBefore: List<String>.from(json['moodBefore'] as List? ?? const []),
        perceivedDifficulty:
            _difficultyFromName(json['perceivedDifficulty'] as String?),
        journalNote: json['journalNote'] as String?,
      );
}

/// Where the user is in the 12-week plan + streak bookkeeping.
@immutable
class ProgressState {
  const ProgressState({
    this.currentWeek = 1,
    this.currentDay = 1,
    this.streak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
  });

  final int currentWeek; // 1..12
  final int currentDay; // 1..7
  final int streak;
  final int longestStreak;
  final String? lastCompletedDate; // 'YYYY-MM-DD' local

  ProgressState copyWith({
    int? currentWeek,
    int? currentDay,
    int? streak,
    int? longestStreak,
    String? lastCompletedDate,
  }) =>
      ProgressState(
        currentWeek: currentWeek ?? this.currentWeek,
        currentDay: currentDay ?? this.currentDay,
        streak: streak ?? this.streak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      );

  Map<String, dynamic> toJson() => {
        'currentWeek': currentWeek,
        'currentDay': currentDay,
        'streak': streak,
        'longestStreak': longestStreak,
        'lastCompletedDate': lastCompletedDate,
      };

  factory ProgressState.fromJson(Map json) => ProgressState(
        currentWeek: (json['currentWeek'] as num?)?.toInt() ?? 1,
        currentDay: (json['currentDay'] as num?)?.toInt() ?? 1,
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
        lastCompletedDate: json['lastCompletedDate'] as String?,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/sessions/models_json_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Checkpoint + commit**

Run: `flutter analyze` (expect clean), `flutter test` (expect all pass).

```bash
git add lib/features/sessions/logic/models/session_models.dart test/sessions/models_json_test.dart
git commit -m "Phase 4 Task 1: session + progress models

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Catalog parser + sessions.json asset + loader

**Files:**
- Create: `lib/features/sessions/logic/catalog_parser.dart`
- Create: `assets/content/sessions.json`
- Create: `lib/features/sessions/session_catalog.dart`
- Modify: `pubspec.yaml`
- Test: `test/sessions/catalog_parser_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/sessions/catalog_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/catalog_parser.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';

const _json = '''
{
  "pfmt_identify": {
    "title": "Finding the muscles",
    "type": "kegel",
    "steps": [
      {"title": "Settle", "seconds": 30, "guidance": "Relax."},
      {"title": "Locate", "seconds": 60, "guidance": "Find them."}
    ]
  },
  "breathwork_basics": {
    "title": "Calm breathing",
    "type": "breathwork",
    "steps": [
      {"title": "Inhale", "seconds": 120, "guidance": "Slow breaths."}
    ]
  }
}
''';

void main() {
  test('parseCatalog builds a tag-keyed map of SessionDefs', () {
    final catalog = parseCatalog(_json);
    expect(catalog.keys, containsAll(['pfmt_identify', 'breathwork_basics']));
    expect(catalog['pfmt_identify']!.type, SessionType.kegel);
    expect(catalog['pfmt_identify']!.totalSeconds, 90);
    expect(catalog['breathwork_basics']!.steps.single.title, 'Inhale');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/sessions/catalog_parser_test.dart`
Expected: FAIL — `parseCatalog` not defined.

- [ ] **Step 3: Implement the parser**

```dart
// lib/features/sessions/logic/catalog_parser.dart
import 'dart:convert';

import 'models/session_models.dart';

/// Parses the sessions JSON asset into a tag-keyed catalog.
Map<String, SessionDef> parseCatalog(String jsonStr) {
  final raw = json.decode(jsonStr) as Map<String, dynamic>;
  return raw.map(
    (tag, value) => MapEntry(tag, SessionDef.fromJson(tag, value as Map)),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/sessions/catalog_parser_test.dart`
Expected: PASS.

- [ ] **Step 5: Create the starter content asset**

Create `assets/content/sessions.json`. It MUST contain an entry for every session-bearing moduleTag emitted by the Phase 3 plan generator. Those tags (from `lib/features/onboarding/logic/plan_generator.dart`) are: `anatomy`, `pfmt_identify`, `reverse_kegel_intro`, `breathwork_basics`, `kegel_reverse_combined`, `stop_start`, `sensate_solo`, `sensate_partnered`, `mindset_dopamine`, `pfmt_functional`, `mental_rehearsal`, `partner_communication`, `first_encounter_readiness`. (The `solo`/`partnered` track tags are NOT sessions and are intentionally absent.)

```json
{
  "anatomy": {
    "title": "Know the ground",
    "type": "education",
    "steps": [
      {"title": "Orient", "seconds": 60, "guidance": "We'll map the pelvic floor — the hammock of muscles that supports control. No action yet, just understanding."},
      {"title": "Picture it", "seconds": 60, "guidance": "Imagine a sling running front to back between your sit bones. That sling is what we train."},
      {"title": "Why it matters", "seconds": 60, "guidance": "A responsive pelvic floor means steadier control and stronger erections. Consistency beats intensity."}
    ]
  },
  "pfmt_identify": {
    "title": "Finding the muscles",
    "type": "kegel",
    "steps": [
      {"title": "Settle", "seconds": 30, "guidance": "Sit or lie comfortably. Breathe slowly and let your body soften."},
      {"title": "Locate", "seconds": 90, "guidance": "Imagine stopping the flow of urine. The muscles that tighten are your target. Keep stomach and thighs relaxed."},
      {"title": "Gentle holds", "seconds": 120, "guidance": "Squeeze for 3 seconds, release for 3. Breathe normally throughout."}
    ]
  },
  "reverse_kegel_intro": {
    "title": "Learning to let go",
    "type": "reverseKegel",
    "steps": [
      {"title": "Settle", "seconds": 30, "guidance": "Comfortable position, slow breath."},
      {"title": "Lengthen", "seconds": 120, "guidance": "On each exhale, gently push down and out — the opposite of a squeeze. This releases tension."},
      {"title": "Rest", "seconds": 60, "guidance": "Let everything soften. Notice the difference between holding and releasing."}
    ]
  },
  "breathwork_basics": {
    "title": "Calm breathing",
    "type": "breathwork",
    "steps": [
      {"title": "Settle", "seconds": 30, "guidance": "Close your eyes if that feels right."},
      {"title": "Box breath", "seconds": 180, "guidance": "Inhale 4, hold 4, exhale 4, hold 4. Let the rhythm steady your nervous system."},
      {"title": "Return", "seconds": 30, "guidance": "Let your breath return to normal. Notice the calm."}
    ]
  },
  "kegel_reverse_combined": {
    "title": "Squeeze and release",
    "type": "kegel",
    "steps": [
      {"title": "Warm up", "seconds": 60, "guidance": "A few slow breaths to begin."},
      {"title": "Combined sets", "seconds": 180, "guidance": "Squeeze for 5, release fully for 5, then a gentle reverse push for 5. Repeat."},
      {"title": "Cool down", "seconds": 60, "guidance": "Soften completely. Rest."}
    ]
  },
  "stop_start": {
    "title": "Stop-start control",
    "type": "mindset",
    "steps": [
      {"title": "Frame it", "seconds": 60, "guidance": "Stop-start trains you to recognise and ride the point of no return. This is a mental rehearsal of that skill."},
      {"title": "Rise and pause", "seconds": 180, "guidance": "Imagine arousal climbing. At a high point, pause and breathe until it settles. Repeat the rise and pause."},
      {"title": "Integrate", "seconds": 60, "guidance": "Notice you can influence the wave. Control is a skill you're building."}
    ]
  },
  "sensate_solo": {
    "title": "Sensate focus (solo)",
    "type": "sensate",
    "steps": [
      {"title": "Settle", "seconds": 60, "guidance": "Somewhere private and unhurried."},
      {"title": "Attend", "seconds": 180, "guidance": "Touch your own skin slowly, with curiosity not goal. Notice sensation for its own sake."},
      {"title": "Close", "seconds": 60, "guidance": "Rest. There was nothing to achieve — only to notice."}
    ]
  },
  "sensate_partnered": {
    "title": "Sensate focus (partnered)",
    "type": "sensate",
    "steps": [
      {"title": "Settle", "seconds": 60, "guidance": "If your partner is present, agree this is pressure-free. If not, rehearse it in your mind."},
      {"title": "Attend", "seconds": 180, "guidance": "Slow, curious touch with no goal of performance. Focus on giving and receiving sensation."},
      {"title": "Close", "seconds": 60, "guidance": "Rest together or reflect. Connection over outcome."}
    ]
  },
  "mindset_dopamine": {
    "title": "Resetting the reward",
    "type": "mindset",
    "steps": [
      {"title": "Understand", "seconds": 90, "guidance": "Overstimulation can dull arousal. This is about rebalancing, not shame."},
      {"title": "Reflect", "seconds": 120, "guidance": "Bring to mind real intimacy — warmth, touch, presence. Let that be the cue, not a screen."},
      {"title": "Commit", "seconds": 60, "guidance": "Choose one small change for today. Small and repeated wins."}
    ]
  },
  "pfmt_functional": {
    "title": "Strength in motion",
    "type": "kegel",
    "steps": [
      {"title": "Warm up", "seconds": 60, "guidance": "Slow breaths, gentle holds to begin."},
      {"title": "Functional holds", "seconds": 180, "guidance": "Longer holds — 8 to 10 seconds — with full release between. Quality over count."},
      {"title": "Cool down", "seconds": 60, "guidance": "Release and rest."}
    ]
  },
  "mental_rehearsal": {
    "title": "Mental rehearsal",
    "type": "mindset",
    "steps": [
      {"title": "Relax", "seconds": 60, "guidance": "Settle into calm. Slow breath."},
      {"title": "Rehearse", "seconds": 180, "guidance": "Picture a calm, confident encounter from start to finish. Feel steadiness, not pressure."},
      {"title": "Anchor", "seconds": 60, "guidance": "Carry that steady feeling with you. You've practised it."}
    ]
  },
  "partner_communication": {
    "title": "Talking together",
    "type": "education",
    "steps": [
      {"title": "Why it helps", "seconds": 60, "guidance": "Open talk lowers performance pressure more than any technique."},
      {"title": "Rehearse a line", "seconds": 150, "guidance": "Plan one honest, kind sentence you could say to your partner about going slow. Practise it in your mind."},
      {"title": "Commit", "seconds": 60, "guidance": "Decide when you might share it. No rush."}
    ]
  },
  "first_encounter_readiness": {
    "title": "Readiness",
    "type": "mindset",
    "steps": [
      {"title": "Reframe", "seconds": 60, "guidance": "A first or next encounter is an experience to share, not a test to pass."},
      {"title": "Rehearse calm", "seconds": 150, "guidance": "Picture yourself relaxed, present, and unhurried. Breathe into that image."},
      {"title": "Anchor", "seconds": 60, "guidance": "Confidence is built in small reps like this one."}
    ]
  }
}
```

- [ ] **Step 6: Register the asset in pubspec.yaml**

In `pubspec.yaml`, under the existing `flutter:` section, ensure an `assets:` list includes the content folder. If an `assets:` key already exists, add the line; otherwise create it:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/content/sessions.json
```

(If `assets/` is already broadly registered, confirm `sessions.json` is covered. Run `flutter pub get` after editing.)

- [ ] **Step 7: Implement the catalog loader**

```dart
// lib/features/sessions/session_catalog.dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logic/catalog_parser.dart';
import 'logic/models/session_models.dart';

/// Loads the bundled session content asset into a tag-keyed catalog.
class SessionCatalog {
  const SessionCatalog(this.byTag);

  final Map<String, SessionDef> byTag;

  SessionDef? operator [](String tag) => byTag[tag];

  static Future<SessionCatalog> load() async {
    final jsonStr =
        await rootBundle.loadString('assets/content/sessions.json');
    return SessionCatalog(parseCatalog(jsonStr));
  }
}

/// Overridden in main() with the catalog loaded at startup.
final sessionCatalogProvider = Provider<SessionCatalog>(
  (ref) => throw UnimplementedError('sessionCatalogProvider not overridden'),
);
```

- [ ] **Step 8: Checkpoint + commit**

Run: `flutter analyze` (expect clean), `flutter test` (expect all pass).

```bash
git add lib/features/sessions/logic/catalog_parser.dart lib/features/sessions/session_catalog.dart assets/content/sessions.json pubspec.yaml pubspec.lock test/sessions/catalog_parser_test.dart
git commit -m "Phase 4 Task 2: session content asset + catalog parser/loader

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Scheduler (pure, TDD)

**Files:**
- Create: `lib/features/sessions/logic/scheduler.dart`
- Test: `test/sessions/scheduler_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/sessions/scheduler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/logic/models/onboarding_models.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/logic/scheduler.dart';

SessionDef _def(String tag) => SessionDef(
      tag: tag,
      title: tag,
      type: SessionType.education,
      steps: const [SessionStep(title: 's', seconds: 60, guidance: 'g')],
    );

Plan _planWith(List<String> week1Tags) => Plan(
      weeks: [
        PlanWeek(number: 1, phase: 'Foundation', moduleTags: week1Tags),
      ],
      track: Track.solo,
      emphasis: const {},
      startDifficulty: Difficulty.standard,
    );

void main() {
  final catalog = {
    'anatomy': _def('anatomy'),
    'pfmt_identify': _def('pfmt_identify'),
  };

  test('picks a session from the week tags by day, ignoring non-catalog tags',
      () {
    final plan = _planWith(['anatomy', 'pfmt_identify', 'solo']);
    // day 1 -> playable[0], day 2 -> playable[1], day 3 -> wraps to playable[0]
    expect(todaysSession(plan: plan, week: 1, day: 1, catalog: catalog)!.tag,
        'anatomy');
    expect(todaysSession(plan: plan, week: 1, day: 2, catalog: catalog)!.tag,
        'pfmt_identify');
    expect(todaysSession(plan: plan, week: 1, day: 3, catalog: catalog)!.tag,
        'anatomy');
  });

  test('returns null when the week has no catalog-backed tags', () {
    final plan = _planWith(['solo', 'partnered']);
    expect(todaysSession(plan: plan, week: 1, day: 1, catalog: catalog), isNull);
  });

  test('returns null when the requested week is missing', () {
    final plan = _planWith(['anatomy']);
    expect(todaysSession(plan: plan, week: 5, day: 1, catalog: catalog), isNull);
  });

  test('is deterministic for the same inputs', () {
    final plan = _planWith(['anatomy', 'pfmt_identify']);
    final a = todaysSession(plan: plan, week: 1, day: 2, catalog: catalog);
    final b = todaysSession(plan: plan, week: 1, day: 2, catalog: catalog);
    expect(a!.tag, b!.tag);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/sessions/scheduler_test.dart`
Expected: FAIL — `todaysSession` not defined.

- [ ] **Step 3: Implement the scheduler**

```dart
// lib/features/sessions/logic/scheduler.dart
import '../../onboarding/logic/models/onboarding_models.dart';
import 'models/session_models.dart';

/// Picks today's session from the current week's moduleTags.
///
/// Keeps only tags that have a catalog entry (drops track tags like
/// `solo`/`partnered`), then selects by day-of-week with wraparound.
/// Returns null when the week is missing or has no playable tags.
SessionDef? todaysSession({
  required Plan plan,
  required int week,
  required int day,
  required Map<String, SessionDef> catalog,
}) {
  PlanWeek? planWeek;
  for (final w in plan.weeks) {
    if (w.number == week) {
      planWeek = w;
      break;
    }
  }
  if (planWeek == null) return null;

  final playable =
      planWeek.moduleTags.where(catalog.containsKey).toList(growable: false);
  if (playable.isEmpty) return null;

  final tag = playable[(day - 1) % playable.length];
  return catalog[tag];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/sessions/scheduler_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Checkpoint + commit**

Run: `flutter analyze`, `flutter test`.

```bash
git add lib/features/sessions/logic/scheduler.dart test/sessions/scheduler_test.dart
git commit -m "Phase 4 Task 3: today's-session scheduler (TDD)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Progress logic (pure, TDD)

**Files:**
- Create: `lib/features/sessions/logic/progress_logic.dart`
- Test: `test/sessions/progress_logic_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/sessions/progress_logic_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/logic/progress_logic.dart';

void main() {
  final now = DateTime(2026, 6, 6, 9); // a Saturday morning

  test('dateKey formats local Y-M-D zero-padded', () {
    expect(dateKey(DateTime(2026, 1, 3)), '2026-01-03');
    expect(dateKey(DateTime(2026, 12, 30)), '2026-12-30');
  });

  test('isDoneToday true only when lastCompletedDate is today', () {
    expect(isDoneToday(const ProgressState(), now), isFalse);
    expect(
        isDoneToday(
            const ProgressState(lastCompletedDate: '2026-06-06'), now),
        isTrue);
    expect(
        isDoneToday(
            const ProgressState(lastCompletedDate: '2026-06-05'), now),
        isFalse);
  });

  test('first completion sets streak 1, advances day, stamps date', () {
    final s = advanceAfterCompletion(const ProgressState(), now);
    expect(s.streak, 1);
    expect(s.longestStreak, 1);
    expect(s.currentDay, 2);
    expect(s.currentWeek, 1);
    expect(s.lastCompletedDate, '2026-06-06');
  });

  test('completing on consecutive day increments streak', () {
    const yesterday = ProgressState(
      currentWeek: 1,
      currentDay: 2,
      streak: 1,
      longestStreak: 1,
      lastCompletedDate: '2026-06-05',
    );
    final s = advanceAfterCompletion(yesterday, now);
    expect(s.streak, 2);
    expect(s.longestStreak, 2);
    expect(s.currentDay, 3);
  });

  test('a gap resets streak to 1 but keeps longestStreak', () {
    const stale = ProgressState(
      currentWeek: 1,
      currentDay: 4,
      streak: 3,
      longestStreak: 5,
      lastCompletedDate: '2026-06-03', // 3 days ago
    );
    final s = advanceAfterCompletion(stale, now);
    expect(s.streak, 1);
    expect(s.longestStreak, 5);
  });

  test('completing again the same day is a no-op (idempotent)', () {
    final once = advanceAfterCompletion(const ProgressState(), now);
    final twice = advanceAfterCompletion(once, now);
    expect(twice.currentDay, once.currentDay);
    expect(twice.streak, once.streak);
    expect(twice.lastCompletedDate, once.lastCompletedDate);
  });

  test('day 7 rolls over to next week day 1', () {
    const d7 = ProgressState(
      currentWeek: 1,
      currentDay: 7,
      streak: 6,
      longestStreak: 6,
      lastCompletedDate: '2026-06-05',
    );
    final s = advanceAfterCompletion(d7, now);
    expect(s.currentWeek, 2);
    expect(s.currentDay, 1);
  });

  test('week 12 day 7 stays put (plan complete)', () {
    const last = ProgressState(
      currentWeek: 12,
      currentDay: 7,
      streak: 10,
      longestStreak: 10,
      lastCompletedDate: '2026-06-05',
    );
    final s = advanceAfterCompletion(last, now);
    expect(s.currentWeek, 12);
    expect(s.currentDay, 7);
    expect(s.lastCompletedDate, '2026-06-06');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/sessions/progress_logic_test.dart`
Expected: FAIL — `dateKey` / `advanceAfterCompletion` not defined.

- [ ] **Step 3: Implement the progress logic**

```dart
// lib/features/sessions/logic/progress_logic.dart
import 'models/session_models.dart';

/// Local calendar-day key 'YYYY-MM-DD'.
String dateKey(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

/// True when today's session has already been completed.
bool isDoneToday(ProgressState s, DateTime now) =>
    s.lastCompletedDate == dateKey(now);

/// Applies a completion: advances position (calendar-gated), updates streak.
///
/// Idempotent within a calendar day. Streak increments only when the previous
/// completion was the day before; any gap resets it to 1. Position advances one
/// day, rolling week at day 7, capped at week 12 day 7 (plan complete).
ProgressState advanceAfterCompletion(ProgressState s, DateTime now) {
  final today = dateKey(now);
  if (s.lastCompletedDate == today) return s; // already done today

  final midnight = DateTime(now.year, now.month, now.day);
  final yesterday = dateKey(midnight.subtract(const Duration(days: 1)));
  final newStreak = (s.lastCompletedDate == yesterday) ? s.streak + 1 : 1;
  final newLongest =
      newStreak > s.longestStreak ? newStreak : s.longestStreak;

  var week = s.currentWeek;
  var day = s.currentDay;
  if (week < 12 || day < 7) {
    day += 1;
    if (day > 7) {
      day = 1;
      week += 1;
    }
  }

  return s.copyWith(
    currentWeek: week,
    currentDay: day,
    streak: newStreak,
    longestStreak: newLongest,
    lastCompletedDate: today,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/sessions/progress_logic_test.dart`
Expected: PASS (8 tests).

- [ ] **Step 5: Checkpoint + commit**

Run: `flutter analyze`, `flutter test`.

```bash
git add lib/features/sessions/logic/progress_logic.dart test/sessions/progress_logic_test.dart
git commit -m "Phase 4 Task 4: progress advance + streak logic (TDD)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Stepper clock logic (pure, TDD)

**Files:**
- Create: `lib/features/sessions/logic/step_clock.dart`
- Test: `test/sessions/step_clock_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/sessions/step_clock_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/step_clock.dart';

void main() {
  const durations = [3, 2]; // total 5 seconds, 2 steps

  test('tick counts down within a step', () {
    final t = StepClock.tick(durations, 0, 3);
    expect(t.step, 0);
    expect(t.secondsLeft, 2);
    expect(t.finished, isFalse);
  });

  test('tick at end of a non-last step advances to next step', () {
    final t = StepClock.tick(durations, 0, 1);
    expect(t.step, 1);
    expect(t.secondsLeft, 2); // next step full duration
    expect(t.finished, isFalse);
  });

  test('tick at end of the last step finishes', () {
    final t = StepClock.tick(durations, 1, 1);
    expect(t.finished, isTrue);
    expect(t.step, 1);
    expect(t.secondsLeft, 0);
  });

  test('fraction is elapsed-over-total', () {
    // start of step 0: 0 elapsed
    expect(StepClock.fraction(durations, 0, 3), 0.0);
    // step 0 with 1 left => 2 elapsed of 5
    expect(StepClock.fraction(durations, 0, 1), closeTo(2 / 5, 1e-9));
    // step 1 with 0 left => 5 of 5
    expect(StepClock.fraction(durations, 1, 0), 1.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/sessions/step_clock_test.dart`
Expected: FAIL — `StepClock` not defined.

- [ ] **Step 3: Implement the step clock**

```dart
// lib/features/sessions/logic/step_clock.dart

/// Result of advancing the session timer by one second.
class StepTick {
  const StepTick({
    required this.step,
    required this.secondsLeft,
    required this.finished,
  });

  final int step;
  final int secondsLeft;
  final bool finished;
}

/// Pure timekeeping for the stepper player. The widget owns the real Timer;
/// this maps (step, secondsLeft) one second forward.
class StepClock {
  const StepClock._();

  /// Advance one second. When the current step's last second elapses, move to
  /// the next step (reset to its full duration), or finish on the last step.
  static StepTick tick(List<int> durations, int step, int secondsLeft) {
    if (secondsLeft > 1) {
      return StepTick(
        step: step,
        secondsLeft: secondsLeft - 1,
        finished: false,
      );
    }
    // this step is ending
    if (step < durations.length - 1) {
      final next = step + 1;
      return StepTick(
        step: next,
        secondsLeft: durations[next],
        finished: false,
      );
    }
    return StepTick(step: step, secondsLeft: 0, finished: true);
  }

  /// Elapsed-over-total fraction for the overall progress ring (0..1).
  static double fraction(List<int> durations, int step, int secondsLeft) {
    final total = durations.fold<int>(0, (a, b) => a + b);
    if (total == 0) return 1.0;
    var elapsed = 0;
    for (var i = 0; i < step; i++) {
      elapsed += durations[i];
    }
    elapsed += durations[step] - secondsLeft;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/sessions/step_clock_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Checkpoint + commit**

Run: `flutter analyze`, `flutter test`.

```bash
git add lib/features/sessions/logic/step_clock.dart test/sessions/step_clock_test.dart
git commit -m "Phase 4 Task 5: stepper clock logic (TDD)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: Hive stores + round-trip test

**Files:**
- Create: `lib/data/progress_store.dart`
- Create: `lib/data/session_log_store.dart`
- Test: `test/sessions/stores_test.dart`

- [ ] **Step 1: Implement the progress store**

```dart
// lib/data/progress_store.dart
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Persists progress state as a single JSON map (mirrors OnboardingStore).
class ProgressStore {
  ProgressStore(this._box);

  static const _boxName = 'progress';
  static const _key = 'state';

  final Box _box;

  static Future<ProgressStore> open() async {
    final box = await Hive.openBox(_boxName);
    return ProgressStore(box);
  }

  Map<String, dynamic>? load() {
    final raw = _box.get(_key);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> save(Map<String, dynamic> json) => _box.put(_key, json);

  Future<void> clear() => _box.delete(_key);
}
```

- [ ] **Step 2: Implement the session-log store**

```dart
// lib/data/session_log_store.dart
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Append-only store of session logs (JSON maps under one list key).
class SessionLogStore {
  SessionLogStore(this._box);

  static const _boxName = 'session_logs';
  static const _key = 'logs';

  final Box _box;

  static Future<SessionLogStore> open() async {
    final box = await Hive.openBox(_boxName);
    return SessionLogStore(box);
  }

  List<Map<String, dynamic>> all() {
    final raw = _box.get(_key);
    if (raw == null) return [];
    return (raw as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> append(Map<String, dynamic> json) async {
    final logs = all()..add(json);
    await _box.put(_key, logs);
  }

  Future<void> clear() => _box.delete(_key);
}
```

- [ ] **Step 3: Write the round-trip test (real Hive in a temp dir)**

```dart
// test/sessions/stores_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sahaj/data/progress_store.dart';
import 'package:sahaj/data/session_log_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sahaj_hive_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('ProgressStore saves and loads a state map', () async {
    final store = await ProgressStore.open();
    expect(store.load(), isNull);
    await store.save({'currentWeek': 2, 'currentDay': 3, 'streak': 4});
    expect(store.load(), {'currentWeek': 2, 'currentDay': 3, 'streak': 4});
    await store.clear();
    expect(store.load(), isNull);
  });

  test('SessionLogStore appends logs in order', () async {
    final store = await SessionLogStore.open();
    expect(store.all(), isEmpty);
    await store.append({'id': 'a', 'sessionTag': 'anatomy'});
    await store.append({'id': 'b', 'sessionTag': 'stop_start'});
    final all = store.all();
    expect(all.length, 2);
    expect(all.first['id'], 'a');
    expect(all.last['id'], 'b');
  });
}
```

- [ ] **Step 4: Run the test**

Run: `flutter test test/sessions/stores_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Checkpoint + commit**

Run: `flutter analyze`, `flutter test`.

```bash
git add lib/data/progress_store.dart lib/data/session_log_store.dart test/sessions/stores_test.dart
git commit -m "Phase 4 Task 6: progress + session-log Hive stores

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 7: Progress controller + provider

**Files:**
- Create: `lib/features/sessions/progress_controller.dart`
- Test: `test/sessions/progress_controller_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/sessions/progress_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';

SessionLog _log() => SessionLog(
      id: 'x',
      sessionTag: 'anatomy',
      startedAt: DateTime(2026, 6, 6, 8),
      completedAt: DateTime(2026, 6, 6, 8, 7),
      completionPct: 1.0,
      moodBefore: const ['calm'],
    );

void main() {
  test('starts at week 1 day 1 with no store', () {
    final c = ProgressController();
    expect(c.state.currentWeek, 1);
    expect(c.state.currentDay, 1);
    expect(c.isDoneToday, isFalse);
  });

  test('completeToday advances state and marks done today', () {
    final c = ProgressController();
    final before = c.state.currentDay;
    c.completeToday(_log());
    expect(c.state.currentDay, before + 1);
    expect(c.isDoneToday, isTrue);
  });

  test('completeToday twice in a day is idempotent', () {
    final c = ProgressController();
    c.completeToday(_log());
    final dayAfterFirst = c.state.currentDay;
    c.completeToday(_log());
    expect(c.state.currentDay, dayAfterFirst);
  });

  test('loadFrom hydrates state', () {
    final c = ProgressController();
    c.loadFrom(const ProgressState(currentWeek: 3, currentDay: 2).toJson());
    expect(c.state.currentWeek, 3);
    expect(c.state.currentDay, 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/sessions/progress_controller_test.dart`
Expected: FAIL — `ProgressController` not defined.

- [ ] **Step 3: Implement the controller**

The controller's `isDoneToday` getter would clash with the free `isDoneToday` function from `progress_logic.dart`, so import that library aliased as `logic`:

```dart
// lib/features/sessions/progress_controller.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/progress_store.dart';
import '../../data/session_log_store.dart';
import 'logic/models/session_models.dart';
import 'logic/progress_logic.dart' as logic;

export 'logic/models/session_models.dart';

class ProgressController extends ChangeNotifier {
  ProgressController([this._store, this._logStore]);

  final ProgressStore? _store;
  final SessionLogStore? _logStore;

  ProgressState state = const ProgressState();

  bool get isDoneToday => logic.isDoneToday(state, DateTime.now());

  void loadFrom(Map<String, dynamic> json) {
    state = ProgressState.fromJson(json);
    notifyListeners();
  }

  void completeToday(SessionLog log) {
    _logStore?.append(log.toJson());
    state = logic.advanceAfterCompletion(state, DateTime.now());
    _store?.save(state.toJson());
    notifyListeners();
  }

  void reset() {
    state = const ProgressState();
    _store?.clear();
    _logStore?.clear();
    notifyListeners();
  }
}

final progressControllerProvider =
    ChangeNotifierProvider<ProgressController>((ref) => ProgressController());
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/sessions/progress_controller_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Checkpoint + commit**

Run: `flutter analyze`, `flutter test`.

```bash
git add lib/features/sessions/progress_controller.dart test/sessions/progress_controller_test.dart
git commit -m "Phase 4 Task 7: progress controller + provider

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 8: main.dart wiring (boxes + catalog + overrides)

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Wire startup loading and provider overrides**

Replace the body of `main()` after `Hive.initFlutter()` so it opens the new boxes, loads the catalog, hydrates the progress controller, and adds the overrides. Full new `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/onboarding_store.dart';
import 'data/progress_store.dart';
import 'data/session_log_store.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/sessions/progress_controller.dart';
import 'features/sessions/session_catalog.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();

  // Onboarding (Phase 2/3)
  final store = await OnboardingStore.open();
  final controller = OnboardingController(store);
  final saved = store.load();
  if (saved != null) controller.loadFrom(saved);

  // Sessions (Phase 4)
  final progressStore = await ProgressStore.open();
  final logStore = await SessionLogStore.open();
  final progress = ProgressController(progressStore, logStore);
  final savedProgress = progressStore.load();
  if (savedProgress != null) progress.loadFrom(savedProgress);

  final catalog = await SessionCatalog.load();

  runApp(
    ProviderScope(
      overrides: [
        onboardingControllerProvider.overrideWith((ref) => controller),
        progressControllerProvider.overrideWith((ref) => progress),
        sessionCatalogProvider.overrideWithValue(catalog),
      ],
      child: const SahajApp(),
    ),
  );
}
```

- [ ] **Step 2: Checkpoint + commit**

Run: `flutter analyze` (expect clean), `flutter test` (expect all pass — existing widget tests pump `SahajApp` without overrides, so `progressControllerProvider` falls back to a fresh `ProgressController()` and `sessionCatalogProvider` is only read by the Today card path; that path must tolerate the unoverridden catalog — see Task 11 Step 1, which guards it).

```bash
git add lib/main.dart
git commit -m "Phase 4 Task 8: wire session boxes + catalog + provider overrides

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 9: Mood check-in sheet

**Files:**
- Create: `lib/features/sessions/checkin_moods.dart`
- Create: `lib/features/sessions/pages/mood_checkin_sheet.dart`

- [ ] **Step 1: Define the moods**

```dart
// lib/features/sessions/checkin_moods.dart

/// A check-in mood option (key persisted, label shown).
class CheckinMood {
  const CheckinMood(this.key, this.label);
  final String key;
  final String label;
}

/// Fixed pre-session mood list (multi-select 1-3).
const kCheckinMoods = <CheckinMood>[
  CheckinMood('anxious', 'Anxious'),
  CheckinMood('hopeful', 'Hopeful'),
  CheckinMood('restless', 'Restless'),
  CheckinMood('disappointed', 'Disappointed'),
  CheckinMood('calm', 'Calm'),
  CheckinMood('distracted', 'Distracted'),
  CheckinMood('motivated', 'Motivated'),
  CheckinMood('low', 'Low'),
];
```

- [ ] **Step 2: Implement the sheet**

```dart
// lib/features/sessions/pages/mood_checkin_sheet.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../checkin_moods.dart';

/// Shows the pre-session mood sheet. Returns the selected mood keys (1-3),
/// or null if the user dismissed it (start aborted).
Future<List<String>?> showMoodCheckin(BuildContext context) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _MoodCheckinSheet(),
  );
}

class _MoodCheckinSheet extends StatefulWidget {
  const _MoodCheckinSheet();

  @override
  State<_MoodCheckinSheet> createState() => _MoodCheckinSheetState();
}

class _MoodCheckinSheetState extends State<_MoodCheckinSheet> {
  final _selected = <String>{};

  void _toggle(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else if (_selected.length < 3) {
        _selected.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you arriving?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text('Pick up to three.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final mood in kCheckinMoods)
                FilterChip(
                  label: Text(mood.label),
                  selected: _selected.contains(mood.key),
                  onSelected: (_) => _toggle(mood.key),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Begin session',
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.of(context).pop(_selected.toList()),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Checkpoint + commit**

Run: `flutter analyze`, `flutter test`.

```bash
git add lib/features/sessions/checkin_moods.dart lib/features/sessions/pages/mood_checkin_sheet.dart
git commit -m "Phase 4 Task 9: pre-session mood check-in sheet

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 10: Session player page

**Files:**
- Create: `lib/features/sessions/pages/session_player_page.dart`

- [ ] **Step 1: Implement the stepper player**

The player drives a 1-second `Timer.periodic`, advancing via `StepClock.tick`. On finish it calls `onComplete(completionPct)` (always 1.0 here) so the caller routes to reflection. Back-out (abandon) returns without completing.

```dart
// lib/features/sessions/pages/session_player_page.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/models/session_models.dart';
import '../logic/step_clock.dart';

/// Guided stepper player for a text/timer session. Calls [onComplete] with the
/// completion fraction (1.0) when the last step finishes.
class SessionPlayerPage extends StatefulWidget {
  const SessionPlayerPage({
    super.key,
    required this.session,
    required this.onComplete,
  });

  final SessionDef session;
  final ValueChanged<double> onComplete;

  @override
  State<SessionPlayerPage> createState() => _SessionPlayerPageState();
}

class _SessionPlayerPageState extends State<SessionPlayerPage> {
  late List<int> _durations;
  int _step = 0;
  int _secondsLeft = 0;
  bool _playing = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _durations = widget.session.steps.map((s) => s.seconds).toList();
    _secondsLeft = _durations.isEmpty ? 0 : _durations.first;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!_playing) return;
    final t = StepClock.tick(_durations, _step, _secondsLeft);
    if (t.finished) {
      _timer?.cancel();
      widget.onComplete(1.0);
      return;
    }
    setState(() {
      _step = t.step;
      _secondsLeft = t.secondsLeft;
    });
  }

  void _togglePlay() => setState(() => _playing = !_playing);

  void _prevStep() {
    if (_step == 0) return;
    setState(() {
      _step -= 1;
      _secondsLeft = _durations[_step];
    });
  }

  void _nextStep() {
    if (_step >= _durations.length - 1) {
      _timer?.cancel();
      widget.onComplete(1.0);
      return;
    }
    setState(() {
      _step += 1;
      _secondsLeft = _durations[_step];
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = widget.session.steps;
    final current = steps.isEmpty
        ? const SessionStep(title: '', seconds: 0, guidance: '')
        : steps[_step];
    final fraction = _durations.isEmpty
        ? 1.0
        : StepClock.fraction(_durations, _step, _secondsLeft);

    return AppScaffold(
      title: widget.session.title,
      leading: const BackButton(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text('Step ${_step + 1} of ${steps.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: AppSpacing.xl),
          AppProgressRing(
            value: fraction,
            size: 200,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_secondsLeft',
                    style: theme.textTheme.displayMedium),
                Text('seconds', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(current.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            current.guidance,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                iconSize: 32,
                onPressed: _step == 0 ? null : _prevStep,
                icon: const Icon(Icons.skip_previous),
              ),
              IconButton.filled(
                iconSize: 40,
                onPressed: _togglePlay,
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
              IconButton(
                iconSize: 32,
                onPressed: _nextStep,
                icon: const Icon(Icons.skip_next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Checkpoint + commit**

Run: `flutter analyze`, `flutter test`.

```bash
git add lib/features/sessions/pages/session_player_page.dart
git commit -m "Phase 4 Task 10: stepper session player

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 11: Reflection page

**Files:**
- Create: `lib/features/sessions/pages/reflection_page.dart`

- [ ] **Step 1: Implement the reflection screen**

Captures perceived difficulty + optional blurred note, builds a `SessionLog`, and returns it to the caller (Today wires `completeToday`). Shows a one-line tomorrow preview passed in by the caller.

```dart
// lib/features/sessions/pages/reflection_page.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../logic/models/session_models.dart';

/// Result returned to the caller when the user confirms their reflection.
class ReflectionResult {
  const ReflectionResult({required this.difficulty, this.note});
  final PerceivedDifficulty difficulty;
  final String? note;
}

/// Post-session reflection. Pops with a [ReflectionResult] on confirm.
class ReflectionPage extends StatefulWidget {
  const ReflectionPage({
    super.key,
    required this.sessionTitle,
    this.tomorrowPreview,
  });

  final String sessionTitle;
  final String? tomorrowPreview;

  @override
  State<ReflectionPage> createState() => _ReflectionPageState();
}

class _ReflectionPageState extends State<ReflectionPage> {
  PerceivedDifficulty? _difficulty;
  final _noteController = TextEditingController();
  bool _noteRevealed = false;

  static const _labels = {
    PerceivedDifficulty.easier: 'Easier',
    PerceivedDifficulty.same: 'About the same',
    PerceivedDifficulty.harder: 'Harder',
  };

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Reflection',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How did that feel?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          for (final d in PerceivedDifficulty.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                color: _difficulty == d
                    ? theme.colorScheme.primaryContainer
                    : null,
                onTap: () => setState(() => _difficulty = d),
                child: Text(_labels[d]!, style: theme.textTheme.titleMedium),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text('A note, if you want (private)',
              style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Stack(
            children: [
              AppTextField(
                controller: _noteController,
                hint: 'Anything you noticed...',
                maxLines: 3,
              ),
              if (!_noteRevealed)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _noteRevealed = true),
                        child: Container(
                          color: theme.colorScheme.surface.withValues(alpha: 0.1),
                          alignment: Alignment.center,
                          child: Text('Tap to write',
                              style: theme.textTheme.labelMedium),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (widget.tomorrowPreview != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Tomorrow', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.tomorrowPreview!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: 'Done',
            onPressed: _difficulty == null
                ? null
                : () => Navigator.of(context).pop(
                      ReflectionResult(
                        difficulty: _difficulty!,
                        note: _noteController.text.trim().isEmpty
                            ? null
                            : _noteController.text.trim(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Checkpoint + commit**

Run: `flutter analyze`, `flutter test`.

```bash
git add lib/features/sessions/pages/reflection_page.dart
git commit -m "Phase 4 Task 11: post-session reflection page

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 12: Today tab wiring + Me reset + CHANGELOG

**Files:**
- Modify: `lib/features/home/tabs/today_page.dart`
- Modify: `lib/features/home/tabs/me_page.dart`
- Modify: `docs/CHANGELOG.md`
- Test: `test/sessions/today_widget_test.dart`

- [ ] **Step 1: Rewrite TodayPage to drive the session loop**

```dart
// lib/features/home/tabs/today_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../sessions/logic/models/session_models.dart';
import '../../sessions/logic/scheduler.dart';
import '../../sessions/pages/mood_checkin_sheet.dart';
import '../../sessions/pages/reflection_page.dart';
import '../../sessions/pages/session_player_page.dart';
import '../../sessions/progress_controller.dart';
import '../../sessions/session_catalog.dart';

/// Today tab — derives today's session from the plan + progress and runs the
/// mood -> player -> reflection loop.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(onboardingControllerProvider).plan;
    final progress = ref.watch(progressControllerProvider);

    // Catalog may be unoverridden in widget tests; guard it.
    SessionCatalog? catalog;
    try {
      catalog = ref.watch(sessionCatalogProvider);
    } catch (_) {
      catalog = null;
    }

    final week = progress.state.currentWeek;
    final day = progress.state.currentDay;
    final session = (plan == null || catalog == null)
        ? null
        : todaysSession(
            plan: plan, week: week, day: day, catalog: catalog.byTag);

    return AppScaffold(
      title: 'Today',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan == null
                ? 'Finish onboarding to get your plan'
                : 'Week $week of 12 — ${plan.weeks.first.phase}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (progress.state.streak > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('🔥 ${progress.state.streak}-day streak',
                style: theme.textTheme.labelMedium),
          ],
          const SizedBox(height: AppSpacing.xl),
          _body(context, ref, theme, plan, session, progress),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Plan? plan,
    SessionDef? session,
    ProgressController progress,
  ) {
    if (plan == null) {
      return AppCard(
        child: Text('Your plan appears once onboarding is complete.',
            style: theme.textTheme.bodyMedium),
      );
    }
    if (progress.isDoneToday) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Done for today', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text('Come back tomorrow to keep the streak going.',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }
    if (session == null) {
      return AppCard(
        child: Text('A rest day — nothing scheduled. Breathe easy.',
            style: theme.textTheme.bodyMedium),
      );
    }
    final minutes = (session.totalSeconds / 60).ceil();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text('${session.type.name} · ~$minutes min',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Start session',
            onPressed: () => _startFlow(context, ref, session),
          ),
        ],
      ),
    );
  }

  Future<void> _startFlow(
    BuildContext context,
    WidgetRef ref,
    SessionDef session,
  ) async {
    final moods = await showMoodCheckin(context);
    if (moods == null || !context.mounted) return;

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

    final result = await Navigator.of(context).push<ReflectionResult>(
      MaterialPageRoute<ReflectionResult>(
        builder: (_) => ReflectionPage(sessionTitle: session.title),
      ),
    );
    if (result == null || !context.mounted) return;

    ref.read(progressControllerProvider).completeToday(
          SessionLog(
            id: startedAt.microsecondsSinceEpoch.toString(),
            sessionTag: session.tag,
            startedAt: startedAt,
            completedAt: DateTime.now(),
            completionPct: completion,
            moodBefore: moods,
            perceivedDifficulty: result.difficulty,
            journalNote: result.note,
          ),
        );
  }
}
```

- [ ] **Step 2: Extend the Me-tab dev reset to clear progress + logs**

In `lib/features/home/tabs/me_page.dart`, add the sessions import and extend the existing reset `onTap` to also reset progress. Add import:

```dart
import '../../sessions/progress_controller.dart';
```

Change the reset tile's `onTap` from:

```dart
                  onTap: () {
                    ref.read(onboardingControllerProvider).reset();
                    context.go(Routes.onboarding);
                  },
```

to:

```dart
                  onTap: () {
                    ref.read(onboardingControllerProvider).reset();
                    ref.read(progressControllerProvider).reset();
                    context.go(Routes.onboarding);
                  },
```

- [ ] **Step 3: Write a Today widget smoke test**

```dart
// test/sessions/today_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/home/tabs/today_page.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/sessions/logic/models/session_models.dart';
import 'package:sahaj/features/sessions/session_catalog.dart';

void main() {
  testWidgets('Today shows the session card from plan + catalog', (tester) async {
    final controller = OnboardingController()
      ..setPersona(Persona.singleInexperienced)
      ..finish(); // builds a solo plan; week 1 tags include 'anatomy'

    final catalog = SessionCatalog({
      'anatomy': const SessionDef(
        tag: 'anatomy',
        title: 'Know the ground',
        type: SessionType.education,
        steps: [SessionStep(title: 's', seconds: 60, guidance: 'g')],
      ),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider.overrideWith((ref) => controller),
          sessionCatalogProvider.overrideWithValue(catalog),
        ],
        child: const MaterialApp(home: TodayPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Know the ground'), findsOneWidget);
    expect(find.text('Start session'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run the test**

Run: `flutter test test/sessions/today_widget_test.dart`
Expected: PASS. (If the solo week-1 tags don't include `anatomy`, check `plan_generator.dart` — the Foundation spine lists `anatomy` first; the scheduler picks day-1 → first playable tag.)

- [ ] **Step 5: CHANGELOG entry**

Append to `docs/CHANGELOG.md` a `## Phase 4 — Session player (lean slice) — 2026-06-06` section summarizing: JSON content catalog, runtime scheduler, calendar-gated progress + streak, mood check-in, stepper player (text/timer), reflection + SessionLog, Today loop. Note deferrals: real audio + lock-screen, Firestore sync, Drift, Library/articles, analytics instrumentation. Match the existing CHANGELOG heading/bullet style.

- [ ] **Step 6: Final checkpoint + commit**

Run: `flutter analyze` (expect "No issues found!"), `flutter test` (expect all pass).

```bash
git add lib/features/home/tabs/today_page.dart lib/features/home/tabs/me_page.dart docs/CHANGELOG.md test/sessions/today_widget_test.dart
git commit -m "Phase 4 Task 12: Today session loop + dev reset + CHANGELOG

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

- [ ] **Step 7: Device pass (manual)**

Run: `flutter run`. Verify: complete onboarding → Today shows today's session card → Start → mood sheet → stepper plays and auto-advances steps → finishes → reflection → Done → Today shows "Done for today"; relaunch → still "Done for today" (progress persisted); next calendar day → new session; Me → Reset onboarding clears progress too.

---

## Self-review notes

- **Spec coverage:** JSON content (T2), models (T1), scheduler (T3), calendar progress + streak (T4), stepper logic (T5), stores (T6), controller (T7), startup wiring (T8), mood check-in (T9), player (T10), reflection + SessionLog (T11), Today loop + Me reset + CHANGELOG (T12). All spec sections mapped.
- **Type consistency:** `SessionDef`/`SessionStep`/`SessionLog`/`ProgressState`/`PerceivedDifficulty`/`SessionType` defined once (T1); `todaysSession`, `advanceAfterCompletion`, `isDoneToday`, `dateKey`, `StepClock.tick`/`fraction`, `parseCatalog` signatures match call sites in controller, player, and Today. `SessionCatalog.byTag` used by scheduler call in Today.
- **Naming caveat (T7):** the controller's `isDoneToday` getter clashes with the free `isDoneToday` function — resolved by importing `progress_logic.dart` as `logic` (final form shown). Implementer must use the final form.
- **Test-mode catalog guard (T8/T11/T12):** existing widget tests pump `SahajApp` without overriding `sessionCatalogProvider`; `TodayPage` wraps the `ref.watch(sessionCatalogProvider)` in try/catch and renders a safe state when absent. Confirm the existing `test/widget_test.dart` still passes after T12.
- **Deferred (per spec):** real audio + lock-screen, Firestore sync, Drift/SQLCipher, Library/articles, analytics instrumentation, no-log-on-abandon (intentional).
```
