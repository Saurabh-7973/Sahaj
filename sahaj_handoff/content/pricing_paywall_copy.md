# Sahaj — Pricing & Paywall Copy

> Convention: **plain text** = on-screen copy. *Italic in brackets* = implementation / design note.
>
> Non-negotiables baked in: no fear, no countdown clock, free Foundation works forever, **nothing pre-selected** on the price screen, ₹0 is a real and unstigmatised option, and health/medical messaging is **never** wired to a sale.

---

## 1 — The soft paywall (shown at the start of Week 5)
*[Appears only after the user finishes the free Foundation phase and after onboarding's health screen. It is "soft": dismissible, never blocks what's already free, never counts down.]*

**You've finished the foundation.**

Four weeks in, you've got a real, working base — and it stays yours, free, for as long as you use Sahaj. Nothing you've built expires.

The next eight weeks go further: longer training, the combined patterns, down-training, and using all of it in real life.

If Sahaj is worth it to you, you choose what to pay. If money's tight, ₹0 is a real option — no catch, no lesser version.

*[Price options, displayed in a row, **none pre-selected**, ₹0 presented with the same visual weight as the others — not greyed, not hidden, not last:]*
- **₹0** — pay what you can, which is nothing right now
- **₹499**
- **₹999**
- **₹1,499** — *(decision #10: include only if the pay-it-forward mechanism is real; otherwise omit this row entirely rather than charge a premium for a story we can't back)*

*[Primary: "Unlock the full plan" (enabled once a tier is chosen, including ₹0) · Secondary: "Maybe later" → returns to the free experience, no penalty, no nag, paywall reappears only on the next natural attempt to access paid content.]*

## 2 — The ₹0 line, if the user picks it
*[No friction, no guilt, no "are you sure". This is the whole point of pay-what-you-can.]*

Done. The full plan's yours.

Pay later if it ever helps you and you're able to. Either way, you're exactly as welcome here.

*[₹0 is granted locally — not a Play SKU. Implementation per `pricing_tier.dart`; the paid tiers map to `sahaj_pro_499 / 999 / 1499`.]*

## 3 — The ₹1,499 "pay-it-forward" line — *(only if kept; decision #10)*
*[Show this copy ONLY if a real mechanism exists where this tier funds a ₹0 grant for someone else. If it doesn't, cut both this and the ₹1,499 row above. Charging extra for an unbacked story breaks the honesty rule.]*

Choosing this covers your plan and helps fund a free one for someone who can't pay. Thank you — that's not nothing.

## 4 — Optional doctor consultation
*[A separate, opt-in offering. It lives in its own place — Settings / a "Talk to a doctor" entry — and is surfaced ONLY when the user goes looking for it. It must NEVER be triggered by, linked from, or suggested alongside any health-screening result, warning-sign content, or "see a doctor" message. Funnelling an honest health prompt into a paid sale is exactly the pattern this app refuses.]*

**Want to talk to a doctor?**

If you'd like a professional opinion, you can book a one-time consultation with a doctor through Sahaj.

It's entirely optional — your own GP or any clinician works just as well. This is here only if it's convenient for you.

*[Price: ₹500–₹1,500, one-time. Primary: "Book a consultation" · Secondary: "Not now".]*

---

## Guardrails for build
- The price screen is the **only** place tiers appear. No pricing language anywhere in onboarding, sessions, articles, or notifications.
- **No countdown, no "limited time", no "X people upgraded", no streak-loss threats.** None of it.
- ₹0 is never styled as inferior and never pre-selected; *no* option is pre-selected.
- The consultation (§4) and any "see a doctor" health messaging are **firewalled** from each other — separate surfaces, never cross-linked.
- Dismissing the paywall always returns the user to a fully working free experience.
