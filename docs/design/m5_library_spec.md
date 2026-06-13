# Screen Spec — Module 5: Library & Reader

> **Build order:** #5
> **Mockups (ground truth):** `14_library.html` (tab + PreviewSheet) and `20_article_reader.html` (evidence + heritage) are **adopted into this module** with the heritage-chip patch applied; new states: `m5_01_library_search.html` · `m5_02_reader_footer.html`.
> **Routes:** `/library` (tab) · `/library/article/{id}` · session rows → M1 player directly (free practice skips the mood sheet — it isn't the prescribed session).
> **State:** Riverpod `libraryProvider` (catalog + completion marks + search filter), `articleProvider`.
> **Rule:** mockup wins on visuals, spec wins on copy, undefined behavior → Decisions Needed.

---

## 0. Module laws

1. **Two registers, never blended.** The clinic (evidence articles: doctor badge, sources, health claims allowed) and the heritage room (cultural pieces: era tag, anti-shame frame, **zero health claims**). The registers never mix in a paragraph — and never on a badge: heritage pieces carry a sand `heritage · 1885` chip, **never** a medical-review badge in any state. A review badge on a culture piece blurs what the gate means.
2. **The library never says "not yet" — only "Pro."** Plan sequencing lives in Today; time-gates rendered as library locks read as punishment. One lock type exists here. *(Confirm against built free-practice logic — Decisions #1.)*
3. **The chapter-list law.** Practice rows are pure utility: title, one-line context, duration chip, and at most two marks (✓ done-before in faint moss; `Pro`). Medallions appear on group headers only — wayfinding, not decoration. Anything slowing the path to a session is friction.
4. **No engagement machinery.** No "trending," no recommendations engine, no read-streaks, no "continue reading" nags. A study, not a feed.

## 1. Library tab (`14`, adopted)

Reading first (the tab opens as the study), practice groups collapsed below; free rows sort before Pro within every group; sessions completed ≥1× carry the faint ✓ (useful for "redo what worked"). Group header: medallion + name + count + chevron; one group expanded at a time. PreviewSheet on locked rows as mocked — describes, never blocks; `Maybe later` always one tap.

## 2. Search (`m5_01`)

Filter-as-you-type, local, instant; matches **titles** (body-text search is out — Decisions #4); match substring highlighted in ochre; result rows gain a one-line context (`kegel · week 3`); sections with zero matches disappear entirely — no apology rows; match count as a single tiny line. Clear ✕ restores the browse state. No search history, ever (privacy: a search log is a confession log).

## 3. Reader (`20` adopted + `m5_02`)

- **Frame:** ochre progress bar (the only reading gamification that will ever exist), back, bookmark.
- **Evidence register:** eyebrow `READ · EVIDENCE-BASED`, Fraunces drop cap on the opening paragraph, 17/27.5 reading scale, pothi rule under the meta row.
- **Heritage register:** eyebrow `READ · HERITAGE`, oversized Fraunces quote-mark pull quotes between pothi rules, era tag in small caps (`ANANGA RANGA · BURTON TR., 1885 — LANGUAGE OF ITS TIME`), heritage chip in the meta row. Standing canon line in every heritage piece's intro block: *"Heritage, not instruction — and never medicine."* Quotes are verified excerpts only; the mock's line remains a placeholder until seeding.
- **Trust footer (`m5_02`):** end rule → review badge + date + "review record on file" → Sources card: each citation = name/year/journal + **one plain line on what it showed** (citations come from article frontmatter; the three mocked are real anchors — Dorey 2005, Rosen 1997 IIEF, Symonds 2007 PEDT) → Next-article card (hero treatment, watermark). Articles awaiting sign-off show the turmeric `Review pending` badge here and in the list — honest, shippable.

## 4. States

Article unreadable (corrupt local asset): inline line "Couldn't open this — it's stored on-device, try again." + retry; never a dialog. Empty search: handled by section-disappearance + `0 matches`. All-free user vs Pro user: identical library except chip presence — Pro rows simply lose the chip, no "unlocked!" theatre.

## 5. Don'ts

No padlock glyphs, no ghosted rows, no week-gates (law 2), no body-text snippets in search results (a snippet of this app's content on screen is a shoulder-surf risk), no reading-time pressure ("4 min left"), no social proof ("12k men read this").

## 6. Acceptance criteria

Five global tests, plus: search filter <16ms per keystroke on the 60-item catalog · highlight AA on surface · drop cap renders correctly at +30% strings and large font scale · heritage pieces contain zero claim-bearing sentences (manual audit gate before seeding) · every citation row's "what it showed" line verified against the actual paper during the doctor pass · PreviewSheet reachable by TalkBack with the same describe-don't-block order.

## 7. Decisions needed (flagged, not invented)

1. **Free-practice scope:** confirm the library exposes all free-tier sessions regardless of plan week (law 2 assumes yes).
2. **Heritage doctor-gate:** heritage pieces are outside the medical gate by design (no claims) — confirm you don't want doctor eyes on them anyway; if you do, the badge still stays off the cards (review happens, isn't worn).
3. **Related-session footer (proposal, unmocked):** technique articles could end with one "Practice this" session card bridging read→do. Worth it, but it's a new content field — adopt or drop before seeding.
4. **Search scope:** titles-only (mocked, recommended) vs title+body.
