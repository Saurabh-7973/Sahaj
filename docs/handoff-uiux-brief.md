# Sahaj — Full Project Brief for UI/UX Generation

> Paste this whole document into Claude (web). Goal: generate a complete UI/UX
> design for every screen listed in §6 — visual direction, layout, component
> specs, copy polish — within the constraints in §3–§5. Everything in this app
> is functionally built; nothing is visually designed beyond a token system.
> Treat every screen as "works, but looks like a default Material app."

---

## 1. What Sahaj is

**Sahaj (सहज)** — Sanskrit: "in one's natural state, with ease." A daily
training app for men who want to fix or improve sexual function through
evidence-based pelvic-floor exercise (Kegel/reverse-Kegel), breathwork, and
mindset work. 12-week guided protocol, 5–15 min/day. Flutter, Android-only,
India-first, solo developer, ₹0 budget.

**One sentence:** every day the app gives the user one specific 5–15 minute
session calibrated to his stage, mood, and yesterday — and tracks pelvic-floor
strength, arousal control, and consistency until function returns.

**What it is NOT:** not a pill, not a doctor, not a therapist, not a porn
filter, not a streak-shame engine, not a forum, not a content library you
browse aimlessly.

**Tagline:** "Sahaj — train steady."

## 2. The user

- Indian men, 20s–40s. Issues: premature ejaculation, erection difficulty,
  porn-related desensitisation, first-time anxiety.
- **Persona Zero (the wedge):** men with NO current partner — solo trainees.
  No competitor serves them. Many have never been sexually active; they train
  for readiness, not repair.
- Joint-family reality: shared/visible phones. Discretion is not a feature,
  it's survival. (Book Mode disguise, biometric lock, neutral name.)
- Shame is the enemy. The app is on the user's side, always.

## 3. The twelve principles (North Star — every design decision obeys these)

1. **Health screening before selling** — red flags → doctor referral before training.
2. **Free tier that actually works** — free forever, no trial clock.
3. **No fear-driven copy. Ever.** No countdowns, doom-dates, ruined-life imagery, "porn destroys…" lines. If it could appear in QUITTR's onboarding, it doesn't appear here.
4. **Education before assessment** — user feels smarter five screens in, not more diagnosed.
5. **Coral-tier visual warmth** — calm palette, soft motion, **no red, no urgency**. Looks like a wellness app, not an intervention.
6. **Mojo's voice register** — confident in what we do, honest about what we don't, citation-backed, no fear.
7. **Indian price honesty** — sliding scale ₹0/499/999/1499, "pick what's reasonable for you," no dark patterns.
8. **Agency over shame** — streaks optional + hideable, resets blameless.
9. **Ultra-discreet mode non-negotiable** — disguise icon/name, Book Mode, biometric lock, in v1.
10. **Mood-based daily prescription** — pick 1–3 feelings → one session. No infinite menu.
11. **Free partner premium** (Phase 2 couple mode) — one sub, two accounts.
12. **Progress visualization is the conversion lever** — real metrics, honestly presented, is what makes free users pay.

## 4. Design system AS BUILT (the starting point — extend, don't fight it)

- **Tokens** (`lib/core/theme/`): warm sand / moss / ochre palette, **dark
  theme default**, no pure red anywhere. Spacing 4/8/12/16/24/32/48. Radius
  8/16/24. Motion: 100/200/400/700ms, gentle curves, no overshoot.
- **Type:** Fraunces (display) + Manrope (body). Material 3.
- **Widgets** (`lib/shared/widgets/`): AppButton (filled/outlined/text),
  AppCard, AppScaffold, AppTextField, AppListTile, AppChip, AppMoodSelector
  (5-point emoji, animated), AppProgressRing (animated, center slot).
- Convention: every screen composes these; no raw Material widgets.
- **What's missing (your job):** actual visual identity per screen — hierarchy,
  illustration/iconography direction, empty states, celebratory moments,
  anatomy-diagram art direction, the emotional arc of onboarding, app icon,
  notification icon exists (white lotus).

## 5. Hard constraints for the design

- Android-only v1, Flutter Material 3. Dark default; light theme exists.
- No red, no urgency, no fear. Calm ≠ boring: warmth, breath, space.
- Discreet from the launcher inward: nothing explicit on any screen a
  shoulder-surfer might see; session titles in lock-screen notifications are
  neutral ("Calm breathing").
- Free tier must feel whole, never crippled. Paywall is soft: dismissible
  always ("X" + "Maybe later"), ₹999 recommended, no countdown.
- One developer implements this in Flutter — favor systematic components over
  bespoke one-off layouts.
- English v1 (Hindi planned Phase 2 — leave room for longer strings).

## 6. COMPLETE screen inventory (design every one)

### Onboarding flow (12 screens, ~3–4 min, sequential)
| # | Screen | Content (built) |
|---|--------|-----------------|
| 1 | Welcome | One sentence promise + Begin CTA |
| 2 | The promise | "3 minutes, no payment until you decide, data stays on phone" |
| 3 | Education | 3 story-format slides: what pelvic floor is, where, what it does. NEEDS anatomy illustration direction |
| 4 | Persona routing | "Which describes you right now?" 5 options (the Persona Zero gateway) |
| 5 | Goals | Multi-select, 6 options ("I finish too quickly" … "I'm exploring") |
| 6 | Health screen | 9 single-question screens, one Q per screen, calm framing (morning erections, pain, thirst, weight loss, chest pain, tremors, prescriptions, mood PHQ-2/GAD-2) |
| 7 | Red-flag triage | Conditional: "see a doctor first" referral, can still use free tier |
| 7b | Crisis screen | Conditional (self-harm answer): India crisis lines (Tele-MANAS 14416, iCall, AASRA), tap-to-dial. Highest-care screen in the app |
| 8 | Function baseline | Persona-calibrated question battery (PEDT/IIEF-5-adapted or solo battery) |
| 9 | Mind/body baseline | 5 Qs: stress, sleep, exercise, alcohol, porn frequency |
| 10 | Plan reveal | "Your 12-week plan": weekly structure, daily commitment, milestones at 4/8/12 weeks. THE conversion moment of onboarding |
| 11 | Privacy setup | Book Mode toggle, disguise name, biometric lock enable |
| 12 | First session ready | "7 minutes. No payment, no signup wall." Start now / later |

### Main app (3 tabs)
- **Today tab** — greeting + week banner ("Week 3 of 12"), today's session
  card, mood check-in trigger, streak (hideable), this-week dots. Empty/done
  states exist.
- **Library tab** — "Read" section (6 articles) + all 54 practice sessions
  grouped by type (kegel, reverse-kegel, breathwork, sensate, education,
  mindset) with duration. Free practice anytime. Locked items (Pro) need a
  lock treatment.
- **Me tab** — progress dashboard (honest metrics from real logs: sessions
  done, streak, longest, weekly consistency), Privacy tile → Settings,
  subscription tile, about.

### Session loop (the heart — used daily)
- **Mood check-in sheet** — bottom sheet, pick 1–3 of 5 emoji moods.
- **Session player** — step title, big countdown ring (AppProgressRing),
  guidance text, prev/pause/next. NOW ALSO: audio sessions (voice guidance
  plays under the stepper — same controls). This screen is used 84+ times per
  user; it must be beautiful and calm.
- **Reflection page** — easier/same/harder + optional journal note.
- **Completion moment** — currently unstyled; design the "done for today"
  feeling (principle 8: warm, never gamified-manic).

### Reading
- **Article reader** — markdown body. Needs reading-experience design
  (typography scale, sources block, "doctor-reviewed" badge states).

### Settings & privacy
- **Settings page** — sections: Book Mode toggle + disguise name picker,
  biometric lock, daily reminder (time picker), hide streak, data export,
  delete everything (the one destructive action — confirm pattern needed).
- **Book Mode cover** — the disguise screen shown on launch when enabled
  (currently minimal; must read as a boring generic book/notes app to a
  shoulder-surfer; double-tap reveals real app).
- **Biometric gate** — lock screen w/ PIN fallback.

### Monetisation
- **Paywall screen** — 4 tier cards ₹0/499/999/1499, ₹999 "Recommended",
  single CTA, X + "Maybe later" always visible, honest tiny-print.
- **Subscription page** — current tier, manage-in-Play, restore.

### System
- **App icon** — undesigned. Must be neutral/discreet (lotus motif exists in
  notification icon). Plus the disguise alias icon (calculator/notes/etc.).
- **Notifications** — daily reminder copy (calm, neutral, no app-purpose leak).

## 7. Current content state

- **Sessions:** 54 modules (all authored, in-voice, no health claims), week-rotating variants, goal-personalised plan (Weeks 5–12 adapt to user goals).
- **Articles:** 6 — #1 (pelvic floor & erection control) verified+sourced, 5 placeholders being replaced by a researched batch; all health content doctor-gated before launch.
- **Audio:** engine built (just_audio behind seam). Voice picked: Edge TTS `en-US-AndrewMultilingualNeural` (free, warm). One demo session wired. Full catalog generation pending hosting decision (Firebase Storage now needs billing → likely bundle Foundation weeks only).
- **12-week protocol:** Foundation (wk 1–4: anatomy, identify, intro reverse-kegel, breathwork) → Integration (5–8: combined work, stop-start, sensate, mindset) → Mastery (9–12: functional PFMT, mental rehearsal, readiness/communication).

## 8. Tech/build state (so designs land in reality)

Everything below is implemented and tested (122 tests, debug APK builds):
onboarding+logic+triage+crisis, plan engine, scheduler, session player
(text+timer+audio), progress/streak persistence (Hive, local-only), library,
articles, settings/privacy (Book Mode, biometric, export, wipe), exact-alarm
daily reminders (device-verified), Firebase Analytics+Crashlytics, soft
paywall + subscription seam (RevenueCat key pending), release signing.
NO cloud sync (deliberately — local-first privacy). Decisions: Mixpanel/Sentry
cut (free-only rule).

## 9. Master TODO — everything left, by owner

### UI/UX (this brief's purpose — user + Claude web)
- [ ] Visual identity: art direction, illustration style (esp. anatomy slides), app icon, disguise icon
- [ ] Every screen in §6 designed (incl. empty/done/locked/error states)
- [ ] Onboarding emotional arc (warmth curve from welcome → plan reveal)
- [ ] Session player redesign (daily-use screen, audio + text modes)
- [ ] Completion/celebration moments (calm, not confetti-manic)
- [ ] Book Mode cover that genuinely passes a glance test
- [ ] Paywall that converts without pressure (principle 7)
- [ ] Progress dashboard design — THE conversion lever (principle 12): how to visualise strength score, control duration, consistency honestly

### Code (Claude in IDE — after designs exist)
- [ ] Implement the UI/UX pass screen by screen
- [ ] Book Mode launcher disguise (activity-alias icon/name swap) — waits on disguise identity pick
- [ ] Catalog audio generation pipeline (script ready to build; voice picked; hosting decision needed: bundle Foundation-only ≈ +5MB vs all 54 ≈ +27MB)
- [ ] RevenueCat impl + Play products (when user uploads AAB)

### User (Saurabh)
- [ ] Ear-check the picked voice (30 sec: `open tool/auditions/`)
- [ ] Article batch: 7 topics through Claude web → hand over for seeding
- [ ] Doctor sign-off on all health articles (gate before Play)
- [ ] Play Console: keystore passwords, AAB upload, 3 subscription products
- [ ] Disguise identity decision (name + icon)
- [ ] Device pass on real device after UI implementation

### External / later
- [ ] Hindi (Phase 2), couple mode (Phase 2), cloud sync (post-beta)

## 10. Research corpus (what exists + new direction)

**Existing research (in-repo, drives everything above):**
- `docs/synthesis.md` — full product thesis, competitor audit distilled into the 12 principles. Competitors studied: **Mojo** (voice register, health intake), **Coral** (visual warmth, mood-based prescription), **QUITTR** (the anti-pattern: fear copy, shame mechanics — we are its opposite), **Kegel Trainer PFEI** (discreet mode patterns).
- `docs/solo_dev_roadmap.md` — build/content/audio pipelines, TTS plan, validation plan.
- Clinical grounding: PFMT evidence for ED/PE, stop-start technique, PEDT/IIEF-5 instruments, PHQ-2/GAD-2 screens — all referenced in synthesis; health content additionally doctor-gated.

**NEW research direction — sacred-texts.com (user's idea, promising):**
The Internet Sacred Text Archive hosts public-domain Indian erotology and
tantra: **Kama Sutra** (Burton translation), **Ananga Ranga**, **The Perfumed
Garden**, tantric texts. Why it fits Sahaj:
- **Cultural moat**: Sahaj's name is Sanskrit; grounding content in Indian
  textual tradition (vs. importing Western sexology framing) deepens the brand
  and disarms shame — "your culture has treated this as knowledge for
  millennia" is a powerful anti-shame frame (principle 8).
- Potential uses: article series ("what the Ananga Ranga actually says about
  pacing"), session framing/quotes, education modules connecting breath
  practices to their roots.
- **Cautions**: Victorian translations are dated and orientalist in places —
  quote selectively, modernise framing; no health claims sourced from scripture
  (doctor-gate stays); keep it cultural heritage, not religious instruction
  (synthesis: "culturally resonant without being religious"); public domain =
  free, fits ₹0 budget.
- Ask: when generating UI/UX, consider a visual nod to this lineage
  (manuscript warmth, not temple kitsch).

## 11. What to produce (the ask to Claude web)

For each screen in §6: layout, visual hierarchy, component specs (mapped to
the §4 widget system where possible), copy refinements in the §3 voice, and
state variations. Plus: overall art direction, app icon + disguise icon
concepts, illustration direction for the education slides, and the progress
dashboard visualisation. Flag anywhere a design decision conflicts with a
principle in §3 instead of silently breaking it.
