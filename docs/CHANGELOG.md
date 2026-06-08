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
- **Notification scheduling** — needs `flutter_local_notifications` + AndroidManifest (POST_NOTIFICATIONS, boot receiver, exact-alarm) + timezone + OEM battery-whitelist pass; the "Daily reminder" switch persists intent only.
