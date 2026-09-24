import Foundation

/// Whose coin balance is newer: this device's, or the server's.
///
/// One rule, in one place, because both the launch reconcile and the push response ask the
/// same question and the old answer ("take the bigger number") was wrong in one direction.
/// Coins go down when you spend and up when a friend gifts, so "bigger" cannot decide it;
/// only "newer" can. The version is bumped by whoever actually changed the balance: the
/// app on every local wallet change, `gift_yolks` when it credits server-side.
enum WalletSync {

    /// True when the server's balance should replace the local one.
    ///
    /// - A device that has never synced (`local == 0`) has no claim to make: it adopts,
    ///   which is what a fresh install after a restore needs.
    /// - Equal versions mean the same lineage, so nothing has changed since this device
    ///   last read the server, and the local number stands.
    static func adoptsServer(serverVersion: Int, localVersion: Int) -> Bool {
        localVersion == 0 || serverVersion > localVersion
    }
}
