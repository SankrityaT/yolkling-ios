import SwiftUI
import YolklingCore

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

    /// True when the last load could not reach the server. The UI needs it to tell
    /// "you have no friends" apart from "we couldn't ask", which used to render the
    /// brand-new-user empty state over a full friends list.
    private(set) var loadFailed = false

    func load() async {
        loading = true
        async let f = client.friends(userID: userID)
        async let p = client.postcards(userID: userID)
        let (fr, pc) = await (f, p)
        // On failure keep whatever we already had rather than blanking the screen.
        if let fr { friends = fr }
        if let pc { inbox = pc }
        // EITHER failing means we could not fully ask. With `&&`, a friends failure
        // alongside a successful postcards call left loadFailed false and the empty
        // state rendered "no friends yet" over a real friends list — the bug this flag
        // exists to prevent.
        loadFailed = (fr == nil || pc == nil)
        loading = false
    }

    /// Publish your own creature + room so friends can visit it.
    ///
    /// `isPublic` nil leaves the existing opt-in untouched — a routine sync must never
    /// silently un-publish a room its owner deliberately opened up.
    /// Returns whether the server confirmed it. Only meaningful when `isPublic` is set;
    /// the routine no-flag sync stays best-effort and callers may ignore the result.
    @discardableResult
    func publish(name: String, snapshot: RoomSnapshot, isPublic: Bool? = nil) async -> Bool {
        if let isPublic {
            return await client.publishRoom(userID: userID, name: name, snapshot: snapshot, isPublic: isPublic)
        } else {
            await client.publishRoom(userID: userID, name: name, snapshot: snapshot)
            return true
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

    // MARK: Wandering off on its own

    private var lastWanderKey: String { "yolk.lastWander.\(userID)" }

    var hasWanderedToday: Bool {
        guard let last = UserDefaults.standard.object(forKey: lastWanderKey) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    /// Your yolkling goes somewhere by itself.
    ///
    /// This is the last unmet promise on the landing page — *"it wanders off, visits
    /// someone, brings back a postcard"* — and per RETENTION.md it's the strongest
    /// variable reward in the whole design: a surprise you didn't ask for. Everything
    /// else in the app happens because you tapped a button.
    ///
    /// It is NOT a background job; that needs a server cron. It rolls on the first open
    /// of each day, which is honest enough — from the player's side it genuinely did
    /// happen while they were away, because they weren't here.
    ///
    /// Returns the room it landed in, or nil if it stayed home.
    func wanderIfDue() async -> DriftTarget? {
        guard !hasWanderedToday else { return nil }
        await loadDrift()
        guard let target = driftTargets.randomElement() else { return nil }
        guard await drift(to: target.user_id) else { return nil }
        UserDefaults.standard.set(Date(), forKey: lastWanderKey)
        return target
    }

    /// Send a postcard by vocabulary token. The server stores its own copy of the
    /// phrase, so the message can never be something the client invented.
    func sendPostcardToken(to: String, token: String) async -> (ok: Bool, reward: Int, reason: String?) {
        await client.sendPostcardToken(from: userID, to: to, token: token)
    }

    // MARK: Trading

    private(set) var trades: [TradeOffer] = []

    var incomingTrades: [TradeOffer] { trades.filter(\.incoming) }

    func loadTrades() async {
        trades = await client.trades(userID: userID)
    }

    func tradeable(with other: String) async -> (mine: [Cosmetic], theirs: [Cosmetic]) {
        let ids = await client.tradeable(userID: userID, with: other)
        func look(_ list: [String]) -> [Cosmetic] {
            list.compactMap { id in CosmeticCatalog.all.first { $0.id == id } }
        }
        return (look(ids.mine), look(ids.theirs))
    }

    func propose(to other: String, offer: String, want: String) async -> (ok: Bool, reason: String?) {
        let r = await client.proposeTrade(from: userID, to: other, offer: offer, want: want)
        if r.ok { await loadTrades() }
        return r
    }

    func respond(to trade: TradeOffer, accept: Bool) async -> (ok: Bool, reason: String?) {
        let r = await client.respondTrade(userID: userID, tradeID: trade.id, accept: accept)
        if r.ok { await loadTrades() }
        return r
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

    // MARK: Moderation (App Store 1.2 - required for user-generated postcards).

    /// Block a sender: removes the friendship both ways and hides their notes.
    /// Optimistically drops every surface they appear on, then refreshes from the server.
    ///
    /// `driftTargets` matters as much as `inbox` here: blocking someone whose room your
    /// creature could still wander into would leave them one postcard away from you.
    @discardableResult
    func block(_ otherID: String) async -> Bool {
        inbox.removeAll { $0.from_id == otherID }
        friends.removeAll { $0.user_id == otherID }
        driftTargets.removeAll { $0.user_id == otherID }
        let ok = await client.blockUser(userID: userID, blocked: otherID)
        await load()
        return ok
    }

    /// Report an objectionable postcard for review.
    @discardableResult
    func report(postcardID: Int, reason: String) async -> Bool {
        await client.reportPostcard(userID: userID, postcardID: postcardID, reason: reason)
    }

    @discardableResult
    func report(_ card: Postcard, reason: String = "objectionable") async -> Bool {
        await report(postcardID: card.id, reason: reason)
    }

    // MARK: Living Friends tab - waves, visits, gifts, lastVisited tracking.

    /// Whether the wave was actually delivered. This discarded the result, so both
    /// wave buttons flipped to "waved!" and locked out whether or not anything sent —
    /// an affirmative lie with no retry.
    func sendWave(to: String) async -> Bool {
        await client.sendWave(from: userID, to: to).ok
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
