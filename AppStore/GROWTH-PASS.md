# Retention, virality and monetization: findings

A pass over the shipping code, not a strategy doc. Everything below was checked against
the source. Three items are FIXED (commit 8b8fe1b); the rest are open with a
recommendation each.

---

## FIXED

### 1. There was no App Store review prompt. Anywhere.

The largest growth gap in the app, and the one that made everything else worth less.
Rating count and average are a direct App Store ranking input, and a listing with zero
ratings converts badly no matter how good the keywords are. Every hour spent on ASO in
`AppStore/SUBMIT` was leaning on a prompt that did not exist.

Now `Core/Growth/AppReview.swift`, fired from the care-streak milestone in `HomeView`.
Policy is deliberately stingy, because Apple allows three prompts per 365 days and may
silently show none of them:

- a care-streak milestone only, which is already a celebrated moment
- 7 days or more, never 3 (too early to have an opinion)
- once per install
- never wired to a button, per Apple's own guidance

### 2. The high-value referral had MORE friction than the low-value one

`GrowFriendsView` has always shared a real deep link: `yolkling.com/add/<code>`. Tap it,
the app opens straight into add-a-friend.

`ReferralView`, the founding-flock invite where BOTH people get a founding species,
shared a bare `yolkling.com` and asked the recipient to retype a code by hand. The
higher-intent, higher-reward loop was the one with a manual step in the middle of it.

Now shares the deep link. The AASA file is deployed with the correct bundle id, so it
resolves.

### 3. ~30 dev seams shipped in Release

Including paths that bypass onboarding and the sign-in gate. Not reachable by a real
user (iOS gives no way to set an environment variable or launch argument on an App Store
install), but not something to ship. `RootView.seamsOn` is a compile-time false in
Release. Verified by rendering: Debug shows the paywall for `YOLK_PLUS`, Release ignores
it and shows the sign-in gate.

---

## OPEN, with recommendations

### 4. The paywall has exactly one entry point, and it is buried

`PlusView` is presented from ONE place in the whole app: a row inside Profile
(`ProfileView.swift:245`). A user must open the You tab and tap a row they have no
reason to tap. Conversion from that will round to zero.

This is the one finding I did NOT act on unilaterally, because adding monetization
surfaces changes what the app feels like, and that is your call rather than mine.

**Recommendation: one placement, in the Shop.** Somebody browsing cosmetics is already
thinking about spending, so a `yolkling+` entry there is contextually honest rather than
interruptive. It costs nothing in goodwill because it is a destination, not a modal.

**Explicitly do NOT:** put it in onboarding, or behind a timed modal, or after a check-in.
The app's entire positioning is that money buys expression and never power, and the HAMM
narrative rests on "an engaged free player out-earns a subscriber 3.4x". An interruptive
paywall would earn a little money and cost the story that is worth more than the money.

### 5. Notifications are one gentle daily hello, and nothing else

`YolkNotifications` schedules a rolling series of one user-scheduled daily message. No
badges, no streak guilt. That restraint is correct and on-brand, and it is also the
entire re-engagement system.

The gap is **event-driven** notifications, which are not guilt and would be genuinely
welcome: your yolkling came home from a wander with something, a friend visited, a
postcard arrived. All three are real events the app already models. None of them notify.

**Blocked, honestly:** push was cut from v1 and OneSignal is not wired, so these would
have to be local notifications scheduled on app open, which only works for events the
device already knows about. The wander homecoming is the one that fits, and it also
depends on the `pg_cron` server-side drift that has not been built.

**Recommendation: leave for 1.1.** It is a real lever, and it is not a launch blocker.

### 6. Streak protection exists but is invisible

`Player.restTokens` starts at 2, so a missed day does not necessarily break a streak.
That is a genuinely kind mechanic and exactly the sort of thing this app should be loud
about, and I could not find anywhere it is explained to the user.

**Recommendation: one line in the streak UI** ("you have 2 rest days"). Cheap, and it
converts a hidden kindness into a reason to trust the app. Retention benefit is real:
people abandon streak apps the day they break the streak, and knowing there is slack is
what stops that.

### 7. What is already good, and should not be touched

Worth stating so nobody "optimises" these later:

- **Daily ceilings.** One check-in, one drift, one trade. Nothing to gain from minute
  three. This is a retention mechanic, not a cost: return rate is what a subscription
  business lives on, and minutes in-app are worth nothing to an app with no ads.
- **Yolks are unbuyable.** No exchange rate between dollars and earned currency. This is
  load-bearing for the HAMM entry and must not be softened.
- **Share cards carry the invite code in pixels.** Captions get stripped when reshared;
  pixels do not.
- **No gacha, no loot boxes.** Cosmetics are bought at a fixed price with earned currency.
