# Task 6 Report: VisitView interactions (wave / note / gift) + log_visit

## Wiring summary

**logVisit:** Called in `.task` on VisitView appear via `store.logVisit(owner: friend.user_id)`. Fires once per view load; the RPC throttles to one visit entry per day per visitor-owner pair.

**Wave:** `waveButton` calls `store.sendWave(to: friend.user_id)` inside a `Task`. `Haptics.shared.select()` fires before the async call. A `@State var waved: Bool` flips to `true` immediately and the button label changes to "waved!" with muted color, preventing repeated taps. Animated with `.easeInOut`.

**Note:** `noteButton` sets `composing = true`, presenting the existing `PostcardCompose` sheet. This reuses the existing path identically -- no changes to PostcardCompose.

**Gift:** `giftMenu` is a SwiftUI `Menu` with three `Button` items for 10, 20, 50 Yolks. Selecting one calls `sendGift(_:)` which:
- Sets `giftBusy = true` (disables menu, shows "...").
- Calls `store.giftYolks(to: friend.user_id, amount:)`.
- On `ok:true`: fires `Haptics.shared.reward()`, calls `wallet.adopt(coins: newCoins, owned: wallet.owned)` so sender balance reflects immediately, shows a `YolkDialog` confirming the gift.
- On `ok:false`: fires `Haptics.shared.warn()`, shows a `YolkDialog` with a warm failure message mapped from the reason:
  - `insufficient` -> "you don't have enough Yolks for that."
  - `daily_cap` -> "you have hit today's gift limit. come back tomorrow."
  - `not_friends` -> "you need to be friends to gift Yolks."
  - other -> "couldn't send that just now. try again in a sec."

No em dashes used anywhere.

## Wallet param threading

`wallet: Wallet` was added as a parameter to:
1. `VisitView` (modified) -- uses `wallet.adopt(coins:owned:)` on gift success.
2. `FriendsView` (modified) -- threads it to the `VisitView` sheet.
3. `HomeView` (modified) -- passes `wallet` to the `FriendsView(...)` call.
4. `RootView` YOLK_VISIT seam (modified) -- passes `Wallet()` for the dev preview.

## Build result

`** BUILD SUCCEEDED **` on Yolk-ProMax (`9A3F2A47-5868-4956-B3AB-7531342B9347`, iOS 26.5).

## Screenshot outcome

`/tmp/task6-visit.png`: Sunny's decorated beach room renders correctly. The wave / leave a note / gift action row is visible below the room label. "leave a note" is the primary (dark) action; "wave" and "gift" are secondary (shell2 background). All three buttons are present and the layout is clean.

## Concerns

None. The existing visit reward (postcard `onReward` callback) is untouched. The `wallet.adopt(coins:owned:)` call preserves owned cosmetics while snapping balance to the server-returned value.
