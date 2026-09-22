# What the landing page has to match (as of Sep 21)

The app repo is the source of truth for what the app does. The landing site
(`/Users/sankiii/yolkling-app`) must not claim more than this. Each line was checked
against the code, not from memory.

## Change now, before the Product Hunt launch on Wed Sep 23

**1. Terms, pricing section.** Early supporters now keep the founding price; increases apply
to new subscribers only. Remove these three sentences from `app/terms/page.tsx`:

- "prices can change."
- "the founding price is not guaranteed to last forever."
- "if we ever raise the price on a subscription you already have, apple will ask you to agree
  first, and if you do not agree it simply will not renew at the new price."

Replace with:

> the price is always shown in the app before you buy anything. $4.99 a month and $34.99 a
> year are founding prices, and we may raise the price for new subscribers later. if you
> subscribe at a founding price, you keep that price for as long as your subscription stays
> active, even after it goes up for everyone else. if your subscription ends and you start a
> new one later, the price at that time applies, and switching to a different plan is priced
> at that plan's current price. you will never be charged more without saying yes.

The launch copy says "subscribe while it is and you keep it", so until this is live, the
launch and the terms contradict each other.

## Don't claim these

**Trading yolklings.** Only cosmetics can be traded (hats, glasses, scarves, decor). Species
cannot: they're a "discovered" flag, not an owned item, and founding species are explicitly
blocked. "Trade rare cards" is false, since the cards are species cards.

**"203 species to discover."** The catalog has 203, but 1.0 can only hand out 32. 203 becomes
true when 1.0.1 ships. Until then: "32 to find, from a taxonomy of over 200", or no number.

**Yolks can "never be bought at any price".** Plus grants 400 a month. The true line is that
Yolks aren't sold on their own.

**Mood stays on your device.** It doesn't. The mood goes up in the cloud backup and in the
room snapshot friends and strangers see. What genuinely never leaves the device is steps,
sleep and screen time.

**Anything about AI.** The app uses no AI model.

## True today, will need changing later

**"every species, every cosmetic, every feature is reachable without paying."** True now.
Limited-edition cosmetics for real money are planned; when they ship, this sentence becomes
false and must change.

## Safe to say

- A virtual pet that grows when you look after yourself: steps, sleep, time off the phone.
- Steps, sleep and screen time never leave the device.
- No ads, no tracking, no analytics, no loot boxes.
- One optional subscription, Yolkling Plus: a supporter glow and 400 Yolks a month, at a
  founding price that early supporters keep.
- Sign in with Apple, identifier only, no name or email.
- Friends by share code or QR; visits, waves, postcards from a set list of phrases;
  cosmetic trading; block and report on every profile.
- Account deletion inside the app.
