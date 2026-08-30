import SwiftUI
import Observation
import YolklingCore

/// Bounded-context store for creation. The user directly picks a colour and a
/// base look, then names their yolkling. No quiz, no inference. MV architecture:
/// one `@Observable` store per context, no per-screen view models.
@MainActor
@Observable
final class HatchModel {

    enum Step: Equatable { case welcome, quiz, customize, hatching, naming, gift, health, focus, screenTime, intro }

    private(set) var step: Step = .welcome
    private(set) var finalCreature: HatchedCreature?

    var colorHex: UInt = CreaturePalette.colors[0]
    var style: CreatureStyle = .classic
    /// Which mood it hatches in. The quiz sets this; direct picking leaves it happy.
    var startingMood: Mood = .happy

    /// Set by the priming steps once the system prompt has actually been answered.
    var healthConnected = false
    var screenTimeConnected = false

    /// The live identity built from the current picks.
    var vibe: Vibe {
        Vibe(
            id: "yours",
            name: "yours",
            body: Color(hex: colorHex),
            deep: Color(hex: CreaturePalette.darker(colorHex)),
            style: style
        )
    }

    func selectColor(_ hex: UInt) { colorHex = hex }
    func selectStyle(_ s: CreatureStyle) { style = s }

    /// The quiz comes first, and hands its result to the customize screen — so nobody is
    /// forced through questions, and nobody starts on a blank grid either.
    func begin() { step = .quiz }
    func goToCustomize() { step = .customize }
    func goToHatching() { step = .hatching }
    func goToNaming() { step = .naming }
    func backToCustomize() { step = .customize }
    func goToHealth() { step = .health }
    func goToFocus() { step = .focus }
    func goToScreenTime() { step = .screenTime }

    /// Name the creature → advance to the welcome gift. Returns whether it took.
    @discardableResult
    func name(_ name: String) -> Bool {
        guard let creature = makeCreature(named: name) else { return false }
        finalCreature = creature
        step = .gift
        return true
    }

    func goToIntro() { step = .intro }

    /// Record what the player actually answered on a priming screen.
    ///
    /// `finalCreature` is built at naming, which happens two steps before either
    /// permission is asked for, so these write back onto it rather than being read at
    /// construction time. Declining is a real answer and is stored as one — the flow
    /// continues either way, and nothing here blocks onboarding on a permission.
    func recordHealth(_ granted: Bool) {
        healthConnected = granted
        finalCreature?.healthConnected = granted
    }

    func recordScreenTime(_ granted: Bool) {
        screenTimeConnected = granted
        finalCreature?.screenTimeConnected = granted
    }

    private func makeCreature(named name: String) -> HatchedCreature? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        // startingMood carries the quiz answer through to the saved creature — without
        // this the third question would visibly change the creature during onboarding
        // and then silently do nothing.
        return HatchedCreature(vibe: vibe, startingMood: startingMood, name: trimmed, colorHex: colorHex)
    }

    /// Three cute suggested names, themed to the chosen colour.
    var nameSuggestions: [String] { CreaturePalette.names(for: colorHex) }

    // MARK: Screenshot seam (only fires when YOLK_ONB is set)

    func jumpForDemo(_ name: String) {
        switch name {
        case "hatching": step = .hatching
        case "naming":   step = .naming
        case "gift":     finalCreature = makeCreature(named: "Pip"); step = .gift
        case "health":   finalCreature = makeCreature(named: "Pip"); step = .health
        case "focus":    finalCreature = makeCreature(named: "Pip"); step = .focus
        case "screentime": finalCreature = makeCreature(named: "Pip"); step = .screenTime
        case "intro":    finalCreature = makeCreature(named: "Pip"); step = .intro
        case "welcome":  step = .welcome
        case "quiz":     step = .quiz
        default:         step = .customize
        }
    }
}
