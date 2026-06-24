# Task 3 Report: Render one piece per occupied zone

## What changed in RoomView.swift

**No change needed.**

The existing `ForEach` in `RoomView.swift` (lines 34-38) already renders the passed `decor` array verbatim with no internal ownership or wallet filtering:

```swift
ForEach(decor) { d in
    RoomDecorView(kind: d.kind)
        .frame(width: w * d.sw, height: h * d.sh)
        .position(x: w * d.px, y: h * d.py)
}
```

The parameter `var decor: [RoomDecor] = []` (line 14) is accepted as-is and every element is rendered at its authored `px/py/sw/sh`. There is no `wallet.has`, `owned`, or any filtering logic inside `RoomView`. The contract is already correct: callers pass exactly what should be shown, RoomView draws it.

## Build result

`** BUILD SUCCEEDED **` - xcodebuild against Yolk-SE (`8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1`), no errors or warnings introduced.

## Screenshot verification

Launched with `SIMCTL_CHILD_YOLK_ROOM=0` on Yolk-SE. Screenshot saved to `/tmp/task3-room.png`.

Visual confirmation:
- Room renders with multiple decor pieces at their authored positions (pennant garland at ceiling/hanging zone, sunny poster on left wall, bookshelf on floor-left, lamp on floor-right)
- Creature (yolk) centered at its spot
- Theme, floor, rug, window, and wall art all intact
- YOLK_ROOM seam active (title "ALL DECOR" + decor picker below the room)
- No overlapping pieces in the same zone visible in the sample
