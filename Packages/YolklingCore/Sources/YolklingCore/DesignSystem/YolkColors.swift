import SwiftUI

/// The egg palette. Eggshell canvas, warm ink, yolk yellow, plus the candy
/// accents that back the creature vibes. Mirrors the web brand (yolkling.com).
public enum YolkColor {
    public static let shell = Color(hex: 0xFBF6EC)
    public static let shell2 = Color(hex: 0xF4EAD6)
    public static let ink = Color(hex: 0x2A241B)
    public static let inkSoft = Color(hex: 0x6E5C49)
    public static let muted = Color(hex: 0xA8937D)
    public static let line = Color(hex: 0x2A241B, alpha: 0.12)

    public static let yolk = Color(hex: 0xFFC23B)
    public static let yolkDeep = Color(hex: 0xE8A21E)

    // vibe accents
    public static let grape = Color(hex: 0x7B5CF0)
    public static let pink = Color(hex: 0xFF94C2)
    public static let mint = Color(hex: 0x73E0AE)
    public static let sky = Color(hex: 0x8FD0FF)
    public static let lemon = Color(hex: 0xFFD25A)
}

extension Color {
    /// Hex literal initializer, e.g. `Color(hex: 0xFFC23B)`.
    public init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
