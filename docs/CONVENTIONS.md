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

- **`Core/DesignSystem` is compiled into the WIDGET extension.** Do NOT put code that uses
  `Haptics`, UIKit, or anything not widget-safe in `Core/DesignSystem`. App-only interactive
  controls go in `Core/Components/` (app target globs all of `Yolkling/`; the widget only
  compiles specific Core subdirs).
- The renderers (`Core/Creature`, `Core/Cosmetics`, `Core/Rooms`, `Core/DesignSystem`,
  `Core/Networking/SocialModels.swift`) are pure (no SwiftData / networking) so they can be
  shared into the widget. Keep them that way.
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
- **Build all four targets**, not just the app: `Yolkling`, `YolklingWidgets`,
  `YolklingScreenTimeReport`, `YolklingTests`. The widget cherry-picks sources out of
  `Yolkling/`, so a design-system change can break it while the app still compiles.
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
