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

    /// Take off anything you no longer own.
    ///
    /// You can trade away a hat while wearing it. Nothing used to notice: the item stayed
    /// equipped, `persist()` wrote it into `equippedItemIDs`, and `mySnapshot()` published
    /// it to friends — so you kept visibly wearing something you provably didn't have.
    ///
    /// Takes the **predicate** rather than the `Wallet` so this stays a pure store with no
    /// dependency on the economy, and so the free-starter and grant-only rules live in
    /// exactly one place (`Wallet.owns`).
    ///
    /// Returns early when nothing is stale, so it can't loop through the `onChange` that
    /// watches `equipped`.
    func prune(owns: (Cosmetic) -> Bool) {
        let stale = equipped.filter { !owns($0.value) }.map(\.key)
        guard !stale.isEmpty else { return }
        for slot in stale { equipped[slot] = nil }
    }

    /// Restore the equipped set from persisted cosmetic ids, dropping anything not owned.
    ///
    /// REPLACES rather than merges. The old version only ever added, which meant a cloud
    /// restore left you wearing items the restored snapshot wasn't wearing.
    func restore(equippedIDs: [String], owns: (Cosmetic) -> Bool) {
        var next: [CosmeticSlot: Cosmetic] = [:]
        for id in equippedIDs {
            if let item = CosmeticCatalog.all.first(where: { $0.id == id }), owns(item) {
                next[item.slot] = item
            }
        }
        equipped = next
    }
}
