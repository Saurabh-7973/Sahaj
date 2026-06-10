# Privacy & Settings (lean slice) — Implementation Plan

> **Status: EXECUTED** — shipped to `main`; checkboxes below were not ticked during execution. See docs/CHANGELOG.md for what was built and what was deferred.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Settings screen reachable from the Me tab with the non-negotiable privacy controls (synthesis §9/§210): biometric lock, Book Mode disguise, disguise-name preference, notifications toggle, data export, delete-everything — built as testable logic, with native icon swap / OS notification scheduling deferred to the device pass.

**Architecture:** A `PreferencesController` (Riverpod + Hive `preferences` box, same single-JSON-map pattern as `OnboardingStore`) + a pure data-export assembler + an account-wipe helper + a `SettingsPage`. Reuses the existing `BiometricGate`, onboarding/progress controllers, and design-system widgets.

**Tech Stack:** Flutter, Riverpod, hive_ce, share_plus (new), flutter_test.

---

## Conventions

- Branch `privacy-settings` (off `main`). Each task ends with a **Checkpoint**: `flutter analyze` ("No issues found!") + `flutter test` (all pass), then a commit.
- **TDD for pure logic** (Tasks 1–3). Failing test first → watch fail → implement → watch pass.
- Straight ASCII quotes for Dart string delimiters; fix any curly-quote `Illegal character` analyze errors.
- Design system only; theme tokens from `lib/core/theme/`.

---

## File structure

Created:
- `lib/data/preferences_store.dart`
- `lib/features/settings/preferences_controller.dart`
- `lib/features/settings/logic/data_export.dart`
- `lib/features/settings/account.dart` — `wipeAllData(...)`.
- `lib/features/settings/book_mode_cover.dart`
- `lib/features/settings/settings_page.dart`
- Tests: `test/settings/preferences_test.dart`, `test/settings/data_export_test.dart`, `test/settings/wipe_test.dart`, `test/settings/book_mode_cover_test.dart`, `test/settings/settings_widget_test.dart`.

Modified:
- `pubspec.yaml` — add `share_plus`.
- `lib/main.dart` — open preferences box, hydrate controller, add override.
- `lib/app.dart` — wrap `BiometricGate` in `BookModeCover`.
- `lib/features/home/tabs/me_page.dart` — Privacy tile `onTap` → `SettingsPage`.
- `docs/CHANGELOG.md` — entry.

---

## Task 1: Preferences store + controller (TDD)

**Files:**
- Create: `lib/data/preferences_store.dart`
- Create: `lib/features/settings/preferences_controller.dart`
- Test: `test/settings/preferences_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/settings/preferences_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';

void main() {
  test('defaults are private-safe (everything off / none)', () {
    final c = PreferencesController();
    expect(c.bookMode, isFalse);
    expect(c.disguiseName, DisguiseName.none);
    expect(c.notificationsEnabled, isFalse);
  });

  test('setters update and toJson/loadFrom round-trips', () {
    final a = PreferencesController()
      ..setBookMode(true)
      ..setDisguiseName(DisguiseName.calendar)
      ..setNotificationsEnabled(true);

    final b = PreferencesController()..loadFrom(a.toJson());
    expect(b.bookMode, isTrue);
    expect(b.disguiseName, DisguiseName.calendar);
    expect(b.notificationsEnabled, isTrue);
  });

  test('reset returns to defaults', () {
    final c = PreferencesController()
      ..setBookMode(true)
      ..setDisguiseName(DisguiseName.notes);
    c.reset();
    expect(c.bookMode, isFalse);
    expect(c.disguiseName, DisguiseName.none);
  });

  test('loadFrom tolerates an unknown disguise name', () {
    final c = PreferencesController()..loadFrom({'disguiseName': 'bogus'});
    expect(c.disguiseName, DisguiseName.none);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/settings/preferences_test.dart`
Expected: FAIL — `PreferencesController` not defined.

- [ ] **Step 3: Implement the store**

```dart
// lib/data/preferences_store.dart
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Persists user preferences as a single JSON map (mirrors OnboardingStore).
class PreferencesStore {
  PreferencesStore(this._box);

  static const _boxName = 'preferences';
  static const _key = 'state';

  final Box _box;

  static Future<PreferencesStore> open() async {
    final box = await Hive.openBox(_boxName);
    return PreferencesStore(box);
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

- [ ] **Step 4: Implement the controller**

```dart
// lib/features/settings/preferences_controller.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/preferences_store.dart';

/// In-app disguise label (drives the native icon/name swap, deferred).
enum DisguiseName { none, calendar, notes, wellness }

DisguiseName _disguiseByName(String? name) {
  for (final d in DisguiseName.values) {
    if (d.name == name) return d;
  }
  return DisguiseName.none;
}

/// Holds + persists privacy/disguise/notification preferences.
class PreferencesController extends ChangeNotifier {
  PreferencesController([this._store]);

  final PreferencesStore? _store;

  bool bookMode = false;
  DisguiseName disguiseName = DisguiseName.none;
  bool notificationsEnabled = false;

  void setBookMode(bool v) {
    bookMode = v;
    _persist();
  }

  void setDisguiseName(DisguiseName v) {
    disguiseName = v;
    _persist();
  }

  void setNotificationsEnabled(bool v) {
    notificationsEnabled = v;
    _persist();
  }

  void reset() {
    bookMode = false;
    disguiseName = DisguiseName.none;
    notificationsEnabled = false;
    _store?.clear();
    notifyListeners();
  }

  void _persist() {
    _store?.save(toJson());
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'bookMode': bookMode,
        'disguiseName': disguiseName.name,
        'notificationsEnabled': notificationsEnabled,
      };

  void loadFrom(Map<String, dynamic> json) {
    bookMode = (json['bookMode'] as bool?) ?? false;
    disguiseName = _disguiseByName(json['disguiseName'] as String?);
    notificationsEnabled = (json['notificationsEnabled'] as bool?) ?? false;
    notifyListeners();
  }
}

/// Overridden in main() with the persisted controller.
final preferencesControllerProvider =
    ChangeNotifierProvider<PreferencesController>(
  (ref) => PreferencesController(),
);
```

- [ ] **Step 5: Run, verify PASS**

Run: `flutter test test/settings/preferences_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 6: Checkpoint + commit**

```bash
git add lib/data/preferences_store.dart lib/features/settings/preferences_controller.dart test/settings/preferences_test.dart
git commit -m "Privacy Task 1: preferences store + controller (TDD)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Data export assembler (pure, TDD)

**Files:**
- Create: `lib/features/settings/logic/data_export.dart`
- Test: `test/settings/data_export_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/settings/data_export_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/settings/logic/data_export.dart';

void main() {
  test('assembleExportJson nests all sections and is valid JSON', () {
    final out = assembleExportJson(
      onboarding: {'persona': 'singleInexperienced', 'complete': true},
      progress: {'currentWeek': 2, 'currentDay': 3},
      logs: [
        {'id': 'a', 'sessionTag': 'anatomy'},
      ],
      preferences: {'bookMode': true},
      exportedAt: DateTime.utc(2026, 6, 6, 12),
    );

    final decoded = jsonDecode(out) as Map<String, dynamic>;
    expect(decoded['exportedAt'], '2026-06-06T12:00:00.000Z');
    expect((decoded['onboarding'] as Map)['persona'], 'singleInexperienced');
    expect((decoded['progress'] as Map)['currentWeek'], 2);
    expect((decoded['sessionLogs'] as List).length, 1);
    expect((decoded['preferences'] as Map)['bookMode'], true);
  });

  test('null onboarding becomes an empty section', () {
    final out = assembleExportJson(
      onboarding: null,
      progress: const {},
      logs: const [],
      preferences: const {},
      exportedAt: DateTime.utc(2026, 1, 1),
    );
    final decoded = jsonDecode(out) as Map<String, dynamic>;
    expect(decoded['onboarding'], isNull);
    expect(decoded['sessionLogs'], isEmpty);
  });

  test('output is pretty-printed (indented)', () {
    final out = assembleExportJson(
      onboarding: const {},
      progress: const {},
      logs: const [],
      preferences: const {},
      exportedAt: DateTime.utc(2026, 1, 1),
    );
    expect(out.contains('\n  '), isTrue);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/settings/data_export_test.dart`
Expected: FAIL — `assembleExportJson` not defined.

- [ ] **Step 3: Implement**

```dart
// lib/features/settings/logic/data_export.dart
import 'dart:convert';

/// Assembles all of a user's local data into one pretty-printed JSON string
/// for a user-initiated export. Pure — delivery (share sheet) is the caller's job.
String assembleExportJson({
  required Map<String, dynamic>? onboarding,
  required Map<String, dynamic> progress,
  required List<Map<String, dynamic>> logs,
  required Map<String, dynamic> preferences,
  required DateTime exportedAt,
}) {
  final payload = <String, dynamic>{
    'exportedAt': exportedAt.toIso8601String(),
    'onboarding': onboarding,
    'progress': progress,
    'sessionLogs': logs,
    'preferences': preferences,
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}
```

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/settings/data_export_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Checkpoint + commit**

```bash
git add lib/features/settings/logic/data_export.dart test/settings/data_export_test.dart
git commit -m "Privacy Task 2: data-export assembler (TDD)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Account wipe helper (TDD, real Hive)

**Files:**
- Create: `lib/features/settings/account.dart`
- Test: `test/settings/wipe_test.dart`

This reuses the existing controllers' `reset()` methods (each clears its own Hive box). The helper exists so the Settings screen and tests call one thing.

- [ ] **Step 1: Write the failing test**

```dart
// test/settings/wipe_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sahaj/data/onboarding_store.dart';
import 'package:sahaj/data/preferences_store.dart';
import 'package:sahaj/data/progress_store.dart';
import 'package:sahaj/data/session_log_store.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/settings/account.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';
import 'package:sahaj/features/sessions/progress_controller.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sahaj_wipe_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('wipeAllData clears onboarding, progress, logs, and preferences', () async {
    final onboardingStore = await OnboardingStore.open();
    final progressStore = await ProgressStore.open();
    final logStore = await SessionLogStore.open();
    final prefsStore = await PreferencesStore.open();

    final onboarding = OnboardingController(onboardingStore)
      ..setPersona(Persona.singleInexperienced)
      ..finish();
    final progress = ProgressController(progressStore, logStore)
      ..completeToday(SessionLog(
        id: 'x',
        sessionTag: 'anatomy',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        completionPct: 1.0,
        moodBefore: const [],
      ));
    final prefs = PreferencesController(prefsStore)..setBookMode(true);
    await Future<void>.delayed(Duration.zero);

    // sanity: data present
    expect(onboardingStore.load(), isNotNull);
    expect(logStore.all(), isNotEmpty);

    wipeAllData(onboarding: onboarding, progress: progress, preferences: prefs);
    await Future<void>.delayed(Duration.zero);

    expect(onboardingStore.load(), isNull);
    expect(progressStore.load(), isNull);
    expect(logStore.all(), isEmpty);
    expect(prefsStore.load(), isNull);
    expect(onboarding.complete, isFalse);
    expect(progress.state.currentDay, 1);
    expect(prefs.bookMode, isFalse);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/settings/wipe_test.dart`
Expected: FAIL — `wipeAllData` not defined.

- [ ] **Step 3: Implement**

```dart
// lib/features/settings/account.dart
import '../onboarding/onboarding_controller.dart';
import '../sessions/progress_controller.dart';
import 'preferences_controller.dart';

/// Wipes every local data store: onboarding, progress + session logs, and
/// preferences. Each controller's reset() clears its own Hive box. After this,
/// the app is in a first-launch state and the caller should route to onboarding.
void wipeAllData({
  required OnboardingController onboarding,
  required ProgressController progress,
  required PreferencesController preferences,
}) {
  onboarding.reset();
  progress.reset();
  preferences.reset();
}
```

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/settings/wipe_test.dart`
Expected: PASS.

- [ ] **Step 5: Checkpoint + commit**

```bash
git add lib/features/settings/account.dart test/settings/wipe_test.dart
git commit -m "Privacy Task 3: wipe-all account helper (TDD)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: main.dart wiring

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Open the preferences box + hydrate + override**

In `lib/main.dart`, add imports:

```dart
import 'data/preferences_store.dart';
import 'features/settings/preferences_controller.dart';
```

After the existing sessions wiring block (and before `final catalog = ...` or before `runApp`, order does not matter), add:

```dart
  final prefsStore = await PreferencesStore.open();
  final preferences = PreferencesController(prefsStore);
  final savedPrefs = prefsStore.load();
  if (savedPrefs != null) preferences.loadFrom(savedPrefs);
```

Add the override to the `ProviderScope.overrides` list:

```dart
        preferencesControllerProvider.overrideWith((ref) => preferences),
```

- [ ] **Step 2: Checkpoint + commit**

Run: `flutter analyze` (clean) + `flutter test` (all pass — existing widget tests pump `SahajApp` without this override; `preferencesControllerProvider` falls back to a default `PreferencesController()`, and `BookModeCover` defaults `bookMode=false` so it never covers — see Task 5).

```bash
git add lib/main.dart
git commit -m "Privacy Task 4: wire preferences box + override

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Book Mode cover + app.dart wrap (widget test)

**Files:**
- Create: `lib/features/settings/book_mode_cover.dart`
- Modify: `lib/app.dart`
- Test: `test/settings/book_mode_cover_test.dart`

- [ ] **Step 1: Create the cover**

```dart
// lib/features/settings/book_mode_cover.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import 'preferences_controller.dart';

/// When Book Mode is on, shows a plain reading disguise over the app until a
/// discreet tap dismisses it for this launch. The native app icon/name swap is
/// deferred; this is the in-app half of the disguise (synthesis section 9).
class BookModeCover extends ConsumerStatefulWidget {
  const BookModeCover({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<BookModeCover> createState() => _BookModeCoverState();
}

class _BookModeCoverState extends ConsumerState<BookModeCover> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final bookMode = ref.watch(preferencesControllerProvider).bookMode;
    if (!bookMode || _dismissed) return widget.child;

    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onDoubleTap: () => setState(() => _dismissed = true),
        child: Container(
          color: theme.colorScheme.surface,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text('My Notes', style: theme.textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.lg),
                  for (final title in const [
                    'Reading list',
                    'Weekly reflections',
                    'Ideas',
                    'To revisit',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.article_outlined),
                          const SizedBox(width: AppSpacing.lg),
                          Text(title, style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text('Double-tap anywhere to open',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Wrap it in app.dart**

In `lib/app.dart`, change the builder line from:

```dart
      builder: (context, child) => BiometricGate(child: child ?? const SizedBox.shrink()),
```

to:

```dart
      builder: (context, child) => BookModeCover(
        child: BiometricGate(child: child ?? const SizedBox.shrink()),
      ),
```

Add import:

```dart
import 'features/settings/book_mode_cover.dart';
```

- [ ] **Step 3: Write the widget test**

```dart
// test/settings/book_mode_cover_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/settings/book_mode_cover.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';

void main() {
  testWidgets('hidden when book mode off', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesControllerProvider
              .overrideWith((ref) => PreferencesController()),
        ],
        child: const MaterialApp(
          home: BookModeCover(child: Text('REAL APP')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('REAL APP'), findsOneWidget);
    expect(find.text('My Notes'), findsNothing);
  });

  testWidgets('covers when book mode on, double-tap reveals', (tester) async {
    final prefs = PreferencesController()..setBookMode(true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesControllerProvider.overrideWith((ref) => prefs),
        ],
        child: const MaterialApp(
          home: BookModeCover(child: Text('REAL APP')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My Notes'), findsOneWidget);
    expect(find.text('REAL APP'), findsNothing);

    await tester.tap(find.text('My Notes'));
    await tester.tap(find.text('My Notes')); // double-tap
    await tester.pumpAndSettle();
    expect(find.text('REAL APP'), findsOneWidget);
  });
}
```

> Note: if the two single taps don't register as a double-tap in the test, drive it with a `TestGesture` or replace `onDoubleTap` with `onTap` for testability. Prefer keeping `onDoubleTap` (a single tap shouldn't reveal a disguise); if the test is flaky, use `tester.tap(find.text('My Notes'))` twice with no settle between, or a gesture. Make it pass deterministically.

- [ ] **Step 4: Run the test + full suite**

Run: `flutter test test/settings/book_mode_cover_test.dart` then `flutter test`.
Expected: pass. Existing `test/widget_test.dart` still passes (book mode defaults off).

- [ ] **Step 5: Checkpoint + commit**

```bash
git add lib/features/settings/book_mode_cover.dart lib/app.dart test/settings/book_mode_cover_test.dart
git commit -m "Privacy Task 5: Book Mode disguise cover

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: Settings page + Me tile + share_plus

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/settings/settings_page.dart`
- Modify: `lib/features/home/tabs/me_page.dart`
- Test: `test/settings/settings_widget_test.dart`

- [ ] **Step 1: Add share_plus**

In `pubspec.yaml` under `dependencies:`, add `share_plus: ^10.1.4` (use the latest 10.x the resolver picks). Run `flutter pub get`.

- [ ] **Step 2: Create the Settings page**

```dart
// lib/features/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/session_log_store.dart' show SessionLogStore;
import '../../shared/widgets/widgets.dart';
import '../onboarding/onboarding_controller.dart';
import '../sessions/progress_controller.dart';
import 'account.dart';
import 'logic/data_export.dart';
import 'preferences_controller.dart';

/// Privacy + settings (synthesis section 9 / 210). Reached from the Me tab.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _disguiseLabels = {
    DisguiseName.none: 'No disguise',
    DisguiseName.calendar: 'Calendar',
    DisguiseName.notes: 'Notes',
    DisguiseName.wellness: 'Wellness',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onboarding = ref.watch(onboardingControllerProvider);
    final prefs = ref.watch(preferencesControllerProvider);

    return AppScaffold(
      title: 'Settings',
      leading: const BackButton(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lock', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Biometric lock'),
              subtitle: const Text('Require fingerprint/face to open Sahaj'),
              value: onboarding.biometricLock,
              onChanged: (v) => ref
                  .read(onboardingControllerProvider)
                  .setBiometricLock(v),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Disguise', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Book Mode'),
                  subtitle: const Text(
                      'Open into a plain reading screen; double-tap to reveal'),
                  value: prefs.bookMode,
                  onChanged: (v) => ref
                      .read(preferencesControllerProvider)
                      .setBookMode(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('App name on the home screen',
              style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final d in DisguiseName.values)
            SelectableOption(
              label: _disguiseLabels[d]!,
              selected: prefs.disguiseName == d,
              onTap: () => ref
                  .read(preferencesControllerProvider)
                  .setDisguiseName(d),
            ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text('Renaming the icon arrives in a later update.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Reminders', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily reminder'),
              subtitle: const Text('A gentle nudge. Scheduling arrives soon.'),
              value: prefs.notificationsEnabled,
              onChanged: (v) => ref
                  .read(preferencesControllerProvider)
                  .setNotificationsEnabled(v),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Your data', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Export my data',
            variant: AppButtonVariant.outlined,
            onPressed: () => _export(context, ref),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Delete everything',
            variant: AppButtonVariant.text,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final onboarding = ref.read(onboardingControllerProvider);
    final progress = ref.read(progressControllerProvider);
    final prefs = ref.read(preferencesControllerProvider);
    final json = assembleExportJson(
      onboarding: onboarding.toJson(),
      progress: progress.state.toJson(),
      logs: progress.logs().map((l) => l.toJson()).toList(),
      preferences: prefs.toJson(),
      exportedAt: DateTime.now(),
    );
    // share_plus: use the installed version's API. If Share.share is
    // unavailable, fall back to Clipboard.setData + a snackbar.
    await Share.share(json, subject: 'My Sahaj data');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
            'This permanently removes your plan, progress, logs, and settings '
            'from this device. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    wipeAllData(
      onboarding: ref.read(onboardingControllerProvider),
      progress: ref.read(progressControllerProvider),
      preferences: ref.read(preferencesControllerProvider),
    );
    if (context.mounted) context.go(Routes.onboarding);
  }
}
```

> `SessionLogStore` import is only needed if analyze complains; remove it if unused (logs come via `progress.logs()`). Let analyze be the arbiter. If the installed `share_plus` exposes a different API (e.g. `SharePlus.instance.share(ShareParams(text: json))`), use that; if it causes a build/analyze problem, replace the `Share.share(...)` line with `await Clipboard.setData(ClipboardData(text: json));` plus a snackbar (and `import 'package:flutter/services.dart';`). The export is device-only either way.

- [ ] **Step 3: Wire the Me tab tile**

In `lib/features/home/tabs/me_page.dart`, give the existing "Privacy & discreet mode" `AppListTile` an `onTap` that pushes the Settings page, and a trailing chevron to match the showcase tile. Add import:

```dart
import '../../settings/settings_page.dart';
```

Change the Privacy tile to:

```dart
                AppListTile(
                  leadingIcon: Icons.lock_outline,
                  title: 'Privacy & discreet mode',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsPage(),
                    ),
                  ),
                ),
```

- [ ] **Step 4: Write the Settings widget test**

```dart
// test/settings/settings_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaj/features/onboarding/onboarding_controller.dart';
import 'package:sahaj/features/settings/preferences_controller.dart';
import 'package:sahaj/features/settings/settings_page.dart';

void main() {
  testWidgets('renders sections and toggling Book Mode writes the pref',
      (tester) async {
    final prefs = PreferencesController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider
              .overrideWith((ref) => OnboardingController()),
          preferencesControllerProvider.overrideWith((ref) => prefs),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Biometric lock'), findsOneWidget);
    expect(find.text('Book Mode'), findsOneWidget);
    expect(find.text('Export my data'), findsOneWidget);
    expect(find.text('Delete everything'), findsOneWidget);

    expect(prefs.bookMode, isFalse);
    await tester.tap(find.text('Book Mode'));
    await tester.pumpAndSettle();
    expect(prefs.bookMode, isTrue);
  });
}
```

- [ ] **Step 5: Run the test + full suite**

Run: `flutter test test/settings/settings_widget_test.dart` then `flutter test`.
Expected: pass. (Tapping a `SwitchListTile` by its title toggles it; if the tap misses, target `find.byType(SwitchListTile).first` for Book Mode.)

- [ ] **Step 6: Checkpoint + commit**

Run: `flutter analyze` (clean).

```bash
git add pubspec.yaml pubspec.lock lib/features/settings/settings_page.dart lib/features/home/tabs/me_page.dart test/settings/settings_widget_test.dart
git commit -m "Privacy Task 6: settings page + Me entry + share_plus

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 7: CHANGELOG + final checkpoint

**Files:**
- Modify: `docs/CHANGELOG.md`

- [ ] **Step 1: CHANGELOG entry**

Read `docs/CHANGELOG.md` and append (matching its style) a `## Privacy & Settings — discreet mode + data controls — 2026-06-06` section summarizing: preferences store/controller (Book Mode, disguise name, notifications toggle), Book Mode in-app disguise cover, data-export assembler + share, delete-everything wipe (two-tap), Settings screen from the Me tab. Note deferrals: native app-icon/name swap (activity-alias), OS notification scheduling (`flutter_local_notifications`), language switch (Hindi Phase 2), anonymous auth / encrypted cloud sync.

- [ ] **Step 2: Final checkpoint + commit**

Run: `flutter analyze` (expect "No issues found!") and `flutter test` (expect all pass).

```bash
git add docs/CHANGELOG.md
git commit -m "Privacy Task 7: CHANGELOG entry

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

- [ ] **Step 3: Device pass (manual, deferred with the overall device pass)**

On device: Me → Privacy & discreet mode → Settings. Toggle Book Mode on, leave + reopen the app → plain "My Notes" screen → double-tap reveals the app. Biometric toggle prompts on next launch. Export my data → share sheet with JSON. Delete everything → two-tap → onboarding replays, all data gone.

---

## Self-review notes

- **Spec coverage:** preferences (T1), data export (T2), wipe (T3), startup wiring (T4), Book Mode cover (T5), Settings page + Me entry + share (T6), CHANGELOG (T7). Biometric reuses the onboarding controller; native icon swap + notification scheduling deferred per spec.
- **Type consistency:** `PreferencesController` (`bookMode`/`disguiseName`/`notificationsEnabled`, `setX`, `toJson`/`loadFrom`/`reset`), `DisguiseName`, `assembleExportJson(...)`, `wipeAllData(...)` signatures match their call sites in the Settings page, cover, main, and tests. `onboardingController.biometricLock`/`setBiometricLock` confirmed to exist (Phase 3 Task 10). `progress.logs()` from Phase 5.
- **Test-mode guards:** existing widget tests pump `SahajApp` without the preferences override → falls back to a default `PreferencesController()` (bookMode false → cover never shows). No existing test should break; if `widget_test.dart` interacts with the Me tab it doesn't reach the new tile.
- **share_plus caveat (T6):** delivery is device-only and version-API-dependent; the plan gives a Clipboard fallback. The tested core is the pure `assembleExportJson`.
- **Deferred (per spec):** native icon/name disguise, OS notification scheduling, language switch, cloud sync.
```
