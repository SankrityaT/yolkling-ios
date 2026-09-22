# Retention + monetization plan (1.1 design study)

Grounded in the codebase. Design, not bugs. Respects the hard rules: Yolks never
purchasable, no pay-for-power, no gacha, no ads, daily ceilings stay, and the
"engaged free player out-earns a subscriber 3.4x" number (4,800 paid Yolks/yr) is
load-bearing for the HAMM award and must never be inflated.

## The two highest-leverage moves

**Retention — surface collection set-completion.** The wander already delivers a card a
day, but it drops into a flat list. The 6 completable sets in `SpeciesSet.swift` were
built for the "tide pool, 4 of 6, almost there" pull and do no work today. Show nearest
set progress (starting "2 of 6" day one via `headStart`) on the wander reveal and in the
Dex, with a warm one-time bonus on completion. No new backend, no screen time, no guilt.
Size M. Risk: keep the completion bonus a flat one-time thing, never escalating, never
gating the free species.

**Monetization — activate the Founding Supporter lifetime tier.** A `$rc_lifetime`
package is already configured in RevenueCat and is invisible because
`SubscriptionStore.plans` only composes `[annual, monthly]`. Wire it in as a one-time
launch-window purchase with a distinct permanent glow variant. Pulls real cash into the
Shipaton window, captures the sub-averse cozy crowd, breaks no guardrail (sells status +
expression, never currency, never power). Size M, mostly wiring `plans` + a third card.
It must grant the SAME stipend cadence as Plus, or none, never a lump of Yolks.

## Retention, ranked
1. Collection set-completion + endowed progress (above). M. Wiring + small net-new.
2. Deepen the wander/homecoming loop; vary where it went, occasionally a postcard. S-M.
   Keep it once-a-day, hard; raising frequency violates the daily-ceiling thesis.
3. Make rest-token protection visible as reassurance ("you're covered for a day off"),
   never a countdown. `restTokens` already in view state. S. Framing it as loss-aversion
   would be the exact dark pattern guardrail 3 forbids.
4. Ship a real season cadence on the already-built rails (`EventStore`/`SeasonWindows`).
   S per season, no build to open one. An honest clock you can miss, never a pressure
   countdown.
5. One-tap warm reply/gift-back on `WhileYouWereAwayStrip`. S-M. Only fires on open until
   push exists, so it retains returners, not acquisition.
6. Event-driven notifications ("a friend visited while you were away"). BLOCKED in v1:
   push was cut, OneSignal not wired, and the wander homecoming also needs the pg_cron
   server drift. L, post-v1. The one place the app could drift into notification warfare;
   keep guardrail 4 (one gentle nudge, no badges).

## Monetization, ranked
1. Founding Supporter lifetime tier (above). M.
2. Deepen Plus without gating: Plus-only cosmetic closet rotation, full room-decor/theme
   catalog, deeper mood/growth history, extra glow variants. Turn on `requiresPlus`
   seasons as COSMETIC seasons. S-M. Corrosive only if it ever gates a species or a
   wellness feature.
3. Season pass that sells the season, not the currency: money buys the door, items inside
   are still earned with Yolks. M interim / L for the "off-phone XP" battle-pass version
   (needs Family Controls). Sharpest edge in the plan: the moment a tier advances by
   playing rather than living, it's a battle pass and the thesis inverts.
4. Cosmetic packs with disclosed contents ($1.99-4.99). Needs a real-money -> Wallet.grant
   path distinct from buy() (spends Yolks); must never grant Yolks or touch grantOnly. M.
5. Gift-a-sub (Finch's Guardian idea) on the friend graph. L (redemption flow). Highest
   goodwill, fast-follow not launch.
6. Glow variants/colors as the expression lever, rather than making the base glow louder.
   S-M. Making it flashy/rank-like betrays "support, not status".

## Pricing policy (decided Sep 21)

**Founding prices are kept.** $4.99/month and $34.99/year are founding prices. Anyone who
subscribes at a founding price keeps it for as long as their subscription stays active.
Price increases apply to new subscribers only.

This is now a public promise: the Product Hunt copy says "subscribe while it is and you keep
it". Two things keep it true.

**1. Every price rise preserves existing subscribers.** In App Store Connect, raising a
subscription price asks whether existing subscribers move to it. Always keep them on their
current price. The other choice breaks the promise and is not reversible for the people it
hits.

**2. The terms say so.** They currently say the opposite. Replacement for the landing site
(yolkling.com/terms, the "on price" section), in the site's own voice:

> the price is always shown in the app before you buy anything. $4.99 a month and $34.99 a
> year are founding prices, and we may raise the price for new subscribers later. if you
> subscribe at a founding price, you keep that price for as long as your subscription stays
> active, even after it goes up for everyone else. if your subscription ends and you start a
> new one later, the price at that time applies, and switching to a different plan is priced
> at that plan's current price. you will never be charged more without saying yes.

It replaces these sentences, which must come out:
- "prices can change."
- "the founding price is not guaranteed to last forever."
- "if we ever raise the price on a subscription you already have, apple will ask you to agree
  first, and if you do not agree it simply will not renew at the new price."

The two carve-outs are there because they're how Apple actually behaves: a preserved price
belongs to an active subscription to one product. A lapsed subscriber, or one who switches
from monthly to yearly, gets the current price, and a promise that ignores that would be one
you can't keep.

**Grandfathering is per product.** If you ever add a new plan, it has no founding price
unless you decide it does.

## Limited editions for real money (later)

Planned: some store items sold for real money, as limited editions. This is monetization
item 4 above and matches the original rule, sell the item, never the token. Before any ship:

- **Deterministic.** The buyer gets exactly the item shown. No randomness anywhere near money:
  no mystery boxes, no chance-based packs. The App Store description promises "no gacha, no
  loot boxes", and that has to stay true.
- **"Limited" has to be literally true.** Say what the limit is (a date, or a number) and
  honour it. Never sell a "limited" item again later. False scarcity is a consumer-protection
  problem and exactly the kind of claim App Review can call misleading.
- **Never sell or grant Yolks.** Needs its own real-money path to `Wallet.grant`, separate from
  `buy()`, which spends Yolks. Never touches `grantOnly` or the founding flair.
- **Never a species, never a wellness feature.** Cosmetics only. Same do-not-cross line as Plus.
- **Each item is a new IAP and needs App Review,** with its own review screenshot, submitted
  together with an app version. The last three rejections were partly about exactly this.

**When they ship, the App Store description must change.** It currently says "every species,
every hat, every feature is reachable without it". Once some hats cost real money, that reads
as false. Also revisit "there is one optional subscription" if other purchases exist by then.
Nothing in the launch copy blocks this: it only ever says Yolks aren't sold on their own, which
stays true.

## HAMM narrative, do-not-cross
- Never raise the stipend. Lifetime grants the same cadence or none, not a Yolk lump.
- Never gate free species behind Plus. Cosmetic seasons yes, species sets no.
- Season pass advancing by playtime = battle pass = thesis inverted. Hard guard.
