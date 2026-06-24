# Friends Tab Redesign - Task 8 Report

## New Body Layout

`FriendsView.body` is now a `VStack(spacing: 0)` with a fixed `header` + a `ScrollView` containing:

1. **`WhileYouWereAwayStrip(waves:visits:redecorated:onTap:)`** - renders `EmptyView` when all arrays are empty; `onTap` resolves the friend ID against `store.friends` and sets `visiting`.
2. **Friends grid** - a 2-col `LazyVGrid` of `FriendRoomCard(friend:store:onOpen:)` when `store.friends` is non-empty, or a soft empty-state VStack ("no friends yet") when empty.
3. **`GrowFriendsView(store:myCode:vibe:onAdded:)`** - add-by-code, share link, show QR, scan a friend, +50 invite nudge. `onAdded` triggers `store.load()`.

The fixed `header` is unchanged: "friends" title + inbox envelope button with unread badge.

## Waves / Visits / Redecorated Loading

Added `@State private var waves: [Wave] = []` and `@State private var visits: [Visit] = []`.

In `.task`:
```swift
await store.ensureCode()
await store.publish(name: myName, snapshot: mySnapshot)
await store.load()
async let w = store.loadWaves()
async let v = store.loadRecentVisits()
let (loadedWaves, loadedVisits) = await (w, v)
waves = loadedWaves
visits = loadedVisits
```

`redecorated` is a computed property filtering `store.friends` where `f.updatedDate > store.lastVisited(f.user_id)` (or `lastVisited == nil`).

## What Was Removed

- `codeCard` (the inline "your code" tap-to-copy card) - replaced by GrowFriendsView which owns the full add/share/QR flow.
- `addRow` (inline add-by-code field + button) - now in GrowFriendsView.
- `friendList` / `friendRow(_:)` (the old plain VStack list with YolklingView + chevron) - replaced by the 2-col FriendRoomCard grid.
- `inviteButton` (inline invite button -> ReferralView sheet) - the +50 nudge lives in GrowFriendsView; `showInvite` state and `ReferralView` sheet are still present but now only accessible via ReferralView if wired externally.
- `add()` private function - now handled inside GrowFriendsView.

Preserved: `wallet` param, `onReward` closure, `VisitView` sheet (with `wallet`), `PostcardInbox` sheet, `ReferralView` sheet, header, all init params, `.task` loading, `yolkDialog`.

## Build Result

`** BUILD SUCCEEDED **` on Yolk-ProMax `9A3F2A47-5868-4956-B3AB-7531342B9347` (iOS 26.5), no xcodegen needed (no new files, no project.yml changes).

## Screenshot Outcome

`/tmp/task8-friends.png` shows the full tab rendering top-to-bottom:
- Header: "friends" + inbox envelope icon.
- 2-col grid: Sunny (happy, wave button) and Pip (playful, wave button) as live room cards.
- GrowFriendsView: add field, share invite link, show my QR, scan a friend, +50 nudge.
- WhileYouWereAwayStrip absent (correctly hidden - no waves/visits in the seam fixture).
- Empty state not shown (seam injects fixture friends Sunny + Pip).

No temporary fixtures were added to the seam in Tasks 4/5 (confirmed by grep - the seam only sets `showFriends = true` via the env variable). No cleanup needed.

## Concerns

None. The `showInvite` state + `ReferralView` sheet are retained but not triggered from the new layout (GrowFriendsView handles adds; the old invite flow via `ReferralView` is orphaned). This is low risk - it was already wired before Task 8 and can be removed in a later cleanup pass.
