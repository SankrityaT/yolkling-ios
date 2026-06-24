# Widget Task 1 Report: App Group + Shared Renderer Plumbing

**Result:** BUILD SUCCEEDED (both targets). App Group round-trip confirmed. Temp seam removed.

---

## Files Created / Modified

### Created: `Yolkling/Core/Widget/WidgetSnapshot.swift`
Exact code from the plan: `enum WidgetShare` (appGroup, key, defaults) and `struct WidgetSnapshot: Codable, Sendable` with `read()` / `write()`.

### Modified: `Yolkling/Yolkling.entitlements`
Added to the existing plist dict:
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.Sankritya.Yolkling</string>
</array>
```

### Created: `YolklingWidgets/YolklingWidgets.entitlements`
New plist with the same App Groups array. Referenced by `CODE_SIGN_ENTITLEMENTS` in the widget target settings.

### Modified: `project.yml`

**Widget target sources additions:**
```yaml
- path: Yolkling/Core/DesignSystem
  excludes:
    - TypewriterText.swift
- Yolkling/Core/Creature
- Yolkling/Core/Cosmetics
- Yolkling/Core/Rooms
- Yolkling/Core/Widget
- path: Yolkling/Core/Networking/SocialModels.swift
- path: Yolkling/Features/Onboarding/CustomizeOptions.swift
```

**Widget target settings addition:**
```yaml
CODE_SIGN_ENTITLEMENTS: YolklingWidgets/YolklingWidgets.entitlements
```

---

## File Exclusions from Widget Target

### Excluded: `Yolkling/Core/DesignSystem/TypewriterText.swift`
**Why:** `TypewriterText.swift` calls `Haptics.shared.tick()`. `Haptics.swift` imports `CoreHaptics` and `UIKit`, neither of which are available in widget extensions. `TypewriterText` is used only for onboarding animations and is not a rendering primitive needed by the widget.

### Added (not in plan, needed to resolve): `Yolkling/Features/Onboarding/CustomizeOptions.swift`
**Why:** `Yolkling/Core/Cosmetics/ColorShop.swift` (a renderer dependency) references `CreaturePalette.darker()` and `CreaturePalette.lighter()`. `CreaturePalette` is defined in `CustomizeOptions.swift`, not in any Core directory. The file only imports SwiftUI and defines `HatchedCreature` (a plain struct) and `CreaturePalette` (pure math utilities) -- no app-only symbols. Adding it to the widget sources resolved the compile error without pulling in SwiftData or networking.

---

## Build Results

| Target | Result |
|---|---|
| Yolkling (app) | BUILD SUCCEEDED |
| YolklingWidgets (extension) | BUILD SUCCEEDED |

Both targets compiled in a single `xcodebuild -scheme Yolkling` invocation.

---

## App Group Round-Trip Result

Temporary seam added to `App/RootView.swift` under `YOLK_GROUPCHECK`:
- Called `WidgetShare.defaults != nil` to confirm the suite resolved.
- Wrote a sample `WidgetSnapshot` via `.write()`.
- Screenshot at `/tmp/task1-group.png` shows **"app group OK"** on Yolk-SE (8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1).

**Temp seam status: REMOVED.** Final rebuild after removal: `** BUILD SUCCEEDED **`.

---

## Notes

- The app target already globs the entire `Yolkling/` directory, so `Core/Widget/WidgetSnapshot.swift` is automatically included in the app target -- no explicit addition needed.
- `xcodegen generate` was run before each build.
- No SwiftData, HealthKit, networking, or app-lifecycle imports were introduced into the widget target.
