# YolklingCore

The shared creature layer, as a local Swift package. Everything needed to draw a
yolkling and reason about its identity, and nothing else:

```
Sources/YolklingCore/
  Creature/       Vibe, Mood, YolkExpression, YolklingView (the renderer),
                  YolkMotion, CreatureParts, CreatureStyle, BodyPattern,
                  Species catalog (+ Cozy/Garden/Ocean families), SpeciesSet,
                  FoundingFlair, TrustStage, CareEngines (streak + discovery)
  Cosmetics/      Cosmetic + catalog, CosmeticView (the ~80-item renderer),
                  spring seasonal items, RarityAura, ColorShop (rare colours)
  DesignSystem/   YolkColor (+ Color(hex:)), YolkSpace, YolkType, BrandFonts
  Creation/       HatchedCreature, CreaturePalette (colour math + name ideas)
  Watch/          WatchCreatureSnapshot, the phone -> watch sync contract
```

## Why a package

Before this package, `YolklingWidgets` cherry-picked these same files out of
`Yolkling/` by path in `project.yml`, which compiled the creature twice and made
"what can the widget see" a matter of convention. The Apple Watch app
(`YolklingWatch`) would have needed a third copy. Now all three targets (and
`YolklingTests`) depend on this one product.

The boundary is also a firewall: this package must never import RevenueCat,
FamilyControls/DeviceActivity, HealthKit, SwiftData, or the Supabase client.
Those are iOS-app concerns, and the watch and widget builds must never see them.
If a file needs any of those, it belongs in `Yolkling/`, not here.

## Who depends on it

| Target                    | Uses it for                                        |
|---------------------------|----------------------------------------------------|
| `Yolkling` (iOS app)      | everything creature-shaped                          |
| `YolklingWidgets`         | rendering the room widget's creature                |
| `YolklingWatch`           | its entire UI + the `WatchCreatureSnapshot` contract |
| `YolklingTests`           | species / streak / trust / wallet suites            |
| `YolklingScreenTimeReport`| nothing (deliberately)                              |

## Rules

- **Only SwiftUI / Foundation / CoreText imports.** Pure value types and pure
  rendering. That is what makes it buildable for watchOS (and portable later).
- **Build settings mirror the app.** `Package.swift` sets
  `defaultIsolation(MainActor.self)` + the approachable-concurrency upcoming
  features to match `SWIFT_DEFAULT_ACTOR_ISOLATION` / `SWIFT_APPROACHABLE_CONCURRENCY`
  in `project.yml`, so moving a file across the boundary never changes how it
  compiles. If one changes, change the other.
- **Access control:** anything the app touches must be `public`; the renderer's
  internals (motion math, shapes, per-cosmetic drawing) stay internal. Structs
  the app *constructs* need an explicit `public init` (memberwise inits are never
  public) — `Species`, `Vibe`, `RarityAura`, `HatchedCreature` already have one.
- **Fonts stay in the app bundle.** `BrandFonts.register()` reads `Bundle.main`;
  the watch app does not bundle the .ttf files, so `YolkType` falls back to the
  system rounded face there. Bundle + register the fonts in `YolklingWatch` if
  brand type on the wrist ever matters.

## Building it alone

```sh
cd Packages/YolklingCore
xcodebuild -scheme YolklingCore -destination 'generic/platform=iOS Simulator' build
xcodebuild -scheme YolklingCore -destination 'generic/platform=watchOS Simulator' build
```
