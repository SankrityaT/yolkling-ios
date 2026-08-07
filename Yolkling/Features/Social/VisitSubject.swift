import Foundation

/// Whose room you're standing in.
///
/// `VisitView` is already entirely snapshot-driven — it draws a creature and a room from
/// a `RoomSnapshot` and never needed to know who owned it. The only thing friendship
/// actually gated was which ACTIONS are offered. So this splits "what gets drawn" from
/// "what you're allowed to do", and one view serves both cases instead of forking a
/// near-identical DriftView.
enum VisitSubject: Identifiable, Equatable {
    case friend(Friend)
    case stranger(DriftTarget)

    var id: String { userID }

    var userID: String {
        switch self {
        case .friend(let f):   f.user_id
        case .stranger(let s): s.user_id
        }
    }

    var displayName: String {
        switch self {
        case .friend(let f):   f.displayName
        case .stranger(let s): s.displayName
        }
    }

    var snapshot: RoomSnapshot? {
        switch self {
        case .friend(let f):   f.snapshot
        case .stranger(let s): s.snapshot
        }
    }

    var isStranger: Bool {
        if case .stranger = self { return true }
        return false
    }

    /// Strangers may gift exactly this much, once a day, and they pay it themselves.
    /// Friends get the full ladder.
    var giftAmounts: [Int] { isStranger ? [10] : [10, 20, 50] }

    /// Header line. A stranger's room is a place you wandered into, not someone you know.
    var heading: String { isStranger ? "your yolkling wandered off" : "visiting" }

    static func == (a: VisitSubject, b: VisitSubject) -> Bool { a.userID == b.userID }
}
