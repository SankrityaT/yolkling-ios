import SwiftUI
import Observation

/// Bounded-context store for creation. The user directly picks a colour and a
/// base look, then names their yolkling. No quiz, no inference. MV architecture:
/// one `@Observable` store per context, no per-screen view models.
@MainActor
@Observable
final class HatchModel {

    enum Step: Equatable { case welcome, customize, hatching, naming, gift, health, focus, intro }

    private(set) var step: Step = .welcome
    private(set) var finalCreature: HatchedCreature?

    var colorHex: UInt = CreaturePalette.colors[0]
    var style: CreatureStyle = .classic

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

    func begin() { step = .customize }
    func goToHatching() { step = .hatching }
    func goToNaming() { step = .naming }
    func backToCustomize() { step = .customize }
    func goToHealth() { step = .health }
    func goToFocus() { step = .focus }

    /// Name the creature → advance to the welcome gift. Returns whether it took.
    @discardableResult
    func name(_ name: String) -> Bool {
        guard let creature = makeCreature(named: name) else { return false }
        finalCreature = creature
        step = .gift
        return true
    }

    func goToIntro() { step = .intro }

    private func makeCreature(named name: String) -> HatchedCreature? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return HatchedCreature(vibe: vibe, name: trimmed, colorHex: colorHex)
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
        case "intro":    finalCreature = makeCreature(named: "Pip"); step = .intro
        case "welcome":  step = .welcome
        default:         step = .customize
        }
    }
}
