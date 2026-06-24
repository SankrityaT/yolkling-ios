# Hat cosmetics catalog

A big set of HAT cosmetics for Yolkling, drawn in PURE SwiftUI vector shapes. No images, no emoji, no SF Symbols. Hand made cute assets only.

## Conventions (read first)

These match `Yolkling/Core/Cosmetics/CosmeticView.swift` exactly.

- Everything is sized relative to a single `size` value (the creature's size). Example: `width = size * 0.34`.
- A HAT is drawn centred on the top-of-head anchor. In the hat's own coordinate space, `y = 0` is roughly the top of the head and the hat sits slightly above it. **Negative y is UP.** Offsets look like `.offset(y: -size * 0.1)`.
- Colours are real hex, written as `Color(hex: 0xRRGGBB)`. "creature body colour" means reuse the host creature's fill so the part reads as part of the yolk.
- Keep each hat to a handful of shapes. Readable at shop size (about 50) and on the creature (about 220).
- Existing reusable shapes available: `Triangle` (upward), `Diamond`, `StarShape(innerRatio:)`, `CrownShape`. New reusable shapes are defined at the bottom of this doc with precise Paths.

## Rarity and cost rules

- common = 120 coins, rare = 250 to 300, epic = 450 to 500.
- A couple of items are free starters (cost 0).

## Catalog summary

| # | name | kind id | rarity | cost | category |
|---|------|---------|--------|------|----------|
| 1 | chunky beanie | chunkyBeanie | common | 0 | knit |
| 2 | bobble hat | bobbleHat | common | 120 | knit |
| 3 | earflap hat | earflapHat | rare | 250 | knit |
| 4 | cat ears | catEars | common | 120 | animal ears |
| 5 | bunny ears | bunnyEars | common | 120 | animal ears |
| 6 | bear ears | bearEars | common | 120 | animal ears |
| 7 | fox ears | foxEars | rare | 250 | animal ears |
| 8 | strawberry hat | strawberryHat | rare | 280 | food |
| 9 | mushroom cap | mushroomCap | rare | 280 | food |
| 10 | cupcake hat | cupcakeHat | epic | 460 | food |
| 11 | fried egg hat | friedEggHat | rare | 250 | food |
| 12 | santa hat | santaHat | rare | 300 | seasonal |
| 13 | witch hat | witchHat | rare | 300 | seasonal |
| 14 | pumpkin hat | pumpkinHat | rare | 280 | seasonal |
| 15 | snow hat | snowHat | common | 120 | seasonal |
| 16 | leaf hat | leafHat | common | 120 | nature |
| 17 | single flower | singleFlower | common | 120 | nature |
| 18 | acorn cap | acornCap | rare | 250 | nature |
| 19 | propeller cap | propellerCap | rare | 280 | fun |
| 20 | wizard hat | wizardHat | epic | 480 | fun |
| 21 | chef hat | chefHat | rare | 250 | fun |
| 22 | cowboy hat | cowboyHat | rare | 300 | fun |
| 23 | top hat | topHat | rare | 300 | fun |
| 24 | beret | beret | common | 120 | fun |
| 25 | headphones | headphones | rare | 280 | fun |
| 26 | tiara | tiara | epic | 460 | fun |
| 27 | little horns | littleHorns | rare | 280 | fun |
| 28 | soft halo | softHalo | epic | 500 | fun |
| 29 | bow on head | bowOnHead | common | 120 | fun |
| 30 | bucket hat | bucketHat | common | 120 | fun |

30 hats total. Counts by rarity: common 12, rare 13, epic 5. Free starters: chunky beanie.

---

## 1. chunky beanie

- kind id: `chunkyBeanie`
- rarity: common
- cost: 0 (free starter)
- category: knit

A cozier remix of the existing beanie, with a thick ribbed fold-up cuff and a chunky knit dome. Warm oatmeal colour so it reads against any body.

Shapes (anchor = top of head):
- DOME: Ellipse, width `size * 0.5`, height `size * 0.3`, fill `#E8C9A0`, offset y `-size * 0.06`.
- KNIT SEAM HINT: Capsule, width `size * 0.5 * 0.08`, height `size * 0.22`, fill `#D8B488` at 0.6 opacity, offset y `-size * 0.06`, rotation 0. (one soft vertical rib down the middle for texture)
- CUFF: Capsule, width `size * 0.52`, height `size * 0.11`, fill `#D8B488`, offset y `size * 0.07`.
- CUFF HIGHLIGHT: Capsule, width `size * 0.5`, height `size * 0.035`, fill `#F0DCC0` at 0.7 opacity, offset y `size * 0.045`.

Notes: no pom (that is the bobble hat). The cuff sits low and reads as the brim.

---

## 2. bobble hat

- kind id: `bobbleHat`
- rarity: common
- cost: 120
- category: knit

Classic knit hat with a big fluffy pom on top. Berry red knit, cream pom.

Shapes (anchor = top of head):
- DOME: Ellipse, width `size * 0.48`, height `size * 0.3`, fill `#D94F6A`, offset y `-size * 0.05`.
- CUFF: Capsule, width `size * 0.5`, height `size * 0.1`, fill `#C03F58`, offset y `size * 0.07`.
- POM: Circle, diameter `size * 0.16`, fill `#FBEFE0`, offset y `-size * 0.28`.
- POM SHADE: Circle, diameter `size * 0.07`, fill `#E9D7C2` at 0.7 opacity, offset x `size * 0.03`, y `-size * 0.25` (a soft lower-right shadow on the pom to make it round).

Notes: pom is intentionally larger than the original beanie pom for a bobble look.

---

## 3. earflap hat

- kind id: `earflapHat`
- rarity: rare
- cost: 250
- category: knit

A trapper / earflap knit hat with two hanging flaps and tiny braid ties. Reads cosy and a bit alpine. Teal knit with cream fleece trim.

Shapes (anchor = top of head):
- DOME: Ellipse, width `size * 0.5`, height `size * 0.3`, fill `#3FA6A0`, offset y `-size * 0.05`.
- FLEECE BRIM: Capsule, width `size * 0.52`, height `size * 0.1`, fill `#F2E6CE`, offset y `size * 0.06`.
- LEFT FLAP: RoundedRectangle corner `size * 0.05`, width `size * 0.12`, height `size * 0.2`, fill `#3FA6A0`, offset x `-size * 0.22`, y `size * 0.16`.
- RIGHT FLAP: RoundedRectangle corner `size * 0.05`, width `size * 0.12`, height `size * 0.2`, fill `#3FA6A0`, offset x `size * 0.22`, y `size * 0.16`.
- LEFT FLAP FLEECE: Circle, diameter `size * 0.1`, fill `#F2E6CE`, offset x `-size * 0.22`, y `size * 0.24`.
- RIGHT FLAP FLEECE: Circle, diameter `size * 0.1`, fill `#F2E6CE`, offset x `size * 0.22`, y `size * 0.24`.
- LEFT TIE: Capsule, width `size * 0.02`, height `size * 0.1`, fill `#E8DCC0`, offset x `-size * 0.22`, y `size * 0.31`.
- RIGHT TIE: Capsule, width `size * 0.02`, height `size * 0.1`, fill `#E8DCC0`, offset x `size * 0.22`, y `size * 0.31`.

Notes: flaps hang down past the head sides, which is fine; the slot z-order keeps them behind the body edges.

---

## 4. cat ears

- kind id: `catEars`
- rarity: common
- cost: 120
- category: animal ears

Two soft triangle ears with pink inner ears, perched on the head. Charcoal grey.

Shapes (anchor = top of head, uses the existing `Triangle` shape):
- LEFT EAR: Triangle, width `size * 0.18`, height `size * 0.2`, fill `#3A3A3A`, offset x `-size * 0.16`, y `-size * 0.02`.
- RIGHT EAR: Triangle, width `size * 0.18`, height `size * 0.2`, fill `#3A3A3A`, offset x `size * 0.16`, y `-size * 0.02`.
- LEFT INNER: Triangle, width `size * 0.1`, height `size * 0.11`, fill `#F4A6B8`, offset x `-size * 0.16`, y `size * 0.0`.
- RIGHT INNER: Triangle, width `size * 0.1`, height `size * 0.11`, fill `#F4A6B8`, offset x `size * 0.16`, y `size * 0.0`.

Notes: inner triangle sits slightly lower than outer so the dark rim shows around the top and sides. Slightly round the triangle tips in the renderer if desired for extra softness.

---

## 5. bunny ears

- kind id: `bunnyEars`
- rarity: common
- cost: 120
- category: animal ears

Two tall upright capsule ears with soft pink inner. Cream white, one ear flopped slightly via rotation for cuteness.

Shapes (anchor = top of head):
- LEFT EAR: Capsule, width `size * 0.1`, height `size * 0.34`, fill `#FBF3E8`, offset x `-size * 0.1`, y `-size * 0.14`, rotation `-8` degrees.
- RIGHT EAR: Capsule, width `size * 0.1`, height `size * 0.34`, fill `#FBF3E8`, offset x `size * 0.1`, y `-size * 0.13`, rotation `10` degrees (slightly flopped).
- LEFT INNER: Capsule, width `size * 0.045`, height `size * 0.24`, fill `#F6C0CE`, offset x `-size * 0.1`, y `-size * 0.14`, rotation `-8` degrees.
- RIGHT INNER: Capsule, width `size * 0.045`, height `size * 0.24`, fill `#F6C0CE`, offset x `size * 0.1`, y `-size * 0.13`, rotation `10` degrees.

Notes: the small rotation difference between ears gives a hand-made wobble.

---

## 6. bear ears

- kind id: `bearEars`
- rarity: common
- cost: 120
- category: animal ears

Two round circle ears, low and wide, like a teddy. Warm brown.

Shapes (anchor = top of head):
- LEFT EAR: Circle, diameter `size * 0.2`, fill `#A9743F`, offset x `-size * 0.2`, y `-size * 0.04`.
- RIGHT EAR: Circle, diameter `size * 0.2`, fill `#A9743F`, offset x `size * 0.2`, y `-size * 0.04`.
- LEFT INNER: Circle, diameter `size * 0.1`, fill `#D7A877`, offset x `-size * 0.2`, y `-size * 0.04`.
- RIGHT INNER: Circle, diameter `size * 0.1`, fill `#D7A877`, offset x `size * 0.2`, y `-size * 0.04`.

Notes: round ears sit out to the sides and tuck behind the body edge a touch. A lighter inner circle gives a fuzzy inner-ear look.

---

## 7. fox ears

- kind id: `foxEars`
- rarity: rare
- cost: 250
- category: animal ears

Sharp, taller triangle ears with black tips and white inner fluff. Burnt orange.

Shapes (anchor = top of head, uses `Triangle`):
- LEFT EAR: Triangle, width `size * 0.16`, height `size * 0.26`, fill `#E07B3C`, offset x `-size * 0.17`, y `-size * 0.06`.
- RIGHT EAR: Triangle, width `size * 0.16`, height `size * 0.26`, fill `#E07B3C`, offset x `size * 0.17`, y `-size * 0.06`.
- LEFT TIP: Triangle, width `size * 0.09`, height `size * 0.1`, fill `#2A2A2A`, offset x `-size * 0.17`, y `-size * 0.14` (black tip at the top of the ear).
- RIGHT TIP: Triangle, width `size * 0.09`, height `size * 0.1`, fill `#2A2A2A`, offset x `size * 0.17`, y `-size * 0.14`.
- LEFT INNER: Triangle, width `size * 0.07`, height `size * 0.12`, fill `#FBF1E2`, offset x `-size * 0.17`, y `-size * 0.02`.
- RIGHT INNER: Triangle, width `size * 0.07`, height `size * 0.12`, fill `#FBF1E2`, offset x `size * 0.17`, y `-size * 0.02`.

Notes: tips overlap the ear top, drawn after the orange ear so the black caps the point. Taller and more angled than cat ears.

---

## 8. strawberry hat

- kind id: `strawberryHat`
- rarity: rare
- cost: 280
- category: food

A red strawberry dome worn as a beanie, with tiny yellow seed dots and a little green leaf calyx on top.

Shapes (anchor = top of head; uses new `LeafShape`):
- BERRY BODY: Ellipse, width `size * 0.46`, height `size * 0.34`, fill `#E23B4E`, offset y `-size * 0.03`.
- SEEDS: 7 small Capsules, each width `size * 0.018`, height `size * 0.04`, fill `#FCE38A`, scattered across the lower berry. Suggested offsets (x, y) as multiples of `size`: (-0.14, 0.02), (-0.05, 0.06), (0.05, 0.04), (0.14, 0.01), (-0.1, -0.06), (0.0, -0.03), (0.1, -0.05). Each rotated a little, alternate `-15` and `15` degrees, to look hand-scattered.
- LEAF 1 (calyx): LeafShape, width `size * 0.1`, height `size * 0.12`, fill `#4FAF63`, offset x `-size * 0.06`, y `-size * 0.2`, rotation `-35` degrees.
- LEAF 2: LeafShape, width `size * 0.1`, height `size * 0.12`, fill `#4FAF63`, offset y `-size * 0.22`, rotation `0` degrees.
- LEAF 3: LeafShape, width `size * 0.1`, height `size * 0.12`, fill `#4FAF63`, offset x `size * 0.06`, y `-size * 0.2`, rotation `35` degrees.
- STEM: Capsule, width `size * 0.02`, height `size * 0.05`, fill `#3E8E50`, offset y `-size * 0.26`.

Notes: three small leaves fanned at the top form the green star calyx. Seeds keep the berry readable at small size.

---

## 9. mushroom cap

- kind id: `mushroomCap`
- rarity: rare
- cost: 280
- category: food

A toadstool cap worn as a hat: a red dome with white spots and a pale gilled underbrim.

Shapes (anchor = top of head):
- CAP DOME: Ellipse, width `size * 0.56`, height `size * 0.34`, fill `#E0463F`, offset y `-size * 0.05`.
- UNDERBRIM: Capsule, width `size * 0.56`, height `size * 0.09`, fill `#F3E7D4`, offset y `size * 0.07` (the pale gill ring under the cap).
- SPOTS: 5 white Circles on the dome. Diameters and offsets (x, y) in `size` units: d `0.1` at (0.0, -0.1); d `0.08` at (-0.16, -0.02); d `0.08` at (0.16, -0.03); d `0.06` at (-0.08, 0.02); d `0.06` at (0.1, 0.01). Fill `#FBF4E8`.

Notes: dome is wider than tall for the classic mushroom silhouette. Spots vary in size and are placed slightly off-grid to feel painted by hand.

---

## 10. cupcake hat

- kind id: `cupcakeHat`
- rarity: epic
- cost: 460
- category: food

A whole cupcake on the head: a fluted paper liner, a swirl of pink frosting, a cherry on top, and sprinkles.

Shapes (anchor = top of head; uses new `FlutedLinerShape` and `FrostingSwirlShape`):
- LINER: FlutedLinerShape, width `size * 0.4`, height `size * 0.2`, fill `#F0A03C`, offset y `size * 0.08` (a wide trapezoid with a scalloped/ridged bottom; see shape def).
- FROSTING: FrostingSwirlShape, width `size * 0.42`, height `size * 0.3`, fill `#FF9EC4`, offset y `-size * 0.08` (a stacked swirl mound; see shape def).
- FROSTING HIGHLIGHT: Ellipse, width `size * 0.12`, height `size * 0.06`, fill `#FFC2DC` at 0.8 opacity, offset x `-size * 0.06`, y `-size * 0.12`.
- CHERRY: Circle, diameter `size * 0.1`, fill `#D63A52`, offset y `-size * 0.24`.
- CHERRY SHINE: Circle, diameter `size * 0.03`, fill `#FFFFFF` at 0.8 opacity, offset x `-size * 0.02`, y `-size * 0.26`.
- CHERRY STEM: Capsule, width `size * 0.014`, height `size * 0.05`, fill `#6E8F3E`, offset x `size * 0.02`, y `-size * 0.3`, rotation `18` degrees.
- SPRINKLES: 4 tiny Capsules on the frosting, width `size * 0.012`, height `size * 0.035`, rotations and colours varied. Suggested: (-0.1, -0.06) `#7BD0F0` rot `-30`; (0.08, -0.1) `#FFE27A` rot `25`; (0.12, -0.04) `#9EE6A0` rot `60`; (-0.04, -0.14) `#FFFFFF` rot `0`.

Notes: this is a tall hat, the most decorated of the food set, hence epic. Keep the frosting swirl reading as a soft mound, not spiky.

---

## 11. fried egg hat

- kind id: `friedEggHat`
- rarity: rare
- cost: 250
- category: food

A sunny-side-up fried egg flopped on the head: a wobbly white blob with a golden yolk. A cheeky nod to the yolkling itself.

Shapes (anchor = top of head; uses new `EggWhiteShape`):
- EGG WHITE: EggWhiteShape, width `size * 0.54`, height `size * 0.34`, fill `#FCFAF2`, offset y `-size * 0.02` (an irregular soft blob, wider than tall, with 2 to 3 gentle bumps on the rim; see shape def).
- WHITE SHADE: same EggWhiteShape, width `size * 0.54`, height `size * 0.34`, fill `#ECE6D2` at 0.5 opacity, offset y `size * 0.005` (a hair lower, peeking at the bottom rim for soft depth).
- YOLK: Circle, diameter `size * 0.2`, fill `#FBC02D`, offset y `-size * 0.04`.
- YOLK SHADE: Circle, diameter `size * 0.16`, fill `#F4A81E` at 0.6 opacity, offset y `-size * 0.02` (slightly lower, gives the yolk a domed look).
- YOLK SHINE: Circle, diameter `size * 0.05`, fill `#FFFFFF` at 0.85 opacity, offset x `-size * 0.04`, y `-size * 0.08`.

Notes: the irregular white blob is the personality here. Keep the yolk centred and high.

---

## 12. santa hat

- kind id: `santaHat`
- rarity: rare
- cost: 300
- category: seasonal

The classic floppy red Santa hat with a white fur brim and a white pom at the drooping tip.

Shapes (anchor = top of head; uses new `SantaHatShape`):
- HAT BODY: SantaHatShape, width `size * 0.5`, height `size * 0.42`, fill `#D8323E`, offset x `size * 0.04`, y `-size * 0.14` (a cone that curves and droops to one side; see shape def).
- BODY SHADE: SantaHatShape, width `size * 0.5`, height `size * 0.42`, fill `#B82531` at 0.5 opacity, offset x `size * 0.05`, y `-size * 0.13` (slightly offset to shade the underside of the droop).
- FUR BRIM: Capsule, width `size * 0.52`, height `size * 0.12`, fill `#FBF6EE`, offset y `size * 0.06`.
- BRIM TEXTURE: 3 small Circles, diameter `size * 0.06`, fill `#FFFFFF` at 0.6 opacity, along the brim at x `-size * 0.16`, `0`, `size * 0.16`, all at y `size * 0.06` (soft fluffy bumps).
- TIP POM: Circle, diameter `size * 0.13`, fill `#FBF6EE`, offset x `size * 0.22`, y `-size * 0.26` (sits at the drooped tip on the right).

Notes: the droop goes to the right; mirror if a left droop is preferred. Pom must align with where the SantaHatShape tip ends.

---

## 13. witch hat

- kind id: `witchHat`
- rarity: rare
- cost: 300
- category: seasonal

A pointy witch hat with a wide brim and a buckle band. Deep purple with a gold buckle.

Shapes (anchor = top of head; uses new `WitchConeShape` plus `Triangle`):
- BRIM: Ellipse, width `size * 0.64`, height `size * 0.14`, fill `#3A2A56`, offset y `size * 0.08`.
- BRIM HIGHLIGHT: Ellipse, width `size * 0.58`, height `size * 0.08`, fill `#4A3768` at 0.7 opacity, offset y `size * 0.07`.
- CONE: WitchConeShape, width `size * 0.34`, height `size * 0.46`, fill `#46326A`, offset y `-size * 0.18` (a tall slightly-bent cone; see shape def). If `WitchConeShape` is skipped, use the existing `Triangle` at the same frame for a straight cone.
- BAND: Capsule, width `size * 0.3`, height `size * 0.07`, fill `#2A1E40`, offset y `size * 0.02`.
- BUCKLE: RoundedRectangle corner `size * 0.01`, width `size * 0.07`, height `size * 0.07`, fill `#F4C84A`, offset y `size * 0.02`, with an inner cut-out: overlay a smaller RoundedRectangle corner `size * 0.005`, width `size * 0.035`, height `size * 0.035`, fill same purple as the BAND `#2A1E40` to read as an open buckle.

Notes: cone tilts a few degrees if `WitchConeShape` is used. Buckle on the front of the band.

---

## 14. pumpkin hat

- kind id: `pumpkinHat`
- rarity: rare
- cost: 280
- category: seasonal

A little jack-o-lantern pumpkin worn as a cap, with ribbed segments, a brown stem, and a tiny curling vine.

Shapes (anchor = top of head; uses new `VineShape`):
- PUMPKIN BODY: Ellipse, width `size * 0.56`, height `size * 0.32`, fill `#EE8B2E`, offset y `-size * 0.02`.
- RIB LEFT: Ellipse, width `size * 0.2`, height `size * 0.3`, fill `#D9762088` (orange `#D97620` at ~0.5 opacity), offset x `-size * 0.14`, y `-size * 0.02` (a shaded vertical lobe).
- RIB RIGHT: Ellipse, width `size * 0.2`, height `size * 0.3`, fill `#D97620` at 0.5 opacity, offset x `size * 0.14`, y `-size * 0.02`.
- RIB CENTRE HIGHLIGHT: Ellipse, width `size * 0.16`, height `size * 0.3`, fill `#FBA64A` at 0.6 opacity, offset y `-size * 0.02`.
- STEM: a small trapezoid (use RoundedRectangle corner `size * 0.02`, width `size * 0.08`, height `size * 0.1`), fill `#6E5230`, offset y `-size * 0.2`.
- VINE: VineShape, width `size * 0.12`, height `size * 0.12`, stroke `#7A9A45` lineWidth `size * 0.018`, offset x `size * 0.08`, y `-size * 0.22` (a small open curl; see shape def).

Notes: the three vertical ellipse lobes (two shaded, one highlight) give the pumpkin its ribs without any extra shapes. Optionally add a tiny triangle eye/mouth set in `#5A3A12` if a jack-o-lantern face is wanted, but keep it subtle at small size.

---

## 15. snow hat

- kind id: `snowHat`
- rarity: common
- cost: 120
- category: seasonal

A mound of soft snow with a couple of falling snowflake dots above. Cool and minimal.

Shapes (anchor = top of head):
- SNOW MOUND: Ellipse, width `size * 0.5`, height `size * 0.26`, fill `#F4FAFF`, offset y `size * 0.0`.
- MOUND SHADE: Ellipse, width `size * 0.46`, height `size * 0.1`, fill `#DCEAF6` at 0.7 opacity, offset y `size * 0.06` (cool shadow at the base).
- SNOW BUMP LEFT: Circle, diameter `size * 0.16`, fill `#F4FAFF`, offset x `-size * 0.14`, y `-size * 0.03`.
- SNOW BUMP RIGHT: Circle, diameter `size * 0.14`, fill `#F4FAFF`, offset x `size * 0.15`, y `-size * 0.02`.
- FLAKE 1: small 4-point shape, use new `SnowflakeShape` or a `StarShape(innerRatio: 0.3)` rotated, width `size * 0.06`, fill `#BFE0F5`, offset x `-size * 0.1`, y `-size * 0.2`.
- FLAKE 2: same, width `size * 0.05`, fill `#BFE0F5`, offset x `size * 0.12`, y `-size * 0.16`.

Notes: the overlapping bumps make the snow read as a soft lumpy pile. Flakes are tiny accents; if too fiddly at small size, drop to one flake.

---

## 16. leaf hat

- kind id: `leafHat`
- rarity: common
- cost: 120
- category: nature

A single big leaf laid over the head like a little umbrella, with a visible central vein. Forest green, gentle.

Shapes (anchor = top of head; uses new `LeafShape`):
- LEAF: LeafShape, width `size * 0.5`, height `size * 0.34`, fill `#5BAE5A`, offset y `-size * 0.04`, rotation `-10` degrees (a pointed oval, two arcs meeting at a tip; see shape def).
- LEAF SHADE: LeafShape, width `size * 0.5`, height `size * 0.34`, fill `#4A9A4A` at 0.5 opacity, offset y `-size * 0.025`, rotation `-10` degrees (a hair lower for a folded look).
- CENTRE VEIN: Capsule, width `size * 0.012`, height `size * 0.3`, fill `#3C8240`, offset y `-size * 0.04`, rotation `-10` degrees (runs along the leaf's long axis).
- STEM: Capsule, width `size * 0.016`, height `size * 0.06`, fill `#3C8240`, offset x `-size * 0.2`, y `size * 0.08`, rotation `-10` degrees.

Notes: rotation gives the leaf a jaunty tilt. The vein must share the leaf's rotation to stay aligned.

---

## 17. single flower

- kind id: `singleFlower`
- rarity: common
- cost: 120
- category: nature

One oversized daisy tucked on the side of the head. Reuses the existing flower vocabulary (5 petal circles plus a centre), just one big bloom plus a leaf.

Shapes (anchor = top of head):
- PETALS: 5 Circles, diameter `size * 0.12` each, fill `#FFFFFF`, arranged around a centre at radius `size * 0.1`, i.e. each offset y `-size * 0.1` then `.rotationEffect(.degrees(Double(i) * 72))`. Whole flower group offset x `-size * 0.16`, y `-size * 0.02`.
- PETAL SHADE: optional, 5 Circles diameter `size * 0.12`, fill `#EFEFEF` at 0.4 opacity, same layout but each nudged y `+size * 0.01` for soft depth (skip if too busy at small size).
- CENTRE: Circle, diameter `size * 0.1`, fill `#FFD25A`, at the flower group centre (offset x `-size * 0.16`, y `-size * 0.02`).
- LEAF: LeafShape, width `size * 0.12`, height `size * 0.08`, fill `#5BAE5A`, offset x `-size * 0.02`, y `size * 0.04`, rotation `40` degrees (one little leaf peeking out to the side).

Notes: bigger and bolder than a single flower-crown bloom; placing it off-centre on the head feels tucked behind the ear.

---

## 18. acorn cap

- kind id: `acornCap`
- rarity: rare
- cost: 250
- category: nature

An acorn worn as a hat: a textured brown cupule cap on top of a smooth tan nut, with a tiny stem. Autumn cosy.

Shapes (anchor = top of head; uses new `AcornCupShape`):
- NUT BODY: Ellipse, width `size * 0.42`, height `size * 0.3`, fill `#D9A45E`, offset y `size * 0.04` (smooth tan lower half).
- NUT SHADE: Ellipse, width `size * 0.3`, height `size * 0.16`, fill `#C28A45` at 0.6 opacity, offset y `size * 0.08` (soft bottom shadow).
- CUP: AcornCupShape, width `size * 0.46`, height `size * 0.2`, fill `#8A5A2E`, offset y `-size * 0.04` (a dome with a scalloped lower rim; see shape def).
- CUP TEXTURE: 6 tiny Circles, diameter `size * 0.03`, fill `#6E4622` at 0.7 opacity, in two rows across the cup. Suggested x at `-0.12, -0.04, 0.04, 0.12` (top row, y `-size * 0.06`) and `-0.08, 0.0, 0.08` (lower row, y `-size * 0.02`) in `size` units. (Cross-hatch acorn texture; trim count if busy.)
- STEM: Capsule, width `size * 0.022`, height `size * 0.06`, fill `#5E3E1E`, offset y `-size * 0.16`.

Notes: the cup sits on top, the nut peeks out the bottom. Texture dots are optional flair for the rare tier.

---

## 19. propeller cap

- kind id: `propellerCap`
- rarity: rare
- cost: 280
- category: fun

A multicoloured beanie with a button and a spinning propeller on top. Playful, retro.

Shapes (anchor = top of head; uses new `PropellerBladeShape`):
- CAP DOME: Ellipse, width `size * 0.46`, height `size * 0.28`, fill `#3FA0E0`, offset y `-size * 0.02`.
- COLOUR PANEL LEFT: a half-dome accent, Ellipse width `size * 0.46`, height `size * 0.28`, fill `#F2C03C`, offset y `-size * 0.02`, but clipped to the left half (renderer: overlay then `.clipShape` to left rectangle). If clipping is awkward, instead use 3 Capsule "panel seams" across the dome (width `size * 0.01`, height `size * 0.24`, fill `#2C7CB8` at 0.5, at x `-size * 0.12`, `0`, `size * 0.12`).
- BRIM: Capsule, width `size * 0.5`, height `size * 0.06`, fill `#E55B5B`, offset y `size * 0.08`.
- BUTTON: Circle, diameter `size * 0.07`, fill `#E55B5B`, offset y `-size * 0.16`.
- PROPELLER BLADE 1: PropellerBladeShape, width `size * 0.34`, height `size * 0.06`, fill `#E55B5B`, offset y `-size * 0.18`, rotation `0` degrees (two tapered blades from a centre; see shape def).
- PROPELLER BLADE 2: PropellerBladeShape, width `size * 0.34`, height `size * 0.06`, fill `#F2C03C`, offset y `-size * 0.18`, rotation `90` degrees (a second pair crossed for a 4-blade look).
- PROP HUB: Circle, diameter `size * 0.04`, fill `#2A241B`, offset y `-size * 0.18`.

Notes: this hat is a natural candidate for a gentle continuous `rotationEffect` animation on the propeller group later. Keep blades thin so it stays readable.

---

## 20. wizard hat

- kind id: `wizardHat`
- rarity: epic
- cost: 480
- category: fun

A tall midnight-blue wizard hat covered in little gold stars and a moon, with a soft droop at the tip. The grand cousin of the witch hat.

Shapes (anchor = top of head; uses new `WitchConeShape` reused as the cone, plus `StarShape`):
- BRIM: Ellipse, width `size * 0.6`, height `size * 0.12`, fill `#2A2E58`, offset y `size * 0.09`.
- CONE: WitchConeShape (tall bent cone), width `size * 0.36`, height `size * 0.54`, fill `#33386E`, offset y `-size * 0.22`.
- CONE SHADE: WitchConeShape, width `size * 0.36`, height `size * 0.54`, fill `#262A52` at 0.5 opacity, offset x `size * 0.02`, y `-size * 0.21` (shades the bend underside).
- TIP STAR: StarShape(innerRatio: 0.42), width `size * 0.1`, fill `#FBD24A`, offset x `size * 0.06`, y `-size * 0.44` (sits at the drooped tip).
- STAR 1: StarShape(innerRatio: 0.42), width `size * 0.07`, fill `#FBD24A`, offset x `-size * 0.05`, y `-size * 0.1`.
- STAR 2: StarShape(innerRatio: 0.42), width `size * 0.05`, fill `#FBD24A`, offset x `size * 0.06`, y `-size * 0.22`.
- STAR 3: StarShape(innerRatio: 0.42), width `size * 0.045`, fill `#FBD24A`, offset x `-size * 0.07`, y `-size * 0.3`.
- MOON: a crescent, use new `CrescentShape`, width `size * 0.08`, height `size * 0.08`, fill `#FBD24A`, offset x `size * 0.02`, y `-size * 0.04` (low on the cone front; see shape def).

Notes: epic tier earns the moon plus four stars and a shaded droop. Scatter stars at varied sizes so it feels sprinkled, not gridded.

---

## 21. chef hat

- kind id: `chefHat`
- rarity: rare
- cost: 250
- category: fun

A classic puffy white toque: a pleated band and a tall cloud-puff crown.

Shapes (anchor = top of head; uses new `CloudShape`):
- BAND: Capsule, width `size * 0.42`, height `size * 0.12`, fill `#FBFBF8`, offset y `size * 0.06`.
- BAND PLEATS: 4 thin Capsules, width `size * 0.008`, height `size * 0.1`, fill `#E6E6E0` at 0.7 opacity, at x `-size * 0.12`, `-size * 0.04`, `size * 0.04`, `size * 0.12`, all y `size * 0.06` (vertical pleat lines).
- PUFF: CloudShape, width `size * 0.5`, height `size * 0.34`, fill `#FFFFFF`, offset y `-size * 0.1` (3 to 4 bump cloud; see shape def). If `CloudShape` is skipped, build from 3 overlapping Circles: d `size * 0.26` at (0,-0.1), d `size * 0.22` at (-0.16,-0.06), d `size * 0.22` at (0.16,-0.06).
- PUFF SHADE: Ellipse, width `size * 0.4`, height `size * 0.08`, fill `#ECECE4` at 0.6 opacity, offset y `size * 0.0` (soft shadow where the puff meets the band).

Notes: all-white so it must rely on subtle grey shading to read as 3D against a light background.

---

## 22. cowboy hat

- kind id: `cowboyHat`
- rarity: rare
- cost: 300
- category: fun

A wide-brim cowboy hat with an upturned brim, a pinched crown, and a banded base. Tan leather.

Shapes (anchor = top of head; uses new `CowboyBrimShape` and `CowboyCrownShape`):
- BRIM: CowboyBrimShape, width `size * 0.72`, height `size * 0.18`, fill `#C8924E`, offset y `size * 0.06` (a wide flat ellipse whose left and right edges curl upward; see shape def).
- BRIM EDGE: same CowboyBrimShape stroked, stroke `#A9762F` lineWidth `size * 0.01`, same frame and offset (a darker rim line).
- CROWN: CowboyCrownShape, width `size * 0.34`, height `size * 0.26`, fill `#D49C56`, offset y `-size * 0.08` (a rounded crown with a centre pinch/dent on top; see shape def).
- HAT BAND: Capsule, width `size * 0.34`, height `size * 0.05`, fill `#8A5A2E`, offset y `size * 0.0`.
- BAND BUCKLE: small RoundedRectangle corner `size * 0.006`, width `size * 0.04`, height `size * 0.03`, fill `#F0C24A`, offset x `size * 0.1`, y `size * 0.0`.

Notes: the upturned brim sides are the signature; the crown pinch sells "cowboy" even tiny. Warm leather tones.

---

## 23. top hat

- kind id: `topHat`
- rarity: rare
- cost: 300
- category: fun

A tall black formal top hat with a red ribbon band. Sleek and a bit fancy.

Shapes (anchor = top of head):
- BRIM: Ellipse, width `size * 0.56`, height `size * 0.1`, fill `#1F1B16`, offset y `size * 0.08`.
- BRIM SHINE: Ellipse, width `size * 0.5`, height `size * 0.05`, fill `#3A332A` at 0.6 opacity, offset y `size * 0.075`.
- STACK: RoundedRectangle corner `size * 0.03`, width `size * 0.32`, height `size * 0.36`, fill `#26221C`, offset y `-size * 0.1` (the tall cylinder; corners just round the top edge softly).
- STACK TOP: Ellipse, width `size * 0.32`, height `size * 0.07`, fill `#1F1B16`, offset y `-size * 0.27` (the top oval so the cylinder reads as round).
- STACK SHINE: Capsule, width `size * 0.04`, height `size * 0.24`, fill `#4A4238` at 0.5 opacity, offset x `-size * 0.08`, y `-size * 0.1` (a vertical highlight stripe).
- RIBBON BAND: Capsule, width `size * 0.32`, height `size * 0.07`, fill `#C0394A`, offset y `size * 0.02`.

Notes: the top oval plus the side highlight stripe make the flat rectangle read as a glossy cylinder. Keep blacks slightly warm (charcoal, not pure 000) for the cozy palette.

---

## 24. beret

- kind id: `beret`
- rarity: common
- cost: 120
- category: fun

A soft slouchy beret tilted to one side, with a little stalk on top. Classic Parisian red.

Shapes (anchor = top of head):
- BERET BODY: Ellipse, width `size * 0.5`, height `size * 0.26`, fill `#D24B58`, offset x `size * 0.04`, y `-size * 0.05`, rotation `-12` degrees (the tilt).
- BODY SHADE: Ellipse, width `size * 0.4`, height `size * 0.12`, fill `#B83C49` at 0.6 opacity, offset x `size * 0.06`, y `size * 0.0`, rotation `-12` degrees (underside shadow on the slouch).
- HEADBAND: Capsule, width `size * 0.42`, height `size * 0.07`, fill `#A83340`, offset y `size * 0.06` (the snug band that grips the head).
- STALK: Capsule, width `size * 0.025`, height `size * 0.05`, fill `#A83340`, offset x `size * 0.04`, y `-size * 0.18`, rotation `-12` degrees (the little nub on top).

Notes: the whole beret tilts; keep the headband level (not rotated) so it sits on the head straight while the disc slouches off one side.

---

## 25. headphones

- kind id: `headphones`
- rarity: rare
- cost: 280
- category: fun

Over-ear headphones: a band arcing over the head and two round ear cups on the sides. Modern, cute.

Shapes (anchor = top of head; uses new `ArcBandShape`):
- BAND: ArcBandShape, width `size * 0.5`, height `size * 0.3`, stroke `#3A3F4A` lineWidth `size * 0.05`, offset y `-size * 0.02` (a half-ring arc over the top; see shape def). Stroke uses a round line cap.
- BAND HIGHLIGHT: ArcBandShape, width `size * 0.5`, height `size * 0.3`, stroke `#586070` lineWidth `size * 0.018`, offset y `-size * 0.025` (a lighter inner highlight along the band).
- LEFT CUP: RoundedRectangle corner `size * 0.06`, width `size * 0.14`, height `size * 0.18`, fill `#3A3F4A`, offset x `-size * 0.24`, y `size * 0.06`.
- RIGHT CUP: RoundedRectangle corner `size * 0.06`, width `size * 0.14`, height `size * 0.18`, fill `#3A3F4A`, offset x `size * 0.24`, y `size * 0.06`.
- LEFT CUSHION: Ellipse, width `size * 0.08`, height `size * 0.12`, fill `#E66B8A`, offset x `-size * 0.22`, y `size * 0.06` (a pink ear cushion accent).
- RIGHT CUSHION: Ellipse, width `size * 0.08`, height `size * 0.12`, fill `#E66B8A`, offset x `size * 0.22`, y `size * 0.06`.

Notes: ear cups sit on the head sides at the eye-ish line; the band hugs the top. Swap cushion colour for a recolor option later.

---

## 26. tiara

- kind id: `tiara`
- rarity: epic
- cost: 460
- category: fun

A delicate princess tiara: a thin silver arc band with three rising points, each topped with a gem, and a big centre teardrop gem. Lighter and daintier than the crown.

Shapes (anchor = top of head; uses new `TiaraShape`):
- BAND: TiaraShape, width `size * 0.46`, height `size * 0.2`, fill `#E9EEF4` (silver), with overlay TiaraShape stroke `#B9C4D2` lineWidth `size * 0.006`, offset y `size * 0.02` (a gentle arc band that rises into 3 soft points; see shape def).
- CENTRE GEM: a teardrop, use new `TeardropShape`, width `size * 0.07`, height `size * 0.1`, fill `#7EC8F0`, offset y `-size * 0.06` (point down; see shape def).
- CENTRE GEM SHINE: Circle, diameter `size * 0.02`, fill `#FFFFFF` at 0.85 opacity, offset x `-size * 0.012`, y `-size * 0.08`.
- LEFT GEM: Circle, diameter `size * 0.045`, fill `#F39ED0`, offset x `-size * 0.15`, y `-size * 0.04`.
- RIGHT GEM: Circle, diameter `size * 0.045`, fill `#F39ED0`, offset x `size * 0.15`, y `-size * 0.04`.
- BAND SPARKLE: 2 tiny StarShape(innerRatio: 0.4), width `size * 0.03`, fill `#FFFFFF` at 0.9 opacity, at x `-size * 0.08`, `size * 0.08`, y `-size * 0.0` (little glints along the band).

Notes: silver and soft pastel gems keep it dainty versus the gold crown. The centre teardrop is the focal point.

---

## 27. little horns

- kind id: `littleHorns`
- rarity: rare
- cost: 280
- category: fun

Two tiny curved devil/imp horns poking up. Mischievous but still cute and round-tipped. Soft red, can recolor.

Shapes (anchor = top of head; uses new `HornShape`):
- LEFT HORN: HornShape, width `size * 0.1`, height `size * 0.2`, fill `#D85A5A`, offset x `-size * 0.13`, y `-size * 0.08`, rotation `-14` degrees (a short cone curving outward, rounded tip; see shape def).
- RIGHT HORN: HornShape (mirrored), width `size * 0.1`, height `size * 0.2`, fill `#D85A5A`, offset x `size * 0.13`, y `-size * 0.08`, rotation `14` degrees.
- LEFT HORN SHADE: HornShape, width `size * 0.1`, height `size * 0.2`, fill `#BE4747` at 0.5 opacity, offset x `-size * 0.125`, y `-size * 0.075`, rotation `-14` degrees (inner curve shadow).
- RIGHT HORN SHADE: HornShape, width `size * 0.1`, height `size * 0.2`, fill `#BE4747` at 0.5 opacity, offset x `size * 0.125`, y `-size * 0.075`, rotation `14` degrees.
- LEFT BASE: Ellipse, width `size * 0.06`, height `size * 0.03`, fill `#BE4747`, offset x `-size * 0.13`, y `size * 0.01` (where the horn meets the head).
- RIGHT BASE: Ellipse, width `size * 0.06`, height `size * 0.03`, fill `#BE4747`, offset x `size * 0.13`, y `size * 0.01`.

Notes: keep horns short and the tips rounded for cuteness, not menace. Mirror the HornShape for the right side.

---

## 28. soft halo

- kind id: `softHalo`
- rarity: epic
- cost: 500
- category: fun

A glowing golden ring floating above the head, with a soft outer glow. Angelic, premium.

Shapes (anchor = top of head):
- GLOW: Circle (or Ellipse), width `size * 0.4`, height `size * 0.16`, fill `#FFE9A0` at 0.35 opacity, offset y `-size * 0.24`, with a Gaussian-like soft look (renderer can add `.blur(radius: size * 0.03)`).
- RING OUTER: Ellipse, drawn as a stroke. Use Ellipse().stroke, width `size * 0.34`, height `size * 0.12`, stroke `#FBD24A` lineWidth `size * 0.04`, offset y `-size * 0.24` (a flattened oval ring seen in perspective).
- RING INNER HIGHLIGHT: Ellipse stroke, width `size * 0.34`, height `size * 0.12`, stroke `#FFF0BE` at 0.8 opacity lineWidth `size * 0.014`, offset y `-size * 0.245` (bright top edge).
- SPARKLE 1: StarShape(innerRatio: 0.38), width `size * 0.045`, fill `#FFFFFF` at 0.9, offset x `size * 0.14`, y `-size * 0.2`.
- SPARKLE 2: StarShape(innerRatio: 0.38), width `size * 0.03`, fill `#FFFFFF` at 0.9, offset x `-size * 0.13`, y `-size * 0.28`.

Notes: the ring floats well above the head (high negative y) with a gap. The flattened ellipse stroke reads as a halo in perspective. Premium epic, natural candidate for a gentle float/bob animation later.

---

## 29. bow on head

- kind id: `bowOnHead`
- rarity: common
- cost: 120
- category: fun

A big cute ribbon bow perched on top of the head. Reuses the neck-bow vocabulary (two ellipse loops plus a centre knot), scaled and placed up top, with two short tails.

Shapes (anchor = top of head):
- LEFT LOOP: Ellipse, width `size * 0.2`, height `size * 0.26`, fill `#F06A95`, offset x `-size * 0.12`, y `-size * 0.02`, rotation `-26` degrees.
- RIGHT LOOP: Ellipse, width `size * 0.2`, height `size * 0.26`, fill `#F06A95`, offset x `size * 0.12`, y `-size * 0.02`, rotation `26` degrees.
- LEFT LOOP SHADE: Ellipse, width `size * 0.1`, height `size * 0.16`, fill `#D8497A` at 0.5 opacity, offset x `-size * 0.1`, y `size * 0.0`, rotation `-26` degrees (inner fold shadow).
- RIGHT LOOP SHADE: Ellipse, width `size * 0.1`, height `size * 0.16`, fill `#D8497A` at 0.5 opacity, offset x `size * 0.1`, y `size * 0.0`, rotation `26` degrees.
- LEFT TAIL: RoundedRectangle corner `size * 0.02`, width `size * 0.06`, height `size * 0.14`, fill `#F06A95`, offset x `-size * 0.06`, y `size * 0.1`, rotation `-16` degrees.
- RIGHT TAIL: RoundedRectangle corner `size * 0.02`, width `size * 0.06`, height `size * 0.14`, fill `#F06A95`, offset x `size * 0.06`, y `size * 0.1`, rotation `16` degrees.
- KNOT: Circle, diameter `size * 0.1`, fill `#D8497A`, offset y `-size * 0.02`.

Notes: this is the head version of the existing `bow`; reuse that builder with new offsets/scale if convenient. Tails hang down a touch behind the bow.

---

## 30. bucket hat

- kind id: `bucketHat`
- rarity: common
- cost: 120
- category: fun

A floppy bucket hat with a downturned brim and a topstitch line. Casual, soft. Sage green.

Shapes (anchor = top of head; uses new `BucketBrimShape`):
- CROWN: a soft dome, use RoundedRectangle corner `size * 0.12`, width `size * 0.38`, height `size * 0.22`, fill `#8FAE6A`, offset y `-size * 0.04` (a low rounded box reads as the bucket crown).
- CROWN TOP: Ellipse, width `size * 0.38`, height `size * 0.1`, fill `#9CBC76`, offset y `-size * 0.12` (lighter top so the crown reads rounded).
- BRIM: BucketBrimShape, width `size * 0.6`, height `size * 0.16`, fill `#7C9C58`, offset y `size * 0.08` (a downward-sloping ring brim; see shape def). If `BucketBrimShape` is skipped, use an Ellipse width `size * 0.6` height `size * 0.16` fill `#7C9C58` for a flatter brim.
- TOPSTITCH: Ellipse stroke, width `size * 0.5`, height `size * 0.12`, stroke `#6A8A48` at 0.7 opacity lineWidth `size * 0.008` dashed (renderer: `StrokeStyle(lineWidth:dash:)`), offset y `size * 0.06` (the classic bucket-hat stitch ring around the brim).

Notes: bucket hats are defined by the wide downturned brim plus the stitch line; keep the crown short and squat.

---

# New reusable Shapes (precise Paths for engineering)

Each is defined in a unit rect `r` (the SwiftUI `path(in rect:)` convention). All curves use `addQuadCurve`/`addCurve` for soft rounded forms. Sizes are set by the caller's `.frame`.

## LeafShape
A pointed oval (two arcs meeting at top and bottom tips). Used by strawberry calyx, leaf hat, flower leaf.
```
move to (r.midX, r.maxY)                                  // bottom tip
addQuadCurve to (r.midX, r.minY)                          // up the right side
   control (r.maxX, r.midY)                               // bulge right
addQuadCurve to (r.midX, r.maxY)                          // down the left side back to bottom
   control (r.minX, r.midY)                               // bulge left
closeSubpath
```
For a pointed leaf, the top point is at `r.minY` (y up) and the bottom point at `r.maxY`; widest at `r.midY`.

## FlutedLinerShape
The cupcake paper liner: a trapezoid (narrow top, wide bottom) with a scalloped bottom edge.
```
move to (r.minX + r.width*0.12, r.minY)                   // top-left (liner top is narrower)
addLine to (r.maxX - r.width*0.12, r.minY)                // top-right
addLine to (r.maxX, r.maxY - r.height*0.15)               // down to bottom-right (flares wider)
// scalloped bottom: 5 small upward quad bumps from right to left
for k in 0..<5: addQuadCurve to (next x leftward, r.maxY - r.height*0.15)
   control ((midpoint x), r.maxY)                         // each control dips to r.maxY making a scallop
addLine to (r.minX, r.maxY - r.height*0.15)               // bottom-left
closeSubpath
```
Add 3 to 4 thin vertical "flute" lines as separate overlay Capsules in the caller if more ridging is wanted.

## FrostingSwirlShape
A soft piped-frosting mound: a stack of 2 to 3 rounded humps that taper to a small peak at top.
```
move to (r.minX, r.maxY)                                  // bottom-left of the mound
addQuadCurve to (r.midX, r.maxY)                          // gentle base
   control (r.midX, r.maxY + r.height*0.02)
addLine to (r.maxX, r.maxY)                               // bottom-right
// right side rises in 2 bumps
addQuadCurve to (r.maxX - r.width*0.1, r.minY + r.height*0.45)
   control (r.maxX, r.minY + r.height*0.55)
addQuadCurve to (r.midX + r.width*0.12, r.minY + r.height*0.18)
   control (r.maxX - r.width*0.18, r.minY + r.height*0.18)
// peak
addQuadCurve to (r.midX - r.width*0.12, r.minY + r.height*0.18)
   control (r.midX, r.minY)                               // the top peak
// left side descends in 2 bumps (mirror of right)
addQuadCurve to (r.minX + r.width*0.1, r.minY + r.height*0.45)
   control (r.minX + r.width*0.18, r.minY + r.height*0.18)
addQuadCurve to (r.minX, r.maxY)
   control (r.minX, r.minY + r.height*0.55)
closeSubpath
```
Keep humps soft and rounded, not spiky. The single highlight ellipse (in the caller) sells the swirl.

## EggWhiteShape
An irregular soft blob, wider than tall, with 2 to 3 gentle bumps on the rim. Used by the fried egg hat.
```
// 6 anchor points around an ellipse, radii varied to look hand-poured
center c = (r.midX, r.midY); rx = r.width*0.5; ry = r.height*0.5
points at angles [0, 60, 120, 180, 240, 300] degrees, with radius multipliers
   [1.0, 0.85, 1.05, 0.95, 1.1, 0.8] applied to (rx, ry)
move to first point
connect consecutive points with addQuadCurve, control = midpoint pushed outward ~8%
closeSubpath
```
The varied radius multipliers create the lopsided fried-egg silhouette. Tune multipliers for charm; keep it convex.

## SantaHatShape
A cone that curves and droops to one side (a comma/banana shape) for the Santa and as a base idea for any drooping hat.
```
move to (r.minX, r.maxY)                                  // base-left (sits on the brim)
addLine to (r.maxX, r.maxY)                               // base-right
// right side curves up and bends toward the droop
addQuadCurve to (r.maxX - r.width*0.05, r.minY + r.height*0.25)
   control (r.maxX, r.midY)
// droop tip curling right
addQuadCurve to (r.maxX - r.width*0.0, r.minY + r.height*0.05)
   control (r.maxX - r.width*0.02, r.minY + r.height*0.12)
// underside of the droop returns left toward the body
addQuadCurve to (r.minX + r.width*0.15, r.minY + r.height*0.4)
   control (r.maxX - r.width*0.3, r.minY + r.height*0.15)
// left side back down to base
addQuadCurve to (r.minX, r.maxY)
   control (r.minX, r.midY)
closeSubpath
```
The tip ends near top-right; the caller places the white pom there (offset x `size*0.22`, y `-size*0.26`). Mirror horizontally for a left droop.

## WitchConeShape
A tall slightly-bent cone (witch and wizard hats). Straighter than the Santa droop.
```
move to (r.minX, r.maxY)                                  // base-left
addLine to (r.maxX, r.maxY)                               // base-right
// right edge curves gently inward toward a tip that leans slightly right
addQuadCurve to (r.midX + r.width*0.08, r.minY)
   control (r.maxX - r.width*0.05, r.midY)
// left edge from tip back to base-left
addQuadCurve to (r.minX, r.maxY)
   control (r.minX + r.width*0.05, r.midY)
closeSubpath
```
Tip at `(r.midX + r.width*0.08, r.minY)` gives a subtle lean. Set the lean to 0 (tip at `r.midX`) for a straight cone.

## VineShape
A small open curl (pumpkin vine), drawn as a stroked path (no fill).
```
move to (r.minX, r.maxY)
addCurve to (r.maxX, r.minY + r.height*0.3)
   control1 (r.midX, r.maxY)
   control2 (r.maxX, r.maxY)
addCurve to (r.midX + r.width*0.2, r.minY)
   control1 (r.maxX, r.minY)
   control2 (r.midX + r.width*0.3, r.minY)
```
Leave it open (do not close) and stroke with a round cap so it reads as a tendril.

## AcornCupShape
A dome with a scalloped lower rim (the acorn cap).
```
move to (r.minX, r.midY)
addQuadCurve to (r.maxX, r.midY)                          // the rounded dome top
   control (r.midX, r.minY - r.height*0.1)
// scalloped bottom rim, right to left, ~5 small bumps
for k in 0..<5:
   addQuadCurve to (next x leftward, r.midY + r.height*0.1)
      control ((midpoint x), r.maxY)                      // each dips to r.maxY
closeSubpath
```
The dome is the top half; the scallops give the acorn-cup texture along the bottom edge.

## PropellerBladeShape
Two tapered blades extending left and right from a central hub (one "bar"; the caller rotates a second copy 90 degrees for 4 blades).
```
move to (r.minX, r.midY)                                  // left tip
addQuadCurve to (r.midX, r.midY - r.height*0.5)          // up to centre top
   control (r.width*0.25, r.midY - r.height*0.4)
addQuadCurve to (r.maxX, r.midY)                          // right tip
   control (r.width*0.75, r.midY - r.height*0.4)
addQuadCurve to (r.midX, r.midY + r.height*0.5)          // down to centre bottom
   control (r.width*0.75, r.midY + r.height*0.4)
addQuadCurve to (r.minX, r.midY)                          // back to left tip
   control (r.width*0.25, r.midY + r.height*0.4)
closeSubpath
```
This is a thin leaf-like bar, fat in the middle, tapering to points at both ends.

## CloudShape
A puffy cloud with 3 to 4 bumps along the top (chef hat puff; also reusable for a cloud hat).
```
move to (r.minX, r.maxY)                                  // bottom-left
addLine to (r.maxX, r.maxY)                               // bottom-right (flat base)
// top bumps right-to-left
addQuadCurve to (r.maxX - r.width*0.22, r.minY + r.height*0.25)
   control (r.maxX + r.width*0.02, r.minY)
addQuadCurve to (r.midX, r.minY + r.height*0.1)
   control (r.maxX - r.width*0.3, r.minY - r.height*0.05)
addQuadCurve to (r.minX + r.width*0.22, r.minY + r.height*0.25)
   control (r.minX + r.width*0.3, r.minY - r.height*0.05)
addQuadCurve to (r.minX, r.maxY)
   control (r.minX - r.width*0.02, r.minY)
closeSubpath
```
3 visible bumps across the top; flat bottom sits on the chef-hat band.

## CowboyBrimShape
A wide flat ellipse whose left and right edges curl upward (the cowboy upturned brim).
```
move to (r.minX + r.width*0.05, r.midY)                   // left edge, lifted
addQuadCurve to (r.midX, r.maxY)                          // dip down across the front
   control (r.width*0.25, r.maxY + r.height*0.1)
addQuadCurve to (r.maxX - r.width*0.05, r.midY)           // up to the right lifted edge
   control (r.width*0.75, r.maxY + r.height*0.1)
addQuadCurve to (r.midX, r.minY + r.height*0.2)           // back edge across the top
   control (r.width*0.75, r.minY - r.height*0.1)
addQuadCurve to (r.minX + r.width*0.05, r.midY)           // back to left edge
   control (r.width*0.25, r.minY - r.height*0.1)
closeSubpath
```
The left/right anchors at `r.midY` while the front dips to `r.maxY` produce the upturned-sides look.

## CowboyCrownShape
A rounded crown with a centre pinch (dent) on top.
```
move to (r.minX, r.maxY)                                  // base-left
addQuadCurve to (r.midX - r.width*0.18, r.minY + r.height*0.1)  // up left shoulder
   control (r.minX, r.minY + r.height*0.2)
addQuadCurve to (r.midX, r.minY + r.height*0.35)          // dip into the centre pinch
   control (r.midX - r.width*0.1, r.minY)
addQuadCurve to (r.midX + r.width*0.18, r.minY + r.height*0.1)  // up right shoulder
   control (r.midX + r.width*0.1, r.minY)
addQuadCurve to (r.maxX, r.maxY)                          // down right side to base
   control (r.maxX, r.minY + r.height*0.2)
addLine to (r.minX, r.maxY)                               // close base
closeSubpath
```
The centre control dipping to `r.minY + r.height*0.35` makes the pinch.

## ArcBandShape
A half-ring arc over the top of the head (headphones band). Stroked, not filled.
```
move to (r.minX, r.maxY)                                  // left base
addQuadCurve to (r.maxX, r.maxY)                          // arc over the top
   control (r.midX, r.minY - r.height*0.2)
```
Open path, stroked with a round line cap. The two ear cups (in the caller) sit at the arc's left/right base ends.

## TiaraShape
A gentle arc band that rises into 3 soft points (centre highest).
```
move to (r.minX, r.maxY)                                  // band base-left
addQuadCurve to (r.minX + r.width*0.22, r.midY)          // up to left point
   control (r.minX + r.width*0.1, r.maxY)
addQuadCurve to (r.midX - r.width*0.1, r.midY + r.height*0.1)  // dip between left and centre
   control (r.minX + r.width*0.22, r.maxY - r.height*0.1)
addQuadCurve to (r.midX, r.minY)                         // up to the tall centre point
   control (r.midX - r.width*0.05, r.minY + r.height*0.2)
addQuadCurve to (r.midX + r.width*0.1, r.midY + r.height*0.1)  // down to dip
   control (r.midX + r.width*0.05, r.minY + r.height*0.2)
addQuadCurve to (r.maxX - r.width*0.22, r.midY)          // up to right point
   control (r.maxX - r.width*0.22, r.maxY - r.height*0.1)
addQuadCurve to (r.maxX, r.maxY)                         // down to band base-right
   control (r.maxX - r.width*0.1, r.maxY)
// base line back, slightly arced
addQuadCurve to (r.minX, r.maxY)
   control (r.midX, r.maxY - r.height*0.06)
closeSubpath
```
Centre point reaches `r.minY`; the two side points reach only `r.midY` so the centre is clearly tallest. The gems (in the caller) sit on the 3 points.

## TeardropShape
A teardrop gem, point down, round top (tiara centre gem).
```
move to (r.midX, r.maxY)                                  // bottom point
addQuadCurve to (r.minX, r.minY + r.height*0.3)          // up the left to the round top
   control (r.minX, r.maxY - r.height*0.2)
addQuadCurve to (r.midX, r.minY)                         // over the top
   control (r.minX, r.minY)
addQuadCurve to (r.maxX, r.minY + r.height*0.3)          // down the right
   control (r.maxX, r.minY)
addQuadCurve to (r.midX, r.maxY)                         // back to the bottom point
   control (r.maxX, r.maxY - r.height*0.2)
closeSubpath
```
Rounded bulb at top, sharp point at the bottom.

## HornShape
A short cone that curves outward with a rounded tip (little horns). Drawn for the LEFT horn; mirror x for the right.
```
move to (r.minX, r.maxY)                                  // base-outer
addQuadCurve to (r.maxX, r.maxY)                          // base-inner
   control (r.midX, r.maxY + r.height*0.06)               // slightly rounded base
// inner edge rises and curves out toward the tip
addQuadCurve to (r.midX + r.width*0.15, r.minY + r.height*0.1)
   control (r.maxX, r.midY)
// rounded tip
addQuadCurve to (r.midX - r.width*0.15, r.minY + r.height*0.1)
   control (r.midX, r.minY)                               // tip apex
// outer edge curves back down to base-outer
addQuadCurve to (r.minX, r.maxY)
   control (r.minX, r.midY)
closeSubpath
```
The tip apex at `(r.midX, r.minY)` is rounded by the two quad curves meeting there; the outer edge bows outward via its control at `(r.minX, r.midY)`.

## CrescentShape
A crescent moon (wizard hat), made by subtracting one circle from another. Easiest as an even-odd fill of two arcs.
```
// outer disc
addArc center (r.midX, r.midY) radius r.width*0.5, 0 to 360
// inner disc, shifted right to bite a crescent, added in reverse winding
addArc center (r.midX + r.width*0.28, r.midY) radius r.width*0.42, 360 to 0
use .fill(style: FillStyle(eoFill: true))
```
The offset inner circle removed via even-odd leaves a left-facing crescent. Adjust the inner offset for a fatter or thinner moon.

## SnowflakeShape (optional, for snow hat flakes)
A simple 6-spoke flake, stroked.
```
center c = (r.midX, r.midY); rad = r.width*0.5
for i in 0..<6:
   angle = i * 60 degrees
   move to c
   addLine to (c.x + cos(angle)*rad, c.y + sin(angle)*rad)
```
Stroke thin with a round cap. If even this is too fiddly at small size, the snow hat can fall back to a `StarShape` or plain Circle dots for flakes.

## BucketBrimShape (optional, for bucket hat)
A downward-sloping ring brim (front dips lower than the sides).
```
move to (r.minX, r.midY)                                  // left edge
addQuadCurve to (r.midX, r.maxY)                          // dip down at the front
   control (r.width*0.25, r.maxY)
addQuadCurve to (r.maxX, r.midY)                          // up to right edge
   control (r.width*0.75, r.maxY)
addQuadCurve to (r.midX, r.minY + r.height*0.3)           // back edge across the top
   control (r.width*0.75, r.minY)
addQuadCurve to (r.minX, r.midY)                          // back to left edge
   control (r.width*0.25, r.minY)
closeSubpath
```
Front dips to `r.maxY`, sides at `r.midY`, giving the floppy downturned brim. If skipped, a plain Ellipse brim works.

---

# Engineering notes (wiring into the app)

- Add each `kind id` to `Cosmetic.Kind` in `Yolkling/Core/Cosmetics/Cosmetic.swift` and a matching `case` in `CosmeticView.body`'s switch in `CosmeticView.swift`.
- Add a `Cosmetic(...)` row per hat in `CosmeticCatalog.all` with `slot: .hat` and the rarity/cost from the table above.
- New reusable Shapes go at the bottom of `CosmeticView.swift` next to the existing `Triangle`, `Diamond`, `StarShape`, `CrownShape`.
- All colours via the existing `Color(hex:)` initializer (for example `Color(hex: 0x5BAE5A)`). Every hex in this doc is a valid 6-digit ASCII value.
- Animation candidates for later: propeller cap (spin), soft halo (slow float/bob), wizard hat stars (twinkle opacity).
