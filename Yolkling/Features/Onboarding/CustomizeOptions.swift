import SwiftUI

/// The created, named creature handed off to the home screen.
struct HatchedCreature: Equatable {
    var vibe: Vibe
    var startingMood: Mood = .happy
    var name: String = ""
    var colorHex: UInt = 0xFFC23B   // the picked colour, kept for persistence
}

/// The colour swatches the user picks from at creation. A warm, cohesive set
/// across the egg palette; later this can grow (and a custom picker can follow).
enum CreaturePalette {
    static let colors: [UInt] = [
        0xFFC23B, // yolk
        0xFFB35A, // apricot
        0xFF94C2, // bubble pink
        0xFF6FA3, // rose
        0xB39BE8, // ube
        0x7B8CF0, // periwinkle
        0x8FD0FF, // sky
        0x73E0AE, // mint
        0xB6D98C, // matcha
        0xE7B68C, // toffee
    ]

    /// A darker shade for the radial-gradient depth + limbs.
    static func darker(_ h: UInt, _ f: Double = 0.78) -> UInt {
        let r = UInt(Double((h >> 16) & 0xFF) * f)
        let g = UInt(Double((h >> 8) & 0xFF) * f)
        let b = UInt(Double(h & 0xFF) * f)
        return (r << 16) | (g << 8) | b
    }

    /// A lighter shade for a specular sheen highlight on premium colour finishes.
    static func lighter(_ h: UInt, _ f: Double = 1.18) -> UInt {
        func ch(_ v: UInt) -> UInt { min(255, UInt(Double(v) * f)) }
        return (ch((h >> 16) & 0xFF) << 16) | (ch((h >> 8) & 0xFF) << 8) | ch(h & 0xFF)
    }

    /// Three cute name ideas per colour, each set themed to the colour so every
    /// swatch offers a different, fitting trio.
    private static let nameIdeas: [UInt: [String]] = [
        0xFFC23B: ["Sunny", "Goldie", "Honey"],     // yolk
        0xFFB35A: ["Mango", "Peaches", "Nugget"],   // apricot
        0xFF94C2: ["Bubbles", "Mochi", "Rosie"],    // bubble pink
        0xFF6FA3: ["Cherry", "Berry", "Posie"],     // rose
        0xB39BE8: ["Taro", "Lilac", "Ube"],         // ube
        0x7B8CF0: ["Cosmo", "Iris", "Blu"],         // periwinkle
        0x8FD0FF: ["Sky", "Cloud", "Breeze"],       // sky
        0x73E0AE: ["Sprout", "Kiwi", "Pickle"],     // mint
        0xB6D98C: ["Matcha", "Pea", "Olive"],       // matcha
        0xE7B68C: ["Toffee", "Cocoa", "Biscuit"],   // toffee
    ]

    static func names(for hex: UInt) -> [String] {
        nameIdeas[hex] ?? ["Pip", "Mochi", "Yoko"]
    }
}
