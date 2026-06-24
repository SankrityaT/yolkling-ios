# Ocean family

Soft tide-pool creatures: fish, bubbles, pearls, shells, coral, jellyfish, seafoam,
gentle waves, starfish, little fins. Palette leans aqua, seafoam green, pearl cream,
coral pink, muted deep-sea blue, sandy beige. Everything is cozy, rounded, and
readable on the cream `#FBF6EC` app background.

All specs use the same coordinate system as `YolklingView`: a single `size` value,
offsets as multiples of `size`, y grows DOWNWARD, the head sits near `y = 0` and top
features live around `y = -size*0.4 .. -size*0.6`. Colours are either `vibe.body`,
`vibe.deep`, or a literal `Color(hex: 0xRRGGBB)`. Body patterns are drawn as an
overlay on the body `Circle()` and must be wrapped in `.clipShape(Circle())` so they
never spill past the silhouette. Nothing here uses images, emoji, or SF Symbols for a
body part (one optional accessory notes an alternative, with a pure-shape fallback).

A shared shape used by several features below:

```swift
// A soft, rounded triangle for fins, crests and shell points. Corners are
// pulled in slightly so nothing reads as sharp. Drawn pointing UP in its rect.
struct SoftFin: Shape {
    var round: CGFloat = 0.22   // 0 = sharp, ~0.3 = very soft
    func path(in r: CGRect) -> Path {
        var p = Path()
        let apex = CGPoint(x: r.midX, y: r.minY + r.height * round)
        let bl   = CGPoint(x: r.minX + r.width * round, y: r.maxY)
        let br   = CGPoint(x: r.maxX - r.width * round, y: r.maxY)
        p.move(to: bl)
        p.addQuadCurve(to: apex, control: CGPoint(x: r.minX, y: r.minY)) // left edge bows out
        p.addQuadCurve(to: br,   control: CGPoint(x: r.maxX, y: r.minY)) // right edge bows out
        p.addQuadCurve(to: bl,   control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.18)) // soft base
        p.closeSubpath()
        return p
    }
}
```

---

## New top features

Each is a `@ViewBuilder` returning a small `ZStack`, drawn in the `topFeature()`
switch behind the head (same layer the existing `ears` / `sprout` / `tuft` use).
Keep each to a handful of shapes.

### 1. dorsalFin
A single fin standing up on the crown, the classic "little fish" silhouette.
- `SoftFin(round: 0.22)` fill `vibe.deep`, frame `width size*0.18`, `height size*0.22`, offset `y -size*0.5`.
- Highlight rib: a `Capsule()` fill `vibe.body.opacity(0.45)`, frame `width size*0.02`, `height size*0.13`, offset `y -size*0.5` (sits on the fin, slight left lean `rotationEffect(.degrees(-6))`).

### 2. seashell
A scallop shell sitting on top like a little hat.
- Base: `Ellipse()` fill `vibe.body`, frame `width size*0.30`, `height size*0.20`, offset `y -size*0.47`.
- Three ridges: three `Capsule()` fill `vibe.deep.opacity(0.35)`, each `width size*0.022`, `height size*0.16`, offset `y -size*0.47`, fanned by `rotationEffect(.degrees(d))` with `d = -22, 0, 22` (anchor `.bottom`).
- Hinge knob: `Circle()` fill `vibe.deep`, frame `width size*0.06`, `height size*0.06`, offset `y -size*0.39` (at the shell's bottom centre).

### 3. bubbleCluster
Three rising bubbles, like the creature just exhaled.
- Big: `Circle()` fill `Color(hex: 0xCFEFF4).opacity(0.85)`, frame `size*0.12`, offset `x -size*0.05, y -size*0.46`.
- Mid: `Circle()` fill `Color(hex: 0xCFEFF4).opacity(0.8)`, frame `size*0.085`, offset `x size*0.07, y -size*0.54`.
- Small: `Circle()` fill `Color(hex: 0xCFEFF4).opacity(0.75)`, frame `size*0.055`, offset `x -size*0.02, y -size*0.6`.
- Each bubble gets a tiny `Circle()` glint fill `.white.opacity(0.9)`, frame `size*0.02`, offset to the bubble's upper-left. Outline each with `.overlay(Circle().stroke(Color(hex: 0x9FD3DC), lineWidth: size*0.006))`.

### 4. coralSprig
A little branching coral antler.
- Stem: `Capsule()` fill `Color(hex: 0xF2A6A0)`, frame `width size*0.035`, `height size*0.16`, offset `y -size*0.52`.
- Left branch: `Capsule()` fill `Color(hex: 0xF2A6A0)`, frame `width size*0.03`, `height size*0.1`, `rotationEffect(.degrees(-38))`, offset `x -size*0.05, y -size*0.56`.
- Right branch: `Capsule()` fill `Color(hex: 0xF7B8B0)`, frame `width size*0.03`, `height size*0.09`, `rotationEffect(.degrees(34))`, offset `x size*0.05, y -size*0.55`.
- Three tip nubs: small `Circle()` fill `Color(hex: 0xF7C2BB)`, frame `size*0.04`, at the top of each branch and the stem.

### 5. waveCrest
A gentle curl of water breaking over the head, like a quiff made of sea.
- Use a `Path` curl (reuse `TuftShape` styling) stroked `Color(hex: 0x86C7E0)`, lineWidth `size*0.05`, lineCap `.round`, frame `width size*0.26`, `height size*0.14`, offset `y -size*0.49`.
- Foam: two `Circle()` fill `.white.opacity(0.9)`, frame `size*0.05` and `size*0.035`, tucked at the crest's leading curl, offsets `x -size*0.09, y -size*0.52` and `x -size*0.12, y -size*0.49`.

### 6. jellyTendrils
A tiny jelly bell with three drooping tendrils, sitting like a cap.
- Bell: a half-`Ellipse()` look using `Ellipse()` fill `Color(hex: 0xD7C2EC).opacity(0.85)`, frame `width size*0.26`, `height size*0.18`, offset `y -size*0.5`. Clip the lower half visually with a thin `Rectangle()` of `vibe.body` is not needed; the dome reads fine as a full soft ellipse.
- Scallop trim: three small `Circle()` fill `Color(hex: 0xD7C2EC)`, frame `size*0.05`, along the bell's bottom edge, offsets `x -size*0.07, 0, size*0.07`, all `y -size*0.43`.
- Tendrils: three `Capsule()` fill `Color(hex: 0xE3D6F2).opacity(0.8)`, frame `width size*0.018`, `height size*0.12`, offsets `x -size*0.06, 0, size*0.06`, `y -size*0.36`, each with a slight `rotationEffect(.degrees(d))`, `d = -8, 2, 9` for a soft sway.

### 7. starfishCrown
A single chubby starfish perched on top.
- Body: a 5-point star as a `Path` of five `addQuadCurve` lobes (rounded points), fill `Color(hex: 0xF6B27A)`, frame `width size*0.24`, `height size*0.24`, offset `y -size*0.5`. If a star `Path` is too heavy, fallback is five overlapping `Capsule()` arms (each `width size*0.07`, `height size*0.16`, fanned `rotationEffect` at `0, 72, 144, 216, 288` degrees, anchor `.bottom`) over a centre `Circle()`.
- Dots: three `Circle()` fill `Color(hex: 0xE89A5E)`, frame `size*0.02`, scattered on the centre.

### 8. pearlTiara
A delicate row of pearls arched over the brow.
- Five `Circle()` fill `Color(hex: 0xF7EFE2)`, frames `size*0.04, 0.05, 0.06, 0.05, 0.04` left to right, each with `.overlay(Circle().stroke(Color(hex: 0xE2D4BE), lineWidth: size*0.005))` and a `.white` glint dot.
- Arch them: offsets `x = -size*0.12, -size*0.06, 0, size*0.06, size*0.12` with `y = -size*0.42, -size*0.46, -size*0.48, -size*0.46, -size*0.42` (centre pearl highest).

### 9. anglerLantern
One soft glowing orb on a thin stalk (a cozy, friendly anglerfish, never scary).
- Stalk: `Capsule()` fill `vibe.deep`, frame `width size*0.022`, `height size*0.18`, `rotationEffect(.degrees(-12))`, offset `x -size*0.02, y -size*0.5`.
- Lantern: `Circle()` fill `RadialGradient(colors: [Color(hex: 0xFFF6C9), Color(hex: 0xFFE08A)], center: .center, startRadius: 0, endRadius: size*0.07)`, frame `size*0.12`, offset `x -size*0.08, y -size*0.6`.
- Glow: same `Circle()` behind it, fill `Color(hex: 0xFFE08A).opacity(0.35)`, frame `size*0.2`, `.blur(radius: size*0.03)`, same offset.

### 10. finFan
A wide, low pectoral-style fan that hugs the top of the head (subtler than dorsalFin).
- `SoftFin(round: 0.3)` fill `vibe.body`, frame `width size*0.34`, `height size*0.14`, offset `y -size*0.44`.
- Three rays: three `Capsule()` fill `vibe.deep.opacity(0.3)`, `width size*0.016`, `height size*0.1`, offset `y -size*0.44`, fanned `rotationEffect(.degrees(d))` `d = -16, 0, 16`, anchor `.bottom`.

---

## New patterns

Body markings, drawn as an `.overlay` on the body `Circle()` and wrapped in
`.clipShape(Circle())`. Offsets are relative to the body centre (the body fills
`width size`, `height size`). Keep opacities low so the face stays the hero.

### 1. scaleSpeckle
Soft fish-scale crescents over the lower body.
- A grid of ~9 small crescents: each is an `Ellipse()` fill `vibe.deep.opacity(0.18)`, frame `width size*0.1`, `height size*0.06`, with a slightly offset `vibe.body` ellipse masking the top to leave a crescent (or simply use a thin `Arc`/`Capsule` if masking is fussy).
- Layout: 3 rows of 3, centred at `y = size*0.1, size*0.22, size*0.34`, x at `-size*0.18, 0, size*0.18`, alternate rows nudged `x += size*0.09`. Lower scales slightly larger.

### 2. pearlBelly
A glossy pale sheen low and centre, like a fish's pale underside.
- `Ellipse()` fill `LinearGradient(colors: [Color(hex: 0xFBF3E6).opacity(0.85), .clear], startPoint: .bottom, endPoint: .top)`, frame `width size*0.6`, `height size*0.5`, offset `y size*0.22`.
- A faint crescent highlight: `Capsule()` fill `.white.opacity(0.35)`, frame `width size*0.28`, `height size*0.04`, offset `y size*0.12`, `.blur(radius: size*0.02)`.

### 3. bubbleDots
A scatter of tiny rising bubbles across the body.
- Seven `Circle()` fill `Color(hex: 0xCFEFF4).opacity(0.5)`, frames between `size*0.03` and `size*0.07`, each `.overlay(Circle().stroke(Color(hex: 0x9FD3DC).opacity(0.5), lineWidth: size*0.004))`.
- Offsets (x, y): `(-0.22, 0.18), (0.2, 0.05), (-0.05, 0.3), (0.28, 0.26), (-0.28, -0.02), (0.08, -0.12), (0.16, 0.34)` times `size`. Add a `.white.opacity(0.8)` glint to the three largest.

### 4. waveStripe
A single horizontal wave band wrapping the belly.
- A `WaveStrip` `Shape` (a sine band): two stacked sine paths filled between, fill `vibe.deep.opacity(0.22)`, frame `width size`, `height size*0.12`, offset `y size*0.12`.
- Quick version without a custom shape: a `Capsule()` fill `vibe.deep.opacity(0.18)`, frame `width size*1.1`, `height size*0.08`, `rotationEffect(.degrees(-4))`, offset `y size*0.14`, topped by a thin `vibe.body.opacity(0.5)` capsule for a crest line.

### 5. seafoamFreckles
A light dusting of seafoam dots high on the cheeks/forehead.
- Eight `Circle()` fill `Color(hex: 0xB7E3D4).opacity(0.6)`, frames `size*0.018 .. size*0.03`.
- Cluster two arcs under where the eyes sit: left arc centred `x -size*0.2`, right arc centred `x size*0.2`, both around `y size*0.04`, dots spread `±size*0.06`. Reads as freckles, ties into the cheek blush.

### 6. tidalGradientBand
A diagonal deeper-water band across the upper body (a shadow of the sea above).
- `Rectangle()` fill `LinearGradient(colors: [vibe.deep.opacity(0.22), .clear], startPoint: .topLeading, endPoint: .center)`, frame `width size*1.4`, `height size*1.4`, `rotationEffect(.degrees(-18))`, offset `y -size*0.2`. Clipped to the body circle this gives a soft top-left depth shadow distinct from the base radial gradient.

---

## Accessories

Small worn cosmetics, drawn in front of the body (the existing `outfit` layer
slot). Pure shapes. Optional, tasteful.

### 1. pearlNecklace (neck slot)
- A shallow arc of five `Circle()` fill `Color(hex: 0xF7EFE2)`, frames `size*0.04 .. size*0.055`, each with a `.white` glint and a `Color(hex: 0xE2D4BE)` 1px stroke.
- Arc across the lower face: x at `-size*0.16, -size*0.08, 0, size*0.08, size*0.16`, y dipping `size*0.3 .. size*0.36` (centre lowest). Thread hint: a thin `Capsule()` fill `Color(hex: 0xE2D4BE).opacity(0.4)` behind, following the arc.

### 2. shellHairclip (top-side slot)
- One small `seashell` (see top features), scaled to `width size*0.16`, `height size*0.11`, fill `Color(hex: 0xF2A6A0)` with `Color(hex: 0xD98079)` ridges, offset to one side `x size*0.22, y -size*0.3`, `rotationEffect(.degrees(18))`. Clips onto the head like a barrette.

### 3. snorkelMask (face slot, playful)
- Mask band: `Capsule()` stroke `Color(hex: 0x6FB7D6)`, lineWidth `size*0.03`, frame `width size*0.46`, `height size*0.2`, offset `y -size*0.07` (rings the eyes).
- Lens glint: a thin `Capsule()` fill `.white.opacity(0.3)` across the band, `width size*0.3`, `height size*0.03`, `rotationEffect(.degrees(-14))`.
- Snorkel tube: a `Capsule()` fill `Color(hex: 0xF2A6A0)`, `width size*0.04`, `height size*0.22`, offset `x size*0.26, y -size*0.12`, with a short bent top `Capsule()` of the same colour rotated `90°`. (Whimsical, still a hat-like accessory.)

### 4. kelpScarf (neck slot)
- Two soft `Capsule()` ribbons fill `Color(hex: 0x7FB98C)` and `Color(hex: 0x9AD0A2)`, `width size*0.06`, `height size*0.26`, offset `x -size*0.2, y size*0.34` and `x -size*0.14, y size*0.4`, both `rotationEffect(.degrees(12 / 20))`, draping down one side like trailing kelp. A short `Capsule()` band across the neck `width size*0.4`, `height size*0.07`, ties them on.

---

## Species

40 base names below. Each row: `name | body hex | deep hex | accent hex | top feature | pattern | eye style | rarity | personality`.
Eye style defaults to `round` (the others, `happyArc / sleepy / heart / sparkle`,
already exist in `YolkExpression`). Accent hex is the colour for coloured features
(coral, jelly, pearl, lantern, kelp) where it differs from body/deep; `-` means the
feature uses its own built-in literals.

The marketing "912 species" is met combinatorially: 10 new + 4 base = 14 top features,
6 new patterns + `none` = 7 patterns, and a curated palette set. 14 x 7 = 98 feature
pairings, times even a modest 10-palette set already clears 900 once colour variants
count; the 40 named species below are the hand-curated, lore-bearing subset.

| name | body | deep | accent | top feature | pattern | eye | rarity | personality |
|------|------|------|--------|-------------|---------|-----|--------|-------------|
| guppy | #BFE7E0 | #7FC2BC | - | dorsalFin | scaleSpeckle | round | common | a wiggly little starter fish, always first to the food bowl |
| minnow | #CDEAF2 | #8FBFD8 | - | dorsalFin | bubbleDots | round | common | small, fast, easily delighted by literally anything |
| puddle | #C9E8E2 | #93C9BE | - | classic | pearlBelly | round | common | a calm drop of pond, content to just sit and shimmer |
| dewfish | #D6EFE6 | #9AD0BE | - | finFan | seafoamFreckles | happyArc | common | morning-fresh and a bit dewy-eyed, loves a slow start |
| tadpole | #C3E2D6 | #84B79E | - | tuft | waveStripe | round | common | not sure what it'll grow into yet, optimistic about it |
| pebbleperch | #DDE3D2 | #A9B193 | - | classic | scaleSpeckle | round | common | a sandy riverbed sitter, steady and unbothered |
| sandyfin | #EAD9B8 | #C2A876 | - | dorsalFin | waveStripe | round | common | warm shallows kid, always a little sun-toasted |
| brine | #B7D8DC | #7FACB3 | - | finFan | bubbleDots | round | common | tangy little tidepool gremlin, surprisingly sweet |
| ripple | #C6E6EE | #8CBED2 | - | waveCrest | waveStripe | round | common | leaves tiny rings wherever it goes, can't sit still |
| froth | #E4F1EE | #B2D4CC | - | waveCrest | bubbleDots | happyArc | common | mostly foam and giggles, dissolves into laughter |
| seaspray | #D2ECEC | #9BCAC8 | - | bubbleCluster | seafoamFreckles | round | common | bubbly to a fault, narrates its own adventures |
| spritzle | #CFEFF4 | #95CDD6 | #CFEFF4 | bubbleCluster | bubbleDots | sparkle | common | a fizzy soda of a fish, all pop and sparkle |
| pearlpup | #F7EFE2 | #D8C7A8 | #F7EFE2 | pearlTiara | pearlBelly | round | rare | soft and lustrous, treats everyone like royalty |
| nacre | #F2EFE6 | #CFC6B0 | #F7EFE2 | pearlTiara | pearlBelly | happyArc | rare | quietly elegant, hums to itself in mother-of-pearl |
| oysterling | #E6E1D4 | #B9AE95 | #F7EFE2 | seashell | pearlBelly | sleepy | rare | a homebody who keeps its treasures very close |
| cocklewho | #EDD9CE | #C49F8C | - | seashell | scaleSpeckle | round | rare | nosy little scallop, collects gossip like sand |
| conchita | #F4DCC9 | #CFA286 | - | seashell | waveStripe | round | rare | holds it up to your ear and you hear the whole sea |
| coralla | #F6C9BF | #E08C82 | #F2A6A0 | coralSprig | seafoamFreckles | heart | rare | grows a little prettier the longer you love it |
| reefling | #F2B7AE | #D98079 | #F2A6A0 | coralSprig | scaleSpeckle | round | rare | builds tiny cozy nooks for smaller creatures |
| poppyreef | #FBC4B4 | #E89684 | #F7B8B0 | coralSprig | bubbleDots | happyArc | rare | bright and branching, hosts the whole neighbourhood |
| starlet | #F6B27A | #D98E52 | #F6B27A | starfishCrown | scaleSpeckle | sparkle | rare | five-pointed and fabulous, regrows from any setback |
| seastarla | #F2A95E | #C97E3C | #F6B27A | starfishCrown | seafoamFreckles | round | rare | slow and deliberate, gets there exactly when needed |
| dapplefin | #C8E4D8 | #8DB9A6 | - | dorsalFin | scaleSpeckle | round | rare | speckled like sun through shallow water, very chill |
| glimmerguppy | #CDEBE6 | #8EC6BD | #FFF6C9 | dorsalFin | bubbleDots | sparkle | rare | catches every glint of light and shows it off |
| tidetuft | #BCDDE8 | #82B4C6 | - | waveCrest | tidalGradientBand | round | rare | wears the sea like a quiff, moody in a gentle way |
| foamcrest | #E0EFEC | #ABCFC6 | - | waveCrest | pearlBelly | happyArc | rare | the friendly wave that always rolls back for you |
| snorkelpip | #C4E2EE | #86B6CC | #F2A6A0 | finFan | bubbleDots | round | rare | suited up and ready, narrates the reef tour for free |
| anemonia | #D8C2E0 | #A988BC | #F2A6A0 | coralSprig | seafoamFreckles | round | rare | sways softly and hugs back, surprisingly clingy |
| kelpkin | #A9CBA0 | #729B6A | #7FB98C | sprout | waveStripe | round | rare | a forest-of-the-sea kid, trails greenery everywhere |
| seagrasling | #B7CF9C | #82A064 | #9AD0A2 | sprout | seafoamFreckles | round | rare | meadow-minded, sways with currents most can't feel |
| jellybean | #D7C2EC | #A988CC | #D7C2EC | jellyTendrils | bubbleDots | round | epic | drifts wherever the day takes it, soft and weightless |
| moonjelly | #DCD2EE | #B0A4D6 | #D7C2EC | jellyTendrils | pearlBelly | sleepy | epic | glows faint and pale, keeps the late, quiet hours |
| lumijelly | #C9D6F0 | #95A6D6 | #E3D6F2 | jellyTendrils | tidalGradientBand | sparkle | epic | bioluminescent dreamer, blinks in slow morse code |
| bloomjelly | #F0C7DE | #D690B4 | #D7C2EC | jellyTendrils | seafoamFreckles | heart | epic | trails ribbons of colour, falls in love constantly |
| lanternlot | #FFE3A8 | #E0B25E | #FFE08A | anglerLantern | tidalGradientBand | round | epic | carries a tiny light so nobody's path goes dark |
| deepglow | #9FB6CC | #647F9E | #FFE08A | anglerLantern | pearlBelly | round | epic | lives where it's quiet and deep, gentle and warm |
| abysscot | #8FA6C0 | #586F8E | #FFF6C9 | anglerLantern | tidalGradientBand | sleepy | epic | far down and unhurried, befriends the lonely dark |
| pearl-of-tides | #FBF3E6 | #DCC9A4 | #F7EFE2 | pearlTiara | pearlBelly | sparkle | legendary | a single perfect pearl given a heartbeat, utterly serene |
| coralqueen | #F7B5A6 | #D87A6C | #F2A6A0 | coralSprig | scaleSpeckle | heart | legendary | the whole reef leans toward her, ancient and kind |
| leviabelle | #7FA8C4 | #4E7396 | #FFE08A | anglerLantern | tidalGradientBand | sparkle | legendary | the gentle giant of the deep, a lighthouse with fins |
</content>
</invoke>
