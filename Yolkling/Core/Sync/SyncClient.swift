import Foundation

/// The two-layer data architecture:
///
/// - **SwiftData (local-first fallback):** the `Player` @Model is always the
///   instant, offline source of truth on-device. The app reads/writes it
///   directly, so it works fully with no network and no account.
/// - **Supabase (cloud DB):** a `SyncClient` pushes/pulls that state to the cloud
///   when the user is online and signed in (Sign in with Apple). The cloud is the
///   cross-device source of truth and powers the social layer.
///
/// They compose: every change lands in SwiftData immediately; the SyncClient
/// reconciles with Supabase in the background. If there's no account or no
/// connection, `LocalOnlySyncClient` is the fallback and nothing breaks.

/// A point-in-time snapshot of the syncable player state. Pure `Sendable` value.
struct PlayerSnapshot: Sendable, Equatable {
    var appleUserID: String
    var name: String
    var colorHex: Int
    var styleRaw: String
    var coins: Int
    var ownedItemIDs: [String]
    var equippedItemIDs: [String]
    var updatedAt: Date
}

/// The cloud boundary. Injected at the composition root so it can be swapped for
/// a fake in tests/previews and for the real Supabase client in production.
protocol SyncClient: Sendable {
    func push(_ snapshot: PlayerSnapshot) async throws
    func pull(appleUserID: String) async throws -> PlayerSnapshot?
}

/// Offline / not-signed-in fallback: no cloud, SwiftData is the only store.
/// Nothing fails when there's no account or no network.
struct LocalOnlySyncClient: SyncClient {
    func push(_ snapshot: PlayerSnapshot) async throws {}
    func pull(appleUserID: String) async throws -> PlayerSnapshot? { nil }
}

// SupabaseSyncClient (the cloud implementation) is built once we have the
// yolkling Supabase project access + the Sign in with Apple identity. It maps
// PlayerSnapshot to the `app_users` / `inventory` rows (see docs/sql/rewards.sql)
// over the Supabase client, keyed by appleUserID. Reconciliation: last-write-wins
// by updatedAt, with the server authoritative for friendship + IAP state. E2E:
// content is encrypted client-side before it leaves the device (Core/Crypto).
