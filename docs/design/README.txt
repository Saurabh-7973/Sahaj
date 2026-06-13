SAHAJ — LAMPLIGHT UI KIT (sahaj_briefing)
=========================================

Start here: open 00_index.html in a browser (fonts load from Google Fonts,
so first open with internet; everything else is local and offline-safe).

What's inside
- 00_index.html ............ visual launcher for every mockup
- 01–27 *.html ............. every screen from §6 of the brief (35 phone
                             frames total; multi-phone files show states)
- lamplight.css ............ the shared token system — colors, type, spacing,
                             and every component class map 1:1 to Part A/B of
                             the spec; this file IS the design system reference
                             for the Flutter pass
- sahaj_ui_design_spec.md .. the full written specification (Parts A–L),
                             including the flagged principle conflicts and the
                             implementation order for Claude Code

Notes that matter
- Crisis screen (07b): helpline numbers must be wired from the values already
  implemented in code — the mock shows layout only.
- Heritage reader (20): the pull-quote is a placeholder line; swap in a
  verified excerpt before seeding.
- Session player (17): the breath-mode ring is live-animated in the mock —
  that 6s sine scale (0.86↔1.0) is the app's signature interaction.
- Book Mode cover (23): deliberately stock Material — do not "fix" it to
  match the design system.
- Paywall (25): nothing is pre-selected by design; the ₹1499 pay-it-forward
  line is a copy suggestion, cut if no real mechanism backs it.

Implementation: follow Part L of the spec (daily loop first), tokens only,
all states from Part J, TalkBack + reduced-motion pass per screen.
