# Analytics Instrumentation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A thin analytics seam over Firebase Analytics + typed event helpers, with the synthesis funnel wired from the UI layer. Pure logic never imports Firebase.

**Architecture:** `Analytics` interface (default `NoopAnalytics`, Firebase impl in `main`), `AppEvents` typed helpers (pure, tested via a `FakeAnalytics`), events fired from widgets at the key moments.

**Tech Stack:** Flutter, Riverpod, firebase_analytics (already a dep), flutter_test.

---

## Conventions

- Branch `analytics` (off `main`). Each task ends with a **Checkpoint**: `flutter analyze` ("No issues found!") + `flutter test` (all pass), then a commit.
- **TDD** for the pure helpers (Task 2). Straight ASCII quotes for Dart string delimiters.

---

## File structure

Created:
- `lib/core/analytics/analytics.dart` — `Analytics`, `NoopAnalytics`, `analyticsProvider`.
- `lib/core/analytics/firebase_analytics_service.dart` — `FirebaseAnalyticsService`.
- `lib/core/analytics/events.dart` — `AppEvents`, `appEventsProvider`.
- `test/support/fake_analytics.dart` — `FakeAnalytics` test double.
- Tests: `test/analytics/events_test.dart`, `test/analytics/onboarding_analytics_test.dart`.

Modified:
- `lib/main.dart` — override `analyticsProvider` + fire `app_opened`.
- `lib/features/onboarding/onboarding_flow.dart` — fire onboarding/persona/goal/plan/red-flag events on finish.
- `lib/features/home/tabs/today_page.dart` — fire mood/session events.
- `lib/features/settings/settings_page.dart` — fire export/delete/biometric events.
- `docs/CHANGELOG.md`.

---

## Task 1: Analytics seam + Firebase impl

**Files:**
- Create: `lib/core/analytics/analytics.dart`
- Create: `lib/core/analytics/firebase_analytics_service.dart`

- [ ] **Step 1: Create the interface + Noop + provider**

```dart
// lib/core/analytics/analytics.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The analytics seam. Everything depends on this, not on Firebase directly,
/// so the pure logic layer stays Firebase-free and tests use a fake.
abstract class Analytics {
  void logEvent(String name, [Map<String, Object>? params]);
  void setUserProperty(String name, String? value);
}

/// Default no-op implementation — used in tests and any un-overridden read,
/// so nothing reaches Firebase unless explicitly wired in main().
class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  void logEvent(String name, [Map<String, Object>? params]) {}

  @override
  void setUserProperty(String name, String? value) {}
}

/// Overridden in main() with FirebaseAnalyticsService.
final analyticsProvider = Provider<Analytics>((ref) => const NoopAnalytics());
```

- [ ] **Step 2: Create the Firebase implementation**

```dart
// lib/core/analytics/firebase_analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics.dart';

/// Forwards events to Firebase Analytics. Device/Firebase only — not unit-tested.
class FirebaseAnalyticsService implements Analytics {
  FirebaseAnalyticsService([FirebaseAnalytics? analytics])
      : _fa = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _fa;

  @override
  void logEvent(String name, [Map<String, Object>? params]) {
    _fa.logEvent(name: name, parameters: params);
  }

  @override
  void setUserProperty(String name, String? value) {
    _fa.setUserProperty(name: name, value: value);
  }
}
```

> Firebase's `logEvent`/`setUserProperty` return `Future`s; we fire-and-forget (void). If `flutter analyze` reports an `unawaited_futures`/`discarded_futures` lint (it should not, given the project's lint set), wrap the calls in `unawaited(...)` from `dart:async`.

- [ ] **Step 3: Checkpoint + commit**

`flutter analyze` (clean — firebase_analytics resolves) + `flutter test` (all pass).

```bash
git add lib/core/analytics/analytics.dart lib/core/analytics/firebase_analytics_service.dart
git commit -m "Analytics Task 1: analytics seam + Firebase impl

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Typed event helpers + fake (TDD)

**Files:**
- Create: `lib/core/analytics/events.dart`
- Create: `test/support/fake_analytics.dart`
- Test: `test/analytics/events_test.dart`

- [ ] **Step 1: Create the fake test double**

```dart
// test/support/fake_analytics.dart
import 'package:sahaj/core/analytics/analytics.dart';

/// Records analytics calls for assertions in tests.
class FakeAnalytics implements Analytics {
  final List<({String name, Map<String, Object>? params})> events = [];
  final Map<String, String?> userProps = {};

  @override
  void logEvent(String name, [Map<String, Object>? params]) =>
      events.add((name: name, params: params));

  @override
  void setUserProperty(String name, String? value) => userProps[name] = value;

  ({String name, Map<String, Object>? params})? last(String name) {
    for (final e in events.reversed) {
      if (e.name == name) return e;
    }
    return null;
  }
}
```

- [ ] **Step 2: Write the failing test**

```dart
// test/analytics/events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/analytics/events.dart';

import '../support/fake_analytics.dart';

void main() {
  test('sessionStarted logs name + params', () {
    final fake = FakeAnalytics();
    AppEvents(fake).sessionStarted('kegel', 2, 3);
    final e = fake.last('session_started')!;
    expect(e.params, {'sessionType': 'kegel', 'week': 2, 'day': 3});
  });

  test('goalSelected joins the goals list to a comma string', () {
    final fake = FakeAnalytics();
    AppEvents(fake).goalSelected(['finishTooQuick', 'hardness']);
    expect(fake.last('goal_selected')!.params,
        {'goals': 'finishTooQuick,hardness'});
  });

  test('planGenerated carries persona + goalCount', () {
    final fake = FakeAnalytics();
    AppEvents(fake).planGenerated('singleInexperienced', 2);
    expect(fake.last('plan_generated')!.params,
        {'persona': 'singleInexperienced', 'goalCount': 2});
  });

  test('moodCheckin joins moods; sessionCompleted carries pct', () {
    final fake = FakeAnalytics();
    AppEvents(fake)
      ..moodCheckin(['calm', 'hopeful'])
      ..sessionCompleted('breathwork', 1.0);
    expect(fake.last('mood_checkin_completed')!.params, {'moods': 'calm,hopeful'});
    expect(fake.last('session_completed')!.params,
        {'sessionType': 'breathwork', 'completionPct': 1.0});
  });

  test('parameterless events log just the name', () {
    final fake = FakeAnalytics();
    AppEvents(fake)
      ..appOpened()
      ..onboardingCompleted()
      ..accountDeleted();
    expect(fake.last('app_opened')!.params, isNull);
    expect(fake.last('onboarding_completed')!.params, isNull);
    expect(fake.last('account_deleted')!.params, isNull);
  });

  test('redFlagFired carries flagType', () {
    final fake = FakeAnalytics();
    AppEvents(fake).redFlagFired('cardiac');
    expect(fake.last('health_screen_red_flag_fired')!.params,
        {'flagType': 'cardiac'});
  });
}
```

- [ ] **Step 3: Run, verify FAIL**

Run: `flutter test test/analytics/events_test.dart`
Expected: FAIL — `AppEvents` not defined.

- [ ] **Step 4: Implement the helpers**

```dart
// lib/core/analytics/events.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics.dart';

/// Typed, centralized event helpers. Names + params live here once so call
/// sites stay clean and consistent. Firebase requires snake_case names <=40
/// chars and primitive param values, so list params are comma-joined.
class AppEvents {
  const AppEvents(this._a);

  final Analytics _a;

  void appOpened() => _a.logEvent('app_opened');

  void personaSelected(String persona) =>
      _a.logEvent('persona_selected', {'persona': persona});

  void goalSelected(List<String> goals) =>
      _a.logEvent('goal_selected', {'goals': goals.join(',')});

  void planGenerated(String persona, int goalCount) =>
      _a.logEvent('plan_generated', {'persona': persona, 'goalCount': goalCount});

  void onboardingCompleted() => _a.logEvent('onboarding_completed');

  void redFlagFired(String flagType) =>
      _a.logEvent('health_screen_red_flag_fired', {'flagType': flagType});

  void sessionStarted(String sessionType, int week, int day) =>
      _a.logEvent('session_started',
          {'sessionType': sessionType, 'week': week, 'day': day});

  void sessionCompleted(String sessionType, double completionPct) =>
      _a.logEvent('session_completed',
          {'sessionType': sessionType, 'completionPct': completionPct});

  void moodCheckin(List<String> moods) =>
      _a.logEvent('mood_checkin_completed', {'moods': moods.join(',')});

  void biometricLockEnabled() => _a.logEvent('biometric_lock_enabled');

  void dataExported() => _a.logEvent('data_exported');

  void accountDeleted() => _a.logEvent('account_deleted');
}

/// Reads the active Analytics (Noop by default, Firebase in main()).
final appEventsProvider =
    Provider<AppEvents>((ref) => AppEvents(ref.watch(analyticsProvider)));
```

- [ ] **Step 5: Run, verify PASS**

Run: `flutter test test/analytics/events_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 6: Checkpoint + commit**

```bash
git add lib/core/analytics/events.dart test/support/fake_analytics.dart test/analytics/events_test.dart
git commit -m "Analytics Task 2: typed event helpers (TDD)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: main.dart wiring

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Override the provider + fire app_opened**

Read `lib/main.dart`. Add imports:
```dart
import 'core/analytics/analytics.dart';
import 'core/analytics/events.dart';
import 'core/analytics/firebase_analytics_service.dart';
```
Before `runApp`, construct the service:
```dart
  final analytics = FirebaseAnalyticsService();
```
Add the override to the `ProviderScope.overrides` list:
```dart
        analyticsProvider.overrideWithValue(analytics),
```
Fire app_opened once at startup — after constructing `analytics` and before runApp:
```dart
  AppEvents(analytics).appOpened();
```

- [ ] **Step 2: Checkpoint + commit**

`flutter analyze` (clean) + `flutter test` (all pass — existing widget tests use the Noop default, so no Firebase contact).

```bash
git add lib/main.dart
git commit -m "Analytics Task 3: wire Firebase analytics + app_opened

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Wire onboarding, session, and settings events

**Files:**
- Modify: `lib/features/onboarding/onboarding_flow.dart`
- Modify: `lib/features/home/tabs/today_page.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Test: `test/analytics/onboarding_analytics_test.dart`

- [ ] **Step 1: Onboarding finish events**

In `lib/features/onboarding/onboarding_flow.dart`, the `_next()` method finishes onboarding at:
```dart
    if (_index >= _steps.length - 1) {
      ref.read(onboardingControllerProvider).finish();
      return;
    }
```
Replace that block with one that finishes, then logs the funnel from the controller's now-computed state:
```dart
    if (_index >= _steps.length - 1) {
      final controller = ref.read(onboardingControllerProvider);
      controller.finish();
      final events = ref.read(appEventsProvider);
      final persona = controller.persona?.name ?? 'unknown';
      if (controller.persona != null) events.personaSelected(persona);
      events.goalSelected(controller.goals.map((g) => g.name).toList());
      events.planGenerated(persona, controller.goals.length);
      for (final cat in controller.triage?.categories ?? const {}) {
        events.redFlagFired(cat.name);
      }
      events.onboardingCompleted();
      return;
    }
```
Add import:
```dart
import '../../core/analytics/events.dart';
```
(`TriageCategory` has a `.name`; `controller.triage` is a `TriageResult?` with `.categories` a `Set<TriageCategory>`.)

- [ ] **Step 2: Today session events**

In `lib/features/home/tabs/today_page.dart`, inside `_startFlow`, add analytics. Add import:
```dart
import '../../../core/analytics/events.dart';
```
After the mood sheet returns moods (and the `if (moods == null ...) return;` guard), fire mood + session-started:
```dart
    final events = ref.read(appEventsProvider);
    events.moodCheckin(moods);
    events.sessionStarted(
      session.type.name,
      ref.read(progressControllerProvider).state.currentWeek,
      ref.read(progressControllerProvider).state.currentDay,
    );
```
After reflection confirms (right before/after `completeToday(...)`), fire session-completed:
```dart
    events.sessionCompleted(session.type.name, completion);
```
Place `sessionCompleted` after the `if (result == null ...) return;` guard, alongside the `completeToday` call.

- [ ] **Step 3: Settings events**

In `lib/features/settings/settings_page.dart`, add import:
```dart
import '../../core/analytics/events.dart';
```
- In `_export(...)`, after building `json` and before/after `Share.share(...)`, add: `ref.read(appEventsProvider).dataExported();`
- In `_confirmDelete(...)`, after the user confirms (`if (ok != true ...) return;`) and before `wipeAllData(...)`, add: `ref.read(appEventsProvider).accountDeleted();`
- For the biometric switch `onChanged: (v) => ...setBiometricLock(v)`, change it to also log when enabled:
```dart
              onChanged: (v) {
                ref.read(onboardingControllerProvider).setBiometricLock(v);
                if (v) ref.read(appEventsProvider).biometricLockEnabled();
              },
```

- [ ] **Step 4: Onboarding analytics widget test**

```dart
// test/analytics/onboarding_analytics_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/core/analytics/analytics.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/onboarding/onboarding_flow.dart';

import '../support/fake_analytics.dart';

void main() {
  testWidgets('completing onboarding logs completion + plan_generated',
      (tester) async {
    final fake = FakeAnalytics();
    final controller = OnboardingController()
      ..setPersona(Persona.singleInexperienced);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(fake),
          onboardingControllerProvider.overrideWith((ref) => controller),
        ],
        child: const MaterialApp(home: OnboardingFlow()),
      ),
    );
    await tester.pumpAndSettle();

    // Drive to the last step by tapping the CTA repeatedly.
    for (var i = 0; i < 20; i++) {
      final cta = find.byType(ElevatedButton).evaluate().isNotEmpty
          ? find.byType(ElevatedButton)
          : find.byType(FilledButton);
      if (cta.evaluate().isEmpty) break;
      await tester.tap(cta.first);
      await tester.pumpAndSettle();
      if (controller.complete) break;
    }

    expect(controller.complete, isTrue);
    expect(fake.last('onboarding_completed'), isNotNull);
    expect(fake.last('plan_generated'), isNotNull);
  });
}
```

> If driving the full flow by tapping is flaky (the CTA widget type differs, or pages need answers to advance), simplify: this test's intent is that the finish path logs the events. An acceptable alternative is to extract the finish-logging into a small testable method and call it directly, OR assert at the controller+events level. Keep the committed test deterministic; do not commit a flaky tap-loop. The `AppButton` renders a `FilledButton` by default (see `app_button.dart`), so `find.byType(FilledButton)` should locate the CTA.

- [ ] **Step 5: Run tests + full suite**

Run: `flutter test test/analytics/`, then `flutter test`.
Expected: pass.

- [ ] **Step 6: Checkpoint + commit**

`flutter analyze` (clean).

```bash
git add lib/features/onboarding/onboarding_flow.dart lib/features/home/tabs/today_page.dart lib/features/settings/settings_page.dart test/analytics/onboarding_analytics_test.dart
git commit -m "Analytics Task 4: wire onboarding, session, and settings events

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: CHANGELOG + final checkpoint

**Files:**
- Modify: `docs/CHANGELOG.md`

- [ ] **Step 1: CHANGELOG entry**

Append (matching style) `## Analytics — event instrumentation — 2026-06-06`: the `Analytics` seam (Noop default + Firebase impl), `AppEvents` typed helpers, events wired (app_opened; onboarding completion: persona/goal/plan/red-flag/completed; session: mood/started/completed; settings: export/delete/biometric). Deferred: paywall/subscription events, Mixpanel cohort layer, daysActive/hasPro user properties, A/B variant tagging.

- [ ] **Step 2: Final checkpoint + commit**

Run: `flutter analyze` ("No issues found!") + `flutter test` (all pass).

```bash
git add docs/CHANGELOG.md
git commit -m "Analytics Task 5: CHANGELOG entry

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-review notes

- **Spec coverage:** seam + Firebase impl (T1), typed helpers + fake (T2), main wiring + app_opened (T3), onboarding/session/settings wiring + test (T4), CHANGELOG (T5). All spec events mapped.
- **Type consistency:** `Analytics.logEvent(name,[params])`, `AppEvents` method names/params match the events_test + call sites. `controller.persona?.name`, `controller.goals` (Set<Goal>), `controller.triage?.categories` (Set<TriageCategory>), `session.type.name`, `progress.state.currentWeek/currentDay` confirmed against existing code.
- **Pure-logic isolation:** analytics is only imported by widgets (`onboarding_flow`, `today_page`, `settings_page`) + `main`, never by `triage`/`progress_logic`/controllers.
- **Test-mode safety:** `analyticsProvider` defaults to `NoopAnalytics`, so any widget test without the override logs to a no-op (no Firebase). The onboarding test overrides it with `FakeAnalytics`.
- **Deferred (per spec):** paywall/subscription events, Mixpanel, daysActive/hasPro properties, A/B tagging, onboarding_abandoned granularity.
```
