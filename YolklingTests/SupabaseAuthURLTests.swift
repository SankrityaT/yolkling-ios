import Testing
import Foundation
@testable import Yolkling

/// The auth endpoint URL must keep its query string.
///
/// `URL.appending(path:)` percent-encodes its argument as one path component, so
/// "token?grant_type=id_token" became "token%3Fgrant_type=id_token" -- a route GoTrue
/// does not have. Every sign-in and every token refresh 404'd, silently, for the entire
/// life of the project: production had zero rows in auth.users. Without a session
/// `current_apple_user()` is null, so every `assert_caller` guard refused every real
/// player, and the whole backend was unreachable while looking merely "offline".
struct SupabaseAuthURLTests {

    private let base = URL(string: "https://example.supabase.co")!

    @Test func grantTypeSurvivesAsAQueryNotAPath() throws {
        let url = try #require(SupabaseAuth.authURL("token?grant_type=id_token", base: base))
        #expect(url.query() == "grant_type=id_token")
        #expect(url.path() == "/auth/v1/token")
        // The literal symptom, asserted directly so it cannot come back unnoticed.
        #expect(!url.absoluteString.contains("%3F"))
    }

    @Test func refreshGrantToo() throws {
        let url = try #require(SupabaseAuth.authURL("token?grant_type=refresh_token", base: base))
        #expect(url.query() == "grant_type=refresh_token")
        #expect(url.path() == "/auth/v1/token")
    }

    @Test func pathWithoutQueryIsUnchanged() throws {
        let url = try #require(SupabaseAuth.authURL("logout", base: base))
        #expect(url.path() == "/auth/v1/logout")
        #expect(url.query() == nil)
    }
}
