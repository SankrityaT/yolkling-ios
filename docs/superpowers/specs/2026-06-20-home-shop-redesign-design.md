# Home + Shop Redesign

Date: 2026-06-20
Status: Approved design, ready for implementation plan

## Problem

Two concrete UX failures on the home surface:

1. **Room editing is invisible.** The room is the most important customization
   surface, but the only ways into it are an unlabeled `house` nav icon and an
   unlabeled tap on the room area. The tutorial never mentions it. Worse, owned
   decor auto-places at fixed coordinates with no way to move, swap, or remove a
   piece, so even players who find it do not feel like they are designing.

2. **There is no single shop.** Customization is fragmented across three
   surfaces with three inconsistent layouts and buy/equip flows:
   - `ShopView` (rare colours + cosmetics), reached from the `tshirt` nav icon.
   - `RoomScreen` (themes + decor), reached from the `house` nav icon.
   - `WardrobeView` (cosmetics only) — an orphan with no entry point, missing the
     colours section, with a different card size and a buy-without-preview flow.
   Colours (which recolor the body) sit next to clip-on cosmetics with no visual
   distinction. 82 cosmetics + 21 colours + 34 decor + 16 themes are presented in
   horizontal scroll rows with no search, filter, sort, or owned/unowned toggle.

The tutorial is also inaccurate: it claims "time off your phone" feeds the yolk
(Screen Time is stubbed/gated, not live) and says the yolk will "grow" (it does
not change size; the day feeds trust + mood + Yolks).

## Goals

- Make decorating obvious and make it feel like designing (move / swap / remove).
- Collapse three shop surfaces into one consistent store with real navigation
  (search, filter, sort, owned toggle, curated front).
- Tell the truth in the tutorial, and teach the room.
- Keep all changes SwiftData migration-safe (optional/defaulted fields only).

## Non-goals (YAGNI for v1)

- **Free drag-and-drop** room editing. Rejected in favor of snap-to-zones: no new
  per-player position model, no collision/zoom handling, no off-screen risk.
- **Saved "Looks" presets** (one-tap swap of a whole outfit + room combo). Additive;
  better as a later paid-tier hook.
- **Bundles** (themed theme + decor + outfit sets). Additive; later monetization hook.
- No change to wallet/ownership semantics, the care loop, trust, or HealthKit.

---

## 1. Information architecture

Mental model: **Home is where you live; Shop is where you get things.**

- **Bottom nav, labeled** (icons are mute today): `Home` · `Shop` · `Dex` ·
  `Friends` · `You`. Each gets a text label under the icon.
- **Decorate is not a nav slot.** It is a visible affordance on the room itself,
  because decorating is the home activity.
- **`WardrobeView` is deleted.** Equipping what you own becomes the `Owned` filter
  inside Shop. (`showWardrobe` state, the orphan view, and its dead entry point
  are removed.)
- The `house` nav slot becomes `Home` (the current screen). The old room sheet
  becomes **Decorate mode** (below). Themes + decor move into the Shop's Room aisle
  for browsing/buying; in-room placement happens in Decorate mode.

### Nav slot mapping (old -> new)

| Old (icon)                  | Old destination        | New                         |
|-----------------------------|------------------------|-----------------------------|
| `house.fill`                | RoomScreen sheet       | `Home`                      |
| `square.grid.2x2.fill`      | CollectionView         | `Dex`                       |
| `person.2.fill`             | FriendsView            | `Friends`                   |
| `tshirt.fill`               | ShopView               | `Shop` (unified)            |
| `person.crop.circle.fill`   | ProfileView            | `You`                       |

---

## 2. Home screen

- Same warm diorama (`RoomView` with the player's theme + placed decor + creature).
- Add a **visible `✏️ Decorate` pill** anchored to the room (e.g. bottom-trailing
  corner of the room frame). Tapping the room area still works, but discovery no
  longer depends on it.
- **Tap the yolk = pet** (unchanged). Room tap and the Decorate pill both enter
  Decorate mode.
- Keep the honest status line (trust stage label / mood) and the `today` care row
  (check in / focus / visit) and living card unchanged.

---

## 3. Decorate mode (snap-to-zones)

The room is divided into **7 zones**, each holding **one piece at a time**, so a
fully decorated room is curated and never overlaps.

Zones: `hanging` · `wallL` · `wallC` · `wallR` · `floorL` · `floorC` · `floorR`

### Zone assignment

Every `RoomDecor` is tagged with a `zone`. The piece **keeps its hand-authored
`(px, py)` as its anchor** when displayed, so placements still look intentional.
The zone only governs which single slot the piece occupies (the one-per-zone rule)
and which tray it appears in.

Derivation rule (authored once into the catalog as a `zone` value, derived from the
existing `px/py` + kind):

- `hanging` — ceiling pieces by kind: garland, fairy lights, paper lantern,
  hanging plant, balloons, night stars.
- Otherwise split by `py`: `py < 0.45` = wall band, `py >= 0.45` = floor band.
- Within a band, split by `px`: `< 0.40` = L, `0.40–0.65` = C, `> 0.65` = R.

Resulting assignment of the 34 pieces:

| Zone     | Pieces |
|----------|--------|
| hanging  | garland, fairy lights, paper lantern, hanging plant, balloons, night stars |
| wallL    | wall shelf, bird cage |
| wallC    | sunny poster, wall clock, framed photos, calendar |
| wallR    | heart mirror, wall vines |
| floorL   | bookshelf, cozy bed, toadstool, toy chest, record player, play tent |
| floorC   | wood stool, cactus, flower vase, fireplace, hammock |
| floorR   | beanbag, table lamp, candle, floor cushion, tea table, yolk tower, ball pit, monstera, fish tank |

A maxed room shows up to 7 pieces simultaneously — matching the authored layout
density. Per-zone capacity is a single tunable constant (`zoneCapacity = 1` for v1);
bumping a zone to 2 later is a one-line change if we want denser rooms.

### Flow

1. Enter Decorate from the `✏️ Decorate` pill or by tapping the room.
2. The diorama stays on screen; zones become tappable targets (subtle outline/label
   on tap-in).
3. Tap a zone → a tray slides up showing:
   - The **owned** pieces valid for that zone (tap to place).
   - A **`✕ Clear`** action (empties the zone).
   - **Buyable** pieces valid for that zone with their price → **buy-in-place** using
     the same try-on → buy flow as Shop. On purchase the piece is both owned (wallet)
     and placed (zone dict).
4. Placing writes `placedDecorByZone[zone] = decorID`; clearing removes the key.

This delivers **move** (reassign a piece's zone slot) and **remove**, which do not
exist today, with no new geometry — it is a `[String: String]` dictionary.

### Theme selection

Room theme selection (16 themes) moves to the Shop "Room" aisle for browse/buy, and
the currently applied theme is also switchable from within Decorate (a compact theme
strip), since theme is a room-level choice. Applying a theme writes
`player.roomThemeID` (unchanged field).

---

## 4. Unified Shop

One store, three **aisles** via a segmented control at the top:
`Colours` · `Outfit` · `Room`.

- **One card component** and **one try-on → buy** flow everywhere. This replaces the
  three inconsistent flows (ShopView preview+buy, RoomScreen preview+apply,
  WardrobeView buy-without-preview). Owned items equip/apply on tap.
- **Colours** show a small "recolors your body" hint so they are not mistaken for
  clip-on cosmetics. Buying a colour applies via the existing `onColor` callback.
- **Outfit** keeps the 3 cosmetic slots (hat / eyes / neck), one sub-section each.
- **Room** holds themes + decor. Buying decor here marks it owned; placing it happens
  in Decorate mode (or buy-in-place from a zone tray).

### Utility row (applies within the active aisle)

- **🔎 Search** by name.
- **`All | Owned` toggle** — this is the closet. "Owned" filters to what you have so
  you can re-equip; it replaces the deleted WardrobeView entirely.
- **Sort**: price (low/high), rarity, new.

### Curated front (shown above the full grid, per aisle)

Reduces the "82 raw items" wall:

- **New** — most recently added items.
- **Under 100 Yolks** — affordable now.
- **Almost yours** — items closest to your current balance (nudges earning).

### Grids

Replace horizontal scroll rows with **vertical, scannable lazy grids** so browsing a
large catalog (e.g. 39 hats) is a normal scroll, not a thumb marathon.

---

## 5. Tutorial rewrite

Four honest beats (replaces the 3 inaccurate beats in `HomeTutorial.swift`):

1. **Meet [name]** — "your one of a kind yolk, living in their little room. tap them
   anytime to say hi." (unchanged)
2. **Your real day feeds them** — drop "time off your phone"; say **steps + sleep**
   (what is actually live). Re-add phone time here when Screen Time ships.
3. **Decorate their space** (new beat) — points at the Decorate pill: "this room is
   theirs and yours — tap decorate to make it home."
4. **Earn their trust** — caring for yourself warms them up; they learn to wave and
   celebrate. Replace "grow" with "warm up to you / become truly yours."

The new beat 3 should visually indicate the Decorate pill location (the tutorial
already dims the screen with the room showing through and positions cards by screen
fraction; add a beat whose copy + position point at the pill).

---

## 6. Data model + migration (SwiftData-safe)

- **New** `Player.placedDecorByZone: [String: String]?` — optional, defaults nil.
  Maps zone raw value → decor id. Migration-safe (new optional field only).
- **New** `RoomDecor.zone: Zone` — authored into the catalog (no behavioral data
  loss; `px/py/sw/sh` retained as the in-zone anchor).
- **New** `enum RoomDecor.Zone: String` — the 7 zone cases.
- **First-load migration:** when `placedDecorByZone` is nil, auto-place currently
  owned decor — one piece per zone, highest rarity wins ties — and persist. This
  keeps existing players' rooms populated after the update instead of going empty.
- **Unchanged:** wallet/`owned` remains the source of truth for ownership. The zone
  dict only controls what is currently displayed and where. `roomThemeID`,
  `WardrobeStore` (equipped cosmetics), coins, trust, streak, etc. are untouched.
- `RoomView` rendering changes from "place all owned decor at their px/py" to "place
  the one piece per occupied zone at its px/py." This also fixes the latent overlap
  bug where owning many same-region pieces stacks them.

---

## 7. File-level change map

Add:
- `Features/Shop/ShopHomeView.swift` (or refactor `ShopView`) — the unified store:
  aisle segmented control, utility row, curated front, lazy grids, shared card.
- `Features/Room/DecorateView.swift` — snap-to-zones edit mode (zone targets, tray,
  buy-in-place, theme strip). May absorb/replace `RoomScreen`.
- `Core/Rooms/RoomZone.swift` — the `Zone` enum + assignment + per-zone capacity.

Modify:
- `Core/Rooms/RoomDecor.swift` — add `zone` to the model + catalog rows.
- `Core/Rooms/RoomDecorView.swift` / `Features/Room/RoomView.swift` — render one
  piece per occupied zone (read `placedDecorByZone`).
- `Features/Home/HomeView.swift` — Decorate pill, labeled bottom nav, route nav to
  the unified Shop, remove `showWardrobe`, wire `placedDecorByZone`.
- `Features/Home/HomeTutorial.swift` — the 4-beat rewrite.
- `Core/Persistence/Player.swift` (the `Player` @Model) — add `placedDecorByZone`.

Delete:
- `Features/Wardrobe/WardrobeView.swift` (orphan). Confirm nothing else references it.

Keep but fold in:
- `Features/Wardrobe/ShopView.swift` content is reorganized into the unified store
  (colours + cosmetics aisles). `CosmeticPreviewGrid` reused where it fits.

---

## 8. Testing / verification

- Migration: a player with several owned decor across regions auto-populates one per
  zone on first load; rooms are never empty post-update.
- One-per-zone: placing a second piece in an occupied zone swaps, never stacks.
- Clear: emptying a zone removes the key and the piece disappears.
- Buy-in-place: purchasing from a zone tray both deducts Yolks and places the piece.
- Shop: `All | Owned` toggle correctly scopes each aisle; search/sort operate within
  the active aisle; curated front reflects balance + catalog.
- Tutorial: 4 beats render, beat 3 points at the Decorate pill, no "phone"/"grow"
  copy remains.
- Build clean on Swift 6 / iOS 18 (MainActor isolation), responsive on iPhone SE
  through Pro Max (reuse the existing GeometryReader hero sizing).

---

## Open tunables (not blocking)

- Per-zone capacity (default 1). Bumping floor zones to 2 is a one-line change.
- Whether the theme strip lives in Decorate, Shop's Room aisle, or both (spec says
  both; Decorate strip is the convenience copy).
