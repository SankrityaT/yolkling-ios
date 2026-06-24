import Foundation

/// App-level environment configuration.
///
/// The Supabase project URL and the anon (publishable) key live here on purpose.
/// The anon key is designed by Supabase to be embedded in client apps; Row Level
/// Security policies on the database enforce access control. The `service_role`
/// key (which bypasses RLS) and any database password must NEVER ship in the
/// binary, they stay in server-side tooling only.
enum AppEnvironment {

    /// Supabase project endpoint (shared with the waitlist project).
    static let supabaseURL = URL(string: "https://vlucekvrdxvpkvbizabz.supabase.co")!

    /// Public anon key. Safe to ship, RLS guards data access.
    static let supabaseAnonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsdWNla3ZyZHh2cGt2Yml6YWJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2NjY4ODAsImV4cCI6MjA5NzI0Mjg4MH0.r6XhJ6Suh_Azr3q7G1b6lYHfAS52j0B_y9Gbn7AREUA"

    static let supabaseProjectRef = "vlucekvrdxvpkvbizabz"
}

/// Single source of truth for public-facing URLs. Apple App Review rejects the
/// binary when the privacy URL in App Store Connect does not match the in-app
/// link, so these never drift. Validated once at launch via `assertWellFormed()`
/// so a typo crashes early with a clear message rather than mid-flow.
enum YolklingURLs {
    static let baseHost = "https://yolkling.com"
    static let supportEmail = "hey@yolkling.com"

    static var marketing: URL { resolve("") }
    static var privacy: URL { resolve("/privacy") }
    static var terms: URL { resolve("/terms") }

    static func assertWellFormed() {
        precondition(URL(string: baseHost) != nil, "YolklingURLs.baseHost is not a valid URL: \(baseHost)")
        precondition(URL(string: baseHost + "/privacy") != nil, "YolklingURLs privacy URL did not resolve.")
    }

    private static func resolve(_ path: String) -> URL {
        URL(string: baseHost + path) ?? URL(string: "https://yolkling.com")!
    }
}
