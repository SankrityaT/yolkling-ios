# Progress ledger — Home + Shop Redesign

Plan: `docs/superpowers/plans/2026-06-20-home-shop-redesign.md`
Mode: subagent-driven, NO GIT (gate = build clean + screenshot; reviewers read changed files; no rollback).
Devices: Yolk-SE `8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1`, Yolk-ProMax `9A3F2A47-5868-4956-B3AB-7531342B9347` (iOS 26.5). NEVER uninstall/erase.

- Pre-flight: xcodegen + Xcode 26.5 OK, devices OK, **baseline build GREEN**.

## ALL TASKS COMPLETE — final whole-feature review (opus): spec coverage COMPLETE, integration SHIP. No Critical/Important findings. End-to-end flows verified: place→persist→render→relaunch, migration (safe/once/onAppear), buy→grant→equip. Zero em dashes in copy. Post-review cleanup: deleted orphaned RoomScreen.swift (DecorateView superseded it), final build green. Remaining noted minors (non-blocking): `showWardrobe` var name now stale (drives Shop sheet), deferred Looks/Bundles (v2).

## Task status
- [x] Task 1: Zone model + derivation — RoomZone.swift created, API matches plan, build green, zone counts 6/2/4/2/6/5/9 verified, review clean (controller inline).
- [x] Task 2: Persist placement + first-load migration — Player.swift: placedDecorByZone + placedDecor(ownedIDs:) + setDecor(_:in:), all @MainActor (required by Swift 6), build green, matches contract, review clean (controller inline). Plan Task 5 Step 1 revised to run migration in onAppear (not body).
- [x] Task 3: Render one piece per occupied zone — NO CHANGE NEEDED. RoomView.swift already renders the passed `decor` array verbatim (ForEach lines 34-38, no internal ownership filter). Build green, YOLK_ROOM screenshot confirmed. Review clean (controller inline).
- [x] Task 4: Decorate mode (snap-to-zones) — DecorateView.swift created (signature exact), RoomTryOnPreview repointed. Build green, screenshots confirmed zones/tray/theme strip. Dedicated reviewer: spec PASS, quality APPROVED (3 minors below).
- [x] Task 5: Home screen — pure placedDecor var (l365), init seed (l83), migration only in onAppear (l171/378), room sheet → DecorateView with $placedByZone/$roomThemeID/persist (l148), nav relabeled Home/Shop/Dex/Friends/You (l702, Shop still → ShopView per plan), Decorate pill (l429), persist writes field (l208). Build green BOTH devices, no body-mutation warning. Review clean (controller inline, all 5 wirings verified in code).
- [x] Task 6: Unified Shop — ShopHomeView.swift created + HomeView sheet swapped. Reviewer spec PASS; quality CHANGES NEEDED → fixed + verified in code: F2 itemState wearing/owned (l276, cosmetics wearingLabel:true / themes+decor on:false), F1 `--`→period (none remain), F7 YOLK_WARDROBE opens clean (auto try-on moved to YOLK_TRYON l77). Build green, screenshot clean. Option-b theme apply (F3) sanctioned/kept.
- [x] Task 7: Shop utility row + curated front — ShopHomeView: SortOrder (price asc/desc, rarity, new), search TextField + clear, All|Owned toggle, per-aisle filteredItems + generic applySort, curated strips (new/under 100/almost yours) gated to empty-search+All, Room split themes/decor, empty strips hidden, correct ownership methods, no dashes. Build green, screenshot confirms. Review clean (controller inline).
- [x] Task 8: Delete orphans — removed BOTH WardrobeView.swift AND ShopView.swift (both orphaned after Task 6 swap; ShopView folded into ShopHomeView per plan intent). xcodegen regenerated, build green. Wardrobe/ now: CosmeticPreviewGrid, Wallet, WardrobeStore (all live). Done inline by controller.
- [x] Task 9: Tutorial rewrite — HomeTutorial.swift rewritten to 4 accurate beats (added "make it home" decorate beat; dropped "grow"/"time off your phone feeds"; em dashes removed). BONUS DISCOVERY: the first-run OnboardingView.swift (l411-412) had the SAME inaccuracies ("grows", "time off your phone earn its trust") — fixed to "warms up to you" + "your steps and sleep earn its trust". Build green; BOTH surfaces screenshot-verified (onboarding copy correct; HomeTutorial shows "1/4"). Done inline by controller.
- Minor: OnboardingView.swift:92 has an em dash in a CODE COMMENT (pre-existing, not user-facing, not part of this change) — left as-is.

## Minor findings (for final review triage)
- SourceKit cross-file diagnostics ("cannot find type X") are stale-index noise in this xcodegen project; `xcodebuild` is the source of truth.
- Task 4 M1: DecorateView `confirmBuy` does not guard `!wallet.has(item.id)` before purchase; UI prevents it today but defensive guard would harden against a state race (DecorateView.swift ~450).
- Task 4 M2: RootView `RoomTryOnPreview.stubWallet` is a bare `let`; idiomatic would be `@State` (dev-only seam, harmless).
- Task 4 note: `RoomDecor.Zone.label` is file-private to DecorateView.swift; move to RoomZone.swift if any other screen needs zone labels.
- Task 6 F4 (minor): owned themes show no active-selection ring in shop (apply is in DecorateView; ShopHomeView has no themeID binding). By-design (option b).
- Task 6 F5 (minor): `on` param is a no-op for decor/theme cards (always "owned"); consequence of option b.
- Task 6 F6 (minor): `vibe` stored but only read in init; harmless redundancy mirroring ShopView.

## Watch items (cross-task)
- Task 5: `Player.placedDecor(ownedIDs:)` mutates the @Model (sets `placedDecorByZone`) during the migration branch. If Task 5 calls it from a SwiftUI computed var inside `body`, that can trigger "Modifying state during view update." May need to run migration in `onAppear`/`init` instead of a body-read computed property.
