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
