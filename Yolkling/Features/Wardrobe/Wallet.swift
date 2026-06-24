import SwiftUI
import Observation

/// The in-app currency: **Yolks**.
enum Currency {
    static let name = "Yolks"
}

/// Coin balance + owned cosmetics. New users get a welcome grant; later the
/// balance + grants come from the backend (waitlist early-bird + referral
/// bonuses — see docs/REWARDS.md), and this persists via SwiftData.
@MainActor
@Observable
final class Wallet {
    /// New-user welcome grant.
    nonisolated static let welcomeGrant = 100

    private(set) var coins: Int
    private(set) var owned: Set<String>

    init(coins: Int = Wallet.welcomeGrant, owned: Set<String> = []) {
        self.coins = coins
        // Free starter items are always owned, unioned with anything restored.
        let free = Set(CosmeticCatalog.all.filter { $0.cost == 0 }.map(\.id))
        self.owned = owned.union(free)
    }

    /// Earn Yolks (check-ins, focus sessions, etc.).
    func earn(_ amount: Int) { coins += max(0, amount) }

    /// Adopt the server's authoritative wallet (on sign-in / cross-device restore).
    /// Free starter items stay unioned in so they never vanish.
    func adopt(coins newCoins: Int, owned newOwned: Set<String>) {
        coins = newCoins
        let free = Set(CosmeticCatalog.all.filter { $0.cost == 0 }.map(\.id))
        owned = newOwned.union(free)
    }

    func owns(_ cosmetic: Cosmetic) -> Bool {
        cosmetic.cost == 0 || owned.contains(cosmetic.id)
    }

    func canAfford(_ cosmetic: Cosmetic) -> Bool { coins >= cosmetic.cost }

    /// Buy if affordable and not already owned. Returns whether it happened.
    @discardableResult
    func buy(_ cosmetic: Cosmetic) -> Bool {
        guard !owns(cosmetic), coins >= cosmetic.cost else { return false }
        coins -= cosmetic.cost
        owned.insert(cosmetic.id)
        return true
    }

    /// Generic ownership + purchase by id (rare colours, and future earned packs).
    func has(_ id: String) -> Bool { owned.contains(id) }

    @discardableResult
    func purchase(id: String, cost: Int) -> Bool {
        guard !owned.contains(id), coins >= cost else { return false }
        coins -= cost
        owned.insert(id)
        return true
    }
}
