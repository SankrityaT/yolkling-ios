import Foundation
import Security

/// Keychain storage for the Supabase session.
///
/// Keychain rather than UserDefaults, which is where the rest of this app's small state
/// lives. A refresh token is a long-lived credential for somebody's account: UserDefaults
/// is a plist in the app container, readable from a backup or a jailbroken device, and
/// it is the wrong place for anything that can be replayed to impersonate a person.
///
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` on purpose:
///  - *AfterFirstUnlock* so a background refresh can still read it when the phone is
///    locked, which a stricter class would break.
///  - *ThisDeviceOnly* so it never travels in an iCloud or encrypted device backup. A
///    session should not be restorable onto a different phone from a backup file.
enum TokenStore {
    private static let service = "com.yolkling.ios.supabase"

    static func save(_ value: String, for key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var out: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ] as CFDictionary)
    }
}
