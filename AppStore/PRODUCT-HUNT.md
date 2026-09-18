# Product Hunt: Tuesday Sep 22

Replaces the Sep 15 plan. Review delays ate that date, and the old plan's own rule was
"do not slip past Sep 17". What changed, and why the new dates, is below.

## The sequence

| when | what |
|---|---|
| **now** | Put up a Product Hunt "coming soon" page. Collect followers until launch |
| **now** | Line up support privately, one person at a time (see below) |
| **Mon Sep 21, morning** | Press **Release** on 1.0 in App Store Connect. Start Apple Ads |
| **Mon Sep 21** | Submit 1.0.1 (Dex at 203, Screen Time fix) |
| **Mon Sep 21** | Confirm the App Store link opens and downloads, on a real phone |
| **Tue Sep 22, 12:01 AM Pacific** | Launch. Social push that morning |
| **Sep 21-28** | The new-app ranking boost window. Everything above lands inside it |
| **Sep 30** | Shipaton closes |

Backup: Wed Sep 23. Don't go later; the boost window and Shipaton both run out.

## Why these dates

**Release the day before, not earlier.** New apps get roughly a seven-day ranking boost
driven by download velocity, and apps have been documented falling from the top 10 to
#40-50 when it ends. Releasing on the 17th would have spent four of those seven days with
no marketing behind them. Releasing on the 21st puts the ads, the launch and the social
push all inside the window, and the window closes before Sep 30.

**Release BEFORE launching, never the same instant.** Product Hunt's own guide: "The
product is usable... Closed beta launches are usually not a good fit if it means our
community can't participate." A maker on their forum launched a mental health app before
it reached the App Store and "lost those users in the waiting list, since they opened an
almost empty launch." "Approved" is not downloadable. The link has to work.

**Not Friday Sep 18.** Friday itself is fine: the closest comparable, Urso, took #1 on a
Friday. But the GPT-6 Astra Challenge is funnelling its entire field onto that date, and
Yolkling isn't eligible for it anyway (it uses no AI model at all, and the App Review
notes say so in writing). You'd be competing against every hackathon entry.

**Tuesday over the rest of the week.** Tue-Thu have the most traffic and the most
competition; Mon and Fri are slightly quieter. One maker's four-launch comparison: Tuesday
12:01 AM finished 3rd with 687 upvotes and ~4,800 visitors, Thursday finished 8th with 312
and ~2,100. Placing tenth on a busy day still beats third on a quiet one.

**12:01 AM Pacific.** Days start then and ranking accumulates over 24 hours. Arizona has no
DST, so in September Pacific is your local time. Midnight, not 3 AM.

## What worked for the closest comparables

| product | tagline | day | rank | upvotes |
|---|---|---|---|---|
| Urso | "A mobile game that takes care of your mental health" | Fri | #1 | 714 |
| Polar Habits (relaunch) | "Build lasting habits without the guilt of broken streaks" | Mon | #1 | 615 |
| Habits Garden | "A gamified habit tracker to achieve your goals" | Mon | #4 | 587 |
| Urso 1.0 (relaunch) | "A Tamagotchi-bear that cares for your well-being" | Mon | #4 | 429 |
| Habits Garden for Mobile | "Build habits you won't quit" | Mon | #4 | 351 |
| HabitKit | "Track your consistency with cool grids" | Sun | #5 | 339 |
| Polar Habits | "Guilt-free habit tracking" | Sun | #2 | 253 |
| Tamadoggo | "A living journal for your pet's life, with AI insights" | Mon | #6 | 190 |
| Focus Bear | "Block distractions, build habits." | Fri | #5 | 169 |
| Opal (Android) | "Finally on Android: the world's favorite screen time app." | Tue | #9 | 161 |
| Nibbo | "Family hub with a 3D pet that grows as you get things done" | Sun | #10 | 96 |

Finch, the nearest competitor, isn't in the table: its 2021 launch couldn't be located
under Product Hunt's current slugs, so there are no verified numbers to cite.

What the top three had in common, and what they didn't:

- **Urso (#1, 714)** opened the gallery with a cinematic render of the creature in its world.
  No UI at all, no video. The founder's comment ran ~280 words, and the whole six-person
  team replied to nearly every comment in the thread.
- **Polar Habits (#1, 615)** tied the launch to New Year's Day, the peak moment for habits,
  used Product Hunt's interactive demo in place of a video, and was hunted by Chris Messina.
  The founder's comment was only ~110 words.
- **Habits Garden (#4, 587)** led with a comedy video that generated its own comment thread,
  and its maker is a serial launcher with a large existing following.

The consistent thread is **presence**, not assets: every one of them had people answering
comments all day. That is the part that cannot be prepared the night before.

## The assets

| asset | spec | notes |
|---|---|---|
| Name | 40 chars | `Yolkling` |
| Tagline | 60 chars | see below |
| Description | 500 chars | see below |
| Thumbnail | 240x240 | the creature on cream, no text. It has to read at 40px |
| Gallery | 1270x760, **at least 2**, aim for 5-8 | App Store captures, recomposed landscape |
| Video | optional, YouTube only, public | 53% of Product of the Day winners since 2021 had one. Urso won without |
| Topics | 3 | Health & Fitness, iOS, Self-improvement |

**Gallery order matters more than count.** Open with the creature, not the UI: that is
what Urso did, and Yolkling is a character-led product in the same way. Second slide is the
health connection, because the differentiator has to land before anyone scrolls. Friends
and collecting after that.

### Tagline (55/60)

```
a virtual pet that grows when you take care of yourself
```

Describes what happens to you rather than the technology, which is what now separates
winning taglines: roughly a quarter of all taglines say "AI" and it has stopped
distinguishing anything. Don't open with "Yolkling is a"; the name is already above it.

### Description (456/500)

```
Yolkling is a virtual pet that grows closer to you when you look after yourself in real life. Your steps, sleep and time away from your phone feed it, so the thing that makes it happiest is you putting it down. Hatch a one of a kind yolk, collect 203 species, dress yours up, and let friends' yolks visit yours. No ads, no tracking, no loot boxes. Yolks are earned by showing up and never sold on their own. One optional subscription adds a supporter glow.
```

**"203 species" is only true once 1.0.1 is live.** 1.0 caps discovery at 32. If 1.0.1
hasn't been approved by launch morning, change it to "collect new species". The listing
must match what someone can download that day.

## The first comment is the launch

More people read it than the description. Write it as a person, not a press release. Keep
it between Polar Habits' ~110 words and Urso's ~280.

- **why you built it.** The real reason, not the market reason. Only you can write this
  part, so it's left blank below on purpose
- **the one decision you'd defend to a stranger:** Yolks are earned, never sold on their
  own. A year of showing up earns you several times what a year of the subscription gives
- **what's deliberately missing:** no ads, no streak guilt, no loot boxes, no feed
- **what you want feedback on**

Do NOT list features. The gallery does that. Do not ask for upvotes.

A shape to write into:

> Hi Product Hunt, I'm [name].
>
> [Why you built it. Two or three sentences, in your own words, about the actual thing
> that made you want this to exist.]
>
> Yolkling is a small pet that grows when you look after yourself: your steps, your sleep,
> and time spent away from your phone. The last one is the point. Most wellbeing apps want
> you to open them more. This one is happiest when you put it down.
>
> One thing I'd defend to anyone: you can't buy Yolks on their own. A year of showing up
> earns you several times what a year of the subscription does. The subscription is there
> to support the thing, not to skip it.
>
> What's not here: no ads, no tracking, no loot boxes, no feed, and no guilt when you miss
> a day. Your yolk just waits for you.
>
> I'd love to hear what you think, especially [the thing you actually want to learn].

**Before posting, check the number.** "Several times" is safe: a moderately engaged free
player (daily check-in, the weekly challenge, about fifteen minutes of focus a day, the
one-time streak bonuses) earns about 15,900 Yolks a year against the subscription's 4,800.
Do NOT use the old line "Yolks cannot be bought at any price". Plus grants 400 a month, and
that exact absolute was just removed from the App Store description for being untrue.

## Lining up support

- Message people individually, one at a time, and ask them to **look** on the day. Never
  post "upvote me" anywhere. Product Hunt penalises it and people can tell.
- Point them at the coming soon page now, so they're following before launch day.
- Ask real testers to install and rate on Mon Sep 21, so the listing isn't empty on launch
  day. Genuine ratings only: Apple removes fake reviews and can pull the app.

## Launch day

- **12:01 AM**: live. First comment posted immediately.
- **Answer every single comment, fast and personally, all day.** This is the one thing every
  top comparable did. Response rate is visible, and it is most of what turns a browser into
  an install.
- Post to X, Reddit and the cozy-game Discords that morning.
- Leave the ads alone on the day. One channel at a time.

## What to measure

Not upvotes. **Installs and trials on Sep 22-23**, from App Store Connect and RevenueCat.
Product Hunt is a spike; what matters is whether it converted and whether any of it stuck a
week later. That retention number, plus revenue by Sep 30, is worth more in the Shipaton
write-up than the ranking.

## Sources

- [Preparing for launch, Product Hunt](https://www.producthunt.com/launch/preparing-for-launch)
- [How Product Hunt works](https://www.producthunt.com/launch/how-product-hunt-works)
- [Launch guide, Product Hunt](https://www.producthunt.com/launch)
- [What's the best day to launch? (Aug 2026)](https://www.producthunt.com/p/general/what-s-the-best-day-to-launch-on-product-hunt-2)
- [Have you ever had your launch cancelled or delayed?](https://www.producthunt.com/p/general/have-you-ever-had-your-launch-cancelled-or-delayed)
- [Urso](https://www.producthunt.com/products/urso/launches/urso)
- [Polar Habits](https://www.producthunt.com/products/polar-habits/launches/polar-habits-2)
- [Habits Garden](https://www.producthunt.com/products/habits-garden/launches/habits-garden)
- [Post-launch ASO timeline for indie iOS devs](https://screenfast.app/blog/post-launch-aso-timeline-indie)
- [GPT-6 Astra Challenge](https://www.producthunt.com/contests/gpt-6-astra-challenge)
