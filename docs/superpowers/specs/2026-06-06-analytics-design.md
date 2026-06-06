# Analytics instrumentation — design

**Date:** 2026-06-06
**Status:** Approved-by-delegation — pending spec review

## Goal

Instrument the synthesis/roadmap event funnel (`docs/solo_dev_roadmap.md` §analytics) so the product has real usage data from day one. A thin, testable analytics seam over Firebase Analytics; the pure-Dart logic layer never imports Firebase.

## Architecture

### The seam
- `lib/core/analytics/analytics.dart` — abstract `Analytics`:
  ```text
  abstract class Analytics {
    void logEvent(String name, [Map<String, Object>? params]);
    void setUserProperty(String name, String? value);
  }
  ```
- `NoopAnalytics` (same file or alongside) — does nothing. The default, so tests and any un-overridden read never touch Firebase.
- `lib/core/analytics/firebase_analytics_service.dart` — `FirebaseAnalyticsService implements Analytics`, forwarding to `FirebaseAnalytics.instance` (`logEvent(name:, parameters:)`, `setUserProperty(name:, value:)`). Device/Firebase only — not unit-tested.
- `analyticsProvider` (`Provider<Analytics>`) defaulting to `const NoopAnalytics()`; overridden in `main.dart` with `FirebaseAnalyticsService`.

### Typed event helpers (pure, tested)
`lib/core/analytics/events.dart` — `AppEvents` wraps an `Analytics` and exposes one method per event, each calling `logEvent` with the agreed name + params. This keeps call sites clean and event names/params consistent in one place.

```text
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

final appEventsProvider = Provider<AppEvents>(
  (ref) => AppEvents(ref.watch(analyticsProvider)),
);
```

Firebase Analytics requires event/param names to be snake_case, ≤40 chars, with primitive param values (String/num/bool) — the helpers above comply (lists are joined to comma strings).

## Wiring (UI layer only — pure logic stays Firebase-free)

Events fire from widgets where `ref` is available, never from `triage`/`progress_logic`/controllers:

- **`app_opened`** — `SahajApp` (or a one-shot in `main`) on launch.
- **Onboarding finish** — the flow code that calls `controller.finish()` (`onboarding_flow.dart` `_advance` final step) fires, in order: `personaSelected`, `goalSelected`, `planGenerated(persona, goalCount)`, `onboardingCompleted`. Read values off the controller after `finish()`.
- **Red flags** — after `finish()` computes `triage`, fire `redFlagFired` once per fired category (`triage.categories`).
- **Today `_startFlow`** — `moodCheckin(moods)` after the sheet returns; `sessionStarted(type, week, day)` before pushing the player; `sessionCompleted(type, pct)` after reflection confirms.
- **Settings actions** — `dataExported()` in `_export`; `accountDeleted()` in the delete handler before wipe; `biometricLockEnabled()` when the biometric switch turns on (true only).

## Testing

- `AppEvents` (pure, TDD) — each method logs the correct event name + params against a `FakeAnalytics` (a test double recording `(name, params)` calls). Covers list-joining and key params.
- One widget test — drive onboarding to completion with `analyticsProvider` overridden by a `FakeAnalytics`; assert `onboarding_completed` and `plan_generated` were recorded. (Mirrors the existing onboarding flow tests.)
- `FirebaseAnalyticsService` is device-only — untested, like the player timer / share sheet.
- `FakeAnalytics` lives in `test/support/fake_analytics.dart`.

## File structure

Created:
- `lib/core/analytics/analytics.dart` (`Analytics`, `NoopAnalytics`, `analyticsProvider`)
- `lib/core/analytics/firebase_analytics_service.dart`
- `lib/core/analytics/events.dart` (`AppEvents`, `appEventsProvider`)
- `test/support/fake_analytics.dart`
- Tests: `test/analytics/events_test.dart`, plus an onboarding-completion analytics assertion (new or folded into the flow test).

Modified:
- `lib/main.dart` — override `analyticsProvider` with `FirebaseAnalyticsService`; fire `app_opened`.
- `lib/features/onboarding/onboarding_flow.dart` — fire onboarding/persona/goal/plan/red-flag events on finish.
- `lib/features/home/tabs/today_page.dart` — fire mood/session events in `_startFlow`.
- `lib/features/settings/settings_page.dart` — fire export/delete/biometric events.
- `docs/CHANGELOG.md` — entry.

## Open defaults (locked unless changed)

- Default provider is `NoopAnalytics`; Firebase only wired in `main`.
- List params (goals, moods) are comma-joined strings (Firebase params must be primitive).
- Pure logic never imports analytics; all events fire from the UI layer.
- Deferred: paywall/subscription events (no paywall), Mixpanel cohort layer, `daysActive`/`hasPro` user properties (need auth/subscription), A/B variant tagging, `onboarding_abandoned`/`onboarding_completed_screen` granularity.
