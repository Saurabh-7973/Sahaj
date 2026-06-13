# Sahaj — Master Handoff (Lamplight, curated end to end)

All eight modules are now passed through the curation system: interrogated, mocked at full dress, specced to be executable without questions. This file is the front door.

## How to read this kit

1. **Mockups are pixel truth.** `00_index.html` launches everything; module files (`m1_…`–`m8_…`) are current; v2 screens marked "adopted" are part of their module; "superseded" screens are history.
2. **Module specs govern behavior and copy.** `m1_session_loop_spec.md` · `m2_today_spec.md` · `m3_progress_spec.md` · `m4_onboarding_spec.md` · `m5_library_spec.md` · `m6_privacy_spec.md` · `m7_monetisation_spec.md` · `m8_system_spec.md`. Where a spec and a mock disagree: mock wins on visuals, spec wins on words and states.
3. **`sahaj_ui_design_spec.md`** remains the base layer for tokens (Part A) and the component system (Part B). Its Part L build order is superseded by the module order below.
4. **Nothing is invented at implementation time.** Anything undefined lives in the consolidated decisions list — clear it, don't improvise.

## The uniformity contract — every screen, five tests

1. **Shoulder-surf:** glanced from a metre, nothing names the purpose.
2. **Persona Zero:** every line reads true for a man who has never been sexually active and has nothing wrong.
3. **Two-tap:** open → training in ≤2 taps on a normal day.
4. **Face-down:** any session completable with the screen unseen.
5. **QUITTR:** if a line or visual could appear in their onboarding, it doesn't appear in ours.

## Build order (Claude Code)

Tokens calibration (Part A → `lib/core/theme/`) → **M1 Session Loop** → **M2 Today** → **M3 Me/Progress & Check-ins** → **M4 Onboarding** → **M5 Library & Reader** → **M6 Privacy system** → **M7 Monetisation** → **M8 System**. Definition of done per module: tokens only, every state from the module spec, TalkBack pass, reduced-motion pass, +30% string room, the module's own acceptance criteria, one screenshot per screen into `docs/ui_review/`.

## File map

| Module | Mocks | Spec | Adopted v2 |
|---|---|---|---|
| M1 Session Loop | m1_01–m1_06 (11 phones) | m1_session_loop_spec.md | — |
| M2 Today | m2_01–m2_04 (5) | m2_today_spec.md | — |
| M3 Progress | m3_01–m3_04 (6) | m3_progress_spec.md | — |
| M4 Onboarding | m4_01–m4_03 (3) | m4_onboarding_spec.md | 01–09, 11, 12 |
| M5 Library | m5_01–m5_02 (2) | m5_library_spec.md | 14, 20 (heritage-chip patched) |
| M6 Privacy | m6_01–m6_02 (4) | m6_privacy_spec.md | 21 (haptic-row patched), 22, 23, 24 |
| M7 Monetisation | m7_01–m7_03 (4) | m7_monetisation_spec.md | 25, 26 |
| M8 System | m8_01–m8_02 (2 boards) | m8_system_spec.md | 27 |

## Consolidated decisions — clear before the corresponding module is built

**Plan-engine lookups (answers exist in your code/docs):**
1. Mood→calibration delta table for the prescription echo (M1·3)
2. Weekly session denominator — "3 done" vs "3 of N" (M2·1)
3. Gap threshold N that triggers the adjusted plan (M2·2)
4. Per-persona check-in domain set (M3·2)
5. Crisis-trigger item and threshold as implemented (M4·1)
6. Free-practice scope: library shows all free sessions regardless of week? (M5·1)
7. Goal→personalized-line table for the plan reveal, four lines remaining (M4·2)

**Device tests (Claude Code, on hardware):**
8. Haptic primitive mapping — four cues distinguishable through a mattress (M1·1)
9. Face-down detection strategy + no-proximity fallback (M1·2)
10. Splash-alias carry-through on target APIs/OEMs (M8·1)
11. Media-notification compact view / paused-dismiss behavior (M8·2)
12. App Info label leak check on MIUI/ColorOS/OneUI (M6·3)
13. Badge/dot suppression OEM variance (M8·4)

**Product calls (Saurabh):**
14. "You can stop any time" clause — reassurance or permission-seeking? (M1·4)
15. Date format / l10n approach (M2·3)
16. Free-practice link stays done-state-only (M2·4 — recommended yes)
17. Delta display relative-only vs raw scale (M3·1 — recommended relative-only)
18. Dip/flat copy: synthesis-grounded line or generic stands (M3·3)
19. "Start over" scope in onboarding resume (M4·3 — recommended onboarding-only)
20. Screening-incomplete one-liner on Today (M4·4)
21. Heritage doctor-gate: review without wearing the badge? (M5·2)
22. Related-session footer proposal — adopt or drop before seeding (M5·3)
23. Search scope titles-only (M5·4 — recommended yes)
24. PIN length + lockout policy (M6·1)
25. Panic gesture proposal — adopt or drop (M6·2)
26. Final alias label ("My Notes") + OEM collision check (M6·4)
27. ₹1499 pay-it-forward — real mechanism or cut the line (M7·1)
28. Trial length/eligibility vs Play config (M7·2)
29. Grace-period copy mirrors Play's window (M7·3)
30. Me subscription tile shows tier when Pro (M7·4 / M3·4 — recommended yes)
31. UPI-mandate strip — hold until real support data (M7·5)
32. Default reminder time, and whether "This evening" asks once (M8·3)

## Outside design — the standing user TODOs

Doctor sign-off on all evidence articles (gate before Play) · voice ear-check (`tool/auditions/`) · disguise identity final (closes #26) · Play Console: keystore, AAB, four subscription products at the tier prices + 7-day trial · real-device pass after each module lands.

When the decisions are cleared, hand this zip plus the specs to Claude Code and execute M1→M8 in order. The mocks are the bar; nothing ships below them.
