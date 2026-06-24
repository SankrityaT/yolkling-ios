import SwiftUI

/// Typography. Onest for display and headings, DM Sans for body, DM Mono for
/// little labels. Mirrors the web brand (yolkling.com). The fonts are bundled
/// and registered at launch by `BrandFonts.register()`.
enum YolkType {
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .custom("Onest", size: size).weight(weight)
    }

    static let title = display(36, .heavy)
    static let heading = display(26, .bold)
    static let body = Font.custom("DM Sans", size: 17)
    static let bodySmall = Font.custom("DM Sans", size: 15)
    static let label = Font.custom("DM Mono", size: 14)
}
