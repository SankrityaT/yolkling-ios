import SwiftUI

/// The egg palette. Eggshell canvas, warm ink, yolk yellow, plus the candy
/// accents that back the creature vibes. Mirrors the web brand (yolkling.com).
enum YolkColor {
    static let shell = Color(hex: 0xFBF6EC)
    static let shell2 = Color(hex: 0xF4EAD6)
    static let ink = Color(hex: 0x2A241B)
    static let inkSoft = Color(hex: 0x6E5C49)
    static let muted = Color(hex: 0xA8937D)
    static let line = Color(hex: 0x2A241B, alpha: 0.12)

    static let yolk = Color(hex: 0xFFC23B)
    static let yolkDeep = Color(hex: 0xE8A21E)

    // vibe accents
    static let grape = Color(hex: 0x7B5CF0)
    static let pink = Color(hex: 0xFF94C2)
    static let mint = Color(hex: 0x73E0AE)
    static let sky = Color(hex: 0x8FD0FF)
    static let lemon = Color(hex: 0xFFD25A)
}

extension Color {
    /// Hex literal initializer, e.g. `Color(hex: 0xFFC23B)`.
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
