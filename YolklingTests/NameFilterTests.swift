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
        // "1" IS now decoded, by checking the name as typed AND as "i" AND as "l".
        // It used to be left alone to protect names like M1lo and L1ly, but leaving it
        // made it a separator that destroyed the letters around it, so "n1gger" passed as
        // a creature name other players could see. Both readings are checked instead, and
        // the legitimate names below still pass because none of THEIR readings is blocked.
        #expect(NameFilter.check("sh1t") == .blocked)
        #expect(NameFilter.check("n1gger") == .blocked)
        #expect(NameFilter.check("d1ck") == .blocked)
        #expect(NameFilter.check("$hit") == .blocked)
        #expect(NameFilter.check("f@ggot") == .blocked)
        #expect(NameFilter.check("b!tch") == .blocked)
    }

    @Test("Spacing letters out does not evade")
    func joinsSeparatedLetters() {
        #expect(NameFilter.check("f u c k") == .blocked)
        #expect(NameFilter.check("s h i t") == .blocked)
        // ONE separator used to be enough. The joined-form check required three or more
        // single-character tokens, so "f u c k" was caught and "fu ck" was not, along with
        // every other profanity with a character poked into it. Measured before the fix:
        // twelve of thirteen evasions passed.
        #expect(NameFilter.check("fu ck") == .blocked)
        #expect(NameFilter.check("fu-ck") == .blocked)
        #expect(NameFilter.check("fu.ck") == .blocked)
        #expect(NameFilter.check("fuc k") == .blocked)
        #expect(NameFilter.check("c.unt") == .blocked)
    }

    /// The names the loosened matching could plausibly have caught, and does not.
    @Test("Joining tokens does not create false positives")
    func joiningIsSafe() {
        #expect(NameFilter.check("Bass Ackwards") == .ok)
        #expect(NameFilter.check("M1lo") == .ok)
        #expect(NameFilter.check("L1ly") == .ok)
        #expect(NameFilter.check("Cloud 9") == .ok)
        #expect(NameFilter.check("Cockburn") == .ok)
        #expect(NameFilter.check("Scunthorpe") == .ok)
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
