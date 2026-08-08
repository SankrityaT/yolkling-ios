# Shipaton submission checklist

From RevenueCat's published judging process + the 2026 kickoff livestream. Everything
here is a real disqualification risk or a scoring lever, not general advice.

## Hard gates — fail any of these and you're out at intake

- [ ] **First public release lands Aug 1 – Sep 30, 2026.** They check the release date on
      the store listing and auto-disqualify outside the window. This was the single
      biggest cause of disqualification last year.
- [ ] **The app is available in the US App Store.** Not just your home market. Their words:
      *"it also has to be available in the US app store … if it's not available we will
      unfortunately have to disqualify, because then we don't have any official way of
      testing the real app."* Set availability to include the US when creating the record.
- [ ] **Store URL in the submission works.** They will not chase you: *"we won't be
      reaching out to you to ask if you've submitted the correct URL if it's not working."*
- [ ] **Bundle ID / package name is filled in and correct.** They use it to verify the
      RevenueCat SDK is integrated. For us: `com.Sankritya.Yolkling`, and the RevenueCat
      dashboard must have an App Store app configured against that same bundle ID.
- [ ] **Video is public on YouTube or Vimeo**, linked in the form.
- [ ] **App icon 1024×1024** and **at least one screenshot at 1179×2556, no device frame.**
      These get used for the Times Square billboard, so they're a hard requirement.
- [ ] **A free trial or a promo code** so judges can reach the paid features.
- [ ] **Every category question answered.** *"If you left the question for the RevenueCat
      Peace Prize empty, your app won't get judged for that."* An unanswered question is a
      category you did not enter.

## The video decides almost everything

Prescreeners watch **the first two minutes** and read the description. They are *not*
required to install the app. Two minutes has to carry:

1. **The elevator pitch** — what this is, in one sentence.
2. **The app actually running** — screen recording, real flows.
3. **Which categories you're targeting and why.**

**Only show features that exist in the shipped build.** Explicit warning: *"if you go
through your app and it doesn't have the features that you show in the video we will
unfortunately have to disqualify you."* At final selection a RevenueCat developer advocate
downloads the app and confirms it matches the video.

⚠️ **Specific to us:** the app has a lot of `YOLK_*` launch-argument seams that jump
straight to screens. Do not record any flow you can only reach through a seam. Every
second of the video must be reachable by a judge with a fresh install.

## What actually wins

> *"The apps that stand out are the ones that can tell a good compelling narrative about
> their app related to that specific category."*

Said twice, in both sources. Scoring is 1–5 per category by at least two screeners, then
judges. A working app with a sharp story beats a bigger app with a vague one.

**Don't spam categories.** *"Don't try to fit your app in all of the categories."* Pick the
ones where the narrative is genuinely strong and answer those questions properly.

## Our categories, and the story for each

| Category | The narrative |
|---|---|
| **RevenueCat Design Award** | A creature drawn entirely in code — no art assets — that breathes with asymmetric inhale/exhale, blinks irregularly, and whose hat lags and settles when it moves. 900+ species from parametric parts. |
| **HAMM** | We integrated RevenueCat's **Virtual Currency system specifically in order not to sell currency.** Their ledger holds every Yolk that came from money; ours holds every Yolk that came from living. Two economies, structurally separate. An engaged free player out-earns a subscriber 3.4×, measured. |
| **#BuildInPublic** | `CLAIMS.md` — an honesty ledger tracking every promise the landing page makes against what's actually built, including the ones we got wrong and removed. |
| **Peace Prize** | The only app that monetises *support* rather than attention: revenue is decoupled from screen time, so the business has no incentive to keep you here. |
| **Grand Prize** | Post-launch traction. Needs the growth loop live, which needs the AASA file deployed. |
| **Next Gen** | Student-only, judged on video + open-source code, **no store release required.** A hedge that survives even if the App Store timeline slips. |

Deliberately **not** entering: OneSignal (no push built), Kotlin/Galaxy (wrong platform),
Replit / Stripe Funnels (revenue-dependent).

## Timing

30% of submissions arrive in the final week; 25% in the last three days. Submissions are
**editable right up to the deadline**, so submitting early costs nothing and removes the
risk of a store-review delay eating the window. Submit as soon as the app is live, then
keep improving the page.

## Judging timeline

Submissions close Sep 30 → intake filtering Oct 1 → prescreening (2+ RevenueCat screeners,
1–5 per category) → judge scoring → winners picked Oct 8–9. Winners fly to App Growth
Annual in NYC in October.
