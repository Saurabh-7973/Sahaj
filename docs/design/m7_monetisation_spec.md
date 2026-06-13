# Screen Spec — Module 7: Monetisation (the fair shopkeeper)

> **Build order:** #7
> **Mockups (ground truth):** `25_paywall.html` (unselected) and `26_subscription.html` (free state) **adopted**; new: `m7_01_paywall_selected.html` · `m7_02_zero_dismissal.html` · `m7_03_subscription_pro.html` (trial + active).
> **Routes:** `/paywall` (modal) · `/subscription`.
> **State:** `subscriptionProvider` over the RevenueCat seam; entitlement = single `pro` flag regardless of tier paid.
> **Rule:** mockup wins on visuals, spec wins on copy/behavior, undefined → Decisions Needed.

---

## 0. Module laws

1. **Pull, never push.** The paywall has exactly three entry points: a locked row's PreviewSheet → See Pro · the Me subscription tile · the subscription page's See Pro. It never appears as an interstitial, never after a session, never after a check-in (the ceremony stays pure), never via notification — **notifications never sell, ever.** Dismissed = gone until pulled again.
2. **Dates, not countdowns.** All time-bound billing facts render as dates ("trial until 18 June", "renews 14 June 2027"). Days-remaining counters are pressure mechanics and are banned, including in copy.
3. **Equal dignity at every price.** Nothing pre-selected; selection of any tier gets identical treatment; choosing below the recommendation triggers no nudge, no comparison, no second screen. Selection ends the conversation. ₹0's card is the same size, weight and contrast as every paid card — measured, not eyeballed.
4. **The wall teaches the exit.** The X is always visible; "Maybe later" always present; the trial card states how to cancel without being charged. A user who leaves respected returns; one who feels trapped never does.
5. **One entitlement.** Every paid tier unlocks the identical `pro` flag. The tiers differ in price only — the scale exists because incomes differ (confirmed against synthesis: sliding scale = same product).

## 1. Paywall (`25` adopted, `m7_01`)

- Anatomy as mocked: eyebrow · H1 "Pick what's reasonable for you" · pothi rule · scale explanation · 4-benefit grid · four `TierCard`s · CTA · tiny print · Maybe later.
- **Unselected:** CTA at 42% with "Nothing is pre-selected — tap a tier first." **Selected (`m7_01`):** chosen card gains the gold border + filled radio (₹999's Recommended chip is a label and never moves); CTA wakes; tiny print becomes price-specific: "₹499/yr after 7 days free · cancel anytime in Play · price never changes mid-subscription."
- Tier meaning lines (canon): ₹0 "Keep training free. The core program is yours either way." · ₹499 "A fair price on a tight budget." · ₹999 "The fair price." · ₹1499 "Covers you — and quietly covers someone's ₹499." *(the last line ships only if a real mechanism backs it — Decisions #1)*.
- **₹0 path (`m7_02`):** wall closes to the originating screen + toast "✓ Good — train on." (3s, single line, moss tick). Logged once; the wall never re-prompts unprompted.

## 2. Subscription page states (`26`, `m7_03`)

| State | Card | Notes |
|---|---|---|
| Free | "You're on Free / It stays free." + quiet See Pro | as `26` |
| Trial | "Sahaj Pro" + `trial until {date}` + `then ₹{price}/yr` + the cancel-without-charge line | `m7_03a` |
| Active | "Sahaj Pro" + `₹{price}/yr` + `renews {date}` + "Your price stays ₹{price} — it never changes mid-subscription." | `m7_03b` |
| Grace (payment failed) | Active card + turmeric strip: "Google Play couldn't renew this — fix it in Play. Pro stays open during the grace period." | spec-only; no shame copy |
| Lapsed | returns to Free card; library rows regain Pro chips silently — no "you lost access" screen | spec-only |

Trial→active transition is silent (no congratulation, no email). Manage = Play deep link; Restore = RevenueCat restore with inline result line, never a dialog.

## 3. Don'ts (the banned-pattern list)

No decoy tiers, no crossed-out anchor prices, no "most popular" beyond the single Recommended label, no social-proof counters, no exit-intent offers or surveys, no discount popups, no countdowns or "ends soon", no upsell after lower-tier selection, no anniversary upgrade prompts, no paywall after emotional moments (completion, milestone, check-in result, crisis-adjacent flows — hard ban), no Pro mentions inside onboarding (M4 law), no notification upsells.

## 4. Acceptance criteria

Five global tests, plus: X and Maybe later reachable in every paywall state including keyboard/TalkBack · ₹0 card measured equal (size, type scale, contrast) to paid cards · tiny print ≥10.5px and AA · all five subscription states golden-tested · entitlement flag identical across tiers (unit test) · Play price points match the four tiers in the console before release · dismissal toast honors reduced-motion (no slide, fade only).

## 5. Decisions needed (flagged, not invented)

1. **₹1499 pay-it-forward:** keep the line only if a real mechanism exists (even a yearly public note: "X memberships covered"); otherwise cut before launch.
2. **Trial length & eligibility:** 7 days assumed per synthesis — confirm in Play config, and whether trial applies once per account or per tier.
3. **Grace-period duration copy:** mirror Play's actual grace window in the strip wording.
4. **Me-tile content (closes M3 flag 4):** recommendation — tile shows tier name when Pro ("Subscription · Pro"), plain label when Free.
5. **UPI mandate quirks:** Indian Play subscriptions via UPI can require re-approval; if support tickets emerge, the grace strip may need a UPI-specific line — hold until real data.
