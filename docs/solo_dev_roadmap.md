# Sahaj — Solo Dev Roadmap

The complete build plan for a solo Flutter developer with zero budget, day job, and Claude Code assistance.

Reads top-to-bottom in build order. Each phase has goals, deliverables, technical decisions, AI-generation prompts, and Claude Code instructions.

Built for Saurabh Upadhyay. Mumbai, April 2026.

---

## How to use this document

1. Read the whole thing once before opening Flutter.
2. Work phase by phase. Don't skip ahead.
3. For each phase, the section labeled **Claude Code prompt** is a copy-paste-ready instruction you can hand to Claude Code in your IDE. It includes context, constraints, and acceptance criteria.
4. Mark phases done with a `// done YYYY-MM-DD` comment in your repo's CHANGELOG.md.
5. When in doubt, return to the synthesis document. This roadmap implements that brief. It does not replace it.

---

## The stack, locked

These choices are final unless something breaks badly. Don't reopen them.

**Frontend:** Flutter (latest stable, currently 3.27+). You ship Android first. iOS comes Phase 2.

**State management:** Riverpod. You already use it at Bigul. Don't switch to BLoC just because it's trendy.

**Local-first storage:** Drift (SQLite wrapper) for structured data, Hive for key-value, secure_storage for secrets. All user content stays on-device by default. Cloud sync is opt-in.

**Backend (minimal):** Firebase. Auth (anonymous + email), Firestore (sync only), Storage (audio CDN), Crashlytics, Analytics, Remote Config (feature flags + A/B), Cloud Functions only when absolutely necessary.

**Subscriptions:** RevenueCat. Wraps Google Play Billing, handles entitlements, gives you cross-platform readiness for free. You've already done Sprint 0 setup.

**Audio:** just_audio package + audio_session for proper interruption handling. Stream from Firebase Storage with local caching.

**Analytics:** Firebase Analytics + Mixpanel free tier (20M events/month, plenty for indie scale). Mixpanel for funnel analysis, Firebase for everything else.

**Error tracking:** Sentry free tier. 5K errors/month is enough. Crashlytics also catches crashes — Sentry adds non-fatal exception tracking.

**Content management:** Firestore collections + a simple admin web app you build later, OR a Notion-as-CMS pattern using their API. Start with Firestore JSON files; migrate to a proper CMS only if you ship to 5+ regions.

**Design:** Figma + your existing Bigul design tokens adapted. Use Untitled UI free kit as a starting point for components you don't want to build.

**Build/CI:** Codemagic free tier (500 minutes/month) or GitHub Actions. Both work. Codemagic is easier for Flutter.

**Localization:** flutter_localizations + intl. English in v1. Hindi keys ready but unused.

**Repo structure:** Mono-repo. `lib/` for app code, `content/` for source-of-truth content (Markdown files for articles, scripts for audio), `tool/` for Python scripts (content generators, audio pipeline), `docs/` for this roadmap and synthesis.

---

## The technical foundation, designed up-front

Things you'll regret not deciding now.

### Data model (entities and relations)

**User**
- id (UUID), createdAt, persona enum, goals array, baselineScores object
- preferences: discreetMode bool, biometricLock bool, notifications object, language string
- subscription: tier enum (free/pro), priceTier int, expiresAt, source string
- progress: currentWeek int, currentDay int, streakCount int, longestStreak int

**Session** (a single 5-15 min training unit)
- id, type enum (kegel/reverseKegel/breathwork/sensate/education), duration, difficulty
- contentRef (Firestore doc id), prerequisites array
- localizedTitle Map<String, String>, localizedScript Map<String, String>
- audioRef Map<String, String> (per-language audio paths)

**SessionLog** (a record of a session done by a user)
- id, userId, sessionId, startedAt, completedAt, completionPct
- moodBefore array, moodAfter array, perceivedDifficulty enum (easier/same/harder)
- journalNote string optional

**Article**
- id, slug, title, body Markdown, category, tags array, readTimeSec int
- publishedAt, version int, locale string

**Plan** (the 12-week protocol for a user)
- id, userId, generatedAt, persona, goals
- weeks: array of Week objects, each with 7 Day objects, each with 1-2 sessionRefs

**HealthScreen** (the once-per-user red-flag check)
- userId, completedAt, answers object, redFlagsFired array, referralAcknowledged bool

**ProgressMetric** (computed weekly)
- userId, weekNum, pelvicFloorScore double, controlDuration int, holdTimeSec int
- consistency double (0-1, sessions completed / scheduled), moodTrend enum

### Analytics events (define them now, instrument them as you build)

Naming convention: `<area>_<verb>_<object>` — e.g., `onboarding_completed_screen`.

Critical events (instrument from day 1):

- `app_opened` (cold/warm)
- `onboarding_started`, `onboarding_completed_screen` (with screenIndex), `onboarding_completed`, `onboarding_abandoned` (with lastScreen)
- `health_screen_completed`, `health_screen_red_flag_fired` (with flagType), `health_screen_referral_clicked`
- `persona_selected` (with persona)
- `goal_selected` (with goals array)
- `plan_generated` (with persona, goalCount)
- `session_started` (with sessionType, day, week), `session_completed`, `session_abandoned` (with completionPct)
- `mood_checkin_completed` (with moods array)
- `paywall_viewed` (with source), `paywall_tier_selected` (with priceTier), `subscription_started`, `subscription_cancelled`
- `discreet_mode_enabled`, `biometric_lock_enabled`, `data_exported`, `account_deleted`

User properties to set:

- persona, daysActive, currentWeek, hasPro, priceTier, language

### Feature flags (Remote Config keys to define on day 1)

- `health_screen_strict_mode` (bool) — toggles aggressive red-flag triggers
- `pricing_tiers` (json array) — lets you change prices without app update
- `paywall_copy_variant` (string) — for A/B testing
- `content_pack_v` (int) — content version for cache invalidation
- `kill_switch_<feature>` (bool) — emergency disable for any feature

### Privacy and security baseline (non-negotiable)

- Anonymous auth by default (Firebase anonymous → email upgrade if user wants sync)
- Local DB encrypted at rest using SQLCipher (Drift supports this)
- All Firebase rules deny-by-default; users can only read/write their own docs
- App lock: optional biometric, falls back to PIN
- Discreet mode: app icon swap (Android supports this with activity-alias), book-mode UI overlay
- Data export: one tap, generates ZIP of user's JSON + audio session logs, shares via system share sheet
- Account deletion: two taps, hard delete from Firestore within 24h, local DB wiped immediately

### Error tracking and observability

- Sentry: instrument Flutter error handlers, capture non-fatal exceptions
- Crashlytics: native crashes
- Firebase Analytics: user funnels
- Mixpanel: cohort analysis, retention curves
- One custom dashboard in Firebase console showing: DAU, day-1/7/30 retention, free→pro conversion, top abandonment screens

### A/B testing infrastructure (build once, use forever)

Use Firebase Remote Config + custom analytics. For each experiment:

1. Define variant key in Remote Config
2. Read variant on app start, store in user property
3. Branch UI/logic based on variant
4. Tag all relevant events with variant
5. After 14 days minimum, analyze in Mixpanel

Don't run more than 2 experiments simultaneously in v1. Don't A/B test things that don't matter.

### Offline-first architecture

- All content (articles, audio metadata, session definitions) syncs on first launch and caches locally
- Audio files stream-first, cache-on-completion
- Session logs queue locally, sync to Firestore on next connectivity
- App works fully offline after first launch except for: subscription verification (cached for 7 days), cloud sync (optional)

### Internationalization scaffolding

- All user-facing strings in `app_en.arb` from day 1
- Code never has hardcoded strings; always `S.of(context).someKey`
- `app_hi.arb` exists from day 1 with English strings as placeholders, get translated in Phase 2
- Audio asset paths follow `audio/<sessionId>_<locale>.m4a` convention

---

## The AI content pipeline

This is how you generate 30 audio sessions and 80 articles in 60 days of evenings without spending weekends recording.

### Article pipeline (per article: ~25 minutes)

1. **Outline (2 min):** You write a 5-bullet outline. What the user should know after reading.
2. **Draft (5 min):** Feed outline to Claude/ChatGPT with this prompt template:

```
You are writing an article for Sahaj, a sexual wellness training app for men.

Voice: warm older brother who is also a doctor. Confident, never preachy, never fear-driven. Cite research where relevant. Avoid clinical jargon; use plain English. Indian audience but globally readable.

Constraints:
- 350-500 words
- No bullet lists; flowing prose
- Open with a concrete observation, not a definition
- Include one specific "what to do today" by the end
- Never use the words: porn addiction, manhood, broken, ruin, destroy, demon, struggle (overused)
- Cite at least one research finding with author year format

Topic: [INSERT TOPIC]
Outline:
[INSERT YOUR 5 BULLETS]

Write the article now.
```

3. **Edit (15 min):** Read aloud. Cut 20%. Replace any AI-tells (sentences starting with "It's important to note", "In conclusion", excessive use of "delve", "navigate", "journey"). Verify citations are real (Claude/ChatGPT will hallucinate paper titles — check on Google Scholar).
4. **Save:** Markdown file in `content/articles/<slug>.md` with frontmatter (title, category, tags, readTime, sources).

Time budget: 25 min × 80 articles = 33 hours. ~7 weeks of one evening per week.

### Audio session pipeline (per session: ~20 minutes, ₹0)

Test three free TTS options this weekend. Generate the same 30-second script in each, listen with headphones, pick the one you'd actually want to listen to for 12 weeks. Don't theorize — listen.

Options to test:
- **Kokoro TTS** (HuggingFace: hexgrad/Kokoro-TTS) — Apache 2.0, optimized for solo narration, runs locally or via HF space. Best fit for Sahaj's solo-guided format.
- **Edge TTS** (`pip install edge-tts`, no signup) — Microsoft neural voices including `en-IN-PrabhatNeural` for Indian-English accent. Acceptable quality, dead simple.
- **VibeVoice** (HuggingFace: yasserrmd/vibevoice) — Microsoft MIT-licensed, optimized for multi-speaker dialogue. Overkill for solo sessions but bookmark for Phase 2 if you build partner-conversation roleplay content.
- **Your own voice** — fall back option. Phone mic in a closet (clothes absorb echo), Audacity for cleanup. Roughness is honest. Re-record with better gear later if app earns revenue.

Once you pick one, the per-session pipeline:

1. **Script (5 min):** Take an article or write a session script with `[pause Xs]` markers.
2. **Generate audio (5 min):** Run chosen TTS locally or via HF space. Keep voice consistent across all 30 sessions.
3. **Edit (8 min):** Audacity. Trim silences, add gentle intro chime (freesound.org CC0), normalize, export 96kbps M4A.
4. **Upload (2 min):** Firebase Storage with content-type audio/mp4, public read.

Time budget: 20 min × 30 sessions = 10 hours. One weekend or 10 evenings.

**TTS prompt template for scripts:**

```
[Settings: warm, slow pace, gentle authority]

Welcome back. Today we're working on the elevator exercise.
[pause 2s]

Find a comfortable position. Sitting or lying down, both work.
[pause 3s]

We're going to lift the pelvic floor in stages, like an elevator
going up four floors. First floor, gentle squeeze. Hold.
[pause 4s]

Second floor, a little more. Hold.
[pause 4s]

[continue script]
```

### Visual asset pipeline

- **Anatomy diagrams:** Commission once on Fiverr (₹500-1500 per diagram, you'll need 4-6) or use Biorender free tier with editing
- **Animations:** LottieFiles free tier — search "wellness", "meditation", "breath", download JSON, customize colors in After Effects or with online editors
- **Icons:** Lucide (free, MIT license) — already used widely in Flutter
- **Illustrations:** unDraw (free) for empty states, BlushDesign for diverse human illustrations

### Quality bar

Before any content ships:
- Read aloud — does it sound like you would say it?
- Could a 16-year-old understand it? Could a 45-year-old not feel patronized?
- Does it pass the QUITTR test? (Would I hate seeing this in their app? If yes, rewrite.)
- Are citations real? (Google Scholar check)
- Is there one concrete actionable for today?

---

## Phase-by-phase build plan

Each phase has: duration estimate, deliverables, key technical decisions, and a Claude Code prompt template you can paste directly.

### Phase 0 — Project bootstrap (3-4 evenings)

**Deliverables:**
- Flutter project created or Sprint 0 confirmed reusable
- Repo structure as defined above
- Firebase project linked, Crashlytics + Analytics + Remote Config wired
- Sentry SDK installed
- Mixpanel SDK installed
- RevenueCat SDK installed (no products yet)
- Design tokens file created (colors, typography, spacing) with light + dark theme
- App icon + splash configured
- CHANGELOG.md, README.md, this roadmap and synthesis copied to docs/

**Key technical decisions:**
- Package name: `com.saurabh7973.sahaj` (mirrors your Sanatan Guide convention)
- Min SDK: Android 21 (covers 99%+ of Indian Android users)
- Architecture: Feature-first folders, not layer-first. `lib/features/onboarding/`, `lib/features/sessions/`, etc.

**Claude Code prompt:**

```
You are working on Sahaj, a Flutter app for men's sexual wellness training.
Refer to docs/synthesis.md and docs/solo_dev_roadmap.md for product and
technical context.

Phase 0: Project bootstrap.

Tasks:
1. Verify or scaffold Flutter project at this repo root. Package name
   com.saurabh7973.sahaj, min SDK 21, target latest stable.
2. Create folder structure under lib/:
   - core/ (theme, constants, utils, errors)
   - data/ (models, repositories, datasources)
   - features/ (one folder per feature, populated as we build)
   - shared/ (widgets, hooks)
   - app.dart, main.dart
3. Add these dependencies to pubspec.yaml with latest stable versions:
   flutter_riverpod, drift, sqflite, hive, hive_flutter, secure_storage,
   firebase_core, firebase_auth, cloud_firestore, firebase_storage,
   firebase_analytics, firebase_crashlytics, firebase_remote_config,
   sentry_flutter, mixpanel_flutter, purchases_flutter (RevenueCat),
   just_audio, audio_session, go_router, freezed, json_serializable,
   intl, flutter_localizations.
4. Create lib/core/theme/ with app_colors.dart, app_typography.dart,
   app_spacing.dart. Use the design token pattern from Saurabh's Bigul
   work (AppColorsExtension on ThemeData).
5. Wire main.dart to initialize Firebase, Sentry, Mixpanel, then run app.
6. Create docs/CHANGELOG.md.

Acceptance: app runs on Android emulator, shows a placeholder home screen,
no errors in logs, Firebase initialized, theme switches between light/dark.

Do not implement any features yet. Foundation only.
```

### Phase 1 — Design system and shared widgets (4-5 evenings)

**Deliverables:**
- Color palette: warm neutrals + one accent. NOT red, NOT aggressive blue. Soft sand, deep moss, muted ochre, warm cream. Dark mode is default.
- Typography: 1 serif for headlines (calm, classical — recommend Fraunces or Lora), 1 humanist sans for body (Inter or Manrope)
- Components: AppScaffold, AppButton (3 variants), AppCard, AppListTile, AppTextField, AppChip, AppProgressRing, AppMoodSelector, AppAudioPlayer skeleton
- Motion library: `app_motion.dart` with named curves and durations (calm, settle, response)

**Claude Code prompt:**

```
Phase 1: Design system. Refer to docs/synthesis.md principle 5
("Coral-tier visual warmth, not Brainbuddy-tier urgency").

Tasks:
1. In lib/core/theme/app_colors.dart, define a palette:
   - Primary: warm sand #E8DDD0 light / #2A2520 dark
   - Accent: deep moss #4A5D3F light / muted ochre #C9A961 dark
   - Surface, surface variant, on-surface, on-surface variant
   - Semantic: success, warning, error, info — all muted, no pure reds
   Use ColorScheme.fromSeed where helpful, override values that don't fit.

2. In lib/core/theme/app_typography.dart, set up Google Fonts (use
   google_fonts package): Fraunces for displayLarge/Medium/Small,
   Manrope for body, label, title. Generate a TextTheme.

3. In lib/core/theme/app_motion.dart, define:
   - durations: instant 100ms, quick 200ms, settle 400ms, calm 700ms
   - curves: ease-out for entrance, ease-in-out for transitions, no
     bouncy or overshooting curves anywhere

4. In lib/shared/widgets/, create:
   - AppButton (primary, secondary, text variants; loading state; haptic
     feedback on press; min height 48 for accessibility)
   - AppCard (rounded-16, soft shadow, configurable padding)
   - AppScaffold (handles safe areas, optional appBar, optional bottom
     nav, consistent padding)
   - AppMoodSelector (pill-shaped chips, multi-select, animated)
   - AppProgressRing (circular progress, smooth animation, 0-100%)
   - AppTextField (rounded, gentle focus state, error display)
   - AppListTile (for library and settings lists)

5. Create lib/shared/widgets/showcase_screen.dart that renders all
   components on one scrollable screen. Use this for visual review.

Acceptance: showcase_screen visually reviewed, all components feel calm
and consistent, no element uses red or sharp shadows, dark mode looks
intentional not just inverted.

Constraints:
- No bullet shadows, no neon, no glass-morphism
- Border radii: 8 for small (chips, inputs), 16 for cards, 24 for major
  surfaces
- Spacing scale: 4, 8, 12, 16, 24, 32, 48
```

### Phase 2 — Onboarding flow shell (5-7 evenings)

**Deliverables:**
- 12 onboarding screens with navigation (no logic yet, just the flow)
- Persona routing implemented: choices on screen 4 affect downstream questions
- Persona Zero pathway visibly different from partnered pathways
- Progress bar at top of every onboarding screen
- Back navigation that doesn't lose state
- Analytics events fired for each screen view and completion

**Claude Code prompt:**

```
Phase 2: Onboarding flow. Refer to docs/synthesis.md section 6 for the
12 screens, their copy, and the persona routing logic.

CRITICAL: This is the most important flow in the app. The user's first
3 minutes determine whether they trust us. Re-read principle 4
(education before assessment) and principle 6 (Mojo's voice register)
before writing copy.

Tasks:
1. Create lib/features/onboarding/ with:
   - models/ (OnboardingState, Persona enum, Goal enum, etc.)
   - controllers/ (Riverpod notifier for state across screens)
   - screens/ (one file per screen, 12 total)
   - widgets/ (OnboardingScaffold with progress bar, OnboardingFooter
     with primary/secondary buttons)

2. Implement screens 1-12 per synthesis.md section 6. Use placeholder
   copy where the synthesis is vague — match the voice register
   precisely. Save final copy review for after the flow works.

3. Persona routing logic: screen 4 selection determines whether
   subsequent screens show partnered-language or solo-language variants.
   Implement this as a `bool isSolo` in OnboardingState.

4. Health screen (screen 6): one question per sub-screen, calm
   transitions. If any red flag fires, route to screen 7
   (red-flag triage). If not, skip to screen 8.

5. Analytics: fire onboarding_started on screen 1 mount,
   onboarding_completed_screen with screenIndex on each Next press,
   onboarding_abandoned with lastScreen if user backgrounds the app
   without completing, onboarding_completed on screen 12.

6. State persistence: if user kills the app mid-onboarding, they
   resume where they left off. Use Hive for this.

Acceptance:
- Full onboarding can be completed in under 4 minutes
- All 12 screens reachable, no dead ends
- Solo persona path differs visibly from partnered path on screens 5, 8
- Red-flag screen appears only when triggered
- Analytics events visible in Firebase Analytics DebugView

Constraints:
- No fear-driven copy. Re-read synthesis principle 3.
- Maximum 1 question per screen on the health screen
- Progress bar shows segmented progress (12 segments) not percentage
```

### Phase 3 — Plan generation engine (3-4 evenings)

**Deliverables:**
- Rule-based plan generator: input persona + goals + baseline → output 12-week protocol
- Plan stored locally, viewable in Me tab
- Today's session derivable from current week + day + mood

**Claude Code prompt:**

```
Phase 3: Plan generation. Refer to docs/synthesis.md section 7 for
the 12-week core protocol structure.

Tasks:
1. Create lib/features/plan/ with models, generator, repository.

2. Define Plan, Week, Day, SessionRef Freezed models per the data
   model in solo_dev_roadmap.md.

3. Implement PlanGenerator class:
   input: Persona, List<Goal>, BaselineScores
   output: Plan with 12 weeks × 7 days, populated with sessionRefs

   Logic:
   - Week 1-4: foundation (PFMT identification, basic Kegels, intro
     reverse Kegel, breathwork basics, anatomy modules)
   - Week 5-8: integration (combined Kegel sets, stop-start, sensate
     focus, dopamine module)
   - Week 9-12: mastery (advanced PFMT, mental rehearsal, transfer)
   - Persona Zero gets solo-only sessions in week 9-12; partnered
     personas get partnered sessions
   - PE-priority goal weights stop-start higher
   - PIED-priority goal weights dopamine and rewire content higher
   - Anxiety-loop ED weights mindset and breathwork higher

4. Store Plan in Drift DB. Implement PlanRepository with methods:
   getCurrentPlan, getTodaysSession, advanceDay, regeneratePlan.

5. Create a debug screen at lib/features/debug/plan_debug_screen.dart
   that shows the full 12-week plan as a scrollable list, for QA.

Acceptance:
- Generating a plan for each of personas 0-3 produces visibly
  different protocols
- Plan is deterministic: same inputs → same plan
- Debug screen renders all 84 days clearly
- Plan persists across app restart

Don't write content yet. SessionRefs point to IDs that don't exist;
Phase 4 will fill them.
```

### Phase 4 — Session player and content sync (5-7 evenings)

**Deliverables:**
- Audio session player with proper controls, lock-screen integration, interruption handling
- Content sync from Firestore: session definitions, article texts, audio URLs
- Local cache of all metadata, lazy-load audio
- Mood check-in flow before session
- Post-session reflection capture
- SessionLog persisted

**Claude Code prompt:**

```
Phase 4: Session player and content sync. Refer to data model in
solo_dev_roadmap.md.

Tasks:
1. Create lib/features/sessions/ with player, controllers, screens.

2. Set up content sync:
   - Firestore collection `sessions` with Session documents
   - Firestore collection `articles` with Article documents
   - On app start, sync these collections to local Drift DB if
     content_pack_v in Remote Config is newer than local
   - Audio files stay in Firebase Storage, streamed via just_audio,
     cached locally after first play

3. Build SessionPlayerScreen:
   - Large play/pause control
   - Progress bar with elapsed/remaining
   - Title and current step indicator (e.g., "Step 2 of 4: Body scan")
   - Background gradient that subtly shifts with progress
   - Skip-30-sec, back-15-sec
   - Auto-advance to reflection screen on completion
   - Handles audio interruptions (calls, other media) gracefully
   - Lock-screen controls via audio_service package

4. Pre-session mood check-in: AppMoodSelector on a sheet, multi-select
   1-3 moods from a fixed list (anxious, hopeful, restless,
   disappointed, calm, distracted, motivated, low). Stored in
   SessionLog.moodBefore.

5. Post-session reflection: 3 taps max — "How did that feel?"
   (easier/same/harder), optional journal note (text field, blurs by
   default for privacy), tomorrow preview.

6. Persist SessionLog with all fields.

7. Analytics: session_started, session_completed, session_abandoned,
   mood_checkin_completed.

Acceptance:
- Plays a real audio file from Firebase Storage end-to-end
- Pause/resume works, skip works, lock-screen controls work
- Phone call interrupts → resumes after call ends
- SessionLog persisted to local DB and synced to Firestore (when
  online)
- Mood data appears in user properties

Constraints:
- No social-share buttons in the player
- No comparison to "average user" anywhere — we don't shame on speed
- If user abandons mid-session, no notification or guilt; just store
  the partial completion
```

### Phase 5 — Home, Library, Me tabs (5-6 evenings)

**Deliverables:**
- Bottom nav with three tabs
- Today tab with greeting, current week status, today's session card, mood entry, optional streak
- Library tab with browseable exercises, breathwork, articles, education modules
- Me tab with progress dashboard, settings, subscription view, about

**Claude Code prompt:**

```
Phase 5: Main navigation and tab content. Refer to synthesis.md
section 6 for tab layouts.

Tasks:
1. Create lib/features/home/, lib/features/library/, lib/features/me/.

2. Implement bottom nav with go_router. Three destinations: Today,
   Library, Me. Each tab maintains its own navigation stack.

3. Today screen:
   - Greeting based on time of day and user.firstName (collected during
     onboarding, optional)
   - Current week status card ("Week 3 of 12: building strength")
   - Today's session card: large CTA "Get today's session" → opens
     mood check-in → routes to player
   - This week consistency indicator (5 dots, filled per session done)
   - Streak (collapsed by default, expandable, can be hidden in
     settings per principle 8 "agency over shame")
   - Quick-access tiles: 90-second breathwork, reverse Kegel reminder

4. Library screen:
   - Tab strip: Exercises, Breathwork, Education
   - Exercises tab: filterable list of all PFMT/reverse Kegel sessions
     with duration, difficulty
   - Breathwork tab: list of breathwork audios
   - Education tab: scrollable list of articles with category chips
   - Search at top

5. Me screen:
   - Progress dashboard: 4 metric cards (pelvic floor strength score,
     reverse Kegel hold time, weekly consistency, control duration)
     each as a sparkline + current value
   - Settings link → SettingsScreen with: discreet mode, biometric
     lock, notifications, language, data export, delete account
   - Subscription card: shows current tier, CTA to upgrade or manage
   - About link → AboutScreen with app version, science citations,
     contact

6. Settings → discreet mode flow:
   - Toggle to enable
   - Choose disguise: rename app icon to "Calendar" / "Notes" / "Wellness"
   - Book Mode toggle: when on, app UI shows as a reading interface
     with the actual content as collapsible sections
   - Biometric lock toggle

Acceptance:
- Can navigate between all three tabs without state loss
- Today's session is correctly derived from plan + current day
- Discreet mode actually changes the icon and works through a launcher
  test
- Progress dashboard shows real data after a few sessions
- Search in library returns relevant results

Constraints:
- Streak module is collapsible, never the largest element on screen
- Progress metrics show "no data yet" gracefully when user has fewer
  than 7 days of history
- All metric tooltips explain what they mean (no jargon)
```

### Phase 6 — Subscription and pricing (3-4 evenings)

**Deliverables:**
- RevenueCat products configured: 4 pro tiers (₹0, ₹499, ₹999, ₹1499) all annual
- Pay-what-you-can paywall mirroring Mojo's pattern
- Free vs Pro feature gating (gentle, never aggressive)
- Subscription management screen
- Receipt validation and entitlement caching

**Claude Code prompt:**

```
Phase 6: Subscription. Refer to synthesis.md section 8 for the pricing
model and principle 7 (Indian price honesty).

Tasks:
1. RevenueCat dashboard: create entitlement "pro", create 4 products
   (sahaj_pro_0, sahaj_pro_499, sahaj_pro_999, sahaj_pro_1499) all
   annual subscriptions, all attached to "pro" entitlement.

2. Implement lib/features/subscription/:
   - SubscriptionRepository wrapping RevenueCat SDK
   - PricingTier enum
   - PaywallScreen mirroring Mojo's pay-what-you-can layout:
     * Header: "Pro unlocks the full 12-week protocol"
     * Subhead with Mojo-style framing about money not getting in the
       way
     * 4 tier cards stacked vertically, each tappable
     * "₹999 is the standard" label on the recommended tier
     * "₹0 — for users who genuinely cannot afford" subtitle on free
     * "Supporter — helps fund the ₹0 tier" on highest
     * Single CTA: "Continue with ₹X / year"
     * Tiny print: cancel anytime in Google Play, refund window per
       Play policy

3. Feature gating (from synthesis.md section 8):
   - Free tier: full PFM identification, 8 basic Kegels, 4 reverse
     Kegels, 1 breathwork, 3 articles, mood check-in, basic progress,
     discreet mode
   - Pro: full 12-week protocol, all sessions, all articles, detailed
     progress, partner mode (Phase 2)

4. Gating UI:
   - Locked content shows a small lock icon + one-line explanation
   - Tap → soft paywall (NOT a hard block; user can browse upgrade
     options without being trapped)
   - "Maybe later" always available

5. Subscription management screen:
   - Current tier and renewal date
   - "Manage in Google Play" button (opens Play subscription page)
   - "Pause subscription" option if RevenueCat allows
   - Why-pay copy that re-states value, not fear

6. Analytics: paywall_viewed (with source), paywall_tier_selected,
   subscription_started, subscription_cancelled.

Acceptance:
- All 4 tiers selectable and process correctly via Google Play test
  account
- ₹0 tier doesn't trigger Play purchase but does grant entitlement
- Locked content behavior matches "soft paywall" — user never feels
  trapped
- Cancellation flow works and feature access expires correctly

Constraints:
- NO countdown timers anywhere
- NO "discount on cancel" dark patterns
- NO "1 day left" notifications
- NEVER hide the X / close button on paywalls
- NEVER use red on the paywall
```

### Phase 7 — Privacy, security, data control (3-4 evenings)

**Deliverables:**
- Biometric lock fully working
- Data export feature (one tap → ZIP file)
- Account deletion flow (immediate local wipe + Firestore deletion within 24h via Cloud Function)
- Privacy policy and terms accessible
- Discreet mode with icon swap and book mode

**Claude Code prompt:**

```
Phase 7: Privacy and security. Refer to synthesis.md principles 5,
8, 9 (warmth, agency, ultra-discreet).

Tasks:
1. Biometric lock:
   - Use local_auth package
   - Trigger on app foreground if enabled
   - Falls back to PIN if biometric not available
   - Store PIN hashed in secure_storage
   - Setting to disable, requires current biometric/PIN to disable

2. Discreet mode — icon swap:
   - Configure activity-alias entries in AndroidManifest.xml for 3
     disguises (Calendar, Notes, Wellness Tracker — use generic icons)
   - Implement IconChanger service that enables/disables aliases via
     PackageManager
   - Settings UI to switch

3. Discreet mode — book mode:
   - Alternate UI theme that renders all screens as a reading
     interface: serif font, paper texture, content as chapters
   - Toggle in settings, persists
   - All actual functionality still accessible, just visually
     disguised

4. Data export:
   - Generate JSON of all user data (profile, plan, session logs,
     metrics, journal notes)
   - Include audio session log timestamps but not the audio files
   - ZIP and share via system share sheet
   - Show export size before share

5. Account deletion:
   - 2-tap confirm flow with clear "this is permanent" message
   - Local DB wipe immediately, no waiting
   - Schedule Firestore delete via Cloud Function (deferred OK, must
     complete within 24h per Play policy)
   - Sign out and return to onboarding screen 1
   - No "are you sure" guilt-tripping; user wants to leave, let them

6. Privacy policy and terms:
   - Static markdown files in assets/legal/
   - Rendered with flutter_markdown
   - Linked from onboarding screen 2 and Settings → About

Acceptance:
- App locks behind biometric on foreground when enabled
- Icon swap actually changes the launcher icon (test on real device,
  not emulator)
- Book mode renders correctly across all major screens
- Data export produces a valid ZIP that opens
- Account deletion wipes local DB and the user can immediately
  re-onboard fresh

Constraints:
- Never claim "100% private" or "your data never leaves your device"
  if it isn't true. Be precise.
- Privacy policy must list every third-party SDK (Firebase, Sentry,
  Mixpanel, RevenueCat) and what data each receives
```

### Phase 8 — Health screen review and content QA (2 weeks calendar, ~10-15 evenings of work)

**Deliverables:**
- Practo (or similar) doctor consultation completed
- Health screening logic adjusted per doctor feedback
- All v1 articles written and reviewed
- All v1 audio sessions recorded and uploaded
- Internal QA pass on all flows

**Claude Code prompt:**

```
Phase 8 is mostly content and external review. Limited Claude Code work.

Tasks (mostly manual):
1. Book Practo online consultation with a General Physician or
   Endocrinologist. Send them a PDF of:
   - The current health screen questions and red-flag thresholds
   - The referral language used when red flags fire
   - Ask: "Is this conservative enough? Anything missing that should
     refer to a doctor?"
   Budget: ₹500-1500. Iterate the screening once.

2. Generate v1 content per the AI content pipeline in this roadmap:
   - 80 articles in content/articles/*.md
   - 30 audio scripts in content/audio_scripts/*.md
   - Run scripts through ElevenLabs, edit in Audacity, upload to
     Firebase Storage

3. Internal QA: use the app daily for 2 weeks as Persona Zero.
   Note every friction in docs/qa_notes.md.

Claude Code tasks (small):
1. Update lib/features/onboarding/health_screen logic per doctor
   feedback.
2. Add citations field to Article model and display source links at
   bottom of each article.
3. Build a content seeder script in tool/seed_content.dart that
   reads content/articles/*.md and content/audio_metadata.json,
   uploads to Firestore.

Acceptance:
- Doctor sign-off documented in docs/clinical_review.md
- All 80 articles in Firestore, all 30 audio sessions uploaded and
  playable
- 2-week self-test complete with documented improvements to v2
```

### Phase 9 — Beta launch (1 week calendar)

**Deliverables:**
- Closed beta on Play Store internal testing track
- 10-20 beta users recruited
- Feedback channel set up (in-app survey + optional Discord/Telegram for active users)
- First retention metrics collected

**Claude Code prompt:**

```
Phase 9: Beta launch.

Tasks:
1. Build app in release mode, sign with the keystore at
   android/app/sahaj-release.jks (create if not exists, store
   credentials in secure place — DO NOT commit).

2. Generate AAB. Upload to Play Console internal testing track.

3. Recruit 10-20 beta testers:
   - Reddit posts in r/IndianTeenagers, r/India (carefully — read
     subreddit rules), r/NoFap (delicate but the audience matches),
     r/PelvicFloor
   - Twitter/X — your indie dev network
   - Personal network — DM trusted friends only

4. In-app feedback widget on Today screen: "How is Sahaj working for
   you? [Tap to share]" → opens a short form (3 questions max).

5. Set up basic Mixpanel funnel dashboards:
   - Onboarding funnel (screen 1 → screen 12 → first session)
   - Free → Pro funnel
   - 7-day retention curve
   - Top abandonment screens

Acceptance:
- App installs cleanly from internal testing link on real devices
- 10+ users have completed onboarding
- 5+ users have done at least 3 sessions
- First feedback received and triaged
```

### Phase 10 and beyond — Post-beta backlog (ongoing)

Things to defer to post-beta:

- Hindi audio + UI localization
- Couple mode with free partner premium
- Community feature (anonymous, moderated)
- iOS build
- Apple Health / Google Fit integration
- Web landing page for marketing
- ASO (App Store Optimization) iterations
- Content additions based on most-requested topics

---

## Skills to register with Claude Code

You mentioned Claude Code can use skills. Here are the ones that will help most for this project:

**Already public skills you can use:**
- `frontend-design` — for UI work, design tokens, component patterns
- `docx` — if you ever need to generate documents (clinician brief, investor deck later)

**Custom skills to create for Sahaj specifically:**

1. **sahaj-voice** — a skill that captures the voice register for all copy. The skill instructs Claude to write in the "warm older brother who is also a doctor" tone, never use banned words, always cite research, etc. Use this for every article generation and every UI string review.

2. **sahaj-content-pipeline** — a skill that handles the article-to-script-to-audio pipeline. Takes a topic, produces an article and a session script with proper pause markers and ElevenLabs settings.

3. **sahaj-health-screen** — a skill that reviews any change to the health screening logic against the conservative-screening principle. Catches accidental relaxations of red-flag triggers.

4. **sahaj-anti-pattern-check** — a skill that reviews any new screen, copy, or feature against the 12 principles. Catches "would QUITTR do this?" violations before they ship.

You can create these as folder-based skills in your repo at `.claude/skills/<name>/SKILL.md`. Each is a markdown file with the trigger conditions and instructions.

---

## What this roadmap commits to

By the end of Phase 9 (about 90-100 evenings of work, spread over 4-5 calendar months given your day job), you will have:

- A production Flutter app with full onboarding, plan generation, daily sessions, library, settings, subscription
- 80 articles, 30 audio sessions, all your own work via free AI pipeline
- Privacy and discreet mode functioning
- Doctor-reviewed health screening
- 10-20 beta users with first retention data
- Total cash spend: ₹0 to closed beta (Play Console already done), ₹500-1500 to public launch (one Practo doctor consult)
- Total time: ~90-100 evenings (10-15 hours/week × 16-20 weeks)

This is the most ambitious solo build for the most underserved audience in Indian sexual wellness, shipping for effectively zero cash. The principles, the foundation, the content pipeline, and the build sequence are all here.

Open Flutter. Start Phase 0.
