import SwiftUI

/// The created, named creature handed off to the home screen.
public struct HatchedCreature: Equatable {
    public var vibe: Vibe
    public var startingMood: Mood = .happy
    public var name: String = ""
    public var colorHex: UInt = 0xFFC23B   // the picked colour, kept for persistence

    /// Whether the player actually granted these during onboarding.
    ///
    /// The priming screens used to be theatre: "connect health" and "maybe later" were
    /// wired to the same closure, so the button asked for a permission it never requested
    /// and the flow moved on either way. The real prompt only ever appeared much later,
    /// from the home screen. These carry the true answer through to the `Player`.
    public var healthConnected = false
    public var screenTimeConnected = false

    public init(vibe: Vibe, startingMood: Mood = .happy, name: String = "", colorHex: UInt = 0xFFC23B) {
        self.vibe = vibe
        self.startingMood = startingMood
        self.name = name
        self.colorHex = colorHex
    }
}

/// The colour swatches the user picks from at creation. A warm, cohesive set
/// across the egg palette; later this can grow (and a custom picker can follow).
public enum CreaturePalette {
    public static let colors: [UInt] = [
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
    public static func darker(_ h: UInt, _ f: Double = 0.78) -> UInt {
        let r = UInt(Double((h >> 16) & 0xFF) * f)
        let g = UInt(Double((h >> 8) & 0xFF) * f)
        let b = UInt(Double(h & 0xFF) * f)
        return (r << 16) | (g << 8) | b
    }

    /// A lighter shade for a specular sheen highlight on premium colour finishes.
    public static func lighter(_ h: UInt, _ f: Double = 1.18) -> UInt {
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

    public static func names(for hex: UInt) -> [String] {
        nameIdeas[hex] ?? ["Pip", "Mochi", "Yoko"]
    }
}
