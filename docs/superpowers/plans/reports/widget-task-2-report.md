# Widget Task 2 Report

## Status: COMPLETE

---

## Files Changed

- **Created:** `YolklingWidgets/YolkRoomWidget.swift`
- **Modified:** `YolklingWidgets/YolklingWidgetBundle.swift` (registered `YolkRoomWidget`)
- **Modified:** `project.yml` (added `Yolkling/Features/Room/RoomView.swift` to widget sources)
- **Modified (temporary, removed):** `Yolkling/App/RootView.swift` (YOLK_WIDGET seam, now removed)

---

## Widget Code Shape

### YolkEntry
```swift
struct YolkEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let phase: YolkExpression.DayPhase
}
```

### YolkRoomProvider
Timeline builds entries at `now` plus each of `[0, 5, 11, 18, 22]` boundary hours (the
`DayPhase` transition hours) over the next ~24h, `.atEnd` policy so the widget stays
current through the next day. Each entry carries the same `snap` read once from
`WidgetShare.defaults`.

### YolkRoomEntryView
- `theme` = `room?.theme ?? RoomThemes.cozy`
- `vibe` = `room?.makeVibe(name: snapshot?.name ?? "yolk") ?? .yolk`
  (NOTE: `RoomSnapshot` has NO `.vibe` computed property -- it exposes `makeVibe(name:)`,
  not `.vibe`. The plan's skeleton used `.vibe` which would not compile; this was corrected.)
- `expression` = `(room?.expression ?? .content).atPhase(entry.phase, sleptWell: false)`
- Small scale: `1.15x` via `.scaleEffect` to bring the yolk closer to center
- Medium scale: `1.0` (full room visible, wide layout)
- Empty state overlay: "open yolkling" in a `.thinMaterial` capsule at `.bottom`

### containerBackground
```swift
.containerBackground(for: .widget) { theme.wall }
```
`RoomTheme.wall` is a `LinearGradient` (top/bottom wall hex colors). This is the correct
property -- NOT `wallTop`/`wallBottom` raw values, NOT `floorColor`.

### RoomView init used
```swift
RoomView(vibe: vibe, expression: expression, theme: theme,
         outfit: room?.outfit ?? [], decor: room?.decor ?? [])
```
All parameters have defaults in the real `RoomView` definition, so only named params are needed.
`showCreature` left at default `true`.

---

## project.yml change

`RoomView.swift` lives in `Yolkling/Features/Room/`, not `Core/Rooms/`. The widget target
already had `Yolkling/Core/Rooms` (which contains `RoomTheme.swift`, `RoomDecor.swift`,
`RoomDecorView.swift`, `RoomZone.swift`) but NOT the Features directory. Added:

```yaml
- path: Yolkling/Features/Room/RoomView.swift
```

`DecorateView.swift` (also in Features/Room/) was NOT added -- it has app-only dependencies
and is not needed for widget rendering.

---

## Seam Approach

Used **direct RoomView** (not widget types). `YolkEntry`/`YolkRoomEntryView` are defined
in the `YolklingWidgets` extension target, which is not visible to the app target. The seam
instead rendered `RoomView(...)` directly with the same framing logic:

- Small (day): `scaleEffect(1.15)`, `frame(155x155)`, `clipShape(RoundedRectangle(22))`
- Empty (night): `scaleEffect` none, cozy theme, `Vibe.yolk`, "open yolkling" capsule overlay
- Medium (evening): no scale, `frame(340x155)`, `clipShape(RoundedRectangle(22))`

Layout was a `VStack` with an `HStack` (small + empty side by side) above the medium, all
fitting in one viewport without scrolling.

Sample snapshot reused `SocialPreview.sunny.snapshot!` (the "beach day" room with
bookshelf/lamp/cactus/balloons decor and crown outfit, `colorHex: 0xFFC23B`).

---

## Build Result

`** BUILD SUCCEEDED **` on both the initial build (with seam) and the final build (seam removed).

One project.yml fix was required: `RoomView.swift` had to be explicitly added to widget
sources since it lives in `Features/Room/` not `Core/Rooms/`.

---

## Screenshot Results (`/tmp/task2-widget3.png`)

- **Small (day):** Yolk nicely centered in beach-themed room. Crown cosmetic visible. Room
  art, window, bookshelf, balloons all readable. Not cropped. Scale 1.15 gives a good
  tight crop on the yolk without cutting the ceiling.
- **Medium (evening):** Wide room, yolk centered, all decor spread across wider layout.
  Evening expression (slightly lower energy, calm).
- **Empty (night):** Default cozy room, `Vibe.yolk` golden creature, sleepy/night expression
  with zzz particle. "open yolkling" pill label visible at bottom of the frame.

---

## Seam Removal

`YOLK_WIDGET` block removed from `App/RootView.swift` before final build. Final build is
`** BUILD SUCCEEDED **` with no seam code present.
