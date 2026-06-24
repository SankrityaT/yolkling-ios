# Garden family

The garden family of yolkling species: flowers, sprouts, mushrooms, clover, leaves, berries, vines, and gentle little bugs (ladybugs, bees, snails, butterflies). Soft greens, petal pinks, mushroom cream, berry mauve, honey, and sky bluebell. Everything here is drawable with the existing primitive kit (Circle, Ellipse, Capsule, RoundedRectangle, small Path arcs, simple gradients), matching the conventions in `Yolkling/Core/Creature/YolklingView.swift`.

Conventions used below (same as the live renderer):
- All sizes and offsets are multiples of `size`. Hex is written `#RRGGBB` here, implemented as `Color(hex: 0xRRGGBB)`.
- `y` grows DOWNWARD. Top features sit roughly between `y = -size*0.40` and `y = -size*0.60`.
- "body colour" = `vibe.body`, "deep colour" = `vibe.deep`, "accent" = the species accent hex.
- `side` is `-1` (left) or `+1` (right) just like the existing `arm` / `foot` / `ear` helpers.
- Top features draw BEHIND the head (added before `bodyCircle` in the ZStack), so stems and petals tuck behind the body, same as the current `ears` / `sprout` / `tuft`.
- Patterns draw ON the body and are clipped to the body Circle (`.clipShape(Circle())` over the body frame), so nothing spills past the silhouette.

---

## New top features

Each is a small cluster of shapes centered above the head. Keep the count low. All rotations are in degrees. Where a feature uses the species accent, it is noted as "accent"; otherwise a literal hex is given so the feature reads correctly even on an accent-less species.

### tulipBud
A single closed tulip bud on a short stem.
- STEM: Capsule, `size*0.035` wide x `size*0.17` tall, fill `#77C47E`, offset `y -size*0.50`.
- BUD BACK PETAL: Ellipse, `size*0.16` wide x `size*0.20` tall, fill accent (fallback `#F2A0B6`), offset `y -size*0.58`.
- BUD FRONT PETAL: Ellipse, `size*0.10` wide x `size*0.18` tall, fill a lighter accent (mix accent toward white ~30%, fallback `#F8C2D2`), offset `y -size*0.585`.
- Two LEAF: Ellipse `size*0.11` wide x `size*0.06` tall, fill `#86D38C`; left rotation `30`, offset `x -size*0.05, y -size*0.47`; right rotation `-28`, offset `x size*0.06, y -size*0.48`.

### daisyCrown
A five petal daisy sitting flat on the crown.
- FIVE PETALS: each an Ellipse `size*0.09` wide x `size*0.15` tall, fill `#FFFFFF` (stroke optional `#EAD7C2` width `size*0.006`), arranged around center `(0, -size*0.50)` at rotations `0, 72, 144, 216, 288`, each pushed out `size*0.085` from center along its rotation. (Implement as 5 copies, each `.rotationEffect(.degrees(i*72))` then `.offset(y: -size*0.585)`; the rotation orbits the petal around the crown center.)
- CENTER: Circle `size*0.10`, fill `#F7C94B` (honey), offset `y -size*0.50`.

### singlePetalFlower
A simpler four petal bloom, good for commons.
- FOUR PETALS: Ellipse `size*0.10` wide x `size*0.13` tall, fill accent (fallback `#F2A0B6`), at rotations `45, 135, 225, 315` orbiting center `(0, -size*0.50)` pushed out `size*0.07`.
- CENTER: Circle `size*0.09`, fill `#FBF1E2` (cream), offset `y -size*0.50`.

### mushroomCap
A domed mushroom cap with spots, like a tiny hat.
- CAP: Ellipse `size*0.40` wide x `size*0.24` tall, fill `#E58B7B` (or accent), offset `y -size*0.46`. To get the dome, clip the bottom: overlay a Rectangle `#FBF6EC` over the lower half OR simply use a half-capsule via a small Path arc; an Ellipse alone reads fine at this size.
- CAP UNDERSIDE RIM: Capsule `size*0.34` wide x `size*0.05` tall, fill `#FBF1E2` (cream gills), offset `y -size*0.37`.
- THREE SPOTS: Circle `size*0.06`, fill `#FBF1E2`; offsets `x -size*0.09 y -size*0.49`, `x size*0.07 y -size*0.46`, `x -size*0.01 y -size*0.42`.

### cloverTop
A three leaf clover (or four for luck variants).
- THREE LEAVES: each a heart-ish leaf made of two Circles. Per leaf use ONE Circle `size*0.11`, fill `#7FC98A`, with a small notch implied by overlapping; arrange three around center `(0, -size*0.50)` at rotations `0, 120, 240` pushed out `size*0.07`.
- STEM: Capsule `size*0.03` wide x `size*0.10` tall, fill `#5FA86B`, offset `y -size*0.42`.
- (FOUR-LEAF luck variant: four Circles at `0, 90, 180, 270`, used by epic/legendary clover species.)

### antennae
Two gentle bug antennae with rounded tips, for the bug species.
- Two STALKS: Capsule `size*0.02` wide x `size*0.14` tall, fill deep colour; left rotation `-18` offset `x -size*0.10, y -size*0.50`; right rotation `18` offset `x size*0.10, y -size*0.50`.
- Two TIP BALLS: Circle `size*0.06`, fill accent (fallback deep colour); left offset `x -size*0.15, y -size*0.57`; right offset `x size*0.15, y -size*0.57`.

### beeAntennae
Like `antennae` but tips are honey gold, paired with the bee stripe pattern.
- Two STALKS: Capsule `size*0.02` wide x `size*0.13` tall, fill `#5A4632`; left rotation `-16` offset `x -size*0.09, y -size*0.50`; right rotation `16` offset `x size*0.09, y -size*0.50`.
- Two TIP BALLS: Circle `size*0.055`, fill `#F7C94B`; left offset `x -size*0.14, y -size*0.56`; right offset `x size*0.14, y -size*0.56`.

### berryCluster
A little bunch of berries with a leaf, for the berry species.
- THREE BERRIES: Circle `size*0.10`, fill accent (fallback `#9C6B8E` mauve); offsets `x -size*0.08 y -size*0.50`, `x size*0.08 y -size*0.50`, `x 0 y -size*0.43`. Add a tiny highlight Circle `size*0.025` fill `#FFFFFF` opacity `0.5` at the top-left of each berry.
- LEAF: Ellipse `size*0.12` wide x `size*0.06` tall, fill `#7FC98A`, rotation `-30`, offset `x size*0.10, y -size*0.57`.

### leafPair
Two upright leaves meeting at a center vein, simple and sweet.
- Two LEAVES: Ellipse `size*0.10` wide x `size*0.22` tall, fill `#86D38C` (left) and `#77C47E` (right, slightly deeper); left rotation `-18` offset `x -size*0.05, y -size*0.52`; right rotation `18` offset `x size*0.05, y -size*0.52`.
- CENTER VEIN: a thin Capsule `size*0.012` wide x `size*0.12` tall, fill `#5FA86B`, offset `y -size*0.50`.

### bellFlower
A single nodding bluebell, hanging from a slim stem.
- STEM: Capsule `size*0.025` wide x `size*0.15` tall, fill `#6FB07A`, offset `x size*0.02, y -size*0.50`.
- BELL: a Path bell, approximated as an Ellipse `size*0.15` wide x `size*0.18` tall, fill accent (fallback `#9DB7E8` bluebell), rotation `12`, offset `x size*0.04, y -size*0.58`.
- BELL MOUTH: three tiny scallop Circles `size*0.04`, fill a lighter accent (`#B9CCF0`), along the bottom edge of the bell at offsets `x -size*0.01/size*0.04/size*0.08, y -size*0.51`.

### sproutTrio
A denser version of the base `sprout`: a stem with three little leaves, for grassy species.
- STEM: Capsule `size*0.035` wide x `size*0.18` tall, fill `#77C47E`, offset `y -size*0.52`.
- LEAF LEFT: Ellipse `size*0.12` wide x `size*0.07` tall, fill `#86D38C`, rotation `34`, offset `x -size*0.06, y -size*0.55`.
- LEAF RIGHT: Ellipse `size*0.11` wide x `size*0.07` tall, fill `#86D38C`, rotation `-30`, offset `x size*0.06, y -size*0.57`.
- LEAF TOP: Ellipse `size*0.08` wide x `size*0.06` tall, fill `#9BE0A0`, offset `y -size*0.61`.

### acornCap
A small acorn perched on top, autumn-garden flavor.
- NUT: Ellipse `size*0.18` wide x `size*0.20` tall, fill `#C99A6B` (or accent), offset `y -size*0.46`.
- CAP: Ellipse `size*0.20` wide x `size*0.11` tall, fill `#8A6240`, offset `y -size*0.53` (sits over the top of the nut).
- STALK: Capsule `size*0.02` wide x `size*0.06` tall, fill `#6E4D2F`, offset `y -size*0.58`.

---

## New patterns

Overlays drawn on the body, clipped to the body Circle. Use shades derived from the body or a low-opacity accent so they always read on cream `#FBF6EC` and never fight the face. Keep marks in the lower two thirds of the body so they sit below the eyes (eyes are near `y -size*0.08`). Body center is `(0,0)`; body radius is `size*0.5`.

### ladybugSpots
Scattered round dots, the classic ladybug look.
- SIX SPOTS: Circle `size*0.08`, fill deep colour at opacity `0.85` (or `#2E2A2A` for true black-spot ladybugs). Offsets: `x -size*0.20 y size*0.06`, `x size*0.18 y size*0.10`, `x -size*0.10 y size*0.22`, `x size*0.12 y size*0.26`, `x -size*0.24 y size*0.20`, `x size*0.25 y size*0.20`. Clip to body.
- Optional CENTER LINE: a thin Capsule `size*0.02` wide x `size*0.5` tall, fill same as spots opacity `0.6`, offset `y size*0.10` (the wing seam). Only for the true ladybug species.

### beeStripe
Two horizontal bands across the lower belly.
- TWO STRIPES: each a Capsule `size*0.9` wide x `size*0.13` tall, fill `#5A4632` at opacity `0.85` (or deep colour). Offsets `y size*0.10` and `y size*0.30`. Clip to body Circle so the ends curve with the silhouette.
- Pair with honey-gold bodies for the bee read.

### freckleDots
Soft sparse freckles, gentle and cute.
- SEVEN DOTS: Circle `size*0.035`, fill deep colour at opacity `0.45`. Offsets clustered low and to the sides, avoiding the cheeks (`x ±size*0.31, y size*0.06`): `x -size*0.22 y size*0.18`, `x size*0.22 y size*0.18`, `x -size*0.14 y size*0.28`, `x size*0.14 y size*0.28`, `x 0 y size*0.30`, `x -size*0.27 y size*0.10`, `x size*0.27 y size*0.10`. Clip to body.

### leafBelly
A single soft leaf-shaped belly patch, lighter than the body.
- PATCH: Ellipse `size*0.42` wide x `size*0.50` tall, fill body colour lightened ~18% toward white (fallback `#FBF6EC` at opacity `0.5`), offset `y size*0.16`. Clip to body.
- MIDRIB: a thin Capsule `size*0.015` wide x `size*0.34` tall, fill deep colour opacity `0.35`, offset `y size*0.16`.
- Optional THREE VEIN dashes: Capsule `size*0.10` wide x `size*0.012` tall, fill deep opacity `0.25`, rotated `25`, down the right of the midrib at `y size*0.02/size*0.14/size*0.26`.

### petalSpeckle
A light shower of tiny petal flecks, like fallen blossom.
- EIGHT PETALS: Ellipse `size*0.05` wide x `size*0.075` tall, fill accent at opacity `0.55` (fallback `#F2A0B6`). Random-feeling but fixed offsets across the lower body, each at a small rotation (`0/20/-15/35/-30/10/-25/15`): `x -size*0.22 y size*0.04`, `x size*0.20 y size*0.08`, `x -size*0.08 y size*0.20`, `x size*0.10 y size*0.24`, `x -size*0.24 y size*0.22`, `x size*0.25 y size*0.18`, `x 0 y size*0.30`, `x size*0.14 y size*0.32`. Clip to body.

### vineTrail
A thin curving stem with two small leaves climbing up one side of the belly.
- VINE: a small Path quad curve, stroked `#6FB07A` width `size*0.02`, from `(size*0.18, size*0.32)` curving to `(size*0.06, -size*0.02)` with control `(size*0.26, size*0.14)`. Clip to body.
- Two LEAVES: Ellipse `size*0.10` wide x `size*0.055` tall, fill `#86D38C`; rotation `35` offset `x size*0.20 y size*0.18`; rotation `-20` offset `x size*0.08 y size*0.02`.

### snailSwirl
A spiral marking on the side, gentle nod to a snail shell.
- SWIRL: a single stroked Path spiral (2 turns), stroke deep colour opacity `0.7`, width `size*0.022`, bounding box `size*0.26` square, offset `x size*0.14, y size*0.16`. If a true Archimedean spiral Path is too fussy, approximate with three concentric arcs: stroked open Circles of diameters `size*0.24, size*0.16, size*0.08`, each a `270` degree arc rotated progressively, same center. Clip to body.

---

## Accessories

Small worn extras, drawn in front of the body (in the outfit layer). Tasteful, code-only, no SF Symbols needed.

### dewDrop
A single dewdrop highlight resting on the cheek or brow, fresh-morning feel.
- DROP: a Path teardrop, or simply a Circle `size*0.06` fill `#CDEBF7` opacity `0.85` with a smaller white Circle `size*0.02` highlight at its top-left. Offset `x size*0.22, y -size*0.06`. One drop only.

### honeyDab
A tiny honey dollop on top of the head, pairs with bee species.
- DAB: Ellipse `size*0.12` wide x `size*0.07` tall, fill `#F7C94B`, offset `y -size*0.40`.
- DRIP: a small Capsule `size*0.03` wide x `size*0.06` tall, same fill, offset `x size*0.04, y -size*0.35`.

### snailShell
A worn shell on the back, turning any species into a cozy snail.
- SHELL: stroked spiral as in `snailSwirl` but filled: an Ellipse `size*0.26` wide x `size*0.24` tall, fill accent (fallback `#D8A86B`), offset `x size*0.34, y size*0.04` (peeking from behind the side). Overlay a 2-turn stroked spiral, stroke `#A87B45` width `size*0.02`, same center.
- Note: draw BEHIND the body edge so it reads as carried on the back; place in a back z-slot.

### petalHat
A little upturned petal worn as a sun hat.
- BRIM: Ellipse `size*0.40` wide x `size*0.10` tall, fill accent (fallback `#F8C2D2`), offset `y -size*0.34`.
- CROWN: Ellipse `size*0.20` wide x `size*0.14` tall, fill a deeper accent (`#F2A0B6`), offset `y -size*0.42`.
- BAND: a thin Capsule `size*0.20` wide x `size*0.03` tall, fill `#86D38C` (a leaf band), offset `y -size*0.37`.

---

## Species

One row per species. Columns: name | body | deep | accent | top feature | pattern | eye style | rarity | personality.

Eye style is `round` (default) unless a species earns a different mood-neutral eye. Top features reference the base set (`classic`, `ears`, `sprout`, `tuft`) and the new garden features above. Patterns reference the new patterns or `none`.

| name | body | deep | accent | top feature | pattern | eye | rarity | personality |
|------|------|------|--------|-------------|---------|-----|--------|-------------|
| sprig | #B6D98C | #84B85E | #FFFFFF | sprout | none | round | common | the first to wake, always pointing at the sun. |
| budling | #C7E8A0 | #8FC267 | #F2A0B6 | tulipBud | none | round | common | keeps a bloom tucked away for someone special. |
| pip | #D7EBB0 | #9AC773 | - | leafPair | freckleDots | round | common | small, springy, and easily delighted by rain. |
| clovi | #9FD6A0 | #6FB07A | #FFFFFF | cloverTop | none | round | common | thinks every walk might be the lucky one. |
| daisette | #EAF3D6 | #BED894 | #F7C94B | daisyCrown | none | round | common | hums a little, loses petals when she counts. |
| mossbun | #A9C98A | #7B9E61 | - | ears | leafBelly | round | common | naps on stones, wears soft green everywhere. |
| fernlet | #93C98F | #5FA86B | #FFFFFF | sproutTrio | none | round | common | unrolls slowly in the morning, very patient. |
| petunia | #F7BCD0 | #E08AAE | #FFFFFF | singlePetalFlower | petalSpeckle | round | common | dramatic about weather, sweetest at dusk. |
| poppet | #F4A9B8 | #DD7E94 | #F7C94B | daisyCrown | freckleDots | round | common | giggles in the breeze, easily tickled. |
| dewberry | #C9A8D6 | #9C6B8E | #B388C4 | berryCluster | freckleDots | round | common | hoards morning dew like little treasures. |
| bramble | #B68FA8 | #8A5E78 | #C9A8D6 | berryCluster | vineTrail | round | rare | tangly and stubborn, hides the sweetest fruit. |
| capling | #FBF1E2 | #E5C9A8 | #E58B7B | mushroomCap | none | round | common | pops up after rain, very proud of its hat. |
| toadcap | #F2D9B8 | #CBA579 | #C9544A | mushroomCap | ladybugSpots | round | rare | a touch shy, smells faintly of damp earth. |
| beelle | #F7C94B | #D89A2E | #5A4632 | beeAntennae | beeStripe | round | rare | busy busy busy, leaves a trail of pollen. |
| honeydrop | #FBD876 | #E0A93E | #F2A0B6 | classic | beeStripe | round | rare | sticky-sweet, gives the warmest little hugs. |
| ladypip | #E8736E | #C24A45 | #2E2A2A | antennae | ladybugSpots | round | rare | counts her spots when nervous, always lands safe. |
| spotwing | #EF8A86 | #CC5C57 | #2E2A2A | antennae | ladybugSpots | round | common | clumsy flier, lands on noses on purpose. |
| flutterby | #C6A8E8 | #9670D0 | #F2A0B6 | antennae | petalSpeckle | sparkle | rare | drifts wherever the wind is prettiest. |
| snaily | #D8C2A8 | #A88B6B | #D8A86B | leafPair | snailSwirl | sleepy | common | takes the long way, arrives exactly on time. |
| escargo | #C9B6E0 | #9C84C2 | #A87B45 | leafPair | snailSwirl | sleepy | rare | carries his whole cozy house on his back. |
| bluebell | #9DB7E8 | #6F8FD0 | #B9CCF0 | bellFlower | none | round | rare | rings softly when happy, shy around loud days. |
| violetta | #B39BE8 | #8466D6 | #C7B4F0 | bellFlower | petalSpeckle | round | rare | reads the garden gossip, keeps the gentle secrets. |
| primrose | #F9C9A8 | #E5A275 | #F2A0B6 | singlePetalFlower | freckleDots | round | common | first to bloom, last to give up on a grey day. |
| marigold | #FBB85E | #E08A2E | #C9544A | daisyCrown | none | round | common | loud, golden, and impossible to be sad near. |
| sunnip | #FFD98A | #E8B04E | #FFFFFF | sproutTrio | leafBelly | round | common | turns to face you like you are the sun. |
| sorrel | #A8C98A | #7B9E5E | #C9544A | leafPair | none | round | common | a little tart, secretly very soft inside. |
| thymelet | #BCD9A0 | #8AB06B | #F2A0B6 | sproutTrio | freckleDots | round | common | tiny and fragrant, hums when watered. |
| basilica | #8FC98A | #5FA86B | #FFFFFF | leafPair | leafBelly | round | rare | regal about being a herb, smells incredible. |
| acornel | #D9B98C | #A8855E | #8A6240 | acornCap | none | round | common | tucks things away for later and forgets where. |
| chestlet | #E0C2A0 | #B0916B | #C99A6B | acornCap | freckleDots | round | common | round and warm, falls asleep mid-sentence. |
| ivory | #EDE6D2 | #C9BCA0 | #9FD6A0 | leafPair | vineTrail | round | rare | pale and climbing, reaches for every window. |
| ivylace | #CFE0BC | #9CB884 | #6FB07A | sproutTrio | vineTrail | round | rare | delicate and persistent, wraps around your heart. |
| roselet | #F4A0B0 | #DC7187 | #FFFFFF | singlePetalFlower | none | round | rare | thorny only when teased, blushes the rest of the time. |
| peony | #F7B8C9 | #E085A0 | #F7C94B | daisyCrown | petalSpeckle | round | rare | extravagant, opens slow, worth the wait. |
| lilura | #E8C2D9 | #C28AB0 | #C7B4F0 | bellFlower | freckleDots | round | rare | quiet and lovely, faints in the heat (dramatic). |
| crocus | #C2A8E0 | #9270C2 | #F7C94B | tulipBud | none | round | common | pokes up through the last frost, very brave. |
| tulipa | #F2A0B6 | #D8728E | #FFFFFF | tulipBud | petalSpeckle | round | common | stands up straight, proud of its single perfect cup. |
| lavendel | #BCAEE0 | #8E7CC2 | #FFFFFF | sproutTrio | petalSpeckle | sleepy | rare | calming presence, makes the whole room drowsy-happy. |
| minty | #A8E0C2 | #6FB894 | #FFFFFF | leafPair | freckleDots | round | common | cool and breezy, fixes bad moods on contact. |
| willowisp | #C2D9B0 | #8FAE78 | #CDEBF7 | tuft | none | round | rare | sways even with no wind, daydreams a lot. |
| dandi | #FBE08A | #E8C04E | #FFFFFF | daisyCrown | freckleDots | round | common | makes a wish, scatters, comes back next week. |
| pollenpuff | #FBD876 | #E0B04E | #F7C94B | classic | beeStripe | sparkle | rare | sneezes glitter, beloved by every bee in the yard. |
| nectarine | #F9B888 | #E08A56 | #F2A0B6 | berryCluster | none | round | rare | juicy-sweet optimist, shares everything. |
| mulber | #A87BA0 | #7B5274 | #C9A8D6 | berryCluster | petalSpeckle | round | rare | stains your fingers and your heart, no regrets. |
| gourdie | #F2A85E | #D87E2E | #7FC98A | acornCap | leafBelly | round | rare | rolls around contentedly, biggest in autumn. |
| sproutling | #C7E8A0 | #8FC267 | #FFFFFF | sprout | leafBelly | round | common | just a baby leaf, impossibly hopeful. |
| trefoil | #8FC98A | #5FA86B | #FFFFFF | cloverTop | freckleDots | round | rare | three for hope, faith, and love, carries all three. |
| fourleaf | #7FC98A | #4F9866 | #F7C94B | cloverTop | none | happyArc | epic | so lucky it is almost suspicious. radiates calm. |
| queenbee | #F7C94B | #D89A2E | #5A4632 | beeAntennae | beeStripe | sparkle | epic | the whole garden hums when she arrives. |
| firefleur | #F4A9B8 | #DD7E94 | #FBE08A | daisyCrown | petalSpeckle | sparkle | epic | glows at dusk, the garden's gentle nightlight. |
| moonpetal | #DCD2F0 | #A894D6 | #CDEBF7 | bellFlower | petalSpeckle | sparkle | epic | only fully blooms by moonlight, keeps soft secrets. |
| heartvine | #F2A0B6 | #D8728E | #7FC98A | berryCluster | vineTrail | heart | epic | grows toward whoever loves it most. unstoppably fond. |
| auragold | #FBE08A | #E0B84E | #FFFFFF | daisyCrown | leafBelly | sparkle | legendary | the very first bloom of the very first spring. warms everything near it. |
| evergreen | #6FB07A | #3F7E54 | #F7C94B | sproutTrio | leafBelly | happyArc | legendary | older than the garden, patient as a forest. has seen every season and loves them all. |
| willowqueen | #BCAEE0 | #8E7CC2 | #CDEBF7 | bellFlower | snailSwirl | sparkle | legendary | the quiet sovereign of the dusk garden, makes time slow down and worries small. |
