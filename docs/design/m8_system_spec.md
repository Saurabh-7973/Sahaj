# Screen Spec — Module 8: System (icons, notifications, OS seams)

> **Build order:** #8 (last — everything it protects now exists)
> **Mockups (ground truth):** `27_system.html` (adopted: concepts board + notification cards) · new: `m8_01_lockscreen.html` (the audio seam) · `m8_02_icon_adaptive.html` (Concept A finalized).
> **No routes** — this module lives on Android's surfaces, not the app's.
> **Rule:** mockup wins on visuals, spec wins on copy/behavior, undefined → Decisions Needed.

---

## 0. Notification doctrine

- **Channel:** one — "Daily reminder", importance **DEFAULT, never HIGH.** A heads-up banner sliding over WhatsApp mid-family-chat is an exposure event; this app never peeks over anything.
- **Copy bank (canon, rotating):** "Your 7 minutes are ready." · "Calm breathing — when you're ready." · "Today's session is short. Take it when it suits." · "Eight minutes tonight — whenever works." · "Your session's waiting. No rush." · "A quiet ten minutes, when you get them."
- **Rules:** no emoji, no name, no session-type words beyond the neutral bank, no streak-risk framing ("don't lose / don't break" banned), and — M7 law restated — **notifications never sell.**
- **Suppression:** none if today's session is done (never remind a man who already trained) · none while a session is active · max one per day, at the chosen time only.
- **Permission timing:** `POST_NOTIFICATIONS` is requested only when the user expresses intent — the C12 "This evening" tap, or the Settings reminder toggle. Never at app open.
- **Alias flow-through:** the app name on every notification follows Book Mode state, always.
- **Launcher badges/dots:** off via channel config; OEM variance noted in Decisions #4.

## 1. The media-session law (`m8_01`)

Audio sessions create a lock-screen media notification whether we like it or not, so its metadata is governed: **title = a neutral copy-bank line** (the session's neutral display title, e.g. "Calm breathing"), **subtitle = "Audio"**, artwork = the lotus glyph (or none), app name = active identity. No technique words, no durations framed as exercise, standard transport controls. Beside a Messages card it must read as someone playing a calm track — that sentence is the acceptance test.

## 2. Icon — Concept A, finalized (`m8_02`)

Adaptive set, three layers: **foreground** bud line-art with nothing essential outside the 66% safe zone · **background** flat `#221D17` · **monochrome** bud paths only — under Material You tinting the icon becomes *maximally* anonymous, just another wallpaper-tinted glyph. The alias ships the same three-layer structure in the grey-blue aesthetic. Identity swap via activity-alias (M6 mechanics). **Splash:** Android 12+ derives splash from the launcher icon — minimal duration, no brand moment; alias carry-through is Decisions #1.

## 3. Small seams, governed

- **Book Mode toggle moment:** one-time line after toggling — "Your launcher icon just changed to My Notes — it may take a moment to appear." (launcher caches vary).
- **Export filename:** always `backup_{yyyy-mm-dd}.json` — never "sahaj" in a filename in either identity; files outlive the moment they were shared in.
- **No widgets in v1** (a widget is a permanent exposure surface) · no quick-settings tile · app shortcuts disabled while disguised (M6).

## 4. Acceptance — the surface audit

Enumerate every OS surface that can display app-origin text and verify **zero purpose-words in both identities**: lock screen (reminder + media) · notification shade collapsed/expanded · heads-up (must never occur — verified by channel importance) · status-bar icon · media controls / output switcher · recents thumbnail (M6) · App Info (M6 Decisions) · share-sheet source name · splash · launcher label · export filename. One golden checklist, run on a real device, both identities, before release. Plus the five global tests.

## 5. Decisions needed (flagged, not invented)

1. **Splash-alias verification:** confirm the alias icon (and an acceptable splash background) carries into the Android 12+ splash on target APIs/OEMs.
2. **Media-notification minimization:** compact-view-only and swipe-dismiss behavior when paused — pick after a device test.
3. **Default reminder time:** 21:30 mocked — confirm, and whether C12 "This evening" sets a fixed default or asks once.
4. **Badge/dot OEM variance:** MIUI/ColorOS may ignore channel badge settings — decide if acceptable or worth a settings note.
