# Yolk Room Widget

Date: 2026-06-21
Status: Approved design, ready for implementation plan

## Problem

There is no home-screen widget. A live "your yolk in its decorated room" widget is
one of the highest-leverage retention + organic-marketing features for a creature
app (people screenshot their home screen), and it keeps the yolk present between
sessions. The widget extension today only ships a Focus Live Activity.

Two hard facts shape the design:
1. A widget runs in a separate process and cannot read the app's SwiftData `Player`.
   The app must publish a small snapshot to a shared App Group container.
2. Widgets are notoriously undiscovered. We must actively tell the user it exists.

## Goals

- A home-screen widget (small + medium) showing the player's real yolk in its real,
  decorated, themed room, updating its time-of-day tint on its own timeline.
- Tell the user the widget exists, at a good moment, without nagging.
- Reuse the existing renderers and `RoomSnapshot` (no new drawing code).

## Non-goals (YAGNI)

- Large widget, Lock Screen / StandBy widgets, interactive (AppIntent) widgets.
- Live animation in the widget (widgets render static frames; time-of-day via the
  timeline is enough).
- Any new networking. The snapshot is local, written by the app.

## Architecture

### 1. App Group (shared container)
Add an App Group `group.com.Sankritya.Yolkling` to BOTH targets (app + widget) in
`project.yml` entitlements. This is the only channel the two processes share.

### 2. Snapshot publish (app -> shared store)
`RoomSnapshot` already exists (`Core/Networking/SocialModels.swift`) and already
reconstructs a creature + room (colour, style, accent, pattern, founding id, mood,
theme, decor ids, outfit ids). The app writes a `WidgetSnapshot { name, room:
RoomSnapshot }` (Codable, JSON) into the App Group `UserDefaults(suiteName:)` and
calls `WidgetCenter.shared.reloadAllTimelines()` whenever the look changes:
- `HomeView.persist()` (covers decor/outfit/coins/streak/theme writes)
- `HomeView.applyColor(...)` (rare colour change)
- `HomeView.checkIn(...)` (mood change)
Best-effort, fire-and-forget; if the user is not onboarded there is simply no snapshot.

### 3. Shared renderer (the widget draws the REAL diorama)
The drawing code is pure SwiftUI with no SwiftData / networking / app-only deps
(verified: `Core/Creature`, `Core/Cosmetics`, `Core/Rooms`, `Core/DesignSystem` are
clean; the only "Player" token is a record-player decor function). These directories
plus `Core/Networking/SocialModels.swift` (for `RoomSnapshot`) are added to the
widget target's `sources` in `project.yml`, so the widget compiles the same
`RoomView` / `YolklingView` and draws a sharp diorama at any size. (Dual target
membership, not a separate framework, to keep xcodegen simple.)

## The widget

`YolkRoomWidget` (StaticConfiguration), registered in `YolklingWidgetBundle`
alongside the existing `FocusLiveActivity`.

- **TimelineProvider:** reads `WidgetSnapshot` from the App Group. Emits entries at
  the four time-of-day boundaries (morning / day / evening / night) for the next
  ~24h, so the room tint + the yolk's sleepiness update without the app running.
  Each entry carries the snapshot + the current `YolkExpression.DayPhase`.
- **Entry view:** renders `RoomView(vibe:, expression:, theme:, outfit:, decor:)`
  built from the snapshot, with the expression derived from mood + day phase (reuse
  `RoomSnapshot.expression` + `YolkExpression.atPhase`). Framed for:
  - `.systemSmall` — square crop centered on the yolk (room visible around it).
  - `.systemMedium` — wider framing showing more of the room.
- **Tap:** tapping the widget opens the app (system default for a StaticConfiguration
  widget). No custom URL scheme or routing for v1; it just launches Yolkling.
- **Empty state:** if no snapshot yet (not onboarded), render a default `.yolk` vibe
  in the `cozy` theme with a small "open yolkling" hint.

## Discoverability

- **One-time home nudge:** a small, dismissible card on the home screen ("put your
  yolk on your home screen") shown ONCE, the first time the player opens home AND has
  at least one decor placed (so the widget is worth showing). Tapping it opens a
  `WidgetHowToView` sheet with the 3-step add flow (long-press home screen -> tap +
  -> search "Yolkling" -> add). Dismiss or "got it" sets `Player.widgetNudgeShown =
  true`; never shown again.
- **Permanent entry:** a "Home screen widget" row in `ProfileView` that opens the same
  `WidgetHowToView`, so it is always findable even after the nudge is dismissed.
- Gate: `Player.widgetNudgeShown: Bool` (optional/defaulted false, migration-safe).

## Files

Create:
- `Core/Widget/WidgetSnapshot.swift` (shared by both targets) — the Codable snapshot,
  the App Group suite name + key constants, and `read()` / `write(_:)` helpers. Single
  source of the shared contract.
- `YolklingWidgets/YolkRoomWidget.swift` — widget, `Provider`, `Entry`, entry view
  (small + medium framing), empty state.
- `Features/Widget/WidgetHowToView.swift` — the how-to sheet (used by nudge + Profile).

Modify:
- `project.yml` — App Group entitlement on both targets; add renderer dirs +
  `SocialModels.swift` + `Core/Widget/WidgetSnapshot.swift` to the widget sources.
- `Yolkling/Yolkling.entitlements` — add the App Group.
- `YolklingWidgets/YolklingWidgetBundle.swift` — register `YolkRoomWidget`.
- `Core/Persistence/Player.swift` — add `widgetNudgeShown: Bool = false`.
- `Features/Home/HomeView.swift` — call the publisher in `persist()`/`applyColor`/
  `checkIn`; show the one-time widget nudge when eligible.
- `Features/Profile/ProfileView.swift` — add the "Home screen widget" row.

## Data / migration

- `Player.widgetNudgeShown: Bool = false` — defaulted, SwiftData-migration-safe.
- App Group entitlement is additive; no data migration.
- The shared snapshot is best-effort; a missing/old snapshot just shows the last
  known or the empty state. Never blocks the app.

## Testing / verification

- Build green for BOTH targets (app + widget) on Yolk-SE.
- Render the widget entry view at small + medium via a SwiftUI `#Preview` and a
  TEMPORARY in-app RootView seam (`YOLK_WIDGET`) so it can be screenshotted (simctl
  cannot place real home-screen widgets); confirm the diorama renders, reflects a
  sample snapshot's decor/outfit/theme, and the empty state renders. Remove the seam
  after.
- Confirm the nudge appears once (with decor placed), opens the how-to, and does not
  reappear after `widgetNudgeShown`.
- No em dashes in user-facing copy. No new dependencies.

## Open / deferred

- Large + Lock Screen + interactive widgets (v2).
- A "tap a friend's widget to visit" idea (far future).
