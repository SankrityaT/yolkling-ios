import SwiftUI
import Observation

/// What the creature is currently wearing — one cosmetic per slot. In-memory for
/// now; persists with SwiftData and gates on owned items + coins once the economy
/// lands (see docs/REWARDS.md).
@MainActor
@Observable
final class WardrobeStore {
    var equipped: [CosmeticSlot: Cosmetic] = [:]

    /// The equipped set as a flat list for the renderer (stable slot order).
    var outfit: [Cosmetic] {
        CosmeticSlot.allCases.compactMap { equipped[$0] }
    }

    func toggle(_ cosmetic: Cosmetic) {
        if equipped[cosmetic.slot]?.id == cosmetic.id {
            equipped[cosmetic.slot] = nil
        } else {
            equipped[cosmetic.slot] = cosmetic
        }
    }

    func clear(_ slot: CosmeticSlot) { equipped[slot] = nil }

    func isEquipped(_ cosmetic: Cosmetic) -> Bool {
        equipped[cosmetic.slot]?.id == cosmetic.id
    }

    /// Restore the equipped set from persisted cosmetic ids.
    func restore(equippedIDs: [String]) {
        for id in equippedIDs {
            if let item = CosmeticCatalog.all.first(where: { $0.id == id }) {
                equipped[item.slot] = item
            }
        }
    }
}
