# Yolkling project conventions (READ BEFORE CODING / before writing any plan)

These are standing rules. They MUST be copied into every implementation plan's Global
Constraints and into every subagent dispatch, because they keep getting lost across
context compaction. If you are an agent picking this project back up, read this first.

## UI

- **Segmented controls / tabs / toggles: use `YolkSegmented` (Core/Components/YolkSegmented.swift).**
  NEVER use SwiftUI's `Picker(...).pickerStyle(.segmented)`. The system segmented control
  does not match the Yolkling look. Every aisle / tab / All|Owned style switch is a custom
  pill row. (This rule has been violated repeatedly after compaction. Do not.)
- **NO em dashes (or spaced hyphens ` - `) in ANY user-facing copy.** Warm, lowercase-ok
  voice. The only `-` allowed is in `// MARK: -` code comments. No AI-tells.
- Match the existing brand: `YolkColor`, `YolkSpace`, `YolkType`, rounded pills, `Haptics.shared`.

## Architecture / build

- **After every `xcodegen generate`, run `python3 tools/fix_local_packages.py`.**
  XcodeGen wires local packages in a shape `xcodebuild` accepts but the Xcode IDE does
  not (every in-IDE build fails instantly with "Missing package product 'YolklingCore'"
  while the CLI builds fine). The script rewrites the wiring into the shape native Xcode
  writes. If the project was open in Xcode during regeneration, close and reopen it —
  Xcode never refreshes its package graph from an in-place reload.
- **The creature layer lives in `Packages/YolklingCore`** (local SPM package: Creature,
  Cosmetics, colour/spacing/type tokens, CreaturePalette, the watch sync contract). The
  app, the widget, the watch app and the tests all depend on it. It must NEVER import
  RevenueCat, FamilyControls, HealthKit, SwiftData, or the Supabase client — the watch and
  widget builds must never see those. New shared creature code goes there and needs
  `public` on anything targets touch (plus an explicit `public init` on structs they
  construct). See `Packages/YolklingCore/README.md`.
- **`Core/Rooms`, `Core/Widget`, `Core/Networking/SocialModels.swift` and `RoomView.swift`
  are still cherry-picked into the WIDGET extension** by path in `project.yml`. Keep them
  pure (no SwiftData / networking / Haptics / RevenueCat). App-only interactive controls go
  in `Core/Components/` (app target globs all of `Yolkling/`).
- SwiftData `@Model` (Player) changes must be OPTIONAL or DEFAULTED (migration-safe).

## Verification

- **Swift Testing** (`import Testing`, `@Test`/`@Suite`), in the `YolklingTests` target.
  Not XCTest — this file said "no XCTest in this project" long enough that the sentence
  was read as "no tests", which was wrong in both directions. Run with
  `xcodebuild ... -scheme Yolkling test`; it must say `** TEST SUCCEEDED **`.
  Cover pure logic (wallet arithmetic, streak rules, snapshot decoding). Views are
  covered by the screenshot seams instead, not by tests.
- Verify with `xcodebuild` (must say `** BUILD SUCCEEDED **`) plus the `YOLK_*` screenshot
  seams in `App/RootView.swift` + `HomeView.applyScreenshotSeams()`.
- **Build all five targets**, not just the app: `Yolkling`, `YolklingWidgets`,
  `YolklingScreenTimeReport`, `YolklingWatch`, `YolklingTests`. The widget still
  cherry-picks some sources out of `Yolkling/`, so a Rooms/Widget change can break it while
  the app compiles; a YolklingCore change can break the watch the same way (the `Yolkling`
  scheme covers all of them via dependencies). The watch app builds with
  `-destination 'generic/platform=watchOS Simulator'` (see docs/WATCH_APP.md).
- **Haptics and Screen Time cannot be verified here.** Neither runs on the simulator.
  Anything touching them is written-and-unverified until it has been on a device; say so
  rather than reporting it as working.
- SourceKit cross-file "cannot find type X" diagnostics are stale-index NOISE here; trust
  `xcodebuild`.
- Build/screenshot devices (never erase/uninstall): Yolk-SE `8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1`,
  Yolk-ProMax `9A3F2A47-5868-4956-B3AB-7531342B9347` (iOS 26.5). Use whichever the user is NOT on.

## Backend

- Supabase project `vlucekvrdxvpkvbizabz`. Migrations via Management API query endpoint with
  the PAT in `yolkling-app/.env.local` (`SUPABASE_ACCESS_TOKEN`, a SECRET; never echo). The
  connected Supabase MCP is a DIFFERENT org, do not use it for this project.
