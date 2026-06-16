# Sahaj — External Tasks Playbook
### Everything outside the code, in the order you can actually do it

> Work top to bottom. **The catch:** these have a dependency chain — you can't set up RevenueCat until your Play products exist, which needs the AAB uploaded, which needs the keystore. So order matters. Code-side steps (Claude Code) are marked **[CC]** where they interleave.
>
> Official click-by-click changes often; where the UI matters, I link the official doc. Confirm anything UI-specific there.

---

## The chain at a glance
```
[CC] keystore → [CC] signed AAB → create app in Play → host privacy policy URL
→ upload AAB to Internal testing → store listing + content rating + data safety
→ create one-time unlock products in Play → set up RevenueCat (Cloud service acct → link → import → key)
→ give key to [CC] → [CC] wires it → internal testing pass
→ (closed-testing window if your account needs it) → production
```

> **Billing model = one-time lifetime unlock (decided).** Pay once, kept forever — no renewal, no trial clock. Code reflects this (`subscription_controller.dart`). In Play these are **in-app products (one-time / non-consumable)**, NOT subscriptions.
**Parallel (anytime):** recruit testers · device verification (during testing) · TTS ear-check (optional) · heritage curation (optional).
**Deferred to first revenue:** doctor sign-off · lawyer · clinician thresholds.

---

## PHASE 1 — Get a testable build into Play

### 1.1 Keystore + signed AAB **[CC]**
- Claude Code builds the signed AAB. The **keystore** is yours to keep forever.
- **Critical:** back up the keystore file + passwords somewhere safe. Lose it and you can never update the app under the same listing. (If you use Play App Signing, the *upload* key can be reset by Google, but still — back it up.)
- **Done when:** you have a signed `.aab` in hand.

### 1.2 Create the app in Play Console
- Play Console → **All apps → Create app**. Name: *Sahaj*. Default language, App (not Game), Free, accept the declarations.
- Same developer account as Sanatan — no new fee.
- **Done when:** the Sahaj app dashboard exists.

### 1.3 Host the privacy policy + Terms at a public URL
- Use the `privacy_policy_terms.md` draft. Cheapest hosting: **GitHub Pages** (free), Google Sites, or Netlify — paste the content as a simple page.
- Put the URL in Play Console → **App content → Privacy policy**, and give it to [CC] for the in-app About screen.
- **Done when:** the policy is live at a URL and entered in Play.

### 1.4 Upload the AAB to Internal testing
- Play Console → **Testing → Internal testing → Create new release** → upload the AAB → add tester emails → review & roll out.
- Internal testing is instant (no review wait) — good for your own device checks.
- **Done when:** the build is live on the internal track and you can install it via the opt-in link.

### 1.5 Store listing + content rating + data safety
- **Main store listing:** use `store_listing.md` (title, short/full description, screenshots, captions).
- **Content rating:** answer the IARC questionnaire honestly — declare *references to sexual/medical health themes*, **no** explicit content, no nudity. Expect a Mature 17+ rating; that's fine.
- **Data safety:** fill from the prep notes in `store_listing.md`. **Keep it exactly in sync** with the privacy policy and what the app actually does — Play rejects mismatches.
- **Done when:** all three sections show complete/green.

---

## PHASE 2 — Monetisation (only after the app exists in Play)

### 2.1 Create the one-time unlock products in Play
- Play Console → **Monetise with Play → Products → In-app products → Create product**. (NOT Subscriptions — the model is a one-time lifetime unlock.)
- **Product IDs must exactly match `pricing_tier.dart`:** `sahaj_pro_499` and `sahaj_pro_999`. (₹1499 is cut; ₹0 is a **local grant in code, not a Play product**.)
- Set price ₹499 / ₹999, then **Activate**. No base plan, no billing period, **no trial offer** — one-time products don't have them.
- These are **non-consumable** (bought once, owned forever; RevenueCat treats them as a lifetime entitlement).
- **Done when:** the two products are Active in Play.

### 2.2 Set up RevenueCat (the multi-console one — switch between Play, Google Cloud, and RevenueCat)
Follow RevenueCat's official Google Play codelab alongside this (it's the current source of truth): `revenuecat.github.io/codelabs/google-play.html` and the service-credentials doc `revenuecat.com/docs/service-credentials/creating-play-service-credentials`.

a. **RevenueCat:** create an account and a Project.
b. **Google Cloud Console** (the project linked to your Play account): enable the **Google Play Android Developer API** and the **Play Developer Reporting API**.
c. **Create a service account** (IAM & Admin → Service Accounts), give it the roles RevenueCat's doc specifies (currently Pub/Sub Admin + Monitoring Viewer), then **create a JSON key** and download it.
d. **Google Play Console → Users and permissions** (API access): grant that service-account email access to the Sahaj app with the needed (finance/admin) permissions. *(Tip: editing any product's description in Play nudges the new credentials to validate faster.)*
e. **RevenueCat:** create an **Android app** — name, package name `com.saurabh7973.sahaj`, and **upload the service-account JSON**.
f. **Import** your two one-time (non-consumable) products into RevenueCat. Create an **Entitlement** (e.g. `pro`), attach both products, then create an **Offering**.
g. Set up **Pub/Sub server notifications** (RevenueCat app settings → Google Developer Notifications topic → Connect to Google).
h. Copy the **public SDK API key** (RevenueCat → Project → API Keys → **SDK API keys**, the Android/Google one). *Tip: there's also a Test Store `test_` key + Play **License testing** (Play Console → Settings → License testing) so you can test purchases without real charges.*
- **Done when:** RevenueCat shows your products imported and a green connection to Play, and you have the public SDK key.

### 2.3 Hand the key to Claude Code **[CC]**
- Give [CC] the public SDK API key. It wires `PlatformSubscriptionRepository`, replacing the Noop stand-in.
- **Done when:** a purchase made via the License-testing account unlocks Pro in the app.

---

## PHASE 3 — Real devices + testers

### 3.1 Recruit testers
- You've done this for Sanatan. Pull together your tester emails, share the opt-in link, and make sure they actually install and use it.
- **Done when:** testers are opted in and on the build.

### 3.2 Device verification (your MIUI / ColorOS / OneUI phones)
Run the full surface audit (the detailed checklist Claude Code gave you). The ones that matter most:
- **Disguise/Book Mode:** zero purpose-words on every surface (lock screen, shade, status-bar icon, media controls, recents, App Info, share-sheet, splash, launcher label, export filename); launcher icon+label flips cleanly with no duplicate/missing home entry.
- **Notifications:** heads-up never fires; exact-alarm reminder fires at the chosen minute (not Doze-deferred).
- **Haptics** distinguishable through a mattress at in-pocket intensity.
- **Lock:** biometric + 6-digit PIN on enrolled and non-enrolled devices.
- Plus **purchase flow** via License testing.
- **Done when:** the checklist passes on at least one real device of each skin you care about.

### 3.3 Internal testing pass
- Target: **10+ onboard, 5+ complete 3 sessions.**
- **Done when:** you've hit those and nothing's broken.

---

## PHASE 4 — Production
### 4.1 Closed-testing window (if needed)
- Newer personal accounts must run **closed testing with N testers for ~14 days** before production access. **Confirm from your Sanatan run whether this is per-app or once-per-account** — you'll know better than the docs. Plan the ~2-week clock in if it applies.
### 4.2 Promote → review → publish
- Promote the build to production, submit, wait out Google's review (a few days, possibly longer for a health app), publish.

---

## DEFERRED TO FIRST REVENUE *(process noted so you're ready, not to do now)*

### D.1 Doctor sign-off on the 8 articles
- **Who:** the doctor you'll partner with for the in-app consultations is the natural reviewer.
- **Send:** the 8 article files. Each has a **References — for verification** section with **VERIFY** flags.
- **Ask them to:** (1) confirm each "what it showed" line against the cited paper, (2) flag anything to change, (3) confirm the **red-flag triage + hypertonic thresholds** (safety pack §2–§3) and the down-training-first track.
- **Then [CC]:** flip each article `reviewState` pending→reviewed, set `reviewedDate`, drop the badge.

### D.2 Lawyer
- Finalise Terms **§1b** (health/liability), add a limitation-of-liability clause valid under Indian law, and confirm **DPDP Act 2023** compliance (incl. a Grievance Officer).

### D.3 Clinician thresholds
- Same person can confirm the red-flag + hypertonic screening thresholds (overlaps D.1).

---

## OPTIONAL / NON-BLOCKING
- **TTS voice ear-check** — when audio is added, confirm the chosen voice on a real demo session.
- **Heritage excerpts** — framework's done; source verified public-domain quotes via GRETIL / sacred-texts.com / Project Madurai, era-tag each, zero-claims audit.

---

### Bottom line
The only things gating a **free closed-testing launch** are in Phases 1–3: keystore/AAB **[CC]**, the Play setup, RevenueCat, device checks, testers. Doctor, lawyer, and clinician are all first-revenue. Billing model is **locked: one-time lifetime unlock** (in-app products, not subscriptions) — code already matches.
