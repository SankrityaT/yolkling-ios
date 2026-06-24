# Friends Tab Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the static Friends tab into a living social surface: live friend room cards + ambient status, wave/note/gift interactions, a "while you were away" strip, and frictionless growth (share/QR/scan).

**Architecture:** A small Supabase migration adds waves/visits/gifts tables + SECURITY DEFINER RPCs. The client gains store methods + decodables, publishes streak/hour into the existing snapshot jsonb, and the Friends tab is rebuilt from focused view components. Reuses the existing renderers (RoomView), wallet (`app_users.coins`), and social RPCs.

**Tech Stack:** Swift 6 (MainActor default isolation), SwiftUI, SwiftData, CoreImage (QR gen), AVFoundation (QR scan), Supabase (Postgres + PostgREST RPCs).

## Global Constraints

- iOS 18.0; Swift 6 strict concurrency (MainActor default isolation).
- SwiftData migration-safe: only OPTIONAL/DEFAULTED `@Model` props; `RoomSnapshot` new fields OPTIONAL.
- NO em dashes in user-facing copy. Warm lowercase-ok voice.
- No new third-party dependencies (CoreImage + AVFoundation are system frameworks).
- **No git** in this project: no commit steps. Gate per task = (a) compiles clean, and (b) the task's stated verification (RPC smoke test or seam screenshot).
- **No XCTest** (codebase convention): verify via build + the `YOLK_*` seams.
- **Supabase project ref: `vlucekvrdxvpkvbizabz`.** Migrations apply via the Management API query endpoint:
  `POST https://api.supabase.com/v1/projects/vlucekvrdxvpkvbizabz/database/query`,
  header `Authorization: Bearer $TOKEN`, JSON body `{"query":"..."}`.
  The token is `SUPABASE_ACCESS_TOKEN` in `/Users/sankiii/yolkling-app/.env.local`. It is an
  ACCOUNT SECRET: load it into an env var, NEVER echo/print/commit it. Do NOT use the
  connected Supabase MCP (different org). End DDL batches with `notify pgrst, 'reload schema';`.
  Load safely: `export $(grep -E '^SUPABASE_ACCESS_TOKEN=' /Users/sankiii/yolkling-app/.env.local | xargs)` (does not print the value).

### Devices (never erase/uninstall)
- **Yolk-ProMax `9A3F2A47-5868-4956-B3AB-7531342B9347` (iOS 26.5) — USE THIS for builds/screenshots** (the user is on Yolk-SE).
- Yolk-SE `8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1` — do not touch (user's device).

### Build + verify
```bash
cd /Users/sankiii/iOSLocal/yolkling && xcodegen generate   # only if files added/removed or project.yml changed
xcodebuild -scheme Yolkling -destination 'platform=iOS Simulator,id=9A3F2A47-5868-4956-B3AB-7531342B9347' -derivedDataPath build/DD build 2>&1 | tail -25
```
Expected: `** BUILD SUCCEEDED **`. Seam screenshot: install, `SIMCTL_CHILD_YOLK_FOO=1 xcrun simctl launch --terminate-running-process <SE> com.Sankritya.Yolkling`, `sleep 4`, `xcrun simctl io <SE> screenshot /tmp/x.png`, then Read it.

---

## File structure

Create:
- `docs/sql/social-living.sql` — the migration (waves/visits/gifts + RPCs).
- `Features/Social/FriendRoomCard.swift` — one friend's live mini-room card + status + wave.
- `Features/Social/WhileYouWereAwayStrip.swift` — the reciprocity strip.
- `Features/Social/GrowFriendsView.swift` — add-by-code + ShareLink + QR show + QR scan + invite.
- `Features/Social/QRCodeView.swift` — CoreImage QR generator view.
- `Features/Social/QRScannerView.swift` — AVFoundation camera scanner (UIViewControllerRepresentable).

Modify:
- `Core/Networking/SocialModels.swift` — `Wave`, `Visit` decodables; `RoomSnapshot.streak`/`.hour` optional.
- `Features/Social/SocialStore.swift` — wave/visit/gift/recent methods + `lastVisited` tracking.
- `Core/Networking/SupabaseClient.swift` — RPC methods.
- The snapshot publisher (`Core/Widget/WidgetPublisher.swift` caller in `HomeView.mySnapshot()`) — include streak + hour.
- `Features/Social/VisitView.swift` — wave/note/gift actions + `log_visit` on open.
- `Features/Social/FriendsView.swift` — rebuilt layout assembling the components.
- `project.yml` — `INFOPLIST_KEY_NSCameraUsageDescription`.

---

### Task 1: Backend migration (waves / visits / gifts)

**Files:** Create `docs/sql/social-living.sql`.

- [ ] **Step 1: Write `docs/sql/social-living.sql` exactly**

```sql
-- Living Friends tab: waves, visits, gifts. All RPCs SECURITY DEFINER; tables not
-- directly client-selectable. Idempotent (if not exists / or replace).
create table if not exists public.waves (
  id bigint generated always as identity primary key,
  from_id text not null references public.app_users(apple_user_id) on delete cascade,
  to_id   text not null references public.app_users(apple_user_id) on delete cascade,
  created_at timestamptz not null default now(),
  seen_at timestamptz,
  check (from_id <> to_id)
);
create index if not exists waves_to_unseen on public.waves(to_id, seen_at);

create or replace function send_wave(p_from text, p_to text)
returns jsonb language plpgsql security definer as $$
begin
  if not exists (select 1 from public.friendships where user_id = p_from and friend_id = p_to) then
    return jsonb_build_object('ok', false, 'reason', 'not_friends');
  end if;
  delete from public.waves where from_id = p_from and to_id = p_to and seen_at is null;
  insert into public.waves(from_id, to_id) values (p_from, p_to);
  return jsonb_build_object('ok', true);
end; $$;

create or replace function get_waves(p_user text)
returns jsonb language plpgsql security definer as $$
declare v jsonb;
begin
  select coalesce(jsonb_agg(jsonb_build_object('from_id', w.from_id, 'name', rs.name,
           'created_at', w.created_at) order by w.created_at desc), '[]'::jsonb)
    into v
  from public.waves w
  left join public.room_snapshots rs on rs.user_id = w.from_id
  where w.to_id = p_user and w.seen_at is null;
  update public.waves set seen_at = now() where to_id = p_user and seen_at is null;
  return v;
end; $$;

create table if not exists public.visits (
  id bigint generated always as identity primary key,
  visitor_id text not null references public.app_users(apple_user_id) on delete cascade,
  owner_id   text not null references public.app_users(apple_user_id) on delete cascade,
  created_at timestamptz not null default now(),
  check (visitor_id <> owner_id)
);
create index if not exists visits_owner on public.visits(owner_id, created_at);

create or replace function log_visit(p_visitor text, p_owner text)
returns void language plpgsql security definer as $$
begin
  if exists (select 1 from public.visits where visitor_id = p_visitor and owner_id = p_owner
             and created_at >= date_trunc('day', now())) then
    return;
  end if;
  insert into public.visits(visitor_id, owner_id) values (p_visitor, p_owner);
end; $$;

create or replace function get_recent_visits(p_user text)
returns jsonb language sql security definer as $$
  select coalesce(jsonb_agg(j order by j->>'created_at' desc), '[]'::jsonb) from (
    select distinct on (v.visitor_id)
      jsonb_build_object('visitor_id', v.visitor_id, 'name', rs.name, 'created_at', v.created_at) as j
    from public.visits v
    left join public.room_snapshots rs on rs.user_id = v.visitor_id
    where v.owner_id = p_user and v.created_at >= now() - interval '7 days'
    order by v.visitor_id, v.created_at desc
  ) t;
$$;

create table if not exists public.gifts (
  id bigint generated always as identity primary key,
  from_id text not null references public.app_users(apple_user_id) on delete cascade,
  to_id   text not null references public.app_users(apple_user_id) on delete cascade,
  amount int not null,
  created_at timestamptz not null default now()
);
create index if not exists gifts_from on public.gifts(from_id, created_at);

create or replace function gift_yolks(p_from text, p_to text, p_amount int)
returns jsonb language plpgsql security definer as $$
declare v_today int; v_balance int;
begin
  if p_amount not in (10,20,50) then return jsonb_build_object('ok', false, 'reason', 'bad_amount'); end if;
  if not exists (select 1 from public.friendships where user_id = p_from and friend_id = p_to) then
    return jsonb_build_object('ok', false, 'reason', 'not_friends');
  end if;
  select coalesce(sum(amount),0) into v_today from public.gifts
    where from_id = p_from and created_at >= date_trunc('day', now());
  if v_today + p_amount > 100 then return jsonb_build_object('ok', false, 'reason', 'daily_cap'); end if;
  select coins into v_balance from public.app_users where apple_user_id = p_from for update;
  if coalesce(v_balance,0) < p_amount then return jsonb_build_object('ok', false, 'reason', 'insufficient'); end if;
  update public.app_users set coins = coins - p_amount where apple_user_id = p_from;
  update public.app_users set coins = coins + p_amount where apple_user_id = p_to;
  insert into public.gifts(from_id, to_id, amount) values (p_from, p_to, p_amount);
  select coins into v_balance from public.app_users where apple_user_id = p_from;
  return jsonb_build_object('ok', true, 'coins', v_balance);
end; $$;

grant execute on function send_wave(text, text)         to anon, authenticated;
grant execute on function get_waves(text)               to anon, authenticated;
grant execute on function log_visit(text, text)         to anon, authenticated;
grant execute on function get_recent_visits(text)       to anon, authenticated;
grant execute on function gift_yolks(text, text, int)   to anon, authenticated;

notify pgrst, 'reload schema';
```

- [ ] **Step 2: Apply it via the Management API (secret token, never echoed)**

```bash
export $(grep -E '^SUPABASE_ACCESS_TOKEN=' /Users/sankiii/yolkling-app/.env.local | xargs)
Q=$(python3 -c "import json,sys; print(json.dumps({'query': open('/Users/sankiii/iOSLocal/yolkling/docs/sql/social-living.sql').read()}))")
curl -s -X POST "https://api.supabase.com/v1/projects/vlucekvrdxvpkvbizabz/database/query" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  -d "$Q" | head -40
```
Expected: a non-error JSON (e.g. `[]` or row output), NOT an error object. If it returns an error, read it and fix the SQL.

- [ ] **Step 3: Smoke-test each RPC with two existing fixture users**

First find two real `apple_user_id`s to test with:
```bash
curl -s -X POST "https://api.supabase.com/v1/projects/vlucekvrdxvpkvbizabz/database/query" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" -H "Content-Type: application/json" \
  -d '{"query":"select apple_user_id, coins from public.app_users limit 5;"}'
```
If fewer than 2 users / not friends, create two fixtures + a friendship via a query (insert into app_users + friendships). Then call (substituting A and B):
- `select send_wave('A','B');` -> `{"ok":true}`; `select get_waves('B');` -> array with A; second `get_waves('B')` -> `[]` (seen).
- `select log_visit('A','B'); select log_visit('A','B'); select get_recent_visits('B');` -> ONE entry for A (throttled).
- `select gift_yolks('A','B',20);` -> `{"ok":true,"coins":...}` (A debited, B credited). `select gift_yolks('A','B',999);` -> bad_amount. Over-cap + insufficient + non-friend each return the right reason.
Record the results in the report. Do NOT delete real users; only fixtures you created.

---

### Task 2: Client models + store + RPC methods

**Files:** Modify `Core/Networking/SocialModels.swift`, `Features/Social/SocialStore.swift`, `Core/Networking/SupabaseClient.swift`.

**Interfaces (Produces):**
- `struct Wave: Codable, Sendable, Identifiable { let from_id: String; let name: String?; let created_at: String; var id: String { from_id } ; var senderName: String }`
- `struct Visit: Codable, Sendable, Identifiable { let visitor_id: String; let name: String?; let created_at: String; var id: String { visitor_id }; var visitorName: String }`
- `RoomSnapshot.streak: Int?`, `RoomSnapshot.hour: Int?` (optional).
- `SocialStore`: `func sendWave(to: String) async`, `func loadWaves() async -> [Wave]`, `func logVisit(owner: String) async`, `func loadRecentVisits() async -> [Visit]`, `func giftYolks(to: String, amount: Int) async -> (ok: Bool, coins: Int?, reason: String?)`, and `lastVisited(_ id: String) -> Date?` / `markVisited(_ id: String)` (persisted).
- `SupabaseClient`: matching `rpc` calls.

- [ ] **Step 1: Add `Wave`/`Visit` + snapshot fields**

In `SocialModels.swift` add the two structs (mirror the existing `Postcard`/`Friend` decodable style, with a `senderName`/`visitorName` fallback to "a friend"). Add to `RoomSnapshot`: `var streak: Int?` and `var hour: Int?` (and include them in its CodingKeys + custom `init(from:)` if it has one, defaulting to nil when absent).

- [ ] **Step 2: Add `SupabaseClient` RPC methods**

Match the existing RPC-call pattern in `SupabaseClient.swift` (read `addFriend`/`sendPostcard` for the exact `rpc(_:params:)` helper + decoding). Add: `sendWave(from:to:)`, `waves(userID:)`, `logVisit(visitor:owner:)`, `recentVisits(userID:)`, `giftYolks(from:to:amount:)`. Each posts to `/rest/v1/rpc/<name>` with the params and decodes the jsonb result.

- [ ] **Step 3: Add `SocialStore` methods + lastVisited**

Wrap the client methods (read `SocialStore.swift` for the `userID`/pattern). Persist `lastVisited` as a `[String: Date]` in `UserDefaults` (key `social.lastVisited`); `markVisited(id)` sets now, `lastVisited(id)` reads.

- [ ] **Step 4: Build + live smoke via a seam**

Build. Add a TEMP `YOLK_SOCIALCHECK` seam in RootView that, on appear, calls `loadRecentVisits()`/`loadWaves()` for the install's user and renders the counts (proves decoding against the live RPCs from Task 1). Screenshot, confirm no decode crash, remove the seam, rebuild green. (If the install user has no waves/visits, an empty array + no crash is a pass.)

---

### Task 3: Publish presence extras (streak + hour)

**Files:** Modify `HomeView.mySnapshot()` (the `RoomSnapshot` builder) in `Features/Home/HomeView.swift`.

- [ ] **Step 1: Include streak + hour in the published snapshot**

In `mySnapshot()`, set `streak: careStreak` and `hour: Calendar.current.component(.hour, from: Date())` on the returned `RoomSnapshot` (these flow to `publish_room` + the widget). Build green. (No new file.)

- [ ] **Step 2: Verify**

Build. Confirm `mySnapshot()` compiles with the new fields and that `publishWidget()`/`publish` still send the snapshot. (Behavioral check: the friend cards in Task 4 will read streak/hour.)

---

### Task 4: FriendRoomCard + the friends grid (living presence)

**Files:** Create `Features/Social/FriendRoomCard.swift`.

**Interfaces (Consumes):** `Friend` (has `snapshot: RoomSnapshot?`), `RoomView`, `SocialStore.lastVisited`, `RoomSnapshot.updated_at`? NOTE: `updated_at` is on the get_friends row, not inside the snapshot — read how `Friend` currently carries it (it may need adding to the `Friend` decodable). `SocialStore.sendWave`.

- [ ] **Step 1: Ensure `Friend` carries `updated_at`**

Read `SocialModels.swift` `Friend`. If `updated_at` is not decoded, add `let updated_at: String?` (get_friends already returns it). Provide a `var updatedDate: Date?` parsed helper.

- [ ] **Step 2: Build `FriendRoomCard`**

A card with a live mini `RoomView` built from `friend.snapshot` (use `snapshot.makeVibe(name:)`, `.theme`, `.outfit`, `.decor`, `.expression`), framed ~square and clipped. Below: the friend's name + a status row computed from the snapshot + lastVisited:
- `✨ new` if `friend.updatedDate > store.lastVisited(friend.id)`.
- mood label (from `snapshot.moodRaw`).
- `😴` if `snapshot.hour` is in the night phase (reuse `YolkExpression.phase(forHour:) == .night`).
- `🔥 \(streak)` if `snapshot.streak ?? 0 > 0`.
A small `👋` button calling `store.sendWave(to: friend.id)` with a haptic + transient "waved" state. Tapping the card body invokes an `onOpen(friend)` closure (the parent opens VisitView).

- [ ] **Step 3: Verify via the friends seam**

Build. Use the existing `YOLK_FRIENDS` seam (or extend it) so the friends grid renders with the fixture friend(s) (e.g. `SocialPreview.sunny`). Screenshot `/tmp/task4-cards.png`, Read it: a live room card with name + status renders, wave button present. Tune the framing so the room reads.

---

### Task 5: WhileYouWereAwayStrip (what's new)

**Files:** Create `Features/Social/WhileYouWereAwayStrip.swift`.

- [ ] **Step 1: Build the strip**

A view that takes `waves: [Wave]`, `visits: [Visit]`, and `redecorated: [Friend]` (friends with `updatedDate > lastVisited`) and renders a count-free list of warm lines: `"\(name) waved"`, `"\(name) visited your room"`, `"\(name) redecorated"`, each with a small icon, newest first, capped at ~6. Hidden entirely if all three are empty. Match the card style of `weeklyChallengeCard` (read `HomeView`). Tapping a line invokes `onTap(friendID)`.

- [ ] **Step 2: Verify**

Build. Extend the `YOLK_FRIENDS` seam to inject fixture waves/visits and render the strip. Screenshot `/tmp/task5-strip.png`, Read it: the strip shows the lines; confirm it hides when empty (toggle the fixture).

---

### Task 6: VisitView interactions (wave / note / gift) + log_visit

**Files:** Modify `Features/Social/VisitView.swift`.

**Interfaces (Consumes):** `SocialStore.logVisit`, `sendWave`, `giftYolks`; existing postcard compose; `wallet` for the gift affordance.

- [ ] **Step 1: Log the visit + add actions**

On VisitView appear, call `store.logVisit(owner: friend.id)`. Add an actions row under their room: `👋 wave` (sendWave), `💌 leave a note` (the existing postcard compose path), `🎁 gift yolks` (a small picker 10/20/50 -> `store.giftYolks(to:amount:)`). On a successful gift, show a confirmation and update the local wallet to the returned `coins` (so the sender's balance reflects it immediately); on `ok:false`, show the reason gently (not enough yolks / daily limit reached). Keep the existing visit reward.

- [ ] **Step 2: Verify**

Build. Use `YOLK_VISIT` seam. Screenshot `/tmp/task6-visit.png`, Read it: the room renders with the wave/note/gift actions. (The gift hitting the live RPC was smoke-tested in Task 1; here verify the UI + wiring compiles and renders.)

---

### Task 7: Grow section (share link + QR show + QR scan)

**Files:** Create `Features/Social/GrowFriendsView.swift`, `QRCodeView.swift`, `QRScannerView.swift`; modify `project.yml` (camera usage string).

- [ ] **Step 1: QRCodeView (CoreImage)**

`QRCodeView(text: String)` -> renders a `CIQRCodeGenerator` image scaled up (nearest-neighbor), tinted to match the brand. Pure SwiftUI + CoreImage.

- [ ] **Step 2: QRScannerView (AVFoundation)**

A `UIViewControllerRepresentable` wrapping an `AVCaptureSession` + `AVCaptureMetadataOutput` (`.qr`); on a detected string, extract the code (accept either a raw `YOLK-XXXX` code or a `https://yolkling.com/add/<code>` URL) and call `onScan(code)`. Handle camera-permission-denied with a gentle message. Add `INFOPLIST_KEY_NSCameraUsageDescription = "Scan a friend's code to add them."` to the app target in `project.yml`.

- [ ] **Step 3: GrowFriendsView**

Assembles: the add-by-code field (existing `addFriend` flow), a `ShareLink` sharing `https://yolkling.com/add/<myCode>`, a "show my QR" button -> `QRCodeView`, a "scan a friend" button -> `QRScannerView` sheet, the "+50 each" invite line, and the empty-state copy. No em dashes.

- [ ] **Step 4: Verify**

`xcodegen generate` (new files + project.yml), build. Screenshot the grow section via the friends seam (`/tmp/task7-grow.png`): add field, share, show-QR (render the QR), scan button present. Camera scan itself cannot be exercised on the simulator (no camera) — note that; the scanner view should at least present without crashing.

---

### Task 8: Assemble the new FriendsView

**Files:** Modify `Features/Social/FriendsView.swift`.

- [ ] **Step 1: Rebuild the layout**

Rebuild `FriendsView` as one scroll: header ("friends" + inbox button w/ unread badge, unchanged) -> `WhileYouWereAwayStrip(waves:visits:redecorated:onTap:)` -> `FriendsGrid` of `FriendRoomCard` (2-col `LazyVGrid`, `onOpen` -> `visiting = friend`) -> `GrowFriendsView`. On appear / `.task`, load friends (existing), `loadWaves()`, `loadRecentVisits()`, and compute `redecorated`. Keep the `VisitView` sheet (now enhanced) and the postcard inbox sheet.

- [ ] **Step 2: Verify**

Build. `YOLK_FRIENDS` seam screenshot `/tmp/task8-friends.png`, Read it: the full tab renders top-to-bottom (strip when present, grid of live cards, grow section). Confirm empty state (no friends) shows the grow/share prompt. Remove any temporary fixtures added to the seam during 4/5; rebuild green.

---

## Self-review

**Spec coverage:**
- Living presence (cards + status, new-since-visit) -> Tasks 3,4. Wave -> Tasks 1,2,4,6.
  Note (postcard) -> Task 6 (reuses existing). Gift yolks (RPC + cap + UI) -> Tasks 1,2,6.
  What's new strip (waves+visits+redecorated) -> Tasks 1,2,5,8. Easier to grow (share/QR
  show/QR scan/invite/empty) -> Task 7. Presence extras in snapshot -> Task 3. Backend
  (waves/visits/gifts + RPCs, Management API, secret token) -> Task 1. Camera permission
  -> Task 7. Privacy (streak/hour only) -> Task 3 scope. Layout -> Task 8.
- Deferred (milestones beyond redecorate, push notifs, postcard reactions) -> no task.

**Placeholder scan:** SQL migration + smoke tests are exact. Client model fields are exact.
Store/client methods + view tasks give precise interfaces + the existing files to read for
the RPC-call + card-render patterns, rather than reproducing hundreds of lines of SwiftUI/
networking; the implementers MUST read the named files (SupabaseClient rpc helper,
SocialStore, RoomView init, SocialModels) and match them. No "TBD".

**Type consistency:** `Wave`/`Visit` (with `senderName`/`visitorName`), `RoomSnapshot.streak`/
`.hour`, `Friend.updated_at`/`updatedDate`, `SocialStore.{sendWave,loadWaves,logVisit,
loadRecentVisits,giftYolks,lastVisited,markVisited}`, `gift_yolks(from,to,amount)->(ok,coins,
reason)`, `FriendRoomCard(onOpen:)`, `WhileYouWereAwayStrip(waves:visits:redecorated:onTap:)`,
`QRCodeView(text:)`, `QRScannerView(onScan:)` are consistent across tasks.

**Executor reads before coding:** `Core/Networking/SupabaseClient.swift` (rpc helper +
addFriend/sendPostcard), `Features/Social/SocialStore.swift`, `Core/Networking/SocialModels.swift`
(Friend/Postcard/RoomSnapshot + any custom Codable init), `Features/Social/VisitView.swift`,
`Features/Social/FriendsView.swift`, `Features/Home/HomeView.swift` (`mySnapshot()`,
`weeklyChallengeCard` style), `Core/Creature/YolkExpression.swift` (`phase(forHour:)`).
