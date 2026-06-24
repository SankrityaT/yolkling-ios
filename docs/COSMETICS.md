# Cosmetics + community designs (the "Bitmoji" system)

Goal: a **wide range** of worn cosmetics (hats, glasses, neckwear, held items, patterns)
AND an **open-source pipeline** so anyone can submit their own designs.

## The creature is code, so cosmetics must be DATA, not code
The yolkling is drawn in pure SwiftUI shapes — no art assets, no per-item native code.
For a community to contribute, a cosmetic has to be a **declarative document the app
renders**, not Swift someone has to compile into the app.

## Chosen format: SVG + a small JSON manifest
- **SVG** is the contribution format. Universal — designers already use Figma / Illustrator /
  Inkscape; it's vector (crisp at any size), recolorable, and small. We render it in SwiftUI by
  converting SVG paths to `CGPath` → SwiftUI `Path` via an open-source lib (**SwiftDraw** or
  **PocketSVG**). No proprietary format to learn.
- **manifest.json** per item describes how it attaches:
  ```json
  {
    "id": "party-hat",
    "name": "Party Hat",
    "slot": "hat",            // hat | eyes | neck | cheeks | held | pattern
    "anchor": { "x": 0.0, "y": -0.48 },   // relative to creature size, 0,0 = body centre
    "scale": 0.5,
    "z": "front",
    "recolor": ["#FF6FA3"],   // fill ids the wearer can recolor
    "rarity": "common",
    "cost": 120,              // coins; 0 = free
    "author": "@handle",
    "license": "CC-BY-4.0"
  }
  ```
- **Animated tier (later):** Lottie (JSON from After Effects / LottieFiles) for moving items
  (a sparkling crown, a wagging tail), rendered via lottie-ios. Same manifest, `format: "lottie"`.

## The open-source pipeline
1. Public repo `yolkling/cosmetics`. Each item = a folder with `item.svg` + `manifest.json`.
2. Contributor opens a **PR**. CI validates the manifest against a schema and renders a preview
   image on the creature for review.
3. On merge, items are published to the backend (**Supabase Storage / CDN**) and appear in the
   in-app shop, crediting the author in-app ("designed by @handle").
4. Licensing: permissive (CC-BY or a contributor agreement); creators keep credit. Optional
   revenue-share or featured-creator program later.
5. **Lowering the barrier to zero (later):** a web "creator studio" (Bitmoji-style) that outputs
   the same `svg + manifest`, so non-designers can make items with no tools.

## In-app model (built now, format-agnostic)
- `CosmeticSlot` — the layer it occupies (hat, eyes, neck, …). Bitmoji-style stacking.
- `Cosmetic` — a pure `Codable`/`Sendable` value: `id, name, slot, rarity, cost, kind`.
  - `kind` today = a built-in code renderer (so we ship a starter set without the SVG dep yet).
  - `kind` later gains `.svg(url)` / `.lottie(url)` — the renderer switches on it, so the
    community pipeline slots in without touching equip/inventory/shop logic.
- The renderer draws the equipped cosmetics on the creature at each slot's anchor + z-order.
- Equip state lives in a `WardrobeStore`; ownership/coins come from the economy (see REWARDS.md).

## Why not ship SVG right now
The starter catalog is rendered in code (no dependency) so the feature is live today. We add the
SwiftDraw/PocketSVG dependency when we open the community repo — at which point built-in items can
also migrate to SVG for consistency. The `Cosmetic`/`CosmeticSlot`/`WardrobeStore` model is already
shaped for it.
