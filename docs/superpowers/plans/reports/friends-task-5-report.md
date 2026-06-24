# Friends Tab Redesign — Task 5 Report

## Component signature

```swift
struct WhileYouWereAwayStrip: View {
    let waves: [Wave]
    let visits: [Visit]
    let redecorated: [Friend]
    var onTap: (String) -> Void
}
```

## Line formats

- Per wave: `👋  <wave.senderName> waved` (onTap: wave.from_id)
- Per visit: `🏠  <visit.visitorName> visited your room` (onTap: visit.visitor_id)
- Per redecorated friend: `✨  <friend.displayName> redecorated` (onTap: friend.user_id)
- Rows capped at 6 total (waves first, then visits, then redecorated).
- No counts, no em dashes, warm lowercase title "while you were away".

## Empty-state behavior

When all three arrays are empty, `rows` is empty and the `body` returns `EmptyView` — no card, no space, nothing rendered.

## Card style

Matches `weeklyChallengeCard`: `.background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 16))`, `.padding(.vertical, 11).padding(.horizontal, YolkSpace.md)`, `.padding(.horizontal, YolkSpace.lg)` outer.

## Build result

`** BUILD SUCCEEDED **` on Yolk-ProMax `9A3F2A47-5868-4956-B3AB-7531342B9347` (iOS 26.5), both with seam and after seam removal.

## Screenshot outcome

- `/tmp/task5-strip.png` — strip visible with 4 lines: "Maya waved", "Leo waved", "Rio visited your room", "Sunny redecorated". Card style matches design system.
- `/tmp/task5-strip-empty.png` — no card rendered; only the debug toggle label visible, confirming `EmptyView` path.

## Seam removed

`YOLK_AWAYSTRIP` branch and `AwayStripPreview` struct removed from `RootView.swift`. Final build green with no trace of the seam.

## Files changed

- **Created:** `Yolkling/Features/Social/WhileYouWereAwayStrip.swift`
- **Temp-modified then restored:** `Yolkling/App/RootView.swift` (seam added and removed; net diff = zero)
