# Task 5 Report: Home screen (Decorate pill, labeled nav, wiring)

## Summary

All 5 steps implemented in `Features/Home/HomeView.swift` only. Build succeeded. Both device sizes screenshot. DecorateView opens via the room sheet seam. No "Modifying state during view update" warning observed.

---

## Edits to HomeView.swift

### Step 1: Replace `placedDecor` computed var + migration state

**Added state var** (alongside `showRoom`, `showFriends`):
```swift
@State private var placedByZone: [String: String]? = nil
```

**Added init line** (end of `init`, after `_roomThemeID`):
```swift
_placedByZone = State(initialValue: player?.placedDecorByZone)
```

**Before** (line 359):
```swift
private var placedDecor: [RoomDecor] { RoomDecorCatalog.all.filter { wallet.has($0.id) } }
```

**After** -- PURE computed var + migration helper:
```swift
/// Pure read: the placed pieces in display order. No mutation here.
private var placedDecor: [RoomDecor] {
    let owned = wallet.owned
    guard let dict = placedByZone else {
        // pre-migration fallback (migration runs in onAppear): show owned, capped
        return Array(RoomDecorCatalog.all.filter { owned.contains($0.id) }.prefix(7))
    }
    return RoomZones.displayOrder.compactMap { zone in
        guard let id = dict[zone.rawValue], owned.contains(id) else { return nil }
        return RoomDecorCatalog.byID(id)
    }
}

/// Runs once in onAppear: migrates placedDecorByZone on first launch after the update.
private func migratePlacedDecorIfNeeded() {
    guard let p = player, p.placedDecorByZone == nil else { return }
    _ = p.placedDecor(ownedIDs: wallet.owned)   // migrates + persists into the model
    placedByZone = p.placedDecorByZone
    try? context.save()
}
```

**onAppear chain updated** to include `migratePlacedDecorIfNeeded()`:
```swift
.onAppear { applyScreenshotSeams(); applyTrustDecay(); restoreHealth(); pushWalletToServer(); helloWaveIfTrusted(); maybeShowTutorial(); migratePlacedDecorIfNeeded() }
```

### Step 2: Decorate pill overlay on creatureHero

Added `.overlay(alignment: .bottomTrailing)` on the ZStack in `creatureHero`, before `.frame(height: heroHeight)`:
```swift
.overlay(alignment: .bottomTrailing) {
    Button { Haptics.shared.select(); showRoom = true } label: {
        Label("Decorate", systemImage: "pencil")
            .font(YolkType.bodySmall.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(YolkColor.ink)
    }
    .buttonStyle(.plain).padding(YolkSpace.md)
}
```

Existing room-tap gesture (`showRoom = true`) is kept as a secondary path.

### Step 3: Room sheet body replaced

**Before:**
```swift
.sheet(isPresented: $showRoom) {
    RoomScreen(vibe: vibe, expression: shownExpression, outfit: wardrobe.outfit,
               wallet: wallet, themeID: $roomThemeID)
        .presentationDetents([.large])
}
```

**After:**
```swift
.sheet(isPresented: $showRoom) {
    DecorateView(vibe: vibe, expression: shownExpression, outfit: wardrobe.outfit,
                 wallet: wallet, placed: $placedByZone, themeID: $roomThemeID,
                 onChange: { player?.placedDecorByZone = placedByZone; persist() })
        .presentationDetents([.large])
}
```

### Step 4: bottomNav rewritten with labeled navItem

**Before:**
```swift
private var bottomNav: some View {
    HStack(spacing: 0) {
        navItem("house.fill", active: true) { showRoom = true }
        navItem("square.grid.2x2.fill", active: false) { showCollection = true }
        navItem("person.2.fill", active: false) { showFriends = true }
        navItem("tshirt.fill", active: false) { showWardrobe = true }
        navItem("person.crop.circle.fill", active: false) { showProfile = true }
    }
    ...
}

private func navItem(_ icon: String, active: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: icon)
            .font(.title3)
            .foregroundStyle(active ? YolkColor.ink : YolkColor.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
    }
    .buttonStyle(.plain)
}
```

**After:**
```swift
private var bottomNav: some View {
    HStack(spacing: 0) {
        navItem("house.fill", label: "Home", active: true) { showRoom = true }
        navItem("bag.fill", label: "Shop", active: false) { showWardrobe = true }
        navItem("square.grid.2x2.fill", label: "Dex", active: false) { showCollection = true }
        navItem("person.2.fill", label: "Friends", active: false) { showFriends = true }
        navItem("person.crop.circle.fill", label: "You", active: false) { showProfile = true }
    }
    ...
}

private func navItem(_ icon: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(active ? YolkColor.ink : YolkColor.muted)
            Text(label)
                .font(.system(size: 10, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? YolkColor.ink : YolkColor.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    .buttonStyle(.plain)
}
```

Nav order: Home (house, active, sets showRoom), Shop (bag.fill, showWardrobe -> existing ShopView), Dex (grid, showCollection), Friends (person.2, showFriends), You (person.crop.circle, showProfile). `showWardrobe` still presents the existing `ShopView` sheet body unchanged.

### Step 5: persist() updated

Added `player.placedDecorByZone = placedByZone` to `persist()`, before `try? context.save()`.

---

## Build result

`** BUILD SUCCEEDED **` against Yolk-SE (8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1). No warnings. No new files added, so xcodegen regenerate was not required.

---

## Screenshot outcomes

### Yolk-SE (`/tmp/task5-home-se.png`)
- Launched with `SIMCTL_CHILD_YOLK_VIBE=0` (screenshotMode -> HomeView without player)
- Decorate pill: VISIBLE, bottom-trailing of the room frame
- Bottom nav: 5 items (Home, Shop, Dex, Friends, You) with text labels, NOT clipped on the SE screen (375pt width)

### Yolk-ProMax (`/tmp/task5-home-promax.png`)
- Launched with `SIMCTL_CHILD_YOLK_VIBE=0`
- Decorate pill: VISIBLE
- Bottom nav: 5 labeled items, all visible without clipping

### Room sheet seam (`/tmp/task5-room-sheet-se.png`)
- Launched with `SIMCTL_CHILD_YOLK_VIBE=0` + `SIMCTL_CHILD_YOLK_ROOM_SHEET=1`
- DecorateView opens (NOT the old RoomScreen): shows "decorate" header, room diorama with zone targets, theme strip

---

## Runtime warning check

No "Modifying state during view update" purple warning observed. The migration helper `migratePlacedDecorIfNeeded()` is called exclusively from the `.onAppear` callback (not from body or any computed var). The `placedDecor` computed var is purely read-only -- it reads `placedByZone` state and `wallet.owned`, with no mutations.

---

## Files changed

- `Features/Home/HomeView.swift` (only file modified)

## No files created or deleted.
