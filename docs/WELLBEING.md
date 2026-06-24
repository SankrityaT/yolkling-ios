# Wellbeing + social: the mission, and how the mechanics serve it

The north star: **Yolkling should measurably help your mental health and your real
friendships — not be a cute dress-up game with wellbeing as a coat of paint.** Every
mechanic below must route back to that. If a feature can't, it doesn't ship.

## The core principle: the growth loop IS a wellbeing loop
You don't grind or pay for Yolks. You **earn them by genuinely taking care of yourself.**
- Finish a phone-down **focus session** → Yolks.
- A gentle daily **mood check-in** → Yolks (and it sets your creature's state).
- Real **wellness signals** (HealthKit: sleep, steps, daylight, mindful minutes) → Yolks + the creature thrives.
- A **gratitude / reflection** note → Yolks.
- Showing up at all (a **forgiving** streak, Finch-style) → small Yolks.

So customizing your creature is a *reward for caring for yourself*. The cosmetics economy
is the carrot for wellbeing, never a money sink. This is also why there's **no real-money
IAP**: Yolks are earned, full stop. (Optional far-future: one transparent "supporter tip,"
or cause cosmetics whose proceeds go to mental-health orgs. Never pay-to-win, never gacha.)

## The creature as a gentle mirror (self-awareness + regulation)
- It reflects your real state — sleepy when you're up late, low when you've been running on
  empty. Externalizing emotion onto a character is a recognized regulation aid.
- Caring for it is a low-stakes proxy for caring for yourself (Finch model).
- **Never guilt.** Neglect = "waiting," not "sad/dying" (see 07-creature-expression §6).
  It always recovers warmly the moment you return.

## Social = support, not status
The anti-doomscroll social layer. **No likes, no followers, no public feed, no counts.**
- Friends' creatures **visit** yours; you send yours to **check on** a friend.
- Send a warm **note / postcard** — "thinking of you," a little nudge.
- **Gift** Yolks or an accessory to a friend having a hard day (prosocial giving lifts the
  giver's mood too).
- A friend's visit **cheers your creature up** — connection visibly helps.
- Everything is small, private (E2E), opt-in acts of care between real friends.

## Anti-engagement by design (the honest moat)
The product literally wants you to **put the phone down, sleep, go outside.** Incentives are
inverted from typical engagement apps:
- Forgiving streaks, never punishing. Miss a day → the creature waits, never shames.
- Honest empty states (HealthKit read-status is opaque — never bluff a "connected ✓").
- **Provisional** notifications, or contextual asks — never a cold launch prompt or nag loop.
- No dark patterns anywhere (we already build the over-budget moment as an *encouragement*).

## Safety + responsibility
- Mood check-ins stay supportive, never clinical over-claim (we are not therapy).
- If check-ins signal real distress, gently surface real resources (988 / Crisis Text Line).
- Privacy as a trust asset: Sign in with Apple + E2E so emotional data is genuinely safe;
  say so plainly at the Health ask (we already do).

## What this means for the build order
1. **Mood check-in** (daily, gentle) — the simplest, highest-impact wellbeing primitive; it
   feeds creature state AND earns Yolks. Build first.
2. **Focus sessions** (phone-down timer + Live Activity) — "off your phone," earns Yolks, no
   special entitlement. The honest core of "thrives when you put your phone down."
3. **HealthKit signals** — sleep/steps/daylight/mindful → growth + Yolks (needs capability).
4. **Social** — friend graph, visits, postcards, gifting (needs the Supabase backend).
5. **Screen Time monitoring** (passive doomscroll awareness) — tier 3, needs Apple's
   **Family Controls entitlement** (gated approval). Pursue, never depend on it.

The onboarding now teaches exactly this arc: *grows from how you live → thrives when you put
the phone down → visits your friends.* The mechanics just have to deliver on that promise.
