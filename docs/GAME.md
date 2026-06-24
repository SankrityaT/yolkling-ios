# Yolkling: the game design

The whole game is one sentence: **take care of yourself, and your one-of-a-kind creature
thrives, grows, and visits the people you love.** Everything below serves that, and the
wellbeing rules in WELLBEING.md are the constitution (earn by caring, never guilt, no IAP,
social = support not status).

## The daily loop (what a good day looks like)
1. Open the app → your creature greets you, its mood reflecting how you've actually been.
2. **Check in** (mood) → sets its feeling, earns Yolks, builds a private emotional record.
3. **Focus** (phone down) → it rests and glows while you're away, earns Yolks.
4. Real life is tracked gently (HealthKit: sleep, steps, daylight, mindful minutes) → it grows.
5. Spend earned Yolks in the **closet** to make it more *yours*.
6. A friend's creature **visits**; you send a note or a little gift back.
7. Close the app and go live your life. That's the point.

## Screens (the hub + spokes)
- **Home (hub)** — built v1. Top bar (streak + Yolks), the creature (tap to pet), **today's
  care actions**, bottom nav. This is where you land.
- **Check-in** — a gentle "how are you?" (1-5 + optional note / a feeling word). Sets the
  creature's mood, earns Yolks. Light, never clinical. Builds an encrypted mood history.
- **Focus** — a phone-down timer + Live Activity; the creature rests/glows; earns Yolks on
  completion. No special entitlement (this is the honest "off your phone").
- **Closet** — built. Earn-to-own cosmetics; the open-source SVG catalog (COSMETICS.md).
- **Friends** — the social layer: your friends' creatures visit; send notes/postcards; gift
  Yolks or an accessory to someone having a hard day. No likes/followers/feeds.
- **Profile** — stats (streak, growth, mood trends you own), account, privacy/data controls,
  redeem a founder/referral code (REWARDS.md).

## Progression (what makes it feel like a game)
- **Wellbeing meter** — the creature's health, fed by your real wellness + care actions. High =
  it's thriving (happy/excited baseline); low = sleepy/low (gently, recoverable).
- **Growth / life stages** — the creature visibly grows over weeks of care (egg → little →
  grown), a slow, earned arc. Never reverts/dies; neglect just pauses growth.
- **Streak** — forgiving (Finch/Duolingo mercy). Missing a day pauses, never punishes.
- **Collection** — cosmetics + (later) species/patterns; the "make it uniquely mine" drive.

## Economy (Yolks)
- **Earned only** (no real-money IAP): check-ins, focus sessions, wellness signals, gentle
  daily showing-up, referrals + early-bird grants.
- **Spent on** cosmetics in the closet; (later) gifts to friends.
- Tuned so the 100-Yolk welcome grant is a teaser; the good stuff is earned by caring.

## Social (the moat, done kindly)
- Friend graph over Supabase + Realtime (RLS). E2E-encrypted content; server sees only the
  bare graph (to route visits), never what's inside.
- Mechanics: creature **visits**, **postcards/notes**, **gifting** Yolks/cosmetics, "thinking
  of you." A visit cheers your creature up — connection visibly helps.

## Build roadmap (in order)
1. ✅ Home hub v1, creature + expression engine, closet + economy, full onboarding.
2. **Mood check-in** — simplest, highest-impact wellbeing primitive; earns Yolks, sets mood.
3. **Focus sessions** — timer + Live Activity; earns Yolks; "off your phone."
4. **Persistence** (SwiftData) + **Sign in with Apple** — creature/outfit/wallet survive.
5. **HealthKit** signals → growth (needs the capability + signing).
6. **Social** — friends, visits, postcards, gifting (needs the Supabase backend + REWARDS.md).
7. **Profile / settings**, redeem codes, data export/delete.
8. **Screen Time** awareness tier — needs Apple's Family Controls entitlement (pursue, don't depend).

The home hub already teases the shape (today = check-in / focus / visit). Now we build each
spoke into a real feature, wellbeing-first.
