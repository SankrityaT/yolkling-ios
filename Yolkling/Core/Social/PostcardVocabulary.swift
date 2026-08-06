import Foundation

/// Everything a yolkling is able to say on a postcard.
///
/// Postcards are composed by **selection, never free text**. That started as a product
/// decision — creatures don't type, and a text box between strangers is a different
/// product than the one described in `docs/RETENTION.md` — but it also takes the app
/// out of scope for App Store Guideline 1.2 entirely: no user-generated content means
/// no moderation queue, no reporting flow, and no way to send anyone something unkind.
///
/// A client-side list alone isn't a guarantee (anyone holding the anon key can call the
/// RPC directly), so the same vocabulary gets mirrored into a server table and enforced
/// by `send_postcard_v2`. Until then this is the only thing in the app that can produce
/// a message, which closes the UI-level risk.
enum PostcardVocabulary {

    struct Phrase: Identifiable, Hashable, Sendable {
        let id: String
        let text: String
    }

    enum Category: String, CaseIterable, Identifiable, Sendable {
        case warmth, cheer, comfort, silly

        var id: String { rawValue }

        var title: String {
            switch self {
            case .warmth:  "warm"
            case .cheer:   "cheer"
            case .comfort: "comfort"
            case .silly:   "silly"
            }
        }
    }

    static func phrases(in category: Category) -> [Phrase] {
        switch category {
        case .warmth:
            [
                Phrase(id: "w1", text: "thinking of you"),
                Phrase(id: "w2", text: "your room looks so cozy"),
                Phrase(id: "w3", text: "glad you're around"),
                Phrase(id: "w4", text: "just came by to say hi"),
                Phrase(id: "w5", text: "you crossed my mind today"),
                Phrase(id: "w6", text: "sending a little sunshine"),
                Phrase(id: "w7", text: "it's nicer here with you in it"),
                Phrase(id: "w8", text: "hope someone's been kind to you"),
                Phrase(id: "w9", text: "no reason, just wanted to wave"),
                Phrase(id: "w10", text: "saved you a warm spot"),
            ]
        case .cheer:
            [
                Phrase(id: "c1", text: "you've got this"),
                Phrase(id: "c2", text: "proud of you today"),
                Phrase(id: "c3", text: "one small thing at a time"),
                Phrase(id: "c4", text: "that was brave"),
                Phrase(id: "c5", text: "look how far you've come"),
                Phrase(id: "c6", text: "cheering from over here"),
                Phrase(id: "c7", text: "you did the hard part already"),
                Phrase(id: "c8", text: "keep going, gently"),
                Phrase(id: "c9", text: "today counts too"),
                Phrase(id: "c10", text: "worth it, promise"),
            ]
        case .comfort:
            [
                Phrase(id: "m1", text: "hope your day is gentle"),
                Phrase(id: "m2", text: "rest is allowed"),
                Phrase(id: "m3", text: "it's okay to go slow"),
                Phrase(id: "m4", text: "drink some water, love"),
                Phrase(id: "m5", text: "the hard bit passes"),
                Phrase(id: "m6", text: "you don't have to do it all"),
                Phrase(id: "m7", text: "go outside for a minute"),
                Phrase(id: "m8", text: "sleep well tonight"),
                Phrase(id: "m9", text: "nothing to fix, just breathe"),
                Phrase(id: "m10", text: "put the phone down, it'll keep"),
            ]
        case .silly:
            [
                Phrase(id: "s1", text: "my yolk tracked mud in your room, sorry"),
                Phrase(id: "s2", text: "yours has excellent taste in hats"),
                Phrase(id: "s3", text: "we napped. it was productive."),
                Phrase(id: "s4", text: "borrowed a snack. no regrets."),
                Phrase(id: "s5", text: "your yolk is showing off again"),
                Phrase(id: "s6", text: "wobbled all the way here"),
                Phrase(id: "s7", text: "ten out of ten room, would visit again"),
                Phrase(id: "s8", text: "rolled over. that's the whole update."),
                Phrase(id: "s9", text: "came for the vibes, stayed too long"),
                Phrase(id: "s10", text: "left a tiny mess as a gift"),
            ]
        }
    }

    static var all: [Phrase] { Category.allCases.flatMap { phrases(in: $0) } }

    /// Whether a message could have come from this vocabulary. Mirrors what the server
    /// will enforce; useful as a client-side assertion and for tests.
    static func isValid(_ text: String) -> Bool {
        all.contains { $0.text == text }
    }
}
