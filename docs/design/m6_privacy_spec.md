# Screen Spec — Module 6: The Privacy System

> **Build order:** #6
> **Mockups (ground truth):** `21_settings.html` (adopted, **haptic-cues row patched in**) · `22_erase_confirm.html` (adopted) · `23_book_cover.html` (adopted) · `24_biometric_gate.html` (adopted) · new: `m6_01_cover_depth.html` (fake note + recents test) · `m6_02_gate_pin.html` (PIN pad + wrong-PIN).
> **Routes:** cover and gate sit **before** `/today` in the launch sequence when enabled; `/settings`, `/settings/erase`.
> **State:** `privacyProvider` (Book Mode flag, alias identity, lock method), secure storage for PIN hash.
> **Rule:** mockup wins on visuals, spec wins on copy/behavior, undefined → Decisions Needed.

---

## 0. The worst-seconds table — every exposure, one design answer

| Worst second | Design answer | Where |
|---|---|---|
| Launcher glanced | alias icon + "My Notes" label, another developer's aesthetic | A7 / `27` |
| Cover glanced (2s) | stock-Material notes list, pinned sections, plausible Indian-household content | `23` |
| Cover **tapped** | one level of real depth — a living checklist, one item ticked, a note to ask Mummy | `m6_01a` |
| Recents/task switcher | cover swapped in on `onPause`; FLAG_SECURE blank card as fallback only (a black rectangle invites questions a notes list doesn't) | `m6_01b` |
| Lock-screen notification | alias app-name + neutral copy bank (I1); session titles always neutral | `27` |
| Gate glanced | mark + sensor only — no app name, no purpose | `24` |
| PIN entered in company | mark, dots, pad; nothing readable | `m6_02a` |
| PIN fails | turmeric flash + "Try again" — no red, no countdown threat | `m6_02b` |
| "Arre, what's this app?" while open | every in-app screen already passes shoulder-surf (global test 1); panic gesture stays a proposal (Decisions #2) |
| App Info long-press | alias label must flow through to App Info; shortcuts & widgets disabled while disguised | Decisions #3 |

## 1. Launch sequence

Book Mode **on**: cover → double-tap anywhere → gate (biometric auto-fires; `Use PIN` fallback) → app. Book Mode **off**: gate (if lock enabled) → app. The double-tap is taught exactly once (C11 strip); no hint ever appears on the cover itself. Backgrounding from anywhere returns to the cover (when on), not the gate — the gate only stands between cover and app.

## 2. Cover depth rules (`23` + `m6_01a`)

- **Canned content only.** Every note title and body is authored once and shipped; nothing is ever generated from real data, contacts, dates, or usage. The cover must not become a second data surface.
- Depth = exactly one level: list → note. Notes are read-only-believable (checklist with one ticked item sells "in use"); the FAB and toolbar are inert decoys. No second-level navigation exists to get lost in.
- Content register: mundane Indian household (grocery with atta and dahi, "ask Mummy re: jeera brand", meeting note with a follow-up). Dates within the last ~6 weeks, static.
- The cover is the sanctioned stock-Material exception (Part K flag 4) — never "fix" it toward the design system; comment the exception in code.

## 3. Gate (`24`, `m6_02`)

Biometric prompt auto-fires on arrival; PIN pad on fallback or no enrollment. PIN length 4 (Decisions #1 if 6 preferred). Failure: dots turmeric + 200ms shake + "Try again" — full ceremony, nothing more; repeated-failure lockout policy is Decisions #1. Forgot PIN: **no recovery** — local-first means the honest path is wipe-and-restart; the "Forgot PIN" link goes to a plain screen explaining exactly that, reusing the G1 erase confirm. No app name anywhere on gate or pad.

## 4. Settings (`21`, adopted + patch)

Sections as mocked: Privacy (Book Mode + live alias preview · Biometric lock) · Daily rhythm (Daily reminder + time · **Haptic cues — relearn**, fulfilling M1's promise · Hide steady days) · Your data (Export — one JSON via share sheet · Erase everything → `22`). Erase flow: full-screen confirm, HoldToConfirm 3s, return to Welcome; wipes everything including onboarding answers and PIN.

## 5. Don'ts

No "privacy mode active" indicators inside the app (an indicator is a label). No cover content settings/customization in v1 (every option is a way to break the disguise). No screenshots blocked app-wide — only the recents rule; blocking screenshots punishes the user's own exports. No red on any failure state. Never name the gesture on the cover.

## 6. Acceptance criteria

Five global tests, plus the **literal glance protocol**: show the cover and the open note to three people for two seconds each; all three must answer "a notes app" — any other answer fails the build. Recents thumbnail shows the cover in 100% of backgrounding paths (golden test per route). PIN pad TalkBack-safe (announces "digit entered", never the digit). Alias label flows to notifications, App Info, and share-sheet source name. Wrong-PIN shake honors reduced-motion (flash only).

## 7. Decisions needed (flagged, not invented)

1. **Lockout policy + PIN length:** behavior after N failed attempts (cooldown? none?) and 4 vs 6 digits — your call; the screen design absorbs either.
2. **Panic gesture (proposal):** an in-app gesture (e.g., two-finger swipe-down) that instantly shows the cover, for the leaned-over moment. Cheap to build on the existing cover; adds one teachable gesture. Adopt or drop.
3. **App Info label:** verify the activity-alias label is what Android surfaces in App Info / battery / permissions screens on target APIs; if the real app name leaks there, document it honestly in C11 ("the disguise covers launcher, switcher and notifications — not Android's own settings pages").
4. **Final alias label:** "My Notes" pending your disguise-identity decision; check collision against the device's preinstalled notes app on common Indian OEM skins (MIUI/ColorOS/OneUI).
