# Friends Tab Redesign - Task 2 Report

## Summary

Task 2 (client data layer) is complete. Build green, live decode verified, temp seam removed.

---

## Step 1: New model fields and structs (SocialModels.swift)

### Wave

```swift
struct Wave: Codable, Sendable, Identifiable {
    let from_id: String
    let name: String?
    let created_at: String
    var id: String { from_id }
    var senderName: String { (name?.isEmpty == false ? name : nil) ?? "a friend" }
}
```

Decodes `get_waves` shape: `{ "from_id": string, "name": string|null, "created_at": string }`.

### Visit

```swift
struct Visit: Codable, Sendable, Identifiable {
    let visitor_id: String
    let name: String?
    let created_at: String
    var id: String { visitor_id }
    var visitorName: String { (name?.isEmpty == false ? name : nil) ?? "a friend" }
}
```

Decodes `get_recent_visits` shape: `{ "visitor_id": string, "name": string|null, "created_at": string }`.

### RoomSnapshot additions

Added `var streak: Int?` and `var hour: Int?` as stored properties. The existing custom `init(from:)` decoder was extended with:

```swift
streak = try c.decodeIfPresent(Int.self, forKey: .streak)
hour   = try c.decodeIfPresent(Int.self, forKey: .hour)
```

Both default to `nil` when absent (lenient decode). The canonical `init(...)` gained `streak: Int? = nil, hour: Int? = nil` with defaults so all existing call sites compile unchanged.

### Friend additions

Added `var updated_at: String? = nil` (with default so existing memberwise init calls are unaffected) and computed helper:

```swift
var updatedDate: Date? {
    guard let s = updated_at else { return nil }
    return ISO8601DateFormatter().date(from: s)
}
```

---

## Step 2: SupabaseClient RPC methods (SupabaseClient.swift)

All five methods use the existing `postJSON(_:_:)` helper and match the decode pattern of `addFriend`/`sendPostcard`/`postcards`.

| Method | RPC | Return |
|--------|-----|--------|
| `sendWave(from:to:)` | `send_wave` | `(ok: Bool, reason: String?)` |
| `waves(userID:) -> [Wave]` | `get_waves` | `JSONDecoder().decode([Wave].self, from:)` |
| `logVisit(visitor:owner:)` | `log_visit` | void (fire-and-forget) |
| `recentVisits(userID:) -> [Visit]` | `get_recent_visits` | `JSONDecoder().decode([Visit].self, from:)` |
| `giftYolks(from:to:amount:)` | `gift_yolks` | `(ok: Bool, coins: Int?, reason: String?)` |

---

## Step 3: SocialStore methods + lastVisited (SocialStore.swift)

### New async methods

```swift
func sendWave(to: String) async
func loadWaves() async -> [Wave]
func logVisit(owner: String) async
func loadRecentVisits() async -> [Visit]
func giftYolks(to: String, amount: Int) async -> (ok: Bool, coins: Int?, reason: String?)
```

All wrap the matching `SupabaseClient` method with `userID` filled in.

### lastVisited persistence

Stored as `[String: Date]` in `UserDefaults` under key `social.lastVisited`. Encoded/decoded via `JSONEncoder`/`JSONDecoder` (which encode `Date` as ISO 8601 by default).

```swift
func lastVisited(_ id: String) -> Date?   // reads from UserDefaults
func markVisited(_ id: String)            // writes now() into the map
```

---

## Build result

`** BUILD SUCCEEDED **` -- both with and without the SOCIALCHECK seam (two separate builds).

---

## SOCIALCHECK verify result

Seam placed in `RootView.swift` as `SocialCheckPreview` (private struct), launched with `SIMCTL_CHILD_YOLK_SOCIALCHECK=1`. Screenshot `/tmp/task2-social.png` shows:

- Header: "SOCIAL CHECK"
- "waves: 0"
- "visits: 0"

No crash, no red screen. Empty arrays returned from live RPCs for a fresh install user -- confirmed pass. The decode path hit both `get_waves` and `get_recent_visits` RPCs against the live Supabase backend (`vlucekvrdxvpkvbizabz`).

## Temp seam removal

`SocialCheckPreview` struct and the `YOLK_SOCIALCHECK` branch have been removed from `RootView.swift`. Final rebuild confirmed `** BUILD SUCCEEDED **`.

---

## Files changed

- `Yolkling/Core/Networking/SocialModels.swift` -- Wave, Visit structs; RoomSnapshot.streak/hour; Friend.updated_at/updatedDate
- `Yolkling/Core/Networking/SupabaseClient.swift` -- sendWave, waves, logVisit, recentVisits, giftYolks
- `Yolkling/Features/Social/SocialStore.swift` -- sendWave, loadWaves, logVisit, loadRecentVisits, giftYolks, lastVisited, markVisited
- `Yolkling/App/RootView.swift` -- temp seam added then removed (no net change from original)
