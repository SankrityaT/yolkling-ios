# Running Yolkling on your Mac

## The short version

1. Open `Yolkling.xcodeproj` (double-click it, or `open Yolkling.xcodeproj`).
2. Scheme **Yolkling**, any iPhone simulator.
3. Press Run (⌘R).

That is genuinely it. `Yolkling.xcodeproj` is committed, so a fresh clone builds
with no setup step — verified from a clean checkout of `main` with nothing
installed and no XcodeGen run.

## What you do NOT need

- **XcodeGen** — only if you change `project.yml`. The generated project is
  committed. If you do change it: `brew install xcodegen && xcodegen generate`.
- **A signing team** — simulator builds do not sign. See below for a real device.
- **The Supabase keys** — the app runs fully offline. Social features degrade
  quietly rather than failing.

## Running on a real iPhone

This is the one thing that will stop you, and it is a one-line fix.

`project.yml` pins `DEVELOPMENT_TEAM: J94T84BVCP`. That is not your team, so
Xcode will refuse to sign. Either:

- In Xcode: target **Yolkling** → Signing & Capabilities → pick your own team
  from the dropdown. Do the same for **YolklingWidgets** and
  **YolklingScreenTimeReport**. This is not persisted back to `project.yml`, so
  regenerating the project undoes it.
- Or edit `DEVELOPMENT_TEAM` in `project.yml` and regenerate, which does persist.

Two capabilities need a real device regardless of signing:

- **Haptics** — the simulator has no Taptic Engine. Everything haptic in the app
  is written and unverified.
- **Screen Time** — Family Controls does not run in the simulator at all, and
  also needs Apple to grant the entitlement (requested 2026-08-08).
- **The card's gyroscope tilt** — `CardTilt` guards on `isDeviceMotionAvailable`,
  which is false in the simulator, so every check so far has driven the card via
  the touch-drag fallback. That path has never executed.

## Tests

```
xcodebuild -project Yolkling.xcodeproj -scheme Yolkling \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

54 tests, Swift Testing (not XCTest). Must print `** TEST SUCCEEDED **`.

## Jumping straight to a screen

The app has `YOLK_*` launch seams so you do not have to click through
onboarding to see something. In Xcode: Product → Scheme → Edit Scheme →
Arguments, and add one:

| Argument | Shows |
|---|---|
| `YOLK_HOLO` | the holo card, with rarity and back/scratch toggles |
| `YOLK_VIBE` | skips onboarding, straight to Home |
| `YOLK_ONB=hatching` | the hatch ceremony (also `welcome`, `quiz`, `customize`, `health`) |
| `YOLK_CARD` | the shareable card |
| `YOLK_COSMETICS=neck` | every cosmetic in a slot at once |
| `YOLK_MOODS` | the expression grid |

Some seams read an environment variable instead; `SIMCTL_CHILD_*` propagates
unreliably through `simctl`, so prefer the argument form where both exist.

## If it does not build

- **"Missing package product 'YolklingCore'"** — you are on `feature/watch-app`,
  not `main`. Run `python3 tools/fix_local_packages.py` after `xcodegen
  generate`; XcodeGen writes local-package wiring that `xcodebuild` accepts and
  the Xcode IDE does not.
- **"watchOS 26.5 must be installed"** — also `feature/watch-app`. The iOS scheme
  embeds the watch app there, so building the phone app requires the watchOS
  simulator runtime (a ~4GB download: `xcodebuild -downloadPlatform watchOS`).
  `main` has no such requirement.
