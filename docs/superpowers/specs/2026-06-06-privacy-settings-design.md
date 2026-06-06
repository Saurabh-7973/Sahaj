# Privacy & Settings (lean slice) — design

**Date:** 2026-06-06
**Status:** Approved-by-delegation (user asked me to choose the next-best build and approved this scope) — pending spec review

## Goal

Build the privacy/trust layer synthesis marks *non-negotiable* (§9 ultra-discreet mode; §210 settings list) as a real Settings screen reachable from the Me tab — implemented as unit/widget-testable logic, with the genuinely device-only pieces (native app-icon swap, OS notification scheduling, share sheet) explicitly deferred to the eventual device pass.

## Why this is the right next build

- Synthesis §9: "Ultra-discreet mode is non-negotiable in India… build this in v1, not v2." A user in a joint-family context won't keep a sexual-wellness app installed without disguise + lock. It's the wedge.
- Synthesis §210 lists Settings = discreet mode, biometric lock, notifications, language, data export, delete account.
- Needs no content authoring and no API keys (unlike a subscription paywall), and most of it is testable now.

## Scope decisions (locked)

| Decision | Choice |
|----------|--------|
| Book Mode | In-app reading-disguise **cover** now; native app-icon/name swap (activity-alias) **deferred to device** |
| Notifications | Persisted **toggle only** now; OS scheduling (`flutter_local_notifications`) **deferred** |
| Data export | Pure JSON **assembler** (tested) + delivery via `share_plus` (new dep; share call device-only) |
| Delete everything | Wipe-all coordinator + two-tap confirm; logic tested |
| Biometric lock | Stays in `OnboardingController` (read by `BiometricGate`); Settings reads/writes it there |
| Language switch | Deferred (Hindi is Phase 2) |

## Architecture

A `PreferencesController` (Riverpod `ChangeNotifierProvider` + Hive `preferences` box, same single-JSON-map pattern as `OnboardingStore`/`ProgressStore`), a pure data-export/wipe layer, and a `SettingsPage`. Existing wiring (`BiometricGate`, onboarding/progress controllers) is reused, not churned.

### 1. Preferences

**Model + store** — `lib/data/preferences_store.dart` (Hive box `preferences`, `load`/`save`/`clear`, mirrors `OnboardingStore`).

**Controller** — `lib/features/settings/preferences_controller.dart`:

```text
enum DisguiseName { none, calendar, notes, wellness }   // label shown on disguise

class PreferencesController extends ChangeNotifier {
  PreferencesController([PreferencesStore? store]);
  bool bookMode = false;
  DisguiseName disguiseName = DisguiseName.none;
  bool notificationsEnabled = false;

  void setBookMode(bool v);
  void setDisguiseName(DisguiseName v);
  void setNotificationsEnabled(bool v);
  void loadFrom(Map<String,dynamic> json);
  Map<String,dynamic> toJson();
  void reset();           // clears prefs + store
}
final preferencesControllerProvider = ChangeNotifierProvider(...);
```

Hydrated in `main.dart` via override (open box, `loadFrom` saved). Exports nothing special.

### 2. Data export (pure)

`lib/features/settings/logic/data_export.dart`:

```text
String assembleExportJson({
  required Map<String,dynamic>? onboarding,   // OnboardingController.toJson()
  required Map<String,dynamic> progress,      // ProgressState.toJson()
  required List<Map<String,dynamic>> logs,    // SessionLogStore.all()
  required Map<String,dynamic> preferences,   // PreferencesController.toJson()
  required DateTime exportedAt,
});
```

Builds a single map `{ exportedAt, onboarding, progress, sessionLogs, preferences }` and returns `JsonEncoder.withIndent('  ')` output. Pure + unit-tested. The Settings screen passes this string to `Share.share(...)` (`share_plus`) — the share call itself is device-only (untested, like the player timer).

### 3. Account wipe

A coordinator method invoked from Settings (lives in the Settings page or a small helper): calls `onboardingController.reset()` (clears onboarding box), `progressController.reset()` (clears progress + session_logs boxes), `preferencesController.reset()` (clears preferences box), then `context.go(Routes.onboarding)`. Two-tap confirm (`AlertDialog`). A unit test asserts that after wipe, every store's `load()/all()` is empty.

### 4. Book Mode cover

`lib/features/settings/book_mode_cover.dart` — a `ConsumerStatefulWidget` wrapping the app (composed in `app.dart`'s `MaterialApp.router` `builder` alongside `BiometricGate`): when `preferences.bookMode` is true and not yet dismissed this launch, it renders a plain reading/Notes disguise surface (calm title, fake "chapters" list) over `child`; a discreet tap dismisses it to reveal the real app. Widget-testable (flag on → cover shown; tap → child shown). The **native icon/name disguise is deferred** — this cover is the in-app half of §9's "book-mode UI disguise."

Composition: `builder: (context, child) => BookModeCover(child: BiometricGate(child: child ?? SizedBox()))` — disguise outermost, then biometric, then app.

### 5. Settings page

`lib/features/settings/settings_page.dart` (`ConsumerWidget`), reached from the Me tab's existing "Privacy & discreet mode" tile (add `onTap` → `Navigator.push`). Sections (design-system widgets):
- **Lock** — biometric switch (reads/writes `onboardingController.biometricLock`).
- **Disguise** — Book Mode switch (`preferences.bookMode`); disguise-name picker (`SelectableOption`s for none/Calendar/Notes/Wellness) — picker stores the preference now; it drives the native swap later.
- **Notifications** — daily-reminder switch (`preferences.notificationsEnabled`; toggle only, with a one-line "scheduling arrives soon" caption).
- **Your data** — "Export my data" (assemble JSON → `Share.share`); "Delete everything" (two-tap → wipe-all).

## Testing

Pure/widget (deterministic):
- `preferences` round-trip (toJson/loadFrom) + store save/load (real temp-Hive).
- `assembleExportJson` — shape + nesting + valid JSON + `exportedAt` present.
- wipe-all — after wipe, onboarding/progress/log/preferences stores all empty (real temp-Hive).
- `SettingsPage` widget — renders sections; toggling biometric/bookMode/notifications writes to the controllers.
- `BookModeCover` widget — flag on shows cover; tap reveals child.

Deferred (device): `Share.share`, native icon/name swap, notification scheduling.

## File structure

Created:
- `lib/data/preferences_store.dart`
- `lib/features/settings/preferences_controller.dart`
- `lib/features/settings/logic/data_export.dart`
- `lib/features/settings/book_mode_cover.dart`
- `lib/features/settings/settings_page.dart`
- Tests: `test/settings/preferences_test.dart`, `test/settings/data_export_test.dart`, `test/settings/wipe_test.dart`, `test/settings/settings_widget_test.dart`, `test/settings/book_mode_cover_test.dart`.

Modified:
- `pubspec.yaml` — add `share_plus`.
- `lib/main.dart` — open preferences box, hydrate controller, add provider override.
- `lib/app.dart` — wrap `BiometricGate` in `BookModeCover` inside the `MaterialApp.router` builder.
- `lib/features/home/tabs/me_page.dart` — Privacy tile `onTap` → `SettingsPage`.
- `docs/CHANGELOG.md` — entry.

## Open defaults (locked unless changed)

- Disguise names: none / Calendar / Notes / Wellness.
- Book Mode cover dismiss = single discreet tap (biometric still gates separately via `BiometricGate`).
- Notifications toggle persists intent now; no OS scheduling this slice.
- Export delivered via share sheet; no encryption of the export file (it is the user's own data, user-initiated).
