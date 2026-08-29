import SwiftUI
import Observation
import YolklingCore

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

    /// Ids the server has **confirmed** holding.
    ///
    /// This is what lets a reconcile tell "the server deleted this" (you traded it away)
    /// apart from "the server has never heard of this" (bought while offline, or the push
    /// failed and there is no retry). Without the distinction, adopting the server's list
    /// authoritatively destroys any purchase that has not landed yet — and unrecoverably,
    /// because the server never had it.
    ///
    /// Empty on a fresh install and on the first launch after this ships, which makes the
    /// first reconcile a pure union. That is deliberate: historic duplicates stay put
    /// rather than being retroactively confiscated.
    private(set) var syncedIDs: Set<String>

    /// Items that are owned by definition, whatever the wallet says.
    ///
    /// `owns` short-circuits on these, so the client cannot express losing one. That is
    /// why they are also excluded from the server's trade allowlist — see
    /// `docs/sql/tradeable_items.sql`.
    private static var freeStarters: Set<String> {
        Set(CosmeticCatalog.all.filter { $0.cost == 0 && !$0.grantOnly }.map(\.id))
    }

    init(coins: Int = Wallet.welcomeGrant, owned: Set<String> = [], synced: Set<String> = []) {
        self.coins = coins
        self.syncedIDs = synced
        // Free starter items are always owned, unioned with anything restored.
        self.owned = owned.union(Self.freeStarters)
    }

    /// Earn Yolks (check-ins, focus sessions, etc.).
    func earn(_ amount: Int) { coins += max(0, amount) }

    /// Adopt the server's authoritative wallet (on sign-in / cross-device restore).
    /// Free starter items stay unioned in so they never vanish.
    func adopt(coins newCoins: Int, owned newOwned: Set<String>) {
        coins = newCoins
        owned = newOwned.union(Self.freeStarters)
    }

    /// Take the server's inventory as the record of **what** you own.
    ///
    /// REPLACES rather than unions, which is the whole point: `respond_trade` deletes the
    /// row for an item you traded away, and until something here notices, the next
    /// `push_wallet` re-inserts it — so both players end up owning it. Union semantics
    /// cannot express a removal, and removal is exactly what a trade is.
    ///
    /// Three things survive the replace:
    ///  - **free starters**, which are owned by definition;
    ///  - **anything never synced**, because the server cannot have removed what it never
    ///    held. This is the guard that keeps an offline purchase alive;
    ///  - **coins**, which aren't part of this and are merged by the caller. `gift_yolks`
    ///    writes them server-side, so a blind replace could destroy a gift in flight.
    func reconcile(serverOwned: Set<String>) {
        // Everything the server has never confirmed. Not "recent" — genuinely unknown to
        // the server, which is a different thing and the only safe test.
        let neverSynced = owned.subtracting(syncedIDs)
        owned = serverOwned.union(Self.freeStarters).union(neverSynced)
        syncedIDs = serverOwned
    }

    /// Apply a swap the **server has already performed**.
    ///
    /// Keyed on the two ids the trade row itself reports, so the client can never remove
    /// something the server didn't. Cheaper and racier-safe than re-fetching: the accept
    /// response already tells us exactly what moved.
    func applyTrade(gave: String, got: String) {
        owned.remove(gave)
        owned.insert(got)
        syncedIDs.remove(gave)
        syncedIDs.insert(got)
    }

    /// Items the server granted — a season joined, a referral paid out. Not a purchase:
    /// no coins move.
    ///
    /// Deliberately does not touch `syncedIDs`. Treating a grant as never-synced is the
    /// safe default: if the push hasn't happened yet, a later reconcile must not read the
    /// server's silence as a removal.
    func grant(_ ids: [String]) { owned.formUnion(ids) }

    /// Record what the server confirmed after a successful push. Only a **confirmed**
    /// push may mark ids synced — a dropped request has to leave them unsynced, or the
    /// next reconcile mistakes them for removals.
    func markSynced(_ ids: Set<String>) { syncedIDs = ids }

    func owns(_ cosmetic: Cosmetic) -> Bool {
        // Grant-only items are never free, whatever their cost says — they're earned by
        // being there for a season, not bought.
        if cosmetic.grantOnly { return owned.contains(cosmetic.id) }
        return cosmetic.cost == 0 || owned.contains(cosmetic.id)
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
