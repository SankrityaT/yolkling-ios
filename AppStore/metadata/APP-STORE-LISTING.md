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
Yolkling
```
(8 / 30 characters)

---

## Subtitle

```
a cozy pet that grows with you
```
(30 / 30 characters — verified exact, at the limit)

---

## Promotional Text

Editable after release without a new build. Use it for the launch.

```
free forever. hatch a one of a kind creature, then grow it by living well: steps, sleep, and time off your phone. collect, decorate, and visit friends.
```
(151 / 170 characters)

---

## Description

Leads with the locked one-liner from docs/PITCH.md, verbatim. Paste as-is.

```
Yolkling is a virtual pet that grows when you take care of yourself in real life. Your steps, sleep, and time off your phone feed your yolk, and you collect new yolks and dress them up.

it is free. all of it. no in-app purchases, no ads, no real money anywhere. the only currency is Yolks, and you earn those just by showing up for yourself.

hatch
your yolk is one of a kind. pick its color and its look, watch it hatch, and it is yours. there are 219 named species to discover across five families, so the one you start with is just the first.

grow by living
connect Apple Health if you want to, and your real days feed your yolk. steps and sleep help it grow, slowly, over weeks, from a little one into a grown one. it is completely optional. the app works fully without Health access, and nothing about your day ever leaves your device to make this happen.

put the phone down
start a focus session when you want time away from the screen. your yolk rests and glows while you are gone, a Live Activity keeps you company on the lock screen, and you earn Yolks when you finish. this is the honest version of screen time: you choose to step away, and your yolk is happier for it.

check in, earn, collect
a gentle daily check-in asks how you are, sets your yolk's mood, and builds a private record just for you. earn Yolks from checking in and from focus sessions, then spend them in the shop and closet on hats, glasses, scarves, rare colors, and decor for your yolk's room. no gacha, no loot boxes, no tricks. you buy the exact thing you want.

friends, done kindly
add friends with a share code or a QR scan, let their yolks visit yours, and send postcards back and forth. invite a friend with your founding-flock code and you both get a founding species. no feeds, no follower counts, no likes. just the people you actually know.

honest by design
no ads. no tracking. no in-app purchases. your mood history and your day stay on your device. there is a home-screen widget so your yolk is one glance away, and a real account you own, with the controls to match.

made by one person who wanted a pet that roots for the real you.
```

---

## Keywords

Comma-separated, no spaces. Paste exactly.

```
virtualpet,creature,cozy,selfcare,tamagotchi,wellbeing,companion,habit,collect,focus,mood,pet,egg
```
(97 / 100 characters)

---

## What's New in This Version (1.0 launch)

```
the first hatch. Yolkling 1.0 is here.

hatch a one of a kind yolk, grow it by living well with optional Apple Health, put the phone down with focus sessions, check in on how you are, and earn Yolks to dress it up. add friends by code or QR, send postcards, and start your Dex of 219 species.

free forever. no ads, no in-app purchases. made by one person. thank you for being here for the first one.
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

## Age Rating: 4+

Answer the Age Rating questionnaire exactly as below. Result should be **4+**.

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

There is user-generated content (friend postcards). That is handled in the App
Review notes and App Privacy sections below, and is moderated with block/report and
account controls, so it does not raise the age rating above 4+.

---

## App Review notes

Paste into the "Notes" field of the version's App Review Information.

```
Thanks for reviewing Yolkling.

HealthKit is optional. The app is fully functional without granting Health access. If you decline the Health prompt, everything still works. To see the "grow by living" behavior, please add Steps and Sleep samples in the Apple Health app; the creature reads those to grow over time. (Note: the DEBUG-only sample-seeding path, seedSampleDay, is compiled out of the Release build, so real Health samples are the way to exercise this in review.)

Social works logged out to start. You can hatch, grow, focus, check in, earn Yolks, and shop without an account. Adding friends, visits, and postcards use a share code or QR scan.

Focus sessions use a Live Activity to show the resting creature on the lock screen while the phone is set down.

Monetization: there is none. No in-app purchases, no subscriptions, no ads. The only currency is Yolks, earned in-app, spent on fixed-price cosmetics. There is no real-money transaction anywhere in the app.

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
