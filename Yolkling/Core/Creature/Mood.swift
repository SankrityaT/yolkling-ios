import Foundation

/// The semantic emotion layer: a named mood maps to a concrete `Expression`
/// pose. The rest of the app speaks in `Mood` (derived by the mood resolver
/// from wellness + events); the renderer only ever sees the `Expression`.
///
/// Identity (`Vibe`) and emotion (`Mood`) are orthogonal: any vibe can wear any
/// mood. See `docs/research/07-creature-expression.md`.
enum Mood: String, CaseIterable, Sendable, Identifiable {
    case content, happy, excited, proud, affectionate
    case curious, surprised, sleepy, calm, playful
    case low, tired, unwell, waiting

    var id: String { rawValue }

    /// Human label for UI (capitalised).
    var label: String { rawValue.capitalized }

    /// The facial + body pose for this mood.
    var expression: YolkExpression {
        switch self {
        case .content:      .content
        case .happy:        .happy
        case .excited:      .excited
        case .proud:        .proud
        case .affectionate: .affectionate
        case .curious:      .curious
        case .surprised:    .surprised
        case .sleepy:       .sleepy
        case .calm:         .calm
        case .playful:      .playful
        case .low:          .low
        case .tired:        .tired
        case .unwell:       .unwell
        case .waiting:      .waiting
        }
    }
}
