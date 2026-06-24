import Foundation

/// The relationship arc between you and your yolk, earned only by taking care of
/// YOURSELF. Each stage unlocks behaviour (eye contact, waving, celebrating). See
/// docs/RELATIONSHIP.md. Gentle by design: trust never drops to punish you, it just
/// eases back a stage when you've been away, and re-warms fast.
enum TrustStage: Int, CaseIterable, Sendable {
    case stranger, warming, friend, companion, devoted

    /// Map a 0...1 trust value to a stage.
    static func from(trust: Double) -> TrustStage {
        switch trust {
        case ..<0.2:  return .stranger
        case ..<0.45: return .warming
        case ..<0.7:  return .friend
        case ..<0.9:  return .companion
        default:      return .devoted
        }
    }

    /// The line shown under the creature.
    var label: String {
        switch self {
        case .stranger:  return "getting to know you"
        case .warming:   return "warming up to you"
        case .friend:    return "starting to trust you"
        case .companion: return "your companion"
        case .devoted:   return "devoted to you"
        }
    }

    /// Waves hello once it considers you a friend.
    var waves: Bool { rawValue >= TrustStage.friend.rawValue }

    /// Celebrates your self-care wins once you're companions.
    var celebrates: Bool { rawValue >= TrustStage.companion.rawValue }
}
