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

## HAMM narrative, do-not-cross
- Never raise the stipend. Lifetime grants the same cadence or none, not a Yolk lump.
- Never gate free species behind Plus. Cosmetic seasons yes, species sets no.
- Season pass advancing by playtime = battle pass = thesis inverted. Hard guard.
