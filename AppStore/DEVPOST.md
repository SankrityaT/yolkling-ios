# Devpost submission — RevenueCat Shipaton 2026

Draft copy, ready to paste. Every number here traces to CLAIMS.md or a live check.
Nothing in this document describes a feature the shipped build does not have.

---

## The hard facts (form fields)

| Field | Value |
|---|---|
| Project name | Yolkling: Self Care Pet |
| App Store URL | https://apps.apple.com/us/app/yolkling-self-care-pet/id6804105200 |
| Bundle ID | `com.yolkling.ios` |
| Platform | iOS 18.0+ |
| Price | Free, with an optional subscription (Yolkling Plus) |
| First public release | 2026-09-21 (inside the Aug 1 – Sep 30 window) |
| US availability | Yes |
| Website | https://yolkling.com |
| Video | **NOT MADE YET — blocking** |

---

## Tagline

A virtual pet that grows when you take care of yourself in real life.

---

## Inspiration

I checked my screen time and it said six hours. Every app I had that was supposed
to help me with that was another thing to open, another streak to keep, another
guilt notification at 9pm.

So I built the opposite. A small creature that is fed by the hours I am NOT on my
phone, by my sleep, by my steps. When I live badly it does not scold me and it does
not die. It just gets sleepy and waits. That turned out to be the whole product.

## What it does

You hatch a creature by answering three questions about your vibe. It is yours and
it exists once.

From then on it runs on your real life. HealthKit gives it your steps and your
sleep. Check-ins and focus sessions earn Yolks, the in-app currency. Screen Time
feeds it the hours you spend away from the phone. Live well and it is bright and
bouncing. Sleep four hours and it is dim and half lidded with z z Z floating over
it. It never gets sick, it never dies, there is no streak funeral.

Around that sits a cozy game. 203 named species across four families, 88 cosmetics,
17 room themes, 34 decor pieces, 21 colour swatches. Once a day your creature
wanders off to a friend's room on its own and comes back with a postcard from a
room it really visited. You can gift Yolks, trade spare costumes, and visit
strangers' rooms. Postcards are composed by picking from a server validated
vocabulary rather than free text, so there is no way to send someone something
cruel.

Every creature is drawn in code. There is not one image asset in the app.

## How we built it

SwiftUI and SwiftData, Swift 6 with strict concurrency, local first. Supabase for
the social layer. RevenueCat for the subscription and for the virtual currency
ledger. XcodeGen so the project file is reproducible. 107 tests.

The creature is a parametric renderer, not a sprite sheet. Species are recipes:
about 46 top features by 26 body patterns by the palette set, which is where the
900+ combinatorial figure comes from, with 203 of them hand named. Because it is
all vector maths the same creature renders at any size, in a card, in a room, in a
postcard, and it animates: asymmetric breathing so the inhale and exhale are not
the same length, an irregular blink, and secondary motion so a hat lags and settles
after the head stops moving.

The Screen Time integration was rebuilt from scratch during the hackathon. The
first version read today's usage inside a `DeviceActivityReport` extension and
wrote it to an App Group. That can never work: the report extension runs in a
read only sandbox and Apple silently drops the write, so the tile read "counting"
forever on every device and no error ever appeared. The second version registers a
ladder of `DeviceActivityEvent` thresholds, 15 minute steps up to 12 hours, and a
`DeviceActivityMonitor` extension records the highest one that fires. That
extension is allowed to write. The number it produces is a lagging lower bound in
15 minute steps rather than a live count, and we say so in the app.

## Challenges we ran into

The read only report extension, above. Two days lost to an API that fails silently
by design.

Wallets that refunded themselves. Both the client and the server used `greatest()`
to merge coin balances, which means the higher number always wins, which means
every time you spent money your old balance came back on the next sync. A player
spent down to 200 and woke up with 565 again and their purchases gone. Fixed with a
Lamport style `wallet_version` counter: strictly newer wins, and the loser is
discarded even if it is larger.

Trading duplicating items. The client never observed the server's deletion, so the
next push reinserted the item and both sides ended up owning it. Found by an audit,
not by a user.

## Accomplishments that we're proud of

We integrated RevenueCat's Virtual Currency system specifically in order **not** to
sell currency.

Their ledger holds every Yolk that came from money. Our database holds every Yolk
that came from living. They are structurally separate and the app can prove it. An
engaged free player out-earns a subscriber by roughly 3.4x, measured against our own
earn rates. You cannot buy Yolks at any price. Cash never touches a random roll.

The other one is `CLAIMS.md`, an honesty ledger in the repo that tracks every
promise the landing page makes against what the app actually does, with dated
audits. It corrects in both directions. It caught us claiming "no real money IAP"
after we had shipped a subscription, and it also caught us having quietly deleted a
true claim about trading from the website because we had forgotten we built it.

## What we learned

That an honesty ledger is cheaper than a launch checklist, because a checklist only
asks whether you built the thing and the ledger asks whether the sentence on your
website is still true.

And that the interesting monetisation question is not how to charge more. It is
what your revenue is correlated with. Ours is not correlated with attention, so we
have no incentive to keep anyone in the app.

## What's next for Yolkling

Verifying the Screen Time rewrite on real hardware. It is written, unit tested and
shipped, but Family Controls does not report usage in the simulator, so it has
never actually run.

Then species card trading, which needs server side ownership rows that do not exist
yet, and making the holo cards reachable. They are built, real, and currently only
visible through a dev seam.

## Built with

swift, swiftui, swiftdata, swift-testing, revenuecat, supabase, postgres, healthkit,
family-controls, deviceactivity, storekit, xcodegen, nextjs, typescript, gsap, vercel

---

## Category answers

### RevenueCat Design Award

A creature drawn entirely in code. No art assets anywhere in the app, and no
designer either. Species are parametric recipes, roughly 46 top features by 26 body
patterns by the palette set, 203 of them hand named across celestial, garden, ocean
and cozy families.

Because it is maths and not pixels, it can be alive. The breathing is asymmetric so
the inhale and the exhale are different lengths, the way real breathing is. The
blink is irregular, never on a timer. Hats and limbs have secondary motion, so they
lag the head and settle after it stops. There are 14 moods.

The restraint is the design decision though: the creature is never sick, never
crying, never dying. A bad day makes it sleepy. That is the entire emotional
contract of the app, and it is expressed almost entirely through a half lidded eye.

### HAMM (Hackathon's App Making Money)

We adopted RevenueCat's Virtual Currency system in order not to sell currency.

Yolks are the in-app currency and they are not purchasable at any price. RevenueCat's
ledger records exactly the Yolks that came from money, which is the monthly stipend
that comes with a Yolkling Plus subscription. Supabase records the ones that came
from living: check-ins, focus sessions, steps, sleep. Two economies, deliberately
kept apart, and an engaged free player out-earns a subscriber by about 3.4x.

What Plus actually sells is three things and the paywall lists exactly these three:
a supporter glow, a monthly handful of Yolks, and "you keep this alive, no ads ever."
It sells support, not power and not shortcuts.

### #BuildInPublic

`CLAIMS.md`, in the repo. Every promise on yolkling.com checked against what the app
does, with dated audits and a legend that includes "copy and app disagree, fix one
of them."

The reason it is worth reading is that it corrects in both directions. It caught us
overstating: we said "no real money IAP" twice after shipping a subscription, and
we said the Plus paywall included "every season," which it never did. It also caught
us understating: rooms, rare colours, cloud backup and trading were all built and
still marked as not built, and a pending pull request was about to delete a true
claim about trading from the live site.

The rule it enforces is that we do not ship to the App Store until every claim is
either true or softened. It is the same file we use to decide what goes in a demo
video.

### RevenueCat Peace Prize

Yolkling monetises support rather than attention.

Almost every free app's revenue rises with time in app, which gives the business a
reason to keep you there. Ours does not. Subscription revenue is flat regardless of
whether you open the app twice a day or twice a week, and the in-app currency is
partly earned by being off your phone. The incentive to retain you by any means is
structurally absent.

Concretely: no ads, no analytics SDK, no tracking, local first storage. Autonomous
wandering happens once a day, gifting to strangers is capped at one a day, and
there is no streak that punishes you for missing it. The creature does not get sick
and cannot die. Block and report are reachable from the place you meet a stranger
rather than buried in settings, and postcards are composed by selection from a
validated vocabulary so a stranger cannot type something cruel at you.

### Grand Prize

[Fill after launch traction is in. Needs real install and retention numbers.]

### Next Gen (student)

[Student status + open source repo link. Judged on video + code, no store release required.]

---

## Form facts (confirmed 2026-09-26)

| | |
|---|---|
| Devpost draft | https://devpost.com/submit-to/29969-revenuecat-shipaton-2026/manage/submissions/1128977-yolkling/ |
| Deadline | Sep 30, 2026 @ 11:45pm **MST** |
| Team | Sankritya Thakur (@sankritya09-02) + Havishea Vannemreddy (@hvannemr), already added |
| RevenueCat project ID | `projc1eca855` |
| Assets staged | `AppStore/devpost/` — app-icon-1024.png, three 1179x2556 unframed screenshots |

## Blocking gaps

1. **Demo video.** Not made. `marketing/PITCH-VIDEO.md` is a script only. Prescreeners
   watch the first two minutes and are not required to install the app. This is the
   single highest-value missing item.
2. **Judge access to Yolkling Plus.** RevenueCat shows no offer codes and no
   promotional offers, and both App Store products read "Store Status: could not
   check" so a free trial cannot be confirmed. Judges need either an App Store offer
   code or a confirmed trial, or they cannot see the paid features.
3. **Image uploads.** Devpost needs the icon and an unframed screenshot attached, and
   two required checkboxes confirm it. Files are staged; the upload is manual.
4. **#BuildInPublic links, and the repo.** `CLAIMS.md` is the whole entry and it lives
   in a **private** repo, so judges cannot read it. Either publish it as a page on
   yolkling.com or make the repo public. Field 16 is blank until there are real links.
5. **Next Gen.** Needs a public code repository and a student email. Both repos are
   private. Left blank.

## Deliberately not entered

Catvertising, Best Game, Influencer (all five tracks), Ship Kotlin Everywhere, Most
Viral (Noise), Best App for Galaxy, Idea to Income (Replit), Keep Them Coming Back
(OneSignal), The Growth Loop (Layers), Funnel Vision (Stripe).
