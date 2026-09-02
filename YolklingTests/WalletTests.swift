import Testing
import YolklingCore
@testable import Yolkling

/// Exercises `Wallet`: the welcome grant, earning clamp, buy/purchase guards, the
/// canAfford boundary, and adopt. Source of truth:
/// `Yolkling/Features/Wardrobe/Wallet.swift`.
///
/// NOTE: `Wallet` is `@MainActor @Observable`, so the whole suite runs on the main
/// actor. NOTE: the initializer always UNIONS the free (cost == 0) starter
/// cosmetics into `owned`, so ownership assertions target a *paid* cosmetic.
@MainActor
@Suite("Wallet")
struct WalletTests {

    /// A paid cosmetic pulled from the real catalog (cost > 0), used to test the
    /// buy path without colliding with the always-owned free starters.
    private var paidCosmetic: Cosmetic {
        CosmeticCatalog.all.first { $0.cost > 0 }!
    }

    /// A second, distinct paid cosmetic for multi-item cases.
    private var otherPaidCosmetic: Cosmetic {
        let first = paidCosmetic
        return CosmeticCatalog.all.first { $0.cost > 0 && $0.id != first.id }!
    }

    @Test("welcomeGrant is 100 and is the default starting balance")
    func welcomeGrant() {
        #expect(Wallet.welcomeGrant == 100)
        #expect(Wallet().coins == 100)
    }

    @Test("Free starter cosmetics are always owned after init")
    func freeStartersOwned() {
        let wallet = Wallet(coins: 0, owned: [])
        let frees = CosmeticCatalog.all.filter { $0.cost == 0 && !$0.grantOnly }
        #expect(!frees.isEmpty)
        for free in frees { #expect(wallet.owns(free)) }
    }

    /// The other half of the rule, and the one that is actually load-bearing.
    ///
    /// Seasonal cosmetics are priced at 0 because they are not for sale, not because
    /// they are free. "Costs nothing" and "is yours" used to be the same test, which
    /// handed every player the whole spring set the moment it shipped. Scarcity is the
    /// entire point of a seasonal item, so this is the assertion that protects it.
    @Test("Grant-only cosmetics are NOT free, even at cost 0")
    func grantOnlyNotFree() {
        let wallet = Wallet(coins: 0, owned: [])
        let grantOnly = CosmeticCatalog.all.filter(\.grantOnly)
        #expect(!grantOnly.isEmpty)
        for item in grantOnly { #expect(!wallet.owns(item)) }
    }

    // MARK: earn

    @Test("earn adds a positive amount")
    func earnPositive() {
        let wallet = Wallet(coins: 100)
        wallet.earn(50)
        #expect(wallet.coins == 150)
    }

    @Test("earn clamps a negative amount to zero (never debits)")
    func earnNegativeClampsToZero() {
        let wallet = Wallet(coins: 100)
        wallet.earn(-40)
        #expect(wallet.coins == 100)
    }

    // MARK: buy

    @Test("buy debits exactly the cost and marks it owned when affordable")
    func buyAffordableDebitsCost() {
        let item = paidCosmetic
        let wallet = Wallet(coins: item.cost + 5, owned: [])
        #expect(wallet.buy(item) == true)
        #expect(wallet.coins == 5)
        #expect(wallet.owns(item))
    }

    @Test("buy refuses and does not debit when coins < cost")
    func buyUnaffordableRefuses() {
        let item = paidCosmetic
        let wallet = Wallet(coins: item.cost - 1, owned: [])
        #expect(wallet.buy(item) == false)
        #expect(wallet.coins == item.cost - 1)
        #expect(!wallet.owns(item))
    }

    @Test("buy refuses (no double-charge) when already owned")
    func buyAlreadyOwnedRefuses() {
        let item = paidCosmetic
        let wallet = Wallet(coins: item.cost * 3, owned: [item.id])
        #expect(wallet.buy(item) == false)
        #expect(wallet.coins == item.cost * 3) // untouched
    }

    // MARK: canAfford boundary

    @Test("canAfford is true exactly when coins == cost (boundary)")
    func canAffordBoundary() {
        let item = paidCosmetic
        #expect(Wallet(coins: item.cost).canAfford(item) == true)
        #expect(Wallet(coins: item.cost - 1).canAfford(item) == false)
        #expect(Wallet(coins: item.cost + 1).canAfford(item) == true)
    }

    @Test("buy succeeds at the exact cost boundary, draining to zero")
    func buyAtExactBoundary() {
        let item = paidCosmetic
        let wallet = Wallet(coins: item.cost, owned: [])
        #expect(wallet.buy(item) == true)
        #expect(wallet.coins == 0)
    }

    // MARK: purchase(id:cost:)

    @Test("purchase debits exactly and refuses when unaffordable or owned")
    func purchaseByIDGuards() {
        let wallet = Wallet(coins: 100, owned: [])
        // affordable
        #expect(wallet.purchase(id: "rare-color-1", cost: 30) == true)
        #expect(wallet.coins == 70)
        #expect(wallet.has("rare-color-1"))
        // already owned -> refuse, no charge
        #expect(wallet.purchase(id: "rare-color-1", cost: 30) == false)
        #expect(wallet.coins == 70)
        // unaffordable -> refuse
        #expect(wallet.purchase(id: "rare-color-2", cost: 999) == false)
        #expect(wallet.coins == 70)
        #expect(!wallet.has("rare-color-2"))
    }

    @Test("purchase at the exact-cost boundary succeeds")
    func purchaseBoundary() {
        let wallet = Wallet(coins: 40, owned: [])
        #expect(wallet.purchase(id: "boundary", cost: 40) == true)
        #expect(wallet.coins == 0)
    }

    // MARK: adopt

    @Test("adopt overwrites coins and owned (free starters stay unioned)")
    func adoptOverwrites() {
        let item = paidCosmetic
        let other = otherPaidCosmetic
        let wallet = Wallet(coins: 100, owned: [item.id])
        wallet.adopt(coins: 777, owned: [other.id])
        #expect(wallet.coins == 777)
        #expect(wallet.has(other.id))          // adopted set present
        #expect(!wallet.has(item.id))          // previous non-free owned replaced
        // free starters survive the overwrite
        let free = CosmeticCatalog.all.first { $0.cost == 0 }!
        #expect(wallet.owns(free))
    }

    @Test("grant-only season items can never be bought, at any price")
    func grantOnlyNeverPurchasable() {
        var w = Wallet(coins: 9999, owned: [])
        // The real catalog item, so this test tracks the shipping definition.
        let exclusive = CosmeticCatalog.all.first { $0.grantOnly }!
        #expect(w.buy(exclusive) == false, "a grant-only item was purchasable")
        #expect(w.owns(exclusive) == false)
        #expect(w.coins == 9999, "coins moved on a refused buy")
        // But a legitimate grant still lands it.
        w.grant([exclusive.id])
        #expect(w.owns(exclusive) == true)
    }

}
