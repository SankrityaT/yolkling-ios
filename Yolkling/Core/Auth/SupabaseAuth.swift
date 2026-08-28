import Foundation
import CryptoKit

/// Real identity for backend calls.
///
/// **The problem this exists to fix.** Every backend function took the user id as a
/// plain parameter (`p_user`) and every request authenticated with the anon key, which
/// ships inside the app binary. So the database had no way to tell who was calling, and
/// the id was simply asserted by whoever sent the request. Anyone could extract the key
/// from the IPA and call any of the 30 SECURITY DEFINER functions as anybody else:
/// read their wallet, alter their inventory, post as them, or call `delete_account` and
/// destroy their creature. The ids were not secret either, `get_friends` returns them
/// for every friend and `get_drift` hands out strangers' ids by design.
///
/// **The fix.** Trade the Apple identity token for a real Supabase session and send that
/// user's JWT instead of the anon key. The database can then derive the caller from the
/// token via `auth.uid()` rather than believing a parameter, which is the only way this
/// can be made safe: any client-side check is irrelevant to an attacker who is not using
/// our client.
///
/// This only became possible when Sign in with Apple became mandatory, because that is
/// what produces a verifiable identity token at the right moment.
@MainActor @Observable
final class SupabaseAuth {
    static let shared = SupabaseAuth()

    private enum Key {
        static let access = "access_token"
        static let refresh = "refresh_token"
        static let expiry = "expires_at"
    }

    private(set) var accessToken: String?
    private var refreshToken: String?
    private var expiresAt: Date?

    /// The nonce for the sign-in currently in flight. See `beginNonce()`.
    private var pendingNonce: String?

    private init() {
        accessToken = TokenStore.read(Key.access)
        refreshToken = TokenStore.read(Key.refresh)
        if let raw = TokenStore.read(Key.expiry), let t = TimeInterval(raw) {
            expiresAt = Date(timeIntervalSince1970: t)
        }
    }

    /// Whether we hold a session that is worth sending.
    var isSignedIn: Bool { accessToken != nil }

    // MARK: Nonce
    //
    // Sign in with Apple should be nonced, and Supabase needs the raw value to verify
    // the token it is handed. Apple receives the SHA256 hash and embeds it in the
    // identity token; we keep the raw string and send that alongside. Without this an
    // identity token captured anywhere else could be replayed into our backend.

    /// Generate a nonce, remember the raw value, and return the hash to give Apple.
    func beginNonce() -> String {
        let raw = Self.randomNonce()
        pendingNonce = raw
        return SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    // MARK: Sign in

    /// Exchange an Apple identity token for a Supabase session.
    ///
    /// Returns false rather than throwing: a failure here must never block getting into
    /// the app. The player still has their Apple id and everything works locally, they
    /// simply do not have a server session yet and we try again next launch.
    @discardableResult
    func signIn(appleIdentityToken: String) async -> Bool {
        var body: [String: Any] = ["provider": "apple", "id_token": appleIdentityToken]
        if let nonce = pendingNonce { body["nonce"] = nonce }
        pendingNonce = nil

        guard let json = await post("token?grant_type=id_token", body) else { return false }
        return store(json)
    }

    // MARK: Session

    /// A token good for right now, refreshing first if it is close to expiry.
    ///
    /// Refreshes 60s early. A token that expires between this check and the request
    /// landing is an avoidable failure, and the cost of being slightly eager is nothing.
    func validAccessToken() async -> String? {
        if let exp = expiresAt, exp.timeIntervalSinceNow < 60, refreshToken != nil {
            await refresh()
        }
        return accessToken
    }

    private func refresh() async {
        guard let refreshToken else { return }
        guard let json = await post("token?grant_type=refresh_token",
                                    ["refresh_token": refreshToken]) else {
            // A refresh token the server has rejected is worse than none: it will fail
            // forever. Drop the session so the next sign-in starts clean.
            signOut()
            return
        }
        _ = store(json)
    }

    func signOut() {
        accessToken = nil; refreshToken = nil; expiresAt = nil
        TokenStore.delete(Key.access)
        TokenStore.delete(Key.refresh)
        TokenStore.delete(Key.expiry)
    }

    // MARK: Plumbing

    @discardableResult
    private func store(_ json: [String: Any]) -> Bool {
        guard let access = json["access_token"] as? String else { return false }
        accessToken = access
        TokenStore.save(access, for: Key.access)

        if let r = json["refresh_token"] as? String {
            refreshToken = r
            TokenStore.save(r, for: Key.refresh)
        }
        let lifetime = (json["expires_in"] as? Double) ?? 3600
        let expiry = Date().addingTimeInterval(lifetime)
        expiresAt = expiry
        TokenStore.save(String(expiry.timeIntervalSince1970), for: Key.expiry)
        return true
    }

    private func post(_ path: String, _ body: [String: Any]) async -> [String: Any]? {
        var request = URLRequest(url: AppEnvironment.supabaseURL.appending(path: "auth/v1/\(path)"))
        request.httpMethod = "POST"
        request.setValue(AppEnvironment.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json
    }
}
