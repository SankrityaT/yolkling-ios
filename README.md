# Yolkling

A virtual pet for iPhone that grows when you take care of yourself in real life.
Your steps, your sleep and the time you spend off your phone feed it. A bad day
makes it sleepy, never sick, and it waits for you.

[Yolkling on the App Store](https://apps.apple.com/us/app/yolkling-self-care-pet/id6804105200) · [yolkling.com](https://yolkling.com)

Built for RevenueCat Shipaton 2026 by Sankritya Thakur and Havishea Vannemreddy.

## What is in here

- `Yolkling/` — the app. SwiftUI and SwiftData, Swift 6.
- `Packages/YolklingCore/` — the creature renderer. Every creature is drawn in
  code from a recipe of parts, patterns and palettes; there are no image assets.
- `DeviceActivityMonitor/` — the Screen Time extension.
- `YolklingTests/` — the test suite (Swift Testing).
- `docs/sql/` — the Supabase schema and functions behind friends, visits and the wallet.
- `CLAIMS.md` — every promise we make, checked against what the app actually does.
- `ARCHITECTURE.md`, `RUNNING.md` — how it fits together and how to run it.

## Running it

The Xcode project is generated from `project.yml`:

```
brew install xcodegen
xcodegen generate
open Yolkling.xcodeproj
```

Pick the `Yolkling` scheme and an iOS 18 simulator. HealthKit and Screen Time
need a real device. See `RUNNING.md` for the details.

## Licence

MIT. See `LICENSE`. The bundled typefaces (Onest, DM Sans, DM Mono) are under
their own SIL Open Font Licence.
