# Eyes / Face Accessories

Design specs for the EYES slot of Yolkling cosmetics. Every item is pure SwiftUI vector
shapes, drawn centred on the eye line. In each item's own coordinate space, x = 0 is the
point between the two eyes, the two eyes sit at x = ±size*0.2, and negative y is UP. All
sizes are multiples of the creature's `size` value (default 220). Colours are real hex,
used as `Color(hex: 0x...)`.

## Conventions reused from CosmeticView.swift

- Frame ink: `#2A241B`. Default stroke for outlines: `lineWidth size*0.022`.
- Existing reusable shapes you may use directly: `StarShape(innerRatio:)`, `Triangle`,
  `Diamond` (in CosmeticView.swift / CreatureParts.swift).
- Two-lens items: build one lens view, place it at `.offset(x: -size*0.2)` and
  `.offset(x: size*0.2)`, joined by a bridge `Rectangle` centred at x = 0.
- Keep every item to a handful of shapes. Soft, rounded, cute, readable at small scale.

## New reusable Shapes (define once, reuse across items)

- **HeartShape** — a Path in a unit-ish rect: start at bottom point
  `(midX, maxY)`, addQuadCurve up the left side to the left top dip, two
  arcs/quads forming the two top lobes meeting at `(midX, minY + h*0.28)`, then
  symmetric down the right side back to the bottom point. Concretely: move to
  `(midX, maxY)`; addCurve to `(minX, midY*0.7)` controls `(midX*0.55, maxY*0.95)`
  and `(minX, midY)`; addArc left lobe centred `(minX + w*0.25, minY + h*0.28)`
  radius `w*0.25`; addArc right lobe centred `(maxX - w*0.25, minY + h*0.28)`
  radius `w*0.25`; addCurve back to `(midX, maxY)` controls `(maxX, midY)` and
  `(midX*1.45, maxY*0.95)`. Closed.
- **CatEyeLens** — an Ellipse-like Path with the OUTER top corner pulled up to a
  soft point: trace an ellipse `w x h` but replace the outer-top quadrant with a
  quad curve that overshoots to `(outerX, minY - h*0.28)` then curves back in. Mirror
  horizontally for the opposite eye (use `.scaleEffect(x: -1)` on the right lens).
- **HalfMoonLens** — the bottom half of a Circle: Path that is a semicircle, flat
  edge on top. Arc from `(minX, midY)` to `(maxX, midY)` sweeping downward through
  `(midX, maxY)`, then close along the top straight edge.
- **CrescentShape** (sleep-mask body) — a wide soft lozenge: a Capsule is enough,
  but the mask uses a RoundedRectangle with a gentle bottom bow (a Path: rounded
  rect whose bottom edge dips via one quad curve through `(midX, maxY + h*0.12)`).
- **DominoMaskShape** — a single Path covering both eyes: a wide rounded band with
  two eye holes is awkward in one Path, so build the mask as a filled
  RoundedRectangle with two Circle "holes" punched via `.blendMode(.destinationOut)`
  inside a `.compositingGroup()`. Spec per item below.
- **TearShape** (for the single hanging gem / bindi drop variant) — a Path: circle
  bottom with a pulled-up point at top. Move to `(midX, minY)`; addQuadCurve to
  `(maxX, midY + h*0.1)` control `(maxX, minY + h*0.2)`; addArc bottom semicircle
  to `(minX, midY + h*0.1)`; addQuadCurve back to `(midX, minY)` control
  `(minX, minY + h*0.2)`. Closed.

---

## 1. Round Reading Glasses

- **name:** Round Specs
- **kind:** `roundReadingGlasses`
- **rarity:** common
- **cost:** 120

**Shapes**
- Bridge: `Rectangle` fill `#2A241B`, `size*0.14 x size*0.022`, centred x = 0, y = 0.
- Left lens: `Circle` stroke `#2A241B` `lineWidth size*0.022`, `size*0.22 x size*0.22`, offset x = -size*0.2.
- Right lens: same Circle, offset x = +size*0.2.
- Two temple arms: `Rectangle` fill `#2A241B`, `size*0.06 x size*0.018`, offset x = ±size*0.31, y = -size*0.01, rotation ±8°.
- Soft reflection: small `Ellipse` fill `#FFFFFF` opacity 0.45, `size*0.05 x size*0.035`, offset x = (-size*0.2 + size*0.05), y = -size*0.05 on each lens.

This is the clean baseline round frame, warmer than the free starter glasses thanks to temple arms and a glint.

---

## 2. Square Glasses

- **name:** Square Frames
- **kind:** `squareGlasses`
- **rarity:** common
- **cost:** 120

**Shapes**
- Bridge: `Rectangle` fill `#2A241B`, `size*0.13 x size*0.022`, x = 0, y = -size*0.02.
- Left lens: `RoundedRectangle(cornerRadius: size*0.03)` stroke `#2A241B` `lineWidth size*0.022`, `size*0.24 x size*0.19`, offset x = -size*0.2.
- Right lens: same, offset x = +size*0.2.
- Glint: `Capsule` fill `#FFFFFF` opacity 0.4, `size*0.02 x size*0.07`, rotation 22°, offset toward inner-top of each lens (x = ∓size*0.16, y = -size*0.04).

Friendly rounded-square hipster frame.

---

## 3. Cat-Eye Glasses

- **name:** Cat-Eye Glasses
- **kind:** `catEyeGlasses`
- **rarity:** rare
- **cost:** 280

**Shapes**
- Bridge: `Rectangle` fill `#2A241B`, `size*0.14 x size*0.022`, x = 0, y = -size*0.01.
- Left lens: `CatEyeLens` stroke `#2A241B` `lineWidth size*0.022`, base ellipse `size*0.22 x size*0.16`, outer top corner pulled up to `+size*0.04`. Offset x = -size*0.2 (outer = left).
- Right lens: same `CatEyeLens` mirrored via `.scaleEffect(x: -1)`, offset x = +size*0.2.
- Optional tint fill: each lens fill `#F4A6C0` opacity 0.25 behind the stroke for a soft rosy lens.

Classic upswept cat-eye; the lifted outer points read as playful even at thumbnail size.

---

## 4. Half-Moon Reading Glasses

- **name:** Half-Moon Readers
- **kind:** `halfMoonGlasses`
- **rarity:** rare
- **cost:** 250

**Shapes**
- Bridge: `Rectangle` fill `#C9962E` (gold), `size*0.12 x size*0.018`, x = 0, y = +size*0.02 (bridge sits low, glasses ride down the nose).
- Left lens: `HalfMoonLens` stroke `#C9962E` `lineWidth size*0.02`, `size*0.2 x size*0.11`, flat edge on top, offset x = -size*0.2, y = +size*0.02.
- Right lens: same, offset x = +size*0.2, y = +size*0.02.
- Lens fill: each `#FFFFFF` opacity 0.18.

Grandparent-cozy half-glasses perched low. Gold wire frame for warmth.

---

## 5. Heart Glasses

- **name:** Heart Glasses
- **kind:** `heartGlasses`
- **rarity:** rare
- **cost:** 280

**Shapes**
- Bridge: `Rectangle` fill `#E0567E`, `size*0.1 x size*0.02`, x = 0, y = 0.
- Left lens: `HeartShape` fill `#FF8FB3` opacity 0.55, with `HeartShape` stroke `#E0567E` `lineWidth size*0.02` overlay, frame `size*0.22 x size*0.2`, offset x = -size*0.2.
- Right lens: same, offset x = +size*0.2.
- Sparkle: tiny `StarShape(innerRatio: 0.4)` fill `#FFFFFF` opacity 0.7, `size*0.05 x size*0.05`, offset x = -size*0.16, y = -size*0.03 (left lens only).

Pink heart-shaped lenses, the cutest sweetheart staple.

---

## 6. Aviator Sunglasses

- **name:** Aviators
- **kind:** `aviatorSunglasses`
- **rarity:** rare
- **cost:** 280

**Shapes**
- Bridge: a shallow `Capsule` fill `#C9962E`, `size*0.1 x size*0.016`, x = 0, y = -size*0.04 (top bar between lenses, like the classic double bridge).
- Left lens: `RoundedRectangle(cornerRadius: size*0.06)` fill `LinearGradient(#3A4A66 → #1E2738, top→bottom)`, `size*0.24 x size*0.2`, with the bottom outer corner slightly larger radius (use teardrop: scale a Circle? keep RoundedRectangle for simplicity), offset x = -size*0.2.
- Right lens: same, offset x = +size*0.2.
- Frame ring: each lens overlaid with `RoundedRectangle(cornerRadius: size*0.06)` stroke `#C9962E` `lineWidth size*0.014`.
- Glint: `Capsule` fill `#FFFFFF` opacity 0.35, `size*0.02 x size*0.08`, rotation 28°, offset to inner-top of each lens.

Teardrop-ish dark gradient lenses with thin gold rims.

---

## 7. Round Sunglasses

- **name:** Round Sunnies
- **kind:** `roundSunglasses`
- **rarity:** common
- **cost:** 120

**Shapes**
- Bridge: `Rectangle` fill `#2A241B`, `size*0.14 x size*0.022`, x = 0, y = 0.
- Left lens: `Circle` fill `LinearGradient(#5B3A8C → #2A1B45, top→bottom)`, `size*0.22 x size*0.22`, offset x = -size*0.2.
- Right lens: same, offset x = +size*0.2.
- Rim: each lens `Circle` stroke `#2A241B` `lineWidth size*0.018` overlay.
- Glint: `Ellipse` fill `#FFFFFF` opacity 0.3, `size*0.06 x size*0.04`, offset inner-top of each lens.

Retro round purple-tinted shades.

---

## 8. Visor Shades

- **name:** Visor Shades
- **kind:** `visorShades`
- **rarity:** epic
- **cost:** 450

**Shapes**
- Single wraparound lens: `Capsule` fill `LinearGradient(#FF7A59 → #E03A6E, leading→trailing)`, `size*0.56 x size*0.2`, x = 0, y = 0 (spans across both eyes).
- Top frame bar: `Capsule` fill `#2A241B`, `size*0.58 x size*0.04`, offset y = -size*0.09.
- Shine streak: `Capsule` fill `#FFFFFF` opacity 0.3, `size*0.04 x size*0.13`, rotation 24°, offset x = -size*0.14, y = -size*0.01.
- Second shorter streak: `Capsule` fill `#FFFFFF` opacity 0.2, `size*0.025 x size*0.1`, rotation 24°, offset x = -size*0.05.

Futuristic single-panel gradient visor. Sporty cyber-cute.

---

## 9. Monocle

- **name:** Monocle
- **kind:** `monocle`
- **rarity:** epic
- **cost:** 450

**Shapes**
- Lens: `Circle` stroke `#C9962E` `lineWidth size*0.024`, `size*0.22 x size*0.22`, offset x = +size*0.2 (right eye only).
- Lens fill: `Circle` fill `#FFFFFF` opacity 0.12 inside.
- Glint: small `Ellipse` fill `#FFFFFF` opacity 0.5, `size*0.05 x size*0.035`, offset x = size*0.25, y = -size*0.05.
- Chain: a small `Path` of 4–5 tiny `Circle`s (each `size*0.02`) fill `#C9962E`, stepping from the lens bottom-outer (x = size*0.28, y = size*0.09) down and out in a gentle curve to (x = size*0.34, y = size*0.26). Alternatively one thin curved `Path` stroke `#C9962E` `lineWidth size*0.01` dashed.

Dapper single gold lens with a dangling chain. Distinguished and silly.

---

## 10. 3D Glasses

- **name:** 3D Glasses
- **kind:** `threeDGlasses`
- **rarity:** rare
- **cost:** 250

**Shapes**
- Frame: one `RoundedRectangle(cornerRadius: size*0.04)` stroke `#2A241B` `lineWidth size*0.02`, `size*0.56 x size*0.2`, x = 0, y = 0 (single wide frame around both lenses, classic cardboard 3D specs).
- Left lens fill: `RoundedRectangle(cornerRadius: size*0.03)` fill `#E0383C` opacity 0.7 (red), `size*0.24 x size*0.16`, offset x = -size*0.2.
- Right lens fill: `RoundedRectangle(cornerRadius: size*0.03)` fill `#2E78D6` opacity 0.7 (cyan/blue), `size*0.24 x size*0.16`, offset x = +size*0.2.
- Centre divider: `Rectangle` fill `#2A241B`, `size*0.018 x size*0.2`, x = 0.

Red/blue anaglyph cinema glasses. Nostalgic and instantly readable.

---

## 11. Swim Goggles

- **name:** Swim Goggles
- **kind:** `swimGoggles`
- **rarity:** rare
- **cost:** 250

**Shapes**
- Left cup: `Circle` fill `#7FD7E8` opacity 0.5, `size*0.22 x size*0.22`, offset x = -size*0.2; overlay `Circle` stroke `#2E9CC4` `lineWidth size*0.03`.
- Right cup: same, offset x = +size*0.2.
- Nose bridge: a short thick `Capsule` fill `#2E9CC4`, `size*0.1 x size*0.03`, x = 0, y = 0.
- Strap: `Capsule` fill `#2E9CC4`, `size*0.62 x size*0.035`, offset y = -size*0.02, placed BEHIND the cups (drawn first), bowing slightly (rotation 0, it reads as a band wrapping the head).
- Glint: `Ellipse` fill `#FFFFFF` opacity 0.55, `size*0.06 x size*0.04`, inner-top of each cup.

Chunky teal swim goggles with a rubber strap. Splashy and cute.

---

## 12. Sleep Mask

- **name:** Sleep Mask
- **kind:** `sleepMask`
- **rarity:** common
- **cost:** 120

**Shapes**
- Mask body: `CrescentShape` (or RoundedRectangle with bowed bottom) fill `#9B7FD4`, `size*0.58 x size*0.22`, x = 0, y = 0 (covers both eyes).
- Highlight band: `Capsule` fill `#B9A3E6` opacity 0.6, `size*0.5 x size*0.06`, offset y = -size*0.04.
- Strap: `Capsule` fill `#7E63B8`, `size*0.62 x size*0.03`, offset y = -size*0.08, drawn behind body.
- Closed eyes (cute detail): two `Path` arcs (smile-down, i.e. sleepy lashes) stroke `#3A2F5A` `lineWidth size*0.012`, each a shallow downward arc `size*0.08` wide, offset x = ±size*0.2, y = +size*0.01.
- Tiny embroidered "Zzz": skip text; instead three `Capsule`s fill `#FFFFFF` opacity 0.7 of increasing size stacked diagonally at x = size*0.18, y = -size*0.08 (reads as Zzz without glyphs). Keep small.

Purple over-the-eyes sleep mask with sleepy lashes. Naptime cozy.

---

## 13. Superhero Domino Mask

- **name:** Hero Mask
- **kind:** `dominoMask`
- **rarity:** epic
- **cost:** 450

**Shapes** (use `.compositingGroup()` so the eye holes punch out)
- Mask plate: `RoundedRectangle(cornerRadius: size*0.1)` fill `#E0383C`, `size*0.6 x size*0.24`, x = 0, y = 0; gently raised outer corners via two small `Triangle`s or by topping with an `Ellipse` mask. Keep as a soft rounded band.
- Eye hole left: `Ellipse` `size*0.18 x size*0.13`, offset x = -size*0.2, `.blendMode(.destinationOut)`.
- Eye hole right: same, offset x = +size*0.2, `.blendMode(.destinationOut)`.
- Rim accent: overlay the plate with `RoundedRectangle(cornerRadius: size*0.1)` stroke `#A81F22` `lineWidth size*0.012`.
- Top points: two small `Triangle` fill `#E0383C`, `size*0.1 x size*0.08`, offset x = ±size*0.28, y = -size*0.08, rotation ±15° (the swooped outer brow peaks).

Classic red superhero eye mask with punched-out eye holes and swept brow tips.

---

## 14. Eyepatch

- **name:** Eyepatch
- **kind:** `eyepatch`
- **rarity:** common
- **cost:** 120

**Shapes**
- Patch: `RoundedRectangle(cornerRadius: size*0.05)` fill `#2A241B`, `size*0.22 x size*0.24`, offset x = -size*0.2 (left eye covered).
- Strap: `Capsule` fill `#2A241B`, `size*0.64 x size*0.025`, offset y = -size*0.04, rotation -6° (angles up to the opposite side of the head), drawn behind patch.
- Highlight: `Capsule` fill `#4A4036` opacity 0.6, `size*0.03 x size*0.12`, rotation 18°, offset on the patch.
- Optional skull-free cute stitch: a single `Capsule` fill `#5C5046`, `size*0.1 x size*0.012`, rotation 35° as a stitch line, offset on patch.

Single dark eyepatch with an angled strap. Adventurer charm, no scary skull.

---

## 15. Anime Sparkle Eyes

- **name:** Sparkle Eyes
- **kind:** `sparkleEyes`
- **rarity:** epic
- **cost:** 500

This is an OVERLAY drawn on top of the creature's eyes (it enlarges/dazzles them), not a frame.

**Shapes (per eye, mirrored, at x = ±size*0.2)**
- Big iris: `Ellipse` fill `LinearGradient(#6FB8FF → #2E5FC4, top→bottom)`, `size*0.18 x size*0.22`.
- Iris rim: `Ellipse` stroke `#1E3E8A` `lineWidth size*0.01` overlay.
- Big highlight: `Circle` fill `#FFFFFF`, `size*0.07 x size*0.07`, offset y = -size*0.05, x toward inner.
- Small highlight: `Circle` fill `#FFFFFF`, `size*0.035`, offset y = +size*0.03, x toward outer.
- Sparkle stars: two `StarShape(innerRatio: 0.35)` fill `#FFFFFF` opacity 0.9, `size*0.05` and `size*0.035`, offset to upper-outer of each iris and one floating at x = 0, y = -size*0.14.

Shoujo-manga shimmering eyes with twin highlights and floating sparkles. Maximum cute.

---

## 16. Eyebrows (Expressive Brows)

- **name:** Bold Brows
- **kind:** `eyebrows`
- **rarity:** common
- **cost:** 120

**Shapes**
- Left brow: `Capsule` fill `#5A3D2B`, `size*0.18 x size*0.04`, offset x = -size*0.2, y = -size*0.16, rotation +10° (raised inner, expressive).
- Right brow: `Capsule` fill `#5A3D2B`, `size*0.18 x size*0.04`, offset x = +size*0.2, y = -size*0.16, rotation -10°.

Two soft thick brows sitting above the eye line. Reads as a cheeky raised-brow expression.

---

## 17. Unibrow

- **name:** Unibrow
- **kind:** `unibrow`
- **rarity:** rare
- **cost:** 250

**Shapes**
- Single brow: `Capsule` fill `#4A3322`, `size*0.5 x size*0.045`, x = 0, y = -size*0.16, with a gentle upward bow (use a `Path` rounded bar arcing up `size*0.02` in the centre, or a `Capsule` plus a small overlapping `Capsule` at the centre to thicken the middle).
- Texture tufts: three tiny `Capsule`s fill `#3A2618`, `size*0.03 x size*0.06`, rotation 90°-ish, poking up along the top edge at x = -size*0.1, 0, +size*0.1.

One confident continuous brow across both eyes. Bold, comedic, lovable.

---

## 18. Googly Eyes

- **name:** Googly Eyes
- **kind:** `googlyEyes`
- **rarity:** rare
- **cost:** 250

Overlay craft-store googly eyes on top of the creature's eyes.

**Shapes (per eye, at x = ±size*0.2)**
- White backing: `Circle` fill `#FFFFFF`, `size*0.2 x size*0.2`, with `Circle` stroke `#D8D2C8` `lineWidth size*0.006` overlay.
- Pupil: `Circle` fill `#1A1714`, `size*0.09 x size*0.09`, offset to a slightly DIFFERENT position per eye for the wobbly look: left pupil offset x = +size*0.02, y = +size*0.03; right pupil offset x = -size*0.03, y = -size*0.02.
- Tiny glint: `Circle` fill `#FFFFFF`, `size*0.025`, offset on each pupil top-left.

Wobbly mismatched plastic googly eyes. Instant goofy delight.

---

## 19. Single Flower Over One Eye

- **name:** Eye Bloom
- **kind:** `eyeFlower`
- **rarity:** rare
- **cost:** 280

**Shapes** (reuse the flower vocabulary from CosmeticView's `flower`)
- Petals: five `Circle` fill `#FF94C2`, each `size*0.09 x size*0.09`, arranged radially (offset y = -petal*0.6, rotated `i*72°`) — same construction as the existing `flower`, scaled up.
- Centre: `Circle` fill `#FFD25A`, `size*0.07 x size*0.07`.
- Placement: whole flower offset x = -size*0.2, y = -size*0.04 (sits over/above the left eye like a tucked bloom).
- Tiny leaf: one `Triangle` (or `SoftFin`) fill `#86D38C`, `size*0.06 x size*0.08`, offset x = -size*0.27, y = +size*0.04, rotation -30°.

A single pink daisy tucked over one eye. Springtime sweet.

---

## 20. Freckles

- **name:** Freckles
- **kind:** `freckles`
- **rarity:** common
- **cost:** 0 (free)

A scatter of dots across the cheeks/under-eye area.

**Shapes**
- Left cluster: 4 `Circle`s fill `#C97A4A`, sizes `size*0.018`–`size*0.028`, scattered around x = -size*0.22, y = +size*0.06 (offsets: (-0.04,0.0), (0.0,0.03), (0.03,-0.02), (-0.01,0.06) times size).
- Right cluster: mirror of the left, around x = +size*0.22, y = +size*0.06.
- Optional two stray freckles near the bridge: 2 `Circle`s `size*0.016` at x = ±size*0.04, y = +size*0.04.

Soft warm cheek freckles. Free starter, universally cute.

---

## 21. Face Gem / Bindi

- **name:** Face Gem
- **kind:** `faceGem`
- **rarity:** epic
- **cost:** 450

A single sparkling gem between/above the eyes.

**Shapes**
- Gem: `Diamond` (existing shape) fill `LinearGradient(#FF6FA3 → #C23E78, top→bottom)`, `size*0.07 x size*0.1`, x = 0, y = -size*0.1 (forehead/third-eye spot).
- Facet line: thin `Capsule` fill `#FFFFFF` opacity 0.5, `size*0.012 x size*0.06`, x = 0, y = -size*0.1.
- Sparkle: `StarShape(innerRatio: 0.3)` fill `#FFFFFF` opacity 0.9, `size*0.05 x size*0.05`, offset x = +size*0.03, y = -size*0.13.
- Tiny accent gems: two `Circle`s fill `#FFD25A`, `size*0.018`, offset x = ±size*0.05, y = -size*0.06.

A jewel-toned teardrop/diamond bindi with a sparkle. Regal and pretty.

(Optional alternate: swap `Diamond` for `TearShape` for a hanging-jewel look.)

---

## Rarity / cost summary

| # | name | kind | rarity | cost |
|---|------|------|--------|------|
| 1 | Round Specs | roundReadingGlasses | common | 120 |
| 2 | Square Frames | squareGlasses | common | 120 |
| 3 | Cat-Eye Glasses | catEyeGlasses | rare | 280 |
| 4 | Half-Moon Readers | halfMoonGlasses | rare | 250 |
| 5 | Heart Glasses | heartGlasses | rare | 280 |
| 6 | Aviators | aviatorSunglasses | rare | 280 |
| 7 | Round Sunnies | roundSunglasses | common | 120 |
| 8 | Visor Shades | visorShades | epic | 450 |
| 9 | Monocle | monocle | epic | 450 |
| 10 | 3D Glasses | threeDGlasses | rare | 250 |
| 11 | Swim Goggles | swimGoggles | rare | 250 |
| 12 | Sleep Mask | sleepMask | common | 120 |
| 13 | Hero Mask | dominoMask | epic | 450 |
| 14 | Eyepatch | eyepatch | common | 120 |
| 15 | Sparkle Eyes | sparkleEyes | epic | 500 |
| 16 | Bold Brows | eyebrows | common | 120 |
| 17 | Unibrow | unibrow | rare | 250 |
| 18 | Googly Eyes | googlyEyes | rare | 250 |
| 19 | Eye Bloom | eyeFlower | rare | 280 |
| 20 | Freckles | freckles | common | 0 |
| 21 | Face Gem | faceGem | epic | 450 |

21 items: 7 common (one free), 9 rare, 5 epic. Covers glasses variants, sunglasses
variants, monocle, 3D glasses, swim goggles, sleep mask, domino mask, eyepatch, anime
sparkle eyes, eyebrows, unibrow, googly eyes, single flower, freckles, and a face gem.
