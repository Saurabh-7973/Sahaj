# Sahaj — Claude Code Handoff (complete)

**Read this first.** This package contains all the content, copy, specs, safety material, and the full evidence-article series produced for Sahaj's content/UX-finishing phase, ready to implement and seed. The app's UI/architecture is already built; this finishes and fills it for a closed-testing release.

---

## Project context (1 paragraph)
Sahaj is a men's pelvic-floor & sexual-wellness *training* app (Flutter, Android, package `com.saurabh7973.sahaj`). Core ethic: health before performance, agency over shame, **no fear-based copy, no pure red in the UI**, honesty-first, discreet by design (Book Mode). Wedge persona is "Persona Zero" — men with no current partner. The app runs a rule-based 12-week program (daily ~10-min session: settle → core work → down-regulate → reflection), with onboarding, a health screen, a paywall after a free 4-week Foundation, a privacy gate, and a content library. Stack: Hive persistence, go_router `StatefulShellRoute`, Provider/ChangeNotifier, Firebase Analytics + Crashlytics (paid trackers off).

---

## What's in this package

```
sahaj_handoff/
├── README_HANDOFF.md              ← you are here
├── session_scripts/
│   ├── session_scripts_ALL.md     ← PRIMARY: all 12 weeks, one file, seed from this
│   └── by_week/week_01.md … week_12.md
├── content/
│   ├── onboarding_copy.md         ← 12-screen onboarding (incl. crisis interrupt)
│   ├── pricing_paywall_copy.md    ← soft paywall + ₹0 grant + consultation copy
│   ├── store_listing.md           ← Play listing + content-rating/data-safety prep
│   └── privacy_policy_terms.md    ← privacy policy + ToS DRAFT (host + in-app)
├── safety/
│   ├── safety_screening_pack.md   ← hardened disclaimer + hypertonic branch + red-flag triage
│   └── physio_reviewer_brief.md   ← for the physio (sent at first revenue)
├── articles/                      ← ALL 8, each REVIEW PENDING
│   ├── article_1_pelvic_floor.md
│   ├── article_2_erections.md
│   ├── article_3_performance_anxiety.md
│   ├── article_4_premature_ejaculation.md
│   ├── article_5_delayed_ejaculation.md
│   ├── article_6_sleep_metabolic.md
│   ├── article_7_pornography_myths.md
│   └── article_8_warning_signs.md
├── heritage/
│   └── heritage_framework.md      ← claim-free curation framework (+ remaining excerpt pass)
└── decisions/
    └── decisions_and_specs.md     ← 16 decisions + #1 mood-calibration + #5 plan-reveal lines
```

---

## Implementation task list (in order)

**1 — Safety pack → onboarding (do first; pre-launch).** From `safety/safety_screening_pack.md`: the must-accept **health disclaimer** screen (store acceptance + version); the **tension/hypertonic screening** branch with down-training-first routing; the **conservative red-flag triage** + urgent/emergency carve-out. Onboarding order: red-flag screen → tension screen → plan; emergency carve-out overrides all.

**2 — Reconcile copy with existing screens.** Apply `content/onboarding_copy.md` and `content/pricing_paywall_copy.md`. Keep paywall guardrails (nothing pre-selected, ₹0 unstigmatised, no countdown; consultation firewalled from any "see a doctor" message).

**3 — Seed the session program.** From `session_scripts/session_scripts_ALL.md` — 12 weeks. Settle/Down-regulate are full in Week 1 and reused verbatim; only Core work + reflection change weekly.

**4 — Apply decisions.** From `decisions/decisions_and_specs.md`: implement #1 (mood deltas) and #5 (plan-reveal lines); make the CHANGE items (#2→4, #8→6-digit, #10→cut ₹1499, #14→relabel disguise, #16→add content field + read→do footer, #12→reconcile reminder-time discrepancy). Everything else ships on its default.

**5 — Privacy/terms + disclaimer.** Host `content/privacy_policy_terms.md` at a public URL; wire into Play Console + in-app About; the must-accept disclaimer is part of task 1.

**6 — Articles & heritage.** Seed all 8 articles in `articles/` behind **"review pending"** badges. Heritage pieces (per `heritage/heritage_framework.md`) render without the badge — but only because they carry no claims; keep them claim-free. The library should tolerate heritage being added later.

**7 — Build the signed AAB** for the closed-testing track.

---

## Sequencing & gating
- **RevenueCat is post-upload.** Key + subscription products can only be created after the app is registered in Play. The free Foundation runs without it (Noop/local-trial seam). Wire RevenueCat before the paid tiers transact, not before testing.
- **Doctor / physio / lawyer are deferred to first revenue.** Until then: articles ship behind the review-pending badge; the red-flag triage + disclaimer run on the grounded conservative versions in the safety pack; the privacy policy runs on the draft. The article reference sections each carry **VERIFY** flags for the clinician.
- **Device verification happens during closed testing** on real phones (disguise/Book Mode, launcher swap, haptics, exact-alarm, biometric/PIN).

## Not in this package (still pending / not Claude Code's)
- Final heritage **excerpt selection + provenance verification** (the framework is here; the short curation pass remains — ₹0 via the public-domain pipeline).
- The optional Settle/Down-regulate copy variant pool.
- RevenueCat key, Play Console steps, tester recruitment, device testing, publish (Saurabh's).

## Non-negotiable guardrails (apply throughout)
- No fear-based copy anywhere; no pure red in the UI (turmeric for attention states).
- Session copy stays **instructional and claim-free** — health claims live only in the doctor-gated articles.
- Paywall: nothing pre-selected, ₹0 genuine and unstigmatised, no countdown; **never** funnel a health/"see a doctor" message into the paid consultation.
- Persona-Zero-inclusive: never assume the user has a partner or has been sexually active.
- The down-training (reverse-kegel) cue stays gentle — never a forceful bearing-down.
