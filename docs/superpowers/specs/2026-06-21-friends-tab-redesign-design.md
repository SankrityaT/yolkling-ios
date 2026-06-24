# Friends Tab Redesign — a living social tab

Date: 2026-06-21
Status: Approved design (full scope), ready for implementation plan

## Problem

The Friends tab is functional but lifeless: your share code, an add-by-code field, a
plain list of friends (tap to visit their room), and a postcard inbox. It is cozy but
static. We want it to feel alive and mutual, while keeping the brand's no-likes,
no-followers, no-pressure ethos.

## Goals (the four pillars the user chose, all in v1)

1. **Living presence** — friends shown as live mini-room cards with gentle ambient
   status (redecorated / mood / asleep / streak).
2. **Little interactions** — wave (yolk waves back), leave a note (postcard), and gift
   a few Yolks. No likes/comments/counts.
3. **What's new / reciprocity** — a count-free "while you were away" strip: who waved,
   who visited your room, who redecorated.
4. **Easier to grow** — share link, a QR you can show, QR scan to add in person,
   clearer invite reward, better empty state.

## Non-goals (YAGNI)

- Public profiles, follower counts, likes, comments, a global feed.
- Real-time presence/co-visiting (no live sockets; everything is pull + best-effort).
- Friend requests/approval flow (adding by code is mutual + instant, as today).

## Backend (Supabase project `vlucekvrdxvpkvbizabz`)

Existing (reuse): `app_users(apple_user_id, referral_code, coins)`, `inventory`,
`friendships`, `room_snapshots(user_id, name, snapshot jsonb, updated_at)`,
`postcards`, RPCs `add_friend`, `get_friends` (RETURNS `updated_at` already),
`publish_room`, `wallet_state`, `push_wallet`, `send/get postcards`.

Migrations are applied to project `vlucekvrdxvpkvbizabz` via the Supabase Management
API query endpoint using the PAT in `/Users/sankiii/yolkling-app/.env.local`
(`SUPABASE_ACCESS_TOKEN`). That token is an account secret: read it from the file, never
print/echo it, never commit it. The connected Supabase MCP is a DIFFERENT org and must
NOT be used for this project. After DDL, run `notify pgrst, 'reload schema'`.

New schema + RPCs (one new migration file `docs/sql/social-living.sql`):

- **waves**: `id bigint identity pk, from_id text, to_id text, created_at timestamptz
  default now(), seen_at timestamptz`. FKs to `app_users`, indexes on `(to_id,
  seen_at)`.
  - `send_wave(p_from text, p_to text) returns jsonb` — must be friends; rate-limit to
    one unseen wave per (from,to) (on-conflict-do-nothing or delete-prior-unseen);
    returns `{ok:true}`.
  - `get_waves(p_user text) returns jsonb` — unseen waves to me with sender name; marks
    them seen (set `seen_at = now()` for the returned rows in the same call).
- **visits**: `id bigint identity pk, visitor_id text, owner_id text, created_at
  timestamptz default now()`. Index `(owner_id, created_at)`.
  - `log_visit(p_visitor text, p_owner text) returns void` — throttle to at most one row
    per (visitor, owner) per day (skip insert if one exists today). Called when you open
    a friend's room.
  - `get_recent_visits(p_user text) returns jsonb` — recent DISTINCT visitors to MY room
    (last ~7 days), with names, newest first.
- **gifts** (anti-abuse log): `id bigint identity pk, from_id text, to_id text, amount
  int, created_at timestamptz default now()`. Index `(from_id, created_at)`.
  - `gift_yolks(p_from text, p_to text, p_amount int) returns jsonb` — SECURITY DEFINER,
    atomic: must be friends; `p_amount` in {10,20,50}; enforce a daily cap (sum of
    today's gifts from `p_from` + `p_amount` <= 100); require sender `coins >= p_amount`;
    `update app_users set coins = coins - p_amount where from`; `... coins = coins +
    p_amount where to`; insert a gifts row; return `{ok:true, coins:<sender new
    balance>}` or `{ok:false, reason:...}`.
- Grants: all new RPCs `to anon, authenticated`. RLS on the tables consistent with the
  existing social tables (RPCs are SECURITY DEFINER; tables not directly selectable by
  clients).

Note on the wallet's last-write-wins push model: `gift_yolks` mutates `app_users.coins`
server-side. The sender's client must immediately adopt the returned new balance (and
not re-push a stale higher local balance); the receiver sees the credit on its next
`wallet_state` pull (launch / sign-in / periodic). Acceptable for a cozy gift.

## Client architecture

### Models / store (`Features/Social/`)
- `SocialModels.swift` — add `Wave { fromName }`, `Visit { visitorName, createdAt }`
  decodables; add OPTIONAL `streak: Int?` and `hour: Int?` to `RoomSnapshot` (Codable,
  migration-safe) so presence can show streak + asleep.
- `SocialStore.swift` — add: `sendWave(to:)`, `loadWaves() -> [Wave]`,
  `logVisit(owner:)`, `loadRecentVisits() -> [Visit]`, `giftYolks(to:amount:) ->
  (ok, coins)`. Plus `lastVisited: [friendID: Date]` persisted locally (UserDefaults or
  the Player) to compute "new since last visit" against each friend's `updated_at`.
- `SupabaseClient` — matching methods hitting the new RPCs.

### Publishing presence
The widget/social publisher already builds a `RoomSnapshot`. Add `streak` (the player's
`careStreak`) and `hour` (current local hour) to the published snapshot so friends can
render "5-day streak" and "asleep" (hour in the night phase). No schema change (jsonb).

### Views (`Features/Social/`)
- `FriendsView.swift` (rewrite) — one scroll:
  1. Header: "friends" + inbox button (unread postcards badge).
  2. `WhileYouWereAwayStrip` — shown only if non-empty: waves received + recent visits
     to me + friends who redecorated (count-free lines, each tappable to that friend).
  3. `FriendsGrid` — 2-col grid of `FriendRoomCard`.
  4. `GrowFriendsSection` — add-by-code field, share link, show-QR, scan button, invite
     reward + empty-state copy when you have no friends.
- `FriendRoomCard.swift` (new) — a live mini `RoomView` from the friend's snapshot +
  name + status row (`✨ new` if `updated_at` > my lastVisited; mood; `😴` if their
  `hour` is night; `🔥 streak`). A small `👋` wave button. Tap card → VisitView.
- `VisitView.swift` (enhance) — their live room + actions: `👋 wave`, `💌 leave a note`
  (existing postcard compose), `🎁 gift yolks` (10/20/50 picker). Calls `logVisit` on
  open. Keeps the existing visit reward.
- `ShareInviteView` / inline — `ShareLink` for `https://yolkling.com/add/<code>` (or the
  raw code), a `QRCodeView` (CoreImage `CIQRCodeGenerator`, pure client), and a
  `QRScannerView` (AVFoundation; on detect, extract the code and call addFriend).
- `WhileYouWereAwayStrip.swift` (new).

### Permissions
- QR scan needs camera: add `INFOPLIST_KEY_NSCameraUsageDescription` in `project.yml`
  ("Scan a friend's code to add them.") — copy with no em dashes.

## Data / privacy / migration

- New `RoomSnapshot.streak`/`.hour` are OPTIONAL (old snapshots decode fine).
- `lastVisited` map persisted locally; no server change for "new".
- Shared-with-friends-only new signals: streak + rough time-of-day. Both positive/cozy.
  (If the user later wants streak private, it is one field to drop from publish.)
- Gifts: daily cap 100 Yolks/sender; amounts {10,20,50}; friends-only; server-atomic.

## Testing / verification

- Build green (app target) on Yolk-SE; no XCTest in this project, so verify via the
  existing social seams + screenshots: `YOLK_FRIENDS` (the tab), `YOLK_VISIT` (a visit),
  `YOLK_INBOX` (postcards). Add temporary seams to render the new strip + a populated
  friends grid + the gift/QR flows with fixture data, screenshot, then remove.
- Backend: after applying `social-living.sql`, smoke-test each RPC with two fixture
  users via the Management API query endpoint (send_wave/get_waves, log_visit/
  get_recent_visits, gift_yolks happy-path + over-cap + insufficient-funds + not-friends).
- No em dashes in user-facing copy. No new third-party dependencies (CoreImage +
  AVFoundation are system frameworks).

## Open / deferred (v2)

- Friend milestones beyond redecorate (e.g. "reached devotion").
- Wave/visit/gift push notifications (the strip covers it in-app for now).
- Reactions/stickers on postcards.
