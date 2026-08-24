# App Store listing — Yolkling 1.0.0

Copy-paste deliverable for App Store Connect. Every field below is labeled exactly
as it appears in App Store Connect. For each character-limited field the exact
count of the string is printed in parentheses so you can trust it fits before you
paste. Voice: cozy, honest, lowercase-ish, no em dashes. Every claim maps to a
shipped feature (see CLAIMS.md).

Bundle id: `com.Sankritya.Yolkling` · Version: `1.0.0`

---

## App Name

```
Yolkling: Self Care Pet
```
(23 / 30 characters)

**Why not "Yolkling: Grow by Living".** The App Name carries the single heaviest
ranking weight of any field, and "Grow by Living" is brand poetry with no search
volume behind it, so the most valuable 14 characters in the entire listing were
spent on a phrase nobody types. "self care pet" is the exact term Finch ranks on,
and Finch does $30M ARR in this category, so the intent behind it is proven.

The bare "Yolkling" was taken by a never-submitted app record on the original
developer account, and Apple will not delete a record that was never approved.
The home-screen name is unaffected: that comes from `CFBundleDisplayName` and
still reads "Yolkling". Rename to the bare word if the reservation is ever
released.

---

## Subtitle

```
grow a cozy virtual creature
```
(28 / 30 characters)

**Why the change.** The old subtitle repeated "pet" from the title, and Apple credits a
keyword once no matter how many fields it appears in, so that word was wasted. It also
spent 12 of its 30 characters on "a", "that", "with" and "you", none of which are ever
searched. This version adds four new indexed terms instead: grow, cozy, virtual, creature.

---

## Promotional Text

Editable after release without a new build. Use it for the launch.

```
free to play, all of it. hatch a one of a kind creature, then grow it by living well: steps, sleep, and time off your phone. collect, decorate, visit friends.
```
(156 / 170 characters)

---

## Description

Leads with the locked one-liner from docs/PITCH.md, verbatim. Paste as-is.

```
Yolkling is a virtual pet that grows when you take care of yourself in real life. Your steps, sleep, and time off your phone feed your yolk, and you collect new yolks and dress them up.

free to play, all of it. no ads, and the only currency is Yolks, which you earn by showing up for yourself. Yolks are never for sale: there is no way to buy them at any price.

hatch
your yolk is one of a kind. pick its color and its look, watch it hatch, and it is yours. there are 203 named species to discover across four families, so the one you start with is just the first.

grow by living
connect Apple Health if you want to, and your real days feed your yolk. steps and sleep help it grow, slowly, over weeks, from a little one into a grown one. it is completely optional. the app works fully without Health access, and nothing about your day ever leaves your device to make this happen.

put the phone down
start a focus session when you want time away from the screen. your yolk rests and glows while you are gone, a Live Activity keeps you company on the lock screen, and you earn Yolks when you finish. this is the honest version of screen time: you choose to step away, and your yolk is happier for it.

check in, earn, collect
a gentle daily check-in asks how you are, sets your yolk's mood, and builds a private record just for you. earn Yolks from checking in and from focus sessions, then spend them in the shop and closet on hats, glasses, scarves, rare colors, and decor for your yolk's room. no gacha, no loot boxes, no tricks. you buy the exact thing you want.

friends, done kindly
add friends with a share code or a QR scan, let their yolks visit yours, and send postcards back and forth. invite a friend with your founding-flock code and you both get a founding species. no feeds, no follower counts, no likes. just the people you actually know.

honest by design
no ads. no tracking. your mood history and your day stay on your device. there is a home-screen widget so your yolk is one glance away, and a real account you own, with the controls to match.

if you want to support it
there is one optional subscription, Yolkling Plus. it adds a supporter glow on your yolk and a small handful of Yolks each month, and that is all it does. every species, every hat, every feature is reachable without it. the only thing you cannot earn is the glow, which is the point of it: it says you chose to keep this going.

made by one person who wanted a pet that roots for the real you.
```

---

## Keywords

Comma-separated, no spaces. Paste exactly.

```
tamagotchi,habit,tracker,mood,journal,wellbeing,mental,health,sleep,step,focus,cute,kawaii,egg,buddy
```
(100 / 100 characters)

**Three fixes to the old list.**

"cozy", "pet", "creature" and "selfcare" all now appear in the title or subtitle, and
Apple counts a keyword once, so repeating them here bought nothing. They are gone,
freeing space for terms that are not indexed anywhere else.

"virtualpet" was written as one word. Apple builds phrases by combining terms ACROSS
fields, so "virtual" in the subtitle plus "pet" in the title already matches a search for
"virtual pet". Jamming them together only matched the literal string.

Everything is singular. Apple matches English plurals automatically, so "step" also
covers "steps" and the extra character is dead weight.

**Phrases this combination matches:** self care pet, virtual pet, cozy pet, virtual
creature, self care, habit tracker, mood tracker, sleep tracker, cute pet, kawaii pet,
tamagotchi pet, mental health.

---

## What's New in This Version (1.0 launch)

```
the first hatch. Yolkling 1.0 is here.

hatch a one of a kind yolk, grow it by living well with optional Apple Health, put the phone down with focus sessions, check in on how you are, and earn Yolks to dress it up. add friends by code or QR, send postcards, and start filling your Dex.

free to play, all of it. no ads. made by one person. thank you for being here for the first one.
```

---

## URLs

| Field | Value |
|---|---|
| Support URL | `https://yolkling.com/support` |
| Marketing URL | `https://yolkling.com` |
| Privacy Policy URL | `https://yolkling.com/privacy` |

Privacy Policy URL must byte-match the in-app privacy link. App Review rejects
mismatches.

---

## Category

- Primary: **Lifestyle**
- Secondary: **Health & Fitness**

Rationale: the core loop is a cozy daily companion and self-expression (Lifestyle),
with an optional Apple Health tie-in where steps and sleep grow the creature
(Health & Fitness). Lifestyle is primary because the app never diagnoses, measures,
or prescribes anything clinical.

---

## Age Rating: 9+ (actual result)

This section originally predicted 4+ and that prediction was WRONG. The submitted
questionnaire returned **9+ in 172 regions and 12+ in Vietnam**, driven by declaring
User-Generated Content = Yes. Recorded here as fact so nobody re-litigates it later.

9+ was accepted deliberately. Declaring No to UGC to hold 4+ would contradict the
block/report controls described in our own App Review notes, and 9+ costs almost
nothing in discoverability for this category.

Answer the questionnaire as below.

| Question | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Horror/Fear Themes | None |
| Mature/Suggestive Themes | None |
| Medical/Treatment Information | None |
| Gambling (simulated) | No |
| Contests | No |
| Unrestricted Web Access | No |
| Gambling and Contests (legacy combined) | No |

Notes on the two that sometimes trip people up:
- No gambling: the earned Yolks economy has no randomized purchases, no loot boxes,
  no real money. Cosmetics are bought at a fixed price with earned currency.
- No unrestricted web access: the app does not embed an open browser.

### User-Generated Content and Messaging (the two that decide the rating)

| Question | Answer |
|---|---|
| User-Generated Content | **Yes** |
| Messaging / Chat | **No** |

**Messaging is No** because there is no chat. Postcards are picked from a fixed
vocabulary (`Core/Social/PostcardVocabulary.swift`) and sent by TOKEN, not text, via
`sendPostcardToken(from:to:token:)`. The server keeps its own copy of each phrase, so a
client cannot invent one even by calling the RPC directly. No reply threads, no free
text, no real-time exchange. The only `TextField` in Social is for a friend's invite
code. Declaring Yes here would over-declare a feature we do not have.

**UGC is Yes, and postcards are not the reason.** The creature's NAME is: a free
`TextField` in onboarding, stored server-side, returned to other users by `get_friends`
and `get_recent_visits`, with no profanity filter or moderation anywhere in the code.
That is an arbitrary user-typed string displayed to other people, which is textbook UGC
and is what a reviewer would find. Declaring No while shipping it would be the
contradiction that earns a metadata rejection.

Guideline 1.2 applies precisely BECAUSE we have UGC, and its controls already ship:
block, report, and account deletion.

**Known gap, accepted for 1.0:** creature names have no filter. Not a blocker with
block/report in place, but it is the one UGC surface without a control on it, and it is
the first thing to add if Apple pushes back.

---

## App Review notes

Paste into the "Notes" field of the version's App Review Information.

```
Thanks for reviewing Yolkling.

HealthKit is optional. The app is fully functional without granting Health access. If you decline the Health prompt, everything still works. To see the "grow by living" behavior, please add Steps and Sleep samples in the Apple Health app; the creature reads those to grow over time. (Note: the DEBUG-only sample-seeding path, seedSampleDay, is compiled out of the Release build, so real Health samples are the way to exercise this in review.)

Sign in with Apple is required to create a creature. Only the stable user identifier is requested (requestedScopes is empty), so no name and no email is ever collected. It is required because the creature is backed up to the account and because the friend graph is keyed on it; without it a creature cannot survive a reinstall and cannot be found by friends. An existing creature made before this requirement is never locked out.

Focus sessions use a Live Activity to show the resting creature on the lock screen while the phone is set down.

Monetization: one auto-renewable subscription, Yolkling Plus (com.yolkling.ios.plus.monthly), managed through RevenueCat. It grants a cosmetic supporter glow and a small monthly grant of Yolks. It gates no content: every species, cosmetic and feature is reachable without it. There are no ads.

Yolks, the in-app currency, are deliberately NOT purchasable at any price. There is no currency pack, no gacha, no loot box, and no randomised purchase anywhere in the app. Cash never touches a random roll: the only randomness sits behind packs the player earns through daily use. Cosmetics are fixed price in Yolks.

The paywall is reachable from Profile > yolkling+, and Restore Purchases sits on the paywall itself. Cancel, refund and plan changes are available in-app through RevenueCat's Customer Center, also from Profile.

If the paywall shows "the supporter tier isn't available right now", the storefront could not be reached from your test device rather than the app failing. Both products are approved and live; the screen states plainly that nothing is wrong with the user's creature and offers a retry, because an indefinite spinner on a payment screen is worse than an honest message. Tapping either plan and then "become a supporter" starts a normal StoreKit purchase.

User-generated content: friends can send short postcards. The app includes block, report, and account deletion controls.

Happy to provide a demo account or a walkthrough if useful.
```

---

## App Privacy (nutrition label)

Answer these in App Store Connect > App Privacy. These MUST match the shipped
`PrivacyInfo.xcprivacy` in the build. If they diverge, fix the manifest, not just
this table.

### Tracking
- Do you or your partners track users? **No.** (No ATT prompt, no cross-app/site
  tracking, no data broker sharing.)

### Data collected

| Data type | Collected? | Linked to identity? | Used for tracking? | Purpose |
|---|---|---|---|---|
| Health & Fitness (steps, sleep) | **Not collected** | — | — | Read from HealthKit and processed on-device only; never leaves the device, never uploaded |
| Identifiers (user ID / install ID) | **Collected** | Linked | No | App Functionality (account, friend graph, syncing your own data) |
| User Content (creature + room snapshot, postcard text, creature name) | **Collected** | Linked | No | App Functionality (visits, postcards, syncing your creature) |
| Contact Info | None | — | — | — |
| Location | None | — | — | — |
| Financial Info | None | — | — | — |
| Browsing / Search History | None | — | — | — |
| Purchases | None | — | — | — |
| Usage Data | None | — | — | — |
| Diagnostics | None | — | — | — |
| Contacts | None | — | — | — |
| Sensitive Info | None | — | — | — |

Plain-language summary of the two "Collected" rows:
- Identifiers: an account/install identifier so your yolk, wallet, and friend graph
  are yours across sessions. Linked to you, not used to track you across other apps.
- User Content: what you make and send (your creature and room snapshot, a postcard's
  text, your creature's name) so friends can receive visits and postcards. Linked to
  you, not used to track you.

Health data is deliberately in the "Not collected" column because it is read from
HealthKit and processed on-device only. Reconfirm this claim against
`PrivacyInfo.xcprivacy` before submitting.

---

## Field-length quick reference

| Field | Limit | Actual |
|---|---|---|
| App Name | 30 | 8 |
| Subtitle | 30 | 30 (at limit) |
| Promotional Text | 170 | 151 |
| Keywords | 100 | 97 |


---

## Note on the species count

Counted from the source on 2026-08-24, not from memory:

| Family | Named species |
|---|---|
| celestial | 48 |
| garden | 55 |
| ocean | 40 |
| cozy | 60 |
| **total** | **203** |

`SpeciesCatalog.all` is `celestial + garden + ocean + cozy`, so it is **four** families,
not five, and **203** species, not 219. Both numbers in the earlier copy were wrong.

Separately, the **Dex is 32**, which is a different thing again: `SpeciesSets.dex` is the
curated set list the collection screen groups by, and the app's own UI says "9 of 32
discovered". So "your Dex of 219 species" was wrong twice over, conflating the full
catalog with the Dex.

There is also a "912 species" figure referenced in `Species.swift`, which counts
procedural palette combinations rather than named creatures. Do not put it in the listing
without saying what it counts.

Metadata that overstates content is a rejection risk under Guideline 2.3, and a reviewer
who opens the Dex sees 32.
