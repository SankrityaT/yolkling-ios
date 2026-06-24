# Neck / Body Cosmetics

Design specs for the NECK slot of Yolkling. Every item is PURE SwiftUI vector
(Circle, Ellipse, Capsule, RoundedRectangle, Triangle, Diamond, StarShape,
small Path / arcs, gradients). No images, no emoji, no SF Symbols.

## Conventions (match `CosmeticView.swift`)

- All dimensions are multiples of the creature's `size` value.
- The NECK slot is drawn centred on the lower-body anchor (`CosmeticSlot.neck`
  uses `anchorY = 0.3`, the bottom third of the round body).
- `x = 0` is the centre. Negative `y` is UP, positive `y` is DOWN.
- Existing reference items (the quality bar): bow / bow tie (two rotated Ellipse
  loops plus a knot Circle), scarf (Capsule wrap plus a RoundedRectangle tail
  plus a knot Circle).
- Reusable shapes already in the project: `Triangle`, `Diamond`, `CrownShape`,
  `StarShape(innerRatio:)`. New shapes are defined at the bottom of this file.
- Cost guide: common 120, rare 250 to 300, epic 450 to 500. A couple are free (0).
- Each item is built as a `ZStack` so layer order (top of list draws underneath,
  bottom draws on top) matches the spec ordering described.

---

## 1. Knit Scarf

- **kind:** `knitScarf`
- **rarity:** common
- **cost:** 120
- **slot:** neck

A cozy chunky-knit wrap with a soft ribbed look and a single tail.

**Shapes (back to front):**
1. Wrap band: `Capsule` fill `#C56B7A`, frame `width size*0.58, height size*0.11`,
   offset `(0, -size*0.01)`.
2. Knit ribs: three `Capsule` strokes `#A8525F` lineWidth `size*0.012`, each
   `width size*0.02, height size*0.1`, offsets `x = -size*0.14, 0, size*0.14`,
   `y = -size*0.01`. (Short vertical ribs across the band for knit texture.)
3. Tail: `RoundedRectangle` cornerRadius `size*0.03` fill `#C56B7A`,
   frame `width size*0.11, height size*0.2`, offset `(size*0.14, size*0.15)`.
4. Tail ribs: two `Capsule` strokes `#A8525F` lineWidth `size*0.01`,
   `width size*0.015, height size*0.16`, offsets `x = size*0.115 and size*0.165`,
   `y = size*0.15`.
5. Knot: `Circle` fill `#B25C6A`, frame `size*0.12`, offset `(size*0.14, size*0.005)`.

---

## 2. Striped Scarf

- **kind:** `stripedScarf`
- **rarity:** common
- **cost:** 120
- **slot:** neck

A jolly two-tone candy-stripe scarf, both tails hanging.

**Shapes (back to front):**
1. Wrap band base: `Capsule` fill `#E86A6A`, frame `width size*0.58, height size*0.1`,
   offset `(0, -size*0.01)`.
2. Diagonal stripes: four `Capsule` fill `#F7F0E2`, each `width size*0.045,
   height size*0.13`, rotation `28 degrees`, offsets `x = -size*0.18, -size*0.06,
   size*0.06, size*0.18`, `y = -size*0.01`. (Use a `.clipShape` of the band Capsule
   so stripes stay inside.)
3. Left tail: `RoundedRectangle` cornerRadius `size*0.025` fill `#E86A6A`,
   frame `width size*0.09, height size*0.16`, offset `(-size*0.12, size*0.13)`.
4. Right tail: same `RoundedRectangle`, offset `(size*0.12, size*0.16)`.
5. Tail stripe accents: two `Capsule` fill `#F7F0E2` `width size*0.07,
   height size*0.018` across the bottom of each tail (offsets at the tail ends).

---

## 3. Chunky Cowl

- **kind:** `chunkyCowl`
- **rarity:** rare
- **cost:** 260
- **slot:** neck

An oversized soft cowl that swallows the lower body in cream wool.

**Shapes (back to front):**
1. Outer cowl: `Ellipse` fill gradient (`#F3E4CC` top to `#E3D0B2` bottom,
   `.linearGradient` top-to-bottom), frame `width size*0.62, height size*0.34`,
   offset `(0, size*0.02)`.
2. Inner hollow: `Ellipse` fill `#D8C29E`, frame `width size*0.4, height size*0.16`,
   offset `(0, -size*0.05)`. (The dark neck opening at the top.)
3. Ribbing: five `Capsule` strokes `#D8C29E` lineWidth `size*0.012`, each
   `width size*0.02, height size*0.24`, fanned across the cowl at offsets
   `x = -size*0.2, -size*0.1, 0, size*0.1, size*0.2`, `y = size*0.04`, with
   rotations `-12, -6, 0, 6, 12 degrees` so they splay outward.

---

## 4. Infinity Scarf

- **kind:** `infinityScarf`
- **rarity:** rare
- **cost:** 280
- **slot:** neck

A looped figure-eight scarf, no ends, modern and soft.

**Shapes (back to front):**
1. Lower loop: `Ellipse` stroke `#7FB3A3` lineWidth `size*0.05`,
   frame `width size*0.34, height size*0.22`, offset `(0, size*0.06)`.
2. Upper loop: `Ellipse` stroke `#9BC9BA` lineWidth `size*0.05`,
   frame `width size*0.5, height size*0.2`, offset `(0, -size*0.05)`.
3. Twist knot where loops cross: `Capsule` fill `#7FB3A3`,
   frame `width size*0.14, height size*0.07`, rotation `35 degrees`,
   offset `(size*0.02, size*0.0)`.

---

## 5. Bow Tie (classic) — variant palette

- **kind:** `dapperBowtie`
- **rarity:** common
- **cost:** 120
- **slot:** neck

A crisp formal bow tie (the reference bow geometry, navy + cream centre).

**Shapes (back to front):**
1. Left loop: `Ellipse` fill `#3E5C8A`, frame `width size*0.13, height size*0.17`,
   rotation `-28 degrees`, offset `(-size*0.06, 0)`.
2. Right loop: `Ellipse` fill `#3E5C8A`, same frame, rotation `28 degrees`,
   offset `(size*0.06, 0)`.
3. Centre knot: `Capsule` fill `#2E466B`, frame `width size*0.05, height size*0.09`,
   offset `(0, 0)`.

---

## 6. Polka Bow Tie

- **kind:** `polkaBowtie`
- **rarity:** common
- **cost:** 120
- **slot:** neck

A playful spotted bow tie.

**Shapes (back to front):**
1. Left loop: `Ellipse` fill `#E06A8C`, `width size*0.14, height size*0.18`,
   rotation `-28 degrees`, offset `(-size*0.065, 0)`.
2. Right loop: `Ellipse` fill `#E06A8C`, mirror, rotation `28 degrees`,
   offset `(size*0.065, 0)`.
3. Dots: four `Circle` fill `#FBE9EF` `size*0.028`, two per loop at offsets
   `(-size*0.085, -size*0.02), (-size*0.05, size*0.02)` and mirrored on the right.
4. Centre knot: `Circle` fill `#C8557A`, frame `size*0.07`, offset `(0, 0)`.

---

## 7. Necktie

- **kind:** `necktie`
- **rarity:** common
- **cost:** 120
- **slot:** neck

A little business necktie with a knot at the throat and a long blade.

**Shapes (back to front):**
1. Collar band: `Capsule` fill `#F4ECDD`, frame `width size*0.3, height size*0.05`,
   offset `(0, -size*0.08)`.
2. Knot: `Diamond` fill `#9B3F4E`, frame `width size*0.1, height size*0.1`,
   offset `(0, -size*0.04)`.
3. Blade: a `TieBlade` Path fill `#B24A5B` (new shape, see below), frame
   `width size*0.13, height size*0.26`, offset `(0, size*0.13)`.
4. Stripe accent: one `Capsule` fill `#8A3644` `width size*0.1, height size*0.018`,
   rotation `-18 degrees`, offset `(0, size*0.06)`.

---

## 8. Bandana

- **kind:** `bandana`
- **rarity:** common
- **cost:** 120
- **slot:** neck

A folded triangle kerchief tied at the throat, cowboy style.

**Shapes (back to front):**
1. Triangle drape: `Triangle` rotated `180 degrees` (point down) fill `#D85B5B`,
   frame `width size*0.42, height size*0.24`, offset `(0, size*0.05)`.
2. Paisley dots: five `Circle` fill `#F6E7C9` `size*0.025` scattered across the
   triangle at offsets `(-size*0.1, size*0.02), (0, size*0.04), (size*0.1, size*0.02),
   (-size*0.05, size*0.1), (size*0.05, size*0.1)`.
3. Fold band: `Capsule` fill `#C24E4E`, frame `width size*0.34, height size*0.05`,
   offset `(0, -size*0.06)`.
4. Knot: `Circle` fill `#A84141`, frame `size*0.07`, offset `(0, -size*0.06)`.

---

## 9. Bell Collar

- **kind:** `bellCollar`
- **rarity:** rare
- **cost:** 280
- **slot:** neck

A cat-style collar band with a buckle and a little golden bell.

**Shapes (back to front):**
1. Collar band: `Capsule` fill `#E0567E`, frame `width size*0.54, height size*0.06`,
   offset `(0, -size*0.02)`.
2. Buckle: `RoundedRectangle` cornerRadius `size*0.01` stroke `#C9C2B4`
   lineWidth `size*0.012`, frame `size*0.05`, offset `(-size*0.12, -size*0.02)`.
3. Bell body: `Circle` fill gradient (`#FFD25A` to `#E0A02E`, top-to-bottom),
   frame `size*0.11`, offset `(0, size*0.06)`.
4. Bell slot: `Capsule` fill `#C98E1E`, frame `width size*0.06, height size*0.014`,
   offset `(0, size*0.09)`.
5. Bell highlight: `Circle` fill `#FFF0C0` `size*0.025`, offset `(-size*0.02, size*0.04)`.
6. Bell loop: `Circle` stroke `#E0A02E` lineWidth `size*0.01`, frame `size*0.03`,
   offset `(0, size*0.01)`.

---

## 10. Frilly Ruff Collar

- **kind:** `ruffCollar`
- **rarity:** epic
- **cost:** 460
- **slot:** neck

A theatrical Elizabethan frill, a ring of soft scallops around the neck.

**Shapes (back to front):**
1. Ruff ring: a `ScallopRing` Path fill `#F7F0E6` with stroke `#E4D8C4`
   lineWidth `size*0.01` (new shape, see below), frame `width size*0.66,
   height size*0.34`, offset `(0, size*0.02)`. The scallops are twelve soft
   semicircle bumps around the outer edge.
2. Inner shadow ring: `Ellipse` fill `#E8DCC8`, frame `width size*0.34,
   height size*0.16`, offset `(0, -size*0.03)`. (Neck opening.)
3. Pleat lines: eight `Capsule` strokes `#E4D8C4` lineWidth `size*0.008`,
   `width size*0.015, height size*0.13`, radiating from centre at
   rotations `0, 45, 90, 135, 180, 225, 270, 315 degrees`, offset `(0, size*0.02)`.

---

## 11. Pearl Necklace

- **kind:** `pearlNecklace`
- **rarity:** rare
- **cost:** 270
- **slot:** neck

A dainty row of cream pearls on a gentle downward arc.

**Shapes (back to front):**
1. Seven `Circle` pearls `size*0.05` fill `#F7EFE2` with a `#E2D4BE` stroke
   lineWidth `size*0.006`, arranged along a shallow downward arc from
   `x = -size*0.18` to `x = size*0.18`. Suggested offsets:
   `(-size*0.18, -size*0.01), (-size*0.12, size*0.015), (-size*0.06, size*0.03),
   (0, size*0.04), (size*0.06, size*0.03), (size*0.12, size*0.015),
   (size*0.18, -size*0.01)`.
2. Pearl highlights: a tiny `Circle` fill `#FFFFFF` `size*0.016` on each pearl,
   offset up-left by `(-size*0.012, -size*0.012)` from each pearl centre.

---

## 12. Pendant Necklace

- **kind:** `pendantNecklace`
- **rarity:** rare
- **cost:** 290
- **slot:** neck

A thin chain with a sweet heart charm hanging at the centre.

**Shapes (back to front):**
1. Chain: a `ChainArc` Path stroke `#E3B23C` lineWidth `size*0.012` (new shape,
   a shallow downward arc), frame `width size*0.36, height size*0.12`,
   offset `(0, -size*0.01)`.
2. Bail (ring): `Circle` stroke `#E3B23C` lineWidth `size*0.01`, frame `size*0.035`,
   offset `(0, size*0.04)`.
3. Heart charm: a `HeartShape` Path fill gradient (`#FF8FB0` to `#E0567E`),
   frame `width size*0.11, height size*0.1`, offset `(0, size*0.1)`.
4. Charm shine: `Circle` fill `#FFD7E3` `size*0.02`, offset `(-size*0.02, size*0.08)`.

---

## 13. Star Pendant Necklace

- **kind:** `starPendant`
- **rarity:** epic
- **cost:** 470
- **slot:** neck

The pendant variant with a glinting gold star charm.

**Shapes (back to front):**
1. Chain: `ChainArc` Path stroke `#C9C2B4` lineWidth `size*0.012`,
   frame `width size*0.36, height size*0.12`, offset `(0, -size*0.01)`.
2. Bail: `Circle` stroke `#C9C2B4` lineWidth `size*0.01`, `size*0.035`,
   offset `(0, size*0.04)`.
3. Star charm: `StarShape(innerRatio: 0.45)` fill gradient (`#FFE08A` to `#E0A02E`)
   with stroke `#FFF6D8` lineWidth `size*0.006`, frame `size*0.14`,
   offset `(0, size*0.11)`.
4. Sparkle: a tiny `StarShape(innerRatio: 0.3)` fill `#FFFFFF` `size*0.03`,
   offset `(size*0.04, size*0.06)`.

---

## 14. Flower Lei

- **kind:** `flowerLei`
- **rarity:** epic
- **cost:** 480
- **slot:** neck

A garland of little flowers draped in a U around the neck. Reuses the existing
flower motif (five petal Circles plus a centre disk).

**Shapes (back to front):**
1. Vine: a `ChainArc` Path stroke `#86D38C` lineWidth `size*0.02`,
   frame `width size*0.5, height size*0.22`, offset `(0, size*0.02)`. (A U-shaped
   downward drape.)
2. Seven flowers along the vine. Each flower = five `Circle` petals `size*0.04`
   fill alternating `#FF94C2` / `#FFC6DD` / `#FFE08A` (per flower), each petal
   offset `y = -petal*0.6` and rotated `i*72 degrees` for i in 0..4, plus a
   `Circle` centre `size*0.025` fill `#FFD25A`.
   Flower centre offsets along the drape:
   `(-size*0.2, -size*0.02), (-size*0.14, size*0.04), (-size*0.07, size*0.08),
   (0, size*0.1), (size*0.07, size*0.08), (size*0.14, size*0.04),
   (size*0.2, -size*0.02)`.

---

## 15. Cape

- **kind:** `cape`
- **rarity:** epic
- **cost:** 480
- **slot:** neck

A heroic cape draped behind and under the body, with a clasp at the throat.

**Shapes (back to front, cape drapes UNDER everything):**
1. Cape drape: a `CapeShape` Path fill gradient (`#7B3FA0` top to `#5C2E7D` bottom),
   frame `width size*0.7, height size*0.5`, offset `(0, size*0.18)`. (A trapezoid
   that flares wider at the bottom with a gently wavy hem.)
2. Inner lining peek: `CapeShape` Path fill `#C9A0E0`, frame `width size*0.5,
   height size*0.36`, offset `(0, size*0.2)`. (A smaller inset showing lining.)
3. Left clasp: `Circle` fill gradient (`#FFD25A` to `#E0A02E`), `size*0.07`,
   offset `(-size*0.1, -size*0.06)`.
4. Right clasp: `Circle` fill gradient (`#FFD25A` to `#E0A02E`), `size*0.07`,
   offset `(size*0.1, -size*0.06)`.
5. Clasp cord: `Capsule` fill `#E0A02E`, `width size*0.22, height size*0.012`,
   offset `(0, -size*0.06)`. (Links the two clasps across the throat.)

---

## 16. Medal on a Ribbon

- **kind:** `medalRibbon`
- **rarity:** rare
- **cost:** 300
- **slot:** neck

A prize medal hanging from a V-shaped ribbon.

**Shapes (back to front):**
1. Ribbon left: `Capsule` fill `#4A7FC0`, `width size*0.05, height size*0.2`,
   rotation `18 degrees`, offset `(-size*0.06, -size*0.04)`.
2. Ribbon right: `Capsule` fill `#3E6BA8`, `width size*0.05, height size*0.2`,
   rotation `-18 degrees`, offset `(size*0.06, -size*0.04)`.
3. Medal disk: `Circle` fill gradient (`#FFE08A` to `#E0A02E`), `size*0.16`,
   offset `(0, size*0.1)`.
4. Inner ring: `Circle` stroke `#C98E1E` lineWidth `size*0.012`, `size*0.11`,
   offset `(0, size*0.1)`.
5. Star: `StarShape(innerRatio: 0.45)` fill `#C98E1E`, `size*0.08`,
   offset `(0, size*0.1)`.
6. Shine: `Circle` fill `#FFF6D8` `size*0.025`, offset `(-size*0.03, size*0.06)`.

---

## 17. Locket

- **kind:** `locket`
- **rarity:** rare
- **cost:** 290
- **slot:** neck

A sentimental oval locket on a fine chain.

**Shapes (back to front):**
1. Chain: `ChainArc` Path stroke `#E3B23C` lineWidth `size*0.012`,
   frame `width size*0.32, height size*0.1`, offset `(0, -size*0.02)`.
2. Bail: `Circle` stroke `#E3B23C` lineWidth `size*0.01`, `size*0.03`,
   offset `(0, size*0.035)`.
3. Locket body: `Ellipse` fill gradient (`#F4C95A` to `#D49A2A`),
   `width size*0.13, height size*0.16`, offset `(0, size*0.11)`.
4. Locket seam: `Capsule` fill `#C98E1E`, `width size*0.11, height size*0.008`,
   offset `(0, size*0.11)`. (Horizontal line where it opens.)
5. Heart engraving: `HeartShape` Path stroke `#C98E1E` lineWidth `size*0.008`,
   `width size*0.06, height size*0.055`, offset `(0, size*0.09)`.

---

## 18. Bib

- **kind:** `babyBib`
- **rarity:** common
- **cost:** 120
- **slot:** neck

A soft rounded baby bib with a scalloped bottom edge and a heart motif.

**Shapes (back to front):**
1. Bib body: a `BibShape` Path fill `#A7D8E8` (new shape, see below), frame
   `width size*0.42, height size*0.34`, offset `(0, size*0.1)`. (Rounded square
   with a neck notch cut out at the top.)
2. Scallop trim: a `ScallopRing` Path arc (bottom half only) stroke `#88C2D6`
   lineWidth `size*0.012` along the lower edge, frame `width size*0.4,
   height size*0.1`, offset `(0, size*0.22)`.
3. Heart motif: `HeartShape` Path fill `#F08FB0`, `width size*0.12,
   height size*0.11`, offset `(0, size*0.12)`.
4. Neck ties: two `Capsule` fill `#88C2D6`, `width size*0.04, height size*0.07`,
   offsets `(-size*0.16, -size*0.04)` and `(size*0.16, -size*0.04)`,
   rotations `-20 degrees` and `20 degrees`.

---

## 19. Backpack Strap

- **kind:** `backpackStrap`
- **rarity:** rare
- **cost:** 260
- **slot:** neck

Two padded straps crossing the body, with a chest clip. (The pack sits behind,
implied; only the front straps render.)

**Shapes (back to front):**
1. Left strap: `Capsule` fill `#E0A24A`, `width size*0.07, height size*0.42`,
   rotation `12 degrees`, offset `(-size*0.13, size*0.06)`.
2. Right strap: `Capsule` fill `#E0A24A`, `width size*0.07, height size*0.42`,
   rotation `-12 degrees`, offset `(size*0.13, size*0.06)`.
3. Strap stitching: two `Capsule` strokes `#C2842F` lineWidth `size*0.008`,
   `width size*0.04, height size*0.36`, matching each strap offset / rotation.
4. Chest strap: `Capsule` fill `#C2842F`, `width size*0.24, height size*0.04`,
   offset `(0, size*0.04)`.
5. Buckle: `RoundedRectangle` cornerRadius `size*0.008` fill `#6B4A1F`,
   `size*0.05`, offset `(0, size*0.04)`.

---

## 20. Sash

- **kind:** `sash`
- **rarity:** epic
- **cost:** 450
- **slot:** neck

A diagonal honorary sash across the body with a rosette and dangling ribbon ends.

**Shapes (back to front):**
1. Sash band: `Capsule` fill gradient (`#C0405A` to `#9B2E47`, along its length),
   `width size*0.66, height size*0.13`, rotation `-30 degrees`,
   offset `(size*0.02, size*0.04)`. (Runs shoulder to opposite hip.)
2. Trim line: `Capsule` stroke `#FFD25A` lineWidth `size*0.01`,
   `width size*0.6, height size*0.09`, rotation `-30 degrees`,
   offset `(size*0.02, size*0.04)`.
3. Rosette base: `StarShape(innerRatio: 0.7)` fill `#FFD25A` (a soft scalloped
   medallion via many points; or use `RosetteShape` below), `size*0.16`,
   offset `(-size*0.16, size*0.14)`.
4. Rosette centre: `Circle` fill `#C0405A`, `size*0.07`,
   offset `(-size*0.16, size*0.14)`.
5. Rosette button: `Circle` fill `#FFD25A` `size*0.03`,
   offset `(-size*0.16, size*0.14)`.
6. Ribbon tails: two `RoundedRectangle` cornerRadius `size*0.015` fill `#9B2E47`,
   `width size*0.05, height size*0.16`, offsets `(-size*0.21, size*0.24)` and
   `(-size*0.11, size*0.24)`, with a small `Triangle` (point up) notch cut from
   each bottom (or just rounded ends).

---

# New Reusable Shapes

Define these `Shape` structs (private, alongside the existing `Triangle`,
`Diamond`, `CrownShape` at the bottom of `CosmeticView.swift`).

## HeartShape

A classic cute heart: two top lobes meeting in a dip, tapering to a point at the
bottom. Drawn with two arcs/quad curves.

```
func path(in r: CGRect) -> Path {
    var p = Path()
    let w = r.width, h = r.height
    p.move(to: CGPoint(x: r.midX, y: r.minY + h * 0.28))
    // left lobe
    p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.28),
               control1: CGPoint(x: r.midX - w * 0.18, y: r.minY - h * 0.05),
               control2: CGPoint(x: r.minX, y: r.minY - h * 0.02))
    // down to the point
    p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
               control1: CGPoint(x: r.minX, y: r.minY + h * 0.55),
               control2: CGPoint(x: r.midX - w * 0.2, y: r.minY + h * 0.7))
    // up the right side
    p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.28),
               control1: CGPoint(x: r.midX + w * 0.2, y: r.minY + h * 0.7),
               control2: CGPoint(x: r.maxX, y: r.minY + h * 0.55))
    // right lobe back to start
    p.addCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.28),
               control1: CGPoint(x: r.maxX, y: r.minY - h * 0.02),
               control2: CGPoint(x: r.midX + w * 0.18, y: r.minY - h * 0.05))
    p.closeSubpath()
    return p
}
```

## ChainArc

A shallow downward arc, used as a necklace chain or garland vine. Just a single
open arc (apply `.stroke`, not fill). The arc dips to a low point at the centre.

```
func path(in r: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: r.minX, y: r.minY))
    p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                   control: CGPoint(x: r.midX, y: r.maxY * 1.4))
    return p
}
```

## ScallopRing

A ring whose outer edge is a sequence of small semicircle bumps (for the ruff
collar and the bib trim). Build by stepping around a circle and adding an arc bump
per step. For an open trim (bib), only sweep the lower half of the angle range.

```
// n bumps around an ellipse of the rect; each bump is a semicircle arc.
// For the full ruff ring use n = 12 over 0..2pi.
// For the bib trim use n = 6 over the lower arc only (pi*0.15 .. pi*0.85).
```

Concretely: for `i in 0..<n`, compute the angle, place a point on the ellipse
edge, and `addArc` a small radius bump (`radius = ringCircumferenceStep * 0.5`)
centred on that edge point, alternating so bumps face outward. Fill for the ruff,
stroke for the bib trim.

## CapeShape

A draped cape: a trapezoid narrow at the top (shoulders) flaring wide at the
bottom, with a gently wavy hem (two shallow scallops).

```
func path(in r: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: r.minX + r.width * 0.28, y: r.minY))     // top-left (shoulder)
    p.addLine(to: CGPoint(x: r.maxX - r.width * 0.28, y: r.minY))  // top-right (shoulder)
    p.addLine(to: CGPoint(x: r.maxX, y: r.maxY * 0.92))            // flare out right
    // wavy hem: two scallops back to the left
    p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control: CGPoint(x: r.midX + r.width * 0.25, y: r.maxY * 0.86))
    p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY * 0.92),
                   control: CGPoint(x: r.midX - r.width * 0.25, y: r.maxY * 0.86))
    p.closeSubpath()
    return p
}
```

## TieBlade

The hanging blade of a necktie: a narrow shape that comes to a downward point.

```
func path(in r: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: r.midX - r.width * 0.32, y: r.minY))   // top-left
    p.addLine(to: CGPoint(x: r.midX + r.width * 0.32, y: r.minY)) // top-right
    p.addLine(to: CGPoint(x: r.maxX, y: r.maxY * 0.72))          // widen
    p.addLine(to: CGPoint(x: r.midX, y: r.maxY))                 // point at bottom
    p.addLine(to: CGPoint(x: r.minX, y: r.maxY * 0.72))          // widen
    p.closeSubpath()
    return p
}
```

## RosetteShape (optional, for the sash)

A scalloped prize-rosette medallion: many small semicircle petals around a circle.
If you prefer to avoid a new shape, approximate with `StarShape(innerRatio: 0.7)`
at a high point count, or ring of small Circles. Concrete version: `n = 12`
petals, each a semicircle arc bump on a circle of radius `r.width*0.5`, similar to
`ScallopRing` but smaller and always filled.

---

# Catalog Wiring (for the implementer)

Add these `Kind` cases and `CosmeticCatalog` entries (all `slot: .neck`). Suggested
ids and costs:

| id | name | kind | rarity | cost |
|----|------|------|--------|------|
| knit-scarf | Knit Scarf | knitScarf | common | 120 |
| striped-scarf | Striped Scarf | stripedScarf | common | 120 |
| chunky-cowl | Chunky Cowl | chunkyCowl | rare | 260 |
| infinity-scarf | Infinity Scarf | infinityScarf | rare | 280 |
| dapper-bowtie | Dapper Bow Tie | dapperBowtie | common | 120 |
| polka-bowtie | Polka Bow Tie | polkaBowtie | common | 120 |
| necktie | Necktie | necktie | common | 120 |
| bandana | Bandana | bandana | common | 120 |
| bell-collar | Bell Collar | bellCollar | rare | 280 |
| ruff-collar | Ruff Collar | ruffCollar | epic | 460 |
| pearl-necklace | Pearl Necklace | pearlNecklace | rare | 270 |
| pendant-necklace | Heart Pendant | pendantNecklace | rare | 290 |
| star-pendant | Star Pendant | starPendant | epic | 470 |
| flower-lei | Flower Lei | flowerLei | epic | 480 |
| cape | Cape | cape | epic | 480 |
| medal-ribbon | Medal | medalRibbon | rare | 300 |
| locket | Locket | locket | rare | 290 |
| baby-bib | Bib | babyBib | common | 120 |
| backpack-strap | Backpack Strap | backpackStrap | rare | 260 |
| sash | Sash | sash | epic | 450 |

Rarity spread: 8 common, 8 rare, 4 epic (20 items). No free items in this set
(the existing `bow` at cost 0 already covers the free neck starter); flip any
`common` to cost 0 if a second free neck item is wanted.
```
