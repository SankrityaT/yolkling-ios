# Celestial family

Stars, moons, suns, comets, ringed planets, auroras, nebulae, twilight, and shooting
stars, all in soft cosmic pastels. Everything here is drawn in pure SwiftUI primitives
(Circle, Ellipse, Capsule, RoundedRectangle, small Path arcs, gradients). No art assets,
no images, no emoji.

## Conventions used in this spec

These match the existing `YolklingView`:

- `size` is the single base measure. Body is a `Circle` of width `size`, drawn with a
  `RadialGradient` from `vibe.body` (light, top-left, center `UnitPoint(x: 0.36, y: 0.30)`)
  to `vibe.deep` (shade). Accent is an extra hex per species.
- Colours: `Color(hex: 0xRRGGBB)` and `Color(hex: 0xRRGGBB, alpha: 0.0...1.0)`. "body
  colour" = `vibe.body`, "deep colour" = `vibe.deep`, "accent hex" = the species accent.
- `.offset(x:y:)` measures from body centre. y grows DOWNWARD. Top features sit around
  `y = -size*0.4 ... -size*0.6` (above the head). Rotations are `.rotationEffect(.degrees(...))`.
- Body PATTERNS are an overlay placed inside the body `Circle` and clipped to it:
  `.overlay( patternView ).clipShape(Circle())`. They draw at low opacity over the
  gradient so the face stays readable.
- All palettes are tuned to read on the cream app background `#FBF6EC`. No em dashes anywhere.

A tiny reusable 5-point star `Shape` is assumed (used by several features below). It draws a
classic star bounded by the frame, alternating outer radius `0.5 * min(w,h)` and inner radius
`0.20 * min(w,h)` over 10 points starting at the top. Call it `StarShape`. Where a 4-point
sparkle is wanted, `SparkleShape` uses inner radius `0.12` for thin diamond arms.

---

## New top features

Each is a small cluster of shapes sitting above the head. Keep each to a handful of shapes.
Fills are `body` (vibe.body), `deep` (vibe.deep), or a literal hex (usually the species accent).

### 1. star antenna
A single bobbing star on a thin stalk. Cute and minimal.
- Capsule, `size*0.022` wide x `size*0.16` tall, fill deep colour, offset `y -size*0.50`.
- `StarShape` bounded `size*0.12`, fill accent hex, offset `y -size*0.62`, rotation `0`.
- Optional tiny highlight: Circle `size*0.03`, fill `#FFFFFF` at alpha `0.6`, offset
  `(x -size*0.02, y -size*0.64)`.

### 2. twin star antennae
Two stalks, like little feelers, each tipped with a small star. Reads as "starbug".
- For `side` in `[-1, +1]`:
  - Capsule `size*0.018` x `size*0.13`, fill deep colour, rotation `side*16` deg,
    offset `(x side*size*0.10, y -size*0.50)`.
  - `StarShape` bounded `size*0.09`, fill accent hex, offset `(x side*size*0.16, y -size*0.60)`,
    rotation `side*12` deg.

### 3. crescent moon tuft
A soft crescent resting where hair would be, tilted like a beret.
- Outer Circle `size*0.20`, fill accent hex, offset `(x size*0.02, y -size*0.50)`.
- Inner Circle `size*0.17`, fill the cream background `#FBF6EC` (acts as the "bite" that
  carves the crescent), offset `(x size*0.07, y -size*0.52)`.
- Build as `ZStack { outer; inner }` then `.rotationEffect(.degrees(-24))`. The cream
  inner disc subtracts from the accent disc to leave a crescent.
- Tiny accent Circle `size*0.025`, fill accent hex, offset `(x -size*0.10, y -size*0.42)`
  as a little orbiting star.

### 4. planet ring halo
A flat ellipse ring tilted around the top of the head, like Saturn's rings seen edge-on.
- Ellipse STROKE, frame `size*0.62` wide x `size*0.20` tall, stroke accent hex
  lineWidth `size*0.03`, rotation `-18` deg, offset `y -size*0.42`.
- Second inner Ellipse STROKE, frame `size*0.50` x `size*0.15`, stroke deep colour at
  alpha `0.45`, lineWidth `size*0.016`, rotation `-18` deg, offset `y -size*0.42`.
- The body shows through the ring, so the creature itself reads as the planet.

### 5. sun rays crown
A ring of short tapered rays fanning over the crown. Warm and radiant.
- 7 Capsules, each `size*0.018` wide x `size*0.11` tall, fill accent hex.
- For ray `i` in `0..<7`, angle `= -70 + i*23.3` degrees: `.rotationEffect(.degrees(angle))`
  then offset to sit on an arc of radius `size*0.46` centred at the crown:
  `offset(x: sin(angle)*size*0.0, y: -size*0.50)` with the rotation pushing each outward
  (simplest implementation: place each Capsule at offset `y -size*0.50`, apply rotation
  about the body bottom anchor by wrapping in `.rotationEffect(.degrees(angle), anchor: .bottom)`).
- Optional soft centre: Circle `size*0.10`, fill accent hex at alpha `0.5`, offset `y -size*0.50`.

### 6. comet swoosh
A small head-orb trailing a tapered tail, swept up to one side like a fringe.
- Circle `size*0.10`, fill accent hex, offset `(x size*0.16, y -size*0.52)`.
- Tail: a `Capsule` `size*0.05` x `size*0.22`, fill a linear gradient from accent hex
  (alpha 1, at the orb) to accent hex (alpha 0, at the tip), rotation `52` deg, offset
  `(x size*0.04, y -size*0.46)`.
- Two trail sparkles: Circles `size*0.03` and `size*0.02`, fill `#FFFFFF` alpha `0.7`,
  offsets `(x -size*0.06, y -size*0.40)` and `(x -size*0.11, y -size*0.36)`.

### 7. aurora wisps
Two soft vertical ribbons of light curling up from behind the head.
- For `side` in `[-1, +1]`:
  - A `Capsule` `size*0.06` wide x `size*0.26` tall, fill a vertical linear gradient from
    accent hex (alpha 0 at top) to accent hex (alpha 0.55 at bottom), `.blur(radius: size*0.02)`,
    rotation `side*10` deg, offset `(x side*size*0.14, y -size*0.50)`.
- One extra central ribbon: same recipe, `size*0.05` x `size*0.22`, second accent or
  deep colour, alpha to 0.4, offset `y -size*0.52`.

### 8. constellation arc
Three small stars connected by a faint line, arcing over the head like a tiara.
- Three `StarShape`s bounded `size*0.07`, `size*0.05`, `size*0.07`, fill accent hex, at
  offsets `(x -size*0.16, y -size*0.48)`, `(x 0, y -size*0.56)`, `(x size*0.16, y -size*0.48)`.
- Connector: a `Path` with `move` to the left star centre, `addQuadCurve` to the right
  star centre with control point at `(x 0, y -size*0.60)`, stroked deep colour alpha `0.4`,
  lineWidth `size*0.01`, drawn behind the stars.

### 9. ringed orbit dot
A tilted thin orbit ellipse with a single tiny moon riding it. Minimal, charming.
- Ellipse STROKE, frame `size*0.5` x `size*0.16`, stroke deep colour alpha `0.5`,
  lineWidth `size*0.012`, rotation `20` deg, offset `y -size*0.44`.
- Moon: Circle `size*0.06`, fill accent hex, offset `(x size*0.22, y -size*0.40)` (sitting
  on the right edge of the tilted orbit).

### 10. nebula puff
A soft cloud of two overlapping blurred ellipses with a star nestled in front. Dreamy.
- Ellipse `size*0.26` x `size*0.16`, fill accent hex alpha `0.45`, `.blur(radius: size*0.03)`,
  offset `(x -size*0.04, y -size*0.50)`.
- Ellipse `size*0.20` x `size*0.13`, fill deep colour alpha `0.40`, `.blur(radius: size*0.03)`,
  offset `(x size*0.06, y -size*0.46)`.
- `StarShape` bounded `size*0.08`, fill `#FFFFFF` alpha `0.85`, offset `(x size*0.02, y -size*0.50)`.

---

## New patterns

Each pattern is an overlay drawn ON the body and clipped to the body `Circle`. Implement as
`.overlay(patternView).clipShape(Circle())`. Use low opacity so the gradient and face read
through. "lighter shade" = `vibe.body` lightened (use `vibe.body.opacity(0.5)` over white, or
simply `#FFFFFF` at low alpha); "darker shade" = `vibe.deep` at low alpha.

### A. star freckles
A light sprinkle of tiny stars scattered across the body, like freckles.
- 7 `StarShape`s, sizes ranging `size*0.03 ... size*0.05`, fill `#FFFFFF` at alpha `0.7`.
- Suggested offsets (clipped, so off-disc parts just vanish):
  `(-0.22,-0.10) (0.20,-0.04) (-0.10,0.14) (0.26,0.18) (0.06,0.24) (-0.28,0.06) (0.14,-0.18)`,
  each multiplied by `size`. Rotate each by a fixed varied angle (`0, 14, -10, 22, -18, 8, -6`).

### B. galaxy swirl
A faint spiral of dots curling from the belly outward, a soft arm of a galaxy.
- 8 Circles, radius shrinking from `size*0.05` to `size*0.015`, fill accent hex alpha `0.5`.
- Place along a spiral: for `i` in `0..<8`, angle `= i*0.9` rad, radius `= size*(0.05 + i*0.03)`,
  offset `(x cos(angle)*radius, y sin(angle)*radius)` centred at `(x size*0.05, y size*0.05)`.
- Optional centre glow: Circle `size*0.10`, fill `#FFFFFF` alpha `0.35`, `.blur(size*0.03)`,
  at the spiral centre.

### C. crescent belly glow
A soft luminous crescent across the lower belly, like a moon-lit tummy.
- Outer Ellipse `size*0.6` x `size*0.5`, fill accent hex alpha `0.30`, `.blur(radius: size*0.05)`,
  offset `(x 0, y size*0.20)`.
- Inner Ellipse `size*0.5` x `size*0.42`, fill the body colour (to subtract and leave a glow
  arc), offset `(x 0, y size*0.12)`. Because it is clipped and sits over the gradient, the
  visible result is a soft crescent of accent light along the belly's lower rim.

### D. twilight gradient band
A horizontal band that fades the lower half toward a dusk tone, like a horizon line.
- A Rectangle filling the body bounds, with a vertical `LinearGradient` from `clear` (top,
  at `UnitPoint(x:0.5,y:0.45)`) to accent hex alpha `0.45` (bottom). Clipped to the circle.
- One thin Capsule `size*0.5` x `size*0.012`, fill `#FFFFFF` alpha `0.4`, offset `y size*0.02`
  as a faint horizon line.

### E. orbit rings
Two faint concentric ellipse outlines tilted across the body, like planetary orbits.
- Ellipse STROKE `size*0.7` x `size*0.34`, stroke deep colour alpha `0.30`, lineWidth
  `size*0.012`, rotation `-16` deg, offset `(x 0, y size*0.04)`.
- Ellipse STROKE `size*0.5` x `size*0.22`, stroke accent hex alpha `0.35`, lineWidth
  `size*0.01`, rotation `-16` deg, offset `(x 0, y size*0.04)`.
- One tiny Circle `size*0.04`, fill accent hex, sitting on the outer ring's right edge:
  offset `(x size*0.30, y -size*0.02)`.

### F. moon dust speckle
A dense, very subtle field of tiny dots, like fine stardust over the whole body.
- 14 Circles, each `size*0.012 ... size*0.02`, fill `#FFFFFF` alpha `0.45`, scattered
  evenly (a fixed pseudo-random set of offsets within radius `size*0.42`). Reads as a soft
  textured shimmer, not distinct freckles.

---

## Accessories

Small worn items in the celestial spirit. Each is code-drawable and sits in a cosmetic slot
(hat-ish around `y -size*0.4..-0.6`, or held to the side). All pure shapes, no SF Symbols.

### i. tiny star wand (held)
- Capsule `size*0.018` x `size*0.20`, fill `#C9A24B` (muted gold), rotation `18` deg,
  offset `(x size*0.40, y size*0.10)`.
- `StarShape` bounded `size*0.10`, fill accent hex, offset `(x size*0.46, y -size*0.02)`.

### ii. halo ring (hat slot)
- Ellipse STROKE `size*0.34` x `size*0.12`, stroke `#FFE9A8` (soft starlight gold)
  lineWidth `size*0.02`, offset `y -size*0.46`. A gentle floating halo above the head.
- Optional soft glow: same ellipse, stroke alpha `0.4`, `.blur(radius: size*0.02)`.

### iii. moon barrette (hair clip)
- Small crescent (Circle `size*0.10` accent hex minus a cream Circle `size*0.085` offset
  `x size*0.025`), rotation `-20` deg, offset `(x -size*0.24, y -size*0.30)`. Clips to the
  side of the head like a barrette.

### iv. starlight scarf (neck)
- Capsule `size*0.5` x `size*0.10`, fill deep colour, offset `y size*0.30` (wraps the lower body).
- Three `StarShape`s `size*0.04`, fill accent hex, spaced along it at
  `(x -size*0.14, y size*0.30) (x 0, y size*0.32) (x size*0.14, y size*0.30)`.

---

## Species

Columns: name | body | deep | accent | top feature | pattern | eye | rarity | personality.
Eye is the existing emotion default `round` unless a calmer resting pose suits the character
(`sleepy` or `happyArc`). All hexes read on cream `#FBF6EC`. 48 species, no duplicate names.

| name | body | deep | accent | top feature | pattern | eye | rarity | personality |
|------|------|------|--------|-------------|---------|-----|--------|-------------|
| stardrop | #FBE6A8 | #E7C25E | #FFF4C9 | star antenna | star freckles | round | common | the cheerful first wish of the night |
| lilac comet | #C9B8E8 | #9A82C9 | #FFD9B0 | comet swoosh | moon dust speckle | round | rare | always arriving a little out of breath |
| moonpuff | #E8E2D2 | #C2BAA6 | #FBF1C9 | crescent moon tuft | crescent belly glow | sleepy | common | naps through every sunrise on purpose |
| sunny yolkstar | #FFD98C | #F0B23E | #FFE9A8 | sun rays crown | twilight gradient band | happyArc | common | wakes the whole sky up by being loud |
| dusk plum | #A99BCF | #7C6BA8 | #F2B6C6 | twilight gradient band* | twilight gradient band | round | rare | likes the quiet ten minutes after sunset |
| ringling | #BCCBE8 | #8AA0CC | #E9C77A | planet ring halo | orbit rings | round | epic | wears its own little Saturn rings, proudly |
| starnap | #D7C8E8 | #A98FCC | #FFE2A6 | crescent moon tuft | star freckles | sleepy | common | counts stars until it forgets which it was on |
| auroria | #A7D8D0 | #6FAFA8 | #C8A6E8 | aurora wisps | galaxy swirl | round | epic | shy, but glows softly when it is happy |
| nebulina | #C4A9D6 | #8E6FB0 | #F0AFC4 | nebula puff | galaxy swirl | round | epic | dreams in slow swirling colours |
| pip the small star | #FFEFC2 | #E9CC78 | #FFFBE9 | star antenna | star freckles | round | common | tiny, bright, certain it is very important |
| twinkleberry | #F4C6D6 | #D98FAC | #FFE3A8 | twin star antennae | star freckles | round | common | giggles in little sparkles when tickled |
| midnight bao | #8E9BC4 | #5E6B98 | #E8D08A | constellation arc | moon dust speckle | sleepy | rare | soft, round, and full of quiet midnight |
| solune | #FFE0A6 | #E8B05E | #B9A6E0 | sun rays crown | crescent belly glow | round | rare | half daydream, half afternoon sun |
| cometail | #B6C7E8 | #8298C9 | #FFC79A | comet swoosh | orbit rings | round | rare | leaves a glittery trail everywhere it goes |
| haloh | #F0E6C9 | #CCB888 | #FFF0BE | halo ring (accessory) | moon dust speckle | happyArc | rare | so well behaved a halo just appears |
| starling jr | #FBE3B0 | #E6BE68 | #FFF6D2 | constellation arc | star freckles | round | common | practicing being a whole constellation |
| violetwink | #B79CE0 | #8C6CC4 | #FFD7E2 | twin star antennae | galaxy swirl | round | rare | winks one star at a time, very deliberately |
| peachorbit | #FAD2B4 | #E8A878 | #C7B2E8 | ringed orbit dot | orbit rings | round | rare | one tiny moon and it loves that moon dearly |
| lullamoon | #DCD6E8 | #ABA2C9 | #F5DFA8 | crescent moon tuft | crescent belly glow | sleepy | common | hums you to sleep and falls asleep first |
| glimmerbit | #FFF1CC | #EAD183 | #FFFDEF | star antenna | moon dust speckle | round | common | so shiny it is hard to look directly at |
| dawnberry | #FBC9C0 | #E8978E | #FFE2A0 | sun rays crown | twilight gradient band | happyArc | common | the soft pink before the sun is fully up |
| eclipsi | #9A93B0 | #6A6385 | #FFE9A8 | crescent moon tuft | crescent belly glow | round | epic | quiet and rare, like the moment of eclipse |
| starwhisper | #C7D8E0 | #93AEBC | #E8C089 | aurora wisps | star freckles | sleepy | rare | tells secrets only the constellations hear |
| cozmo | #A6B8E0 | #768CC4 | #FFD08A | planet ring halo | orbit rings | round | epic | a tiny gas giant with a very big heart |
| sprinklestar | #FBD9E2 | #E89CB6 | #FFF0C2 | twin star antennae | star freckles | round | common | scatters happy sparkles when it bounces |
| moonbean | #EDE7D0 | #C8BE9A | #D9C2F0 | crescent moon tuft | moon dust speckle | round | common | a little bean that came back from the moon |
| auroric | #9CD0C4 | #65A89A | #E0B0F0 | aurora wisps | galaxy swirl | happyArc | epic | ripples with soft green and violet light |
| stargazel | #D2C4E8 | #A286C9 | #FFE0A8 | constellation arc | star freckles | round | rare | tilts its head back to find new stars |
| sunkit | #FFD27A | #EAA63A | #FFEDB0 | sun rays crown | crescent belly glow | happyArc | common | a small warm sunbeam in creature form |
| cinderstar | #E8C9A8 | #C99A6E | #FFE7B0 | comet swoosh | star freckles | round | rare | a warm ember drifting up into the dark |
| periwink | #B9C2E8 | #8794C9 | #FFD9C2 | twin star antennae | orbit rings | round | common | periwinkle blue and perpetually winking |
| galaxia | #B098D0 | #7E60AC | #F2A9C6 | nebula puff | galaxy swirl | round | legendary | holds a whole tiny galaxy in its belly |
| lunette | #E2DCEC | #B2A8CC | #FBE6A0 | crescent moon tuft | crescent belly glow | sleepy | common | a small soft moon that fits in your hands |
| brightnel | #FFF3D0 | #ECD68A | #FFFCEE | star antenna | moon dust speckle | happyArc | common | the brightest little night-light there is |
| stormnova | #94A0C4 | #636F98 | #FFCF8E | comet swoosh | galaxy swirl | round | epic | quiet now, but it remembers being a nova |
| dewstar | #CDE2DE | #9AC0BA | #E8C68C | constellation arc | moon dust speckle | round | common | a star that landed in the morning dew |
| ambermoon | #F0CE9A | #D29E5E | #B8A4E0 | crescent moon tuft | twilight gradient band | round | rare | the warm gold moon of a late harvest |
| pixiebeam | #F6CFE2 | #DC96B8 | #FFF0C4 | star antenna | star freckles | round | common | a beam of pink starlight with opinions |
| voidling | #8A86A6 | #5C5880 | #C8B4F0 | nebula puff | moon dust speckle | sleepy | epic | gentle, soft-spoken, made of cozy dark |
| solstice | #FFDFA0 | #E8B458 | #E0BCF0 | sun rays crown | orbit rings | happyArc | rare | the longest, sunniest, happiest day |
| meteorling | #D0C0B0 | #A28E78 | #FFD98C | comet swoosh | star freckles | round | common | a little falling star you got to keep |
| celestine | #BFD0E8 | #8FA8CC | #F4C6D2 | planet ring halo | orbit rings | round | epic | calm, pale blue, and quietly luminous |
| twinklepea | #DCE8C0 | #B0C488 | #E8C2F0 | twin star antennae | galaxy swirl | round | common | a sweet pea that grew under starlight |
| nocturne | #9690B8 | #645E8C | #FFE3A6 | crescent moon tuft | crescent belly glow | sleepy | rare | the gentle song the night hums to itself |
| sunpetal | #FFE4B0 | #ECBC68 | #F0C0D8 | sun rays crown | crescent belly glow | happyArc | common | unfolds toward any bit of warm light |
| cosmolette | #C8B2E8 | #9874C9 | #FFD2B8 | nebula puff | galaxy swirl | round | rare | a small swirl of cosmos in a comfy shape |
| starbun | #FBEAC8 | #E6C988 | #FFF8E0 | star antenna | star freckles | round | common | round as a bun and twice as warm |
| aurelune | #E6DDE8 | #BBAACC | #FFE0AE | crescent moon tuft | twilight gradient band | sleepy | legendary | the rare gold-lit moon seen once a year |

\* "twilight gradient band" listed as a top feature for `dusk plum` should use the
`aurora wisps` top feature instead if a non-pattern top look is required; the band is a
pattern, so `dusk plum` reads as wisps over a twilight body. (Kept the row's spirit; pick
`aurora wisps` as its implementable top feature.)

### Notes for implementation

- Top features map cleanly to new `CreatureStyle` cases (e.g. `.starAntenna`, `.crescentTuft`,
  `.ringHalo`, `.sunRays`, `.comet`, `.aurora`, `.constellation`, `.orbitDot`, `.nebula`,
  `.twinAntennae`), drawn exactly like the existing `sprout`/`tuft`/`ears` switch arms.
- Patterns map to a `BodyPattern` enum applied as `.overlay(...).clipShape(Circle())` inside
  `bodyCircle`, gated so `.none` adds nothing (matching the `.classic` no-op style).
- Accent hex becomes a third optional colour on `Vibe` (e.g. `accent: Color?`), defaulting to
  `nil` for the existing five vibes so nothing breaks.
- Combinatorial reach for the "912 species" claim: 14 top features (4 base + 10 new) x 7
  patterns (6 new + none) x the palette set easily clears 900 before the 48 curated names
  above are layered on top.
