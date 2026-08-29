import CoreText
import Foundation

/// Registers the bundled brand fonts (Onest, DM Sans, DM Mono) with Core Text
/// at launch so SwiftUI's `Font.custom` can resolve them. Programmatic
/// registration means there is no Info.plist `UIAppFonts` list to keep in sync.
public enum BrandFonts {
    public static func register() {
        let files = ["Onest-VF", "DMSans-VF", "DMMono-Regular", "DMMono-Medium"]
        for file in files {
            guard let url = Bundle.main.url(forResource: file, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
