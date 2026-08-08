# What we claim, and what actually ships

The rule: we don't ship to the App Store until everything claimed on yolkling.com or in
the app actually works, or the copy gets softened. Never lie. Same policy as no fake
numbers and no fake reviews.

This file is also the **#BuildInPublic entry**, so the corrections stay in it. The
dated audits at the bottom are the trail, including the times we got it wrong in our own
favour and the times we got it wrong against ourselves. Both happen.

Legend: ✅ ships · 🟡 partial, stated honestly · ⬜ not built · ✂️ cut on purpose ·
⚠️ copy and app disagree, fix one of them

---

## Current status — audited 2026-08-08

### The creature

| Claim | Status | Detail |
|---|---|---|
| "hatch a one of a kind creature" | ✅ | Parametric, code-only. No image assets anywhere in the app. |
| "912 species" | ✅ | **203 hand-named** standard species across celestial (48), garden (55), ocean (40) and cozy (60), plus **16 founding**, all rendered in code through the live `YolklingView`. The 900+ figure is combinatorial: ~46 top features × 26 body patterns × the palette set. Both numbers are real; the named count is the one to quote when someone asks a hard question. |
| "tell it your vibe, three silly questions" | ✅ | Built. Three questions that hand you a creature, with "i'd rather just pick" as an escape hatch to the grid. This line was ⚠️ for months. |
| "the faces it makes" | ✅ | 14 moods/expressions, asymmetric breathing, irregular blink, secondary motion on hats and limbs. |

### Raise it by living

| Claim | Status | Detail |
|---|---|---|
| steps and sleep feed the creature | ✅ | HealthKit reads both. |
| "doomscroll → sleepy" / phone time | ⬜ | **Gated on Apple's Family Controls entitlement**, requested 2026-08-08, 2 to 4 week approval. Ships as a post-launch update. `ScreenTimeService` is a stub returning `available == false`; `HomeView.livingStatSoon` renders the locked placeholder honestly. |
| "the only app that wants you off your phone" | 🟡 | Focus sessions deliver this today. The full claim needs the Screen Time half. **Do not market the strong version yet.** |
| the trust arc | ✅ | Trust rises only from caring for *yourself* (check-in, grow-by-living), never from petting. Decays with neglect, floored at 0.12 so it can't hit zero. |

### Social

| Claim | Status | Detail |
|---|---|---|
| "it wanders off, brings back a postcard" | ✅ | `WanderArrival`. Once a day, on first open. **Honest caveat:** it rolls on app open, not a server cron, so "while you were away" is true from the player's side but there is no background job. It never fabricates a note from someone who didn't write one. The postcard is a picture of a real room your creature really visited. |
| friend visits + postcards | ✅ | One snapshot-driven view serves friends and strangers. Postcards are composed by SELECTION from a server-validated vocabulary, never free text (Guideline 1.2). |
| "your friends' yolklings come over" | ✅ | Real waves, visits and redecorations from the server. |
| gifting | ✅ | Friends 10/20/50, strangers a fixed 10 once a day. **Sender always pays**, which is what makes alt-account farming net-negative. |
| founding-flock referral | ✅ | Shipped and verified live. Credits both parties, one-time, server-validated. 16 grant-only limited editions. |
| block and report | ✅ | Reachable from the place you meet a stranger, not buried in settings. |

### Trading

| Claim | Status | Detail |
|---|---|---|
| "swap a spare with a friend" | ✅ | **Built. This was previously ✂️ cut and the promise removed from the site; it has since shipped and the copy is back** (yolkling-app PR #1, merged 2026-08-08). Friends only, both sides accept, nothing moves until they do. |
| the creature you made is not tradeable | ✅ | Enforced in the database, not promised. Its colour, pattern, look and room are part of the creature. What travels is the costume. |
| trade species cards | ⬜ | Designed. Needs server-side species ownership rows that don't exist. When it lands, "met" and "held" become two different numbers. |

### The store

| Claim | Status | Detail |
|---|---|---|
| "a little shop of hats, rooms and rare colours" | ✅ | **88 cosmetics**, **17 room themes**, **34 decor pieces**, **21 colour swatches** (15 rare, 6 epic). All three halves of the claim now ship. Rooms and rare colours were marked ⬜ here for months after they were built. |
| "earn coins just by living well" | 🟡 | Check-in and focus sessions ✅. Real wellness signals are the Screen Time gap above. |
| "no gacha, no loot boxes, no tricks" | ✅ | Cash never touches a random roll. Randomness sits only behind packs you *earn*. |
| rarity is found, finish is bought | ✅ *(rule)* / ⬜ *(shop)* | The rule is settled and enforced by design: money never changes what a card *is*. The finish shop itself is not built. |
| seasons | ✅ | Machinery ships and is server-flippable without a build. One spring set of 6 grant-only cosmetics exists. More art does not. |

### Cards

| Claim | Status | Detail |
|---|---|---|
| holo cards, rarity as material | ✅ *(built)* / ⬜ *(reachable)* | Real and verified: 3D tilt off the gyroscope, foil that lags the card, six laminates picked by rarity, all drawn in code. **Not wired into any screen a user can reach** — dev seam only. Video of it is honest; "open the app and tilt your card" is not, yet. |
| the crack-and-flip pack reveal | ⬜ | Designed. The current reveal is a wiggling egg. |

### Money and privacy

| Claim | Status | Detail |
|---|---|---|
| "free to hatch. always will be." | ✅ | No paywall on hatching. |
| ~~"no real-money IAP"~~ | ⚠️ **corrected** | **This was true and is now false.** Yolkling Plus is a real subscription through RevenueCat. The accurate claim is narrower and better: **we sell a subscription and cosmetics. We do not sell Yolks.** |
| Yolks are not purchasable | ✅ | Deliberate. We adopted RevenueCat's virtual currency system specifically in order *not* to sell currency, so their ledger records exactly the Yolks that came from money and Supabase records the ones that came from living. An engaged free player out-earns a subscriber roughly 3.4×. |
| what Plus actually gives you | ✅ | Three things, and the paywall lists exactly these three: a supporter glow, a monthly handful of Yolks, and "you keep this alive, no ads ever". **Note:** an earlier entry in this file claimed the paywall also said "every season included". It does not, and did not. Corrected. |
| cloud backup | ✅ | **Built. Previously listed here as "never built, removed from the site" — that was accurate when written and is now wrong.** `PlayerBackup` + `docs/sql/backup.sql`. It is **free for anyone signed in with Apple, not a Plus perk**, which is why it is correctly absent from the paywall. It could honestly go back on the site as a free feature. |
| "no ads, data stays yours, no creepy tracking" | ✅ | Local-first SwiftData, no ads, no analytics SDK, no tracking. |
| ~~"end to end encrypted"~~ | ✂️ | Removed from the app. The crypto layer isn't built, so the sign-in screen no longer says it does. |
| account deletion | ✅ | Guideline 5.1.1(v). Server rows cascade, local store wipes, install id resets. |

---

## Gaps that still block launch

1. **Nothing.** The blocking list is empty for the first time. What remains is either
   entitlement-gated (Screen Time), deliberately post-launch, or not-yet-reachable
   polish (cards).
2. Before submitting, walk this table and confirm every line of live marketing copy maps
   to a ✅. Anything else gets softened or cut.

## Not blocking, but stated so nobody markets it early

- Screen Time / phone-time signals (entitlement pending)
- "two minutes a day" as a positioning line (drift and stranger gifting are genuinely
  capped; trading and packs are not yet)
- Holo cards being user-reachable
- Species-card trading, and "met" vs "held"
- The crack-and-flip pack reveal
- The card finish shop

---

## Audit log

### 2026-08-08 — the two-way audit

First audit that corrected claims in **both** directions, which is the point of keeping
this file rather than a launch checklist.

Understated (built, still marked not-built here):
- rooms in the shop, and rare/seasonal colours. 17 themes, 34 decor, 21 swatches.
- cloud backup. Listed as "never built, removed from the site."
- trading. Listed as ✂️ cut, with the promise removed from yolkling.com. It shipped, and
  the removal was still sitting unmerged in PR #1 where it would have deleted a true
  claim. Fixed before merge.

Overstated:
- "no real-money IAP", twice. Plus is a real subscription.
- "the Plus tier lists a supporter glow, a monthly handful of Yolks, and every season
  included." The third one was never in the paywall.

Also this session: an ownership audit found trading was **duplicating items across
accounts** (the client never observed the server's deletion, so the next push re-inserted
it), and that `is_tradeable` was a blocklist permissive enough that the colour of your
creature's face was tradeable. Both fixed. Neither was ever a marketing claim, but a
"here is a bug I found in my own app" post is more honest content than most launch copy.

### 2026-08-07 — landing page audit

Checked the LIVE site (`yolkling-app`, Next.js) rather than the stale local copy, and
found it selling two things the app did not do:

- ✂️ **"extra creatures"** — never built. Removed from the site and from the in-app
  paywall (Guideline 3.1.2: selling unimplemented functionality).
- ✂️ **"cloud backup, it can't truly die"** — not built *at the time*. Same treatment.
  Since built; see above.

**Note for future audits:** `/Users/sankiii/yolkling/` is a STALE static copy, roughly
half the size of the live site. The real source is the `yolkling-app` repo. Auditing the
local folder would have missed all of the above.

### Earlier — the social layer

Four rows that had been ⬜ closed at once: the wander, friend visits, postcards, and
"your friends' yolklings come over". Before that the social layer was the single biggest
gap between the landing page and the app.
