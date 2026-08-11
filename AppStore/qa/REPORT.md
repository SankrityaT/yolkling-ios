# Yolkling 1.0 — QA + verification report

Date of run: 2026-07-17. Build: iOS 18 target, Xcode 26.6, iPhone 16 Pro Max sim (iOS 26.5), 1320x2868.

## Build + tests
- `xcodegen generate` + `xcodebuild build` (Debug, simulator): **BUILD SUCCEEDED**, including the new `YolklingScreenTimeReport` app-extension and the family-controls entitlement.
- `xcodebuild test`: **48 tests in 6 suites passed** (Rewards, Wallet, StreakEngine, TrustStage, Species, Sync). Pure-logic, deterministic. See `YolklingTests/`.

## Free-tier pivot (100% free)
- Removed `SubscriptionStore.swift`, `PlusView.swift`, `Yolkling.storekit`, the `storeKitConfiguration` scheme line, the `YOLK_PLUS` seam, and the profile plus-row.
- Grep confirms no `isPlus` / `SubscriptionStore` / `PlusView` / `storeKitConfiguration` symbols remain. No feature was gated, so nothing was lost. No IAP => simplest App Review, no paid-agreement/banking setup needed.

## Screen Time / Family Controls (real, built)
- `ScreenTimeService` now uses `AuthorizationCenter.requestAuthorization(for: .individual)` + a `DeviceActivityReport` extension that sums today's on-screen time privacy-blind (opaque tokens only) and writes off-phone hours to the App Group; the app hosts a hidden report and reads it back.
- Feeds the creature **additively** (`min(1, healthVitality + 0.15 * offScreenProgress)`) — a heavy screen day can never lower vitality (WELLBEING guardrail: sleepy, never sick).
- Self-gating: on the simulator / before the entitlement is granted / if declined, `available == false` and the Home card shows the soft "soon" pillar (tappable to opt in). The app ships correctly either way.
- **Cannot be functionally verified in the simulator** (Family Controls is device-only). Verified: compiles + signs for the sim, gated fallback renders, and the `#if DEBUG mock` path renders the real off-phone pillar (see screenshot 03). Real-device verification is pending the Apple **Family Controls (Distribution)** entitlement (human action).

## App Store compliance
- **Account deletion (Guideline 5.1.1(v)):** "delete my account" in Profile with a destructive confirm; calls the `delete_user` RPC then wipes the local SwiftData player (returns app to onboarding). Client + SQL done.
- **UGC block/report (Guideline 1.2):** each received postcard has a visible menu -> "report this note" / "block sender", wired to `report_content` / `block_user` RPCs with a confirmation toast. Client + SQL done.
- **Honest copy:** softened the two shipping E2E-encryption overclaims (onboarding health priming + profile) and the SyncClient comment. Grep confirms no E2E claim remains in shipping UI.
- **Privacy manifest:** added `Yolkling/PrivacyInfo.xcprivacy` (+ widget twin): tracking false, UserDefaults CA92.1 reason, collected types = UserID + OtherUserContent (linked, not tracking, app functionality). Matches the nutrition-label answers in the listing doc.
- **Version:** bumped to 1.0.0 (1).

## Live backend (Supabase) verification
- **RLS proof:** anon direct-reads of `app_users`, `friendships`, `postcards`, `room_snapshots` return empty `[]` — the shipped anon key cannot enumerate other users' data.
- **Social live:** `ensure_app_user` RPC returns a real friend code — the social backend is deployed and reachable.
- **Moderation SQL DEPLOYED + verified.** `docs/sql/moderation.sql` was applied to the live project via the Management API (HTTP 201). End-to-end anon-key run confirmed: `add_friend` → `send_postcard` (+5) → `report_content` (ok) → `block_user` (friends and inbox both cleared to `[]`) → `delete_user` ×N (ok). All QA test rows (incl. the earlier `qa-verify-delete-me`) were deleted afterward. The `blocks` + `content_reports` tables and the three functions are live.

## UI/UX smoke (via screenshot seams, simulator)
Captured and eyeballed at 1320x2868 — all render correctly, on-brand, no clipping / safe-area / dark-mode leaks:
- Home hero (`YOLK_VIBE=0`), grow-by-living with steps+sleep+**off-phone** (`YOLK_HEALTH=high` + `YOLK_SCREENTIME=high`), focus, Dex, closet, friend visit, hatch step, postcard inbox.
- Raw captures in `screenshots/raw/`, captioned marketing set in `screenshots/marketing/` (8 shots, 1320x2868).
- **Device-only, not smoke-tested here:** the Focus Live Activity and the home-screen widget (require a real device); include in the TestFlight device pass.

## Known follow-ups (non-blocking for the build; see SUBMISSION-CHECKLIST.md)
1. Human: file the Family Controls (Distribution) entitlement request (gates submission), then real-device verify Screen Time.
2. Human: run `docs/sql/moderation.sql`.
3. Optional polish: an onboarding Screen Time priming step (parallel to the health one). Opt-in already exists via the Home "off phone" pillar.
4. Optional: `get_friends`/`get_postcards` could also filter blocked users at read time (note in moderation.sql); the block action already clears current content.
