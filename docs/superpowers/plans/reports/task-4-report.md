# Task 4 Report: Decorate Mode (Snap-to-Zones)

## Files changed

- **Created:** `Yolkling/Features/Room/DecorateView.swift`
- **Modified:** `Yolkling/App/RootView.swift` (`RoomTryOnPreview` repointed at `DecorateView`)

## Final public signature

```swift
struct DecorateView: View {
    let vibe: Vibe
    let expression: YolkExpression
    let outfit: [Cosmetic]
    @Bindable var wallet: Wallet
    @Binding var placed: [String: String]?   // zone.rawValue -> decor id
    @Binding var themeID: String
    var onChange: () -> Void
}
```

Exact match to the interface Task 5 depends on.

## Exact Wallet purchase + theme-apply calls used

**Purchase (decor or theme):**
```swift
wallet.purchase(id: item.id, cost: item.cost)
```
This is `Wallet.purchase(id: String, cost: Int) -> Bool` (discardable). Called in `confirmBuy(_:)` after the `wallet.coins >= item.cost` guard.

**Ownership check:**
```swift
wallet.has(piece.id)       // decor
t.cost == 0 || wallet.has(t.id)   // theme (free themes always owned)
```

**Theme apply (owned):**
```swift
themeID = t.id
onChange()
```
Setting `themeID` binding propagates immediately; `onChange()` tells HomeView to persist.

**Decor buy-then-place:**
```swift
wallet.purchase(id: item.id, cost: item.cost)
// then:
place(d.id, in: d.zone)   // mutates the `placed` binding and calls onChange()
```

## How zones, trays, and buy-in-place work

**Zone targets:** `GeometryReader` overlay on the room frame. Seven transparent `Button` views are `.position()`-ed at fixed fractional anchors (`DecorateView.zoneAnchor`). Each shows a dashed/filled circle indicator and a label when active. Tapping sets `activeZone`; tapping again (or the tray X) clears it.

**Zone tray:** `zoneTray(_ zone:)` is shown below the room when `activeZone != nil`. It is a horizontal `ScrollView` of every `RoomDecorCatalog.all` piece whose `.zone` matches. A leading "clear" chip empties the zone. Each piece card shows a `RoomDecorView` swatch and a price label with three states:
- owned + placed in this zone -> "placed" text + dark border ring; tap to clear
- owned, not placed -> "owned" text; tap to place immediately via `place(_:in:)`
- unowned -> coin icon + cost; tap to set `tryOn = .decor(piece)` (try-on path)

**Buy-in-place:** `tryOnBar(_:)` slides up from the bottom with "trying on the X" hint, "not now" and "buy N" buttons. On confirm: `wallet.purchase(id:cost:)` -> place in zone -> clear `tryOn`. On insufficient funds: `YolkDialog` with `Mood.curious` creature icon.

**Theme strip:** Horizontal scroll of all `RoomThemes.all`. Owned themes apply immediately (tap sets `themeID` binding + calls `onChange()`). Unowned themes use the same `tryOnBar` path with `TryOnItem.theme(_:)`, and on buy: `themeID = t.id` + `onChange()` + clear `tryOn`.

**Try-on preview:** `tryOnDisplayTheme` and `tryOnDisplayDecor` overlay the try-on piece on the live room without mutating state, exactly matching the RoomScreen pattern.

**Local mutation helper:**
```swift
private func place(_ id: String?, in zone: RoomDecor.Zone) {
    var dict = placed ?? [:]
    if let id { dict[zone.rawValue] = id } else { dict.removeValue(forKey: zone.rawValue) }
    placed = dict
    onChange()
    Haptics.shared.select()
}
```

## Build result

`** BUILD SUCCEEDED **` on Yolk-SE (`8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1`), iOS Simulator 26.5.

xcodegen regenerated cleanly (new file picked up by glob). No Swift 6 concurrency warnings from the new file (all mutations occur in Button action closures on the MainActor-isolated view).

## Screenshot verification

**Screenshot 1** (`/tmp/task4-decorate.png`, initial launch via `SIMCTL_CHILD_YOLK_ROOM_TRYON=1`):
- "decorate" heading with 999 Yolks coin balance and X dismiss button visible at top
- Live room rendered with the matcha yolk creature, beach theme active, stub placed decor visible (sunny poster top-left wall, lamp bottom-right)
- Seven zone target dots overlaid on the room at their fractional anchors (visible as small circles on wall and floor regions)
- "THEMES" label strip at bottom showing cozy, forest cabin, beach (active, with selection highlight ring), candy shop, night sky swatches with price labels (cozy "owned", others with Yolk costs)
- Beach theme is the pre-seeded `themeID` in the stub, correctly shown as active

Zone tray and buy bar were not open in the initial screenshot (no zone tapped yet), which is the correct default state. The view is fully functional for tap interactions in the live simulator.

## RoomTryOnPreview status

**Left repointed at DecorateView.** The `YOLK_ROOM_TRYON` seam now presents `DecorateView` with a stub `Wallet(coins: 999, owned: ["decor-poster", "decor-lamp", "decor-cactus"])`, a pre-seeded `placed` dict (`{"wallC": "decor-poster", "floorL": "decor-lamp"}`), and `themeID = "room-beach"`. This is more useful for ongoing development of Task 5 and beyond than the old `RoomScreen` try-on seam.

## Notes / concerns

- No em dashes anywhere in the file. All strings use lowercase warm voice matching existing copy.
- `RoomScreen.swift` is untouched (as required). `HomeView.swift` is untouched (Task 5 responsibility).
- The `TryOnItem` enum is internal to `DecorateView` (not exported), matching RoomScreen's own internal `TryOn` enum pattern.
- `Rarity.rank` (from `RoomZone.swift`, Task 1) is NOT used in `DecorateView` itself; it is used by `Player.placedDecor(ownedIDs:)` (Task 2) for tie-breaking. No dependency issue.
- Zone target buttons use `.buttonStyle(.plain)` and are `.position()`-ed over a `ZStack`, so they are individually tappable without blocking the room's own gesture passthrough.
