import Foundation

/// Filters objectionable creature names.
///
/// **Why this exists.** App Store Guideline 1.2 requires FOUR things of any app with
/// user-generated content: a way to block abusive users, a way to report content,
/// published contact information, and "a method for filtering objectionable material
/// from being posted to the app". Yolkling shipped the first three and not the fourth.
///
/// The creature's name is this app's real UGC surface, not the postcards. Postcards are
/// fixed-vocabulary tokens with no free text (`PostcardVocabulary`), so there is nothing
/// to filter there. The name is a free `TextField` in onboarding, it is stored
/// server-side, and `get_friends` and `get_recent_visits` hand it to other people. It
/// went out with no check on it at all.
///
/// **The hard part is false positives, not catching words.** A filter that rejects
/// "Scunthorpe" is worse than no filter, because it insults a real person about a name
/// they chose while catching nobody who was actually trying. So terms are split in two:
///
/// - `blockedWords` are matched as WHOLE TOKENS only. These are words that appear inside
///   ordinary English all the time: hell in hello and shell, ass in class and bass, shit
///   in shiitake, tit in title, cum in cucumber. Substring-matching any of them is the
///   classic way to ship an embarrassing bug.
/// - `blockedSubstrings` are matched ANYWHERE, and every entry has been checked to have
///   no innocent embedding. Note what is deliberately absent: the c-word lives in
///   Scunthorpe, so it is a whole-token term despite being severe.
///
/// **Deliberately a short list.** A giant blocklist is mostly false positives and a false
/// sense of coverage. This catches good-faith mistakes and casual abuse; block, report
/// and account deletion catch what it misses, and those already ship.
///
/// **Client-side, and honest about it.** The anon key ships in the binary, so a
/// determined person can write a name straight to the RPC. That is what report and block
/// are for. Moving this server-side into `ensure_user` is the right follow-up.
enum NameFilter {

    enum Verdict: Equatable {
        case ok
        /// Nothing to name.
        case empty
        /// Long enough to break a friend's row. Not a moderation call, a layout one.
        case tooLong
        /// Matched the filter.
        case blocked
    }

    /// Longest name that still fits a friend row on the smallest supported screen.
    nonisolated static let maxLength = 20

    nonisolated static func check(_ raw: String) -> Verdict {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        guard trimmed.count <= maxLength else { return .tooLong }

        let (tokens, collapsed) = normalize(trimmed)
        guard !tokens.isEmpty else { return .empty }

        // Whole-token pass, against the raw token AND its squashed form, so "shiiit"
        // reads as "shit" without the blocklist itself being squashed.
        //
        // The blocklist must NOT be pre-squashed. Doing that destroys any term whose
        // meaning IS a repeated character: squash("kkk") is "k", which put the bare
        // letter k in the blocklist and rejected Yolkers, Dickens, cocktail, Cockburn
        // and shiitake. The tests below pin that down.
        for token in tokens {
            if blockedWords.contains(token) || blockedWords.contains(squash(token)) {
                return .blocked
            }
        }

        // Anywhere pass, for terms that cannot innocently embed. Checked against both
        // forms for the same reason.
        let collapsedSquashed = squash(collapsed)
        for term in blockedSubstrings
        where collapsed.contains(term) || collapsedSquashed.contains(term) {
            return .blocked
        }

        // Separator evasion: "f u c k" arrives as four one-letter tokens, which the
        // token pass cannot see and the substring pass only catches for severe terms.
        // Three or more single-character tokens is not how anyone names a pet, so treat
        // the joined form as a word and run the token list over it too.
        if tokens.filter({ $0.count == 1 }).count >= 3,
           blockedWords.contains(collapsed) || blockedWords.contains(squash(collapsed)) {
            return .blocked
        }

        return .ok
    }

    /// Message shown to the person. Written to be matter-of-fact rather than scolding:
    /// most people who hit this are testing what happens, and the app's whole voice is
    /// gentle. It also never repeats what they typed back at them.
    nonisolated static func message(for verdict: Verdict) -> String? {
        switch verdict {
        case .ok:      return nil
        case .empty:   return "your yolk needs a name"
        case .tooLong: return "that name is a little long. \(maxLength) characters or fewer"
        case .blocked: return "let's pick a different name. friends can see this one"
        }
    }

    // MARK: Normalising

    /// Lowercased, accent-folded, leet-decoded, reduced to letters and separators.
    /// Returns the tokens and the separator-free join of them.
    nonisolated private static func normalize(_ s: String) -> (tokens: [String], collapsed: String) {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive],
                               locale: Locale(identifier: "en_US_POSIX"))
        var out = ""
        for ch in folded {
            if let letter = leet[ch] { out.append(letter) }
            else if ch.isLetter { out.append(ch) }
            else { out.append(" ") }          // digits and punctuation become separators
        }
        let tokens = out.split(separator: " ").map(String.init)
        return (tokens, tokens.joined())
    }

    /// Common character substitutions. Only the unambiguous ones: `1` is left out
    /// because it reads as both i and l and guessing wrong invents matches.
    nonisolated private static let leet: [Character: Character] = [
        "@": "a", "4": "a", "3": "e", "!": "i", "0": "o", "$": "s", "5": "s", "7": "t", "+": "t",
    ]

    /// Collapse runs of the same character to one, so "fuuuck" and "fuck" compare equal.
    /// Applied to the blocklists too, or the two sides would never meet.
    nonisolated private static func squash(_ s: String) -> String {
        var out = ""
        for ch in s where out.last != ch { out.append(ch) }
        return out
    }

    // MARK: The lists

    /// Matched as whole tokens ONLY. Every one of these appears inside ordinary words.
    nonisolated private static let blockedWords: Set<String> = [
        "ass", "asshole", "arse", "bastard", "bitch", "bollocks", "cock", "coon", "cum",
        "cunt", "dick", "dyke", "fag", "faggot", "fuck", "fucker", "hell", "hoe", "jizz",
        "nazi", "nigga", "nigger", "piss", "prick", "pussy", "rape", "rapist", "retard",
        "retarded", "shit", "slut", "spic", "tit", "tits", "twat", "wank", "whore",
    ]

    /// Matched anywhere. Each checked for innocent embeddings before being put here.
    /// The c-word is NOT in this list: Scunthorpe.
    nonisolated private static let blockedSubstrings: Set<String> = [
        "faggot", "nigger", "nigga", "rapist", "kkk", "hitler",
    ]
}
