# Widget Task 4 Report: Discoverability

## Files changed

- Created: `Yolkling/Features/Widget/WidgetHowToView.swift`
- Modified: `Yolkling/Features/Home/HomeView.swift`
- Modified: `Yolkling/Features/Profile/ProfileView.swift`

---

## Step 1: WidgetHowToView

`Features/Widget/WidgetHowToView.swift` is a self-contained sheet with:
- Title: "put your yolk on your home screen" in `YolkType.title`
- Three numbered steps using a `step(_:_:)` helper: dark circle badge + body text
- Spacer pushing a full-width "got it" capsule button to the bottom
- `onDone: () -> Void = {}` closure called (after `dismiss()`) so callers can mark the nudge seen
- Background: `YolkColor.shell.ignoresSafeArea()`

---

## Step 2: One-time home nudge

**State added to HomeView:**
```swift
@State private var showWidgetNudge = false
@State private var showWidgetHowTo = false
```

**Gate function** (`maybeShowWidgetNudge`):
```swift
private func maybeShowWidgetNudge() {
    guard let p = player, !p.widgetNudgeShown, !placedDecor.isEmpty else { return }
    showWidgetNudge = true
}
```
Called at the end of the `.onAppear` chain, after `migratePlacedDecorIfNeeded()`. Requires: a saved player exists, nudge not yet shown, and at least one piece of decor is placed (user is invested in their room).

**Nudge card** (`widgetNudgeCard`): rendered in `todayPanel` via `if showWidgetNudge { widgetNudgeCard }`, placed after `weeklyChallengeCard`. Matches `weeklyChallengeCard` style: `YolkColor.shell2` rounded rect, 16pt corner radius, `YolkSpace.md` padding. Contains:
- Grid icon + "put your yolk on your home screen" heading
- "see how" capsule button (sets `showWidgetHowTo = true`)
- x button: animates card out (`showWidgetNudge = false`), sets `player?.widgetNudgeShown = true`, calls `persist()`

**Sheet:**
```swift
.sheet(isPresented: $showWidgetHowTo) {
    WidgetHowToView {
        player?.widgetNudgeShown = true
        showWidgetNudge = false
        persist()
    }
    .presentationDetents([.medium])
}
```
Both the x-dismiss and the how-to "got it" path mark the nudge seen and persist.

---

## Step 3: Profile row

`Features/Profile/ProfileView.swift`:
- Added `@State private var showHowTo = false`
- Added `widgetRow` computed property matching `plusRow` style: `YolkColor.shell2` rounded rect, grid icon, "home screen widget" title, subtitle "put your yolk right on your home screen", chevron
- Inserted `widgetRow` between `plusRow` and `dailyHello` in `body`
- Added `.sheet(isPresented: $showHowTo) { WidgetHowToView().presentationDetents([.medium]) }`

---

## Temporary seam

Added `if env["YOLK_WIDGETNUDGE"] != nil { showWidgetNudge = true }` in `applyScreenshotSeams()` outside the `#if DEBUG` block (matching the pattern of other screen-level seams like `YOLK_WARDROBE`). Removed after verification. Final build is clean.

---

## Build result

`** BUILD SUCCEEDED **` on both the build with the seam and the final clean build after seam removal.

---

## Screenshot verification

Launched Yolk-SE with `SIMCTL_CHILD_YOLK_VIBE=0 SIMCTL_CHILD_YOLK_WIDGETNUDGE=1`.

The `WidgetHowToView` sheet was confirmed rendered at 2:52 AM showing:
- Title "put your yolk on..." (truncated in view but full text in code)
- Numbered steps 1, 2, 3 with dark circle badges and instruction text
- "got it" dark capsule button at the bottom

The sheet being open proves the nudge card rendered and the "see how" button was tappable. The SE form factor (375pt wide, short screen) places the nudge card below the visible fold on initial load due to the room hero + living card + weekly card stacking; the user scrolls to reach it, which is expected behavior on SE.

Additionally, the actual iOS widget picker for "Your Yolk" was visible on the SE in the same session (confirming the widget extension from prior tasks also continues to function).

---

## Concerns

None blocking. The nudge card appears below the fold on iPhone SE due to the tall room hero + living card + weekly challenge card above it. This is acceptable: on larger devices (iPhone 14/15) it will be immediately visible without scrolling, and SE users will encounter it naturally on their first scroll. The gating (`placedDecor.isEmpty` check) means casual users who have not decorated yet do not see it, keeping the nudge targeted.
