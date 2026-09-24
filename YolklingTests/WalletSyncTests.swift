import Testing
@testable import Yolkling

/// The bug these exist for: coins merged with `max()` on both the device and the server,
/// so a purchase could never lower the balance. Spend 400 Yolks, relaunch, and the older
/// higher number came back with the item still owned. Every purchase was refunded.
struct WalletSyncTests {

    @Test func spendingWinsOverTheServersOlderBalance() {
        // The device spent (version 5); the server still holds the pre-spend balance (4).
        #expect(WalletSync.adoptsServer(serverVersion: 4, localVersion: 5) == false)
    }

    @Test func aGiftCreditedServerSideIsAdopted() {
        // gift_yolks bumped the version past ours, so its number is the newer one.
        #expect(WalletSync.adoptsServer(serverVersion: 9, localVersion: 8) == true)
    }

    @Test func aFreshDeviceAdoptsTheServer() {
        // Never synced: a reinstall must arrive at the real balance, not the welcome grant.
        #expect(WalletSync.adoptsServer(serverVersion: 12, localVersion: 0) == true)
    }

    @Test func equalVersionsKeepTheLocalBalance() {
        // Same lineage, nothing changed server-side. Adopting here would undo a spend
        // made between the read and the push.
        #expect(WalletSync.adoptsServer(serverVersion: 7, localVersion: 7) == false)
    }

    @Test func serverMilesAheadStillWins() {
        #expect(WalletSync.adoptsServer(serverVersion: 40, localVersion: 3) == true)
    }
}
