# Rewards + Referrals (waitlist early-birds, referral program, in-app economy)

Captured because our memory server was offline when this came up. Confirm the
TBD specifics before building.

## The two mechanics
1. **Early waitlist users get something free** (coins or a free accessory) when they join the app.
2. **Referrals**: each referrer gets in-app coins or a free accessory per successful referral; the new user gets a welcome bonus.

## The core problem: identity matching
App users sign in with **Sign in with Apple**, which often returns a **Hide My Email** relay address, not their real email. The waitlist is keyed on the email they typed on the website. So we **cannot reliably match an app user to their waitlist entry by email.**

## The solution: redeem codes (one system does both)
- Every **waitlist signup** gets a unique **code** (e.g. `YOLK-7K2P`), included in their welcome email ("your founder code").
- Every **app user** also gets their own code to share = their **referral code**.
- In the app, after hatching, a **"Have a code?"** step: enter a code →
  - if it's a waitlist/founder code → grant the **early-bird reward**, mark claimed (one-time).
  - if it's another user's referral code → grant the **new user** a welcome bonus AND credit the **referrer** (coins or accessory).
- Redemption is **one-time per user**, validated server-side.

## DB schema (additive — never drop the existing waitlist)
- `waitlist` (exists): + `referral_code` (unique), + `cohort`/`is_early` flag, + `claimed_by` (app user id, nullable), + `claimed_at`.
- `app_users`: `apple_user_id` (pk), `referral_code` (unique, theirs to share), `referred_by` (code), `coins` (int), `created_at`.
- `inventory`: `user_id`, `item_id` (accessory), `source` (`waitlist`|`referral`|`purchase`|`gift`), `granted_at`.
- `redemptions`: `code`, `redeemed_by` (user id), `redeemed_at` — enforces one-time use.
- A `SECURITY DEFINER` Postgres function `redeem_code(code, user_id)` that validates, grants atomically, marks claimed, returns the reward. RLS: users read only their own rows.

## App economy (needed so rewards have something to land on)
- **Coins** wallet + **inventory** of cosmetics, SwiftData local + Supabase sync (server authoritative for balances/grants).
- **Cosmetics = a worn-accessory layer** on the creature (hat, bow, glasses, scarf), rendered in code on top of the body — separate from the base `CreatureStyle` look. This is also the seed of the gentle cosmetics shop.

## Sequencing
- **Buildable now (no DB access needed):** the worn-accessory cosmetic layer + coins wallet + inventory models + a "redeem a code" screen (stubbed grant until backend is live).
- **Needs the waitlist Supabase account connected (or run the SQL by hand):** code generation for existing waitlist rows, the `redeem_code` function, referral attribution.

## Earning + pacing (so people can speed up without paying)

The tension: Yolks are earned by self-care, which is paced (slow by design), but it
must never feel like an endless wait. "Speeding up" means doing more good or bringing
friends, NEVER paying to skip. Three dials plus one hard line.

**Dial 1, faucets (how many ways to earn).** The more self-care actions exist, the
faster an engaged person earns. A power user who does five healthy things a day out-
earns a casual one five to one. The accelerator and the mission are the same thing.
- live: check-in (+10/day), focus session (+20/day, capped 60/day).
- planned: water, sleep (HealthKit), journal, breathe, a daily quest.
- planned, on-mission: a KIND NOTE to a friend (small, ~+5, lands with friend
  visits #17). Rewarding kindness itself, the warm-glow lever. Kept ungameable:
  reward the SENDER not the receiver (so two friends cannot spam each other), cap
  at a couple rewarded notes a day, one per friend per day, real friends only. The
  reward is small on purpose, the kindness is the point.

**Dial 2, rate + bonuses (how much each pays).** Consistency compounds.
- streak milestones (built): day 3 +20, 7 +50, 14 +100, 30 +250, 60 +400, 100 +750.
- weekly challenge (built): care 5 days this week, +100 Yolks. Resets weekly.
- referral (built): both sides get Yolks, social acceleration.

**Dial 3, sinks + pacing (what things cost + how close the next goal is).** Tune so
there is ALWAYS something a few days away. The welcome grant (100) plus the first
check-ins should put a first cheap cosmetic in reach within days. The collection is
the cushion: every check-in hands a free new creature regardless of coins, so nobody
is ever empty-handed while saving.

**The hard line.** You speed up by doing more, or inviting a friend. You never buy
coins. If money ever enters (only if users ask), it buys a SPECIFIC named cosmetic,
never coins, never a faster grind. No selling Yolks, no rewarded ads, no energy/timer
gates that make you wait to play.

## TBD (confirm)
- Early-bird reward: how many coins, or which specific free accessory?
- Referral reward: coins amount vs a free accessory? Per referral, with a cap?
- "Early" = everyone currently on the waitlist (pre-launch), the first N, or before a date?
- Landing-page referral capture (so website shares attribute) — in scope now or later?
