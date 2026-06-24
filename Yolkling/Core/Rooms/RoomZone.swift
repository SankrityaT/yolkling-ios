import SwiftUI

extension RoomDecor {
    /// A single display slot in the room. Each zone shows at most `RoomZones.capacity`
    /// piece(s) so a fully decorated room stays curated and never overlaps. A piece's
    /// authored (px, py) is still its anchor; the zone only decides which slot it owns.
    enum Zone: String, CaseIterable, Sendable {
        case hanging, wallL, wallC, wallR, floorL, floorC, floorR
    }
    /// Derived, stable for a given catalog entry.
    var zone: Zone { RoomZones.zone(for: self) }
}

enum RoomZones {
    /// Pieces per zone shown at once. Bump a zone later by making this a per-zone map.
    static let capacity = 1

    /// Top to bottom, for laying out edit targets + trays.
    static let displayOrder: [RoomDecor.Zone] =
        [.hanging, .wallL, .wallC, .wallR, .floorL, .floorC, .floorR]

    private static let hangingKinds: Set<RoomDecor.Kind> =
        [.pennantGarland, .fairyLights, .paperLantern, .hangingPlant, .balloonBunch, .nightStars]

    /// Reproduces the authored 34-piece mapping (see spec): ceiling pieces by kind,
    /// then wall vs floor by py at 0.45, then L/C/R by px at 0.40 and 0.65.
    static func zone(for d: RoomDecor) -> RoomDecor.Zone {
        if hangingKinds.contains(d.kind) { return .hanging }
        let isWall = d.py < 0.45
        let col: Int = d.px < 0.40 ? 0 : (d.px <= 0.65 ? 1 : 2)
        switch (isWall, col) {
        case (true, 0):  return .wallL
        case (true, 1):  return .wallC
        case (true, _):  return .wallR
        case (false, 0): return .floorL
        case (false, 1): return .floorC
        case (false, _): return .floorR
        }
    }
}

extension Rarity {
    /// common < rare < epic, for "highest rarity wins" placement ties.
    var rank: Int {
        switch self {
        case .common: return 0
        case .rare:   return 1
        case .epic:   return 2
        }
    }
}
