# Task 2 Report: Persist placement + first-load migration

## Status

DONE

## File changed

`Yolkling/Core/Persistence/Player.swift` (only file modified)

## Properties and methods added

### Stored property (placed after `tutorialSeen`, before `createdAt`)

```swift
/// Decorate-mode placement: zone.rawValue -> decor id. Optional + defaulted nil so
/// it is SwiftData migration-safe. nil means "not migrated yet" (see placedDecor()).
var placedDecorByZone: [String: String]? = nil
```

### Resolver + migration (added inside the `@Model` class body, after `init`)

```swift
@MainActor
func placedDecor(ownedIDs: Set<String>) -> [RoomDecor.Zone: RoomDecor]
```

On first call (when `placedDecorByZone == nil`): iterates `RoomDecorCatalog.all`, picks the highest-rarity owned piece per zone (using `d.zone` and `Rarity.rank` from Task 1), writes the result back into `placedDecorByZone`, and returns the map. On subsequent calls: decodes the stored dict, validates each entry against `ownedIDs`, and returns the filtered map.

```swift
@MainActor
func setDecor(_ id: String?, in zone: RoomDecor.Zone)
```

Mutates `placedDecorByZone` for a single zone (place, swap, or clear). Caller is responsible for persisting.

## Placement in Player.swift

- `placedDecorByZone` is at line ~94, alongside the other optional/defaulted persisted fields (`tutorialSeen`, `trust`, `firstWaveShown`, etc.), immediately before `createdAt`.
- `placedDecor(ownedIDs:)` and `setDecor(_:in:)` are appended at the end of the class body, after the `init` closing brace.

## Build result

`** BUILD SUCCEEDED **` on first build attempt after adding `@MainActor` (required by Swift 6 strict concurrency -- see Concerns below).

## Concerns

### `@MainActor` annotation required (Swift 6 strict concurrency)

The spec's code snippet did not include `@MainActor` on either method. Swift 6 strict concurrency with `default-isolation=MainActor` caused the initial build to fail because:
- `RoomDecorCatalog.all` and `RoomDecorCatalog.byID(_:)` are `@MainActor`-isolated (inferred by default).
- `d.zone` (computed from `RoomZones.zone(for:)`) and `Rarity.rank` are also `@MainActor`-isolated for the same reason.

The fix was to add `@MainActor` to both `placedDecor(ownedIDs:)` and `setDecor(_:in:)`. This is consistent with how the rest of the codebase works -- callers in `HomeView` are already on `@MainActor`, so this annotation is harmless and correct.

### Calling `placedDecor(ownedIDs:)` from a SwiftUI view body

`placedDecor(ownedIDs:)` mutates `self.placedDecorByZone` on first call (the migration path). This is fine in `@MainActor` SwiftUI code (view bodies are already on `@MainActor`) -- but calling it directly from a computed property inside a `@Model`-observed view body is dangerous:

- SwiftUI may call the view body multiple times before the `@Model` write is committed to the SwiftData context, which could trigger repeated migration writes.
- More critically: writing to a SwiftData `@Model` property during a view body render (outside of an explicit `withAnimation` or a `Task`) can cause runtime warnings or unexpected invalidation loops.

**Recommended mitigation for Task 5 (HomeView wiring):** call `placedDecor(ownedIDs:)` from `.onAppear` or `.task`, store the result in a `@State` var, and only read that `@State` var inside the view body. Do not call the mutating resolver from a `var body: some View { ... }` computed property. The plan's Task 5 Step 1 shows this pattern correctly (`placedByZone` as `@State`), so the design is sound -- the concern is only if an implementer accidentally calls the resolver directly from `body`.
