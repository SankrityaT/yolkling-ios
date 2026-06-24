# The relationship — Yolkling's core system

Everything else (cosmetics, rooms, collection, friends, health) plugs into ONE
system: the bond between you and your yolk, earned by how you take care of
**yourself**. The landing-page reviews are not separate features, they are
symptoms of this system working. Build the bond, the reviews come true.

## The flip
Tamagotchi guilts you into feeding a pet. Yolkling does the opposite: the creature
trusts you more as **you** live well (sleep, movement, less screen time, showing
up). You are not maintaining a pet, you are becoming someone it can rely on.

Neglect never kills it or guilt-trips you. Step away and it just goes a little shy,
then re-warms fast when you return. The bond rewards consistency without punishing
absence. That line is the whole differentiation.

## The trust arc (the spine)
Trust is a 0..1 value, surfaced as named stages, each unlocking *behavior*:

| Stage | Trust | How it behaves |
| --- | --- | --- |
| Stranger | 0.0–0.2 | shy, doesn't fully meet your eyes, reserved |
| Warming | 0.2–0.45 | peeks, reacts when you show up, small bounces |
| Friend | 0.45–0.7 | **waves hello**, comes to the front when you open the app |
| Companion | 0.7–0.9 | little tricks, mirrors your mood, **celebrates** your wins |
| Devoted | 0.9–1.0 | knows your rhythm, waits for you, the "I'd die for him" stage |

## The model: consistency, not points (LOCKED)
Trust is NOT a score you grind. It is a CONSISTENCY read: how reliably you've shown
up for yourself. One symmetric rule — "ease toward a target":

- **Caring eases it UP toward 1.0**, diminishing as it rises: `trust += 0.15 * (1 - trust)`.
  Responsive early (warming in ~2 days), a slow burn near the top.
- **Only the FIRST self-care action each day counts** (check-in OR living bonus), so it
  can't be crammed — showing up *daily* is what compounds, not doing more in one day.
- **Drifting eases it DOWN toward a floor**, slower than it rises (forgiving):
  `trust = floor + (trust - floor) * 0.94^neglectedDays`, floor 0.12.

Pace (engaged, daily): warming ~day 2-3, first wave (Friend) ~day 5-7, Companion
~2 weeks, **Devoted ~2 weeks**. Casual / one-faucet users stretch each out toward a
month. Rises ~3x faster than it decays, so returning is always easy.

Trust rises ONLY from self-care (check-ins, grow-by-living, later less screen time).
Never from petting it.

## Losing trust (gently, never guilt)
Same "ease toward floor" rule above, made forgiving:
- **A one-day grace**, plus **rest tokens absorb covered days** (ties into streak protection).
- **Floor 0.12** so even after a long absence it eases back at most to a shy "warming,"
  never a cold stranger. Once bonded, the bond remembers you.
- **The cue is non-verbal, never guilt.** A drifted-from yolk is simply shy again
  (reserved pose + lower stage), and brightens the instant you care for yourself.
  No "you neglected me", no sad/sick/dying creature, no nagging notification.

## Surfacing (LOCKED: behavioral only)
No trust meter / progress bar. The bond is read from the stage label + how the yolk
behaves (shy → waves → celebrates). More magical, less gamified.

Computed lazily on app open from the last self-care date.

## Decisions (the three forks)
1. **Arc length**: a gentle burn. ~a week of self-care reaches Friend (the first
   wave); ~a month reaches Devoted. Slow enough to mean something, fast enough to
   feel progress weekly.
2. **Physical change**: for v1 the yolk keeps its shape and changes **behavior +
   warmth** (blush, eye contact, lean, gestures), not size. Physical growth/evolution
   is a later layer.
3. **Hero moment**: the **first wave** is the beat we nail first (done).

## Gestures (expand "learned to wave" into a system)
A vocabulary of small earned behaviors, each a moment when first unlocked:
- **wave** (Friend) — raised arm beside the head, wiggles. DONE.
- **celebrate** (Companion) — both arms up + a happy hop, on a self-care win. BUILDING.
- morning stretch / yawn (sleep streak) — future
- happy spin (step-goal streak) — future
- bring you a "gift" (Devoted) — future
- sleepy curl + bedtime nudge (late night) — next task

## Living rhythm (expand "got sleepy at 1am")
The yolk lives on a clock + your habits: stretchy mornings, playful afternoons,
winding down in the evening, genuinely drowsy late at night (nudges YOU to sleep),
brighter the morning after good sleep. Next build after gestures.

## Memory + ceremonies (why it sticks)
- It remembers: best streak, the day you connected Health, your check-in pattern,
  and surfaces these gently ("you slept well 5 days straight, [name] has never been
  happier"). That's where "my therapist asked about it by name" comes from.
- Ceremonies: first wave, first time it sleeps trusting you, one-month anniversary,
  earning its "true name." These are the share-worthy beats that generate reviews.

## How each self-care type feeds the bond differently
- **sleep** → rested, learns faster, trust grows quicker
- **movement** → energetic, playful, active gestures
- **less screen time** → the deepest trust: you chose life over the scroll

## The reviews this earns
- "learned to wave" / "i'd die for him" → gestures + the arc
- "got sleepy at 1am so i went to bed" → living rhythm
- "deleted instagram, happier" → off-phone trust
- "my therapist asked about it by name" → memory + the arc feeling like it knows you
- "co-raise one with my bf" → shared companion (future, big)
- "they're dating now" → creature bonds from visits (future)
