# What the landing page promises, and how the app delivers each

The rule: we don't ship to the App Store until everything claimed on yolkling.com
actually works, or the copy gets softened. Never lie (same as: no fake numbers, no
fake reviews). Status legend: ✅ done · 🟡 partial · ⬜ not built · ⚠️ copy diverged.

## the creature
- ✅ "hatch a one of a kind creature" — onboarding hatch (pick colour + look → bouncy reveal). Parametric, code-only.
- 🟡 "your colours, the faces it makes, your particular brand of weird" — colours + 4 looks + 14 moods/expressions done. A deterministic 1-of-1 seed / more parts: not yet.
- ⚠️ "tell it your vibe — three silly questions, or it watches how you type" — **we changed this to direct colour + look selection.** Either add a vibe step back, or update the landing copy. Right now the page promises something the app doesn't do.
- ✅ "912 species. yours is just the first." — real taxonomy shipped: ~46 top features x 26 body patterns x the palette set clears 900+ combinatorially, with 219 hand-named species across 5 families (celestial, garden, ocean, cozy, founding) rendered in code through the live YolklingView. See docs/species/*.md + Core/Creature/Species*.swift.

## the four tiny steps to a friend for life
1. ⚠️ "tell it your vibe" — see above (now direct selection).
2. ✅ "it hatches" — the reveal, with haptics.
3. 🟡 "raise it by living (sleep, water, sunlight, texting people back; doomscroll → sleepy)" — **mood check-in + focus sessions are in, but the creature does NOT yet react to real wellness signals.** HealthKit (sleep/steps/daylight) → growth is not wired; doomscroll → sleepy needs Family Controls. This is the core promise and it's the biggest gap.
4. ⬜ "it wanders off — visits a friend's, makes a mess, brings back gossip → a postcard" — **the friend-visiting / postcard social layer is NOT built.** (The thing you just flagged.)

## the twist
- 🟡 "the only app that wants you off your phone" — focus sessions deliver this. But "doomscroll → sleepy, go outside/sleep/drink water → it lights up" needs real HealthKit + Screen Time signals, not built yet.

## social
- ⬜ "your friends' yolklings come over to play / gifts / nonsense while you sleep / postcards" — **not built.** The friend graph + visits + gifting + postcards.
- ✅ "founding-flock referral (invite a friend → you both get a founding species)" — **shipped + verified live.** Referral credits both parties; `redeem_code` grants a founding species (founder code → 1; referral → 1 to BOTH the friend and the referrer), recorded in `inventory`, one-time, server-validated. The client reveals it (cozy sheet) and lets you wear it. 16 grant-only limited editions (auras, halos, iridescent bodies, gem crests). See docs/species/founding.md + docs/sql/founding_grant.sql.

## the store
- 🟡 "a little shop of hats, rooms and rare colours" — hats/glasses/neckwear closet is **done** (earn-to-own). Rooms ⬜, rare/seasonal colours ⬜.
- 🟡 "earn coins just by living well" — earn Yolks from check-in + focus (done); from real wellness signals (not yet).
- ⬜ "trade your spare ones with friends" — trading not built.
- ✅ "no gacha, no loot boxes, no tricks" — earn-based economy, no randomised purchases, no real-money IAP.

## pricing / honesty
- ✅ "free to hatch. always will be." — no paywall on hatching, no real-money IAP.
- 🟡 "no ads, data stays yours, private by design, no creepy tracking" — local-first (SwiftData), no ads, no tracking ✅. **E2E encryption for content is not implemented yet** (Core/Crypto). Privacy is committed; the E2E claim needs the crypto layer.
- ✅ "made by one person" — true.

## the gaps to close before launch (priority)
1. **Friend visits + postcards** (social layer) — the "wanders off to friends" promise + the #1 retention lever.
2. **Raise it by living** — wire real HealthKit signals (sleep/steps/daylight) → growth/mood, so the creature reflects real life (not just manual check-in).
3. **Fix the diverged copy**: the "three silly questions" onboarding line.
4. **E2E encryption** for synced content.
5. **Store**: rooms, rare/seasonal colours, trading.

## pre-launch gate
Before the App Store, walk this list and confirm every line of marketing copy maps to
a shipped, working feature. Any claim that can't ship gets the copy softened or cut.
The landing page and the app never disagree.

---

## Update — the social layer is built

The four ⬜ rows above are now closed:

- ✅ **"it wanders off — visits a friend's, brings back a postcard"** — `WanderArrival`. Once
  a day, on first open, your yolkling lands in a stranger's open room by itself and brings
  back a postcard OF that room. Honest caveat: it rolls on app open, not from a server
  cron, so "while you were away" is true from the player's side but there is no background
  job. **It never fabricates a note from a real person who didn't write one** — the
  postcard is a picture of a real room your creature really visited.
- ✅ **friend visits + postcards** — `VisitView` serves friends and strangers from one
  snapshot-driven view; postcards are composed by SELECTION from a server-validated
  vocabulary, never free text.
- ✅ **"your friends' yolklings come over"** — `WhileYouWereAwayStrip` shows real waves,
  visits and redecorations from the server.
- ✅ **gifting** — friends 10/20/50, strangers a fixed 10 once a day, sender always pays.

Still open, and stated plainly:

- ⬜ **"raise it by living"** — HealthKit reads steps and sleep today; Screen Time is
  gated on Apple's Family Controls entitlement and ships as a post-launch update.
- ⬜ **trading** — not built.
- ⬜ **rooms and rare/seasonal colours in the shop** — seasons ship the machinery; the
  extra art does not exist yet.
- ⚠️ **"three silly questions" onboarding** — the app still uses direct colour + look
  selection. The landing page copy needs softening, or the step needs building.
- ✅ **"end to end encrypted"** — this claim was REMOVED from the app. The crypto layer
  isn't built, so the sign-in screen no longer says it does.
