# Landing claims vs the app (audit)

Every concrete promise on yolkling.com (`yolkling-app/app/body.ts`) checked against
what the app actually does as of this audit. Legend:

- ✅ works as said
- 🟡 partial / works differently than the words imply
- ❌ claimed, not built
- 🎨 stylized copy (poetic, never meant literally)

## Hero
| Claim | Status | Reality |
| --- | --- | --- |
| "hatch a one of a kind creature from your vibe" | ✅ | Onboarding hatches a unique creature (colour + style + pattern). |
| "grows a little every time you take care of yourself" | ✅ | HealthKit steps + sleep feed it (living bonus), check-ins earn, and vitality changes its look. |
| "toddles off to visit your friends when you're not looking" | 🟡 | Friend visits exist, but YOU tap to visit; no autonomous wandering. |

## How it works (the four cards)
| Claim | Status | Reality |
| --- | --- | --- |
| 01 "answer three silly questions, hum a song, or let it watch how you type" | 🟡🎨 | You pick a vibe via choices in onboarding. No literal three questions, humming, or typing analysis. |
| 02 "out pops a creature that exists exactly once" | ✅ | Unique hatched creature. |
| 03 "raise it by living: sleep, water, sunlight, texting back. doomscroll at 2am -> sleepy" | 🟡 | Steps + sleep ✅ live; low day -> visibly sleepy ✅ (vitality). Water / sunlight / texting-back are NOT tracked. "Doomscroll -> sleepy" needs Screen Time, which is STUBBED, not live. |
| 04 "wanders into a friend's house, makes a mess, brings back gossip, you get a postcard" | 🟡 | Visits + postcards ✅, but postcards are sent by you, not auto-generated; no autonomous wandering / mess / gossip. |

## Statement / Friends / Collection
| Claim | Status | Reality |
| --- | --- | --- |
| "the only app that wants you to put your phone down" | 🟡 | The intent + the sleepy-on-low-day cue are there, but phone-time tracking (Screen Time) is STUBBED. Not measured yet. |
| "your friends' yolklings come over to play" | 🟡 | You can visit a friend's room and they see yours (published snapshot). No live co-presence. |
| "912 species. yours is just the first." | 🟡 | 912 is a combinatorial / possibility claim backed by palettes. The app ships a curated set of named species + "the rest are out there to find." Not 912 distinct hand-made creatures. |

## Store
| Claim | Status | Reality |
| --- | --- | --- |
| "a little shop of hats, rooms and rare colours" | ✅ | Cosmetics shop, room themes + 34 decor, 20 rare colours all shipped. |
| "earns coins just by you living well; spend on outfits, tiny rooms, seasonal looks" | 🟡 | Earn via living + check-ins, spend on outfits + rooms ✅. "Seasonal looks" = limited founding species; no seasonal cosmetic rotation. |
| "outfits... and trade your spare ones with friends" | ❌ | Dress / mix / collect ✅. Trading with friends NOT built. |
| "little rooms... show off when a friend's yolkling comes to visit" | ✅ | Rooms + decorate, and friends see it on visit. |
| "rare and seasonal... earn them, or chip in a couple bucks to grab one" | 🟡❌ | Rare colours ✅, limited founding species ✅ (grant-only). "Chip in a couple bucks" (IAP) NOT built. "Only appear for a while" (timed rotation) not enforced. |
| "no gacha, no loot boxes, no tricks" | ✅ | True. Everything is earned. |

## Pricing
| Claim | Status | Reality |
| --- | --- | --- |
| FREE: 1 creature, grows with habits, friend visits, private by design | ✅ | All true. |
| YOLKLING+ "a few $": extra creatures, outfits/rooms/colours, seasonal species, cloud backup | ❌🟡 | No IAP, no extra creatures (single creature). Outfits/rooms/colours exist but are free. Cloud backup = wallet sync on Apple sign-in (partial, just built). |
| FRIENDS: shared village, trade and gift cosmetics, it remembers everyone | 🟡❌ | Friends + visits ✅. Trade / gift NOT built. |

## Plumbing
| Claim | Status | Reality |
| --- | --- | --- |
| Waitlist email | ✅ | `/api/waitlist` works (landing). |
| Feedback form | ✅ | `app_feedback` backend works. |

## The real gaps (claimed, not built)
1. **Trade / gift cosmetics between friends** — promised three times (store, pricing FRIENDS). Not built.
2. **IAP / "a few dollars" / YOLKLING+ / extra creatures** — intentionally deferred (no-IAP stance). The landing implies you can pay; the app has no purchases.
3. **Screen Time / "put your phone down"** — stubbed, not live (needs the Family Controls entitlement).
4. **912 species as a literal count** — it's combinatorial, not 912 hand-made.
5. **Onboarding "three questions / hum / typing"** — copy divergence from the real vibe picker.
6. **Autonomous wandering / auto-postcards** — visits + notes are manual.
7. **Water / sunlight / texting-back as inputs** — only steps + sleep are tracked.

## Two honest options for each gap
Either **build it** (trade/gift is the most-promised and most buildable) or **soften the copy** so the page matches the app (especially the IAP lines, "three questions", "912", and "when you're not looking"). The no-IAP gap in particular: the page sells a paid tier the app doesn't have.
