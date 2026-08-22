# Yolkling — full context

A handover briefing. Written 2026-08-22. Everything below is either verified against
the code or explicitly flagged as unverified.

---

## What it is

> Yolkling is a virtual pet that grows when you take care of yourself in real life.
> Your steps, sleep, and time off your phone feed your yolk, and you collect new
> yolks and dress them up.

That one-liner is locked (`docs/PITCH.md`) and should be used verbatim.

The premise underneath it: people struggle to do healthy things for themselves but will
reliably do them for something that depends on them. Yolkling borrows that motivation
without the shame that streak-obsessed habit apps carry. Its trust mechanic rises **only**
from self-care (check-ins, steps, sleep) and never from petting the creature, which is the
whole design argument in one rule.

Positioning line: *"the only app that wants you off your phone."* Currently a claim rather
than a measurement (see Unverified, below).

## Status

- **Unreleased.** iOS only, pre-submission, targeting App Store launch.
- Entered in **RevenueCat Shipaton 2026** (Aug 1 to Sep 30, 2026).
- ~22,000 lines of Swift across 130 files, 54 tests passing.
- Four build targets: the app, a widget extension, a Screen Time report extension, tests.
- iOS 18 minimum. Swift 6, `MainActor` default isolation.

## Stack

| Layer | Choice |
|---|---|
| UI | SwiftUI, iOS 18+ |
| Local data | SwiftData (`Player` is the single `@Model`) |
| Backend | Supabase, hand-rolled `SupabaseClient`, all access via SECURITY DEFINER RPCs |
| Payments | RevenueCat 5.83.1 (entitlement `Yolkling Plus`, virtual currency `YLK`) |
| Health | HealthKit (steps, sleep) |
| Screen Time | FamilyControls + DeviceActivityReport extension |
| Project | **xcodegen** — `project.yml` is the source of truth, `.pbxproj` is generated |

**Everything visual is drawn in code.** No image assets, no AI art. The creature, all
species, the room, the card foils, every icon. This is a genuine differentiator and is
marketed as one, so introducing image assets (Lottie, Rive, exported SVG) would cost a
claim that is currently true.

## The creature

Built from primitives rather than assets:

- **Vibe** = colour + accent + pattern + `CreatureStyle` (58 base looks)
- **YolkExpression** = a pose (eyes, mouth, brow, bounce, particles). Expressions lerp,
  so any mood change morphs cleanly.
- **YolkMotion** = all idle motion derived from a single time value `t`, so a given `t`
  always produces the same frame. This is what makes `frozenAt:` work for the widget,
  share cards and snapshot tests.
- Secondary motion: arms, feet and hats trail the body and settle past it.

**6 Dex sets, 32 species in the Dex.** (The App Store listing claims 219 named species
across five families; I have not independently verified that number.)

## The daily loop

1. **Check in** — pick a mood once a day, earns Yolks, moves trust
2. **Focus session** — put the phone down, Live Activity on the lock screen, earns Yolks
3. **Grow by living** — steps and sleep from HealthKit, plus time off phone from Screen Time
4. **Visit** — your creature wanders to a stranger's room once a day and brings back a postcard
5. **Collect** — species discovery, a Dex, holo trading cards

Everything is capped daily on purpose. One check-in, one drift, one pack. The cap is the
retention mechanic, not a cost: Wordle is one puzzle a day. Session length is worth nothing
here because there are no ads.

## Economy and monetization

**Yolks** are the only currency. Earned by living well. **Never purchasable at any price.**
That is load-bearing, not incidental: RevenueCat's virtual currency system was adopted
specifically *in order not to sell currency*, so their ledger records exactly the Yolks that
came from money and Supabase records the ones that came from living.

**Yolkling Plus** — auto-renewing subscription, `com.yolkling.ios.plus.monthly`, $4.99/mo
(a founding price). An annual is planned at ~$34.99. It grants:
- a supporter glow on the creature
- a small monthly Yolks stipend (400)
- no ads (there are none anyway)

**It gates nothing.** Every species, cosmetic and feature is reachable free. The only thing
money buys that cannot be earned is the glow.

Rules that must not be broken:
- **Cash never touches randomness.** No gacha, no loot boxes. Randomness only sits behind
  packs the player earns.
- **Rarity is found, finish is bought.** Money buys presentation, never what a card *is*.
- **The bond card's finish comes from trust**, which only rises from self-care and decays.
  So the best-looking card in the app has no price on it.

Comparable: **Finch** does $30M ARR at $9.99/mo or $69.99/yr, with the same shape (free core
loop, one supporter-visible exclusive).

## Social

Friends only, never strangers-as-contacts. Add by share code or QR. Friends' creatures
visit each other's rooms, send postcards from a **fixed vocabulary** (so there is no free
text to moderate), wave, gift, and trade cosmetics.

**The creature you made is not tradeable.** Colour, pattern, look and room are part of that
creature and cannot be lost. Only the costume travels. This is enforced in the database by
an allowlist (`docs/sql/tradeable_items.sql`), not by client-side promises.

## Backend

Supabase project `vlucekvrdxvpkvbizabz`. 15 SQL files in `docs/sql/`, all applied. Every
table is RLS-locked and reachable only through SECURITY DEFINER functions keyed on a text
user id. A `pg_cron` job rolls the nightly wander at 04:00.

## Where things are, App Store side

- Team **94277H98XP** (a friend's account; the founder cannot receive app revenue)
- Bundle IDs: `com.yolkling.ios`, `.Widgets`, `.ScreenTimeReport`, group `group.com.yolkling.ios`
- App record created as **"Yolkling: Grow by Living"** (the bare name is held by an
  abandoned record on the old account that Apple will not delete)
- **Blocked on:** Paid Applications Agreement + banking, the Family Controls distribution
  entitlement (2 to 4 weeks, filed), and Xcode signing access to the team

## The rules this project holds itself to

From `docs/CONVENTIONS.md` and hard experience:

- **No em dashes in user-facing copy.**
- Verification is `xcodebuild` plus screenshots, never assertion. If it has not been
  rendered and looked at, it is not verified.
- **Check the iPhone SE.** Text that fits on a Pro Max truncates at 375pt, repeatedly.
- SwiftData `@Model` changes must be optional or defaulted.
- `Core/DesignSystem` compiles into the widget; `Core/Haptics` does not. Design primitives
  must never call Haptics.
- SourceKit cross-file "cannot find type" errors are stale-index noise. Trust xcodebuild.
- Never start anyone at zero. The streak pill says "day one", not "0 days".

## Unverified, and treated as unverified

These are written and shipped but have **never executed on real hardware**:

- **The card's gyroscope tilt.** `CardTilt` guards on `isDeviceMotionAvailable`, false in
  the simulator, so every check so far used the touch-drag fallback. "Turns toward your
  phone's tilt" is the strongest marketing line and the least proven thing in the app.
- **Every haptic.** The simulator has no Taptic Engine.
- **Screen Time.** FamilyControls does not run in the simulator at all, and needs Apple's
  entitlement approval.

`CLAIMS.md` is the live ledger of what is true. It is maintained honestly, including
admissions, and should be read before writing any marketing copy.
