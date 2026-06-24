# Progress ledger — Friends Tab Redesign

Plan: `docs/superpowers/plans/2026-06-21-friends-tab-redesign.md`
Mode: subagent-driven, NO GIT. Task 1 (live DB migration) done by controller for secret handling; client tasks delegated.
Supabase project: `vlucekvrdxvpkvbizabz` (Management API + PAT from yolkling-app/.env.local, SECRET).
Device: Yolk-ProMax `9A3F2A47-5868-4956-B3AB-7531342B9347` (switched from SE at user request mid-run; user is on SE).

## Task status
- [x] Task 1: Backend migration — social-living.sql applied to vlucekvrdxvpkvbizabz. 3 tables + 5 RPCs confirmed. Smoke-tested all (wave/seen-once, visit throttle, gift happy/bad_amount/daily_cap/insufficient — balances correct). Fixtures removed. [controller]
- [x] Task 2: Client models + store + RPC methods — Wave/Visit decodables, RoomSnapshot.streak/hour (lenient), Friend.updated_at/updatedDate, 5 SupabaseClient RPC methods (postJSON helper), 5 SocialStore methods + lastVisited (UserDefaults). Build green, live decode "waves:0 visits:0" no crash. Review clean (controller).
- [x] Task 3: Publish presence extras — mySnapshot() now sends streak (careStreak) + hour. Build green. [controller inline]
- [x] Task 4: FriendRoomCard — live mini RoomView + name + status (new/mood/asleep/streak) + wave button. Build green, screenshot confirmed. Review clean (controller).
- [x] Task 5: WhileYouWereAwayStrip — count-free lines (waved/visited/redecorated), EmptyView when all empty, weeklyChallengeCard style. Build green (ProMax), screenshot confirmed. Review clean (controller).
- [x] Task 6: VisitView interactions — logVisit on appear; wave/note/gift actions; gift success adopts server coins (preserves owned), failure shows gentle reason; wallet param threaded VisitView←FriendsView←HomeView. Build green (ProMax), screenshot confirmed all 3 actions. Review clean (controller).
- [x] Task 7: Grow section — QRCodeView (CoreImage), QRScannerView (AVFoundation, permission-safe), GrowFriendsView (add/share/show-QR/scan/invite), NSCameraUsageDescription in project.yml. Build green (ProMax), screenshot confirmed. Review clean (controller).
- [x] Task 8: Assemble new FriendsView — header + WhileYouWereAwayStrip + 2-col live FriendRoomCard grid + GrowFriendsView; loads waves/visits, computes redecorated; preserves VisitView(+wallet)/inbox sheets. Build green (ProMax), full-tab screenshot verified. Controller fix: GrowFriendsView empty-state line had a spaced hyphen + showed with friends present -> changed to neutral always-true nudge (real empty state stays in FriendsView). Final dash sweep clean (only `// MARK: -`).

## ALL 8 TASKS COMPLETE. Friends redesign shipped. Final build green (ProMax).

## Minor findings (final triage)
- `showInvite`/`ReferralView` sheet in FriendsView is now ORPHANED (GrowFriendsView owns add/invite). Harmless dead state; clean up in a later pass. ALSO verify the "+50 each" invite reward is still actually granted via `add_friend` now that ReferralView (which may have handled it) is unreferenced.
