# Cross-localization: 5x the indexed keywords, no build required

Supersedes the es-MX-only plan in `4-SPANISH-LOCALIZATION.md`, which was correct but
covered one locale out of ten.

## Why

The US storefront does not index only English (U.S.). It indexes **ten locales**, and
each one carries its own 30-char name, 30-char subtitle and 100-char keyword field. That
is up to 1,440 bonus indexable characters for the US alone, and English (U.S.) gets no
priority over the others.

Right now Yolkling has roughly 23 indexed terms. The five locales below take it to **88**,
with zero duplication, no new build, and edits that stay editable after release.

## The split, and the trade-off stated plainly

For each added locale:

- **Keywords: English.** Nobody reads this field. It is what the US storefront indexes.
- **Name, subtitle, description: copy the English ones verbatim.** App Store Connect will
  not save a localization with these empty.

**The cost is real and worth saying out loud.** A Korean user browsing the Korean
storefront will see an English listing. For a US-focused launch that is the right trade,
and it is reversible: properly translate any locale later once analytics show installs
actually coming from it. Do NOT do this for a market you intend to serve.

## The keyword sets

Paste into the Keywords field of each localization. Comma-separated, no spaces.
Every set is verified to have zero overlap with en-US and with each other, because Apple
credits a term once per storefront no matter which locale it sits in.

### Spanish (Mexico) — 99/100
```
anxiety,stress,calm,routine,daily,streak,detox,screentime,widget,pomodoro,timer,diary,companion,zen
```
The wellbeing angle. Backed by focus sessions, Screen Time, care streaks, the widget
target and the daily check-in.

### Portuguese (Brazil) — 93/100
```
plant,garden,bloom,nurture,gentle,quiet,slow,rest,unwind,breathe,soft,warm,pastel,cottagecore
```
The cozy/nurture angle. This is the aesthetic search cluster the app actually sits in,
and it is completely unserved by the en-US set.

### French — 93/100
```
collect,unlock,rare,pixel,retro,nostalgia,digital,keychain,nineties,hatch,monster,raise,adopt
```
The collector and virtual-pet-nostalgia angle. "keychain" and "nineties" are how people
search for the Tamagotchi memory without typing the trademark.

### Korean — 94/100
```
friend,social,share,gift,visit,postcard,together,community,wholesome,positive,kindness,support
```
The social angle. Every term maps to a shipped feature: friends, visits, postcards,
gifting.

### Russian — 93/100
```
motivation,goal,progress,reward,consistency,discipline,balance,unplug,offline,mindful,burnout
```
The self-improvement angle, deliberately kept NON-clinical. No "therapy", "adhd",
"autism" or similar: Apple treats implied medical claims harshly and the app makes none.

## Order to add them, if you are not doing all five

1. **Spanish (Mexico)** — the classic, highest confidence
2. **Portuguese (Brazil)** — unlocks the cozy/aesthetic cluster, the app's real niche
3. **French** — the collector and nostalgia cluster
4. **Korean** — social
5. **Russian** — self-improvement

## How to add one

App Store Connect > the app > Distribution / App Store tab > language dropdown at the top
> **Add Language**. Fill name, subtitle and description with the English ones, paste the
keyword set above, and leave screenshots empty so they inherit.

## What NOT to do

- **Do not translate the keyword sets.** English is the point.
- **Do not upload per-locale screenshots.** They inherit, and a second set is 16 more
  images to keep in sync for nothing.
- **Do not reuse a term across locales.** The whole gain comes from every term being new.
