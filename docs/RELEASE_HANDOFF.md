# Sahaj — Release Handoff & Decision Checklist

> One page that pulls every flagged product decision and device-side TODO into
> a single pre-launch checklist. Generated at the close of the Lamplight UI
> pass (M1–M8, commit `513dd79`). Source of detail: `docs/CHANGELOG.md`.

**Build state:** all 8 design modules built · 276 tests green · `flutter analyze`
clean · Kotlin compiles · Android resources + manifest merge clean. The app
runs end to end: onboarding → plan → daily loop → progress → check-ins →
library → privacy → paywall → notifications.

---

## A. Product decisions awaiting your call

Each is implemented with a sensible, flagged default so nothing blocks the
build. Confirm or change before release.

| # | Decision | Current default (in code) | Where to change |
|---|---|---|---|
| 1 | **Mood→calibration deltas** for `low` / `open` moods | run unchanged (only heavy/level/charged calibrate) | `session_calibration.dart` |
| 2 | **Gap-return threshold** (missed days → "plan adjusted") | `kGapThresholdDays = 3` | `today_logic.dart` |
| 3 | **Per-persona check-in domains** | derived 1:1 from baseline batteries (Control/Confidence/Calm · …/Staying-power) | `dashboard_logic.dart` (`kSoloDomains`/`kPartneredDomains`) |
| 4 | **Delta display granularity** | relative-only ("on your own week-0 scale") | M3 — keep, raw scores medicalize |
| 5 | **Personalized plan-reveal lines** | 6 goal→line mappings (2 match spec, 4 new) — review tone | `plan_reveal_lines.dart` |
| 6 | **Free-session scope** (library) | Foundation base techniques + variants free; rest Pro | `feature_gate.dart` (`kFreeSessionBaseTags`) |
| 7 | **Search scope** | titles-only | M5 — keep |
| 8 | **PIN length + lockout policy** | 4 digits, no lockout enforced | `lock_controller.dart` (`kPinLength`) |
| 9 | **Panic gesture** (in-app two-finger → cover) | not adopted (proposal) | — |
| 10 | **₹1499 pay-it-forward line** | ships as written | `pricing_tier.dart` — cut if no real mechanism |
| 11 | ~~Trial length~~ → **one-time lifetime unlock** (decided) | no trial, no renewal; pay once | `subscription_controller.dart` + Play in-app products |
| 12 | **Default reminder time** | 21:30; "This evening" uses same | `preferences_controller.dart` |
| 13 | **"You can stop any time" clause** | shown on holds 1–2 then drops | M1 — confirm tone with a real read |
| 14 | **Disguise alias label** | "My Notes" | `strings.xml` / cover — check OEM collision |
| 15 | **Heritage doctor-gate** | heritage pieces outside the medical gate (no claims); badge stays off cards | M5 policy |
| 16 | **Related-session footer** (read→do bridge) | not adopted (needs a content field) | before seeding |

---

## B. Device-side verification (real hardware, both identities)

Cannot be done from the dev machine — needs a phone, ideally across MIUI /
ColorOS / OneUI.

- [ ] **Surface audit (M8 §4):** zero purpose-words on every OS surface in
      both identities — lock screen (reminder + media), notification shade,
      status-bar icon, media controls, recents thumbnail, App Info,
      share-sheet source, splash, launcher label, export filename.
- [ ] **Launcher disguise swap:** Book Mode toggle actually changes icon +
      label (Sahaj ↔ My Notes); confirm launcher-cache timing and that no
      duplicate / missing home-screen entry occurs.
- [ ] **Recents thumbnail** shows the cover in 100% of backgrounding paths.
- [ ] **Adaptive icon** renders correctly under the three masks + Material You
      tinting; **splash/alias carry-through** on Android 12+ (decision M8 #1).
- [ ] **Heads-up never occurs** (channel importance = DEFAULT) — verify no
      reminder banner slides over another app.
- [ ] **Media-notification** compact/paused-dismiss behavior (M8 #2).
- [ ] **Launcher badge/dot** OEM variance (M8 #4) — accept or add a settings note.
- [ ] **Haptic cues** distinguishable through a mattress at in-pocket intensity
      (M1 decision #8) — and **face-down sensing** strategy (M1 #9, currently
      manual-entry only).
- [ ] **Biometric + PIN gate** flow on real enrollment / no-enrollment devices.
- [ ] **Exact-alarm reminder** fires at the chosen minute (not Doze-deferred).
- [ ] **App Info label** — confirm the alias label flows through; if the real
      name leaks on a skin, document it in the C11 privacy copy.

---

## C. External / content (not code)

- [ ] **Doctor sign-off** on all evidence articles — hard gate before Play.
      Articles currently render the honest "Review pending" badge; flip to
      `reviewState: reviewed` + `reviewedDate` + verified `sources[]` per
      article after the pass.
- [ ] **Heritage seeding:** swap the placeholder pull-quote for a verified
      public-domain excerpt; era-tag each piece; manual audit that zero
      claim-bearing sentences exist.
- [ ] **Citation "what it showed" lines** verified against each actual paper.
- [ ] **Voice ear-check** — confirm the picked TTS voice on the demo session.
- [ ] **Content depth** vs goals (session modules / articles) per roadmap.

---

## D. Play Console / release

- [ ] Keystore + signed AAB.
- [ ] Two **one-time** in-app products (non-consumable) at ₹499 / ₹999 +
      the ₹0 local grant (not a Play SKU); product ids match `pricing_tier.dart`
      (`sahaj_pro_499/999`). ₹1499 cut (#10); billing = one-time lifetime
      unlock, no subscriptions, no trial.
- [ ] RevenueCat API key → wire `PlatformSubscriptionRepository`; then the
      lifetime entitlement becomes backend-driven (today a local unlock stands
      in). See `docs/EXTERNAL_TASKS.md`.
- [ ] Deferred keys still stubbed in `main.dart`: Sentry DSN, Mixpanel token
      (both currently off per the "paid services off" decision — telemetry is
      Firebase only).
- [ ] Internal testing pass: 10+ onboard, 5+ complete 3 sessions.

---

## E. Remaining native code task

- [ ] **`PlatformSubscriptionRepository`** against RevenueCat (the seam exists;
      `NoopSubscriptionRepository` is wired today).
- [x] Launcher activity-alias runtime swap — **done** (`MainActivity.kt` +
      `launcher_disguise.dart`).

---

_Screenshots for M1–M7 live in `docs/ui_review/`. M8 surfaces are native and
verified on-device per section B._
