import SwiftUI

/// A room's palette: wall gradient, floor, and an accent (rug/decor). A theme is
/// bought with Yolks (like a cosmetic). The room itself is code-drawn (RoomView);
/// designers add themes + decor without touching the renderer. See docs/rooms/.
struct RoomTheme: Identifiable, Sendable {
    let id: String
    let name: String
    let wallTop: UInt
    let wallBottom: UInt
    let floor: UInt
    let floorEdge: UInt
    let accent: UInt
    let rarity: Rarity
    let cost: Int

    var wall: LinearGradient {
        LinearGradient(colors: [Color(hex: wallTop), Color(hex: wallBottom)], startPoint: .top, endPoint: .bottom)
    }
    var floorColor: Color { Color(hex: floor) }
    var floorEdgeColor: Color { Color(hex: floorEdge) }
    var accentColor: Color { Color(hex: accent) }
}

enum RoomThemes {
    static let cozy = RoomTheme(id: "room-cozy", name: "cozy", wallTop: 0xFBEEE2, wallBottom: 0xF3DAC6,
                                floor: 0xE6C49A, floorEdge: 0xD3AC80, accent: 0xE89BB0, rarity: .common, cost: 0)

    // docs/rooms/themes.md
    static let all: [RoomTheme] = [cozy,
        t("forest cabin", "room-forest", 0xEFE7D6, 0xD9C9A8, 0x8E6A4C, 0x6F503A, 0x7FA56A, .common, 120),
        t("beach day", "room-beach", 0xDDF1F4, 0xBFE3E6, 0xEAD7B0, 0xD2BA8C, 0xF2B07A, .common, 100),
        t("candy shop", "room-candy", 0xFCE3EE, 0xF8C9DD, 0xF6D7C2, 0xE8B6A2, 0xF49AB8, .rare, 300),
        t("night sky", "room-night", 0x2E3A60, 0x1C2444, 0x3B3A57, 0x282741, 0x6FA8DC, .epic, 500),
        t("little library", "room-library", 0xEFE3CC, 0xD8C2A0, 0x7A5A40, 0x5E4530, 0xA8743F, .rare, 320),
        t("greenhouse", "room-greenhouse", 0xE9F6E4, 0xCDE9CC, 0xC9B894, 0xB19E78, 0x6FB58A, .rare, 310),
        t("ocean deep", "room-ocean", 0xCFE9EF, 0xA6D3DE, 0x8FB7B6, 0x6F9695, 0x4FA0AE, .rare, 300),
        t("outer space", "room-space", 0x38305C, 0x211A40, 0x332C4E, 0x231E3A, 0xC9A6E8, .epic, 520),
        t("autumn", "room-autumn", 0xF6E4CC, 0xEBC79E, 0xA06A45, 0x7E5234, 0xD98441, .common, 130),
        t("winter snow", "room-winter", 0xEEF4FA, 0xD6E4F0, 0xC7D2DD, 0xA9B6C4, 0x8FB8D8, .rare, 290),
        t("sunrise", "room-sunrise", 0xFDEAD2, 0xF8C9A8, 0xE9B88E, 0xCF9A70, 0xF2956E, .common, 110),
        t("lavender fields", "room-lavender", 0xF0E8F7, 0xDCCBEC, 0xC3B0A0, 0xA8957F, 0x9C7CC4, .rare, 300),
        t("mushroom cottage", "room-mushroom", 0xF2E2D6, 0xE0C2AE, 0x8C5A3F, 0x6E432D, 0xD26A5A, .rare, 330),
        t("paper origami", "room-paper", 0xF7F2E9, 0xE7DECB, 0xD8CDB8, 0xBEB199, 0xE0976E, .common, 90),
        t("pastel arcade", "room-arcade", 0xEDE6FA, 0xD6C9F2, 0xB7AECF, 0x968CB0, 0xF58FB0, .epic, 480),
        t("rainy day", "room-rainy", 0xDCE3E8, 0xC2CCD4, 0xA7AEB4, 0x878E94, 0x7C9AB0, .common, 120),
    ]

    private static func t(_ name: String, _ id: String, _ wt: UInt, _ wb: UInt, _ fl: UInt, _ fe: UInt, _ ac: UInt, _ rarity: Rarity, _ cost: Int) -> RoomTheme {
        RoomTheme(id: id, name: name, wallTop: wt, wallBottom: wb, floor: fl, floorEdge: fe, accent: ac, rarity: rarity, cost: cost)
    }
}
