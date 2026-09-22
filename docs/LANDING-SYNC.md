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

**Trading yolklings.** Only wearable cosmetics can be traded: the 83 things your yolkling
wears, like hats, ears, glasses and bows. Not species (they're a "discovered" flag, not an
owned item), not founding species (explicitly blocked), and not decor, room themes or colours
either. "Trade rare cards" is false, since the cards are species cards. See "How trading
works" below.

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
- Friends by share code or QR; visits, waves, postcards from a set list of phrases; swapping
  a spare wearable with a friend, one for one; block and report on every profile.
- Account deletion inside the app.

## How trading works

Checked against `TradeSheet.swift`, `VisitView.swift` and `propose_trade` in
`docs/sql/trading.sql`.

1. **Friends only.** You add each other by share code or QR first. Strangers you meet on a
   wander can't be offered a swap, and nobody who has blocked you can be.
2. **Start from their room.** Visit a friend, tap **swap**, then **offer a swap**. The menu
   line under it says "they have to say yes".
3. **Pick one for one.** Choose one of your wearables to give and one of theirs you'd like.
   The picker only shows swaps that can actually go through: something you own that they
   don't, against something they own that you don't. You see the result on your own yolkling
   before sending.
4. **They decide.** It appears under "waiting on you" on their side, previewed on *their*
   yolkling, with "swap" or "no thanks". Nothing moves until they say yes.
5. **Limits.** At most five open offers at a time, and each one expires after three days.

It is deliberately small: no marketplace, no browsing, no prices or valuations, no history.
The code calls it "a small favour between friends, not a marketplace". Describe it that way.

**Known gap, so don't promise otherwise.** The person receiving an offer isn't told about it.
There's no notification, badge or inbox: offers are only loaded inside the swap screen, so
they only see it if they open a swap with some friend within three days, and otherwise it
quietly expires. Don't write "get notified when a friend wants to swap" or anything implying
offers find you. This is a bug worth fixing in 1.0.1, not a feature to describe.

**Suggested line:** "swap a spare hat with a friend, one for one. they have to say yes."
