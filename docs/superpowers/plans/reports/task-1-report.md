# Task 1 Report: Zone model + derivation

## Status

DONE

## Files Created/Modified

- **Created:** `/Users/sankiii/iOSLocal/yolkling/Yolkling/Core/Rooms/RoomZone.swift`
- **Modified (temporary seam, then restored):** `/Users/sankiii/iOSLocal/yolkling/Yolkling/App/RootView.swift`

Note: `RoomDecor.swift` was NOT modified. The computed `var zone` is added via the extension in `RoomZone.swift` (Swift allows extending structs across files), so no change to the model file was needed.

## Build Result

`** BUILD SUCCEEDED **` -- both the initial build after adding `RoomZone.swift`, and the final build after removing the temporary seam.

## Zone Counts Observed in Screenshot

Confirmed via `/tmp/task1-zones.png` on Yolk-SE (8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1):

| Zone   | Count | Pieces |
|--------|-------|--------|
| hanging | 6 | Garland, Balloons, Fairy Lights, Hanging Plant, Paper Lantern, Night Stars |
| wallL  | 2 | Wall Shelf, Bird Cage |
| wallC  | 4 | Sunny Poster, Wall Clock, Framed Photos, Calendar |
| wallR  | 2 | Heart Mirror, Wall Vines |
| floorL | 6 | Bookshelf, Cozy Bed, Toadstool, Toy Chest, Record Player, Play Tent |
| floorC | 5 | Wood Stool, Cactus, Flower Vase, Fireplace, Hammock |
| floorR | 9 | Beanbag, Table Lamp, Candle, Floor Cushion, Tea Table, Yolk Tower, Ball Pit, Monstera, Fish Tank |

All counts match the spec (hanging 6, wallL 2, wallC 4, wallR 2, floorL 6, floorC 5, floorR 9). Total: 34 pieces.

## Rarity.rank

`Rarity` (defined in `Core/Cosmetics/Cosmetic.swift`, line 61) had no `rank` property. Added the extension at the bottom of `RoomZone.swift`:

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

There was no existing ordering to reuse.

## Temporary Seam

Added `YOLK_ZONES` branch to `RootView.swift` for zone mapping verification, then removed it. Final `RootView.swift` is identical to its pre-task state. Final build after removal: `** BUILD SUCCEEDED **`.
