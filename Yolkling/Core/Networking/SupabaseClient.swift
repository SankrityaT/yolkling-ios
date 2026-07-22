import Foundation

/// Minimal Supabase REST client (anon key, RLS-guarded) for the referral RPCs.
/// See docs/REWARDS.md + docs/sql/rewards.sql. Server-authoritative balances land
/// with the full sync layer (task: server-authoritative rewards).
struct SupabaseClient {
    static let shared = SupabaseClient()

    struct RedeemResult: Sendable {
        let ok: Bool
        let kind: String?     // "early_bird" | "referral"
        let bonus: Int
        let reason: String?
        let founding: String?  // granted founding species id, if any
    }

    /// The founding species this user owns (grant-only). Used to surface a grant
    /// the user earned as a referrer, who was offline when their friend redeemed.
    func myFounding(_ userID: String) async -> [String] {
        guard let data = await post("my_founding", ["p_user": userID]) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    /// Create the user's row if needed; returns their referral code.
    func ensureUser(_ userID: String) async -> String? {
        guard let data = await post("ensure_user", ["p_user": userID]) else { return nil }
        return try? JSONDecoder().decode(String.self, from: data)
    }

    /// Redeem a founder or referral code. Both parties are credited server-side.
    func redeem(code: String, userID: String) async -> RedeemResult {
        guard let data = await post("redeem_code", ["p_code": code, "p_user": userID]),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return RedeemResult(ok: false, kind: nil, bonus: 0, reason: "couldn't reach the server", founding: nil)
        }
        return RedeemResult(
            ok: obj["ok"] as? Bool ?? false,
            kind: obj["kind"] as? String,
            bonus: obj["bonus"] as? Int ?? 0,
            reason: obj["reason"] as? String,
            founding: obj["founding"] as? String
        )
    }

    /// Send a piece of in-app feedback (write-only; RLS-locked server side).
    func submitFeedback(userID: String, kind: String, message: String, version: String) async -> Bool {
        guard let data = await post("submit_feedback",
                                    ["p_user": userID, "p_kind": kind, "p_message": message, "p_version": version]),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return false }
        return obj["ok"] as? Bool ?? false
    }

    // MARK: Social (#17) — friends, pet houses, postcards. See docs/sql/social.sql.

    /// Become mutual friends by redeeming a friend's code (their referral code).
    func addFriend(code: String, userID: String) async -> AddFriendResult {
        guard let data = await postJSON("add_friend", ["p_user": userID, "p_code": code]),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return AddFriendResult(ok: false, friendID: nil, name: nil, reason: "offline") }
        return AddFriendResult(ok: obj["ok"] as? Bool ?? false,
                               friendID: obj["friend_id"] as? String,
                               name: obj["name"] as? String,
                               reason: obj["reason"] as? String)
    }

    /// Your friends + each one's latest published room snapshot.
    func friends(userID: String) async -> [Friend] {
        guard let data = await postJSON("get_friends", ["p_user": userID]) else { return [] }
        return (try? JSONDecoder().decode([Friend].self, from: data)) ?? []
    }

    /// Publish your own creature + room so friends can visit it.
    func publishRoom(userID: String, name: String, snapshot: RoomSnapshot) async {
        let snapObj = (try? JSONEncoder().encode(snapshot))
            .flatMap { try? JSONSerialization.jsonObject(with: $0) } ?? [:]
        _ = await postJSON("publish_room", ["p_user": userID, "p_name": name, "p_snapshot": snapObj])
    }

    /// Send a kind note. Returns whether it sent + any (sender-only, capped) reward.
    func sendPostcard(from: String, to: String, message: String) async -> (ok: Bool, reward: Int) {
        guard let data = await postJSON("send_postcard", ["p_from": from, "p_to": to, "p_message": message]),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return (false, 0) }
        return (obj["ok"] as? Bool ?? false, obj["reward"] as? Int ?? 0)
    }

    /// Your received postcards, newest first.
    func postcards(userID: String) async -> [Postcard] {
        guard let data = await postJSON("get_postcards", ["p_user": userID]) else { return [] }
        return (try? JSONDecoder().decode([Postcard].self, from: data)) ?? []
    }

    /// Mark the whole inbox read.
    func markPostcardsRead(userID: String) async {
        _ = await postJSON("mark_postcards_read", ["p_user": userID])
    }

    // MARK: Living Friends tab (#friends-tab-redesign) - waves, visits, gifts.

    /// Send a wave to a friend. Returns ok + optional reason on failure.
    func sendWave(from: String, to: String) async -> (ok: Bool, reason: String?) {
        guard let data = await postJSON("send_wave", ["p_from": from, "p_to": to]),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return (false, "offline") }
        return (obj["ok"] as? Bool ?? false, obj["reason"] as? String)
    }

    /// Fetch unseen waves for the user. Marks them seen on the server.
    func waves(userID: String) async -> [Wave] {
        guard let data = await postJSON("get_waves", ["p_user": userID]) else { return [] }
        return (try? JSONDecoder().decode([Wave].self, from: data)) ?? []
    }

    /// Log that visitor viewed owner's room (throttled server-side to once per day).
    func logVisit(visitor: String, owner: String) async {
        _ = await postJSON("log_visit", ["p_visitor": visitor, "p_owner": owner])
    }

    /// Fetch recent (7-day) distinct room visitors for the user.
    func recentVisits(userID: String) async -> [Visit] {
        guard let data = await postJSON("get_recent_visits", ["p_user": userID]) else { return [] }
        return (try? JSONDecoder().decode([Visit].self, from: data)) ?? []
    }

    /// Gift yolks to a friend. Returns ok, the sender's updated coin balance, and an optional failure reason.
    func giftYolks(from: String, to: String, amount: Int) async -> (ok: Bool, coins: Int?, reason: String?) {
        guard let data = await postJSON("gift_yolks", ["p_from": from, "p_to": to, "p_amount": amount]),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return (false, nil, "offline") }
        return (obj["ok"] as? Bool ?? false, obj["coins"] as? Int, obj["reason"] as? String)
    }

    // MARK: Moderation + account (App Store 1.2 UGC + 5.1.1(v)). See docs/sql/moderation.sql.

    /// Block a user: hides their content from you and yours from them, both ways.
    @discardableResult
    func blockUser(userID: String, blocked: String) async -> Bool {
        guard let data = await postJSON("block_user", ["p_user": userID, "p_blocked": blocked]),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return false }
        return obj["ok"] as? Bool ?? false
    }

    /// Report an objectionable postcard for review (recorded server-side).
    @discardableResult
    func reportPostcard(userID: String, postcardID: Int, reason: String) async -> Bool {
        guard let data = await postJSON("report_content",
                                        ["p_user": userID, "p_postcard": postcardID, "p_reason": reason]),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return false }
        return obj["ok"] as? Bool ?? false
    }

    /// Permanently delete the account and all its rows (friendships, rooms,
    /// postcards, inventory, redemptions). Required by App Store 5.1.1(v).
    @discardableResult
    func deleteAccount(userID: String) async -> Bool {
        guard let data = await postJSON("delete_user", ["p_user": userID]),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return false }
        return obj["ok"] as? Bool ?? false
    }

    // MARK: Wallet (#11) — durable + cross-device, keyed to Apple id. See docs/sql/wallet.sql.

    /// The server's current view of the player's wallet.
    func walletState(userID: String) async -> (coins: Int, owned: [String])? {
        guard let data = await postJSON("wallet_state", ["p_user": userID]),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return (obj["coins"] as? Int ?? 0, obj["owned"] as? [String] ?? [])
    }

    /// Push the local wallet up; returns the reconciled authoritative state to adopt.
    @discardableResult
    func pushWallet(userID: String, coins: Int, owned: [String]) async -> (coins: Int, owned: [String])? {
        guard let data = await postJSON("push_wallet", ["p_user": userID, "p_coins": coins, "p_owned": owned]),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return (obj["coins"] as? Int ?? coins, obj["owned"] as? [String] ?? owned)
    }

    private func post(_ function: String, _ body: [String: String]) async -> Data? {
        var request = URLRequest(url: AppEnvironment.supabaseURL.appending(path: "rest/v1/rpc/\(function)"))
        request.httpMethod = "POST"
        request.setValue(AppEnvironment.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppEnvironment.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode)
        else { return nil }
        return data
    }

    /// Like `post`, but the body can carry nested JSON (e.g. the room snapshot).
    private func postJSON(_ function: String, _ body: [String: Any]) async -> Data? {
        var request = URLRequest(url: AppEnvironment.supabaseURL.appending(path: "rest/v1/rpc/\(function)"))
        request.httpMethod = "POST"
        request.setValue(AppEnvironment.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppEnvironment.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode)
        else { return nil }
        return data
    }
}
