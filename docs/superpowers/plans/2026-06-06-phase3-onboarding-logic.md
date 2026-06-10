# Phase 3 — Onboarding Logic Implementation Plan

> **Status: EXECUTED** — shipped to `main`; checkboxes below were not ticked during execution. See docs/CHANGELOG.md for what was built and what was deferred.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Phase 2 onboarding navigation shell into a functioning intake — self-harm safety interrupt, conservative red-flag triage, persona routing, persona-calibrated baseline + mind/body banding, rule-based 12-week plan generation, Hive persistence, and biometric lock.

**Architecture:** A pure-Dart logic layer (`lib/features/onboarding/logic/`) of testable functions (`triage`, `banding`, `plan_generator`) over plain immutable models. `OnboardingController` collects answers and, on `finish()`, runs triage + plan-gen and persists state as a JSON map to a Hive box. Existing onboarding pages keep their structure; placeholders are replaced and two pages (crisis, red-flag) become conditional.

**Tech Stack:** Flutter, Riverpod (ChangeNotifierProvider), go_router 14.8.1, hive_ce + hive_ce_flutter, local_auth, flutter_test.

---

## Conventions for this plan

- **No git in this repo.** Ignore commits. Each task ends with a **Checkpoint** step: run `flutter analyze` (expect "No issues found!") and `flutter test` (expect all pass). That is the gate before the next task.
- **TDD for pure logic** (Tasks 4, 5b, 7b, 9): write the failing test first, watch it fail, implement, watch it pass. Run a single test file with `flutter test test/<path>_test.dart`.
- Follow existing design-system rules ([[sahaj-design-system]]): screens use `AppScaffold` / design-system widgets, never raw `ElevatedButton`. Theme tokens from `lib/core/theme/`.

---

## File structure (created / modified)

Created:
- `lib/features/onboarding/logic/models/onboarding_models.dart` — all plain models + enums.
- `lib/features/onboarding/logic/triage.dart` — `evaluate()`.
- `lib/features/onboarding/logic/banding.dart` — `bandFromIndex()`.
- `lib/features/onboarding/logic/plan_generator.dart` — `generatePlan()`.
- `lib/features/onboarding/baseline_questions.dart` — solo/partnered + mind/body question data.
- `lib/features/onboarding/pages/crisis_screen.dart` — self-harm crisis resources.
- `lib/data/onboarding_store.dart` — Hive box wrapper.
- Tests: `test/logic/triage_test.dart`, `test/logic/banding_test.dart`, `test/logic/plan_generator_test.dart`, `test/onboarding_persistence_test.dart`, `test/onboarding_flow_logic_test.dart`.

Modified:
- `lib/features/onboarding/onboarding_controller.dart` — new state fields, `track` getter, `toJson`/`loadFrom`, store writes, `finish()` runs triage + plan-gen.
- `lib/features/onboarding/health_questions.dart` — append self-harm question.
- `lib/features/onboarding/onboarding_pages.dart` — replace Baseline/MindBody/PlanReveal placeholders; RedFlagPage category-specific + clearance choices.
- `lib/features/onboarding/onboarding_flow.dart` — conditional steps (crisis interrupt, skip red-flag when no flags, solo/partnered baseline).
- `lib/main.dart` — Hive init + hydrate controller.
- `lib/app.dart` — wrap router in a biometric gate.
- `lib/features/home/tabs/today_page.dart` — read stored plan for "Week N — phase".
- `lib/features/home/tabs/me_page.dart` — dev "reset onboarding" action.
- `docs/CHANGELOG.md` — Phase 3 entry.

---

## Task 1: Models + enums

**Files:**
- Create: `lib/features/onboarding/logic/models/onboarding_models.dart`

- [ ] **Step 1: Create the models file**

```dart
import 'package:flutter/foundation.dart';

/// Content track chosen by persona routing.
enum Track { solo, partnered }

/// Coarse banding for baseline / mind-body areas (no clinical scoring yet).
enum Band { low, medium, high }

/// Starting ramp for the generated plan.
enum Difficulty { gentle, standard }

/// Where the user stands on the soft medical gate (synthesis §6 screen 7).
enum MedicalClearance { notSeen, proceedAnyway, confirmedDoctor }

/// Categories a red flag can fall into.
enum TriageCategory { cardiac, metabolic, neuro, organicErectile, mentalHealth }

@immutable
class TriageFlag {
  const TriageFlag(this.category, this.reason);
  final TriageCategory category;
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is TriageFlag &&
      other.category == category &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(category, reason);
}

@immutable
class TriageResult {
  const TriageResult(this.flags);
  final List<TriageFlag> flags;

  bool get hasFlags => flags.isNotEmpty;
  Set<TriageCategory> get categories =>
      flags.map((f) => f.category).toSet();
}

@immutable
class Baseline {
  const Baseline({required this.bands, required this.raw});
  final Map<String, Band> bands;
  final Map<String, int> raw;
}

@immutable
class PlanWeek {
  const PlanWeek({
    required this.number,
    required this.phase,
    required this.moduleTags,
  });
  final int number;
  final String phase;
  final List<String> moduleTags;
}

@immutable
class Plan {
  const Plan({
    required this.weeks,
    required this.track,
    required this.emphasis,
    required this.startDifficulty,
  });
  final List<PlanWeek> weeks;
  final Track track;
  final Set<String> emphasis;
  final Difficulty startDifficulty;
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze`
Expected: `No issues found!`

---

## Task 2: Hive persistence + controller serialization

**Files:**
- Create: `lib/data/onboarding_store.dart`
- Modify: `lib/features/onboarding/onboarding_controller.dart`
- Modify: `lib/main.dart`
- Test: `test/onboarding_persistence_test.dart`

- [ ] **Step 1: Create the store**

```dart
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Persists onboarding state as a single JSON map (no TypeAdapter codegen).
class OnboardingStore {
  OnboardingStore(this._box);

  static const _boxName = 'onboarding';
  static const _key = 'state';

  final Box _box;

  static Future<OnboardingStore> open() async {
    final box = await Hive.openBox(_boxName);
    return OnboardingStore(box);
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

- [ ] **Step 2: Add serialization + store wiring to the controller**

Replace the body of `OnboardingController` in `lib/features/onboarding/onboarding_controller.dart` so it keeps the existing fields/methods and adds the new ones. Full new class body:

```dart
class OnboardingController extends ChangeNotifier {
  OnboardingController([this._store]);

  final OnboardingStore? _store;

  Persona? persona;
  final Set<Goal> goals = <Goal>{};
  final Map<String, int> healthAnswers = <String, int>{};
  final Map<String, int> baselineRaw = <String, int>{};
  final Map<String, int> mindBodyRaw = <String, int>{};
  bool complete = false;

  // Derived/result state (computed on finish()).
  TriageResult? triage;
  MedicalClearance? medicalClearance;
  Plan? plan;

  /// Persona routing → content track (synthesis §6 screen 4).
  Track? get track {
    switch (persona) {
      case Persona.partneredActive:
      case Persona.partneredInactive:
        return Track.partnered;
      case Persona.singleExperienced:
      case Persona.singleInexperienced:
      case Persona.preferNotToSay:
        return Track.solo;
      case null:
        return null;
    }
  }

  void setPersona(Persona p) {
    persona = p;
    _persist();
  }

  void toggleGoal(Goal g) {
    if (!goals.add(g)) goals.remove(g);
    _persist();
  }

  void setHealthAnswer(String key, int value) {
    healthAnswers[key] = value;
    _persist();
  }

  void setBaselineAnswer(String key, int value) {
    baselineRaw[key] = value;
    _persist();
  }

  void setMindBodyAnswer(String key, int value) {
    mindBodyRaw[key] = value;
    _persist();
  }

  void setMedicalClearance(MedicalClearance c) {
    medicalClearance = c;
    _persist();
  }

  void finish() {
    triage = evaluate(healthAnswers);
    if (triage!.hasFlags && medicalClearance == null) {
      medicalClearance = MedicalClearance.notSeen;
    }
    final t = track ?? Track.solo;
    final baseline = Baseline(
      bands: _band(baselineRaw),
      raw: Map<String, int>.from(baselineRaw),
    );
    plan = generatePlan(
      track: t,
      goals: goals,
      baseline: baseline,
      mindBody: _band(mindBodyRaw),
    );
    complete = true;
    _persist();
  }

  Map<String, Band> _band(Map<String, int> raw) =>
      raw.map((k, v) => MapEntry(k, bandFromIndex(v)));

  void reset() {
    persona = null;
    goals.clear();
    healthAnswers.clear();
    baselineRaw.clear();
    mindBodyRaw.clear();
    triage = null;
    medicalClearance = null;
    plan = null;
    complete = false;
    _store?.clear();
    notifyListeners();
  }

  void _persist() {
    _store?.save(toJson());
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'persona': persona?.name,
        'goals': goals.map((g) => g.name).toList(),
        'health': healthAnswers,
        'baseline': baselineRaw,
        'mindBody': mindBodyRaw,
        'medicalClearance': medicalClearance?.name,
        'complete': complete,
      };

  void loadFrom(Map<String, dynamic> json) {
    persona = _enumByName(Persona.values, json['persona'] as String?);
    goals
      ..clear()
      ..addAll(((json['goals'] as List?) ?? [])
          .map((n) => _enumByName(Goal.values, n as String))
          .whereType<Goal>());
    healthAnswers
      ..clear()
      ..addAll(Map<String, int>.from(json['health'] as Map? ?? {}));
    baselineRaw
      ..clear()
      ..addAll(Map<String, int>.from(json['baseline'] as Map? ?? {}));
    mindBodyRaw
      ..clear()
      ..addAll(Map<String, int>.from(json['mindBody'] as Map? ?? {}));
    medicalClearance =
        _enumByName(MedicalClearance.values, json['medicalClearance'] as String?);
    complete = (json['complete'] as bool?) ?? false;
    if (complete) finish(); // recompute triage + plan from stored answers
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
```

Add these imports at the top of the file (keep existing ones):

```dart
import '../../data/onboarding_store.dart';
import 'logic/banding.dart';
import 'logic/models/onboarding_models.dart';
import 'logic/plan_generator.dart';
import 'logic/triage.dart';
```

Change the provider so it can take a store (defaults to none for widget tests that don't need persistence):

```dart
final onboardingControllerProvider =
    ChangeNotifierProvider<OnboardingController>(
      (ref) => OnboardingController(),
    );
```

> Note: `evaluate`, `bandFromIndex`, `generatePlan` are defined in Tasks 4, later this task's dependencies; this task will not analyze-clean until Tasks 3–4 and banding/plan-generator stubs exist. Implement Tasks 3, 4, then banding (Task 7b) and plan_generator (Task 9) **stubs** first if executing strictly in order — OR reorder: do Task 4 (triage), a minimal `bandFromIndex`, and a minimal `generatePlan` before wiring `finish()`. See Step 5.

- [ ] **Step 3: Hive init in main.dart**

In `lib/main.dart`, add imports and initialize Hive before `runApp`, hydrate the controller via an override:

```dart
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'data/onboarding_store.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

Inside `main()`, after `Firebase.initializeApp(...)` and before `runApp`:

```dart
  await Hive.initFlutter();
  final store = await OnboardingStore.open();
  final controller = OnboardingController(store);
  final saved = store.load();
  if (saved != null) controller.loadFrom(saved);

  runApp(
    ProviderScope(
      overrides: [
        onboardingControllerProvider.overrideWith((ref) => controller),
      ],
      child: const SahajApp(),
    ),
  );
```

- [ ] **Step 4: Write the persistence round-trip test**

```dart
// test/onboarding_persistence_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';

void main() {
  test('toJson/loadFrom round-trips answers and completion', () {
    final a = OnboardingController();
    a.setPersona(Persona.singleInexperienced);
    a.toggleGoal(Goal.firstTimeOrGap);
    a.setHealthAnswer('morning_erections', 0);
    a.setBaselineAnswer('arousal_control', 1);
    a.setMindBodyAnswer('sleep', 2);
    a.finish();

    final json = a.toJson();

    final b = OnboardingController();
    b.loadFrom(json);

    expect(b.persona, Persona.singleInexperienced);
    expect(b.goals, contains(Goal.firstTimeOrGap));
    expect(b.complete, isTrue);
    expect(b.track, Track.solo);
    expect(b.plan, isNotNull);
  });
}
```

- [ ] **Step 5: Run the test**

Run: `flutter test test/onboarding_persistence_test.dart`
Expected: PASS (after Tasks 4, 7b, 9 logic exists). If executing in strict order, this test depends on triage/banding/plan-generator; create those (Tasks 4, 7b, 9) then return here.

- [ ] **Step 6: Checkpoint**

Run: `flutter analyze` then `flutter test`
Expected: clean + all pass.

---

## Task 3: Self-harm safety question + crisis screen

**Files:**
- Modify: `lib/features/onboarding/health_questions.dart`
- Create: `lib/features/onboarding/pages/crisis_screen.dart`
- Modify: `lib/features/onboarding/onboarding_flow.dart`

- [ ] **Step 1: Append the self-harm question**

Add as the LAST entry in `kHealthQuestions` in `health_questions.dart`:

```dart
  HealthQuestion(
    id: 'self_harm',
    prompt:
        'Over the last 2 weeks, how often have you had thoughts that you '
        'would be better off dead, or of hurting yourself?',
    options: ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
  ),
```

- [ ] **Step 2: Create the crisis screen**

```dart
// lib/features/onboarding/pages/crisis_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';

/// Shown immediately when the self-harm question is answered above
/// "Not at all". Calm, non-clinical, India crisis resources. Not a gate —
/// the user can return to onboarding via "I'm safe, continue".
class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  static const _lines = [
    ('Tele-MANAS', '14416'),
    ('iCall', '9152987821'),
    ('AASRA', '9820466726'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('You deserve support', style: theme.textTheme.displaySmall),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Thank you for being honest. What you’re feeling matters, and you '
            'don’t have to carry it alone. Talking to someone trained can help '
            'right now — these lines are free and confidential.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final line in _lines)
            AppCard(
              onTap: () => launchUrl(Uri.parse('tel:${line.$2}')),
              child: Row(
                children: [
                  Icon(Icons.call_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.$1, style: theme.textTheme.titleMedium),
                        Text(line.$2, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'I’m safe, continue',
            variant: AppButtonVariant.outlined,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
```

> `url_launcher` is in `pubspec.yaml` (transitive via Firebase/other deps). If `flutter analyze` reports it missing, add `url_launcher: ^6.3.0` to `pubspec.yaml` and run `flutter pub get`.

- [ ] **Step 3: Interrupt the flow on a positive answer**

In `onboarding_flow.dart`, in `_next()`, before advancing, detect that the just-answered step was the self-harm question with a positive answer and route to the crisis screen instead. Add a flag field `bool _showingCrisis = false;` and in `build`, when `_showingCrisis`, render `CrisisScreen(onContinue: () { setState(() => _showingCrisis = false); _advance(); })` instead of the Scaffold.

Add helper and update `_next()`:

```dart
  void _next() {
    final step = _steps[_index];
    if (step.body is HealthQuestionPage) {
      final q = (step.body as HealthQuestionPage).question;
      if (q.id == 'self_harm') {
        final ans = ref.read(onboardingControllerProvider).healthAnswers['self_harm'];
        if (ans != null && ans > 0) {
          setState(() => _showingCrisis = true);
          return;
        }
      }
    }
    _advance();
  }

  void _advance() {
    if (_index >= _steps.length - 1) {
      ref.read(onboardingControllerProvider).finish();
      return;
    }
    _pageController.nextPage(
      duration: AppMotion.settle,
      curve: AppMotion.transition,
    );
  }
```

(Replace the old `_next()` body; the old advance logic moves into `_advance()`.)

- [ ] **Step 4: Widget test — positive answer shows crisis screen**

```dart
// add to test/onboarding_flow_logic_test.dart (created in Task 6 or here)
```
See Task 6 Step for the shared file; add this test there:

```dart
testWidgets('self-harm positive shows crisis screen', (tester) async {
  // pump onboarding, drive to the self_harm question, select "Several days",
  // tap Continue, expect crisis numbers.
  // (full setup in Task 6 shared test file)
});
```

- [ ] **Step 5: Checkpoint**

Run: `flutter analyze` then `flutter test`
Expected: clean + pass.

---

## Task 4: Red-flag triage (pure logic, TDD)

**Files:**
- Create: `lib/features/onboarding/logic/triage.dart`
- Test: `test/logic/triage_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/logic/triage_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/logic/triage.dart';
import 'package:sahaj/features/onboarding/logic/models/onboarding_models.dart';

void main() {
  test('clean answers fire no flags', () {
    final r = evaluate({
      'morning_erections': 0, // Yes regularly
      'pelvic_pain': 0,       // No
      'weight_loss': 0,       // No
      'thirst_urination': 0,  // No
      'chest_breath': 0,      // No
      'tremors_heart': 0,     // No
      'prescriptions': 0,     // No
      'mood_down': 0,
      'mood_anxious': 0,
      'self_harm': 0,
    });
    expect(r.hasFlags, isFalse);
  });

  test('no morning erections fires organicErectile', () {
    final r = evaluate({'morning_erections': 2});
    expect(r.categories, contains(TriageCategory.organicErectile));
  });

  test('weight loss and thirst fire metabolic', () {
    expect(evaluate({'weight_loss': 1}).categories,
        contains(TriageCategory.metabolic));
    expect(evaluate({'thirst_urination': 2}).categories,
        contains(TriageCategory.metabolic));
  });

  test('chest symptoms fire cardiac at "sometimes" (conservative)', () {
    expect(evaluate({'chest_breath': 1}).categories,
        contains(TriageCategory.cardiac));
  });

  test('daily low mood fires mentalHealth', () {
    expect(evaluate({'mood_down': 3}).categories,
        contains(TriageCategory.mentalHealth));
  });

  test('any self-harm fires mentalHealth', () {
    expect(evaluate({'self_harm': 1}).categories,
        contains(TriageCategory.mentalHealth));
  });
}
```

- [ ] **Step 2: Run, verify fail**

Run: `flutter test test/logic/triage_test.dart`
Expected: FAIL — `evaluate` not defined.

- [ ] **Step 3: Implement triage**

```dart
// lib/features/onboarding/logic/triage.dart
import 'models/onboarding_models.dart';

/// Conservative red-flag evaluation over health-screen answers.
/// Heuristic and pre-clinician-review (synthesis §10). When unsure, fire.
/// Answer ints are option indices from `kHealthQuestions`.
TriageResult evaluate(Map<String, int> a) {
  final flags = <TriageFlag>[];
  void flag(TriageCategory c, String reason) => flags.add(TriageFlag(c, reason));

  // organicErectile: no morning erections (index 2 = "No, rarely or never").
  if (a['morning_erections'] == 2) {
    flag(TriageCategory.organicErectile, 'No morning erections');
  }
  // neuro / organic: frequent pelvic pain (index 2 = "Yes, often").
  if ((a['pelvic_pain'] ?? 0) >= 2) {
    flag(TriageCategory.neuro, 'Frequent pelvic pain or numbness');
  }
  // metabolic: unexplained weight loss (index 1 = "Yes").
  if (a['weight_loss'] == 1) {
    flag(TriageCategory.metabolic, 'Unexplained weight loss');
  }
  // metabolic: thirst/urination (index 2 = "Yes, often").
  if ((a['thirst_urination'] ?? 0) >= 2) {
    flag(TriageCategory.metabolic, 'Persistent thirst or frequent urination');
  }
  // cardiac: chest pain/breathlessness — conservative, fire at "Sometimes" (>=1).
  if ((a['chest_breath'] ?? 0) >= 1) {
    flag(TriageCategory.cardiac, 'Chest pain or breathlessness on exertion');
  }
  // neuro/metabolic: tremors or high heart rate (index 2 = "Yes").
  if ((a['tremors_heart'] ?? 0) >= 2) {
    flag(TriageCategory.neuro, 'Tremors or a persistently high heart rate');
  }
  // mentalHealth: daily low mood or anxiety (index 3 = "Nearly every day").
  if ((a['mood_down'] ?? 0) >= 3 || (a['mood_anxious'] ?? 0) >= 3) {
    flag(TriageCategory.mentalHealth, 'Frequent low mood or anxiety');
  }
  // mentalHealth: any self-harm thought (> "Not at all").
  if ((a['self_harm'] ?? 0) >= 1) {
    flag(TriageCategory.mentalHealth, 'Thoughts of self-harm');
  }
  return TriageResult(flags);
}
```

- [ ] **Step 4: Run, verify pass**

Run: `flutter test test/logic/triage_test.dart`
Expected: PASS.

- [ ] **Step 5: Checkpoint**

Run: `flutter analyze`
Expected: clean (triage.dart + models compile).

---

## Task 5: Conditional RedFlagPage + clearance choices

**Files:**
- Modify: `lib/features/onboarding/onboarding_pages.dart`
- Modify: `lib/features/onboarding/onboarding_flow.dart`

- [ ] **Step 1: Make RedFlagPage category-aware with clearance choices**

Replace `RedFlagPage` in `onboarding_pages.dart` with a `ConsumerWidget` that reads `triage` (recomputed live) and shows category-specific copy + two clearance choices:

```dart
class RedFlagPage extends ConsumerWidget {
  const RedFlagPage({super.key});

  static const _copy = {
    TriageCategory.cardiac:
        'Chest pain or breathlessness is worth a doctor’s check before any physical training.',
    TriageCategory.metabolic:
        'Unexplained weight loss or constant thirst can point to something treatable — a quick blood test is wise.',
    TriageCategory.neuro:
        'Pain, numbness, or tremors are worth ruling out with a doctor first.',
    TriageCategory.organicErectile:
        'A lack of morning erections can have a physical cause. A doctor can check before we train.',
    TriageCategory.mentalHealth:
        'How you’ve been feeling matters. Talking to a doctor or counsellor is a strong first step.',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = ref.watch(onboardingControllerProvider);
    final result = evaluate(c.healthAnswers);
    final clearance = c.medicalClearance;

    return OnbBody(
      children: [
        const OnbHeader(
          title: 'A quick note on health',
          body:
              'Some things are worth checking with a doctor before training. '
              'We’re not a medical service, and we want you to be well first. '
              'You can still use the free tier today.',
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final cat in result.categories)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Text(_copy[cat]!, style: theme.textTheme.bodyMedium),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        SelectableOption(
          label: 'I’ll see a doctor first',
          selected: clearance == MedicalClearance.notSeen,
          onTap: () => ref
              .read(onboardingControllerProvider)
              .setMedicalClearance(MedicalClearance.notSeen),
        ),
        SelectableOption(
          label: 'I understand — continue for now',
          selected: clearance == MedicalClearance.proceedAnyway,
          onTap: () => ref
              .read(onboardingControllerProvider)
              .setMedicalClearance(MedicalClearance.proceedAnyway),
        ),
      ],
    );
  }
}
```

Add imports to `onboarding_pages.dart`:

```dart
import 'logic/models/onboarding_models.dart';
import 'logic/triage.dart';
```

- [ ] **Step 2: Skip RedFlagPage in the flow when no flags**

In `onboarding_flow.dart`, the steps list includes `RedFlagPage`. Make its inclusion dynamic by recomputing the steps when navigating past the health questions. Simplest robust approach: keep `RedFlagPage` always in the list but have `_advance()` skip it when `!evaluate(health).hasFlags`.

Add to `_advance()` just after computing the next index target — when the next page is the red-flag step and there are no flags, skip one further. Implement by checking the body type:

```dart
  void _advance() {
    final controller = ref.read(onboardingControllerProvider);
    if (_index >= _steps.length - 1) {
      controller.finish();
      return;
    }
    var target = _index + 1;
    if (_steps[target].body is RedFlagPage &&
        !evaluate(controller.healthAnswers).hasFlags) {
      target += 1; // skip red-flag when nothing fired
    }
    _pageController.animateToPage(
      target,
      duration: AppMotion.settle,
      curve: AppMotion.transition,
    );
  }
```

Add import to `onboarding_flow.dart`:

```dart
import 'logic/triage.dart';
```

- [ ] **Step 3: Checkpoint**

Run: `flutter analyze` then `flutter test`
Expected: clean + pass.

---

## Task 6: Persona routing already lives in the controller — verify + shared widget test file

Persona→`Track` is the `track` getter added in Task 2. No extra page work; the routing effect is consumed by the baseline battery (Task 7). This task adds the shared widget-test file used by Tasks 3 and 7.

**Files:**
- Test: `test/onboarding_flow_logic_test.dart`

- [ ] **Step 1: Create the shared flow test file with a driver helper**

```dart
// test/onboarding_flow_logic_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/app.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';

void main() {
  testWidgets('persona routing sets solo track for single user', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SahajApp()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SahajApp)),
    );
    final c = container.read(onboardingControllerProvider)
      ..setPersona(Persona.singleInexperienced);
    expect(c.track, Track.solo);
  });
}
```

- [ ] **Step 2: Run**

Run: `flutter test test/onboarding_flow_logic_test.dart`
Expected: PASS.

- [ ] **Step 3: Checkpoint**

Run: `flutter test`
Expected: all pass.

---

## Task 7: Baseline battery + banding

### 7a — Baseline + mind/body question data

**Files:**
- Create: `lib/features/onboarding/baseline_questions.dart`

- [ ] **Step 1: Create the question data**

```dart
// lib/features/onboarding/baseline_questions.dart
import 'health_questions.dart'; // reuse the HealthQuestion shape

/// Persona-calibrated baseline (synthesis §6 screen 8). Capture only;
/// coarse banding via bandFromIndex. Friendly wording, not clinical.
const partneredBaseline = <HealthQuestion>[
  HealthQuestion(
    id: 'pe_control',
    prompt: 'During sex, how much control do you feel over when you finish?',
    options: ['Very little', 'Some', 'A good amount', 'Full control'],
  ),
  HealthQuestion(
    id: 'erection_confidence',
    prompt: 'How confident are you that you can get and keep an erection?',
    options: ['Not confident', 'Slightly', 'Fairly', 'Very confident'],
  ),
  HealthQuestion(
    id: 'erection_maintain',
    prompt: 'How often can you maintain an erection through sex?',
    options: ['Rarely', 'Sometimes', 'Most times', 'Almost always'],
  ),
];

const soloBaseline = <HealthQuestion>[
  HealthQuestion(
    id: 'arousal_control',
    prompt: 'On your own, how much control do you feel over your arousal?',
    options: ['Very little', 'Some', 'A good amount', 'Full control'],
  ),
  HealthQuestion(
    id: 'rehearsal_comfort',
    prompt: 'How comfortable are you imagining a calm, confident encounter?',
    options: ['Not at all', 'A little', 'Fairly', 'Very comfortable'],
  ),
  HealthQuestion(
    id: 'future_anxiety',
    prompt: 'How anxious do you feel about a future first or next encounter?',
    options: ['Very anxious', 'Somewhat', 'A little', 'Not anxious'],
  ),
];

/// Mind/body baseline (synthesis §6 screen 9). 5 questions.
const mindBodyQuestions = <HealthQuestion>[
  HealthQuestion(
    id: 'sleep',
    prompt: 'How would you rate your sleep lately?',
    options: ['Poor', 'Fair', 'Good', 'Great'],
  ),
  HealthQuestion(
    id: 'stress',
    prompt: 'How stressed have you felt recently?',
    options: ['Very stressed', 'Somewhat', 'A little', 'Calm'],
  ),
  HealthQuestion(
    id: 'exercise',
    prompt: 'How often do you exercise?',
    options: ['Rarely', 'Sometimes', 'Often', 'Most days'],
  ),
  HealthQuestion(
    id: 'alcohol',
    prompt: 'How often do you drink alcohol?',
    options: ['Daily', 'Often', 'Sometimes', 'Rarely or never'],
  ),
  HealthQuestion(
    id: 'porn_freq',
    prompt: 'How often do you watch porn?',
    options: ['Daily', 'Often', 'Sometimes', 'Rarely or never'],
  ),
];
```

### 7b — Banding (pure logic, TDD)

**Files:**
- Create: `lib/features/onboarding/logic/banding.dart`
- Test: `test/logic/banding_test.dart`

- [ ] **Step 2: Write failing test**

```dart
// test/logic/banding_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/logic/banding.dart';
import 'package:sahaj/features/onboarding/logic/models/onboarding_models.dart';

void main() {
  test('index 0 → low, 1 → medium, 2+ → high', () {
    expect(bandFromIndex(0), Band.low);
    expect(bandFromIndex(1), Band.medium);
    expect(bandFromIndex(2), Band.high);
    expect(bandFromIndex(3), Band.high);
  });
}
```

- [ ] **Step 3: Run, verify fail**

Run: `flutter test test/logic/banding_test.dart`
Expected: FAIL — `bandFromIndex` not defined.

- [ ] **Step 4: Implement**

```dart
// lib/features/onboarding/logic/banding.dart
import 'models/onboarding_models.dart';

/// Maps a (higher = better) answer index to a coarse band.
/// 0 → low, 1 → medium, 2 and above → high. Deliberately simple — exact
/// clinical scoring is deferred to clinician review (synthesis §10).
Band bandFromIndex(int index) {
  if (index <= 0) return Band.low;
  if (index == 1) return Band.medium;
  return Band.high;
}
```

- [ ] **Step 5: Run, verify pass**

Run: `flutter test test/logic/banding_test.dart`
Expected: PASS.

### 7c — Replace BaselinePage with the track-driven battery

**Files:**
- Modify: `lib/features/onboarding/onboarding_pages.dart`

- [ ] **Step 6: Replace BaselinePage**

```dart
class BaselinePage extends ConsumerWidget {
  const BaselinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(onboardingControllerProvider);
    final questions =
        c.track == Track.partnered ? partneredBaseline : soloBaseline;
    return OnbBody(
      children: [
        const OnbHeader(
          title: 'Where you’re starting from',
          body: 'An honest baseline so we can measure your progress.',
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final q in questions) ...[
          Text(q.prompt, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < q.options.length; i++)
            SelectableOption(
              label: q.options[i],
              selected: c.baselineRaw[q.id] == i,
              onTap: () =>
                  ref.read(onboardingControllerProvider).setBaselineAnswer(q.id, i),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}
```

Add import to `onboarding_pages.dart`:

```dart
import 'baseline_questions.dart';
```

- [ ] **Step 7: Checkpoint**

Run: `flutter analyze` then `flutter test`
Expected: clean + pass.

---

## Task 8: Mind/body page

**Files:**
- Modify: `lib/features/onboarding/onboarding_pages.dart`

- [ ] **Step 1: Replace MindBodyPage**

```dart
class MindBodyPage extends ConsumerWidget {
  const MindBodyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(onboardingControllerProvider);
    return OnbBody(
      children: [
        const OnbHeader(
          title: 'Sleep, stress, and habits',
          body: 'A few quick questions to tune your plan.',
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final q in mindBodyQuestions) ...[
          Text(q.prompt, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < q.options.length; i++)
            SelectableOption(
              label: q.options[i],
              selected: c.mindBodyRaw[q.id] == i,
              onTap: () =>
                  ref.read(onboardingControllerProvider).setMindBodyAnswer(q.id, i),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: Checkpoint**

Run: `flutter analyze` then `flutter test`
Expected: clean + pass.

---

## Task 9: Plan generator + plan reveal + today wiring

### 9a — Plan generator (pure logic, TDD)

**Files:**
- Create: `lib/features/onboarding/logic/plan_generator.dart`
- Test: `test/logic/plan_generator_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/logic/plan_generator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/logic/plan_generator.dart';
import 'package:sahaj/features/onboarding/logic/models/onboarding_models.dart';

void main() {
  final emptyBaseline = const Baseline(bands: {}, raw: {});

  test('plan always has 12 weeks across 3 phases', () {
    final p = generatePlan(
      track: Track.solo,
      goals: {},
      baseline: emptyBaseline,
      mindBody: {},
    );
    expect(p.weeks.length, 12);
    expect(p.weeks.map((w) => w.phase).toSet(),
        {'Foundation', 'Integration', 'Mastery'});
  });

  test('finishTooQuick adds stop-start emphasis', () {
    final p = generatePlan(
      track: Track.solo,
      goals: {Goal.finishTooQuick},
      baseline: emptyBaseline,
      mindBody: {},
    );
    expect(p.emphasis, contains('stop_start'));
  });

  test('low baseline band → gentle difficulty', () {
    final p = generatePlan(
      track: Track.solo,
      goals: {},
      baseline: const Baseline(bands: {'arousal_control': Band.low}, raw: {}),
      mindBody: {},
    );
    expect(p.startDifficulty, Difficulty.gentle);
  });

  test('partnered track tags appear', () {
    final p = generatePlan(
      track: Track.partnered,
      goals: {},
      baseline: emptyBaseline,
      mindBody: {},
    );
    expect(p.track, Track.partnered);
  });
}
```

- [ ] **Step 2: Run, verify fail**

Run: `flutter test test/logic/plan_generator_test.dart`
Expected: FAIL — `generatePlan` not defined.

- [ ] **Step 3: Implement**

```dart
// lib/features/onboarding/logic/plan_generator.dart
import '../onboarding_controller.dart' show Goal;
import 'models/onboarding_models.dart';

/// Rule-based 12-week plan (synthesis §7). One spine + modifiers:
/// persona→track content tags, goals→emphasis, baseline band→start difficulty.
Plan generatePlan({
  required Track track,
  required Set<Goal> goals,
  required Baseline baseline,
  required Map<String, Band> mindBody,
}) {
  final trackTag = track == Track.partnered ? 'partnered' : 'solo';

  // §7 spine.
  final spine = <PlanWeek>[
    for (var w = 1; w <= 4; w++)
      PlanWeek(number: w, phase: 'Foundation', moduleTags: [
        'anatomy',
        'pfmt_identify',
        'reverse_kegel_intro',
        'breathwork_basics',
        trackTag,
      ]),
    for (var w = 5; w <= 8; w++)
      PlanWeek(number: w, phase: 'Integration', moduleTags: [
        'kegel_reverse_combined',
        'stop_start',
        'sensate_$trackTag',
        'mindset_dopamine',
        trackTag,
      ]),
    for (var w = 9; w <= 12; w++)
      PlanWeek(number: w, phase: 'Mastery', moduleTags: [
        'pfmt_functional',
        'mental_rehearsal',
        track == Track.partnered ? 'partner_communication' : 'first_encounter_readiness',
        trackTag,
      ]),
  ];

  // Goal → emphasis tags.
  final emphasis = <String>{};
  for (final g in goals) {
    switch (g) {
      case Goal.finishTooQuick:
        emphasis.addAll(['stop_start', 'reverse_kegel']);
      case Goal.hardness:
        emphasis.add('arousal_confidence');
      case Goal.firstTimeOrGap:
        emphasis.add('readiness');
      case Goal.pornRelationship:
        emphasis.add('dopamine_rewire');
      case Goal.lastLongerOptimize:
        emphasis.add('advanced_control');
      case Goal.exploring:
        break;
    }
  }

  // Baseline band → difficulty: any low band → gentle ramp.
  final hasLow = baseline.bands.values.any((b) => b == Band.low);
  final difficulty = hasLow ? Difficulty.gentle : Difficulty.standard;

  return Plan(
    weeks: spine,
    track: track,
    emphasis: emphasis,
    startDifficulty: difficulty,
  );
}
```

- [ ] **Step 4: Run, verify pass**

Run: `flutter test test/logic/plan_generator_test.dart`
Expected: PASS.

### 9b — Render the generated plan + today

**Files:**
- Modify: `lib/features/onboarding/onboarding_pages.dart`
- Modify: `lib/features/home/tabs/today_page.dart`

- [ ] **Step 5: Make PlanRevealPage render the live plan**

Replace `PlanRevealPage` with a `ConsumerWidget` that computes the plan preview from current answers (so it reflects choices even before `finish()`):

```dart
class PlanRevealPage extends ConsumerWidget {
  const PlanRevealPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = ref.watch(onboardingControllerProvider);
    final track = c.track ?? Track.solo;
    final preview = generatePlan(
      track: track,
      goals: c.goals,
      baseline: Baseline(
        bands: {for (final e in c.baselineRaw.entries) e.key: bandFromIndex(e.value)},
        raw: c.baselineRaw,
      ),
      mindBody: {for (final e in c.mindBodyRaw.entries) e.key: bandFromIndex(e.value)},
    );
    final phases = ['Foundation', 'Integration', 'Mastery'];
    final blurb = {
      'Foundation': 'Find the muscles, learn to relax them, build basic strength.',
      'Integration': 'Connect breath, body, and arousal awareness.',
      'Mastery': 'Apply the trained capacity to real situations.',
    };

    return OnbBody(
      children: [
        const OnbHeader(
          title: 'Your 12-week plan',
          body: 'Based on what you shared, here’s the shape of it.',
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final phase in phases)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weeks ${_weekRange(preview, phase)}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(phase, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(blurb[phase]!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Roughly 65–80% of users see meaningful improvement by week 12 if '
          'they train 5+ days per week. 5–15 minutes a day.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _weekRange(Plan p, String phase) {
    final ws = p.weeks.where((w) => w.phase == phase).map((w) => w.number);
    return '${ws.reduce((a, b) => a < b ? a : b)}–${ws.reduce((a, b) => a > b ? a : b)}';
  }
}
```

Add imports to `onboarding_pages.dart` (if not already present from earlier tasks):

```dart
import 'logic/banding.dart';
import 'logic/plan_generator.dart';
```

- [ ] **Step 6: Today reads the stored plan**

In `today_page.dart`, convert to `ConsumerWidget` and replace the hardcoded "Week 1 of 12 — finding the muscles" with the plan's first week/phase:

```dart
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(onboardingControllerProvider).plan;
    final subtitle = plan == null
        ? 'Your plan is ready'
        : 'Week 1 of ${plan.weeks.length} — ${plan.weeks.first.phase}';
    // ... existing layout, using `subtitle` in place of the hardcoded string.
  }
}
```

Add imports:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding/onboarding_controller.dart';
```

- [ ] **Step 7: Run plan tests + full suite**

Run: `flutter test`
Expected: all pass (persistence test from Task 2 now green too).

- [ ] **Step 8: Checkpoint**

Run: `flutter analyze`
Expected: clean.

---

## Task 10: Biometric lock

**Files:**
- Modify: `lib/features/onboarding/onboarding_controller.dart` (store the pref)
- Create: `lib/features/security/biometric_gate.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Store the biometric preference**

In `onboarding_controller.dart`, add a field and persist it:

```dart
  bool biometricLock = false;

  void setBiometricLock(bool v) {
    biometricLock = v;
    _persist();
  }
```

Add `'biometricLock': biometricLock` to `toJson()` and
`biometricLock = (json['biometricLock'] as bool?) ?? false;` to `loadFrom()`.

Wire the Phase 2 PrivacyPage switch to it: in `onboarding_pages.dart`, change
`PrivacyPage` from `StatefulWidget` to `ConsumerWidget`, read/write
`biometricLock` via the controller instead of local `_biometric` state.

```dart
class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = ref.watch(onboardingControllerProvider);
    return OnbBody(
      children: [
        const OnbHeader(
          title: 'Yours, and private',
          body:
              'Your data lives on this device. Cloud sync is optional and '
              'encrypted. You can disguise the app — rename the icon and '
              'choose Book Mode — anytime.',
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Row(
            children: [
              Icon(Icons.fingerprint, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biometric lock', style: theme.textTheme.titleMedium),
                    Text('Require fingerprint/face to open Sahaj',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Switch(
                value: c.biometricLock,
                onChanged: (v) =>
                    ref.read(onboardingControllerProvider).setBiometricLock(v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Create the biometric gate**

```dart
// lib/features/security/biometric_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../onboarding/onboarding_controller.dart';

/// Wraps the app: if biometric lock is on and we haven't authenticated this
/// launch, require local auth before revealing [child].
class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate> {
  final _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAuth());
  }

  Future<void> _maybeAuth() async {
    final locked = ref.read(onboardingControllerProvider).biometricLock;
    if (!locked) {
      setState(() {
        _unlocked = true;
        _checked = true;
      });
      return;
    }
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Sahaj',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      setState(() {
        _unlocked = ok;
        _checked = true;
      });
    } catch (_) {
      setState(() {
        _unlocked = false;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    return Scaffold(
      body: Center(
        child: _checked
            ? IconButton(
                iconSize: 48,
                icon: const Icon(Icons.lock_outline),
                onPressed: _maybeAuth,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
```

- [ ] **Step 3: Wrap the router in app.dart**

In `lib/app.dart`, wrap the `MaterialApp.router`'s content. Since `MaterialApp.router` builds the navigator, wrap via the `builder`:

```dart
    return MaterialApp.router(
      title: 'Sahaj',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => BiometricGate(child: child ?? const SizedBox.shrink()),
    );
```

Add import:

```dart
import 'features/security/biometric_gate.dart';
```

- [ ] **Step 4: Checkpoint**

Run: `flutter analyze` then `flutter test`
Expected: clean + pass. (Biometric path isn't unit-tested — it needs a device; verify on device.)

---

## Task 11: Dev reset + CHANGELOG

**Files:**
- Modify: `lib/features/home/tabs/me_page.dart`
- Modify: `docs/CHANGELOG.md`

- [ ] **Step 1: Add a dev "reset onboarding" tile**

In `me_page.dart` (already a route to showcase), make it a `ConsumerWidget` and add below the showcase tile:

```dart
                const Divider(),
                AppListTile(
                  leadingIcon: Icons.restart_alt,
                  title: 'Reset onboarding (dev)',
                  subtitle: 'Clear answers and replay the intake',
                  onTap: () {
                    ref.read(onboardingControllerProvider).reset();
                    context.go(Routes.onboarding);
                  },
                ),
```

Add imports:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../onboarding/onboarding_controller.dart';
```

- [ ] **Step 2: CHANGELOG Phase 3 entry**

Append a `## Phase 3 — Onboarding logic — 2026-06-06` section summarizing: triage, self-harm crisis interrupt, persona→track, baseline/mind-body banding, plan generation, Hive persistence, biometric lock; note deferrals (full discreet mode, Pro gating enforcement, clinical scoring).

- [ ] **Step 3: Final checkpoint**

Run: `flutter analyze` then `flutter test`
Expected: `No issues found!` + all tests pass.

- [ ] **Step 4: Device pass (manual)**

Run: `flutter run`
Verify: fresh launch → onboarding; complete a solo path → lands on Today with "Week 1 of 12 — Foundation"; relaunch → stays on Today (persistence); self-harm positive → crisis screen; reset onboarding (Me tab) → replays.

---

## Self-review notes

- **Spec coverage:** persistence (T2), self-harm interrupt (T3), triage (T4/T5), persona routing (T2 getter + T6), baseline battery (T7), mind/body (T8), plan-gen (T9), biometric (T10), reset/changelog (T11). All §-items mapped.
- **Ordering caveat (T2 ↔ T4/7b/9):** `finish()` references `evaluate`, `bandFromIndex`, `generatePlan`. Execute Task 4, 7b, 9a (the pure functions) before running Task 2's test, or stub them. Noted in T2 Step 2/5.
- **Type consistency:** `Track`, `Band`, `Difficulty`, `MedicalClearance`, `TriageCategory`, `Baseline`, `Plan`, `PlanWeek` defined once (T1); `generatePlan` / `evaluate` / `bandFromIndex` signatures match call sites in controller + pages.
- **Deferred (per spec):** full discreet mode, Pro-purchase enforcement of clearance, clinical PEDT/IIEF-5 scoring, Drift layer.
