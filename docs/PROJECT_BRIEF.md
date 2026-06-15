# Sahaj — Project Brief (paste into a fresh chat)

> Self-contained context for discussing Sahaj in a new Claude conversation.
> Authoritative status detail lives in `docs/RELEASE_HANDOFF.md` and
> `docs/CHANGELOG.md` in the repo. Last updated: 2026-06-14.

---

## What Sahaj is

**Sahaj** (सहज, "natural / at ease") is a men's sexual wellness *training* app.

- **Platform:** Flutter, Android-only. Package `com.saurabh7973.sahaj`.
- **Team:** solo developer (Saurabh). Budget ₹0 — free/open services only.
- **Repo:** github.com/Saurabh-7973/Sahaj (public; Firebase config committed —
  non-secret by design). All work merged to `main`, no long-lived branches.
- **Workflow:** brainstorm → spec → plan → execution, TDD on pure logic.
  Saurabh owns UI/UX design; Claude writes all the code.

### The wedge — Persona Zero
Men with **no current partner** (solo trainees). No competitor serves them — the
category assumes a couple. This is the entry wedge; partnered users are also
supported, but Persona Zero is the differentiator.

### Core ethic (non-negotiable)
- Health > performance. Agency > shame.
- **No fear-driven copy, ever. No pure red** in the UI.
- Ultra-discreet mode is mandatory (India joint-family reality): "Book Mode"
  disguises the app as a plain notes app, plus a real launcher icon/label swap.
- Free tier works **forever** — no trial countdown clock.
- Pay-what-you-can pricing: ₹0 / ₹499 / ₹999 / ₹1499 (₹0 = local grant, not a
  Play SKU).

### What the app does (end-to-end, all built)
Onboarding (12 screens, incl. self-harm crisis interrupt with India helplines +
conservative red-flag triage) → persona routing → rule-based 12-week plan →
daily session loop (mood check-in → text+timer player, optional audio →
reflection log) → honest progress dashboard → check-ins → content library
(sessions + doctor-gated evidence articles + heritage pieces) → privacy
(biometric/PIN gate, Book Mode disguise, data export, wipe-all) → soft paywall →
daily reminder notifications (exact-alarm, OEM-reliable).

---

## Build state

**UI build complete: design modules M1–M8 shipped. 276 tests green,
`flutter analyze` clean, Kotlin compiles, Android resources + manifest merge
clean.** The app runs the full loop end to end.

Stack notes: Hive for persistence (JSON map, no Drift). go_router 3-tab
`StatefulShellRoute`. Provider/ChangeNotifier. Firebase Analytics + Crashlytics
(ride committed config, no key). Audio engine built (just_audio, M4A, Firebase
Storage) but content is still text+timer until voiced audio is recorded.

**Paid services are OFF** (₹0 budget): Sentry + Mixpanel stubbed in `main.dart`.
Telemetry = Firebase only.

---

## What's left (5 lanes)

### 1. Code — one task
- `PlatformSubscriptionRepository` against RevenueCat. The seam exists
  (`NoopSubscriptionRepository` wired today, real local 7-day trial stands in).
  Blocked on a RevenueCat API key. Launcher disguise swap is **done**.

### 2. Product decisions — 16 awaiting Saurabh's call
All implemented with sensible flagged defaults; none block the build. The
weighty ones:
- **#10** ₹1499 "pay-it-forward" line — keep or cut (no real mechanism behind it yet).
- **#8** PIN length + lockout policy — currently 4 digits, no lockout.
- **#14** disguise alias label — currently "My Notes"; check OEM collision.
- **#1** mood→calibration deltas for `low`/`open` moods.
- **#2** gap-return threshold (missed days → "plan adjusted"), default 3.
- **#5** personalized plan-reveal line tone.
(Full table with in-code defaults + file to change: `RELEASE_HANDOFF.md` §A.)

### 3. Device verification — needs a real phone (MIUI / ColorOS / OneUI)
Surface audit (zero purpose-words on every OS surface, both identities),
launcher swap timing + recents thumbnail + adaptive-icon masks, heads-up never
fires, media-notification behavior, haptics distinguishable through a mattress,
biometric/PIN gate on real enrollment, exact-alarm fires on the minute.
(Checklist: `RELEASE_HANDOFF.md` §B.)

### 4. External / content (not code)
- **Doctor sign-off** on all evidence articles — *hard gate before Play.*
  Articles render an honest "Review pending" badge until then.
- Heritage seeding: verified public-domain excerpts, era tags, zero
  claim-bearing sentences.
- Citation "what it showed" lines verified against each real paper.
- TTS voice ear-check (en-US-AndrewMultilingualNeural picked; hosting TBD).

### 5. Play Console / release
Keystore + signed AAB. Four subscription products at tier prices + ₹0 local
grant + 7-day trial (ids match `pricing_tier.dart`: `sahaj_pro_499/999/1499`).
RevenueCat key → wire the repository. Internal testing pass (10+ onboard, 5+
complete 3 sessions).

---

## How to help in this chat
Good lanes for a web chat (no code execution needed): the 16 product decisions,
content authorship (session scripts — no health claims; article copy is
doctor-gated), pricing/paywall copy, store listing, launch sequencing, tone
review. For anything touching code or the repo, that runs in Claude Code on the
dev machine.
