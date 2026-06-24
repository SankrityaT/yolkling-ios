# Cozy family

The comfort family: the warmest, softest, most huggable yolklings. Desserts and soft textures. Warm creams, soft browns, peach, butter yellow, berry, oat beige. Everything below is pure SwiftUI vector shapes (Circle, Ellipse, Capsule, RoundedRectangle, small Path/arcs, simple gradients). No images, no emoji, no SF Symbols for body parts.

Conventions match the existing base creature (`Yolkling/Core/Creature/YolklingView.swift`):
- Colours are `Color(hex: 0xRRGGBB)`, or `vibe.body` / `vibe.deep` for the creature's own palette.
- All sizes and offsets are multiples of the single `size` value.
- y grows DOWNWARD. Top features sit roughly between y `-size*0.40` and `-size*0.60`.
- The head/body is a Circle of width/height `size`, centred at origin. Its top edge is at about y `-size*0.5`.
- Patterns are drawn ON the body and clipped with `.clipShape(Circle().frame(width: size, height: size))` style, i.e. masked to the body circle so nothing spills past the silhouette.
- "accent" below means a third palette hex (the species `accent` column); when a species has no accent, use a tint of `vibe.deep` as noted.

---

## New top features

Each is a small ZStack drawn by `topFeature()` (same slot as ears/sprout/tuft). Shapes, sizes, offsets, rotation, and fill are given exactly. Keep each to a handful of shapes.

### 1. cream swirl
A soft-serve curl of piped cream. Three stacked Ellipses of decreasing size, plus a tiny round tip.
- Ellipse, w `size*0.20`, h `size*0.12`, fill `#FFF6E8`, offset y `-size*0.46`.
- Ellipse, w `size*0.15`, h `size*0.10`, fill `#FFFBF2`, offset x `size*0.02`, y `-size*0.53`.
- Ellipse, w `size*0.10`, h `size*0.075`, fill `#FFF6E8`, offset x `-size*0.015`, y `-size*0.585`.
- Circle (tip), w/h `size*0.045`, fill `#FFFDF8`, offset x `size*0.01`, y `-size*0.625`.

### 2. knit bobble (pom-pom)
A fuzzy yarn pom on a tiny stalk. One soft Circle plus three small Circles around its edge to fuzz the silhouette.
- Capsule (stalk), w `size*0.03`, h `size*0.08`, fill `vibe.deep`, offset y `-size*0.49`.
- Circle (pom core), w/h `size*0.17`, fill accent (default `#F2D7B8`), offset y `-size*0.57`.
- Circle, w/h `size*0.07`, fill accent, offset x `-size*0.07`, y `-size*0.55`.
- Circle, w/h `size*0.07`, fill accent, offset x `size*0.07`, y `-size*0.59`.
- Circle, w/h `size*0.06`, fill accent, offset x `size*0.02`, y `-size*0.64`.
(Slight `.opacity(0.92)` on the three outer Circles reads as soft fuzz.)

### 3. cream dollop
A single relaxed blob of whipped cream with a curled peak. Use a small Path, or approximate with two Ellipses and a tip Circle.
- Ellipse (base), w `size*0.22`, h `size*0.13`, fill `#FFFBF2`, offset y `-size*0.47`.
- Ellipse (upper), w `size*0.13`, h `size*0.11`, fill `#FFFDF8`, rotation `-12°`, offset x `size*0.03`, y `-size*0.55`.
- Circle (peak tip), w/h `size*0.05`, fill `#FFFFFF`, offset x `size*0.06`, y `-size*0.60`.

### 4. steam wisp
Two thin rising curls of warm steam. Use the existing `TuftShape`-style stroked Path, thin and tall, or two stroked arcs.
- Path/arc 1: a gentle S-curve, stroke width `size*0.022`, lineCap round, colour `#FFFFFF` at `.opacity(0.55)`, framed w `size*0.06` h `size*0.20`, offset x `-size*0.05`, y `-size*0.55`.
- Path/arc 2: mirrored S-curve, stroke width `size*0.018`, colour `#FFFFFF` at `.opacity(0.40)`, framed w `size*0.05` h `size*0.16`, offset x `size*0.05`, y `-size*0.57`.
(Steam reads best paired with a hot-cocoa or matcha body. Drawn behind the head like other top features.)

### 5. marshmallow tuft
Two squishy marshmallow pillows nestled on top. Two RoundedRectangles, very round corners, plus a soft highlight.
- RoundedRectangle, w `size*0.15`, h `size*0.12`, cornerRadius `size*0.05`, fill `#FFF7F1`, rotation `-8°`, offset x `-size*0.05`, y `-size*0.50`.
- RoundedRectangle, w `size*0.13`, h `size*0.11`, cornerRadius `size*0.045`, fill `#FFFDFB`, rotation `10°`, offset x `size*0.06`, y `-size*0.52`.
- Ellipse (highlight), w `size*0.06`, h `size*0.03`, fill `#FFFFFF` at `.opacity(0.7)`, offset x `-size*0.04`, y `-size*0.53`.

### 6. folded dough ears
Two soft folded ears like raised dough or a bun, warmer and rounder than the base `ears`. Each ear is an Ellipse with an inner fold line.
- Ellipse (left ear), w `size*0.17`, h `size*0.22`, fill `vibe.body`, rotation `-16°`, offset x `-size*0.26`, y `-size*0.43`.
- Capsule (left fold), w `size*0.03`, h `size*0.11`, fill `vibe.deep` at `.opacity(0.35)`, rotation `-16°`, offset x `-size*0.26`, y `-size*0.43`.
- Ellipse (right ear), w `size*0.17`, h `size*0.22`, fill `vibe.body`, rotation `16°`, offset x `size*0.26`, y `-size*0.43`.
- Capsule (right fold), w `size*0.03`, h `size*0.11`, fill `vibe.deep` at `.opacity(0.35)`, rotation `16°`, offset x `size*0.26`, y `-size*0.43`.

### 7. cherry on top
A glossy berry with a tiny stem. One Circle, a highlight, a thin stem Capsule.
- Capsule (stem), w `size*0.02`, h `size*0.10`, fill `#7A9A52`, rotation `12°`, offset x `size*0.01`, y `-size*0.55`.
- Circle (cherry), w/h `size*0.12`, fill `#E0556B`, offset y `-size*0.49`.
- Ellipse (gloss), w `size*0.04`, h `size*0.025`, fill `#FFFFFF` at `.opacity(0.75)`, offset x `-size*0.025`, y `-size*0.51`.

### 8. honey drip
A warm bead of honey resting on top, with a soft drop hanging just over the brow. Two Ellipses plus a small drip Circle.
- Ellipse (pool), w `size*0.20`, h `size*0.10`, fill `#F2B84B`, offset y `-size*0.47`.
- Ellipse (pool highlight), w `size*0.08`, h `size*0.035`, fill `#FBD884` at `.opacity(0.8)`, offset x `-size*0.04`, y `-size*0.485`.
- Circle (drip bead), w/h `size*0.05`, fill `#F2B84B`, offset x `size*0.05`, y `-size*0.42`.

### 9. teacup steam crown
A tiny porcelain handle/curl framing the head, cosy and minimal. One stroked arc (the handle), one warm dot.
- Arc (handle), a C-shaped stroked Path, stroke width `size*0.03`, lineCap round, colour `#FFFFFF`, framed w `size*0.10` h `size*0.14`, offset x `size*0.16`, y `-size*0.40`.
- Circle (warm dot / button), w/h `size*0.04`, fill accent (default `#E7B27A`), offset x `-size*0.16`, y `-size*0.42`.
(Reads as the rim/handle of a cup peeking up behind the head. Keep subtle.)

### 10. fuzzy wool tuft
A soft cloud of wool, like a sheep's curl. Three overlapping Circles forming a bumpy cloud.
- Circle, w/h `size*0.12`, fill `#F4ECDD`, offset x `-size*0.06`, y `-size*0.50`.
- Circle, w/h `size*0.14`, fill `#FBF4E8`, offset y `-size*0.55`.
- Circle, w/h `size*0.11`, fill `#F4ECDD`, offset x `size*0.06`, y `-size*0.51`.
(Each Circle at `.opacity(0.96)` so overlaps read as soft fluff.)

---

## New patterns

Overlays drawn ON the body and clipped to the body circle (so nothing spills past the silhouette). All offsets are relative to the body centre; the body spans roughly x/y `-size*0.5 ... size*0.5`. Use lighter/darker shades of `vibe.body` or an accent hex at low opacity so the pattern stays soft and harmonious.

### 1. cocoa freckles
A light dusting of tiny cocoa specks across the cheeks and lower face.
- 7 to 9 small Circles, w/h `size*0.018` to `size*0.026`, fill `vibe.deep` at `.opacity(0.5)`.
- Scatter offsets (x, y as multiples of size): `(-0.22, 0.10)`, `(-0.16, 0.14)`, `(-0.10, 0.09)`, `(0.10, 0.10)`, `(0.17, 0.13)`, `(0.23, 0.08)`, `(-0.04, 0.16)`, `(0.04, 0.15)`, `(0.0, 0.20)`.
- Keep them low on the face, below the eyes, so they read as freckles not noise.

### 2. cream belly patch
A soft pale patch over the lower belly, like a two-tone plush.
- One large Ellipse, w `size*0.55`, h `size*0.42`, fill `#FFF6E8` at `.opacity(0.9)`, offset y `size*0.18`.
- Clip to the body circle so the patch curves with the silhouette at the bottom.
- Optional inner Ellipse, w `size*0.40`, h `size*0.30`, fill `#FFFBF3` at `.opacity(0.8)`, same offset, for a soft gradient feel.

### 3. knit v-stitches
A cosy knitted-sweater texture of small chevrons across the lower body.
- Rows of small V (chevron) shapes drawn as stroked Paths: each V is two short line segments meeting at a low point, framed w `size*0.07` h `size*0.05`, stroke width `size*0.018`, lineCap round, colour `vibe.deep` at `.opacity(0.35)`.
- Layout: 3 rows of 4 to 5 stitches. Row y offsets `size*0.06`, `size*0.16`, `size*0.26`; stitch x offsets across `-size*0.20 ... size*0.20` in steps of `size*0.10`, alternate rows shifted by `size*0.05`.
- Clip to the body circle so edge stitches fade at the silhouette.

### 4. sprinkle dots
Scattered pastel sprinkles (tiny capsules) like funfetti, across the upper body.
- 8 to 10 small Capsules, w `size*0.012`, h `size*0.04`, each a random small rotation (`-40°`...`40°`).
- Colours cycle through soft pastels: `#F4A6B8` (pink), `#A8D8C0` (mint), `#F4D08A` (butter), `#B6A8E0` (lilac), each at `.opacity(0.85)`.
- Scatter offsets (x, y): `(-0.20, -0.10)`, `(-0.12, 0.02)`, `(-0.04, -0.14)`, `(0.05, -0.06)`, `(0.14, -0.12)`, `(0.20, 0.0)`, `(0.08, 0.08)`, `(-0.16, 0.10)`, `(0.0, 0.0)`, `(-0.08, -0.04)`.

### 5. toasty cheeks gradient
Extra warmth: a soft toasted-gradient glow on each cheek (beyond the base blush), like the browned edge of toast.
- Two Ellipses, w `size*0.26`, h `size*0.20`, fill a RadialGradient from `vibe.deep` at `.opacity(0.0)` (centre) to `vibe.deep` at `.opacity(0.30)` (edge), blurred `radius 3`.
- Offsets x `-size*0.30` and `size*0.30`, y `size*0.06` (same band as the base blush, sitting just outside it).
- Clip to the body circle.

### 6. swirl marbling
A gentle marble swirl, like cocoa folded into cream (matcha-and-cream, mocha).
- One stroked spiral Path: an arc that curves from upper-left down to lower-right, stroke width `size*0.05`, lineCap round, colour `vibe.deep` at `.opacity(0.22)`, framed across w `size*0.7` h `size*0.7`, centred.
- A second thinner swirl Path, stroke width `size*0.03`, colour `#FFFFFF` at `.opacity(0.25)`, offset slightly (x `size*0.04`, y `-size*0.03`).
- Clip to the body circle so the swirl reads as marbling under the surface.

---

## Accessories

Small, tasteful, code-drawable. Drawn in the outfit/accessory layer at the noted anchor. All pure shapes.

### 1. knit scarf
A chunky scarf around the neck (base of head), with a short hanging tail.
- Capsule (wrap), w `size*0.62`, h `size*0.14`, fill accent (default `#D98C7A`), offset y `size*0.34`.
- RoundedRectangle (tail), w `size*0.12`, h `size*0.22`, cornerRadius `size*0.03`, fill accent, offset x `size*0.12`, y `size*0.46`.
- 3 thin Capsules (fringe), w `size*0.012`, h `size*0.05`, fill accent (darkened ~15%), at the tail's bottom edge, offsets x `size*0.08/0.12/0.16`, y `size*0.57`.
- Optional 2 thin horizontal lines (`vibe.deep` at `.opacity(0.2)`, width `size*0.006`) across the wrap for a knit ribbing hint.

### 2. tiny chef / sleep cap
A soft folded cap sitting back on the head, like a nightcap or baker's cap. One slumped Capsule plus a pom.
- Capsule (cap body), w `size*0.34`, h `size*0.16`, fill `#FBF4E8`, rotation `-10°`, offset x `size*0.08`, y `-size*0.38`.
- Capsule (cap band), w `size*0.30`, h `size*0.06`, fill `#F0E6D2`, offset y `-size*0.32`.
- Circle (pom), w/h `size*0.07`, fill `#FFFFFF`, offset x `size*0.22`, y `-size*0.42`.

### 3. cocoa mug
A little mug held at the side, with a warm fill line. Held low, off to one side.
- RoundedRectangle (mug body), w `size*0.16`, h `size*0.15`, cornerRadius `size*0.03`, fill `#F4ECDD`, offset x `size*0.34`, y `size*0.30`.
- RoundedRectangle (cocoa fill), w `size*0.12`, h `size*0.05`, cornerRadius `size*0.02`, fill `#7A4B33`, offset x `size*0.34`, y `size*0.26`.
- Arc (handle), stroked Path C-shape, stroke width `size*0.02`, colour `#F4ECDD`, framed w `size*0.06` h `size*0.10`, offset x `size*0.44`, y `size*0.30`.
- 2 thin steam arcs above (`#FFFFFF` at `.opacity(0.5)`, stroke `size*0.012`), offset y `size*0.18`.

### 4. berry beret
A soft slouchy beret tilted on the head, with a tiny stem nub.
- Ellipse (beret), w `size*0.40`, h `size*0.20`, fill accent (default `#B5547A`), rotation `-8°`, offset x `-size*0.04`, y `-size*0.40`.
- Ellipse (band), w `size*0.30`, h `size*0.06`, fill accent (darkened ~12%), offset y `-size*0.33`.
- Circle (stem nub), w/h `size*0.04`, fill accent (darkened ~20%), offset x `-size*0.12`, y `-size*0.47`.

---

## Species

40 to 60 named species. Columns: name | body hex | deep hex | accent hex (or -) | top feature | pattern (or none) | eye style (default round) | rarity | personality. Eye styles use real values from the codebase: `round`, `happyArc`, `sleepy`, `heart`, `sparkle`. All palettes read on a cream `#FBF6EC` background. No duplicate names.

| name | body | deep | accent | top feature | pattern | eye | rarity | personality |
|------|------|------|--------|-------------|---------|-----|--------|-------------|
| mochi | `#F7E4E1` | `#E6B9B3` | `#FFF6E8` | classic | cream belly patch | round | common | squishy and endlessly patient |
| matcha cream | `#C2D9A0` | `#9BBE6E` | `#FFF6E8` | cream swirl | swirl marbling | happyArc | rare | calm, sips life slowly |
| honeydrop | `#F6D98A` | `#E0B04F` | `#FBD884` | honey drip | toasty cheeks gradient | round | common | sweet and a little sticky |
| marshmallow | `#FBF4F0` | `#E9D7CF` | `#FFFDFB` | marshmallow tuft | none | happyArc | common | weightless, all softness |
| peachfuzz | `#FBD2B6` | `#EBA982` | `#FFE6D2` | folded dough ears | toasty cheeks gradient | round | common | shy, blushes at hellos |
| cocoa | `#9C6B4E` | `#6F4632` | `#F4ECDD` | steam wisp | cocoa freckles | sleepy | common | warm to the very middle |
| toastling | `#E4B47C` | `#B27F47` | `#7A4B33` | folded dough ears | toasty cheeks gradient | round | common | golden, best in the morning |
| cinnaroll | `#E7BE92` | `#B5824F` | `#FFF6E8` | cream swirl | swirl marbling | round | rare | spirals into a cosy nap |
| creampuff | `#FBF1DF` | `#E7D2AC` | `#FFFDF8` | cream dollop | cream belly patch | sparkle | rare | puffed up and proud |
| woolly | `#EDE3D2` | `#C9B89B` | `#F4ECDD` | fuzzy wool tuft | knit v-stitches | sleepy | common | drowsy, made of yarn |
| hotcocoa | `#7A4B33` | `#553223` | `#FFF6E8` | steam wisp | none | sleepy | rare | holds you through cold nights |
| butterbun | `#F8E2A6` | `#E2C263` | `#FFFBF2` | folded dough ears | cream belly patch | round | common | rises slow, warm and round |
| berrytart | `#E89DB0` | `#C56885` | `#FFF6E8` | cherry on top | sprinkle dots | heart | rare | tart-sweet and dramatic |
| oatmel | `#E8DCC2` | `#C4B28C` | `#D9C6A0` | knit bobble | knit v-stitches | round | common | steady, a slow comfort |
| pannacotta | `#FBF3E8` | `#E8D6BE` | `#E0556B` | cherry on top | cream belly patch | happyArc | rare | wobbly and elegant |
| strawmilk | `#F8CBD2` | `#E498A6` | `#FFFFFF` | cream swirl | sprinkle dots | heart | common | pink and giggly |
| caramella | `#D9A45E` | `#A9742F` | `#FFF6E8` | honey drip | swirl marbling | sleepy | rare | melts when held too long |
| custard | `#F6E08C` | `#DEBF54` | `#FFFBF2` | cream dollop | toasty cheeks gradient | happyArc | common | jiggly little optimist |
| s'morsel | `#C99A6E` | `#7A4B33` | `#FFF7F1` | marshmallow tuft | cocoa freckles | round | rare | campfire-warm, a bit gooey |
| chai | `#D7A36B` | `#A4733E` | `#E7B27A` | steam wisp | swirl marbling | sleepy | rare | spiced, slow, contemplative |
| vanilla bean | `#F4E9D4` | `#D8C39A` | `#6F4632` | classic | cocoa freckles | round | common | plain and perfect, freckled |
| roseblush | `#F4C2C8` | `#DB9099` | `#FFF6E8` | berry beret | toasty cheeks gradient | heart | rare | soft-spoken romantic |
| gingerling | `#D98C5A` | `#A85E30` | `#FFF6E8` | folded dough ears | cocoa freckles | round | common | snappy-sweet, full of pep |
| meringue | `#FBF6EE` | `#E8DCC8` | `#F4A6B8` | cream dollop | none | sparkle | rare | airy, whisks about happily |
| mapledrop | `#D79A55` | `#A56C2E` | `#5E3A1E` | honey drip | swirl marbling | happyArc | common | trickles slow and golden |
| cottonpuff | `#FBF5F2` | `#E7DAD3` | `#FFFFFF` | fuzzy wool tuft | none | happyArc | common | a cloud that learned to hug |
| brownsugar | `#B98A5E` | `#86603C` | `#FFF6E8` | knit bobble | cocoa freckles | sleepy | common | rich, dissolves into warmth |
| latteling | `#CBA579` | `#9A744B` | `#FFFBF2` | cream swirl | swirl marbling | sleepy | common | needs a minute to wake up |
| sugarplum | `#C9A3D4` | `#9E72AD` | `#FFF6E8` | cherry on top | sprinkle dots | heart | rare | dainty, dances at dusk |
| toffeenut | `#C68A4E` | `#8E5C28` | `#F4ECDD` | knit bobble | cocoa freckles | round | common | crunchy outside, soft heart |
| snowmallow | `#FDFBF7` | `#E4DCD0` | `#D7E8F0` | marshmallow tuft | cream belly patch | happyArc | rare | the first soft snow, warm anyway |
| peachcobbler | `#F4BD92` | `#D08E58` | `#E7C9A0` | cream dollop | sprinkle dots | round | rare | homey and a little crumbly |
| buttercream | `#F8E6B8` | `#E4C778` | `#FFFDF8` | cream swirl | cream belly patch | happyArc | common | smooth, frosts every worry |
| cocoaknit | `#A87854` | `#755035` | `#E7B27A` | knit bobble | knit v-stitches | sleepy | common | wrapped in its own sweater |
| honeycomb | `#F2C75E` | `#D49E33` | `#FBE9B0` | honey drip | toasty cheeks gradient | round | rare | busy, sweet, always humming |
| redvelvet | `#B4566A` | `#823A4A` | `#FBF4E8` | cream dollop | cocoa freckles | heart | epic | plush, deep, quietly fancy |
| tiramisu | `#C9A47A` | `#8A6244` | `#FBF6EE` | steam wisp | swirl marbling | sleepy | epic | layered moods, mostly mellow |
| frostmint | `#CDE6D6` | `#9CC7AE` | `#FFFFFF` | cream swirl | toasty cheeks gradient | happyArc | rare | cool cream, warm heart |
| pumpkinspice | `#E0975A` | `#AE662E` | `#7A4B33` | steam wisp | cocoa freckles | round | rare | autumn in a small round body |
| coconutmacaroon | `#F2E9D6` | `#D2C2A0` | `#C68A4E` | fuzzy wool tuft | cocoa freckles | round | common | toasty edges, soft middle |
| blueberrymuffin | `#A6A0CF` | `#736CA0` | `#FBF4E8` | cream dollop | sprinkle dots | round | rare | warm from the oven, dotted |
| eggnog | `#F6E7C2` | `#DCC388` | `#C9A35E` | knit bobble | toasty cheeks gradient | sleepy | rare | spiced, a holiday in a cup |
| lavendercream | `#D6C7E4` | `#A992C2` | `#FFF6E8` | cream swirl | swirl marbling | happyArc | rare | calm purple, smells of sleep |
| dulce | `#D2965A` | `#9E6730` | `#FFF6E8` | honey drip | swirl marbling | heart | rare | caramel-soft, says yes to naps |
| fluffernutter | `#E8C98C` | `#C39A53` | `#FFF7F1` | marshmallow tuft | none | happyArc | common | peanut-warm and giggly |
| mochaswirl | `#9A6F50` | `#6B4733` | `#FFFBF2` | cream swirl | swirl marbling | sleepy | epic | bittersweet, deeply cosy |
| applepie | `#E0B274` | `#B07F40` | `#C56885` | folded dough ears | knit v-stitches | round | rare | lattice-warm, mother's-kitchen |
| cremebrulee | `#F2DDA8` | `#CBA862` | `#A56C2E` | classic | toasty cheeks gradient | sparkle | epic | crisp on top, tender beneath |
| sleepyoat | `#DACBAC` | `#B4A079` | `#E7DCC2` | fuzzy wool tuft | knit v-stitches | sleepy | common | always one yawn from a nap |
| cottoncandy | `#F4C4DE` | `#DC93BC` | `#CDE0F2` | fuzzy wool tuft | sprinkle dots | sparkle | rare | spun-sugar dreamer |
| gingerbread | `#B07C45` | `#7E5527` | `#FBF4E8` | knit bobble | cocoa freckles | happyArc | rare | cinnamon-warm, button-eyed joy |
| milktea | `#D8B98C` | `#A8895C` | `#7A4B33` | steam wisp | swirl marbling | sleepy | common | chewy-soft, sweet and slow |
| frostedbun | `#F6DEC2` | `#DDB78C` | `#FFFFFF` | cream swirl | cream belly patch | happyArc | common | glazed and gently glowing |
| chestnut | `#9C6A45` | `#6E482D` | `#F4ECDD` | folded dough ears | cocoa freckles | round | common | roasted-warm, a winter friend |
| sugarcookie | `#F2D9A8` | `#D4B270` | `#E0556B` | cherry on top | sprinkle dots | happyArc | common | iced and ready to celebrate |
| warmmilk | `#FBF1E0` | `#E6D2B4` | `#F4D08A` | steam wisp | cream belly patch | sleepy | common | the last sip before bed |
| velvetbear | `#C18A9C` | `#8E5E70` | `#FBF4E8` | folded dough ears | toasty cheeks gradient | heart | epic | plush as a worn-soft teddy |
| goldenhoney | `#F4C24E` | `#C7912A` | `#FFF6E8` | honey drip | toasty cheeks gradient | sparkle | legendary | a small sun you can hold |
| firstsnowcocoa | `#8A5A3E` | `#5E3A26` | `#FDFBF7` | steam wisp | cream belly patch | sleepy | legendary | the hush of a snowed-in day |
| heirloomquilt | `#D6A878` | `#9E724A` | `#B5547A` | knit bobble | knit v-stitches | happyArc | legendary | every patch a warm memory |
</content>
</invoke>
