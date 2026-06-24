# Task 7 Report: Grow Section (share link + QR show + QR scan + invite)

## View Signatures

```swift
struct QRCodeView: View { let text: String }

struct QRScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
}

struct GrowFriendsView: View {
    let store: SocialStore
    let myCode: String
    let vibe: Vibe
    let onAdded: () -> Void
}
```

## QR Text Format

`https://yolkling.com/add/<myCode>` — e.g. `https://yolkling.com/add/YOLK-TEST`

## project.yml Camera Key Added

```yaml
        INFOPLIST_KEY_NSCameraUsageDescription: "Scan a friend's code to add them."
```
Added after `INFOPLIST_KEY_NSSupportsLiveActivities: YES` in the Yolkling target's `settings.base`.

## Files Created/Modified

- **Created** `Yolkling/Features/Social/QRCodeView.swift`
- **Created** `Yolkling/Features/Social/QRScannerView.swift`
- **Created** `Yolkling/Features/Social/GrowFriendsView.swift`
- **Modified** `project.yml` — added `INFOPLIST_KEY_NSCameraUsageDescription`
- **Modified** `Yolkling/App/RootView.swift` — YOLK_GROW seam added then removed

## Build Result

`** BUILD SUCCEEDED **` on Yolk-ProMax `9A3F2A47-5868-4956-B3AB-7531342B9347` (iOS 26.5).
- Seamed build: green
- Final build (seam removed): green (verified by independent rebuild)

## Screenshot Outcome (/tmp/task7-grow.png)

Screenshot confirmed all required UI elements render on the warm yolkling background:
- "a friend's code" TextField + dimmed "add" Button (disabled when empty, capsule style matching FriendsView.addRow exactly)
- "share invite link" full-width capsule button (ShareLink wrapping `https://yolkling.com/add/YOLK-TEST`)
- "show my QR" and "scan a friend" side-by-side capsule buttons
- "invite a friend and you both get +50 yolks" in muted text
- "no friends yet - add someone with their code or share yours" empty-state copy

## Seam Removal

YOLK_GROW seam added to RootView.swift (after YOLK_VISIT, before YOLK_INBOX), used for screenshot, then removed. Final rebuild green.

## Implementation Notes

- **QRCodeView**: Pure SwiftUI + CoreImage. `CIFilter.qrCodeGenerator()` with `inputCorrectionLevel = "M"`. Scaled with nearest-neighbor via CGAffineTransform before rendering. `.interpolation(.none)` on Image. Fallback placeholder if generation fails.
- **QRScannerView**: UIViewControllerRepresentable wrapping `ScannerViewController` (UIViewController subclass). All AVFoundation work on `captureQueue` (serial DispatchQueue). `Coordinator` is `@unchecked Sendable`. `onScan` fires once via `DispatchQueue.main.async`. Accepts raw `YOLK-XXXX` OR `https://yolkling.com/add/<code>` URL. Camera-denied handled gracefully (UILabel message, no crash). Setup error also handled gracefully.
- **GrowFriendsView**: Matches FriendsView.addRow pattern exactly. Uses `.yolkDialog($dialog)`. QR sheet is a private `QRSheet` view with `presentationDetents([.medium])`. Scanner sheet uses `.ignoresSafeArea()` + `.presentationDetents([.large])`. No em dashes anywhere (hyphens used).
- No third-party dependencies introduced.
- Swift 6 strict concurrency: all AVFoundation isolated off MainActor.

## Concerns

None.
