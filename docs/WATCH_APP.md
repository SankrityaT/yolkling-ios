# The Apple Watch app

`YolklingWatch/` is a single-target watchOS app (the app/extension split died
with watchOS 9), embedded in the iOS app via the target dependency in
`project.yml`, so installing Yolkling offers the watch app automatically.

v1 scope, deliberately tiny: your creature on your wrist — same renderer as the
phone — with its name and the trust line under it. Tapping pets it. Shop,
social, subscription, onboarding all stay on the phone.

## How it gets its data (and why not the App Group)

The home-screen widget shares state through the App Group, but **App Groups do
not cross devices** — the watch is a separate computer. State crosses over
WatchConnectivity instead:

```
HomeView.publishWidget()                            (fires on every persist())
  ├── WidgetPublisher.publish(...)                  App Group -> widget (unchanged)
  └── WatchPublisher.shared.publish(snapshot)       Yolkling/Core/Watch/WatchPublisher.swift
        └── WCSession.updateApplicationContext      latest-state-wins, delivered
                                                    even while the watch app is closed
              └── WatchSyncModel (watch side)       YolklingWatch/WatchSyncModel.swift
                    caches the last snapshot in UserDefaults so launch is instant
```

The payload is `WatchCreatureSnapshot` (in `Packages/YolklingCore`, `Watch/`),
a Codable value mirroring `RoomSnapshot`'s creature fields: colour/style/pattern
hexes + raws, founding id, mood, outfit ids, trust, streak. Both sides speak the
same type, and its decode is lenient (missing fields degrade to the default
yolk) because the phone and watch app versions can skew after an update.
`updateApplicationContext` was chosen over `sendMessage`/`transferUserInfo`
because the creature's look is pure current-state: only the latest matters, and
the system delivers it on its own schedule without the watch app running.

## Targets and files

| Piece | Where |
|-------|-------|
| Watch target definition | `project.yml` (`YolklingWatch`, platform watchOS, deployment 11.0) |
| App entry + UI | `YolklingWatch/YolklingWatchApp.swift`, `WatchHomeView.swift` |
| Receiving sync | `YolklingWatch/WatchSyncModel.swift` |
| Sending sync (phone) | `Yolkling/Core/Watch/WatchPublisher.swift`, hooked in `HomeView.publishWidget()` |
| Shared contract + renderer | `Packages/YolklingCore` (see its README) |

Bundle id is `com.Sankritya.Yolkling.watchkitapp` with
`WKCompanionAppBundleIdentifier` pointing at the phone app; both are generated
into the Info.plist by `project.yml` settings. The base project settings pin
`SUPPORTED_PLATFORMS` to iphoneos, so the watch target overrides it — keep that
override if you touch the settings.

## Building / running

Regenerate after any `project.yml` change (`xcodegen generate`), then:

```sh
xcodebuild -project Yolkling.xcodeproj -scheme YolklingWatch \
  -destination 'generic/platform=watchOS Simulator' build
```

Building the `Yolkling` scheme also builds + embeds the watch app. To see the
two talk, run the iOS app on an iPhone simulator that has a paired watch
simulator, then run YolklingWatch on the watch half of the pair; the snapshot
lands after the phone's first `persist()`.

## Known gaps (v1)

- **No app icon art yet** — `Assets.xcassets/AppIcon.appiconset` has an empty
  1024 slot; fine on simulator, needed for TestFlight.
- **Brand fonts don't render on the watch** (system rounded fallback); the .ttf
  files live in the app bundle only. Bundle + register them in the watch target
  if it matters.
- **No complications.** The natural next step: a WidgetKit extension on the
  watch target with `accessoryCircular`/`accessoryRectangular` families reading
  the cached snapshot. The `frozenAt` seam in `YolklingView` exists precisely so
  non-animating surfaces can render the creature.
- **Nothing flows watch -> phone yet.** When a watch-side action (a check-in,
  a focus start) exists, send it with `WCSession.sendMessage` and let the phone
  stay authoritative — the watch never mutates trust/coins/streak itself.
