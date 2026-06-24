# Yolkling Room Decor

Design specs for 27 hand-made decor pieces for the yolk's room. Everything is drawn
in PURE SwiftUI vector shapes. NO images, NO emoji, NO SF Symbols.

## How to read these specs

The room is a `GeometryReader` of width `w`, height `h`. The WALL is the top ~66%,
the FLOOR is the bottom ~34% (floor begins at `y = h * 0.66`).

Each piece is a helper that draws into its OWN frame `(pw, ph)`. Inside the helper
all sizes/offsets are fractions of `pw`/`ph` (the piece frame), NOT of the room.
`RoomView` then places the piece with `.frame(width: w * sizeW, height: h * sizeH)`
and `.position(x: w * placeX, y: h * placeY)`.

So every piece below gives:
- PLACEMENT `(x, y)` as fractions of room `w`/`h` (the `.position`).
- SIZE `(w, h)` as fractions of room `w`/`h` (the `.frame`).
- SHAPES: each primitive, size as a fraction of the piece frame, offset within the
  frame (`+x` right, `+y` down, both as fractions of the piece frame), rotation, fill.

Offsets and sizes use the existing convention from `RoomView.swift`: a shape's
`.frame(width: pw * a, height: ph * b)` then `.offset(x: pw * dx, y: ph * dy)`,
inside a `ZStack` whose own `.frame(width: pw, height: ph)` centers everything.

### Reusable shapes already in the codebase

- `Trapezoid(topRatio:)` — flat-top trapezoid, `topRatio` = top width / bottom width. (`RoomView.swift`)
- `Triangle` — point-up triangle. (`CosmeticView.swift`, also redefine locally if needed)
- `StarShape(points:innerRatio:)` — n-point star. (`CreatureParts.swift`)
- `Color(hex:alpha:)` — hex color initializer. (`YolkColors.swift`)

### NEW reusable shapes introduced here

Add these alongside `Trapezoid` in the room file. Each is described concretely so it
can be dropped in.

```
// A rounded-bottom arch (window/door/lantern/cage tops). Flat sides, semicircle top.
struct ArchShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let radius = r.width / 2
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + radius), radius: radius,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// A symmetric crescent / bunting flag (point-down triangle with a rounded-ish look
// when small). Reuse Triangle rotated 180 for pennants, or this for soft flags.
struct PennantShape: Shape {           // point-down isosceles triangle
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// A single sagging swag line (for fairy-light wire and garland string). A shallow
// downward quadratic curve from left edge to right edge.
struct SwagLine: Shape {
    var sag: CGFloat = 0.6   // 0..1 fraction of frame height the midpoint dips
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.minY + r.height * sag))
        return p
    }
}

// A wavy/scalloped flame for candles and the fireplace (teardrop point-up).
struct FlameShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))                       // tip
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY + r.height * 0.1),
                       control: CGPoint(x: r.maxX, y: r.minY + r.height * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY),
                       control: CGPoint(x: r.maxX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.midY + r.height * 0.1),
                       control: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY),
                       control: CGPoint(x: r.minX, y: r.minY + r.height * 0.2))
        p.closeSubpath()
        return p
    }
}

// A heart, for cushions / mirror tops. Two top bumps, point at the bottom.
struct HeartShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.midX, y: r.minY + h * 0.28))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.28),
                   control1: CGPoint(x: r.midX - w * 0.18, y: r.minY - h * 0.1),
                   control2: CGPoint(x: r.minX, y: r.minY + h * 0.02))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.minX, y: r.minY + h * 0.55),
                   control2: CGPoint(x: r.midX - w * 0.1, y: r.minY + h * 0.7))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.28),
                   control1: CGPoint(x: r.midX + w * 0.1, y: r.minY + h * 0.7),
                   control2: CGPoint(x: r.maxX, y: r.minY + h * 0.55))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY + h * 0.28),
                   control1: CGPoint(x: r.maxX, y: r.minY + h * 0.02),
                   control2: CGPoint(x: r.midX + w * 0.18, y: r.minY - h * 0.1))
        p.closeSubpath()
        return p
    }
}

// A balloon (egg-ish circle with a tiny tie nub at the bottom).
struct BalloonShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height * 0.92))
        p.move(to: CGPoint(x: r.midX - r.width * 0.06, y: r.maxY - r.height * 0.06))
        p.addLine(to: CGPoint(x: r.midX + r.width * 0.06, y: r.maxY - r.height * 0.06))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
```

### Palette anchors

Warm woods `0x9A7B5A 0x8A6A4A 0xC97E54 0xD68E63 0xB5895E`. Cozy creams
`0xFBEEE2 0xFFF3DA 0xFCE3B8`. Plant greens `0x7FC98A 0x6FB07A 0x9CCB86 0x5A9E6E`.
Soft pinks `0xE89BB0 0xF2C3D2 0xE8A6C0`. Glows `0xFFE9A8 0xFFF1C8`. Cool sky
`0xBFE3F2 0xCFE9F5`. Lavender `0xCFC2E6 0xB9A9C9`.

---

# WALL DECOR

---

## 1. Sunny Poster

- kind: `posterSun`
- category: wall
- rarity: common
- cost: 90
- placement: `(0.50, 0.18)`
- size: `(0.16, 0.22)`

A simple unframed paper poster, rounded corners, a big happy sun over a soft stripe.

Shapes (frame `pw` x `ph`):
1. Paper: `RoundedRectangle(cornerRadius: pw * 0.08)`, size `1.0 x 1.0`, offset `(0, 0)`, fill `0xFFFDF6`.
2. Top band: `Rectangle`, size `0.86 x 0.42`, offset `(0, -ph * 0.22)`, fill `0xCFE9F5` (clip to paper via `.clipShape` or inset by `pw * 0.07`).
3. Sun body: `Circle`, size `0.34 x 0.34`, offset `(0, -ph * 0.16)`, fill `0xFFD25A`.
4. Sun rays: `StarShape(points: 12, innerRatio: 0.7)`, size `0.5 x 0.5`, offset `(0, -ph * 0.16)`, fill `0xFFD25A` opacity 0.5 (behind body).
5. Bottom hill: `Ellipse`, size `0.9 x 0.4`, offset `(0, ph * 0.3)`, fill `0x9CCB86`.
6. Frame edge: `RoundedRectangle(cornerRadius: pw * 0.08).strokeBorder`, lineWidth `pw * 0.03`, fill `0xE7D6BC`.

---

## 2. Trio of Framed Photos

- kind: `framedPhotos`
- category: wall
- rarity: common
- cost: 120
- placement: `(0.40, 0.20)`
- size: `(0.26, 0.20)`

Three little wooden frames in a stagger, each a tiny scene. Cute gallery wall.

Shapes (frame `pw` x `ph`), three frames F1/F2/F3:
1. F1 frame: `RoundedRectangle(cornerRadius: pw * 0.02)`, size `0.30 x 0.55`, offset `(-pw * 0.32, -ph * 0.08)`, fill `0x8A6A4A`.
   - F1 inner: `Rectangle`, size `0.22 x 0.42`, same offset, fill `0xF2C3D2`.
   - F1 dot (yolk portrait): `Circle`, size `0.1 x 0.1`, offset `(-pw * 0.32, -ph * 0.08)`, fill `0xFFD25A`.
2. F2 frame: `RoundedRectangle(cornerRadius: pw * 0.02)`, size `0.34 x 0.46`, offset `(0, ph * 0.06)`, fill `0xB5895E`.
   - F2 inner: `Rectangle`, size `0.26 x 0.34`, same offset, fill `0xCFE9F5`.
   - F2 hill: `Ellipse`, size `0.26 x 0.18`, offset `(0, ph * 0.14)`, fill `0x9CCB86`.
3. F3 frame: `RoundedRectangle(cornerRadius: pw * 0.02)`, size `0.28 x 0.5`, offset `(pw * 0.33, -ph * 0.04)`, fill `0x9A7B5A`.
   - F3 inner: `Rectangle`, size `0.2 x 0.38`, same offset, fill `0xFFF1C8`.
   - F3 heart: `HeartShape`, size `0.1 x 0.1`, offset `(pw * 0.33, -ph * 0.04)`, fill `0xE89BB0`.

---

## 3. Cozy Wall Clock

- kind: `wallClock`
- category: wall
- rarity: common
- cost: 100
- placement: `(0.50, 0.14)`
- size: `(0.10, 0.14)`

A round clock with a soft cream face and two stubby hands. Reads at a glance.

Shapes (frame `pw` x `ph`):
1. Outer ring: `Circle`, size `1.0 x 0.8` (use min side), offset `(0, 0)`, fill `0xC97E54`.
2. Bezel: `Circle`, size `0.84 x 0.84`, offset `(0, 0)`, fill `0xFFF3DA`.
3. Hour hand: `Capsule`, size `0.06 x 0.3`, offset `(0, -ph * 0.06)`, rotation `40deg`, fill `0x6B5644`.
4. Minute hand: `Capsule`, size `0.05 x 0.42`, offset `(0, -ph * 0.05)`, rotation `-20deg`, fill `0x6B5644`.
5. Center pin: `Circle`, size `0.1 x 0.1`, offset `(0, 0)`, fill `0xE89BB0`.
6. Four tick dots: `Circle` size `0.05 x 0.05` each at offsets `(0, -ph*0.32)`, `(0, ph*0.32)`, `(-pw*0.32, 0)`, `(pw*0.32, 0)`, fill `0xB5895E`.

---

## 4. Little Book Shelf (wall)

- kind: `wallShelf`
- category: wall
- rarity: rare
- cost: 260
- placement: `(0.30, 0.30)`
- size: `(0.22, 0.10)`

A floating wood plank with a few leaning books and a tiny pot. Warm and tidy.

Shapes (frame `pw` x `ph`):
1. Plank: `RoundedRectangle(cornerRadius: pw * 0.02)`, size `1.0 x 0.18`, offset `(0, ph * 0.34)`, fill `0x9A7B5A`.
2. Plank shadow lip: `Rectangle`, size `1.0 x 0.05`, offset `(0, ph * 0.46)`, fill `0x7A5E44`.
3. Book A: `RoundedRectangle(cornerRadius: pw * 0.01)`, size `0.07 x 0.46`, offset `(-pw * 0.34, -ph * 0.04)`, fill `0xE89BB0`.
4. Book B: `RoundedRectangle`, size `0.07 x 0.52`, offset `(-pw * 0.26, -ph * 0.08)`, fill `0x7FC98A`.
5. Book C (leaning): `RoundedRectangle`, size `0.07 x 0.44`, offset `(-pw * 0.18, -ph * 0.03)`, rotation `12deg`, fill `0xF2C36B`.
6. Pot: `Trapezoid(topRatio: 0.8)`, size `0.16 x 0.3`, offset `(pw * 0.28, ph * 0.02)`, fill `0xC97E54`.
7. Pot leaves: 3x `Ellipse`, size `0.06 x 0.22`, offset `(pw * 0.28, -ph * 0.2)`, rotations `-25 / 0 / 25 deg`, fill `0x6FB07A`.

---

## 5. Pennant Garland

- kind: `pennantGarland`
- category: wall
- rarity: common
- cost: 95
- placement: `(0.50, 0.10)`
- size: `(0.46, 0.10)`

A string of little triangle flags sagging across the wall. Party every day.

Shapes (frame `pw` x `ph`):
1. String: `SwagLine(sag: 0.5)` stroked, lineWidth `pw * 0.006`, frame `1.0 x 0.5`, offset `(0, -ph * 0.1)`, color `0x8A6A4A`.
2. Seven flags: `PennantShape`, each size `0.1 x 0.32`, fill cycling `[0xE89BB0, 0xF2C36B, 0x7FC98A, 0xCFE9F5, 0xE89BB0, 0xF2C36B, 0x7FC98A]`.
   - Position flags along the sag curve: x offsets `-pw*0.4, -pw*0.27, -pw*0.13, 0, pw*0.13, pw*0.27, pw*0.4`; y offsets follow the dip `-ph*0.06, ph*0.0, ph*0.06, ph*0.08, ph*0.06, ph*0.0, -ph*0.06`.
   - Tip of each flag points down (top edge hangs on the string).

---

## 6. Fairy Lights

- kind: `fairyLights`
- category: wall / light
- rarity: rare
- cost: 280
- placement: `(0.50, 0.12)`
- size: `(0.5, 0.12)`

A draped wire with warm glowing bulbs. Soft `.blur` halos make them feel lit.

Shapes (frame `pw` x `ph`):
1. Wire: `SwagLine(sag: 0.55)` stroked, lineWidth `pw * 0.005`, frame `1.0 x 0.5`, offset `(0, -ph * 0.12)`, color `0x6B5644`.
2. Glow halos: 9x `Circle`, size `0.09 x 0.09`, fill `0xFFE9A8` opacity 0.5, `.blur(radius: 6)`, spaced evenly along the wire's dip.
3. Bulbs: 9x `Circle`, size `0.04 x 0.04`, fill `0xFFF1C8`, hanging a touch below each halo (offset `+ph * 0.04`).
4. Bulb caps: 9x tiny `Rectangle`, size `0.012 x 0.02`, fill `0x9A7B5A`, just above each bulb on the wire.

Bulb x offsets: `-pw*0.44 ... pw*0.44` in 9 steps; y offsets trace the sag (deepest at center).

---

## 7. Heart Mirror

- kind: `heartMirror`
- category: wall
- rarity: rare
- cost: 300
- placement: `(0.78, 0.20)`
- size: `(0.13, 0.18)`

A heart-shaped mirror with a soft gold rim and a pale reflective sheen.

Shapes (frame `pw` x `ph`):
1. Rim: `HeartShape`, size `1.0 x 1.0`, offset `(0, 0)`, fill `0xF2C36B`.
2. Glass: `HeartShape`, size `0.82 x 0.82`, offset `(0, ph * 0.01)`, fill `0xD7E9EF`.
3. Sheen 1: `Capsule`, size `0.12 x 0.4`, offset `(-pw * 0.16, -ph * 0.04)`, rotation `30deg`, fill white opacity 0.6.
4. Sheen 2: `Capsule`, size `0.07 x 0.24`, offset `(-pw * 0.04, ph * 0.06)`, rotation `30deg`, fill white opacity 0.45.
5. Hook ribbon: small `Triangle`, size `0.1 x 0.08`, offset `(0, -ph * 0.5)`, fill `0xE89BB0`.

---

## 8. Tear-off Calendar

- kind: `wallCalendar`
- category: wall
- rarity: common
- cost: 85
- placement: `(0.62, 0.16)`
- size: `(0.09, 0.13)`

A little block calendar: red header, a number page, hanging tab. Tidy and clean.

Shapes (frame `pw` x `ph`):
1. Backboard: `RoundedRectangle(cornerRadius: pw * 0.1)`, size `1.0 x 1.0`, offset `(0, 0)`, fill `0xFFFDF6`.
2. Header: `RoundedRectangle(cornerRadius: pw * 0.1)`, size `1.0 x 0.34`, offset `(0, -ph * 0.33)`, fill `0xE89BB0` (top corners rounded; bottom flat via overlapping rect).
3. Header trim: `Rectangle`, size `1.0 x 0.04`, offset `(0, -ph * 0.16)`, fill `0xD27E97`.
4. Number bar: `RoundedRectangle(cornerRadius: pw * 0.06)`, size `0.5 x 0.34`, offset `(0, ph * 0.1)`, fill `0xF2C3D2`.
5. Page line 1: `Capsule`, size `0.62 x 0.04`, offset `(0, ph * 0.34)`, fill `0xE7D6BC`.
6. Hang dot: `Circle`, size `0.1 x 0.1`, offset `(0, -ph * 0.52)`, fill `0x9A7B5A`.

(No literal text/numbers; the pink bar reads as "the date" abstractly.)

---

## 9. Trailing Wall Vines

- kind: `wallVines`
- category: wall / plant
- rarity: rare
- cost: 250
- placement: `(0.92, 0.22)`
- size: `(0.12, 0.40)`

Long leafy vines trailing down a corner of the wall. Soft and organic.

Shapes (frame `pw` x `ph`):
1. Anchor pot: `Trapezoid(topRatio: 0.85)`, size `0.5 x 0.16`, offset `(0, -ph * 0.42)`, fill `0xC97E54`.
2. Stem A: a `Path` quadratic curve from `(pw*0.0, -ph*0.4)` dipping to `(-pw*0.2, ph*0.45)`, stroked lineWidth `pw * 0.04`, color `0x5A9E6E`.
3. Stem B: a `Path` curve from `(pw*0.1, -ph*0.4)` to `(pw*0.25, ph*0.45)`, stroked lineWidth `pw * 0.04`, color `0x6FB07A`.
4. Leaves: 10x `Ellipse`, size `0.18 x 0.1`, alternating along both stems, rotations alternating `-40 / 40 deg`, fill alternating `0x7FC98A / 0x6FB07A`.
   Distribute y offsets from `-ph*0.3` down to `ph*0.42`, x offsets hugging each stem.

---

# FLOOR / FURNITURE

---

## 10. Wooden Bookshelf

- kind: `bookshelf`
- category: furniture
- rarity: rare
- cost: 320
- placement: `(0.14, 0.55)`
- size: `(0.20, 0.46)`

A two-shelf wooden bookcase packed with colorful spines and a tiny plant on top.

Shapes (frame `pw` x `ph`):
1. Carcass: `RoundedRectangle(cornerRadius: pw * 0.04)`, size `1.0 x 0.92`, offset `(0, ph * 0.02)`, fill `0x9A7B5A`.
2. Back panel: `Rectangle`, size `0.86 x 0.8`, offset `(0, ph * 0.02)`, fill `0x7A5E44`.
3. Mid shelf board: `Rectangle`, size `0.86 x 0.04`, offset `(0, -ph * 0.02)`, fill `0xB5895E`.
4. Bottom shelf board: `Rectangle`, size `0.86 x 0.04`, offset `(0, ph * 0.38)`, fill `0xB5895E`.
5. Top row books: 6x `RoundedRectangle`, size `0.1 x 0.28`, offsets across `x = -pw*0.34 ... pw*0.34`, y `-ph*0.22`, one leaning `15deg`, fills cycling `[0xE89BB0, 0x7FC98A, 0xF2C36B, 0xCFE9F5, 0xE8A6C0, 0x6FB07A]`.
6. Bottom row books: 5x `RoundedRectangle`, size `0.12 x 0.28`, y `ph * 0.2`, fills cycling `[0xF2C36B, 0xE89BB0, 0x9CCB86, 0xCFE9F5, 0xF2C3D2]`.
7. Top plant pot: `Trapezoid(topRatio: 0.8)`, size `0.16 x 0.12`, offset `(pw * 0.3, -ph * 0.5)`, fill `0xC97E54`; 3 leaf `Ellipse` `0.05 x 0.18` above it, fill `0x6FB07A`.
8. Feet: 2x small `RoundedRectangle`, size `0.08 x 0.06`, offsets `(-pw*0.38, ph*0.48)`, `(pw*0.38, ph*0.48)`, fill `0x7A5E44`.

---

## 11. Snug Little Bed

- kind: `cozyBed`
- category: furniture
- rarity: rare
- cost: 300
- placement: `(0.30, 0.80)`
- size: `(0.30, 0.22)`

A tiny bed with a plush duvet, a striped pillow and a wooden headboard. Naptime.

Shapes (frame `pw` x `ph`):
1. Headboard: `RoundedRectangle(cornerRadius: pw * 0.06)`, size `0.16 x 0.9`, offset `(-pw * 0.42, -ph * 0.05)`, fill `0x9A7B5A`.
2. Base frame: `RoundedRectangle(cornerRadius: pw * 0.04)`, size `0.92 x 0.5`, offset `(pw * 0.02, ph * 0.22)`, fill `0xB5895E`.
3. Mattress/duvet: `RoundedRectangle(cornerRadius: pw * 0.08)`, size `0.84 x 0.46`, offset `(pw * 0.04, ph * 0.05)`, fill `0xCFE9F5`.
4. Duvet fold: `Capsule`, size `0.6 x 0.1`, offset `(pw * 0.12, -ph * 0.08)`, fill `0xBFE3F2`.
5. Pillow: `RoundedRectangle(cornerRadius: pw * 0.1)`, size `0.26 x 0.24`, offset `(-pw * 0.28, -ph * 0.06)`, rotation `-6deg`, fill `0xFFF3DA`.
6. Pillow stripe: `Capsule`, size `0.2 x 0.03`, offset `(-pw * 0.28, -ph * 0.06)`, rotation `-6deg`, fill `0xE89BB0`.
7. Feet: 2x `RoundedRectangle`, size `0.05 x 0.12`, offsets `(-pw*0.3, ph*0.44)`, `(pw*0.36, ph*0.44)`, fill `0x7A5E44`.

---

## 12. Squishy Beanbag

- kind: `beanbag`
- category: furniture
- rarity: common
- cost: 130
- placement: `(0.82, 0.82)`
- size: `(0.20, 0.18)`

A round slouchy beanbag with a top dimple and seam lines. Begs to be sat on.

Shapes (frame `pw` x `ph`):
1. Body: `Ellipse`, size `1.0 x 0.86`, offset `(0, ph * 0.06)`, fill `0xE8A6C0`.
2. Top cushion: `Ellipse`, size `0.7 x 0.4`, offset `(0, -ph * 0.24)`, fill `0xF2C3D2`.
3. Dimple shadow: `Ellipse`, size `0.34 x 0.16`, offset `(0, -ph * 0.2)`, fill `0xD98AAE` opacity 0.6.
4. Seam left: `Capsule`, size `0.03 x 0.5`, offset `(-pw * 0.22, ph * 0.1)`, rotation `-18deg`, fill `0xD27E97` opacity 0.5.
5. Seam right: `Capsule`, size `0.03 x 0.5`, offset `(pw * 0.22, ph * 0.1)`, rotation `18deg`, fill `0xD27E97` opacity 0.5.
6. Ground shadow: `Ellipse`, size `0.9 x 0.12`, offset `(0, ph * 0.46)`, fill `0x000000` opacity 0.08.

---

## 13. Round Floor Cushion

- kind: `floorCushion`
- category: furniture
- rarity: common
- cost: 80
- placement: `(0.66, 0.86)`
- size: `(0.14, 0.07)`

A flat round seat cushion with a button center and a piped edge. Simple, cute.

Shapes (frame `pw` x `ph`):
1. Cushion: `Ellipse`, size `1.0 x 0.9`, offset `(0, 0)`, fill `0xF2C36B`.
2. Piping: `Ellipse.strokeBorder`, lineWidth `pw * 0.03`, size `1.0 x 0.9`, fill `0xD9A53F`.
3. Top sheen: `Ellipse`, size `0.7 x 0.4`, offset `(0, -ph * 0.12)`, fill `0xFFE0A0`.
4. Button: `Circle`, size `0.12 x 0.12`, offset `(0, -ph * 0.04)`, fill `0xD9A53F`.
5. Four pleat lines: `Capsule`, size `0.02 x 0.34`, offsets at `0 / 45 / 90 / 135 deg` rotations radiating from button, fill `0xD9A53F` opacity 0.4.

---

## 14. Tiny Table with Teacup

- kind: `teaTable`
- category: furniture
- rarity: rare
- cost: 270
- placement: `(0.70, 0.78)`
- size: `(0.18, 0.20)`

A little round side table with a steaming teacup on top. Cozy ritual.

Shapes (frame `pw` x `ph`):
1. Tabletop: `Ellipse`, size `0.9 x 0.16`, offset `(0, -ph * 0.1)`, fill `0xC97E54`.
2. Top edge: `Ellipse`, size `0.9 x 0.16`, offset `(0, -ph * 0.06)`, fill `0xB5895E` (a sliver behind the top for thickness).
3. Leg: `Capsule`, size `0.1 x 0.6`, offset `(0, ph * 0.2)`, fill `0x9A7B5A`.
4. Foot: `Ellipse`, size `0.4 x 0.08`, offset `(0, ph * 0.46)`, fill `0x8A6A4A`.
5. Saucer: `Ellipse`, size `0.34 x 0.06`, offset `(0, -ph * 0.16)`, fill `0xFFFDF6`.
6. Cup: `Trapezoid(topRatio: 1.2)` (slightly flaring), size `0.2 x 0.12`, offset `(0, -ph * 0.22)`, fill `0xF2C3D2`.
7. Handle: `Circle.strokeBorder` lineWidth `pw * 0.02`, size `0.08 x 0.08`, offset `(pw * 0.12, -ph * 0.22)`, fill `0xE89BB0`.
8. Steam: 2x thin wavy `Path` (small S-curves), stroked lineWidth `pw * 0.012`, offset above cup, color white opacity 0.6.

---

## 15. Stubby Stool

- kind: `woodStool`
- category: furniture
- rarity: common
- cost: 90
- placement: `(0.58, 0.82)`
- size: `(0.12, 0.14)`

A three-leg wooden stool, round top, splayed legs. Honest little seat.

Shapes (frame `pw` x `ph`):
1. Seat: `Ellipse`, size `0.9 x 0.3`, offset `(0, -ph * 0.18)`, fill `0xC97E54`.
2. Seat edge: `Ellipse`, size `0.9 x 0.3`, offset `(0, -ph * 0.12)`, fill `0xA9683F`.
3. Leg L: `Capsule`, size `0.08 x 0.6`, offset `(-pw * 0.26, ph * 0.18)`, rotation `12deg`, fill `0x9A7B5A`.
4. Leg R: `Capsule`, size `0.08 x 0.6`, offset `(pw * 0.26, ph * 0.18)`, rotation `-12deg`, fill `0x9A7B5A`.
5. Leg mid (back): `Capsule`, size `0.08 x 0.58`, offset `(0, ph * 0.2)`, fill `0x8A6A4A`.

---

## 16. Toy Chest

- kind: `toyChest`
- category: furniture
- rarity: common
- cost: 140
- placement: `(0.20, 0.84)`
- size: `(0.18, 0.14)`

A rounded wooden chest with a domed lid, a heart latch and a couple toys peeking out.

Shapes (frame `pw` x `ph`):
1. Box: `RoundedRectangle(cornerRadius: pw * 0.06)`, size `1.0 x 0.6`, offset `(0, ph * 0.2)`, fill `0xC97E54`.
2. Lid (dome): `Capsule`, size `1.02 x 0.4`, offset `(0, -ph * 0.18)`, fill `0xD68E63` (clip bottom half by overlaying box top).
3. Lid band: `Rectangle`, size `1.0 x 0.05`, offset `(0, 0)`, fill `0xA9683F`.
4. Vertical straps: 2x `Rectangle`, size `0.04 x 0.7`, offsets `(-pw*0.28, ph*0.05)`, `(pw*0.28, ph*0.05)`, fill `0xA9683F`.
5. Latch: `HeartShape`, size `0.12 x 0.12`, offset `(0, ph * 0.04)`, fill `0xF2C36B`.
6. Peeking ball: `Circle`, size `0.16 x 0.16`, offset `(pw * 0.22, -ph * 0.34)`, fill `0xE89BB0`.
7. Peeking star: `StarShape(points: 5)`, size `0.14 x 0.14`, offset `(-pw * 0.2, -ph * 0.36)`, fill `0xF2C36B`.

---

## 17. Yolk Tower

- kind: `yolkTower`
- category: furniture / fun
- rarity: epic
- cost: 480
- placement: `(0.86, 0.66)`
- size: `(0.18, 0.46)`

A stacked carpet tower (cat-tree style) sized for a round yolk, with a cozy top cup
and a hanging pom-pom. Premium climbing furniture.

Shapes (frame `pw` x `ph`):
1. Base: `Ellipse`, size `0.9 x 0.12`, offset `(0, ph * 0.46)`, fill `0xB5895E`.
2. Post: `RoundedRectangle(cornerRadius: pw * 0.2)`, size `0.22 x 0.86`, offset `(0, 0)`, fill `0xD6C3A6`.
3. Post rope wrap: 5x `Capsule`, size `0.24 x 0.04`, evenly spaced down the post, fill `0xC2A87E` opacity 0.7 (gives a sisal look).
4. Mid platform: `Ellipse`, size `0.7 x 0.12`, offset `(0, -ph * 0.02)`, fill `0xF2C3D2`.
5. Top cup outer: `Ellipse`, size `0.9 x 0.3`, offset `(0, -ph * 0.4)`, fill `0xE8A6C0`.
6. Top cup hollow: `Ellipse`, size `0.62 x 0.18`, offset `(0, -ph * 0.43)`, fill `0xD98AAE`.
7. Pom-pom: `Circle`, size `0.14 x 0.14`, offset `(pw * 0.3, -ph * 0.18)`, fill `0xF2C36B`.
8. Pom string: `Capsule`, size `0.015 x 0.16`, offset `(pw * 0.3, -ph * 0.27)`, fill `0x9A7B5A`.

---

## 18. Ball Pit

- kind: `ballPit`
- category: fun / furniture
- rarity: rare
- cost: 330
- placement: `(0.78, 0.86)`
- size: `(0.26, 0.14)`

A shallow round pit brimming with pastel balls. Pure joy on the floor.

Shapes (frame `pw` x `ph`):
1. Pit shadow: `Ellipse`, size `1.0 x 0.7`, offset `(0, ph * 0.18)`, fill `0xB5895E`.
2. Pit wall: `Ellipse`, size `1.0 x 0.6`, offset `(0, ph * 0.1)`, fill `0xCFE9F5`.
3. Pit inner rim: `Ellipse.strokeBorder` lineWidth `pw * 0.02`, size `1.0 x 0.6`, offset `(0, ph * 0.1)`, fill `0xBFE3F2`.
4. Balls back row: 6x `Circle`, size `0.13 x 0.13`, across `x = -pw*0.36 ... pw*0.36`, y `-ph*0.04`, fills cycling `[0xE89BB0, 0xF2C36B, 0x7FC98A, 0xCFE9F5, 0xE8A6C0, 0xFFD25A]`.
5. Balls front row: 5x `Circle`, size `0.15 x 0.15`, staggered, y `ph*0.1`, fills cycling `[0x7FC98A, 0xE89BB0, 0xFFD25A, 0xCFE9F5, 0xF2C36B]`.
6. Ball sheens: tiny white `Circle` `0.03 x 0.03` opacity 0.6 on the top-left of 4 of the balls.

---

## 19. Record Player

- kind: `recordPlayer`
- category: furniture / fun
- rarity: epic
- cost: 460
- placement: `(0.24, 0.80)`
- size: `(0.18, 0.16)`

A little turntable on a wood box, spinning vinyl, with two music-note dots drifting up.

Shapes (frame `pw` x `ph`):
1. Box: `RoundedRectangle(cornerRadius: pw * 0.05)`, size `1.0 x 0.6`, offset `(0, ph * 0.16)`, fill `0x8A6A4A`.
2. Top plate: `RoundedRectangle(cornerRadius: pw * 0.05)`, size `1.0 x 0.16`, offset `(0, -ph * 0.16)`, fill `0xB5895E`.
3. Vinyl: `Circle`, size `0.56 x 0.56`, offset `(-pw * 0.08, -ph * 0.04)`, fill `0x2E2A28`.
4. Label: `Circle`, size `0.2 x 0.2`, offset `(-pw * 0.08, -ph * 0.04)`, fill `0xE89BB0`.
5. Spindle: `Circle`, size `0.04 x 0.04`, offset `(-pw * 0.08, -ph * 0.04)`, fill `0xFFF3DA`.
6. Tonearm: `Capsule`, size `0.04 x 0.4`, offset `(pw * 0.22, -ph * 0.08)`, rotation `-30deg`, fill `0xD6C3A6`.
7. Notes: 2x small `Circle` `0.06 x 0.06` with a `Capsule` `0.015 x 0.1` stem (note shape), offsets `(pw*0.34, -ph*0.4)`, `(pw*0.42, -ph*0.26)`, fill `0x6B5644`.

---

# PLANTS

---

## 20. Round Cactus

- kind: `cactus`
- category: plant
- rarity: common
- cost: 110
- placement: `(0.40, 0.70)`
- size: `(0.10, 0.20)`

A chubby barrel cactus with one arm, a little flower hat, sitting in a terracotta pot.

Shapes (frame `pw` x `ph`):
1. Pot: `Trapezoid(topRatio: 0.8)`, size `0.7 x 0.3`, offset `(0, ph * 0.34)`, fill `0xC97E54`.
2. Pot rim: `Ellipse`, size `0.78 x 0.1`, offset `(0, ph * 0.2)`, fill `0xD68E63`.
3. Body: `Capsule`, size `0.5 x 0.7`, offset `(0, -ph * 0.06)`, fill `0x6FB07A`.
4. Arm: `Capsule`, size `0.18 x 0.32`, offset `(pw * 0.26, -ph * 0.06)`, rotation `30deg`, fill `0x6FB07A`.
5. Ribs: 3x `Capsule`, size `0.02 x 0.5`, offsets `(-pw*0.12, -ph*0.06)`, `(0, -ph*0.06)`, `(pw*0.12, -ph*0.06)`, fill `0x5A9E6E` opacity 0.5.
6. Flower: `StarShape(points: 6, innerRatio: 0.45)`, size `0.22 x 0.22`, offset `(0, -ph * 0.34)`, fill `0xE89BB0`.
7. Flower center: `Circle`, size `0.07 x 0.07`, offset `(0, -ph * 0.34)`, fill `0xF2C36B`.

---

## 21. Hanging Plant

- kind: `hangingPlant`
- category: plant
- rarity: rare
- cost: 250
- placement: `(0.16, 0.28)`
- size: `(0.12, 0.30)`

A macrame hanging planter with trailing leaves, suspended from the ceiling.

Shapes (frame `pw` x `ph`):
1. Hanger lines: 3x `Capsule`, size `0.012 x 0.5`, offsets `(-pw*0.18, -ph*0.26)`, `(0, -ph*0.28)`, `(pw*0.18, -ph*0.26)`, slight rotations `8 / 0 / -8 deg`, fill `0xD6C3A6`.
2. Top knot: `Circle`, size `0.08 x 0.08`, offset `(0, -ph * 0.48)`, fill `0xC2A87E`.
3. Pot: `Ellipse` (bowl) , size `0.5 x 0.3`, offset `(0, ph * 0.02)`, fill `0xCFC2E6`.
4. Pot bottom: `Trapezoid(topRatio: 1.0)` no, use `Ellipse` half — keep it simple: `Ellipse`, size `0.5 x 0.18`, offset `(0, ph * 0.1)`, fill `0xB9A9C9`.
5. Foliage mound: `Ellipse`, size `0.6 x 0.3`, offset `(0, -ph * 0.1)`, fill `0x6FB07A`.
6. Trailing vines: 4x `Path` quadratic curves drooping from the pot down to `ph*0.45`, stroked lineWidth `pw * 0.03`, color `0x7FC98A`; with 6 small `Ellipse` leaves `0.12 x 0.06` along them.

---

## 22. Flower Vase

- kind: `flowerVase`
- category: plant
- rarity: common
- cost: 120
- placement: `(0.50, 0.74)`
- size: `(0.10, 0.18)`

A slim glass vase with three simple blooms. Fresh and sweet.

Shapes (frame `pw` x `ph`):
1. Vase: `Trapezoid(topRatio: 0.55)` flipped (narrow top) — actually use a `Capsule` pinched: `RoundedRectangle(cornerRadius: pw * 0.2)`, size `0.4 x 0.4`, offset `(0, ph * 0.28)`, fill `0xCFE9F5` opacity 0.85.
2. Vase neck: `RoundedRectangle`, size `0.24 x 0.16`, offset `(0, ph * 0.06)`, fill `0xCFE9F5` opacity 0.85.
3. Water line: `Capsule`, size `0.34 x 0.02`, offset `(0, ph * 0.22)`, fill `0xBFE3F2`.
4. Stems: 3x `Capsule`, size `0.015 x 0.5`, offsets `(-pw*0.12, -ph*0.1)`, `(0, -ph*0.16)`, `(pw*0.12, -ph*0.1)`, rotations `-10 / 0 / 10 deg`, fill `0x6FB07A`.
5. Blooms: 3x `StarShape(points: 5, innerRatio: 0.5)`, size `0.26 x 0.26`, atop each stem, fills `0xE89BB0`, `0xF2C36B`, `0xE8A6C0`.
6. Bloom centers: 3x `Circle`, size `0.08 x 0.08`, fill `0xFFF3DA`.

---

## 23. Tall Monstera

- kind: `monstera`
- category: plant
- rarity: rare
- cost: 290
- placement: `(0.88, 0.60)`
- size: `(0.20, 0.42)`

A statement tall monstera with big split leaves in a woven basket. Reads at room scale.

Shapes (frame `pw` x `ph`):
1. Basket: `Trapezoid(topRatio: 1.2)` (flaring up), size `0.5 x 0.22`, offset `(0, ph * 0.4)`, fill `0xC2A87E`.
2. Basket weave lines: 3x `Capsule`, size `0.5 x 0.02`, stacked in the basket, fill `0xA88A5E` opacity 0.6.
3. Stems: 3x `Capsule`, size `0.025 x 0.6`, offsets fanning from basket, rotations `-14 / 0 / 14 deg`, fill `0x5A9E6E`.
4. Leaves: 5x large `Ellipse`, size `0.34 x 0.5`, fanned at rotations `-45 / -22 / 0 / 22 / 45 deg`, offset up `-ph * 0.18`, fills alternating `0x6FB07A / 0x5A9E6E`.
5. Leaf splits: on each leaf, 2x small `Capsule` `0.02 x 0.16` in the base color of the wall behind... simpler: overlay 2x `Triangle` notches `0.08 x 0.12` fill `0x5A9E6E` opacity 0 — instead cut visual splits with 2 thin `Capsule` `0.015 x 0.18` fill `0x4F8C62` per leaf radiating from leaf center (suggests the monstera fenestration).

---

## 24. Toadstool Mushroom

- kind: `mushroom`
- category: plant / fun
- rarity: common
- cost: 100
- placement: `(0.36, 0.74)`
- size: `(0.10, 0.14)`

A plump red-cap toadstool with white spots. Storybook cute.

Shapes (frame `pw` x `ph`):
1. Stem: `Capsule`, size `0.36 x 0.5`, offset `(0, ph * 0.22)`, fill `0xFFF3DA`.
2. Cap: `Ellipse`, size `1.0 x 0.6`, offset `(0, -ph * 0.16)`, fill `0xE07A6E`.
3. Cap underside: `Ellipse`, size `0.86 x 0.16`, offset `(0, ph * 0.0)`, fill `0xF6D2C9`.
4. Spots: 4x `Circle`, sizes `0.18 / 0.12 / 0.1 / 0.08`, scattered on cap, fill `0xFFFDF6`.
5. Ground tuft: `Ellipse`, size `0.5 x 0.08`, offset `(0, ph * 0.46)`, fill `0x7FC98A` opacity 0.7.

---

# LIGHT / AMBIENT

---

## 25. Table Lamp

- kind: `tableLamp`
- category: light
- rarity: common
- cost: 130
- placement: `(0.84, 0.70)`
- size: `(0.12, 0.18)`

A little table lamp with a trapezoid shade, warm blurred glow, on a turned base.

Shapes (frame `pw` x `ph`):
1. Glow: `Circle`, size `1.3 x 1.3` (min side), offset `(0, -ph * 0.18)`, fill `0xFFE9A8` opacity 0.4, `.blur(radius: 12)`.
2. Base: `Ellipse`, size `0.46 x 0.1`, offset `(0, ph * 0.42)`, fill `0x9A7B5A`.
3. Neck: `Capsule`, size `0.08 x 0.36`, offset `(0, ph * 0.18)`, fill `0xB5895E`.
4. Shade: `Trapezoid(topRatio: 0.55)`, size `0.66 x 0.36`, offset `(0, -ph * 0.18)`, fill `LinearGradient([0xFFF1C8, 0xF6D98A], top→bottom)`.
5. Shade rim: `Capsule`, size `0.66 x 0.04`, offset `(0, 0)`, fill `0xE8C672`.

---

## 26. Paper Lantern

- kind: `paperLantern`
- category: light / fun
- rarity: rare
- cost: 260
- placement: `(0.66, 0.16)`
- size: `(0.11, 0.18)`

A round glowing paper lantern hanging on a cord, with ribbed bands and a tassel.

Shapes (frame `pw` x `ph`):
1. Cord: `Capsule`, size `0.012 x 0.3`, offset `(0, -ph * 0.36)`, fill `0x9A7B5A`.
2. Glow: `Circle`, size `1.1 x 1.1`, offset `(0, ph * 0.02)`, fill `0xFFD9A0` opacity 0.4, `.blur(radius: 10)`.
3. Body: `Circle`, size `0.84 x 0.84` (slightly squashed: `Ellipse` `0.84 x 0.78`), offset `(0, 0)`, fill `0xFFC98E`.
4. Top cap: `Trapezoid(topRatio: 0.5)`, size `0.3 x 0.1`, offset `(0, -ph * 0.32)`, fill `0xE07A6E`.
5. Bottom cap: `Trapezoid(topRatio: 2.0)` (flares down) — use `Ellipse` `0.3 x 0.08`, offset `(0, ph * 0.32)`, fill `0xE07A6E`.
6. Ribs: 3x `Capsule`, size `0.78 x 0.02`, offsets `(0, -ph*0.14)`, `(0, 0)`, `(0, ph*0.14)`, fill `0xE89B5E` opacity 0.5.
7. Tassel: `Capsule`, size `0.04 x 0.16`, offset `(0, ph * 0.44)`, fill `0xE07A6E`.

---

## 27. Candle

- kind: `candle`
- category: light
- rarity: common
- cost: 80
- placement: `(0.62, 0.74)`
- size: `(0.07, 0.13)`

A short pillar candle with a soft teardrop flame and a warm glow. Quiet and warm.

Shapes (frame `pw` x `ph`):
1. Saucer: `Ellipse`, size `0.9 x 0.14`, offset `(0, ph * 0.4)`, fill `0xD6C3A6`.
2. Wax: `RoundedRectangle(cornerRadius: pw * 0.15)`, size `0.5 x 0.6`, offset `(0, ph * 0.12)`, fill `0xFFF3DA`.
3. Wax top: `Ellipse`, size `0.5 x 0.12`, offset `(0, -ph * 0.16)`, fill `0xFCEFCD`.
4. Drip: `Capsule`, size `0.06 x 0.2`, offset `(-pw * 0.12, ph * 0.12)`, fill `0xFCEFCD`.
5. Glow: `Circle`, size `0.7 x 0.7`, offset `(0, -ph * 0.3)`, fill `0xFFE9A8` opacity 0.5, `.blur(radius: 8)`.
6. Flame: `FlameShape`, size `0.16 x 0.3`, offset `(0, -ph * 0.32)`, fill `LinearGradient([0xFFF1C8, 0xFFB347], top→bottom)`.
7. Wick: `Capsule`, size `0.02 x 0.06`, offset `(0, -ph * 0.18)`, fill `0x6B5644`.

---

## 28. Little Fireplace

- kind: `fireplace`
- category: light / ambient
- rarity: epic
- cost: 520
- placement: `(0.50, 0.50)`
- size: `(0.26, 0.34)`

A brick fireplace with a wooden mantel, dancing flames over logs, and a warm glow.
Statement wall-to-floor piece.

Shapes (frame `pw` x `ph`):
1. Surround: `RoundedRectangle(cornerRadius: pw * 0.04)`, size `1.0 x 0.92`, offset `(0, ph * 0.04)`, fill `0xC98A6E`.
2. Brick lines: 4x horizontal `Rectangle` `0.9 x 0.01` + offset vertical seams, fill `0xB07050` opacity 0.4 (suggest brickwork).
3. Firebox: `RoundedRectangle(cornerRadius: pw * 0.06)`, size `0.66 x 0.6`, offset `(0, ph * 0.1)`, fill `0x3A2E2A`.
4. Mantel: `RoundedRectangle(cornerRadius: pw * 0.03)`, size `1.1 x 0.12`, offset `(0, -ph * 0.4)`, fill `0x9A7B5A`.
5. Glow: `Ellipse`, size `0.7 x 0.5`, offset `(0, ph * 0.14)`, fill `0xFFB347` opacity 0.5, `.blur(radius: 14)`.
6. Logs: 2x `Capsule`, size `0.34 x 0.07`, offsets `(-pw*0.05, ph*0.28)` rot `-10deg`, `(pw*0.06, ph*0.3)` rot `8deg`, fill `0x7A5E44`.
7. Flames: 3x `FlameShape`, sizes `0.16 x 0.26 / 0.2 x 0.34 / 0.14 x 0.22`, offsets `(-pw*0.1, ph*0.06)`, `(0, ph*0.0)`, `(pw*0.1, ph*0.08)`, fills `0xFFB347 / 0xFFD25A / 0xFF8A4A`.
8. Mantel decor: tiny `Circle` `0.06 x 0.06` (clock) at `(-pw*0.3, -ph*0.48)` fill `0xFFF3DA`, and a 3-leaf `Ellipse` sprig at `(pw*0.32, -ph*0.5)` fill `0x6FB07A`.

---

## 29. Night-light Stars

- kind: `nightStars`
- category: light / ambient
- rarity: rare
- cost: 250
- placement: `(0.82, 0.40)`
- size: `(0.24, 0.24)`

A cluster of soft glowing stars projected on the wall, plus a crescent moon. Dreamy.

Shapes (frame `pw` x `ph`):
1. Big star glow: `StarShape(points: 5)`, size `0.5 x 0.5`, offset `(-pw * 0.1, -ph * 0.1)`, fill `0xFFE9A8` opacity 0.5, `.blur(radius: 6)`.
2. Big star: `StarShape(points: 5)`, size `0.36 x 0.36`, offset `(-pw * 0.1, -ph * 0.1)`, fill `0xFFF1C8`.
3. Mid star: `StarShape(points: 5)`, size `0.24 x 0.24`, offset `(pw * 0.3, -ph * 0.26)`, fill `0xFFE9A8`.
4. Small stars: 3x `StarShape(points: 4, innerRatio: 0.4)`, size `0.12 x 0.12`, scattered `(pw*0.34, ph*0.12)`, `(-pw*0.34, ph*0.2)`, `(pw*0.04, ph*0.3)`, fill `0xFFF3DA`.
5. Crescent moon: `Circle` `0.3 x 0.3` fill `0xFFE9A8` at `(pw * 0.18, ph * 0.0)`, masked by an overlapping wall-colored `Circle` `0.28 x 0.28` offset `(pw * 0.26, -ph * 0.04)` to carve the crescent.
6. Sparkle dots: 4x `Circle`, size `0.03 x 0.03`, fill white opacity 0.7, scattered between stars.

---

# FUN

---

## 30. Balloon Bunch

- kind: `balloonBunch`
- category: fun
- rarity: common
- cost: 110
- placement: `(0.18, 0.22)`
- size: `(0.16, 0.30)`

Three pastel balloons on curling strings, bobbing in the corner. Always a party.

Shapes (frame `pw` x `ph`):
1. Strings: 3x `Path` gentle S-curves from each balloon down to a gathered point at `(0, ph*0.42)`, stroked lineWidth `pw * 0.01`, color `0x9A7B5A`.
2. Balloon A: `BalloonShape`, size `0.4 x 0.5`, offset `(-pw * 0.22, -ph * 0.2)`, fill `0xE89BB0`.
3. Balloon B: `BalloonShape`, size `0.46 x 0.56`, offset `(pw * 0.05, -ph * 0.3)`, fill `0xF2C36B`.
4. Balloon C: `BalloonShape`, size `0.4 x 0.5`, offset `(pw * 0.26, -ph * 0.16)`, fill `0x9CC9E8`.
5. Sheens: 3x `Ellipse`, size `0.1 x 0.16`, top-left of each balloon, rotation `-20deg`, fill white opacity 0.5.
6. Knot: small `Triangle` `0.06 x 0.05` under each balloon, point up, fill matching balloon (slightly darker).

---

## 31. Cozy Tent

- kind: `playTent`
- category: fun / furniture
- rarity: epic
- cost: 500
- placement: `(0.30, 0.72)`
- size: `(0.32, 0.36)`

A little A-frame play tent with a triangular door flap and a pennant on top. A hideaway
for the yolk.

Shapes (frame `pw` x `ph`):
1. Ground shadow: `Ellipse`, size `0.95 x 0.1`, offset `(0, ph * 0.46)`, fill `0x000000` opacity 0.08.
2. Tent body: `Triangle`, size `1.0 x 0.92`, offset `(0, ph * 0.04)`, fill `0xE8A6C0`.
3. Tent shade side: `Triangle` half (a `Path` of left triangle), size `0.5 x 0.92`, offset `(-pw * 0.25, ph * 0.04)`, fill `0xD98AAE` opacity 0.5 (gives 3D fold).
4. Stripe: `Triangle.strokeBorder`-like band — 2x thin `Capsule` `0.7 x 0.03` following the slopes, fill `0xFFF3DA` opacity 0.7. (Or skip for simplicity.)
5. Door flap L: a `Path` triangle (a peeled-open flap), size `0.18 x 0.6`, offset `(-pw * 0.12, ph * 0.1)`, rotation `-12deg`, fill `0xD98AAE`.
6. Door opening: `Triangle`, size `0.3 x 0.6`, offset `(0, ph * 0.14)`, fill `0x4A3B44` (dark cozy interior).
7. Pole tip + pennant: `Capsule` `0.012 x 0.1` at top `(0, -ph * 0.5)` fill `0x9A7B5A`; `PennantShape` rotated to point right, size `0.12 x 0.1`, offset `(pw * 0.06, -ph * 0.5)`, fill `0xF2C36B`.

---

## 32. Fish Tank

- kind: `fishTank`
- category: fun
- rarity: rare
- cost: 340
- placement: `(0.74, 0.72)`
- size: `(0.20, 0.20)`

A rounded glass aquarium with two little fish, bubbles, gravel and a plant. Lively.

Shapes (frame `pw` x `ph`):
1. Stand: `RoundedRectangle(cornerRadius: pw * 0.04)`, size `0.92 x 0.16`, offset `(0, ph * 0.42)`, fill `0x9A7B5A`.
2. Tank glass: `RoundedRectangle(cornerRadius: pw * 0.1)`, size `1.0 x 0.74`, offset `(0, -ph * 0.04)`, fill `0xBFE3F2` opacity 0.7.
3. Water sheen: `Capsule`, size `0.14 x 0.4`, offset `(-pw * 0.3, -ph * 0.06)`, rotation `12deg`, fill white opacity 0.4.
4. Gravel: `RoundedRectangle(cornerRadius: pw * 0.05)`, size `0.9 x 0.12`, offset `(0, ph * 0.24)`, fill `0xD6C3A6`.
5. Plant: 3x `Ellipse` `0.06 x 0.3`, offset `(pw * 0.3, ph * 0.06)`, rotations `-15 / 0 / 15 deg`, fill `0x6FB07A`.
6. Fish A: `Ellipse` body `0.2 x 0.13` + `Triangle` tail `0.1 x 0.13`, offset `(-pw * 0.12, -ph * 0.06)`, fill `0xF2A24A`; tiny black eye `Circle` `0.025`.
7. Fish B: `Ellipse` body `0.14 x 0.1` + tail, offset `(pw * 0.08, ph * 0.06)`, fill `0xE89BB0`.
8. Bubbles: 4x `Circle`, size `0.04 / 0.03 / 0.025 / 0.02`, rising in a column at `(pw * 0.18, ...)`, fill white opacity 0.6.
9. Rim/frame: `RoundedRectangle(cornerRadius: pw * 0.1).strokeBorder`, lineWidth `pw * 0.03`, size `1.0 x 0.74`, offset `(0, -ph * 0.04)`, fill `0xCFE9F5`.

---

## 33. Bird Cage

- kind: `birdCage`
- category: fun / ambient
- rarity: rare
- cost: 290
- placement: `(0.20, 0.30)`
- size: `(0.12, 0.30)`

A dainty hanging birdcage with a tiny round bird on a swing. Vintage cute.

Shapes (frame `pw` x `ph`):
1. Hook: `Path` small arc (a hook), stroked lineWidth `pw * 0.03`, size `0.2 x 0.16`, offset `(0, -ph * 0.46)`, color `0x9A7B5A`.
2. Cage dome: `ArchShape`, size `0.7 x 0.4`, offset `(0, -ph * 0.18)`, fill `0xE8C672` opacity 0.0 with `.strokeBorder` — i.e. draw `ArchShape().stroke(lineWidth: pw*0.02)` fill `0xC2A87E`.
3. Cage body: `Rectangle.strokeBorder` look — `RoundedRectangle(cornerRadius: pw * 0.06).stroke(lineWidth: pw * 0.02)`, size `0.7 x 0.5`, offset `(0, ph * 0.1)`, color `0xC2A87E`.
4. Vertical bars: 4x `Capsule`, size `0.012 x 0.5`, offsets `-pw*0.21, -pw*0.07, pw*0.07, pw*0.21`, y `ph * 0.1`, fill `0xC2A87E`.
5. Base ring: `Ellipse.strokeBorder` lineWidth `pw * 0.03`, size `0.7 x 0.1`, offset `(0, ph * 0.36)`, fill `0xB5895E`.
6. Swing: `Capsule`, size `0.012 x 0.2`, offset `(0, -ph * 0.02)`, fill `0xC2A87E`; perch `Capsule` `0.2 x 0.02` at bottom of swing.
7. Bird: `Circle` body `0.2 x 0.2`, offset `(0, ph * 0.06)`, fill `0x9CC9E8`; `Triangle` beak `0.05 x 0.05` fill `0xF2A24A`; eye `Circle` `0.025` fill `0x2E2A28`; `Triangle` tail `0.08 x 0.06` fill `0x7FB4DB`.

---

## 34. Hammock

- kind: `hammock`
- category: fun / furniture
- rarity: epic
- cost: 470
- placement: `(0.5, 0.80)`
- size: `(0.36, 0.18)`

A slung fabric hammock between two posts, with a throw pillow and a fringe. Lazy days.

Shapes (frame `pw` x `ph`):
1. Post L: `Capsule`, size `0.05 x 0.9`, offset `(-pw * 0.46, -ph * 0.02)`, rotation `-8deg`, fill `0x9A7B5A`.
2. Post R: `Capsule`, size `0.05 x 0.9`, offset `(pw * 0.46, -ph * 0.02)`, rotation `8deg`, fill `0x9A7B5A`.
3. Post feet: 2x `Ellipse` `0.12 x 0.05` at base of each post, fill `0x8A6A4A`.
4. Hammock sling: a closed `Path` — top edge a shallow `SwagLine(sag: 0.7)` left→right at `y = -ph*0.05`, bottom edge a deeper sag at `y = ph*0.15`, sides joined; fill `0xE89BB0`. (Reads as a hanging cradle.)
5. Sling stripe: `SwagLine(sag: 0.7)` stroked lineWidth `pw * 0.01`, mid-height, color `0xF2C3D2`.
6. End ropes: 2x fan of 3 thin `Capsule` `0.008 x 0.16` gathering from each post top to the sling ends, fill `0xD6C3A6`.
7. Pillow: `RoundedRectangle(cornerRadius: pw * 0.06)`, size `0.18 x 0.12`, offset `(-pw * 0.2, -ph * 0.04)`, rotation `-10deg`, fill `0xFFF3DA`.
8. Fringe: 5x tiny `Capsule` `0.01 x 0.06` hanging from the lowest point of the sling, fill `0xF2C3D2`.

---

# Placement guidance summary

To avoid overlap when several pieces are equipped, recommended room zones:

- WALL UPPER (`y` 0.08–0.22): poster, framed photos, clock, calendar, garland,
  fairy lights, paper lantern, balloon bunch, bird cage, hanging plant.
- WALL MID (`y` 0.22–0.36): wall shelf, mirror, vines, night stars, fireplace (tall).
- FLOOR LEFT (`x` 0.12–0.36): bookshelf, bed, toy chest, record player, tent, mushroom, cactus.
- FLOOR CENTER (`x` 0.40–0.70): floor cushion, stool, candle, flower vase, tea table, hammock.
- FLOOR RIGHT (`x` 0.70–0.92): beanbag, ball pit, fish tank, table lamp, yolk tower, monstera.

Rarity mix across the 34 pieces: 15 common, 14 rare, 5 epic. Epics (fireplace, yolk
tower, record player, tent, hammock) are the larger statement builds with glows,
gradients or multi-zone footprints to justify the 460 to 520 cost band.
