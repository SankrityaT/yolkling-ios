# Yolk Room Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A home-screen widget (small + medium) showing the player's real yolk in its decorated room, with a one-time in-app nudge so people discover it.

**Architecture:** An App Group shares a small `WidgetSnapshot` (the existing `RoomSnapshot` + name) written by the app and read by the widget. The pure creature/room renderers are compiled into the widget target too, so it draws the real diorama. A `TimelineProvider` re-tints by time of day. Discoverability is a one-time home nudge + a permanent Profile row.

**Tech Stack:** Swift 6 (MainActor default isolation), SwiftUI, WidgetKit, SwiftData, xcodegen.

## Global Constraints

- iOS 18.0 target; Swift 6 strict concurrency (MainActor default isolation).
- SwiftData migration-safe: only OPTIONAL or DEFAULTED `@Model` properties.
- NO em dashes in user-facing copy. Warm, lowercase-ok voice matching existing strings.
- No new third-party dependencies.
- **No git** in this project: no commit steps. Each task gate is (a) compiles clean, (b) visual/behavioral verification via a `YOLK_*` seam or an App-Group read.
- **No XCTest** (codebase convention): verification is build + screenshot seams, not unit tests.
- **App Group id:** `group.com.Sankritya.Yolkling` (exact). It works in the SIMULATOR with no provisioning. A real device additionally needs this group registered in the Apple Developer portal under the team (logistics, out of scope for this plan).
- Building the `Yolkling` scheme builds the app AND embeds the `YolklingWidgets` extension, so one build covers both targets.

### Devices (already created; never erase/uninstall)
- Yolk-SE `8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1` (iOS 26.5). App installed here.
- Yolk-ProMax `9A3F2A47-5868-4956-B3AB-7531342B9347` (iOS 26.5).
HARD RULE: never `simctl uninstall`/`erase`/delete a device. `install` (overwrite) + `screenshot` only.

### Build + verify commands
Regenerate after project.yml or added/deleted files:
```bash
cd /Users/sankiii/iOSLocal/yolkling && xcodegen generate
```
Build (gate for every task; builds app + widget):
```bash
cd /Users/sankiii/iOSLocal/yolkling && \
xcodebuild -scheme Yolkling \
  -destination 'platform=iOS Simulator,id=8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1' \
  -derivedDataPath build/DD build 2>&1 | tail -25
```
Expected: `** BUILD SUCCEEDED **`

Screenshot a `YOLK_*` seam on Yolk-SE:
```bash
SE=8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1
xcrun simctl install "$SE" build/DD/Build/Products/Debug-iphonesimulator/Yolkling.app
SIMCTL_CHILD_YOLK_FOO=1 xcrun simctl launch --terminate-running-process "$SE" com.Sankritya.Yolkling
sleep 4; xcrun simctl io "$SE" screenshot /tmp/out.png
```
Then Read the PNG. (Env is passed via the `SIMCTL_CHILD_` prefix, NOT `--setenv`.)

---

## File structure

Create:
- `Core/Widget/WidgetSnapshot.swift` (shared by app + widget) — the Codable snapshot,
  App Group suite name + key constants, `read()`/`write(_:)` helpers. Single source of
  the shared contract.
- `Core/Widget/WidgetPublisher.swift` (app) — builds a `WidgetSnapshot` from the live
  player/wallet/wardrobe and writes it + reloads timelines.
- `YolklingWidgets/YolkRoomWidget.swift` (widget) — widget, `Provider`, `Entry`,
  entry view (small + medium), empty state.
- `Features/Widget/WidgetHowToView.swift` (app) — the how-to sheet (nudge + Profile).

Modify:
- `project.yml` — App Group on both targets; add renderer dirs + `WidgetSnapshot.swift`
  + `SocialModels.swift` to the widget sources.
- `Yolkling/Yolkling.entitlements` (+ a widget entitlements file) — the App Group.
- `YolklingWidgets/YolklingWidgetBundle.swift` — register `YolkRoomWidget`.
- `Core/Persistence/Player.swift` — add `widgetNudgeShown: Bool = false`.
- `Features/Home/HomeView.swift` — publish on look changes; show the one-time nudge.
- `Features/Profile/ProfileView.swift` — "Home screen widget" row.
- `App/RootView.swift` — a temporary `YOLK_WIDGET` seam for screenshotting (added in
  Task 2, removed at end of Task 2).

---

### Task 1: App Group + shared renderer plumbing (both targets compile)

This is the riskiest task (cross-target compile + entitlements). It isolates that risk.

**Files:**
- Create: `Core/Widget/WidgetSnapshot.swift`
- Modify: `project.yml`, `Yolkling/Yolkling.entitlements`, and a widget entitlements file.

**Interfaces:**
- Produces:
  - `enum WidgetShare { static let appGroup = "group.com.Sankritya.Yolkling"; static let key = "yolk.widget.snapshot" }`
  - `struct WidgetSnapshot: Codable, Sendable { var name: String; var room: RoomSnapshot }`
  - `extension WidgetSnapshot { static func read() -> WidgetSnapshot?; func write() }`

- [ ] **Step 1: Create `Core/Widget/WidgetSnapshot.swift`**

```swift
import Foundation

/// The contract shared between the app (writer) and the widget (reader) over the
/// App Group. Pure value type; carries the same RoomSnapshot friends use to render
/// a room, plus the yolk's name.
enum WidgetShare {
    static let appGroup = "group.com.Sankritya.Yolkling"
    static let key = "yolk.widget.snapshot"
    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }
}

struct WidgetSnapshot: Codable, Sendable {
    var name: String
    var room: RoomSnapshot

    /// The latest snapshot the app published, or nil if none yet.
    static func read() -> WidgetSnapshot? {
        guard let data = WidgetShare.defaults?.data(forKey: WidgetShare.key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Persist to the shared container for the widget to read.
    func write() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        WidgetShare.defaults?.set(data, forKey: WidgetShare.key)
    }
}
```

- [ ] **Step 2: Add the App Group entitlement to the app**

Read `Yolkling/Yolkling.entitlements`. Add (merge into the existing plist dict) the App Groups key:
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.Sankritya.Yolkling</string>
</array>
```

- [ ] **Step 3: Give the widget target the App Group + the shared sources**

Read `project.yml`. For the `YolklingWidgets` target:
1. Ensure it has a `CODE_SIGN_ENTITLEMENTS` pointing at a widget entitlements file (e.g. `YolklingWidgets/YolklingWidgets.entitlements`); create that file with the same App Groups array as Step 2 if it does not exist.
2. Add these to the widget target's `sources` list (alongside the existing `YolklingWidgets` path) so the renderers + the shared contract compile into the extension:
   ```yaml
   - Yolkling/Core/DesignSystem
   - Yolkling/Core/Creature
   - Yolkling/Core/Cosmetics
   - Yolkling/Core/Rooms
   - Yolkling/Core/Widget
   - Yolkling/Core/Networking/SocialModels.swift
   ```
   (Match the existing path style in project.yml; the app target keeps compiling these too via its own broad source path. Dual membership is intended.)
3. Add `Yolkling/Core/Widget` to the APP target's sources too if the app's source globbing does not already include it (it should, since it globs `Yolkling`); confirm by building.

- [ ] **Step 4: Regenerate + build BOTH targets**

```bash
cd /Users/sankiii/iOSLocal/yolkling && xcodegen generate
```
Then the standard build. Expected: `** BUILD SUCCEEDED **`.
If the WIDGET fails to compile because a renderer file pulls in an app-only symbol
(SwiftData, networking, Haptics, InstallID, etc.), identify the offending file from the
error and EITHER add its small dependency to the widget sources OR, if it is not needed
for rendering, exclude just that file. Document any exclusion in the report. Do not pull
SwiftData or networking into the widget.

- [ ] **Step 5: Confirm the App Group round-trips (quick seam)**

Temporarily add to `App/RootView.swift` (near the other `YOLK_*` seams), to prove the shared store works:
```swift
} else if ProcessInfo.processInfo.environment["YOLK_GROUPCHECK"] != nil {
    let ok = WidgetShare.defaults != nil
    Text(ok ? "app group OK" : "app group MISSING").padding()
        .onAppear {
            WidgetSnapshot(name: "Test", room: SocialPreviewRoom.sample).write()
        }
```
(If `SocialPreviewRoom.sample` does not exist, inline a `RoomSnapshot(...)` literal with a colour + a couple of decor ids.) Build, run with `YOLK_GROUPCHECK=1`, screenshot, confirm "app group OK". Then REMOVE this seam and rebuild green.

---

### Task 2: The widget (Provider + entry view, small + medium)

**Files:**
- Create: `YolklingWidgets/YolkRoomWidget.swift`
- Modify: `YolklingWidgets/YolklingWidgetBundle.swift`, `App/RootView.swift` (temporary seam)

**Interfaces:**
- Consumes: `WidgetSnapshot.read()`, `RoomSnapshot` (its `.vibe`, `.theme`, `.decor`,
  `.outfit`, `.expression`), `RoomView`, `YolkExpression.phase(forHour:)`,
  `RoomThemes.cozy`, `Vibe.yolk`.
- Produces: `struct YolkRoomWidget: Widget`; a `RoomView`-based entry view.

- [ ] **Step 1: Create `YolklingWidgets/YolkRoomWidget.swift`**

```swift
import WidgetKit
import SwiftUI

struct YolkEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let phase: YolkExpression.DayPhase
}

struct YolkRoomProvider: TimelineProvider {
    func placeholder(in context: Context) -> YolkEntry {
        YolkEntry(date: Date(), snapshot: nil, phase: .day)
    }
    func getSnapshot(in context: Context, completion: @escaping (YolkEntry) -> Void) {
        completion(YolkEntry(date: Date(), snapshot: WidgetSnapshot.read(),
                             phase: YolkExpression.phase(forHour: Calendar.current.component(.hour, from: Date()))))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<YolkEntry>) -> Void) {
        let snap = WidgetSnapshot.read()
        let cal = Calendar.current
        let now = Date()
        // One entry now, then one at each of the next phase boundaries over ~24h so the
        // room re-tints + the yolk gets sleepy at night without the app running.
        var entries: [YolkEntry] = []
        let hours = [0, 6, 11, 17, 21]   // boundary hours that change the day phase
        var dates: [Date] = [now]
        for dayOffset in 0...1 {
            for h in hours {
                if let d = cal.date(bySettingHour: h, minute: 0, second: 0,
                                    of: cal.date(byAdding: .day, value: dayOffset, to: now) ?? now), d > now {
                    dates.append(d)
                }
            }
        }
        for d in dates.sorted() {
            entries.append(YolkEntry(date: d, snapshot: snap,
                                     phase: YolkExpression.phase(forHour: cal.component(.hour, from: d))))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct YolkRoomEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: YolkEntry

    private var room: RoomSnapshot? { entry.snapshot?.room }
    private var theme: RoomTheme { room?.theme ?? RoomThemes.cozy }
    private var vibe: Vibe { room?.vibe ?? .yolk }
    private var expression: YolkExpression {
        let base = room?.expression ?? YolkExpression.content
        return base.atPhase(entry.phase, sleptWell: false)
    }

    var body: some View {
        GeometryReader { geo in
            // Render the real diorama, scaled to fill the widget. Small crops tighter on
            // the yolk; medium shows more room.
            let scale = family == .systemSmall ? geo.size.height / (geo.size.height * 0.0) : 1.0
            RoomView(vibe: vibe, expression: expression, theme: theme,
                     outfit: room?.outfit ?? [], decor: room?.decor ?? [])
                .scaleEffect(family == .systemSmall ? 1.25 : 1.0)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .overlay(alignment: .bottom) {
                    if entry.snapshot == nil {
                        Text("open yolkling").font(.caption2).foregroundStyle(.secondary).padding(4)
                    }
                }
        }
        .containerBackground(for: .widget) { theme.wall }   // use the room wall as the bg
    }
}

struct YolkRoomWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "YolkRoomWidget", provider: YolkRoomProvider()) { entry in
            YolkRoomEntryView(entry: entry)
        }
        .configurationDisplayName("Your Yolk")
        .description("your yolk, living in its little room.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```
NOTE for the implementer: the exact `RoomView` initializer parameters, `RoomSnapshot`'s
computed `vibe`/`theme`/`decor`/`outfit`/`expression`, `YolkExpression.phase(forHour:)`
+ `.atPhase(_:sleptWell:)`, and `RoomTheme`'s background property name (used in
`containerBackground`) must be read from the real code and matched exactly. The
`scale`/`scaleEffect` framing is a starting point: tune from the screenshot so the yolk
is nicely centered and the room reads at each size. Remove the dead `scale` let if unused.

- [ ] **Step 2: Register it in the bundle**

Edit `YolklingWidgets/YolklingWidgetBundle.swift`:
```swift
@main
struct YolklingWidgetBundle: WidgetBundle {
    var body: some Widget {
        YolkRoomWidget()
        FocusLiveActivity()
    }
}
```

- [ ] **Step 3: Add a temporary in-app render seam**

simctl cannot place home-screen widgets, so render the entry view in-app to screenshot.
Add to `App/RootView.swift` near the other seams:
```swift
} else if ProcessInfo.processInfo.environment["YOLK_WIDGET"] != nil {
    let sample = WidgetSnapshot(name: "Sunny", room: SocialPreviewRoom.sample)
    VStack(spacing: 24) {
        YolkRoomEntryView(entry: YolkEntry(date: Date(), snapshot: sample, phase: .day))
            .frame(width: 170, height: 170).clipShape(RoundedRectangle(cornerRadius: 22))   // small
        YolkRoomEntryView(entry: YolkEntry(date: Date(), snapshot: sample, phase: .evening))
            .frame(width: 360, height: 170).clipShape(RoundedRectangle(cornerRadius: 22))   // medium
        YolkRoomEntryView(entry: YolkEntry(date: Date(), snapshot: nil, phase: .night))
            .frame(width: 170, height: 170).clipShape(RoundedRectangle(cornerRadius: 22))   // empty state
    }.padding().background(YolkColor.shell.ignoresSafeArea())
```
Use a real `RoomSnapshot` sample (reuse the one from Task 1, or `SocialPreview` in
`RootView.swift` already has a `RoomSnapshot` literal for "sunny" — reuse that exact
literal). `YolkEntry`/`YolkRoomEntryView` are in the widget target; if RootView (app
target) cannot see them, move the small struct definitions you need into a file shared
with the app target, OR replicate a minimal preview inline. Simplest: this seam may
build the snapshot and show `RoomView(...)` directly with the same framing if the widget
types are not visible to the app target. Note your choice in the report.

- [ ] **Step 4: Regenerate + build + screenshot**

Build. Then run the `YOLK_WIDGET` seam on Yolk-SE, screenshot to `/tmp/task2-widget.png`,
Read it. Confirm: small shows the yolk centered in its room, medium shows a wider room,
empty state shows a default yolk + "open yolkling". Tune the framing/scale and re-shoot
until it looks good.

- [ ] **Step 5: Remove the temporary seam, rebuild green**

Remove the `YOLK_WIDGET` block from `RootView.swift`, rebuild, confirm `** BUILD SUCCEEDED **`.

---

### Task 3: Publish the snapshot from the app

**Files:**
- Create: `Core/Widget/WidgetPublisher.swift`
- Modify: `Features/Home/HomeView.swift`, `Core/Persistence/Player.swift`

**Interfaces:**
- Consumes: `WidgetSnapshot`, `WidgetCenter`, `HomeView.mySnapshot()` (already builds a
  `RoomSnapshot` for social), `heading` (the yolk name).
- Produces: `enum WidgetPublisher { static func publish(name: String, room: RoomSnapshot) }`
  and `Player.widgetNudgeShown: Bool`.

- [ ] **Step 1: Create `Core/Widget/WidgetPublisher.swift`**

```swift
import WidgetKit

/// Writes the current look to the App Group and asks the widget to reload. Best-effort.
enum WidgetPublisher {
    static func publish(name: String, room: RoomSnapshot) {
        WidgetSnapshot(name: name, room: room).write()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

- [ ] **Step 2: Call it where the look changes (HomeView)**

`HomeView` already has `mySnapshot() -> RoomSnapshot` (used for social) and `heading`.
Add a helper and call it from `persist()`, `applyColor(...)`, and `checkIn(...)`:
```swift
private func publishWidget() {
    WidgetPublisher.publish(name: heading, room: mySnapshot())
}
```
Add `publishWidget()` to the end of `persist()`; and at the end of `applyColor(...)`
and `checkIn(...)` (after their `try? context.save()` / `persist()`), so colour and mood
changes refresh the widget too. (persist() already runs on most changes; the extra two
cover the paths that do not route through persist().)

- [ ] **Step 3: Add the nudge flag to Player**

In `Core/Persistence/Player.swift`, alongside the other optional/defaulted fields:
```swift
var widgetNudgeShown: Bool = false
```

- [ ] **Step 4: Build + verify the write**

Build. Then launch the app normally on Yolk-SE (no seam) so `persist()`/`onAppear` runs
and publishes, wait, then dump the App Group value:
```bash
xcrun simctl launch --terminate-running-process "$SE" com.Sankritya.Yolkling; sleep 4
# The app-group container lives under the app's data container; confirm the key exists:
xcrun simctl spawn "$SE" defaults read group.com.Sankritya.Yolkling 2>/dev/null | head
```
Expected: output containing `yolk.widget.snapshot` (a data blob). If the player is not
onboarded on this sim, complete onboarding once (or rely on a prior saved player) so a
snapshot is written. Note the result in the report.

---

### Task 4: Discoverability (one-time nudge + how-to + Profile row)

**Files:**
- Create: `Features/Widget/WidgetHowToView.swift`
- Modify: `Features/Home/HomeView.swift`, `Features/Profile/ProfileView.swift`

**Interfaces:**
- Consumes: `Player.widgetNudgeShown`, `placedByZone`/`placedDecor` (to know decor is
  placed), `WidgetHowToView`.
- Produces: `struct WidgetHowToView: View`.

- [ ] **Step 1: Create `Features/Widget/WidgetHowToView.swift`**

```swift
import SwiftUI

/// A short, warm how-to for adding the home screen widget. Shown from the one-time
/// home nudge and from a permanent Profile row.
struct WidgetHowToView: View {
    var onDone: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: YolkSpace.lg) {
            Text("put your yolk on your home screen")
                .font(YolkType.title).foregroundStyle(YolkColor.ink)
            step(1, "touch and hold an empty spot on your home screen until the apps jiggle.")
            step(2, "tap the + in the top corner, then search \"yolkling\".")
            step(3, "pick a size and add it. your yolk will be right there, living in its room.")
            Spacer()
            Button { dismiss(); onDone() } label: {
                Text("got it").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity).padding(.vertical, 14).background(YolkColor.ink, in: Capsule())
            }.buttonStyle(.plain)
        }
        .padding(YolkSpace.lg)
        .background(YolkColor.shell.ignoresSafeArea())
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: YolkSpace.md) {
            Text("\(n)").font(YolkType.body.weight(.bold)).foregroundStyle(YolkColor.shell)
                .frame(width: 28, height: 28).background(YolkColor.ink, in: Circle())
            Text(text).font(YolkType.body).foregroundStyle(YolkColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
```

- [ ] **Step 2: One-time home nudge**

In `HomeView`, add `@State private var showWidgetNudge = false` and `@State private var
showWidgetHowTo = false`. In the existing `.onAppear`, add a check (runs after migration):
```swift
private func maybeShowWidgetNudge() {
    guard let p = player, !p.widgetNudgeShown, !placedDecor.isEmpty else { return }
    showWidgetNudge = true
}
```
Render a small dismissible card (match the visual style of `weeklyChallengeCard`) in the
`todayPanel`, shown only when `showWidgetNudge`:
- copy: "put your yolk on your home screen" + a small "see how" button.
- "see how" sets `showWidgetHowTo = true`.
- an x dismiss sets `showWidgetNudge = false` and `player?.widgetNudgeShown = true; persist()`.
Add `.sheet(isPresented: $showWidgetHowTo) { WidgetHowToView { player?.widgetNudgeShown = true; showWidgetNudge = false; persist() } .presentationDetents([.medium]) }`.
Call `maybeShowWidgetNudge()` from `.onAppear`.

- [ ] **Step 3: Permanent Profile row**

In `Features/Profile/ProfileView.swift`, add a tappable row "Home screen widget" (match
the existing row style) with `@State private var showHowTo = false`, presenting
`WidgetHowToView()` in a sheet at `.medium`.

- [ ] **Step 4: Build + screenshot**

Build. To force the nudge for the screenshot, temporarily ensure a player with decor and
`widgetNudgeShown == false`. Easiest: add a one-off DEBUG seam line in
`applyScreenshotSeams()` that sets `showWidgetNudge = true` when `YOLK_WIDGETNUDGE` is set,
launch with `YOLK_VIBE=0 YOLK_WIDGETNUDGE=1`, screenshot `/tmp/task4-nudge.png`, Read it:
confirm the nudge card shows on home. Tap-open path: also screenshot the how-to via the
Profile row or a seam. Remove the temporary `YOLK_WIDGETNUDGE` seam after, rebuild green.

---

## Self-review

**Spec coverage:**
- App Group (both targets) -> Task 1. WidgetSnapshot contract -> Task 1. Shared renderer
  into widget -> Task 1 Step 3. Snapshot publish on look changes -> Task 3. Shared diorama
  render -> Task 2. Provider + time-of-day timeline -> Task 2 Step 1. small + medium ->
  Task 2 (`supportedFamilies` + framing). Empty state -> Task 2 entry view + Task 2 seam.
  Tap opens app -> StaticConfiguration default (no code needed; noted). One-time nudge ->
  Task 4 Steps 1-2. Permanent Profile row -> Task 4 Step 3. `widgetNudgeShown` -> Task 3
  Step 3 (created) + Task 4 (used). Verification seams -> each task.
- Deferred (large/Lock Screen/interactive, live animation, networking) -> not in any task.

**Placeholder scan:** Contract, publisher, how-to view, and bundle registration are exact.
The widget entry view + nudge card give structure + key code + the exact existing symbols
to read and match (RoomView init, RoomSnapshot computed props, RoomTheme bg name,
YolkExpression phase API), because those signatures are not all captured here; the
implementer MUST read them. The framing `scaleEffect` is explicitly a tune-from-screenshot
starting point. The `scale` let in the entry view is flagged for removal if unused.

**Type consistency:** `WidgetShare.appGroup`/`.key`/`.defaults`, `WidgetSnapshot{name,room}`
+ `read()`/`write()`, `WidgetPublisher.publish(name:room:)`, `Player.widgetNudgeShown`,
`YolkEntry`/`YolkRoomProvider`/`YolkRoomEntryView`/`YolkRoomWidget`, `WidgetHowToView`
are used consistently across tasks.

**Executor responsibilities (read before coding):**
- `Features/Room/RoomView.swift` — exact init params used in the entry view.
- `Core/Networking/SocialModels.swift` — `RoomSnapshot`'s computed `vibe`/`theme`/`decor`/
  `outfit`/`expression`; reuse the `SocialPreview` "sunny" `RoomSnapshot` literal in
  `RootView.swift` for samples.
- `Core/Creature/YolkExpression.swift` — `DayPhase`, `phase(forHour:)`, `atPhase(_:sleptWell:)`.
- `Core/Rooms/RoomThemes.swift` — `RoomTheme`'s background/wall colour property for
  `containerBackground`.
- `project.yml` — the exact `sources`/entitlements structure for the widget target.
