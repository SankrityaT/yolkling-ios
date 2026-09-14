import Testing
import SwiftUI
import YolklingCore
@testable import Yolkling

/// Exercises the species taxonomy: catalog integrity, head-start / set membership
/// resolution, `Species.vibe` purity, the founding-species pool parity with the
/// SQL grant, and the `DiscoveryEngine` invariant. Sources of truth:
/// `Yolkling/Core/Creature/Species*.swift`, `SpeciesSet.swift`, `FoundingFlair.swift`,
/// `CareEngines.swift`, and `docs/sql/founding_grant.sql`.
@Suite("Species")
struct SpeciesTests {

    // MARK: Catalog integrity

    @Test("All catalog ids are unique")
    func catalogIdsUnique() {
        let ids = SpeciesCatalog.all.map(\.id)
        #expect(ids.count == Set(ids).count)
    }

    @Test("The catalog is non-empty and every species has a non-empty family")
    func familiesNonEmpty() {
        #expect(!SpeciesCatalog.all.isEmpty)
        for species in SpeciesCatalog.all {
            #expect(!species.family.isEmpty, "\(species.id) has an empty family")
            #expect(!species.id.isEmpty)
        }
    }

    // MARK: Membership resolution

    @Test("Every head-start id resolves in the catalog")
    func headStartResolves() {
        #expect(!SpeciesSets.headStart.isEmpty)
        for id in SpeciesSets.headStart {
            #expect(SpeciesCatalog.all.contains { $0.id == id }, "head-start id \(id) not found")
        }
    }

    @Test("Every member of every SpeciesSet resolves in the catalog")
    func speciesSetMembersResolve() {
        for set in SpeciesSets.all {
            #expect(!set.speciesIDs.isEmpty, "set \(set.id) is empty")
            for id in set.speciesIDs {
                #expect(SpeciesCatalog.all.contains { $0.id == id },
                        "set \(set.id) references missing species \(id)")
            }
            // `SpeciesSet.species` should resolve to the same count (compactMap).
            #expect(set.species.count == set.speciesIDs.count,
                    "set \(set.id) has unresolved members")
        }
    }

    // MARK: Vibe purity (colour -> Vibe stable across calls)

    @Test("A Species.vibe built from a fixed hex is stable across two calls")
    func vibeIsStable() {
        let species = Species(
            id: "test-fixed", name: "fixed", family: "test", rarity: .common,
            bodyHex: 0xB6D98C, deepHex: 0x84B85E, accentHex: 0xFFFFFF,
            style: .classic, pattern: .none, personality: "for tests"
        )
        let a = species.vibe
        let b = species.vibe
        #expect(a == b)                       // Vibe is Hashable/Equatable
        #expect(a.hashValue == b.hashValue)
        #expect(a.body == Color(hex: 0xB6D98C))
        #expect(a.deep == Color(hex: 0x84B85E))
        #expect(a.accent == Color(hex: 0xFFFFFF))
        // Color(hex:) is itself pure: same literal -> equal Color.
        #expect(Color(hex: 0xB6D98C) == Color(hex: 0xB6D98C))
    }

    // MARK: Founding pool parity with founding_grant.sql

    /// The `v_pool` array transcribed verbatim from `docs/sql/founding_grant.sql`
    /// (14 entries — the codes-redeemable founding species). `founding-warmwelcome`
    /// and `founding-the very first` exist in the client but are granted outside
    /// this pool (referral / founder's own), so they are intentionally absent here.
    private static let sqlFoundingPool: [String] = [
        "founding-goldenhour", "founding-first light", "founding-daybreak no. 001",
        "founding-pearl", "founding-moonstone", "founding-rose quartz", "founding-opaline",
        "founding-aurora", "founding-dusklight", "founding-seafoam", "founding-honeyfeather",
        "founding-haloglow", "founding-starling no. 002", "founding-the og",
    ]

    @Test("The SQL v_pool has exactly 14 entries")
    func sqlPoolCount() {
        #expect(Self.sqlFoundingPool.count == 14)
    }

    @Test("Every SQL founding-pool id resolves to a client founding species")
    func sqlPoolResolvesInClient() {
        for id in Self.sqlFoundingPool {
            let species = SpeciesCatalog.founding(id: id)
            #expect(species != nil, "founding pool id \(id) missing from client catalog")
            #expect(species?.rarity == .founding)
        }
    }

    @Test("Client founding catalog is a superset of the SQL pool")
    func clientFoundingSupersetOfPool() {
        let clientIDs = Set(SpeciesCatalog.founding.map(\.id))
        #expect(Set(Self.sqlFoundingPool).isSubset(of: clientIDs))
        // The two referral-only foundings are present but not in the pool.
        #expect(clientIDs.contains("founding-warmwelcome"))
    }

    // MARK: DiscoveryEngine invariant (randomised — test the contract, not a value)

    /// Every id reachable through play: the Dex, which is the whole catalog minus the
    /// founding grants. This used to be the union of the six SpeciesSets, 32 of 203,
    /// which is what the engine could hand out at the time. Widening the engine without
    /// widening this would have left the suite asserting the old ceiling.
    private static var dexIDs: Set<String> { Set(SpeciesSets.dex) }

    @Test("pickNext never returns an already-discovered id", .timeLimit(.minutes(1)))
    func pickNextNeverReturnsDiscovered() {
        let pool = Array(Self.dexIDs)
        // Try many random "discovered" subsets and many draws each.
        for _ in 0..<200 {
            let cut = Int.random(in: 0..<pool.count)
            let discovered = Set(pool.shuffled().prefix(cut))
            for _ in 0..<10 {
                if let picked = DiscoveryEngine.pickNext(discovered: discovered) {
                    #expect(!discovered.contains(picked), "pickNext returned discovered id \(picked)")
                    #expect(Self.dexIDs.contains(picked), "pickNext returned unknown id \(picked)")
                }
            }
        }
    }

    /// Guards the regression directly: discovery must not run dry at 32.
    @Test("the dex is the whole catalog, not just the curated sets")
    func dexCoversTheCatalog() {
        #expect(SpeciesSets.dexTotal == SpeciesCatalog.standard.count)
        #expect(SpeciesSets.dexTotal > 200, "dex is \(SpeciesSets.dexTotal), expected the full catalog")
        // Every curated set is still a subset of the dex, so set progress stays meaningful.
        for set in SpeciesSets.all {
            for id in set.speciesIDs {
                #expect(Self.dexIDs.contains(id), "set \(set.id) references \(id), which is outside the dex")
            }
        }
    }

    @Test("pickNext returns nil only when everything is already discovered")
    func pickNextNilOnlyWhenExhausted() {
        // Everything discovered -> nil.
        #expect(DiscoveryEngine.pickNext(discovered: Self.dexIDs) == nil)
        // One short of everything -> must return the single remaining id.
        let all = Self.dexIDs
        let remaining = all.first!
        let discovered = all.subtracting([remaining])
        for _ in 0..<20 {
            #expect(DiscoveryEngine.pickNext(discovered: discovered) == remaining)
        }
    }
}
