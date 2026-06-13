# Changelog

All notable changes to Sahaj. Format: phase, date, summary, deferred items.

---

## Phase 0 — Project bootstrap — 2026-04-29

- Flutter 3.35 project scaffolded. Package: `com.saurabh7973.sahaj`. Android-only platform target.
- Repo structure under `lib/`: `core/{theme,constants,utils,errors}`, `data/{models,repositories,datasources}`, `features/`, `shared/widgets/`, `l10n/`.
- Content + tooling dirs: `content/{articles,audio_scripts}`, `tool/`, `assets/{audio,images}`.
- Dependencies added (pubspec.yaml): Riverpod, go_router, Drift + sqlite3, Hive CE, secure_storage, full Firebase suite, Sentry, Mixpanel, RevenueCat (purchases_flutter), just_audio + audio_service, Freezed + json_serializable, google_fonts, flutter_markdown, local_auth, flutter_localizations.
- Theme tokens locked (`lib/core/theme/`):
  - `app_colors.dart` — warm sand / deep moss / muted ochre. No pure red. Light + dark schemes.
  - `app_typography.dart` — Fraunces (display) + Manrope (body) via google_fonts.
  - `app_spacing.dart` — 4 / 8 / 12 / 16 / 24 / 32 / 48 scale; radii 8 / 16 / 24.
  - `app_motion.dart` — durations (instant 100 / quick 200 / settle 400 / calm 700) + curves (no overshoot).
  - `app_theme.dart` — Material 3 theme assembled from the above.
- `main.dart` runs `ProviderScope` → `SahajApp`. Dark mode default per principle 5.
- Placeholder home renders brand + tagline.
- Widget test updated to assert brand renders.

### Deferred (require user-side credentials)

- `firebase_options.dart` via `flutterfire configure` — Firebase project not yet created.
- Sentry DSN init — account pending.
- Mixpanel project token — account pending.
- RevenueCat API key + entitlement / products — Phase 6.

Each is stubbed with a TODO in `main.dart`.

### Next

Phase 1 — design system. Build `AppButton`, `AppCard`, `AppScaffold`, `AppMoodSelector`, `AppProgressRing`, `AppTextField`, `AppListTile`, plus a `showcase_screen` to visually review.

---

## Phase 1 — Design system widgets — 2026-06-05

Shared widgets under `lib/shared/widgets/` (barrel: `widgets.dart`):

- `app_button.dart` — `AppButton` with filled / outlined / text variants, optional leading icon, loading spinner, expand-to-width default.
- `app_card.dart` — `AppCard` surface container, calm radius (16), optional `onTap` with ink response.
- `app_scaffold.dart` — `AppScaffold` screen shell: SafeArea + consistent horizontal padding, optional AppBar (title/leading/actions), scrollable flag, bottom action slot.
- `app_text_field.dart` — `AppTextField` labeled input, prefix icon, error text, obscure / multiline support.
- `app_list_tile.dart` — `AppListTile` row: leading icon, title/subtitle, trailing, tap.
- `app_mood_selector.dart` — `AppMoodSelector` + `AppMood` model. 5-point emoji scale, animated scale/accent on selection. `kDefaultMoods` provided.
- `app_progress_ring.dart` — `AppProgressRing` custom-painted ring, animates to value (calm 700ms), center content slot.

- `features/showcase_screen.dart` — `ShowcaseScreen` exercising every widget (interactive mood, loading button, progress slider). Wired as `home` in `app.dart` for on-device review (replaces `PlaceholderHome`).
- `flutter analyze` clean.

### Next

Phase 2 — onboarding flow + go_router setup. Then data layer (Drift schema).

---

## Phase 2 — Onboarding shell + routing — 2026-06-06

Navigation shell only — no persona-routing, red-flag triage, or baseline scoring yet (roadmap Weeks 3-4).

**Routing** (`lib/core/router/`):
- `routes.dart` — flat path constants (`/onboarding`, `/today`, `/library`, `/me`, dev `/showcase`).
- `app_router.dart` — `routerProvider` (Riverpod). Top-level `redirect` gates onboarding: not-complete → `/onboarding`, complete → `/today`; `/showcase` always reachable. Main app = `StatefulShellRoute.indexedStack`, 3 branches (Today/Library/Me), per-tab state preserved. `refreshListenable` = the onboarding controller. go_router 14.8.1.
- `app.dart` now `MaterialApp.router` with `routerConfig`.

**Onboarding** (`lib/features/onboarding/`):
- `onboarding_controller.dart` — `ChangeNotifierProvider` holding `Persona`, `Goal`s, health answers, `complete` flag. **In-memory** (does not survive relaunch; Hive persistence deferred). Doubles as router `refreshListenable`.
- `onboarding_flow.dart` — single route, controlled `PageView` (no swipe; advance via Continue for calm pace) + animated progress bar + back. 21 steps total.
- `onboarding_pages.dart` — all 12 synthesis §6 screens (copy verbatim): welcome, promise, pelvic-floor education, persona routing (5 opts), goal multi-select (6 opts), 9 health questions (one per screen), red-flag note (shown unconditionally in shell), function baseline (placeholder), mind/body baseline (placeholder), 12-week plan reveal, privacy + biometric toggle, first session ready.
- `health_questions.dart` — data-driven question list (rendered by one template, not N widgets).
- `widgets/selectable_option.dart` — single/multi-select option row.

**Home tabs** (`lib/features/home/`): `home_shell.dart` (NavigationBar) + `tabs/{today,library,me}_page.dart` stubs using design system. Me tab links to `/showcase` (dev).

- Old `placeholder_home.dart` removed. `flutter analyze` clean; widget test rewritten — verifies redirect→onboarding render + Begin→promise navigation. Green.

### Next

Phase 3 (roadmap Weeks 3-4) — persona-routing logic, health red-flag triage (most important: be conservative), baseline assessment battery (PEDT / IIEF-5 / Persona Zero), rule-based plan generation, onboarding persistence (Hive). Then Drift data layer.

---

## Phase 3 — Onboarding logic + plan generation — 2026-06-06

Full logic layer wired into the existing onboarding shell.

**Hive persistence** (`lib/data/onboarding_store.dart`):
- `OnboardingStore` wraps a Hive box; `save(json)` / `clear()` / `load()`.
- `OnboardingController` accepts an optional `OnboardingStore`; `_persist()` called on every mutation. State survives relaunch.

**Self-harm safety + crisis interrupt** (Task 3):
- Health question `selfHarm` added to `health_questions.dart` (Q9, always shown).
- `CrisisScreen` — full-screen interrupt shown immediately when the user reports self-harm thoughts. Lists India crisis resources: Tele-MANAS (14416), iCall (9152987821), AASRA (9820466627). Onboarding cannot advance past this screen; a "I am safe, continue" path is provided.

**Conservative red-flag triage** (`lib/features/onboarding/logic/triage.dart`):
- `evaluate(healthAnswers)` returns `TriageResult` listing zero or more `RedFlag` categories: `organicErectile`, `metabolic`, `cardiac`, `mentalHealth`.
- Conservative thresholds: cardiac flags at "sometimes" (not just "often"); each category tested independently.
- Fully TDD: 6 unit tests covering clean answers, individual flag triggers, and combined flags.

**Conditional clearance page** (`lib/features/onboarding/pages/red_flag_page.dart`):
- Shown only when `triage.hasFlags`. Category-specific copy per flag set. User must acknowledge before proceeding; `MedicalClearance` enum recorded.

**Persona → content track routing** (`OnboardingController.track`):
- `partneredActive` / `partneredInactive` → `Track.partnered`.
- All solo/prefer-not-to-say options → `Track.solo`.

**Baseline battery + banding** (`lib/features/onboarding/logic/`):
- `banding.dart` — `bandFromIndex(i)`: 0 → low, 1 → medium, ≥2 → high. Used for baseline and mind/body scores.
- `BaselinePage` — persona-calibrated questions wired through `setBaselineAnswer`.
- `MindBodyPage` — coarse banding of physical/mental wellbeing answers.

**Rule-based 12-week plan generation** (`lib/features/onboarding/logic/plan_generator.dart`):
- `generatePlan(track, goals, baseline, mindBody)` → `Plan` with 12 `PlanWeek` entries across 3 phases (foundation / build / integrate, 4 weeks each).
- Goal-specific emphasis: `finishTooQuick` adds stop-start focus; `hardness` adds arousal work; `partneredActive` adds couples exercises.
- Difficulty seeded from baseline band (low → gentle, high → challenging).
- TDD: 4 unit tests.

**Live plan reveal + Today tab wiring**:
- `PlanRevealPage` — animated week-by-week reveal of the generated plan. `OnboardingController.finish()` called here.
- Today tab (`TodayPage`) reads `plan` from the controller and renders the current week's session summary.

**Biometric app lock** (`lib/features/onboarding/pages/biometric_page.dart`):
- Opt-in toggle using `local_auth`. `setBiometricLock(bool)` stored in controller + persisted.
- Gate at app resume checks `biometricLock` before rendering shell (platform integration still required — see Deferred).

**Dev reset action** (`lib/features/home/tabs/me_page.dart`):
- `MePage` converted to `ConsumerWidget`.
- New tile "Reset onboarding (dev)": calls `onboardingControllerProvider.reset()` then navigates to `/onboarding`, allowing full replay without reinstalling.

### Deferred

- **Full discreet / Book Mode** — visual camouflage layer; deferred to Phase 5.
- **Pro-purchase enforcement of medical clearance** — RevenueCat integration; Phase 6.
- **Clinical PEDT / IIEF-5 scoring** — validated instrument scoring and result interpretation; Phase 4+.
- **Drift layer** — structured session/log persistence; next phase.
- **Platform config — `tel:` URI launch**: Android needs `<queries><intent><action android:name="android.intent.action.DIAL"/>` in `AndroidManifest.xml`; iOS needs `LSApplicationQueriesSchemes: [tel]` in `Info.plist`.
- **Platform config — `local_auth`**: iOS needs `NSFaceIDUsageDescription` in `Info.plist`; Android needs `USE_BIOMETRIC` permission and `FlutterFragmentActivity` (not `FlutterActivity`) in `AndroidManifest.xml`.

---

## Phase 4 — Lean session player slice — 2026-06-06

Full end-to-end daily loop: content catalog → scheduler → mood check-in → stepper player → reflection → progress/streak write-back.

**JSON session content catalog** (`assets/content/sessions.json`, `lib/features/sessions/logic/catalog_parser.dart`, `session_catalog.dart`):
- 13 modules covering the Foundation, Integration, and Mastery spines. Keyed by `moduleTag`; loaded at startup into `sessionCatalogProvider`.

**Runtime scheduler** (`lib/features/sessions/logic/scheduler.dart`):
- `todaysSession(plan:, week:, day:, catalog:)` — filters each week's tags to those present in the catalog, then selects by `(day − 1) % playable.length` with wraparound. Returns null on rest days or missing weeks.

**Calendar-gated progress + streak** (`lib/features/sessions/logic/progress_logic.dart`, `progress_controller.dart`, `data/progress_store.dart`, `data/session_log_store.dart`):
- `ProgressState` (currentWeek/currentDay/streak/longestStreak/lastCompletedDate) persisted in Hive.
- `isDoneToday` gates repeat sessions within a calendar day.
- `completeToday(SessionLog)` advances day/week counters, updates streak, writes the log entry.

**Pre-session mood check-in** (`lib/features/sessions/pages/mood_checkin_sheet.dart`):
- `showMoodCheckin(context)` — modal bottom sheet; up to 3 mood tags from `kCheckinMoods`. Returns null on dismiss (aborts the flow).

**Stepper player** (`lib/features/sessions/pages/session_player_page.dart`):
- Text/timer only (no audio). `AppProgressRing` per-step countdown, pause/prev/next controls. Calls `onComplete(1.0)` when last step finishes or user skips forward.

**Post-session reflection + SessionLog** (`lib/features/sessions/pages/reflection_page.dart`):
- `ReflectionPage` collects `PerceivedDifficulty` + optional blurred journal note; returns `ReflectionResult`. `SessionLog` written with start/end timestamps, completion fraction, mood tags, difficulty, and note.

**Today daily loop** (`lib/features/home/tabs/today_page.dart`):
- `TodayPage` rewritten: reads plan + progress state, resolves today's `SessionDef` via scheduler, renders session card or contextual state (no plan / rest day / done today). "Start session" triggers `_startFlow`: mood → player → reflection → `completeToday`. No log written on mid-session abandon (intentional — completion == 0.0 guard).
- Removed `unnecessary_import` of `session_models.dart`; symbols resolve through `progress_controller.dart` re-export.

**Dev reset extended** (`lib/features/home/tabs/me_page.dart`):
- "Reset onboarding (dev)" tile now also calls `progressControllerProvider.reset()`, clearing week/day/streak/logs alongside the onboarding state.

**Test** (`test/sessions/today_widget_test.dart`):
- Smoke test: override `onboardingControllerProvider` + `sessionCatalogProvider`; confirms session card ("Know the ground") and "Start session" button render for a solo week-1 plan. Passes.

### Deferred

- **Real audio + lock-screen controls** — `just_audio` + `audio_service` integration; no audio assets yet.
- **Firestore content sync** — catalog currently bundled as a static asset; remote CMS + delta sync deferred.
- **Drift migration** — `SessionLog` and `ProgressState` written to Hive; Drift schema and migration deferred.
- **Library / articles tab** — content rendering for the Library tab deferred.
- **Analytics instrumentation** — Mixpanel event calls not wired to session completion or streak milestones.
- **No log on mid-session abandon** — intentional design choice; partial-completion logging deferred.
- **Platform `tel:`/biometric config** — still pending from Phase 3 (`AndroidManifest.xml` / `Info.plist` entries). *(Resolved post-Phase-4 — see below.)*

---

## Platform config — Android `tel:` + biometric — 2026-06-06

- `AndroidManifest.xml`: added `USE_BIOMETRIC` permission and a `tel:` `DIAL` `<queries>` intent so the self-harm crisis screen can dial crisis lines and `local_auth` can prompt.
- `MainActivity`: `FlutterActivity` → `FlutterFragmentActivity` (required by `local_auth`).
- Verified with `flutter build apk --debug`.

---

## Phase 5 — Progress dashboard + Library — 2026-06-06

Ships the two highest-value, data-driven pieces of roadmap Phase 5 using only existing data + content (no new authoring, no backend). The progress dashboard is the conversion lever (synthesis §12).

**Controller read + practice API** (`lib/features/sessions/progress_controller.dart`):
- `logs()` — decodes all stored `SessionLog`s from the log store.
- `logPractice(SessionLog)` — records a free-practice session WITHOUT advancing the plan day (practice counts as activity but never consumes a scheduled day).

**Progress metrics** (`lib/features/me/logic/progress_metrics.dart`):
- `computeMetrics(logs:, progress:, phase:, now:)` → `ProgressMetrics`: total sessions, this-week count (last 7 days), streak/longest (passthrough from `ProgressState`), week/phase, easier/same/harder tallies. `hasData` gates the empty state. Clock injected for testability.

**Me progress dashboard** (`lib/features/me/me_dashboard.dart`, mounted in `me_page.dart`):
- Honest metrics from real logs — week status, this-week consistency dots (7), totals, collapsible streak card (synthesis §8: agency over shame — never the largest element). Graceful "appears after your first session" empty state.

**Library grouping** (`lib/features/library/library_catalog.dart`):
- `groupLibrary(SessionCatalog)` → ordered `LibraryGroup`s: Exercises (kegel/reverseKegel), Breathwork, Practice (mindset/sensate), Learn (education). Empty groups omitted, sessions sorted by title.

**Library tab** (`lib/features/home/tabs/library_page.dart`):
- Stub replaced with the grouped, playable catalog. Tap any session → existing `SessionPlayerPage` → `logPractice` on completion → "Nice work" snackbar. Free practice does not change the daily plan. Catalog read guarded for widget tests.

**Tests:** `progress_metrics_test`, `library_catalog_test` (pure); `dashboard_widget_test`, `library_widget_test` (widget); `practice_logging_test` (controller read + practice-no-advance, real Hive). `widget_test.dart` smoke updated for the new Library empty-state text.

### Deferred

- **Article / education text content** — Library "Learn" shows education-type sessions, not authored articles (none exist yet).
- **Strength / IELT / hold-time sparklines** — no per-session quantitative scores captured yet; showing trends would be dishonest.
- **Settings depth, discreet / Book mode, subscription card, About, search** — later phases.

---

## Privacy & Settings — discreet mode + data controls — 2026-06-06

Builds the non-negotiable privacy layer (synthesis §9 ultra-discreet mode; §210 settings) as a Settings screen reachable from the Me tab. Logic is unit/widget-tested; genuinely device-only pieces are deferred.

**Preferences** (`lib/data/preferences_store.dart`, `lib/features/settings/preferences_controller.dart`):
- `PreferencesController` (Hive `preferences` box): `bookMode`, `disguiseName` (none/Calendar/Notes/Wellness), `notificationsEnabled`. Private-safe defaults (all off). `toJson`/`loadFrom`/`reset`, hydrated in `main.dart` via override.

**Book Mode disguise** (`lib/features/settings/book_mode_cover.dart`, wraps `BiometricGate` in `app.dart`):
- When on, the app opens into a plain "My Notes" reading screen; a discreet double-tap reveals the real app. In-app half of §9's book-mode disguise (native icon/name swap deferred).

**Data export** (`lib/features/settings/logic/data_export.dart`):
- `assembleExportJson(...)` — one pretty-printed JSON of onboarding + progress + session logs + preferences (pure, tested). Delivered via `share_plus` share sheet.

**Delete everything** (`lib/features/settings/account.dart`):
- `wipeAllData(...)` resets onboarding + progress + logs + preferences (clears every Hive box), two-tap confirm dialog, routes back to onboarding.

**Settings screen** (`lib/features/settings/settings_page.dart`, entered from the Me tab's Privacy tile):
- Sections: Lock (biometric), Disguise (Book Mode + app-name picker), Reminders (daily toggle), Your data (export / delete). Biometric reuses `OnboardingController.biometricLock`.

**Platform config** (added alongside this work):
- `AndroidManifest.xml`: `USE_BIOMETRIC` + `tel:` `DIAL` `<queries>`; `MainActivity` → `FlutterFragmentActivity`. Build-verified.

### Deferred

- **Native app-icon / name swap** (Android activity-alias) — disguise-name preference is captured; the OS-level swap is device work.
- **OS notification scheduling** (`flutter_local_notifications`) — daily-reminder toggle persists intent only.
- **Language switch** (Hindi) — Phase 2.
- **Anonymous auth / encrypted cloud sync** — later.

---

## Education articles — Library Read section — 2026-06-06

The "teach, don't shame" backbone: bundled psychoeducation articles in the Library.

**Content** (`assets/content/articles.json`): 6 articles — How your pelvic floor works (Anatomy); Kegels and reverse Kegels, simply (Training); Breathing and arousal; The brain–erection connection; Porn, dopamine, and rebalancing; Performance anxiety, and why it eases (Mind & body). Calm, agency-over-shame voice; each ends with a "general education, not medical advice" note.

**Model + parser** (`lib/features/library/logic/article.dart`, `article_parser.dart`): `Article` (slug/title/category/readMinutes/body markdown) + `parseArticles` (TDD).

**Catalog** (`lib/features/library/article_catalog.dart`): `ArticleCatalog.load()` via rootBundle → `articleCatalogProvider`, loaded at startup in `main.dart`.

**Reader** (`lib/features/library/pages/article_reader_page.dart`): `flutter_markdown` `MarkdownBody`, with a `category · ~N min read` header.

**Library wiring**: a "Read" section at the top of the Library tab lists article cards (tap → reader). Catalog read guarded for widget tests.

### Deferred

- **Firestore article sync** — bundled asset for now.
- **Search, tags, bookmarks, reading history** — later.
- **Hindi** — Phase 2.
- **CMS / content pipeline** — articles authored in-repo for now.

---

## Analytics — event instrumentation — 2026-06-06

The roadmap funnel, instrumented from day one behind a testable seam.

**Seam** (`lib/core/analytics/`):
- `Analytics` interface + `NoopAnalytics` default (so tests/un-overridden reads never touch Firebase); `FirebaseAnalyticsService` forwards to `FirebaseAnalytics.instance` (wired only in `main.dart`); `analyticsProvider`.
- `AppEvents` typed helpers (one method per event, snake_case names, list params comma-joined per Firebase rules) + `appEventsProvider`. Pure, TDD-covered against a `FakeAnalytics`.

**Wired events** (from the UI layer only — pure logic stays Firebase-free):
- `app_opened` at launch.
- Onboarding finish: `persona_selected`, `goal_selected`, `plan_generated`, `health_screen_red_flag_fired` (per fired category), `onboarding_completed`.
- Session loop (Today): `mood_checkin_completed`, `session_started` (type/week/day), `session_completed` (type/pct).
- Settings: `data_exported`, `account_deleted`, `biometric_lock_enabled`.

### Deferred

- **Paywall / subscription events** — no paywall yet.
- **Mixpanel cohort layer** — Firebase only for now.
- **User properties** (`daysActive`, `hasPro`, `priceTier`) — need auth/subscription.
- **A/B variant tagging**, `onboarding_abandoned` granularity — later.

---

## Hide-streak toggle + Crashlytics — 2026-06-08

Two unblocked wins (advisor-sorted: ship-a-real-feature, no missing keys).

**Hide-streak toggle** (synthesis §8 — agency over shame; the streak must never become a pressure lever):
- `PreferencesController.hideStreak` (default `false`) + `setHideStreak`, persisted in the existing `preferences` Hive map (`toJson`/`loadFrom`/`reset`).
- Progress dashboard gates the entire streak card behind `!hideStreak` — totals/this-week still render, the streak counter disappears.
- Settings: new "Progress" section with a "Hide streak" switch.
- TDD: pref round-trip/default/reset; dashboard widget test asserts the streak card is gone when the pref is on.

**Crashlytics** (rides the committed Firebase config — no separate key; gradle plugins `com.google.firebase.crashlytics` + `google-services` already applied):
- `main.dart` routes `FlutterError.onError` → `recordFlutterFatalError` and `PlatformDispatcher.instance.onError` → `recordError(fatal: true)` after `Firebase.initializeApp`.

79 tests pass, `flutter analyze` clean.

### Deferred / needs device verification

- **Crashlytics end-to-end** — wiring compiles; actual crash upload to the Firebase console is device-only (force a test crash on a real build to confirm).
- **Mixpanel sink** — still gated on a project token (not built; would be dead code until the key arrives).
- **Notification scheduling** — superseded below.

---

## Daily reminder — notification scheduling — 2026-06-08

Makes the "Daily reminder" switch real (previously persisted intent only).
Full vertical slice; daily-retention lever.

**Design decision (was unspecified in synthesis):** one daily reminder at a
**user-chosen time, default 20:00** (calm evening nudge), off by default.
Calm copy ("A few quiet minutes for yourself today.") — no fear, no shame.

**Seam** (`lib/features/notifications/`):
- `NotificationService` interface + `NoopNotificationService` default (tests/un-overridden reads never touch the platform); `notificationServiceProvider`.
- `LocalNotificationService` — `flutter_local_notifications` + `timezone`/`flutter_timezone`; `zonedSchedule` with `matchDateTimeComponents: time` for daily repeat, **inexact** (`inexactAllowWhileIdle`) so no `SCHEDULE_EXACT_ALARM` permission and friendlier to OEM battery managers. Wired only in `main.dart`.
- `nextReminderTime(...)` — pure schedule math (today vs roll-to-tomorrow), TDD.
- `applyReminderSetting(...)` — coordinator: schedule when enabled+permitted, cancel otherwise; returns active-state so the UI reverts its toggle if the OS denies permission. TDD with a fake service.

**Prefs:** `reminderHour`/`reminderMinute` (default 20:00) added to `PreferencesController` (persisted/round-trip/reset).

**UI:** Settings "Daily reminder" toggle now schedules/cancels; a "Reminder time" row (shown when on) opens a time picker and reschedules.

**Native:** `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED` permissions; scheduled + boot receivers; core-library desugaring enabled in `app/build.gradle.kts` (required by the plugin).

**Verified:** 86 tests pass, `flutter analyze` clean, **debug APK builds** (native config + plugin link confirmed).

### Deferred / needs device verification

- **Actual firing** — that a notification appears at the set time, repeats daily, survives reboot, and is not killed by Xiaomi/Oppo/Vivo battery managers — is device-only. Test on a real OEM device.
- **Notification small icon** — uses `@mipmap/ic_launcher` (renders as a white square on some Androids); a dedicated monochrome `@drawable/ic_notification` is a polish follow-up.
- **Crashlytics end-to-end** — wiring compiles + builds; crash upload to the console is device-only.
- **Mixpanel sink** — still gated on a project token (not built).

---

## Device pass — 2026-06-08

Real-device verification (A015, Android 16 / API 36) of this session's work.

**Verified on-device:**
- App launches clean after the notification plugin + desugaring + manifest changes (no crash; Book Mode disguise → double-tap reveal → Today still works).
- **Daily reminder**: toggle fires the OS `POST_NOTIFICATIONS` prompt; on Allow the alarm lands in the OS table (`dumpsys alarm` shows `RTC_WAKEUP … ScheduledNotificationReceiver`, `origWhen` = next 20:00, `window=+1h` confirming inexact). "Reminder time" picker row appears and shows the set time (8:00 PM).
- **Hide streak**: toggling on removes the streak card from the Me dashboard.

**Bug found + fixed on-device:** Hide streak gated only the Me dashboard — the Today header still showed "🔥 N-day streak". Now gated on both surfaces; the "Done for today" copy also drops the streak reference when hidden. Regression test added (`today_widget_test`).

**Notification firing — VERIFIED on device:** set the reminder ~3 min out via the time picker; the alarm rescheduled in the OS table for the correct same-day time (`origWhen` today, `window=+2m`, inexact), and the notification actually posted at the scheduled time — `NotificationRecord pkg=com.saurabh7973.sahaj id=1001 channel=daily_reminder importance=DEFAULT flags=AUTO_CANCEL`, visible in the shade with the calm copy ("A few quiet minutes for yourself today.").

**Still device-pending:** multi-day OEM battery-kill survival (Xiaomi/Oppo/Vivo) across reboots/idle; Crashlytics crash upload to console.

---

## Notification reliability — exact alarms + battery-opt exemption — 2026-06-08

Adopted the proven pattern from our `sanatan_guide` app to close the OEM-doze
reliability gap (inexact alarms were the weak point).

- **Exact alarms**: schedule mode → `exactAllowWhileIdle` so the reminder fires
  AT the picked minute instead of being deferred for hours by Doze. Wrapped in
  a try/catch that falls back to `inexactAllowWhileIdle` if the OS denies exact
  (Android 14+ can revoke), so launch never crashes.
- **Exact-alarm permission**: `requestExactAlarmsPermission()` on enable
  (auto-granted ≤13; routes to Settings on 14+).
- **Battery-optimisation exemption**: `permission_handler` →
  `Permission.ignoreBatteryOptimizations.request()` on enable — the real fix for
  MIUI/One UI/ColorOS Doze kills. The exact-alarm permission alone isn't enough.
- **Manifest**: `SCHEDULE_EXACT_ALARM` + `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`;
  `USE_EXACT_ALARM` stripped via `tools:node="remove"` (Play restricts it to
  alarm-clock/calendar apps — a wellness app isn't one, so leaving it risks
  store rejection). Added `ActionBroadcastReceiver`.
- **Channel** created explicitly at init (default importance — keeps the nudge
  calm, no heads-up interrupt). Permission-request concurrency guard.
- **main.dart** launch-time reschedule wrapped in try/catch (belt-and-suspenders).

Kept `matchDateTimeComponents` (daily repeat) deliberately: a reminder must keep
firing even if the user never reopens the app, which one-shot exact (sanatan's
verse-of-day approach, rescheduled on open) would not. Trade-off: repeating
alarms are windowed until exact is granted.

**VERIFIED on device** (A015 / Android 16): enabling the reminder launched the
`RequestIgnoreBatteryOptimizations` system dialog ("Let app always run in the
background?") → Allow → app added to `deviceidle whitelist` +
`RUN_ANY_IN_BACKGROUND: allow`. With exact-alarm + battery-opt granted, the
alarm rearmed **exact**: `dumpsys alarm` → `window=0 exactAllowReason=permission`
(was `window=+1h` inexact before the grant). No crash on either path. 88 tests,
analyze clean, debug APK builds.

### Notification icon — 2026-06-08

Replaced the generic launcher icon (white square on the status bar) with a
dedicated **white lotus vector** (`res/drawable/ic_notification.xml`) + muted-
ochre tint (`AndroidNotificationDetails.color`, matching the in-app accent).
Vector drawable so it scales at every density without PNG assets. On-brand and
discreet for a wellness app.

**VERIFIED on device:** notification posted at the exact set time (23:12:00,
`window=0 exactAllowReason=permission`) showing the ochre lotus badge instead of
the Flutter diamond. Closes notification parity with `sanatan_guide`.

---

## Crisis-line dialing — verified on device — 2026-06-09

The safety-critical path, end-to-end on a real device (A015 / Android 16),
previously only widget-tested + composition-inferred.

- Reset onboarding → drove the full intake → answered the self-harm question
  **"Several days"** (above "Not at all") → Continue → **crisis screen shown**
  ("You deserve support" + Tele-MANAS 14416 / iCall / AASRA + "I'm safe, continue").
- Tapped the **Tele-MANAS** card → `launchUrl(tel:14416, externalApplication)`
  fired → Android app chooser → Phone → **dialer opened pre-filled with 14416**.
- Critically, it **stops at the dialer with a Call button** — no auto-dial; the
  call is user-initiated. Returning from the dialer restores the crisis screen
  intact (external launch, state preserved).

Confirms the manifest `tel:` DIAL query + url_launcher path work on-device.

---

## Phase 6 (partial) — Subscription code behind a seam — 2026-06-09

The paywall + pricing + gating + repo, built with NO RevenueCat key and NO
Play upload (those are the last plumbing step). All demoable with a fake.

**Pure logic (TDD):**
- `PricingTier` — free/low/standard/supporter = ₹0/499/999/1499; only paid tiers
  have Play product ids (`sahaj_pro_499/999/1499`); ₹0 has none (Play won't list
  a free sub — it's a local grant). `standard` is recommended.
- `feature_gate` — `isFeatureLocked` + free allowances (`isArticleLocked` ≥3,
  `isSessionLocked` ≥8 per synthesis §8).

**Seam:**
- `SubscriptionRepository` interface + `NoopSubscriptionRepository` default +
  provider. Real `RevenueCatSubscriptionRepository` deferred to key-wiring.
- `SubscriptionController` (ChangeNotifier) + `SubscriptionStore` (Hive):
  `choose(tier)` grants ₹0 locally with no purchase / runs purchase for paid;
  `refresh()` reconciles with backend but never expires a free grant;
  `restore()`; persisted, survives offline relaunch. TDD with a fake repo.

**UI (soft-paywall guardrails — synthesis §8 / principle 7):**
- `PaywallScreen` — 4 tier cards, ₹999 "Recommended", single CTA
  "Continue with ₹X / year", **X always present**, **"Maybe later" always**,
  no countdowns, no red, honest tiny-print.
- `SubscriptionPage` — current tier, "Manage in Google Play", restore, calm
  why-pay copy (value not fear).
- Me tab → "Upgrade to Pro" / "Sahaj Pro" tile.

**Analytics:** `paywall_viewed` (source), `paywall_tier_selected`,
`subscription_started`, `subscription_restored`.

Wired in main() with the Noop repo (guarded refresh). 105 tests, analyze clean.

### Deferred (the key-wiring step, when app is ready to test billing)
- `RevenueCatSubscriptionRepository` impl + `Purchases.configure(key)` in main
  (guarded), real offering/product fetch.
- Play Console: upload AAB to internal testing → create the 3 products.
- RevenueCat: link Play service account, entitlement `pro` + offering, SDK key.
- Per-content free/Pro tagging in the catalog (currently gate logic exists but
  sessions/articles aren't individually flagged yet) + soft-paywall on locked
  taps.
- `subscription_started`/`cancelled` real receipt events; wipe-all to clear the
  subscription store.

## Release signing + code-complete pass — 2026-06-09

- Release signing wired: upload key read from gitignored `key.properties`
  (`android/app/build.gradle.kts`); falls back to debug signing when absent so
  CI/dev builds keep working. User runs `keytool` + fills passwords when ready.
- Wipe-all now also clears the subscription store (a deleted account no longer
  resurrects a Pro grant).
- Notification tap deep-link: cold-start payload consumed in `main()` →
  `reminder_opened` analytics (retention signal).
- Privacy copy fixed: stopped promising cloud sync (not built; local-first is
  the truth).

With this, v1 feature code is complete — remaining work is content, keys
(RevenueCat), and the device/UX passes.

## Content — verified article + goal personalisation + session variety — 2026-06-10

- **Pelvic-floor article verified + seeded**: research-merged, in-voice draft
  replaces placeholder #1 in `assets/content/articles.json` (source kept in
  `content/articles/`). Still needs doctor sign-off before Play. Other 5
  articles remain placeholders pending the 7-topic batch.
- **Goals now personalise the plan**: the computed `emphasis` set was never
  consumed — wired it into Integration + Mastery weeks (5–12), Foundation
  stays a shared base. Authored the 5 missing emphasis modules (reverse_kegel,
  arousal_confidence, readiness, dopamine_rewire, advanced_control).
- **Week-rotating session variety**: a tag may now have variant modules
  (`tag_v2`, `tag_v3`); the scheduler rotates them by week so a phase no
  longer replays the identical session weekly. Authored variants for every
  repeated tag — catalog 13 → 54 modules, all in-voice, no health claims.
- **Asset integrity test**: validates the real `sessions.json` — well-formed
  modules, contiguous variant chains, and every plan tag from every
  track/goal combination resolves to a session.

## Audio playback engine — behind a seam — 2026-06-10

Roadmap format decisions were already on record (just_audio + audio_session,
M4A 96kbps, Firebase Storage stream-first + cache), so the engine is no
longer held on content:

- `SessionDef.audioRef` — optional per-locale map
  (`{"en": "audio/<tag>_en.m4a"}`); absent = text+timer (whole catalog today).
- `resolveAudio` pure logic (TDD): exact locale → `en` fallback → null;
  classifies http(s) refs as network (streamed via `LockCachingAudioSource`,
  cached for offline) vs bundled asset paths.
- `SessionAudio` seam + Noop default + `JustAudioSessionAudio` impl
  (audio-session speech config: ducks others, pauses on interruption).
- Player integration (TDD with a fake): load+play on start, pause/play
  toggles audio with the step timer, dispose releases the platform player,
  text+timer sessions never touch the seam, bad ref degrades silently.
- Wired via `sessionAudioFactoryProvider` in `main()`; Today + Library pass a
  fresh instance per played session.

Activating audio later is content-only: add `audioRef` to a module in
`sessions.json` — zero code. 122 tests, analyze clean, debug APK builds.

### Deferred
- Lock-screen controls / background play (audio_service) — revisit once real
  audio content exists and the in-session experience is validated.
- TTS voice pick (Kokoro vs Edge `en-IN-PrabhatNeural` vs own voice) — listen,
  don't theorize; then record the catalog.

## Lamplight UI pass — tokens + Module 1 (Session Loop) — 2026-06-13

Build-order step 1 of the design handoff (`docs/design/00_MASTER_HANDOFF.md`).

- **Theme calibrated to Part A (mocks = pixel truth):** `AppColors` recalibrated to the lamplight.css palette; `LamplightTokens` ThemeExtension (bg/deep/ember rooms, ink scale, ochre/gold/moss/sand/turmeric, session-type tints, `context.lamp`). No red anywhere — `error` is now turmeric. Fraunces + Manrope bundled in `assets/fonts/` (google_fonts dropped from theme — fully offline, deterministic screenshots). Type scale per A3 with tabular numerals + mock styles (eyebrow, phase, numeral, italic, timeLeft). Motion constants extended (breath scale 0.86↔1.00, dim 42%, press 0.98). 64px grain asset generated + `LampBackground` (standard/deep/ember rooms).
- **Primitives:** `AppProgressRing` rebuilt — countdown / holdPulse / breath modes, fixed tick dial, gradient arc + glow pass, radial halo, paused desaturation, reduced-motion opacity pulse, TalkBack label. `AppMoodSelector` rebuilt — 5 calm-contour glyphs (Heavy/Low/Level/Open/Charged), multi-select ≤3, no emoji. New: `AppChip` (type tints/ok/warn), `RuleDivider` (pothi rule), gradient `AppButton` variants (filled/moss/outlined/text).
- **Step patterns:** optional `pattern` on session steps (`holdRelease{hold,release}` / `breath{inhale,holdIn,exhale,holdOut}`); reps derived from step seconds. 5 catalog steps annotated mechanically from numbers already in their guidance text.
- **Mood calibration engine** (`session_calibration.dart`): heavy → reps ×5/8 + exhale doubled ("gentler tonight"), charged → +1 hold, level → honest "runs as planned". Echo template `You arrived {mood} — {change} tonight.`; never fabricates. Skip path = no echo. Mood list migrated 8→5 keys (old logs tolerated).
- **M1 screens:** mood check-in sheet + prescription echo (crossfade, delta line, "Change how I arrived") · player rebuilt in the deep room (semantic layering, phase ring + 74pt numeral, step-segment bar, 4:20 LEFT line with stop-anytime clause on holds 1–2, paused recession, audio toggle, status chips) · face-down coach (one-time cue legend) + Ember mode (12px ember, 7% arc, double-tap wake) · reflection (slope glyphs, same gold for Harder, skip = still logs) · completion (lotus bloom 700ms line-draw, pothi rule, milestone variant with journey spine).
- **Flow:** Today → mood/echo → (first-time coach) → (first-audio earphone prompt, ask-once) → player → reflection → completion → done state. Haptic cue engine behind a seam (decision #8) wired to phase transitions; face-down sensor seam (decision #9) defaults to manual entry. Keep-awake during sessions (wakelock_plus). Interruption pauses, never auto-resumes. Settings → Reminders gains haptics toggle + cue-guide re-access.
- **Verification:** 152 tests green (new: phase derivation, calibration table, 1.3× string-room overflow checks). 12 review screenshots → `docs/ui_review/` (generated by `test/ui_review/m1_screenshots_test.dart` with real fonts).

### Open decisions surfaced (handoff list)

- #1: calibration rows for `low`/`open` — nothing defined in code/docs; they run unchanged.
- #8/#9: haptic primitives + face-down sensing are device tests; seams in place.
- #14: "you can stop any time" implemented as specced (holds 1–2 then drops) pending the tone read.
- M3 will wire the milestone "Take the check-in" action; until then it lands on Today.

## Lamplight M2 — Today, the daily front door — 2026-06-13

Build-order step 3 (`m2_today_spec.md`, mocks m2_01–04).

- **Doorway doctrine:** one hero with CTA energy; the 12-week spine is cut from Today (week position = top-right `WK N · phase` chip only); no dashboard creep.
- **today_logic.dart** (pure, tested): `TodayKind` (empty/day0/gapReturn/done/standard), why-line table verbatim from spec (priority: day0 > gap > milestone > week-start > after-harder > normal), display-streak (stored streak survives only if last completion was today/yesterday — never stale), Mon-start week dots + completions, greeting bands, `Thursday · 11 June` eyebrow.
- **Gap return (principle 8's proof screen):** `kGapThresholdDays = 3` behind a constant (DECISION #2 — spec's own candidates were 2/3; engine has no value), `calibrateGapReturn` reuses M1's calibrate-down so "a notch gentler" is a real reduction, week chip `plan adjusted`, hero chip `adjusted`, steady zero in faint with `longest N` kept as the dignity anchor.
- **States:** default (hero card with lotus watermark, type/duration/day-N chips, why-line, mood micro-row, 52dp Start) · hidden-streak (tile simply absent) · done (moss card, tomorrow chips, free-practice link → Library) · day 0 (`first session` ok-chip, `starts tonight` week card, no steady tile — earned into existence) · true-empty (calm-contour lamp).
- **New shared widgets:** `WeekDots` (B2), `LotusMark` (watermark + medal glyph), `MoodGlyph` single-glyph export, `AppButton.height`.
- **Verification:** 174 tests green (today_logic table tests, widget-state tests, 1.3× string-room incl. Start-above-the-fold check). Screenshots m2_01a/01b/02/03/04 → `docs/ui_review/`.

### Open decisions surfaced

- #1 (M2): weekly denominator — engine schedules 7/7 days, so `N done` without denominator stands.
- #2: gap threshold default 3 — constant in `today_logic.dart`, change there.
- #3: date format hardcoded English pending l10n call.
- #4: free-practice link done-state-only, as recommended.

## Lamplight M3 — Me / Progress & Check-ins — 2026-06-13

Build-order step 4 (`m3_progress_spec.md`, mocks m3_01–04).

- **Honesty doctrine enforced in code:** every chart carries a source tag (`from your session logs` / `from your sessions` / `from your check-ins`); nothing is projected; the honesty footer ("We never estimate…") ships on every state; down/flat never alarms — flat = faint em-dash, dip = faint "one measurement, not a verdict", no red, no coloured ▼. Dashboard is 100% free (no chart gated).
- **Data layer:** `CheckinStore` + `CheckinController` (records {week, raw scores, completedAt}; pendingWeek marker for deferred check-ins; week-0 read from onboarding `baselineRaw`). `SessionLog.holdSeconds` added — the player now counts squeeze-phase seconds for the honest MIN+HOLD-SECONDS volume label. Wired into wipe + JSON export.
- **dashboard_logic.dart** (pure, tested): domain id→label map per track (Control/Confidence/Staying-power · Control/Confidence/Calm — DECISION #2 flagged), check-in series (points at wk 0/4/8/12, deltas vs week-0 computed at render never stored, decision #1 relative-only), delta caption (ups only, honest "small movements" framing), consistency grid (1 row → 4 then slides), weekly volume, input recap (sessions · minutes · D of N days).
- **Widgets:** JourneySpine (horizontal, moss/ochre/faint, phase ✓), StatTile, ConsistencyGrid (3 moss intensities), VolumeBars (sand/current-ochre, 400ms draw), CheckinChart painter (baseline, lit gradient dots + halo, dashed futures, gradient line, week labels, TalkBack sentence).
- **Me tab rebuilt to the growth rule:** cards earn existence (no stat tiles pre-first-session; check-ins card always present with the wk-0 promise); the one reorder the tab does — check-ins moves above volume once a comparison exists, card border warms + `first comparison` chip; reflection-trend strip cut (effort feeds Today's why-line).
- **Check-in flow (m3_04):** intro (diamond medallion, "Same questions as week 0.", Begin/Tomorrow) → questions (reuse onboarding SelectableOption, persona battery, identical wording) → result on the deep room (enlarged chart, domain delta rows ▲/—, moss input-recap card pairing outcomes with inputs, honesty line). Wired: the M1 milestone "Take the check-in" now launches it; "Tomorrow" defers and re-surfaces at the next completion only (never Today, never notification).
- **Verification:** 193 tests green (check-in series/grid/volume/recap unit tests, dashboard widget states, check-in flow, 1.3× string-room). Screenshots m3_01–04 → `docs/ui_review/`.

### Open decisions surfaced

- #1: deltas relative-only ("on your own week-0 scale"), as recommended.
- #2: domain labels derived 1:1 from the built baseline batteries — confirm against the plan engine before adding domains.
- #3: flat/dip copy uses the generic doctrine line (no evidence-backed week-4 line found in synthesis.md).
- #4: Me subscription tile shows a plain label — revisit in M7.

## Lamplight M4 — Onboarding (the shame-removal machine) — 2026-06-13

Build-order step 5 (`m4_onboarding_spec.md`, mocks m4_01–03 + adopted v2 01–12).

- **Full Lamplight reskin of the 12-screen arc** with canonical copy from the spec: Welcome (lotus line-mark, सहज eyebrow, free-forever chips), Promise (three trust-contract cards), Education (3-slide pager with calm-contour illustrations — hammock → pelvis cross-section → support/control/blood-flow vignettes), Persona (Persona Zero placed 4th, never last), Goals, Health check (why-strip → question → option cards → "tap an answer to continue"), Triage (turmeric reason chips, doctor-article + continue), Baselines (C8/C9), Privacy (biometric + double-tap coach strip), First session (ring preview at 7-min, Start now / This evening).
- **m4_01 validated-instrument template:** PHQ-2/GAD-2 items get the "two standard questions every doctor uses — same words, answer honestly not bravely" strip + "PHQ-2 · standard wording, unchanged" footer; the item itself is rendered untouched (wrap-don't-reword).
- **m4_02 plan reveal:** the only "wow" — an 8-beat staggered choreography (fade+rise ~80ms apart, ~700ms total, instant under reduced motion), journey rail with phase cards + milestone captions, and up to two personalized lines tied to real goals (`planRevealLines` — 6 goal→line mappings, never padded, decision #2). Commitment chips + CTA arrive last.
- **m4_03 resume:** onboarding now persists `lastStep` after every advance; returning mid-flow lands on the resume screen (bookmark medallion, "You were on the health check.", "Question N of 10" — the one allowed numeral) → Continue resumes at the exact pending screen, Start over wipes onboarding answers only (decision #3).
- **C7b crisis** reskinned to spec: deep room, largest type, no decoration, three `DialCard`s (real `tel:` intents, numbers as implemented), quiet text Continue. Self-harm item > "Not at all" triggers it immediately (decision #1 — confirmed against the built `self_harm` question + threshold).
- **New shared widgets:** `StepDots` (no numerals), `DialCard`; `SelectableOption` reskinned to the Lamplight `.opt` style (shared with the M3 check-in).
- **Flow rewritten** to self-contained Lamplight screens with explicit nav callbacks (replacing the old PageView); health/baseline/mind-body questions auto-advance on tap; triage conditional-skip preserved.
- **Verification:** 214 tests green (rewritten crisis-trigger tests for the new mechanics, personalized-lines + resume-step tests, 1.3× string-room). Screenshots m4_01–03 + welcome/education/persona/health/first-session/crisis → `docs/ui_review/`.

### Open decisions surfaced

- #1: crisis trigger = `self_harm` item, any answer above "Not at all" (matches built logic).
- #2: six goal→line mappings written to the plan engine's adaptations; two match the spec examples, four are new — review the tone.
- #3: Start over is onboarding-only wipe, as recommended.
- #4: screening-incomplete-on-Today is **not reachable** — onboarding is gated all-or-nothing (router redirect), the flow only completes at C12, so there is no partial-screening Today state to write. Revisit only if the gate changes.
- Validated-item wording: shown with calm framing but the existing prompts are kept as-is; making them byte-identical to the published PHQ-2/GAD-2 source is a content/clinical task, not this visual pass.

## Lamplight M5 — Library & Reader — 2026-06-13

Build-order step 6 (`m5_library_spec.md`, mocks m5_01–02 + adopted v2 14/20).

- **Two registers, never blended (law 1):** the `Article` model gained `register` (evidence/heritage), `reviewState` (reviewed/pending), `reviewedDate`, `sources[]` (name + one-line finding), and `eraTag` — all optional, so the 6 existing articles render as evidence/review-pending (honest, shippable). Evidence pieces carry a `DoctorBadge`; heritage pieces carry a sand `heritage · 1885` chip and **never** a review badge in any state.
- **One lock type (law 2):** `isSessionLocked` via `kFreeSessionBaseTags` — the Foundation base techniques (and their `_vN` variants) are free, everything past is a `Pro` chip, never a week-gate (DECISION #1 flagged). Library exposes all free sessions regardless of plan week.
- **Library tab** rebuilt to Lamplight: reading first (article cards with type medallion + badge), then collapsible practice groups (one open at a time, medallion + count + chevron); rows are pure utility (title · context · duration · faint ✓ done-before · `Pro`); **free rows sort before Pro** within every group.
- **Search (m5_01):** filter-as-you-type, local, titles-only (decision #4), match substring highlighted ochre, `N matches` line, zero-match sections simply disappear, ✕ clears — no search history ever.
- **PreviewSheet:** a locked row opens a bottom sheet that describes (using the session's real working step, never a fabricated pitch) → `See Pro` / `Maybe later`; never blocks mid-task. Free practice goes straight to the player (no mood sheet — it isn't the prescribed session).
- **Reader (20 + m5_02):** scroll-driven ochre progress bar (the only reading gamification), back + bookmark. Evidence register: `READ · EVIDENCE-BASED` eyebrow, Fraunces drop cap on the opening paragraph, 17/27.5 reading scale, pothi rule, trust footer (review badge + date + "review record on file", collapsible `SourcesBlock`, next-article hero card). Heritage register: `READ · HERITAGE` turmeric eyebrow, the standing canon line *"Heritage, not instruction — and never medicine."*, `> ` blockquotes become `PullQuote`s (oversized Fraunces quote-mark, pothi rules, era tag in small caps), zero health claims.
- **New widgets:** `DoctorBadge`, `HeritageChip`, `LockChip` (no padlock glyph), `DoneTick`, `TypeMedallion`, `HighlightedTitle`, `SourcesBlock`, `PullQuote`. Removed the unused `flutter_markdown` dependency (reader renders blocks itself for drop-cap + pull-quote control). Deleted the superseded `library_catalog.dart` (replaced by `library_logic.dart`).
- **Verification:** 232 tests green (session-lock/grouping/search logic, library widget states, evidence + heritage reader, 1.3× string-room). Screenshots m5_01/02 + library + evidence/heritage readers → `docs/ui_review/`.

### Open decisions surfaced

- #1: free-session set = Foundation base techniques + variants — confirm the intended free scope.
- #2: heritage doctor-gate — pieces are outside the medical gate by design; the badge stays off the cards regardless of whether you review them.
- #3: related-session footer (read→do bridge) — not adopted; needs a new content field, revisit before seeding.
- #4: search is titles-only, as recommended.
- Heritage seeding: the pull-quote line is a placeholder until a verified excerpt is seeded; citation "what it showed" lines need the doctor-pass verification.

## Lamplight M6 — The Privacy System — 2026-06-13

Build-order step 7 (`m6_privacy_spec.md`, mocks m6_01–02 + adopted v2 21–24).

- **Book Mode cover** rebuilt as a believable stock-Material notes app (the sanctioned design-system exception, commented in code): "My Notes" list of 6 canned, mundane Indian-household notes (static dates), each opening **one level** to a read-only note — the grocery checklist with one ticked/struck item and an "ask Mummy re: jeera brand" line; FAB + toolbars are inert decoys. Double-tap anywhere reveals the app. Backgrounding (any route, Book Mode on) re-arms the cover via `didChangeAppLifecycleState` so the recents thumbnail shows the notes app, never the last real screen. All content is canned — never generated from anything real.
- **Gate** reskinned to Lamplight (`24`): lotus mark + dashed sensor ring + "Touch the sensor to unlock", biometric auto-fires, `Use PIN` falls back to the pad. No app name, no purpose (it may be glimpsed).
- **PIN pad (m6_02):** mark + dots + 76dp keys; wrong PIN → dots flash turmeric + 200ms shake (flash-only under reduced motion) + "Try again" — no red, no countdown. `Use fingerprint` and `Forgot PIN` affordances; Forgot routes to the erase confirm (no recovery — local-first means wipe-and-restart is the honest path). TalkBack announces "N of 4 digits entered", never the digit. `PinSetupScreen` does choose-then-confirm.
- **Lock layer:** `LockController` + `PinStore` seam — `SecurePinStore` (flutter_secure_storage / Android Keystore is the real protection for a 4-digit PIN; no hashing theater) in prod, `MemoryPinStore` in tests. PIN length 4, lockout policy flagged (decision #1).
- **Erase confirm (`22`)** is now a full-screen page, never a dialog: "Erase everything", no-cloud body, the new `HoldToConfirm` (press-hold 3s, ring-fill meter, release resets with no penalty copy), `Keep my data` ghost. Wipes everything including onboarding answers and the PIN, then returns to Welcome.
- **Settings (`21`)** patched: a `Set/Change PIN` row in the Lock section, the haptic-cues relearn row (from M1), and the delete flow now pushes the full-screen erase confirm. Button copy fixed to "Erase everything".
- **New widgets:** `HoldToConfirm`, `PinPad`/`PinSetupScreen`, `DialCard` reuse. No red on any failure state anywhere.
- **Verification:** 248 tests green (lock controller, PIN pad ceremony + setup flow, erase hold/release, settings sections, existing cover double-tap, 1.3× string-room). Screenshots m6_01/02 + cover + erase → `docs/ui_review/`.

### Open decisions surfaced

- #1: PIN length 4 + lockout policy after repeated failures — flagged, no lockout enforced yet; the screen absorbs either.
- #2: panic gesture (in-app two-finger swipe to cover) — proposal, not adopted.
- #3/#4: native concerns (activity-alias label flow to App Info / notifications, recents FLAG_SECURE fallback, alias collision on OEM skins) remain device-side TODOs — the Flutter cover/recents-swap half is done; the OS-level alias is a separate native task.

## Lamplight M7 — Monetisation (the fair shopkeeper) — 2026-06-13

Build-order step 8 (`m7_monetisation_spec.md`, mocks m7_01–03 + adopted v2 25–26).

- **Paywall** rebuilt to Lamplight (25/m7_01): eyebrow + always-visible X · H1 "Pick what's reasonable for you" · pothi rule · scale-explanation line · 4-benefit moss-tick grid · four `TierCard`s (`.opt` style, Fraunces price + canon meaning line, gold border + filled radio when selected, ₹999's Recommended chip a fixed label with a faint gold glow). **Nothing is pre-selected** — the CTA sits disabled with "Nothing is pre-selected — tap a tier first." and wakes on selection; the tiny print becomes price-specific ("₹499/yr after 7 days free · cancel anytime in Play · price never changes mid-subscription"). Choosing **below** the recommendation triggers no nudge — selection ends the conversation (equal dignity at every price).
- **₹0 dismissal (m7_02):** tapping ₹0 grants the free entitlement, closes to the originating screen, and shows a single-line moss-tick toast "Good — train on." (fade only). Pull-never-push: the wall never re-prompts unprompted.
- **Subscription page** rebuilt to the five-state model (26/m7_03): **Free** ("You're on Free / It stays free." + quiet See Pro), **Trial** ("Sahaj Pro" + `trial until {date}` + `then ₹X/yr` + cancel-without-charge line), **Active** (`₹X/yr` + `renews {date}` + "Your price stays ₹X — it never changes mid-subscription"). Manage-in-Play + Restore tiles (inline result, no dialog) + "handled by Play — we never see your card" strip. **Dates, not countdowns** everywhere (`billingDate`: "18 June" / "14 June 2027").
- **Trial/renewal on the controller:** `inTrial` + `trialEndsAt` + `renewsAt` (persisted); choosing a paid tier starts a real local 7-day trial (renews a year after it ends) so the trial/active states are live before RevenueCat is wired. **One entitlement** — every paid tier unlocks the identical `pro` flag (unit-tested across tiers).
- **Me tile** now reads "Subscription · Pro" when Pro, plain "Subscription" when Free (closes M3 decision #4).
- **New widget:** `TierCard`. No red, no countdowns, no decoys, no upsell-after-lower-tier anywhere in the flow.
- **Verification:** 265 tests green (canon tier lines, entitlement-identical-across-tiers, trial dates, billing-date format, paywall no-preselect + ₹0 dismissal, 1.3× string-room). Screenshots m7_01 + subscription free/trial/active → `docs/ui_review/`.

### Open decisions surfaced

- #1: ₹1499 pay-it-forward line ships as written — keep only if a real mechanism backs it before launch, else cut.
- #2: trial 7 days, applied per the local stub; confirm length + once-per-account vs per-tier in Play config.
- #3: grace-period copy is spec-only (no live billing yet) — mirror Play's actual grace window when wiring RevenueCat.
- #4: Me tile shows tier presence ("· Pro"), as recommended.
- #5: UPI-mandate strip held until real support data.
