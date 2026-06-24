# Friends Tab Redesign: Task 4 Report

## FriendRoomCard Signature

```swift
struct FriendRoomCard: View {
    let friend: Friend
    let store: SocialStore
    var onOpen: (Friend) -> Void
}
```

## RoomView Init Used

```swift
RoomView(
    vibe: vibe,           // from snapshot.makeVibe(name: friend.displayName) ?? .yolk
    expression: expression, // from snapshot.expression ?? .happy
    theme: theme,         // from snapshot.theme ?? RoomThemes.cozy
    outfit: outfit,       // from snapshot.outfit ?? []
    decor: decor          // from snapshot.decor ?? []
)
```

Framed square via `.aspectRatio(1, contentMode: .fit)`, clipped via `.clipShape(RoundedRectangle(cornerRadius: 18))`.

## Status Computation

Status chips are computed as local computed properties:

- `isNew`: `friend.updatedDate != nil` and (`store.lastVisited(friend.user_id) == nil` OR `updatedDate > lastVisited`). Renders `"✨ new"` in `YolkColor.yolk`.
- `moodLabel`: `Mood(rawValue: snapshot.moodRaw)?.label.lowercased()` -- uses the existing `Mood.label` property. Renders in `YolkColor.muted`.
- `isAsleep`: `YolkExpression.phase(forHour: snapshot.hour) == .night`. Renders `"😴"`.
- `streak`: `snapshot.streak ?? 0 > 0`. Renders `"🔥 \(streak)"` in `YolkColor.inkSoft`.

The entire status row is hidden (opacity 0) when none of the chips are active.

## Wave Button

- Calls `store.sendWave(to: friend.user_id)` inside a `Task {}`.
- Triggers `Haptics.shared.select()` before the Task.
- Local `@State private var waved = false` flips to true immediately on tap.
- Button is disabled after waving; label changes from `"👋 wave"` to `"waved!"`.

## Build Result

`** BUILD SUCCEEDED **` (verified twice: with seam and after seam removal).

## Screenshot Outcome

Screenshot `/tmp/task4-card.png` confirmed: 2-up grid of live FriendRoomCard instances, each showing:
- The friend's yolk (Sunny, classic yellow) standing in their beach-theme room with bookshelf, lamp, cactus, and balloons decor.
- Friend name "Sunny" below the room.
- Mood status label "happy" in muted color.
- Wave button "👋 wave" rendered in a bordered pill.

Framing reads clearly at the 2-column grid width.

## Temp Seam

A `YOLK_FRIENDCARD` seam (`FriendCardPreview` struct) was added to `RootView.swift` for screenshot verification, then fully removed. Final build is green with no seam present.

## Concerns

None. All APIs used exactly match the real signatures read from source files.
