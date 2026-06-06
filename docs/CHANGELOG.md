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
