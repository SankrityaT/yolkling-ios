# Reply to Guideline 2.1 — Information Needed

This is an information request, not a defect. Apple asks this of most new apps. Six of the
seven items are text you paste; item 1 is a screen recording somebody has to make on a
real iPhone.

Paste the whole block below into **App Review Information > Notes**, then reply in the
Resolution Center saying the notes are updated and the recording is attached.

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

```
DEVICES AND OS TESTED
- iPhone 16 Pro Max, iOS 26
- iPhone SE (3rd generation), iOS 26
Both physical devices. Also verified on the iOS 26 simulator for layout across screen sizes.

WHAT THE APP DOES AND WHO IT IS FOR
Yolkling is a virtual pet that grows when you take care of yourself in real life. Your step count, your sleep, and time spent away from your phone feed the creature, so looking after yourself is what makes it thrive.

The problem it addresses: most wellbeing apps ask you to log more, open the app more, and stay longer, which competes with the behaviour they claim to encourage. Yolkling inverts that. The highest-earning activity in the app is time spent NOT on your phone, and there is nothing to gain from a long session.

Target audience: adults and older teenagers who want a gentle, low-pressure way to build daily self-care habits. It is deliberately not a clinical or medical product, makes no health claims, and offers no diagnosis, treatment or advice.

HOW TO SET UP AND ACCESS EVERYTHING
No demo account is needed and none exists. Sign in with Apple is the only sign-in method, so there is no user name or password to provide.

Two ways in, both giving complete access:
1. Tap "look around for a day first" on the first screen. This opens the entire app immediately with no account at all.
2. Or tap "Sign in with Apple" with any Apple ID, including your own test account. The app requests no name and no email (requestedScopes is empty) and receives only the stable user identifier.

Reaching each area:
- Creature, check-in and focus sessions: the Home tab, immediately after onboarding.
- Purchases: the You tab > "yolkling+", or the Shop tab, scroll to the bottom card > "yolkling+". Restore Purchases is on the paywall itself.
- Managing or cancelling a subscription: the You tab > "manage your support", which opens RevenueCat's Customer Center in-app.
- User-generated content, blocking and reporting: the Friends tab. Add a friend by code or QR, open their profile, and Block and Report are there.
- Account deletion: the You tab > delete account.
- Health: optional. The app is fully functional if you decline. To see growth from real data, add Steps and Sleep samples in the Apple Health app.

EXTERNAL SERVICES USED
- RevenueCat (purchases-ios SDK) — subscription management and entitlement checks. Handles the Yolkling Plus subscription and the monthly in-app currency grant.
- Supabase (https://vlucekvrdxvpkvbizabz.supabase.co) — our backend. Stores the creature backup, the friend graph, and the trading and postcard records. Authenticated per user via an identity token exchanged from Sign in with Apple; the app does not trust client-supplied identifiers.
- Apple frameworks only, beyond those two: Sign in with Apple (AuthenticationServices), HealthKit, Family Controls and DeviceActivity for Screen Time, ActivityKit for the focus Live Activity, AVFoundation for the QR code scanner used to add friends, StoreKit via RevenueCat, and local UserNotifications.

There are no AI or machine learning services of any kind, no advertising SDKs, no analytics SDKs, and no third-party data providers. The app does not use the Advertising Identifier and presents no App Tracking Transparency prompt because it does not track.

Health data never leaves the device. Steps and sleep are read on-device and converted into the creature's growth locally; the raw values are never uploaded to our servers or to anyone else.

REGIONAL DIFFERENCES
None. The app functions identically in all 175 regions where it is available. There is no region-locked content, no regional pricing logic beyond Apple's own storefront conversion, and no feature that varies by location. The app does not request location access.

REGULATED INDUSTRY AND THIRD-PARTY MATERIAL
Not applicable. Yolkling is not a medical, health, financial or otherwise regulated product. It makes no medical or health claims, provides no diagnosis, treatment, advice or measurement of any condition, and is not a substitute for professional care.

All artwork, characters, names and copy are original and drawn programmatically in code by the developer. There is no licensed, stock or third-party protected material anywhere in the app. "Yolkling" and all species names are our own.

SUBSCRIPTION DETAILS (Guideline 3.1.2)
One subscription, Yolkling Plus, offered as two auto-renewable options:
- Monthly, USD 4.99 per month
- Yearly, USD 34.99 per year
Both display their title, length and price on the paywall before purchase, alongside links to the Terms of Use and the Privacy Policy. Restore Purchases is on the same screen.

Yolkling Plus grants a cosmetic supporter glow on the creature and a monthly grant of 400 Yolks, the in-app currency. It gates no content: every species, cosmetic and feature is reachable without it.

Yolks cannot be purchased at any price. There is no currency pack, no randomised purchase, no gacha and no loot box anywhere in the app. Cosmetics are bought at fixed prices with Yolks earned through daily use.
```
