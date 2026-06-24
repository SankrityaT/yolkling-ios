# Home + Shop Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make room decorating discoverable and feel like designing (snap-to-zones), collapse three fragmented shops into one unified store, and fix the inaccurate tutorial.

**Architecture:** Add a derived 7-zone system over the existing decor catalog (each zone shows one piece, pieces keep their authored positions). Persist placement as a `[zone: decorID]` dictionary on `Player`. Replace the room sheet with a Decorate mode, fold three shop surfaces into one aisled store, and rewrite the tutorial copy. All additive and SwiftData migration-safe.

**Tech Stack:** Swift 6 (MainActor default isolation), SwiftUI, SwiftData, xcodegen.

## Global Constraints

- iOS deployment target 18.0; Swift 6 strict concurrency (MainActor default isolation). Verbatim from project.yml.
- SwiftData migration-safe: only add OPTIONAL or DEFAULTED `@Model` properties. Never make an existing property non-optional or rename one.
- NO em dashes in any user-facing copy. Lowercase-ok, warm, short voice (match existing strings).
- No new third-party dependencies. No new build targets.
- **No git repository.** This project is not under version control, so the plan has no commit steps. Each task's gate is: (a) compiles clean, (b) visual verification via the named `YOLK_*` seam. If the user runs `git init` first, add a commit at each task's end.
- **Verification harness = build + screenshot seams, not XCTest** (this codebase has no test target; that is its established pattern). Seams are env vars read in `App/RootView.swift` and `Features/Home/HomeView.swift::applyScreenshotSeams()`.

### Devices (real, already created by the user — do NOT create/erase/uninstall)

- **Yolk-SE** (small screen) = `8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1`, iOS 26.5. The app is installed here; it is the user's primary test device.
- **Yolk-ProMax** (large screen) = `9A3F2A47-5868-4956-B3AB-7531342B9347`, iOS 26.5.

HARD RULE: never run `simctl uninstall`, `simctl erase`, or delete a device. Installing a fresh build (`simctl install`, which overwrites) is fine. Screenshots only read.

### Build + verify commands (used by every task)

Regenerate the Xcode project after ADDING or DELETING any `.swift` file (xcodegen globs source dirs):

```bash
cd /Users/sankiii/iOSLocal/yolkling && xcodegen generate
```

Build (the gate for every task) — build against Yolk-SE:

```bash
cd /Users/sankiii/iOSLocal/yolkling && \
xcodebuild -scheme Yolkling \
  -destination 'platform=iOS Simulator,id=8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1' \
  -derivedDataPath build/DD build 2>&1 | tail -25
```
Expected: `** BUILD SUCCEEDED **`

Visual verify via a seam (boot the device by id, install the fresh build, launch with the seam env). Example renders the all-decor room on Yolk-SE:

```bash
SE=8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1
xcrun simctl boot "$SE" 2>/dev/null; sleep 2
xcrun simctl install "$SE" build/DD/Build/Products/Debug-iphonesimulator/Yolkling.app
xcrun simctl launch --terminate-running-process \
  --setenv YOLK_ROOM 0 "$SE" com.Sankritya.Yolkling
sleep 3; xcrun simctl io "$SE" screenshot /tmp/verify.png
```
Then Read `/tmp/verify.png` to confirm the state renders as the task describes.
For large-screen checks (Task 5), repeat with `9A3F2A47-5868-4956-B3AB-7531342B9347` (Yolk-ProMax).

---

## File structure

Create:
- `Core/Rooms/RoomZone.swift` — `RoomDecor.Zone` enum, the derivation `zone(for:)`, `zoneCapacity`, and zone ordering helpers. One responsibility: the zone model.
- `Features/Room/DecorateView.swift` — snap-to-zones edit mode (zone targets + tray + buy-in-place + theme strip). Replaces `RoomScreen`.
- `Features/Shop/ShopHomeView.swift` — the unified store (aisle picker, utility row, curated front, shared card, lazy grids).

Modify:
- `Core/Rooms/RoomDecor.swift` — add a computed `zone` to `RoomDecor`.
- `Core/Persistence/Player.swift` — add `placedDecorByZone` + first-load migration helper.
- `Features/Room/RoomView.swift` — render one piece per occupied zone instead of all owned.
- `Features/Home/HomeView.swift` — Decorate pill, labeled bottom nav, wire `placedDecorByZone`, route to `ShopHomeView`, remove `showWardrobe`.
- `Features/Home/HomeTutorial.swift` — 4-beat accurate rewrite.

Delete:
- `Features/Wardrobe/WardrobeView.swift` (confirmed orphan, no external refs).

Fold in (reorganized, not deleted):
- `Features/Wardrobe/ShopView.swift` content becomes the Colours + Outfit aisles of `ShopHomeView`. `RoomScreen.swift` logic (try-on/buy) informs the Room aisle + Decorate tray.

---

### Task 1: Zone model + derivation

**Files:**
- Create: `Core/Rooms/RoomZone.swift`
- Modify: `Core/Rooms/RoomDecor.swift` (add computed `zone`)

**Interfaces:**
- Produces:
  - `enum RoomDecor.Zone: String, CaseIterable, Sendable { case hanging, wallL, wallC, wallR, floorL, floorC, floorR }`
  - `var RoomDecor.zone: RoomDecor.Zone` (computed)
  - `enum RoomZones { static let capacity = 1; static func zone(for d: RoomDecor) -> RoomDecor.Zone; static let displayOrder: [RoomDecor.Zone] }`
  - `var RoomDecor.Rarity` already exists with `.common/.rare/.epic` (used later for tie-break; add `var rank: Int` if not present).

- [ ] **Step 1: Create `Core/Rooms/RoomZone.swift`**

```swift
import SwiftUI

extension RoomDecor {
    /// A single display slot in the room. Each zone shows at most `RoomZones.capacity`
    /// piece(s) so a fully decorated room stays curated and never overlaps. A piece's
    /// authored (px, py) is still its anchor; the zone only decides which slot it owns.
    enum Zone: String, CaseIterable, Sendable {
        case hanging, wallL, wallC, wallR, floorL, floorC, floorR
    }
    /// Derived, stable for a given catalog entry.
    var zone: Zone { RoomZones.zone(for: self) }
}

enum RoomZones {
    /// Pieces per zone shown at once. Bump a zone later by making this a per-zone map.
    static let capacity = 1

    /// Top to bottom, for laying out edit targets + trays.
    static let displayOrder: [RoomDecor.Zone] =
        [.hanging, .wallL, .wallC, .wallR, .floorL, .floorC, .floorR]

    private static let hangingKinds: Set<RoomDecor.Kind> =
        [.pennantGarland, .fairyLights, .paperLantern, .hangingPlant, .balloonBunch, .nightStars]

    /// Reproduces the authored 34-piece mapping (see spec): ceiling pieces by kind,
    /// then wall vs floor by py at 0.45, then L/C/R by px at 0.40 and 0.65.
    static func zone(for d: RoomDecor) -> RoomDecor.Zone {
        if hangingKinds.contains(d.kind) { return .hanging }
        let isWall = d.py < 0.45
        let col: Int = d.px < 0.40 ? 0 : (d.px <= 0.65 ? 1 : 2)
        switch (isWall, col) {
        case (true, 0):  return .wallL
        case (true, 1):  return .wallC
        case (true, _):  return .wallR
        case (false, 0): return .floorL
        case (false, 1): return .floorC
        case (false, _): return .floorR
        }
    }
}
```

- [ ] **Step 2: Ensure `RoomDecor.Rarity` has a comparable rank (for Task 2 tie-break)**

Open `Core/Rooms/RoomDecor.swift`. Find the `Rarity` type (shared enum, likely in a Cosmetics/Rarity file). If it has no `rank`, add this extension to the bottom of `RoomZone.swift`:

```swift
extension Rarity {
    /// common < rare < epic, for "highest rarity wins" placement ties.
    var rank: Int {
        switch self {
        case .common: return 0
        case .rare:   return 1
        case .epic:   return 2
        }
    }
}
```
If `Rarity` already exposes a rank/ordering, skip this and use the existing one (note its name in Task 2).

- [ ] **Step 3: Regenerate + build**

Run the regenerate then build commands from Global Constraints.
Expected: `** BUILD SUCCEEDED **`. Swift 6 will flag any concurrency/case mismatch.

- [ ] **Step 4: Sanity-check the mapping (temporary seam)**

Temporarily add to `App/RootView.swift` (inside the env `if`/`else` chain, near the other `YOLK_*` seams):

```swift
} else if ProcessInfo.processInfo.environment["YOLK_ZONES"] != nil {
    ScrollView { VStack(alignment: .leading) {
        ForEach(RoomZones.displayOrder, id: \.self) { z in
            Text(z.rawValue).bold()
            Text(RoomDecorCatalog.all.filter { $0.zone == z }.map(\.name).joined(separator: ", "))
                .font(.caption).foregroundStyle(.secondary)
        }
    }.padding() }
```

Build, then run with `--setenv YOLK_ZONES 1` and screenshot. Confirm counts: hanging 6, wallL 2, wallC 4, wallR 2, floorL 6, floorC 5, floorR 9. Then REMOVE the temporary seam and rebuild.

---

### Task 2: Persist placement + first-load migration

**Files:**
- Modify: `Core/Persistence/Player.swift`

**Interfaces:**
- Consumes: `RoomDecor.Zone`, `RoomZones`, `Rarity.rank` (Task 1); `RoomDecorCatalog.all`, `wallet.owned`.
- Produces:
  - `var Player.placedDecorByZone: [String: String]?` (zone.rawValue -> decor id)
  - `func Player.placedDecor(ownedIDs: Set<String>) -> [RoomDecor.Zone: RoomDecor]` (resolves the display map, running first-load migration if the stored dict is nil)

- [ ] **Step 1: Add the stored property**

In `Core/Persistence/Player.swift`, add alongside the other optional persisted fields:

```swift
/// Decorate-mode placement: zone.rawValue -> decor id. Optional + defaulted nil so
/// it is SwiftData migration-safe. nil means "not migrated yet" (see placedDecor()).
var placedDecorByZone: [String: String]? = nil
```

- [ ] **Step 2: Add the resolver + migration**

Add to `Player` (or a `Player` extension in the same file):

```swift
/// The pieces to actually display, one per occupied zone. On first run after the
/// update (`placedDecorByZone == nil`), auto-place owned decor: one per zone, highest
/// rarity wins ties, and persist so rooms are never empty post-update.
func placedDecor(ownedIDs: Set<String>) -> [RoomDecor.Zone: RoomDecor] {
    if let stored = placedDecorByZone {
        var out: [RoomDecor.Zone: RoomDecor] = [:]
        for (zoneRaw, id) in stored {
            guard let zone = RoomDecor.Zone(rawValue: zoneRaw),
                  let d = RoomDecorCatalog.byID(id), ownedIDs.contains(id) else { continue }
            out[zone] = d
        }
        return out
    }
    // Migrate: best owned piece per zone.
    var best: [RoomDecor.Zone: RoomDecor] = [:]
    for d in RoomDecorCatalog.all where ownedIDs.contains(d.id) {
        if let cur = best[d.zone], cur.rarity.rank >= d.rarity.rank { continue }
        best[d.zone] = d
    }
    placedDecorByZone = Dictionary(uniqueKeysWithValues: best.map { ($0.key.rawValue, $0.value.id) })
    return best
}

/// Place / swap / clear a single zone, then it is the caller's job to persist().
func setDecor(_ id: String?, in zone: RoomDecor.Zone) {
    var dict = placedDecorByZone ?? [:]
    if let id { dict[zone.rawValue] = id } else { dict[zone.rawValue] = nil }
    placedDecorByZone = dict
}
```

- [ ] **Step 3: Build**

Regenerate not needed (no new file). Run the build command.
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Note for later tasks**

`HomeView.persist()` must also write `player.placedDecorByZone` (added in Task 5). No action now.

---

### Task 3: Render one piece per occupied zone

**Files:**
- Modify: `Features/Room/RoomView.swift`

**Interfaces:**
- Consumes: `Player.placedDecor(ownedIDs:)` map OR a passed-in `[RoomDecor]` already filtered to placed pieces.
- Produces: `RoomView` displays exactly the placed pieces (one per occupied zone), each at its authored `(px, py, sw, sh)`.

- [ ] **Step 1: Change the decor input contract**

Today `RoomView` receives `decor: [RoomDecor]` and places them all. Keep the same parameter, but callers will now pass only the placed pieces (the resolved map's values). Confirm `RoomView` already iterates `decor` and positions each at its `px/py/sw/sh`. If it filters by ownership internally, remove that — it must render exactly what it is given.

Read `Features/Room/RoomView.swift`, find the `ForEach(decor)` placement block, and ensure it renders the passed array verbatim (no internal owned-filtering).

- [ ] **Step 2: Build**

Run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Visual verify**

The home/room still renders via existing callers (which pass `placedDecor` after Task 5). For now verify the `YOLK_ROOM` seam still builds + shows decor. Run the `YOLK_ROOM 0` seam screenshot and Read it: decor pieces appear, none overlapping in the same corner. (Full one-per-zone behavior is exercised after Task 5 wires the resolver.)

---

### Task 4: Decorate mode (snap-to-zones)

**Files:**
- Create: `Features/Room/DecorateView.swift`
- Reference (read for try-on/buy pattern, then supersede): `Features/Room/RoomScreen.swift`

**Interfaces:**
- Consumes: `RoomZones.displayOrder`, `RoomDecor.zone`, `RoomDecorCatalog.all`, `Player.setDecor(_:in:)`, `Wallet` (purchase + owned), `RoomThemes`, the live `RoomView`.
- Produces: `struct DecorateView: View` presented as a `.large` sheet from `HomeView`. Signature:
  ```swift
  DecorateView(vibe: Vibe, expression: YolkExpression, outfit: [Cosmetic],
               wallet: Wallet, placed: Binding<[String:String]?>,
               themeID: Binding<String>, onChange: () -> Void)
  ```

- [ ] **Step 1: Build the view skeleton**

Create `Features/Room/DecorateView.swift`. Structure (read `RoomScreen.swift` for the existing header + try-on confirm-bar pattern and match its visual style + the `Wallet.purchase` call):

```swift
import SwiftUI

/// Snap-to-zones room editor. The live diorama stays on top; tapping a zone opens a
/// tray of pieces that fit it (owned -> place, unowned -> buy-in-place, plus clear).
/// A compact theme strip switches the room theme. One piece per zone (RoomZones.capacity).
struct DecorateView: View {
    let vibe: Vibe
    let expression: YolkExpression
    let outfit: [Cosmetic]
    @Bindable var wallet: Wallet
    @Binding var placed: [String: String]?
    @Binding var themeID: String
    var onChange: () -> Void

    @State private var activeZone: RoomDecor.Zone? = nil
    @State private var tryOn: RoomDecor? = nil
    @Environment(\.dismiss) private var dismiss

    private var theme: RoomTheme { RoomThemes.all.first { $0.id == themeID } ?? RoomThemes.cozy }
    private var placedPieces: [RoomDecor] {
        (placed ?? [:]).compactMap { RoomDecorCatalog.byID($0.value) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            // Live room with tappable zone targets overlaid.
            ZStack {
                RoomView(vibe: vibe, expression: expression, theme: theme,
                         outfit: outfit, decor: placedPieces, showCreature: true)
                zoneTargets   // transparent buttons positioned per zone anchor
            }
            .frame(maxHeight: .infinity)
            themeStrip
            if let z = activeZone { zoneTray(z) }   // slides up
            if let piece = tryOn { tryOnBar(piece) }
        }
        .background(YolkColor.shell.ignoresSafeArea())
    }
    // header, zoneTargets, themeStrip, zoneTray(_:), tryOnBar(_:) below.
}
```

- [ ] **Step 2: Implement zone targets**

Add `zoneTargets`: a `GeometryReader` overlay with one transparent, rounded, dashed-outline button per `RoomZones.displayOrder`, positioned at a representative anchor for that zone (use the average authored px/py of that zone's pieces, computed once). Tapping sets `activeZone = z`. When `activeZone == z`, show a subtle highlight + the zone's label. Keep anchors as constants:

```swift
private static let zoneAnchor: [RoomDecor.Zone: CGPoint] = [
    .hanging: .init(x: 0.45, y: 0.14), .wallL: .init(x: 0.22, y: 0.30),
    .wallC: .init(x: 0.54, y: 0.17), .wallR: .init(x: 0.85, y: 0.22),
    .floorL: .init(x: 0.24, y: 0.78), .floorC: .init(x: 0.50, y: 0.78),
    .floorR: .init(x: 0.82, y: 0.76),
]
```

- [ ] **Step 3: Implement the zone tray**

`zoneTray(_ zone:)`: a horizontal scroll of every `RoomDecorCatalog.all.filter { $0.zone == zone }`. For each piece show a `RoomDecorView(kind:)` swatch + name + state:
- placed in this zone -> selected ring + tap clears (`setDecor(nil)`).
- owned, not placed -> tap places (`placed?[zone.rawValue] = id`; via `setDecorLocal`).
- unowned -> show cost; tap sets `tryOn = piece`.
Plus a leading `✕ Clear` chip that empties the zone.

Local mutation helper inside the view:
```swift
private func place(_ id: String?, in zone: RoomDecor.Zone) {
    var dict = placed ?? [:]
    if let id { dict[zone.rawValue] = id } else { dict.removeValue(forKey: zone.rawValue) }
    placed = dict
    onChange()   // HomeView persists
    Haptics.shared.select()
}
```

- [ ] **Step 4: Implement try-on/buy bar + theme strip**

`tryOnBar(_ piece:)`: match `RoomScreen`'s confirm bar ("trying on the [name]" + "not now" / "buy [cost]"). On buy: `wallet.purchase(id:cost:)` (use the exact existing Wallet API — read `Features/Wardrobe/Wallet.swift`), then `place(piece.id, in: piece.zone)`, clear `tryOn`. `themeStrip`: horizontal scroll of `RoomThemes.all`; owned -> tap sets `themeID`; unowned -> try-on/buy like decor (theme buy uses the existing theme purchase path from `RoomScreen`).

- [ ] **Step 5: Regenerate + build**

Run regenerate (new file) then build. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Visual verify**

Add a temporary preview seam or reuse `YOLK_ROOM_TRYON` (RootView already has `RoomTryOnPreview`; repoint it at `DecorateView` with a stub wallet that owns a few pieces). Screenshot and Read: zones are tappable, a tray opens with the correct pieces for the zone, clear works, buy bar appears for unowned.

---

### Task 5: Home screen (Decorate pill, labeled nav, wiring)

**Files:**
- Modify: `Features/Home/HomeView.swift`

**Interfaces:**
- Consumes: `DecorateView` (Task 4), `ShopHomeView` (Task 6 — wire after it exists; until then keep routing to existing `ShopView`), `Player.placedDecor(ownedIDs:)`, `Player.placedDecorByZone`.
- Produces: home with a visible Decorate affordance, labeled bottom nav, `placedDecorByZone` persisted.

- [ ] **Step 1: Replace `placedDecor` source + state (migration runs once in onAppear, NEVER in body)**

In `HomeView`, replace `private var placedDecor: [RoomDecor] { RoomDecorCatalog.all.filter { wallet.has($0.id) } }` with a PURE computed var that only reads state. CRITICAL: never mutate a `@Model` or `@State` from a view-body computed property — that triggers "Modifying state during view update". `Player.placedDecor(ownedIDs:)` mutates the model on its migration path, so it must NOT be called from `body`/a computed var; call it once in `onAppear`.

```swift
@State private var placedByZone: [String: String]? = nil   // init from player

/// Pure read: the placed pieces in display order. No mutation here.
private var placedDecor: [RoomDecor] {
    let owned = wallet.owned
    guard let dict = placedByZone else {
        // pre-migration fallback (migration runs in onAppear): show owned, capped
        return Array(RoomDecorCatalog.all.filter { owned.contains($0.id) }.prefix(7))
    }
    return RoomZones.displayOrder.compactMap { zone in
        guard let id = dict[zone.rawValue], owned.contains(id) else { return nil }
        return RoomDecorCatalog.byID(id)
    }
}
```

In `init`, add `_placedByZone = State(initialValue: player?.placedDecorByZone)`.

Add this migration helper and call it from the EXISTING `.onAppear { ... }` list (alongside `applyTrustDecay()` etc.), so the model write happens outside the view body:

```swift
private func migratePlacedDecorIfNeeded() {
    guard let p = player, p.placedDecorByZone == nil else { return }
    _ = p.placedDecor(ownedIDs: wallet.owned)   // migrates + persists into the model
    placedByZone = p.placedDecorByZone
    try? context.save()
}
```

- [ ] **Step 2: Add the Decorate pill**

In `creatureHero`, overlay a pill on the room frame (bottom-trailing), above the diorama:

```swift
.overlay(alignment: .bottomTrailing) {
    Button { Haptics.shared.select(); showRoom = true } label: {
        Label("Decorate", systemImage: "pencil")
            .font(YolkType.bodySmall.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(YolkColor.ink)
    }
    .buttonStyle(.plain).padding(YolkSpace.md)
}
```
Keep the existing room-tap gesture (`showRoom = true`) as a secondary path.

- [ ] **Step 3: Point the room sheet at `DecorateView`**

Change the `.sheet(isPresented: $showRoom)` body from `RoomScreen(...)` to:

```swift
DecorateView(vibe: vibe, expression: shownExpression, outfit: wardrobe.outfit,
             wallet: wallet, placed: $placedByZone, themeID: $roomThemeID,
             onChange: { player?.placedDecorByZone = placedByZone; persist() })
    .presentationDetents([.large])
```

- [ ] **Step 4: Label the bottom nav + remove WardrobeView path**

Rewrite `bottomNav` so each `navItem` has a text label under the icon (add a `label:` param to `navItem`), with: `Home`(house, active) / `Shop`(bag) / `Dex`(grid) / `Friends`(people) / `You`(person). Remove the `tshirt`/`showWardrobe` item; the `Shop` item sets `showWardrobe = true` (kept as the state name that presents the store sheet) routing to the unified store. Delete the now-unused `showWardrobe`-as-wardrobe semantics only after Task 6 renames the sheet target.

- [ ] **Step 5: Persist `placedDecorByZone`**

In `persist()`, add `player.placedDecorByZone = placedByZone`.

- [ ] **Step 6: Regenerate + build + verify**

Build. Then screenshot the home seam (launch with no special env, or `YOLK_VIBE 0`) on BOTH Yolk-ProMax (`9A3F2A47-5868-4956-B3AB-7531342B9347`) AND Yolk-SE (`8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1`). Read both: Decorate pill visible on the room, nav labels visible and not clipped on the small SE screen.

---

### Task 6: Unified Shop — aisles + shared card + buy/equip

**Files:**
- Create: `Features/Shop/ShopHomeView.swift`
- Reference (fold in): `Features/Wardrobe/ShopView.swift`

**Interfaces:**
- Consumes: `ColorShop.all`, `CosmeticCatalog` (by slot), `RoomThemes.all`, `RoomDecorCatalog.all`, `Wallet`, `WardrobeStore`, `onColor` callback.
- Produces: `struct ShopHomeView: View` presented from `HomeView`'s store sheet. Signature mirrors current `ShopView` plus nothing new:
  ```swift
  ShopHomeView(vibe: Vibe, store: WardrobeStore, wallet: Wallet,
               originalBodyHex: Int, originalAccentHex: Int?,
               onColor: (Vibe, Int, Int?) -> Void)
  ```

- [ ] **Step 1: Aisle scaffold**

Create `ShopHomeView` with a segmented `Picker` over `enum Aisle { case colours, outfit, room }` and a live creature preview header (reuse `ShopView`'s preview). Body switches on the aisle. Read `ShopView.swift` and reuse its colour section + cosmetic-slot sections verbatim for `.colours` and `.outfit`.

```swift
enum Aisle: String, CaseIterable { case colours = "Colours", outfit = "Outfit", room = "Room" }
@State private var aisle: Aisle = .outfit
```

- [ ] **Step 2: Shared item card + one try-on/buy flow**

Extract `ShopView`'s card + confirm-bar into a single reusable `ShopCard` + `BuyBar` used by all three aisles, so colours, cosmetics, themes, and decor share one buy flow. Colours show a small caption "recolors your body". Owned items equip/apply on tap; unowned set `tryOn`.

- [ ] **Step 3: Room aisle**

`.room`: two sub-sections, Themes (`RoomThemes.all`) and Decor (`RoomDecorCatalog.all`), each a vertical `LazyVGrid` of `ShopCard`. Buying decor marks owned (placement happens in Decorate). Buying/owning a theme applies it.

- [ ] **Step 4: Vertical lazy grids**

Replace horizontal `ScrollView(.horizontal)` rows with `LazyVGrid(columns: 3-up)` so large catalogs scroll vertically.

- [ ] **Step 5: Point HomeView at it**

In `HomeView`, change the store sheet body from `ShopView(...)` to `ShopHomeView(...)` (same args). Keep `.presentationDetents([.medium, .large])`.

- [ ] **Step 6: Regenerate + build + verify**

Build. Screenshot the store via `--setenv YOLK_WARDROBE 1`. Read: aisle picker present, switching aisles works, colours show the body hint, decor grid scrolls vertically.

---

### Task 7: Shop utility row + curated front

**Files:**
- Modify: `Features/Shop/ShopHomeView.swift`

**Interfaces:**
- Consumes: the active aisle's item list, `wallet.coins`, `wallet.owned`.
- Produces: per-aisle search + `All|Owned` toggle + sort, and a curated front above the grid.

- [ ] **Step 1: Utility row**

Add a row under the aisle picker: a `TextField` search (filters the active aisle by name), an `All | Owned` segmented toggle (Owned filters to `wallet.owned`), and a `Menu` sort (price asc/desc, rarity, new). Apply all three to the active aisle's list via a computed `filteredItems`.

- [ ] **Step 2: Curated front**

Above the full grid (only when search is empty and toggle is All), show up to three single-row strips per aisle: `New` (last N catalog entries), `Under 100 Yolks` (cost < 100, unowned), `Almost yours` (unowned, smallest `cost - wallet.coins` that is still positive, sorted ascending). Each strip is a small horizontal `ScrollView` of `ShopCard`.

- [ ] **Step 3: Build + verify**

Build. Screenshot via `YOLK_WARDROBE 1`. Read: search narrows results, Owned toggle scopes to owned, curated strips appear and reflect the wallet balance.

---

### Task 8: Delete the orphan WardrobeView

**Files:**
- Delete: `Features/Wardrobe/WardrobeView.swift`

- [ ] **Step 1: Confirm no references, delete, regenerate**

```bash
cd /Users/sankiii/iOSLocal/yolkling/Yolkling
grep -rn "WardrobeView" --include="*.swift" . | grep -v build | grep -v "Features/Wardrobe/WardrobeView.swift" || echo "safe to delete"
rm Features/Wardrobe/WardrobeView.swift
cd /Users/sankiii/iOSLocal/yolkling && xcodegen generate
```

- [ ] **Step 2: Build**

Run the build command. Expected: `** BUILD SUCCEEDED **` (no "cannot find WardrobeView").

---

### Task 9: Tutorial rewrite (accurate + teaches the room)

**Files:**
- Modify: `Features/Home/HomeTutorial.swift`

**Interfaces:**
- Produces: four honest beats; beat 3 points at the Decorate pill; no "phone"/"grow" copy.

- [ ] **Step 1: Replace the `beats` array**

Replace the three-element `beats` with four (keep the `Beat` struct + `bottom` positioning; beat 3 uses `bottom: false` so its card sits near the room/pill):

```swift
[
    Beat(eyebrow: "meet \(name)",
         text: "this is \(name), your one of a kind yolk, living in their little room. tap them anytime to say hi.",
         bottom: false, cta: "next"),
    Beat(eyebrow: "the secret",
         text: "your real day feeds \(name). steps and sleep are what nourish them. (time off your phone is coming soon.)",
         bottom: true, cta: "next"),
    Beat(eyebrow: "make it home",
         text: "this little room is theirs and yours. tap decorate to place your stuff and make the space your own.",
         bottom: false, cta: "next"),
    Beat(eyebrow: "earn their trust",
         text: "check in and care for yourself daily. that is how you earn their trust, and they learn to wave, celebrate your wins, and become truly yours.",
         bottom: true, cta: "let's go"),
]
```
Confirm: no em dashes, no "grow", no "time off your phone" as a current driver.

- [ ] **Step 2: Build + verify**

Build. Screenshot via `--setenv YOLK_TUTORIAL 1`. Read each of the 4 beats: copy matches, 4/4 counter, beat 3 references decorate.

---

## Self-review

**Spec coverage:**
- IA / labeled nav -> Task 5 Step 4. Decorate not a nav slot -> Task 5 (pill + sheet). Kill WardrobeView -> Task 8.
- Home Decorate pill + tap -> Task 5 Steps 2-3. Pet unchanged -> untouched.
- Snap-to-zones (7 zones, derivation, mapping) -> Tasks 1, 4. One-per-zone render -> Tasks 2-3, 5. Buy-in-place -> Task 4 Steps 3-4. Theme in Decorate -> Task 4 Step 4.
- Unified Shop aisles + one flow -> Task 6. Colours hint -> Task 6 Step 2. Utility row (search/owned/sort) -> Task 7 Step 1. Curated front -> Task 7 Step 2. Vertical grids -> Task 6 Step 4.
- Tutorial 4 beats -> Task 9.
- Data: `placedDecorByZone` + migration -> Task 2. `RoomDecor.zone` -> Task 1. RoomView one-per-zone -> Task 3.
- Deferred (Looks, Bundles, free-drag) -> not in any task (correct).

**Placeholder scan:** Data-model + tutorial code is exact. View tasks (4, 6, 7) give structure + key snippets + the exact existing files to read for the buy/try-on pattern, rather than reproducing ~600 lines of final SwiftUI; this is the right calibration for executors that read the repo. The two Wallet/theme purchase calls are deliberately deferred to "read the exact API in Wallet.swift / RoomScreen.swift" because those signatures were not captured here — executor MUST read them before calling.

**Type consistency:** `RoomDecor.Zone` (7 cases), `RoomZones.zone(for:)`, `RoomZones.displayOrder`, `RoomZones.capacity`, `Player.placedDecorByZone: [String:String]?`, `Player.placedDecor(ownedIDs:)`, `Player.setDecor(_:in:)`, `DecorateView(vibe:expression:outfit:wallet:placed:themeID:onChange:)`, `ShopHomeView(vibe:store:wallet:originalBodyHex:originalAccentHex:onColor:)` are used consistently across tasks.

**Known executor responsibilities (read before coding):**
- `Features/Wardrobe/Wallet.swift` — exact purchase/owned API used in Tasks 4, 6, 7.
- `Features/Room/RoomScreen.swift` — exact theme purchase + confirm-bar pattern reused in Task 4.
- `Features/Wardrobe/ShopView.swift` — colour + cosmetic sections folded into Task 6.
- `Core/Rooms/RoomDecor.swift` `Rarity` type — confirm `rank` exists or add it (Task 1 Step 2).
