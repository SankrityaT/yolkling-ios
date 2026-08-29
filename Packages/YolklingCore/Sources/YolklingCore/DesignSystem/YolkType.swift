import SwiftUI

/// Typography. Onest for display and headings, DM Sans for body, DM Mono for
/// little labels. Mirrors the web brand (yolkling.com). The fonts are bundled
/// and registered at launch by `BrandFonts.register()`.
public enum YolkType {
    public static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .custom("Onest", size: size).weight(weight)
    }

    public static let title = display(36, .heavy)
    public static let heading = display(26, .bold)
    public static let body = Font.custom("DM Sans", size: 17)
    public static let bodySmall = Font.custom("DM Sans", size: 15)
    public static let label = Font.custom("DM Mono", size: 14)
}
