import Testing
@testable import Yolkling

/// Exercises `NameFilter`, the Guideline 1.2 filtering method for creature names.
/// Source of truth: `Yolkling/Core/Social/NameFilter.swift`.
///
/// The false-positive suite matters more than the blocking suite. A filter that misses a
/// slur gets caught by report and block, both of which ship. A filter that rejects
/// someone's chosen name insults a real person and there is no recovery from that, so
/// every name below is one a person could plausibly want.
@Suite("NameFilter")
struct NameFilterTests {

    // MARK: Names that must always be allowed

    @Test("Ordinary names pass")
    func ordinaryNamesPass() {
        for name in ["mochi", "Sunny", "Pebble", "Yolkers", "little guy",
                     "Sir Eggbert", "bao", "Cloud 9", "Mx. Yolk"] {
            #expect(NameFilter.check(name) == .ok, "rejected \(name)")
        }
    }

    @Test("Words that CONTAIN a blocked word are not blocked")
    func scunthorpeProblem() {
        // Every one of these embeds a term from the blocklist. This is the test that
        // fails the moment someone switches the token pass to a substring pass.
        for name in ["Scunthorpe",   // c-word
                     "assassin",     // ass
                     "bass",         // ass
                     "class",        // ass
                     "hello",        // hell
                     "Shelly",       // hell
                     "Michelle",     // hell
                     "shiitake",     // shit
                     "cucumber",     // cum
                     "title",        // tit
                     "Titan",        // tit
                     "Dickens",      // dick
                     "grape",        // rape
                     "cocktail",     // cock
                     "Cockburn"] {   // cock
            #expect(NameFilter.check(name) == .ok, "false positive on \(name)")
        }
    }

    // MARK: Names that must be blocked

    @Test("Plain profanity and slurs are blocked")
    func blocksPlainTerms() {
        for name in ["fuck", "Shit", "bitch", "faggot", "nigger", "retard", "hitler"] {
            #expect(NameFilter.check(name) == .blocked, "allowed \(name)")
        }
    }

    @Test("Blocked as a word inside a longer name")
    func blocksAsToken() {
        #expect(NameFilter.check("little shit") == .blocked)
        #expect(NameFilter.check("Mr Fuck") == .blocked)
    }

    @Test("Repeated letters do not evade")
    func squashesRuns() {
        #expect(NameFilter.check("fuuuuck") == .blocked)
        #expect(NameFilter.check("shiiiit") == .blocked)
    }

    @Test("Leetspeak does not evade")
    func decodesLeet() {
        #expect(NameFilter.check("sh1t") == .ok)      // 1 is deliberately not decoded
        #expect(NameFilter.check("$hit") == .blocked)
        #expect(NameFilter.check("f@ggot") == .blocked)
        #expect(NameFilter.check("b!tch") == .blocked)
    }

    @Test("Spacing letters out does not evade")
    func joinsSeparatedLetters() {
        #expect(NameFilter.check("f u c k") == .blocked)
        #expect(NameFilter.check("s h i t") == .blocked)
    }

    @Test("Accents do not evade")
    func foldsDiacritics() {
        #expect(NameFilter.check("fûck") == .blocked)
    }

    // MARK: Shape

    @Test("Empty and whitespace-only are .empty, not .blocked")
    func emptyIsItsOwnVerdict() {
        #expect(NameFilter.check("") == .empty)
        #expect(NameFilter.check("   ") == .empty)
    }

    @Test("Over the length limit is .tooLong, not .blocked")
    func lengthIsItsOwnVerdict() {
        #expect(NameFilter.check(String(repeating: "a", count: NameFilter.maxLength + 1)) == .tooLong)
        #expect(NameFilter.check(String(repeating: "a", count: NameFilter.maxLength)) == .ok)
    }

    @Test("Every non-ok verdict has a message, ok has none")
    func messagesExist() {
        #expect(NameFilter.message(for: .ok) == nil)
        for v in [NameFilter.Verdict.empty, .tooLong, .blocked] {
            #expect(NameFilter.message(for: v)?.isEmpty == false)
        }
    }
}
