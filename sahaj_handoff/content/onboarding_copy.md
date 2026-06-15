# Sahaj — Onboarding Copy (12 screens)

> Convention: **plain text** = on-screen copy. *Italic in brackets* = implementation / design note, not shown.
>
> Voice: warm older-brother-doctor, India-aware, no fear, no shame, no performance pressure. Persona-Zero-inclusive throughout (never assume the user is sexually active or has a partner).
>
> **Clinical gate:** the red-flag screen (S7) and its routing (S9) carry clinical thresholds that must be set and signed off by the clinical reviewer. Helpline numbers (S8) must be re-verified at ship.

---

## Screen 1 — Welcome
**Sahaj.**
It means *natural ease*.

This is a quiet, private place to work on your pelvic-floor and sexual health — at your own pace, with no pressure and nothing to be ashamed of.

*[Primary: "Begin" · Secondary: "What is this?" → brief explainer overlay]*

## Screen 2 — How this works
A few things to know up front:

- This is about your **health**, not about performance. Being well matters more than being impressive.
- You're in charge. Go at your pace, stop anytime, skip anything.
- We don't do fear, and we don't do shame. Ever.
- It works whether or not you have a partner, and whether or not you've ever been sexually active.

*[Primary: "Makes sense"]*

## Screen 3 — Your privacy
What happens here stays with you.

- Your information lives **on your phone**, not on a server we read.
- You can lock the app behind your fingerprint or a PIN.
- There's a **discreet mode** that makes Sahaj look like a plain reading app, if you share your phone or your space.

We'll set the lock up at the end.

*[Primary: "Good"]*

## Screen 4 — What brings you here
No wrong answers. Pick what fits — you can change it later.

*[Multi-select, mapped to plan goals. Options, neutral wording:]*
- More control / lasting longer
- More reliable erections
- Less anxiety around sex
- More confidence
- Just building a healthy foundation — no specific problem
- Reconnecting with a partner

*[Primary: "Continue". The "no specific problem" option is the Persona-Zero entry — it must feel as normal as the others, not lesser.]*

## Screen 5 — A bit about your situation
This just helps us shape the plan. Honest answers, only for you.

*[Single-select, persona routing — non-judgmental:]*
- I'm working on this on my own right now
- I have a partner

*[Primary: "Continue". No copy anywhere implies one is better or more "normal" than the other.]*

## Screen 6 — Health first
Before anything else — and before we ever mention money — a few quick health questions.

This is the one part that isn't optional, and it's the most important part: some things are better handled by a doctor than by an app, and we'd rather point you there than waste your time.

*[Primary: "Okay"]*

## Screen 7 — Health screening
*[A short set of conservative yes/no questions. **The specific questions, and which answers trigger the doctor-routing in Screen 9, MUST be provided and signed off by the clinical reviewer.** Placeholder structure only:]*

A few quick checks:
- *[Reviewer-defined red-flag question 1]*
- *[Reviewer-defined red-flag question 2]*
- *[…]*

*[Design rules for this screen, regardless of final questions:]*
- *Plain language, no jargon, no graphic detail.*
- *Framed as routine care, not as "warning signs" — calm, not alarming.*
- *A "prefer not to say" path exists and never blocks access to free general content.*

*[Primary: "Continue"]*

## Screen 8 — *(Conditional)* If distress or self-harm is indicated
*[Triggers if intake responses suggest the user may be in crisis. This screen interrupts the flow gently. It does NOT ask further assessment questions — it expresses care and offers help.]*

It sounds like things might be really heavy right now. That matters more than anything in this app.

You don't have to go through it alone. People are available, any time, free:

- **TeleMANAS** (mental health, 24×7): **14416** or **1-800-891-4416**
- **KIRAN** (24×7): **1800-599-0019**
- **In immediate danger? Call 112.**

Sahaj will be here whenever you're ready. There's no rush.

*[Primary: "Call TeleMANAS" (tel: link) · Secondary: "I'm okay for now" → returns to flow without penalty. Numbers re-verified at ship; clinical reviewer may add region-specific lines.]*

## Screen 9 — *(Conditional)* If the health screen flags something
*[Triggers on reviewer-defined red-flag answers from Screen 7.]*

Based on your answers, this is worth a conversation with a doctor before you start a training program — not because anything's necessarily wrong, but because it's the right order to do things in.

You can still read the general health articles here for free. We'd just hold off on the plan until you've checked in with someone.

*[Primary: "I understand" · Secondary: "Find out why" → links the (doctor-gated) warning-signs article. Routing logic and wording confirmed by clinical reviewer. Must never read as a diagnosis.]*

## Screen 10 — Your plan
*[Shown once cleared. Generates the rule-based 12-week plan from the goal (S4) and persona (S5). Reveal line uses the matched entry from `plan_reveal_lines.dart` (decision #5).]*

Here's your starting plan — twelve weeks, a few quiet minutes a day.

*[Personalised reveal line, e.g. for "healthy foundation":]*
"Nothing here needs fixing — you're building a strong base on your own terms, and honestly that's the best place anyone can start."

It'll adapt as you go. The first four weeks are yours free, for as long as you want them.

*[Primary: "Start week 1"]*

## Screen 11 — A daily nudge
Want a gentle daily reminder? You pick the time.

Most people choose the evening, once the day's quietened down.

*[Time picker, default **21:30** (decision #12 — reconcile with code). Exact-alarm, OEM-reliable. Primary: "Set reminder" · Secondary: "No reminder" — both fine, no nudging toward yes.]*

## Screen 12 — Lock it down
Last thing — keep this private.

*[Options:]*
- Unlock with fingerprint / face
- Unlock with a PIN
- *[Mention discreet "Book Mode" is available in Settings anytime]*

*[Primary: "Finish setup" → first session. Secondary: "Skip for now" — allowed, with a soft note that they can set it later in Settings.]*

---

## Notes for build
- Screens 8 and 9 are **conditional interrupts**, not steps everyone sees.
- Nothing before Screen 10 mentions price — health screening strictly precedes any paywall (core ethic).
- Every "Continue" has a visible back path; the only hard gate is completing the health screen (S6–S7).
- Tone audit before ship: zero fear words, zero shame, zero performance framing, no assumption of partner or prior sexual activity.
