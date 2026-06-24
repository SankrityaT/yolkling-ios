# Task 7 Report: Shop Utility Row + Curated Front

## Files Changed

- `Yolkling/Features/Shop/ShopHomeView.swift` (only file modified)

---

## What Was Built

### Step 1: Utility Row

A `utilityRow` computed var is injected between the aisle picker and the scroll view. It contains:

1. **Search field** + **sort menu** in a horizontal stack.
   - `TextField("search", text: $searchText)` with a leading magnifying glass icon and a trailing `xmark.circle.fill` clear button that appears when text is present.
   - Sort `Menu` with a chevron icon (arrow.up.arrow.down). Four options: `price: low to high`, `price: high to low`, `rarity`, `new`.

2. **All | Owned segmented picker** (`Picker("filter", selection: $showOwned)`), below the search row.

3. An `.onChange(of: aisle)` resets both `searchText` and `showOwned` to defaults when the user switches aisles.

### filteredItems per aisle

Three state vars drive filtering: `@State private var searchText`, `showOwned`, `sortOrder`.

- `filteredColours` - applies to `ColorShop.all`
- `filteredCosmetics(for:)` - per-slot, applies to `CosmeticCatalog.items(in:)`
- `filteredThemes` - applies to `RoomThemes.all`; Owned filter includes free (cost==0) themes
- `filteredDecor` - applies to `RoomDecorCatalog.all`

All four call `applySort(_:cost:rarity:)`, a generic helper:

```swift
private func applySort<T>(_ items: [T], cost: (T) -> Int, rarity: (T) -> Rarity) -> [T] {
    switch sortOrder {
    case .priceAsc:  return items.sorted { cost($0) < cost($1) }
    case .priceDesc: return items.sorted { cost($0) > cost($1) }
    case .rarity:    return items.sorted { rarity($0).rank > rarity($1).rank }
    case .newest:    return items.reversed()
    }
}
```

The `Rarity.rank` extension lives in `Core/Rooms/RoomZone.swift` (added in Task 1): common=0, rare=1, epic=2. All four item types (ColorSwatch, Cosmetic, RoomTheme, RoomDecor) expose both `rarity: Rarity` and `cost: Int`, so no fallback is needed for any type.

The Outfit aisle hides slots where `filteredCosmetics(for:)` returns empty (avoiding orphaned slot headers during search).

The original colour card is suppressed during search or Owned mode (it has no `id` in `wallet`, so it would always show as unowned).

### Step 2: Curated Front

Shown only when `searchText.isEmpty && !showOwned`. Injected above the per-aisle grid inside the `ScrollView`.

#### Colours and Outfit aisles

`curatedStrips(catalog:cost:isOwned:card:)` computes three strips generically:

- **New** - `catalog.reversed().prefix(6)`. Interpretation: the catalog is defined in ascending order of authoring, so the last six entries are the most recently added. Reversing gives newest-first within the strip.
- **Under 100 Yolks** - unowned items where `cost < 100`.
- **Almost yours** - unowned items where `(cost - wallet.coins) > 0`, sorted ascending by that gap, capped at 6. If the wallet can afford everything (no positive gap), this strip is hidden.

#### Room aisle

`roomCuratedFront` applies the same three strips independently to themes and to decor, giving up to six strips total (hidden when empty):

- new themes, under-100 themes, almost-yours themes
- new decor, under-100 decor, almost-yours decor (labeled "almost yours (decor)" to distinguish)

All strips use `curatedStrip(title:content:)` which wraps a `ScrollView(.horizontal)` in a `VStack` with a `sectionTitle`. They reuse the same `colourCard`, `cosmeticCard`, `themeCard`, `decorCard` helpers as the main grid.

---

## Interpretations and Notes

- **"new" interpretation**: reverse catalog order. Catalog arrays are append-only by convention, so the last entries are the most recently authored. No timestamp field exists on any item type.
- **Rarity sort fallback**: NOT needed. All four item types (`ColorSwatch`, `Cosmetic`, `RoomTheme`, `RoomDecor`) have a `rarity: Rarity` field. The generic `applySort` handles all of them uniformly via `Rarity.rank`.
- **"Almost yours" with zero positive gap**: if `wallet.coins >= item.cost` for all unowned items, no items pass the `(cost - wallet.coins) > 0` filter, so the strip is hidden. This matches the plan spec.

---

## Build Result

`** BUILD SUCCEEDED **` on Yolk-SE (`8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1`).

---

## Screenshot Outcome

Launched with `SIMCTL_CHILD_YOLK_VIBE=0 SIMCTL_CHILD_YOLK_WARDROBE=1`. Screenshot at `/tmp/task7-shop.png` confirms:

- Shop sheet opened over the home screen
- Header with "shop" title and coin balance visible
- Aisle picker (Colours / Outfit / Room) visible
- Utility row visible: search field with magnifying glass icon, sort button (arrows icon)
- All / Owned segmented control below the search row
- Curated "NEW" section header visible at the bottom of the visible area, confirming curated strips render above the grid

Search/Owned behavior is verified by code review: `filteredColours`, `filteredCosmetics(for:)`, `filteredThemes`, `filteredDecor` all gate on `searchText.isEmpty` and `showOwned` before passing to `applySort`. The grid renders from the filtered+sorted output, and curated strips only appear when both conditions are false.
