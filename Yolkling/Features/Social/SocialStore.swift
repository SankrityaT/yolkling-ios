import SwiftUI

/// Holds the live social state for the friends surface: your code, your friends
/// (with their pet-house snapshots), and your postcard inbox. Thin wrapper over
/// SupabaseClient so views stay declarative. See docs/sql/social.sql.
@MainActor @Observable
final class SocialStore {
    let userID: String
    var myCode: String
    private(set) var friends: [Friend] = []
    private(set) var inbox: [Postcard] = []
    private(set) var loading = false

    var unreadCount: Int { inbox.filter { !$0.read }.count }

    private let client = SupabaseClient.shared

    init(userID: String, myCode: String) {
        self.userID = userID
        self.myCode = myCode
    }

    /// Make sure we have a shareable code (the referral code doubles as the friend code).
    func ensureCode() async {
        if myCode.isEmpty, let c = await client.ensureUser(userID) { myCode = c }
    }

    func load() async {
        loading = true
        async let f = client.friends(userID: userID)
        async let p = client.postcards(userID: userID)
        let (fr, pc) = await (f, p)
        friends = fr
        inbox = pc
        loading = false
    }

    /// Publish your own creature + room so friends can visit it.
    ///
    /// `isPublic` nil leaves the existing opt-in untouched — a routine sync must never
    /// silently un-publish a room its owner deliberately opened up.
    func publish(name: String, snapshot: RoomSnapshot, isPublic: Bool? = nil) async {
        if let isPublic {
            await client.publishRoom(userID: userID, name: name, snapshot: snapshot, isPublic: isPublic)
        } else {
            await client.publishRoom(userID: userID, name: name, snapshot: snapshot)
        }
    }

    // MARK: Drift — wandering into strangers' rooms.

    private(set) var driftTargets: [DriftTarget] = []

    /// Whether this player's room is open to strangers. Mirrored locally so the UI can
    /// ask before the network answers; the server remains authoritative.
    ///
    /// Drift is deliberately RECIPROCAL: you can only wander into open rooms, so you
    /// open yours first. That isn't a toll — it's what keeps the pool from being all
    /// visitors and no hosts.
    var roomIsPublic: Bool {
        get { UserDefaults.standard.bool(forKey: "yolk.roomPublic.\(userID)") }
        set { UserDefaults.standard.set(newValue, forKey: "yolk.roomPublic.\(userID)") }
    }

    /// Where your yolkling could wander today.
    func loadDrift() async {
        driftTargets = await client.drift(userID: userID)
    }

    /// Land on a stranger. MUST succeed before any wave/note/gift is offered — the
    /// server refuses those to someone you haven't drifted to, and a refusal there
    /// surfaces as "not_friends", which would read as nonsense to the user.
    func drift(to targetID: String) async -> Bool {
        await client.logDrift(from: userID, to: targetID)
    }

    /// Send a postcard by vocabulary token. The server stores its own copy of the
    /// phrase, so the message can never be something the client invented.
    func sendPostcardToken(to: String, token: String) async -> (ok: Bool, reward: Int, reason: String?) {
        await client.sendPostcardToken(from: userID, to: to, token: token)
    }

    // MARK: Moderation

    @discardableResult
    func block(_ targetID: String) async -> Bool {
        let ok = await client.blockUser(userID: userID, blocked: targetID)
        if ok {
            driftTargets.removeAll { $0.user_id == targetID }
            await load()
        }
        return ok
    }

    @discardableResult
    func report(postcardID: Int, reason: String) async -> Bool {
        await client.reportPostcard(userID: userID, postcardID: postcardID, reason: reason)
    }

    func addFriend(code: String) async -> AddFriendResult {
        let r = await client.addFriend(code: code.uppercased(), userID: userID)
        if r.ok { await load() }
        return r
    }

    /// Send a kind note. Returns (sent, reward). Reward is sender-only + server-capped.
    func sendPostcard(to: String, message: String) async -> (ok: Bool, reward: Int) {
        await client.sendPostcard(from: userID, to: to, message: message)
    }

    func markInboxRead() async {
        await client.markPostcardsRead(userID: userID)
        await load()
    }

    // MARK: Living Friends tab - waves, visits, gifts, lastVisited tracking.

    func sendWave(to: String) async {
        _ = await client.sendWave(from: userID, to: to)
    }

    func loadWaves() async -> [Wave] {
        await client.waves(userID: userID)
    }

    func logVisit(owner: String) async {
        await client.logVisit(visitor: userID, owner: owner)
    }

    func loadRecentVisits() async -> [Visit] {
        await client.recentVisits(userID: userID)
    }

    func giftYolks(to: String, amount: Int) async -> (ok: Bool, coins: Int?, reason: String?) {
        await client.giftYolks(from: userID, to: to, amount: amount)
    }

    // MARK: lastVisited - persisted per-friend visit timestamps in UserDefaults.

    private static let lastVisitedKey = "social.lastVisited"

    private var lastVisitedMap: [String: Date] {
        get {
            guard let data = UserDefaults.standard.data(forKey: Self.lastVisitedKey),
                  let dict = try? JSONDecoder().decode([String: Date].self, from: data)
            else { return [:] }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Self.lastVisitedKey)
            }
        }
    }

    func lastVisited(_ id: String) -> Date? {
        lastVisitedMap[id]
    }

    func markVisited(_ id: String) {
        var map = lastVisitedMap
        map[id] = Date()
        lastVisitedMap = map
    }
}
