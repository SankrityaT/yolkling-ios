# Founding yolklings (limited edition, grant-only)

The founding family. These are the legendary, never-for-sale species granted to
early supporters. They render in the exact same pipeline as every yolkling: a
soft round `Circle` body filled with a `RadialGradient` from a light `body`
colour (top-left) to a `deep` shade (bottom-right), two capsule arms in the body
colour, two ellipse feet in the deep colour, and a face that belongs to emotion
(leave eyes and mouth alone). Everything below is added with `Circle`, `Ellipse`,
`Capsule`, `RoundedRectangle`, small `Path` arcs, gradients, and `.blur`. No art
assets, no images, no emoji.

Coordinate conventions match `YolklingView.swift`:
- `size` is the body diameter. All measurements are multiples of `size`.
- y grows DOWNWARD. The head crown sits around y `-size*0.5`. Feet sit near
  y `+size*0.5`.
- The body gradient is `RadialGradient(colors: [body, body, deep], center:
  UnitPoint(x: 0.36, y: 0.30), startRadius: size*0.05, endRadius: size*0.72)`.
  For an iridescent body you pass 2 to 3 stops in place of `[body, body, deep]`.
- Colours are `Color(hex: 0xRRGGBB)`. All hexes below are real and chosen to read
  well on the cream `#FBF6EC` canvas.
- The aura/glow and halo layers draw BEHIND the body (before `bodyCircle`). The
  shimmer dots draw IN FRONT (after the body, like the particle layer). A crest
  or gem top feature draws in the `topFeature()` slot, behind the head.

A founding yolkling is just a `Vibe` plus a small `FoundingFlair` value that
selects which of the reusable special parts below it wears. Nothing here needs a
new shape primitive the base creature does not already use.

---

## Special parts (auras, shimmer, halos, iridescent bodies)

These are the reusable "magic" layers. Each founding species references one or
more by name. Implement each once, then compose.

### Auras and glows (drawn BEHIND the body)

An aura is a soft `Circle` slightly larger than the body, low opacity, heavily
blurred, sometimes gently breathing. Drop it into the `ZStack` before
`bodyCircle`. To make it breathe, multiply the radius by
`(1 + 0.04 * sin(2 * .pi * 0.15 * t))` using the same view clock `t`.

| name | shape | diameter | fill hex | opacity | blur | notes |
|---|---|---|---|---|---|---|
| `glow.gold` | Circle | `size*1.16` | `0xFFD98A` | 0.34 | `size*0.12` | warm soft-gold halo, the house glow |
| `glow.pearl` | Circle | `size*1.13` | `0xFFF4E8` | 0.40 | `size*0.13` | near-white pearl bloom, very gentle |
| `glow.rose` | Circle | `size*1.15` | `0xFFC2D6` | 0.32 | `size*0.12` | rose-quartz blush halo |
| `glow.moon` | Circle | `size*1.15` | `0xCBD8F2` | 0.30 | `size*0.13` | cool moonstone blue-grey |
| `glow.mint` | Circle | `size*1.14` | `0xBFEBD6` | 0.30 | `size*0.12` | soft sea-glass green |
| `glow.peach` | Circle | `size*1.15` | `0xFFD3B0` | 0.32 | `size*0.12` | sunset peach warmth |
| `glow.lilac` | Circle | `size*1.15` | `0xD9C7F0` | 0.30 | `size*0.12` | dusk lilac |
| `glow.aurora` | two stacked Circles `size*1.20` and `size*1.10` | see notes | `0xA8E6CF` over `0xC9B8F0` | 0.26 each | `size*0.14` | layer mint behind, lilac in front, offset the front one by `(x: size*0.05, y: -size*0.04)` for a two-tone aurora wash |

Tip: for an extra-special "double bloom", draw `glow.pearl` first and a thinner
accent glow on top. Keep total aura opacity under ~0.5 so it stays cozy, never
gaudy.

### Shimmer (twinkling sparkle dots, drawn IN FRONT)

Tiny `Circle`s that pulse opacity over time. Each dot's opacity is
`base + amp * abs(sin(t * speed + phase))`. Use `base 0.25`, `amp 0.6`,
`speed 1.8` unless noted. Give each its own `phase` so they twinkle out of sync.
Fill with white `0xFFFFFF` for a clean sparkle, or the species accent hex for a
tinted one. Add `.blur(radius: size*0.004)` to soften the edge.

Positions are `(x, y)` as fractions of `size`, relative to body centre.

| name | dots (x, y, radius·size, phase) | fill | feel |
|---|---|---|---|
| `shimmer.dust` | (0.30, -0.30, 0.030, 0.0), (-0.34, -0.10, 0.022, 0.7), (0.18, 0.22, 0.018, 1.4), (-0.20, 0.30, 0.024, 2.1) | white | scattered fairy dust around the body |
| `shimmer.crown` | (-0.16, -0.52, 0.028, 0.0), (0.0, -0.58, 0.034, 0.6), (0.16, -0.52, 0.028, 1.2) | accent | three sparkles arcing over the head |
| `shimmer.trail` | (0.38, -0.02, 0.026, 0.0), (0.30, 0.14, 0.020, 0.5), (0.40, 0.26, 0.016, 1.0) | accent | a comet-style sparkle trail down one side |
| `shimmer.cheeks` | (-0.30, 0.08, 0.020, 0.0), (0.30, 0.08, 0.020, 0.9) | `0xFFFFFF` | two gentle highlights by the cheeks |
| `shimmer.single` | (0.22, -0.40, 0.040, 0.0) | white | one slow, large, lonely twinkle (use `speed 1.0`) |

### Halos (thin stroked ring above or around the head)

A halo is a stroked `Ellipse` (an oval ring reads as a halo seen at a tilt). Draw
it BEHIND the body so the head overlaps its lower edge, which sells the "ring
around the head" look. Stroke width and size are multiples of `size`. Tilt with
`.rotationEffect`. For a soft glow, add `.blur(radius: size*0.006)` and/or a
second wider, fainter ring behind.

| name | ellipse w x h | stroke width | colour | y offset | rotation | notes |
|---|---|---|---|---|---|---|
| `halo.ring` | `size*0.62` x `size*0.20` | `size*0.018` | `0xFFD98A` | `-size*0.50` | `-12°` | classic tilted gold ring above the head |
| `halo.thin` | `size*0.58` x `size*0.16` | `size*0.012` | `0xFFF1CC` | `-size*0.52` | `-8°` | delicate pale-gold ring |
| `halo.opal` | `size*0.64` x `size*0.22` | `size*0.018` | use opal gradient (see below) along an `AngularGradient` stroke | `-size*0.49` | `-14°` | iridescent ring; stroke with `AngularGradient(colors: [0xFFD6E8, 0xD6F0FF, 0xE8FFD6, 0xFFE8C2, 0xFFD6E8])` |
| `halo.double` | outer `size*0.70` x `size*0.24`, inner `size*0.56` x `size*0.18` | outer `size*0.010`, inner `size*0.016` | `0xFFE3A8` | `-size*0.50` | `-12°` | two concentric rings, outer fainter (opacity 0.5) |
| `halo.dawn` | `size*0.62` x `size*0.20` | `size*0.018` | `LinearGradient([0xFFB7A0, 0xFFE6B0])` left-to-right | `-size*0.50` | `-10°` | warm sunrise gradient ring |

### Iridescent bodies (2 to 3 stop gradients for the body fill)

Pass these stops into the body's `RadialGradient` in place of
`[body, body, deep]`. Keep the lightest stop first (it lands top-left where the
light is) and the deepest last (bottom-right shade). The middle stop gives the
oil-on-water shimmer. Each pairs with a matching `deep` hex used for feet and
arms shading. Stop positions are approximate `Gradient.Stop` locations.

| name | stops (hex @ position) | matching deep | reads as |
|---|---|---|---|
| `iri.opal` | `0xFFF3F8 @0.0`, `0xCFE9FF @0.45`, `0xE6D2FF @1.0` | `0xB9A6E0` | white opal with blue-to-violet fire |
| `iri.pearl` | `0xFFFBF4 @0.0`, `0xFCE9D8 @0.5`, `0xEFD3C2 @1.0` | `0xD8B79C` | warm cream pearl |
| `iri.rosequartz` | `0xFFF0F4 @0.0`, `0xFFD3E0 @0.5`, `0xF3B9CF @1.0` | `0xDC93B2` | blush rose quartz |
| `iri.moonstone` | `0xF4F8FF @0.0`, `0xD8E4F7 @0.5`, `0xBFD0EE @1.0` | `0x93A7CE` | cool blue moonstone sheen |
| `iri.aurora` | `0xEAFBF0 @0.0`, `0xC9F0E0 @0.4`, `0xCBB9F0 @1.0` | `0x9B86D6` | mint-to-lilac aurora |
| `iri.sunrise` | `0xFFF6E6 @0.0`, `0xFFD9A8 @0.45`, `0xFFB48A @1.0` | `0xE89370` | soft golden sunrise |
| `iri.dusk` | `0xFBEFFA @0.0`, `0xE3C9F0 @0.5`, `0xC7A8E8 @1.0` | `0xA083C9` | lilac dusk |
| `iri.honeygold` | `0xFFF3D2 @0.0`, `0xFFDE8E @0.5`, `0xF6C24B @1.0` | `0xD99E2C` | rich founder gold, the house body |

### Crest and gem top features (drawn in the `topFeature()` slot)

These replace or sit above the head, in the same band as the existing classic /
ears / sprout / tuft features (around y `-size*0.4` to `-size*0.6`). All are
simple shapes.

- **`crest.teardrop` (a soft gem):** a single `Ellipse` `size*0.10` x `size*0.14`
  filled with a `LinearGradient` of the species accent (light top, deep bottom),
  centred at y `-size*0.56`. Add a tiny white `Circle` `size*0.025` highlight at
  the top-left of the gem (offset `(-size*0.02, -size*0.59)`) and a soft
  `glow.gold`-style blurred `Circle` `size*0.16` at 0.3 opacity behind it. Cozy
  rounded gem, never faceted or sharp.

- **`crest.trio`:** three `crest.teardrop` gems in a gentle arc: centre at
  y `-size*0.58` size `size*0.11` tall, two side gems size `size*0.08` at
  `(±size*0.12, -size*0.52)`, each tilted `±16°` outward.

- **`crest.dawnband`:** a thin `Capsule` `size*0.30` x `size*0.04` lying flat
  across the crown at y `-size*0.50`, filled `LinearGradient([0xFFCF8A,
  0xFFE9C2])`, with three tiny `Circle` studs (`size*0.03`) spaced along it in
  white at 0.8 opacity. A delicate diadem, not a heavy crown.

- **`crest.leaflet` (gilded sprout):** the existing `sprout` shape recoloured to
  gold: stem `Capsule` `0xE9C46A`, two leaves `Ellipse` filled
  `LinearGradient([0xFFE2A0, 0xE9C46A])`, plus one white `shimmer.single` dot at
  the leaf tip. A founder's twist on a familiar look.

- **`crest.feather`:** a single soft plume. One `Capsule` `size*0.035` x
  `size*0.22` as the quill at `-size*0.58`, tilted `-12°`, topped by an `Ellipse`
  `size*0.10` x `size*0.20` (the vane) filled with the species iridescent
  gradient, same tilt. Reads as one gentle iridescent feather curving off the
  head.

- **`crest.star` (founder's mark, reserved):** a small four-point soft star built
  from two overlapping thin `Capsule`s (vertical `size*0.16` x `size*0.04`,
  horizontal `size*0.12` x `size*0.035`) with rounded ends, crossing at
  y `-size*0.56`, filled solid `0xFFE6A8`, with a `Circle` `size*0.05` of the
  same colour at the crossing and a `glow.gold` bloom behind. Quiet, warm, the
  single rarest mark.

---

## Founding species

16 hand-crafted founding yolklings. Every one is rarity **founding**: grant-only,
never purchasable. Default eye style is round unless noted (eyes belong to
emotion, so this only suggests a resting catchlight feel, never a fixed
expression). The `body` column is either a single hex or an iridescent gradient
name from the table above; pair it with the listed `deep` for feet and arms.

| # | name | body | deep | accent / glow hex | top feature | aura / halo / shimmer | eye style | why it's special |
|---|---|---|---|---|---|---|---|---|
| 1 | the very first | `iri.honeygold` | `0xD99E2C` | `0xFFE6A8` | `crest.star` | `glow.gold` (breathing) + `halo.double` + `shimmer.crown` | round, with a steady second catchlight | the single rarest founding yolkling, the founder's own. Only the earliest of the early carry the star. |
| 2 | the og | `iri.honeygold` | `0xD99E2C` | `0xFFD98A` | `crest.dawnband` | `glow.gold` + `shimmer.dust` | round | the original gold, plain-spoken and warm. The one everyone wishes they had. |
| 3 | first light | `iri.sunrise` | `0xE89370` | `0xFFE6B0` | none (classic body) | `glow.peach` + `halo.dawn` + `shimmer.crown` | round | the first sunrise after a long wait. A soft dawn ring over a peach body. |
| 4 | daybreak no. 001 | `iri.sunrise` | `0xE89370` | `0xFFD3B0` | `crest.dawnband` | `glow.peach` + `shimmer.cheeks` | round | numbered like a limited print. The diadem says "issued, not bought". |
| 5 | goldenhour | `iri.honeygold` | `0xD99E2C` | `0xFFDE8E` | `crest.leaflet` | `glow.gold` (breathing) + `shimmer.trail` | round | bathed in late-afternoon gold, a gilded sprout catching the last light. |
| 6 | pearl | `iri.pearl` | `0xD8B79C` | `0xFFF4E8` | `crest.teardrop` (pearl accent) | `glow.pearl` + `shimmer.cheeks` | round | a single warm pearl. The quietest, most understated founder. |
| 7 | moonstone | `iri.moonstone` | `0x93A7CE` | `0xCBD8F2` | `crest.teardrop` (moon accent) | `glow.moon` + `halo.thin` + `shimmer.single` | round, cool catchlight | cool blue sheen under one slow twinkle. Calm and rare. |
| 8 | rose quartz | `iri.rosequartz` | `0xDC93B2` | `0xFFC2D6` | `crest.trio` (rose gems) | `glow.rose` + `shimmer.cheeks` | round | three blush gems in a gentle arc. Tender and soft, never loud. |
| 9 | opaline | `iri.opal` | `0xB9A6E0` | `0xE6D2FF` | `crest.teardrop` (opal accent) | `glow.pearl` + `halo.opal` + `shimmer.dust` | round | white opal with hidden blue-violet fire and an iridescent ring. |
| 10 | aurora | `iri.aurora` | `0x9B86D6` | `0xC9B8F0` | none (classic body) | `glow.aurora` + `shimmer.dust` | round | a whole sky of mint-to-lilac aurora wrapped around the body. |
| 11 | dusklight | `iri.dusk` | `0xA083C9` | `0xD9C7F0` | `crest.feather` | `glow.lilac` + `shimmer.trail` | round | a lilac plume at dusk. One iridescent feather, gently curved. |
| 12 | seafoam | `iri.aurora` | `0x9B86D6` | `0xBFEBD6` | `crest.leaflet` | `glow.mint` + `shimmer.dust` | round | sea-glass green with a gilded sprout. Cozy coastal calm. |
| 13 | honeyfeather | `iri.honeygold` | `0xD99E2C` | `0xFFE2A0` | `crest.feather` | `glow.gold` + `shimmer.crown` | round | a golden iridescent plume. Soft, warm, a little proud. |
| 14 | haloglow | `iri.pearl` | `0xD8B79C` | `0xFFD98A` | none (classic body) | `glow.gold` (breathing) + `halo.ring` + `shimmer.dust` | round | the purest "angel" founder: a pearl body under a tilted gold ring. |
| 15 | starling no. 002 | `iri.moonstone` | `0x93A7CE` | `0xFFE6A8` | `crest.star` | `glow.moon` + `shimmer.crown` | round | the second to carry the founder's star, on cool moonstone. A numbered companion to "the very first". |
| 16 | warmwelcome | `iri.sunrise` | `0xE89370` | `0xFFCF8A` | `crest.dawnband` | `glow.peach` + `halo.dawn` + `shimmer.cheeks` | round | granted to a friend you brought in. Sunrise body, warm diadem, made to say "you belong here". |

Notes on the set:
- Four sub-families keep it coherent: **gold** (1, 2, 5, 13, 14), **sunrise/dawn**
  (3, 4, 16), **gem** (6, 7, 8, 9), and **aurora/dusk** (10, 11, 12, 15). Every
  body harmonises on the cream `#FBF6EC` canvas.
- **#1 "the very first"** and **#15 "starling no. 002"** are the only two with
  `crest.star`. Reserve #1 as the rarest single grant (the founder's own); it is
  the only one whose `glow.gold` breathes AND wears `halo.double`.
- **#16 "warmwelcome"** is the natural grant for the referred friend, so the
  landing-page promise "invite a friend, you both get a founding species" reads
  literally true. Pair it with any gold founder for the referrer.
- No duplicate names. All names are lowercase and warm, in house voice.

---

## Grant rules

Founding yolklings are **grant-only**. They are never sold, never earnable in the
normal game, and never appear in the store or any drop. They exist only as a
quiet honour for the people who showed up first.

A founding yolkling is granted when:
1. **A founder code is redeemed.** An early waitlist member redeems their founder
   code (the `redeem_code` flow in `REWARDS.md`). On a valid, unclaimed founder
   code, grant one founding species, mark the code claimed (one-time,
   server-validated).
2. **A referral completes.** When a referral code is redeemed by a new user,
   grant a founding species to **BOTH** parties: the new user (the referred
   friend, e.g. "warmwelcome") AND the referrer who invited them. This is what
   makes "invite a friend, you both get a founding species" literally true.

Enforcement:
- Grant-only is enforced server-side. The grant is recorded in `inventory` with
  `source` in (`waitlist`, `referral`, `gift`), never `purchase`. The store and
  any future drop logic must exclude all founding species ids.
- Each grant is **one-time** per code and per user, validated by the
  `redeem_code` Postgres function and the `redemptions` table.
- Founding species are **limited edition**: once the founder window closes, no
  new founder codes are issued, so the population is naturally capped. They are
  never reissued into the normal economy.
- These are meant to feel like a small, genuine honour, not a flex. Keep the
  presentation cozy and warm: a soft reveal, a gentle line of thanks, no fanfare.
</content>
</invoke>
