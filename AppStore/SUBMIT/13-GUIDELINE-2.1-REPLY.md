# Reply to Guideline 2.1 — Information Needed

This is an information request, not a defect. Apple asks this of most new apps. Six of the
seven items are text you paste; item 1 is a screen recording somebody has to make on a
real iPhone.

Paste the whole block below into **App Review Information > Notes**, then reply in the
Resolution Center saying the notes are updated and the recording is attached.


---

## CHECK THIS FIRST: were the subscriptions actually submitted?

Apple's own submission guide says, plainly:

> Submit the In-App Purchases in App Store Connect that you'd like reviewed.

Products **existing** is not the same as products being **submitted with the version**. The
last audit found both subscriptions sitting at "Prepare for Submission" with **no review
screenshot attached**, and a product cannot be submitted without one. If they went in that
state, the reviewer opened the paywall, found nothing purchasable, and could not evaluate
the purchase flow at all. That would explain why they asked for a recording of it.

**Verify before replying:**
1. Both products show a review screenshot
2. Both are attached to this version's submission, not just sitting in the products list
3. Their status is "Waiting for Review", the same as the build

If they are not attached, fixing that may matter more than the recording does.

The good news: the guide also confirms **"In-App Purchases don't need prior approval from
App Review to function in review"**, and our paywall is already returning live prices
($4.99 and $34.99) now the Paid Applications Agreement is active. So the sandbox side
works; it is only the submission linkage to check.

## Also confirmed by the guide

**"We'll need to review the entire app experience, both with and without an account."**
We satisfy this exactly: "look around for a day first" is the without-account path and
Sign in with Apple is the with-account path. The notes above lead with both. This is the
demonstration mode Apple asks for in place of demo credentials.

## If a reply is not enough

The guide offers two escalations worth knowing:

- **Request a call.** Reply to App Review and ask, including a preferred time and
  language. Faster than trading messages when something is being misunderstood.
- **Meet with Apple appointments**, Tuesdays and Thursdays, to talk to a review expert
  before resubmitting.

Neither is needed yet. Use them if a second information request arrives, rather than
guessing at a third reply.

---

## The recording (item 1) — the only part that needs a person

Record on a **physical iPhone**, not a simulator, running the current iOS. Start the
recording BEFORE launching the app. iPhone: Settings > Control Centre > add Screen
Recording, then swipe down and press it.

Show this order, roughly 3 to 4 minutes, no narration needed:

1. **Launch from the home screen** (they explicitly ask for this)
2. **Sign-in screen** — tap "look around for a day first" to show entry without an account,
   then quit and relaunch and use **Sign in with Apple** so both paths appear
3. **Onboarding** through to the creature hatching and being named
4. **Health permission prompt** appearing, and Allow (a sensitive-data prompt they asked for)
5. **Screen Time permission prompt** appearing (second sensitive-data prompt)
6. **Home** — tap the creature, do a check-in, start a focus session
7. **Shop** — scroll to the bottom card, tap **yolkling+**
8. **The paywall** — both plans with prices visible, then start a purchase and show the
   Apple payment sheet (you may cancel it; they need to see the flow, not a charge)
9. **Profile > manage your support** — show the Customer Center where cancelling lives
10. **Friends** — show adding a friend, then a friend's profile showing **block** and
    **report** (they explicitly ask for UGC reporting and blocking)
11. **Profile > delete account** — show the deletion flow exists. You can back out at the
    confirmation.

Items 4, 5, 8, 10 and 11 are the ones they named specifically. Missing any of them
invites the same rejection again.

---

## Paste into App Review Information > Notes

**The field caps at 4,000 characters and fails SILENTLY.** Over the limit, Save appears to
succeed, the button goes to its disabled "saved" state with no error, and a reload shows
the old text back. The first version of this block was 5,033 characters and did exactly
that. This one is 3,437, verified by count.

```
DEVICES TESTED (physical)
iPhone 16 Pro Max (iOS 26), iPhone SE 3rd gen (iOS 26).

WHAT IT DOES AND WHO FOR
Yolkling is a virtual pet that grows when you take care of yourself. Your steps, sleep, and time away from your phone feed the creature.

Most wellbeing apps ask you to open them more, which competes with the behaviour they encourage. Yolkling inverts that: the highest-earning activity is time NOT on your phone, and there is nothing to gain from a long session.

For adults and older teens wanting a gentle way to build daily self-care habits. Not a clinical product: no health claims, no diagnosis, treatment or advice.

ACCESS (no demo account exists)
Sign in with Apple is the only sign-in method, so there is no username or password to give. Two ways in, both with full access:
1. Tap "look around for a day first" on the first screen. Opens the entire app with no account. This is our demonstration mode.
2. Or Sign in with Apple with any Apple ID. We request no name and no email (requestedScopes empty), only the stable user id.

WHERE THINGS ARE
- Creature, check-in, focus: Home tab, after onboarding.
- Purchases: You tab > "yolkling+", or Shop tab, bottom card. Restore is on the paywall.
- Cancel or manage: You tab > "manage your support" (RevenueCat Customer Center, in-app).
- User content, block and report: Friends tab. Add a friend by code or QR, open their profile.
- Account deletion: You tab > delete account.
- Health is optional; the app works fully if declined. Add Steps and Sleep samples in Apple Health to see growth.

EXTERNAL SERVICES
- RevenueCat: subscription management and entitlements.
- Supabase (vlucekvrdxvpkvbizabz.supabase.co): creature backup, friend graph, trading and postcards. Authenticated per user from the Sign in with Apple identity token; the server does not trust client-supplied ids.
- Apple frameworks only otherwise: AuthenticationServices, HealthKit, FamilyControls and DeviceActivity (Screen Time), ActivityKit (focus Live Activity), AVFoundation (QR scanner for adding friends), StoreKit via RevenueCat, local UserNotifications.

No AI or ML services, no advertising SDKs, no analytics SDKs, no third-party data providers. No IDFA and no ATT prompt, because we do not track.

Health data never leaves the device. Steps and sleep are read and used on-device only; raw values are never uploaded anywhere.

REGIONAL DIFFERENCES
None. Identical in all 175 regions. No region-locked content, no location access, no feature that varies by region.

REGULATED INDUSTRY / THIRD-PARTY MATERIAL
Not applicable. Not a medical, health, financial or regulated product; no medical claims, diagnosis, treatment or measurement. All artwork, characters, names and copy are original and drawn programmatically in code by the developer. No licensed, stock or third-party protected material anywhere.

SUBSCRIPTION (3.1.2)
One subscription, Yolkling Plus, two auto-renewable options: Monthly USD 4.99, Yearly USD 34.99. Both show title, length and price on the paywall before purchase, with Terms of Use and Privacy Policy links and Restore Purchases on the same screen.

Plus grants a cosmetic supporter glow and 400 Yolks monthly. It gates no content: every species, cosmetic and feature is reachable without it.

Yolks cannot be bought at any price. No currency packs, no randomised purchases, no gacha, no loot boxes. Cosmetics are fixed-price, bought with Yolks earned through daily use.
```

(3,437 / 4,000 characters. If you edit it, re-count before saving, because the UI will not
tell you.)
